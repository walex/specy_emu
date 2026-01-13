#include <stdio.h>
#include <stdint.h>

extern void print_text(const char* str) {
	printf("%s\n", str);
}

extern void print_hexa8(uint8_t value) {
	printf("%x\n", value);
}

extern void print_hexa16(uint16_t value) {
	printf("%x\n", value);
}

extern void print_hexa32(uint32_t value) {
	printf("%x\n", value);
}

extern void print_hexa64(uint64_t value) {

	printf("%llx\n", value);
}