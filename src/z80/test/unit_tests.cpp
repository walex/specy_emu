#include <map>
#include <filesystem>
#include <iostream>
#include <list>
#include <chrono>
#include <thread>

#include "z80.h"
#include "ula.h"

#ifdef __cplusplus
extern "C" {
#endif

	void InitRegisters(uint16_t*);
	void GetRegisters(uint16_t*);

#ifdef __cplusplus
}
#endif

static double kZ80CpuCycleTimeInNanoseconds;
static double kHostCpuCycleTimeInNanoseconds;
static const size_t MEM_128K = 128 * 1024;
const char* TEST_CASES_PATH = "C:\\Users\\wadrw\\Documents\\develop\\projects\\personal\\sinclair_spec_emu\\test\\json";

#define MAX_LINE_LENGTH 512
#define REGISTERS_COUNT 25
enum reg_indices {
	pc = 0,
	sp,
	a,
	b,
	c,
	d,
	e,
	f,
	h,
	l,
	i,
	r,
	ei,
	wz,
	ix,
	iy,
	af_,
	bc_,
	de_,
	hl_,
	im,
	p,
	q,
	iff1,
	iff2
};

const char* reg_names[] = { "pc",
"sp",
"a",
"b",
"c",
"d",
"e",
"f",
"h",
"l",
"i",
"r",
"ei",
"wz",
"ix",
"iy",
"af_",
"bc_",
"de_",
"hl_",
"im",
"p",
"q",
"iff1",
"iff2"
};

void print_registers(const std::vector<uint16_t>& regs) {

	for (int i = 0; i < regs.size(); i++) {

		printf("%s -> %X\n", reg_names[i], regs[i]);
	}
}

double calculate_cycle_time_nanosecs(double clock_frequency_mhz) {
	// Convert clock frequency from MHz to Hz
	double clock_frequency_hz = clock_frequency_mhz * 1e6;

	// Calculate time per cycle in seconds
	double time_per_cycle_seconds = 1.0 / clock_frequency_hz;

	// Convert to microseconds (1 second = 1,000,000 microseconds)
	double time_per_cycle_nanoeconds = time_per_cycle_seconds * 1e9;

	return time_per_cycle_nanoeconds;
}

void getZ80AndHostCPUFreq(double& z80CpuCycleTimeInNanoseconds, double& hostCpuCycleTimeInNanoseconds) {
	// Get the initial time stamp counter value
	uint32_t long startCycles = __rdtsc();  // rdtsc provides the number of cycles

	// Sleep for a known amount of time (e.g., 1 second)
	std::this_thread::sleep_for(std::chrono::seconds(1));  // Sleep for 1 second

	// Get the final time stamp counter value
	uint32_t long endCycles = __rdtsc();

	// Calculate the difference in cycles
	uint32_t long cycleDifference = endCycles - startCycles;

	// The number of nanoseconds in one second is 1e9
	double cyclesPerSecond = (double)cycleDifference;  // This is the total cycles over 1 second
	hostCpuCycleTimeInNanoseconds = 1.0 / (cyclesPerSecond / 1e9);
	z80CpuCycleTimeInNanoseconds = calculate_cycle_time_nanosecs(Z80_CPU_FREQ_MHZ);
}

std::map<uint16_t, std::list<uint8_t>> io_test_data;

uint8_t get_io_next_test_data(uint16_t portId) {

	uint8_t result = 0;
	if (io_test_data.find(portId) != io_test_data.end()) {
		std::list<uint8_t>& dataPtr = io_test_data[portId];
		if (dataPtr.size() > 0) {
			result = dataPtr.front();
			dataPtr.pop_front();
		}
	}
	return result;
}

void put_io_next_test_data(uint16_t portId, uint8_t data) {

	if (io_test_data.find(portId) == io_test_data.end())
		io_test_data[portId] = {};
	std::list<uint8_t>& dataPtr = io_test_data[portId];
	dataPtr.push_back(data);
}

void clear_io_test_data() {

	io_test_data.clear();
}

