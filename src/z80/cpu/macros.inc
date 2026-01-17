
.code

PUSH_GPRS MACRO
    push rax
    push rcx
    push rdx
    push rbx
    push rbp
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
ENDM

POP_GPRS MACRO
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    pop rdx
    pop rcx
    pop rax
ENDM

PRINT_TEXT_MSG MACRO msg

	LOCAL _str

	.data
	_str db msg, 0
    .code

	PUSH_GPRS

    lea rcx, _str      ; RCX = const char*
    call print_text
	
	POP_GPRS

ENDM

PRINT_HEXA_8 MACRO value
	
.data
    print_hexa8 PROTO
.code

	PUSH_GPRS
	xor rcx, rcx
    mov cl, value      ; RCX = const char*
    call print_hexa8
	
	POP_GPRS

ENDM

PRINT_HEXA_16 MACRO value

.data
    print_hexa16 PROTO
.code

	PUSH_GPRS
	xor rcx, rcx
    mov cx, value      ; RCX = const char*
    call print_hexa16
	
	POP_GPRS

ENDM

PRINT_HEXA_32 MACRO value

.data
    print_hexa32 PROTO
.code

	PUSH_GPRS
	xor rcx, rcx
    mov ecx, value      ; RCX = const char*
    call print_hexa32
	
	POP_GPRS

ENDM

PRINT_HEXA_64 MACRO value

.data
    print_hexa64 PROTO
.code

	PUSH_GPRS
    mov rcx, value      ; RCX = const char*
    call print_hexa64
	
	POP_GPRS

ENDM

CopyMemToMem8 MACRO org, dest
	mov al, [org]
	mov [dest], al
ENDM

CopyMemToMem16 MACRO org, dest
	mov ax, WORD PTR [org]
	mov [dest], ax
ENDM

ProcessNextOpcode MACRO JumpTable, addr	
		
	push x_bp
	xor x_bp, x_bp
	xor x_ax, x_ax	
	mov al, [addr]             ; Select index

	shl Rec_Opcode, 8
	or Rec_Opcode, x_ax

	mov x_bp, OFFSET JumpTable ; Load the base address of the jump table into RBP
	mov x_bx, [x_bp + x_ax*PTR_SIZE]    ; Load the function address from the table
	add addr, 1
	pop x_bp
	IncRegR
	jmp x_bx

ENDM

IncRegR MACRO 

xor ax, ax
mov al, RegR
shl ax, 1
add ax, 2
shr ax, 1
mov RegR, al

ENDM

DecRegR MACRO 

xor ax, ax
mov al, RegR
shl ax, 1
sub ax, 2
shr ax, 1
mov RegR, al
	
ENDM

GetBitMask MACRO dest, args:VARARG

	LOCAL a
	push reg_tmp
	push x_ax
	mov reg_tmp, 0
    FOR a, <args>
		
		mov x_ax, 1		
		shl x_ax, a
		; OF --> PVF
		and ah, 08h
		shr ah, 1
		or al, ah
		xor ah, ah
		or reg_tmp, x_ax
	ENDM
	pop x_ax
	mov dest, reg_tmp
	pop reg_tmp
ENDM

GetBitMaskNeg MACRO dest, args:VARARG

	GetBitMask dest, args
	not dest

ENDM

ResetFlagBits MACRO args:VARARG

push x_cx
GetBitMaskNeg x_cx, args
and RegF, cl
pop x_cx

ENDM

SetFlagBits MACRO args:VARARG

push x_cx
GetBitMask x_cx, args
or RegF, cl
pop x_cx

ENDM

X86FlagsToZ80Flags MACRO args:VARARG
	
	LOCAL OF_SLICE
	OF_SLICE = OF - PVF

	push x_bx
	push x_ax
	pushf
	ResetFlagBits args
	pop ax	
	xor bx, bx
	FOR a, <args>
		
		IF a EQ OF
			mov bl, 1
			shl bl, PVF
			not bl
			and al, bl
			mov bx, ax
			and bx, 0800h
			shr bx, OF_SLICE
			or RegF, bl
		ENDIF
	
	ENDM
	GetBitMask x_bx, args
	and al, bl
	or RegF, al
	pop x_ax
	pop x_bx

ENDM

SetPVFromBC MACRO

push x_ax
ResetFlagBits PVF
mov ax, RegBC
test ax, ax
lahf
and ah, 040h
xor ah, 040h
shr ah, ZF-PVF
or RegF, ah
pop x_ax

ENDM

SetIOFlags MACRO value

push x_ax
mov al, value
test al, al
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
pop x_ax

