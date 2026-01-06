#include <stdio.h>
#include <stdint.h>

extern void __stdcall print_text(const char* str) {
	printf("%s\n", str);
}

extern void __stdcall print_hexa8(uint8_t value) {
	printf("%x\n", value);
}

extern void __stdcall print_hexa16(uint16_t value) {
	printf("%x\n", value);
}

extern void __stdcall print_hexa32(uint32_t value) {
	printf("%x\n", value);
}

extern void __stdcall print_hexa64(uint64_t value) {

	printf("%llx\n", value);
}