void test_opcode(const char* test_name, uint8_t* mem, std::vector<uint16_t>& parameters, bool print_regs = false) {

	// Create a new vector with the first REGISTERS_COUNT elements
	std::vector<uint16_t> init_data(parameters.begin(), parameters.begin() + REGISTERS_COUNT);
	std::vector<uint16_t> result_data(REGISTERS_COUNT);

	InitRegisters(init_data.data());

	// Erase the first REGISTERS_COUNT elements from the original vector
	parameters.erase(parameters.begin(), parameters.begin() + REGISTERS_COUNT);

	// Copy initial ram data
	uint16_t ram_positions_count = (parameters[0] * 2);
	// Erase ram_positions_count from parameters
	parameters.erase(parameters.begin(), parameters.begin() + 1);
	for (uint16_t i = 0; i < ram_positions_count; i += 2) {

		mem[parameters[i]] = (uint8_t)parameters[i + 1];
	}

	// Erase initial ram data so parametes will have only the last REGISTERS_COUNT elements + result ram data + port data
	parameters.erase(parameters.begin(), parameters.begin() + ram_positions_count);

	// read port data
	clear_io_test_data();
	// Copy port data
	uint16_t port_positions_count = (parameters[0] * 3);
	// Erase port_positions_count from parameters
	parameters.erase(parameters.begin(), parameters.begin() + 1);
	// init port mem
	for (uint16_t i = 0; i < port_positions_count; i += 3) {

		put_io_next_test_data(parameters[i], (uint8_t)parameters[i + 1]);
	}

	// Erase port data so parametes will have only the last REGISTERS_COUNT elements + result ram data
	parameters.erase(parameters.begin(), parameters.begin() + port_positions_count);

	// run opcode
	const uint16_t kStartAddress = 0x8000;
	int r = Z80CPU(mem, (uint8_t*)kStartAddress);

	// evaluate if is a invalid o not emulated opcode
	if (r == -1 && (test_name[0] != '0' || test_name[1] != '0')) {
		return;
	}

	GetRegisters(result_data.data());
	int errcnt = 0;
	for (int i = 0; i < init_data.size(); i++) {

		if (i == (int)wz || i == (int)ei || i == (int)p || i == (int)q)
			continue;
		if (i == (int)f) {

			// ignore undoc flags bits for the moment...
			result_data[i] = result_data[i] & 0xD7;
			parameters[i] = parameters[i] & 0xD7;
		}
		if (result_data[i] != parameters[i]) {
			printf("Error opcode %s register  %s is not equal result: %d test case: %d\n", test_name, reg_names[i], result_data[i], parameters[i]);
			errcnt++;
		}
	}

	// Erase the next REGISTERS_COUNT elements from the original vector
	parameters.erase(parameters.begin(), parameters.begin() + REGISTERS_COUNT);

	// Get initial ram data
	ram_positions_count = (parameters[0] * 2);
	// Erase ram_positions_count from parameters
	parameters.erase(parameters.begin(), parameters.begin() + 1);
	for (uint16_t i = 0; i < ram_positions_count; i += 2) {

		if (mem[parameters[i]] != parameters[i + 1]) {

			printf("Error opcode %s memory %d is not equal result: %d test case: %d\n", test_name, i, mem[parameters[i]], parameters[i + 1]);
			errcnt++;
		}
	}

	if (errcnt == 0) {

		//printf("Test passed ok!\n");
	}
	else {

		if (print_regs)
		{
			printf("--------------- Init data --------------------------\n");
			print_registers(init_data);
			printf("--------------- Result data --------------------------\n");
			print_registers(result_data);
			printf("-----------------------------------------\n");
		}
	}
}

void run_test_case(FILE* file, double kZ80CpuCycleTimeInNanoseconds, double kHostCpuCycleTimeInNanoseconds) {

	uint8_t mem[MEM_128K];

	char line[MAX_LINE_LENGTH + 1];

	// Read each line from the file
	while (fgets(line, sizeof(line), file)) {

		static int op_cnt = 0;
		++op_cnt;

		/*if (op_cnt == 0x00002329) {
			op_cnt = op_cnt;
		}*/

		std::vector<uint16_t> parameters;
		parameters.reserve((REGISTERS_COUNT * 2) + 100);
		memset(mem, 0, MEM_128K);
		char* token = strtok(line, ";");  // Split by space, tab, or newline
		char test_name[64];
		int param_cnt = 0;
		bool show_info = false;
		const char* show_test_name = "ED A2 0001";
		while (token != NULL) {
			if (param_cnt++ == 0) {

				strcpy(test_name, token);
				token = strtok(NULL, ";");

				show_info = !strcmp(test_name, show_test_name);

				continue;
			}
			char* endptr;
			parameters.push_back((unsigned int)strtoul(token, &endptr, 10));
			token = strtok(NULL, ";");
		}
		test_opcode(test_name, mem, parameters, show_info);
	}

}

void process_tests() {

	getZ80AndHostCPUFreq(kZ80CpuCycleTimeInNanoseconds, kHostCpuCycleTimeInNanoseconds);

	const std::string path = TEST_CASES_PATH;
	for (const auto& entry : std::filesystem::directory_iterator(path)) {
		if (entry.path().extension() == ".txt") {
			std::string test_path = entry.path().string().c_str();
			FILE* file = fopen(test_path.c_str(), "r");
			if (file == NULL) {
				printf("Error opening file %s.\n", test_path.c_str());
				return;
			}
			run_test_case(file, kZ80CpuCycleTimeInNanoseconds, kHostCpuCycleTimeInNanoseconds);

			fclose(file);
		}
	}

}

int main(int argc, char* argv[]) {

	process_tests();
	return 0;
}