ENDM

LoadZ80CarryFlag MACRO

push x_ax
push x_bx
GetBitMaskNeg x_bx, CF
lahf
and ah, bl
not bl
mov bh, RegF
and bh, bl
or ah, bh
sahf
pop x_bx
pop x_ax

ENDM

TestZ80Flag MACRO flag

push x_cx
GetBitMask x_cx, flag
mov ch, RegF
and ch, cl
test ch, ch
pop x_cx

ENDM

SetRegValue64 MACRO reg

xor rax, rax
mov ax, WORD PTR [rcx]
mov reg, rax
add rcx, 2

ENDM

SetRegValue16 MACRO reg

mov ax, WORD PTR [rcx]
mov reg, ax
add rcx, 2

ENDM

SetRegValue8 MACRO reg

mov ax, WORD PTR [rcx]
mov reg, al
add rcx, 2

ENDM

GetRegValue64 MACRO reg

mov rax, reg
mov WORD PTR [rcx], ax
add rcx, 2

ENDM

GetRegValue16 MACRO reg

xor rax, rax
mov ax, reg
mov WORD PTR [rcx], ax
add rcx, 2

ENDM

GetRegValue8 MACRO reg

xor rax, rax
mov al, reg
mov WORD PTR [rcx], ax
add rcx, 2

ENDM

Z80HFCarryFromBit11 MACRO memptr16_a, memptr16_b, usecf

; (((a & 0xFFF) + (b & 0xFFF)) & 0x1000) == 0x1000

ResetFlagBits HF
mov ax, WORD PTR [memptr16_a]
mov bx, WORD PTR [memptr16_b]
and ax, 0FFFh
and bx, 0FFFh
IF usecf EQ 1
push dx
xor dx, dx
mov dl, RegF
and dl, 1
add ax, dx
pop dx
ENDIF
add bx, ax
and bx, 01000h
shr bx, 8
or RegF, bl

ENDM

Z80HFBorrowFromBit12 MACRO memptr16_a, memptr16_b, usecf

; ((a & 0xFFF) - (b & 0xFFF)) & 0x1000) == 0x1000
ResetFlagBits HF
mov ax, WORD PTR [memptr16_a]
mov bx, WORD PTR [memptr16_b]
and ax, 0FFFh
and bx, 0FFFh
IF usecf EQ 1
push dx
xor dx, dx
mov dl, RegF
and dl, 1
add ax, dx
pop dx
ENDIF
sub bx, ax
and bx, 01000h
shr bx, 8
or RegF, bl

ENDM


SetIOBlockFlagsOUT MACRO reg8ptr

push x_ax
push x_bx

ResetFlagBits HF, PVF, NF, CF

; SF, ZF flags Affected by decreasing register B
mov al, RegB
test al, al
X86FlagsToZ80Flags SF, ZF

;The N flag is a copy of bit 7 of the last value read from/written too the I/O port
mov al, [reg8ptr]
and al, 080h
shr al, SF-NF
or RegF, al

; HF and CF Both set if ((HL) + L > 255)
xor x_ax, x_ax
xor x_bx, x_bx
mov al, [reg8ptr]
mov bl, RegL
add ax, bx
and ax, 0FF00h
test ah, ah
lahf
and ah, 040h
xor ah, 040h
shr ah, ZF-CF
or RegF, ah
shl ah, HF-CF
or RegF, ah

;PF The parity of ((((HL) + L) & 7) xor B)
xor x_ax, x_ax
xor x_bx, x_bx
mov al, [reg8ptr]
mov bl, RegL
add ax, bx
and ax, 07h
mov bl, RegB
xor ax, bx
lahf
and ah, 04h
or RegF, ah

pop x_bx
pop x_ax

ENDM

SetIOBlockFlagsIN MACRO reg8ptr, incdec

push x_ax
push x_bx

ResetFlagBits HF, PVF, NF, CF

; SF, ZF flags Affected by decreasing register B
mov al, RegB
test al, al
X86FlagsToZ80Flags SF, ZF

;The N flag is a copy of bit 7 of the last value read from/written too the I/O port
mov al, [reg8ptr]
and al, 080h
shr al, SF-NF
or RegF, al

;HF and CF Both set if ((HL) + ((C +/- 1) & 255) > 255)
xor x_ax, x_ax
xor x_bx, x_bx
mov al, [reg8ptr]
mov bl, RegC
add bl, incdec
add ax, bx
and ax, 0FFh
and ax, 0FF00h
test ah, ah
lahf
and ah, 040h
xor ah, 040h
shr ah, ZF-CF
or RegF, ah
shl ah, HF-CF
or RegF, ah

