#include <stdio.h>

extern void __stdcall print_text(const char* str) {
	printf("%s\n", str);
}

extern void __stdcall print_hexa8(unsigned char value) {
	printf("%x\n", value);
}

extern void __stdcall print_hexa16(unsigned short value) {
	printf("%x\n", value);
}

extern void __stdcall print_hexa32(unsigned long value) {
	printf("%x\n", value);
}

extern void __stdcall print_hexa64(unsigned __int64 value) {

	printf("%llx\n", value);
}