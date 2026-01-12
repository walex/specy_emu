
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
	jmp x_bx

ENDM

IncRegR MACRO 

mov al,RegR
mov ah,al
and al,80h
inc ah
and ah,7fh
or al,ah
mov RegR,al
	
ENDM

GetBitMask MACRO dest, args:VARARG

	LOCAL a
	push Reg_Tmp
	push x_ax
	mov Reg_Tmp, 0
    FOR a, <args>
		
		mov x_ax, 1		
		shl x_ax, a
		; OF --> PVF
		and ah, 08h
		shr ah, 1
		or al, ah
		xor ah, ah
		or Reg_Tmp, x_ax
	ENDM
	pop x_ax
	mov dest, Reg_Tmp
	pop Reg_Tmp
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

ResetFlagBits PVF
mov ax, RegBC
test ax, ax
lahf
and ah, 040h
xor ah, 040h
shr ah, ZF-PVF
or RegF, ah

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