;PF The parity of (((HL) + ((C +/- 1) & 255)) & 7) xor B)
xor x_ax, x_ax
mov al, [reg8ptr]
add al, RegC
add al, incdec
and al, 0FFh
and al, 07h
xor al, RegB
lahf
and ah, 04h
or RegF, ah

pop x_bx
pop x_ax

ENDM


CALL_C_FUNC MACRO func_name

push reg_pc
sub rsp, 40
call func_name
add rsp, 40
pop reg_pc

ENDM

SetYFXFByRegAQ MACRO

; YF . XF = (Q ^ F) | A
GetBitMask x_cx, YF, XF
push ax
mov al, RegQ
xor al, RegF
or al, RegA
and al, cl
or RegF, al
pop ax

ENDM

SetXFYFFromReg8 MACRO reg8
	
    ResetFlagBits XF, YF
	push ax
	mov al, reg8
	and al, 28h
	or RegF, al
	pop ax

ENDM


SetXFYFForLDIx MACRO reg8

push x_ax
mov al, reg8
add al, RegA
ResetFlagBits YF, XF
push ax
GetBitMask x_cx, 01h
and al, cl
shl al, YF - 01h
or RegF, al
pop ax
GetBitMask x_cx, 03h
and al, cl
or RegF, al
pop x_ax

ENDM

SetXFYFForCPIx MACRO reg8

push x_ax
mov al, RegA ; Take the value of register A
sub al, reg8  ;  subtract the value of (HL)
; subtract the value of HF flag
GetBitMask x_cx, HF ; get flag index
mov ah, RegF ; copy flags register to ah
and ah, cl   ; extract H flag
shr ah, HF ; mov flag to bit 0
sub al, ah ; substract H flag from value
ResetFlagBits YF, XF ; reset undoc flags
GetBitMask x_cx, 01h
push ax
and al, cl ; get bit 1 from value
shl al, YF - 01h ; move to YF position
or RegF, al ; copy to flags register
pop ax
GetBitMask x_cx, 03h 
and al, cl ; get bit 3 value
or RegF, al ;copy to flags register
pop x_ax

ENDM

SET_WZ_FROM_VALUE_16 MACRO v16

push di
mov di, v16
mov RegWZ, di
pop di

ENDM

SET_WZ_FROM_NN_ADDRESS MACRO memPtr

invoke immediate_addressing_mode_ext,memPtr
SET_WZ_FROM_VALUE_16 WORD PTR[reg_di]

ENDM

SET_WZ_FROM_VALUE_16_AND_INC MACRO v16

	SET_WZ_FROM_VALUE_16 v16
	inc RegWZ

ENDM

SET_WZ_FROM_REG_PC MACRO memPtr

push x_ax
mov x_ax, reg_pc
sub x_ax, memPtr
mov RegWZ, ax
pop x_ax

ENDM

INC_WZ MACRO

inc RegWZ

ENDM

DEC_WZ MACRO

dec RegWZ

ENDM

SET_WZ_FROM_REG8_AND_VALUE16 MACRO reg8, v16

; wz = (reg8 << 8) | ((v16 + 1) & 0xFF);
push x_ax
xor ax, ax
mov ah, reg8
mov bx, v16
inc bx
and bx, 0FFh
or ax, bx
SET_WZ_FROM_VALUE_16 ax
pop x_ax

ENDM

SET_WZ_FROM_REG8_AND_VALUE8 MACRO reg8, v8

; wz = (reg8 << 8) | ((v8 + 1) & 0xFF);
push x_ax
xor ax, ax
xor bx, bx
mov ah, reg8
mov bl, v8
inc bx
and bx, 0FFh
or ax, bx
SET_WZ_FROM_VALUE_16 ax
pop x_ax

ENDM

SET_WZ_FROM_A_AND_VALUE16 MACRO v16

; wz = (z->a << 8) | ((v16 + 1) & 0xFF);

SET_WZ_FROM_REG8_AND_VALUE16 RegA, v16


ENDM

SET_WZ_FROM_A_AND_VALUE8 MACRO v8

; wz = (z->a << 8) | ((v16 + 1) & 0xFF);

SET_WZ_FROM_REG8_AND_VALUE8 RegA, v16

ENDM

SET_WZ_FROM_PORT_AND_VALUE8 MACRO port, v8

; wz = (port + 1) | (z->a << 8);

push x_ax
mov al, port
inc al
mov ah, v8
SET_WZ_FROM_VALUE_16 ax
pop x_ax

ENDM
