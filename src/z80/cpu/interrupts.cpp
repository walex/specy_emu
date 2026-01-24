//#include "interrupts.h"
//#include <mutex>
//#include <semaphore>
//#include <thread>
//#include <chrono>
//
//std::mutex nmi_line_mtx;
//std::counting_semaphore<INT64_MAX>  interrupt_nmi_line(0);
//
//std::mutex mi_line_mtx;
//std::counting_semaphore<INT64_MAX> interrupt_mi_line(0);
//
//#ifdef __cplusplus
//extern "C" {
//#endif
//	void interrupts_request_nmi();
//    void interrupts_request_mi(uint8_t mode);
//#ifdef __cplusplus
//}
//#endif
//
//void interrupts_generate_request_nmi(uint64_t delay_micro_secs) {
//
//	auto now = std::chrono::high_resolution_clock::now();	
//	do {
//		interrupts_request_nmi();
//	} while (std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::high_resolution_clock::now() - now).count() < delay_micro_secs);
//}
//
//void interrupts_generate_request_mi(uint64_t delay_micro_secs, uint8_t mode) {
//
//	auto now = std::chrono::high_resolution_clock::now();
//	do {
//		interrupts_request_mi(mode);
//	} while (std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::high_resolution_clock::now() - now).count() < delay_micro_secs);
//}
//
