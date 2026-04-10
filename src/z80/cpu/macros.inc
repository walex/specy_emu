.data
EXTERNDEF check_contained_memory_c:PROC
EXTERNDEF print_opcode:PROC
.code

CopyMemToMem8 MACRO org, dest
	mov x_a8l, [org]
	mov [dest], x_a8l
ENDM

CopyMemToMem16 MACRO org, dest
	mov x_a16, WORD PTR [org]
	mov [dest], x_a16
ENDM

IncRegR MACRO 

;  z->r = (z->r & 0x80) | ((z->r + 1) & 0x7f);
mov x_a8l, RegR
mov x_a8h, RegR
and x_a8l, 080h
inc x_a8h
and x_a8h, 07Fh
or x_a8l, x_a8h
mov RegR, x_a8l

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
		and x_a8h, 08h
		shr x_a8h, 1
		or x_a8l, x_a8h
		xor x_a8h, x_a8h
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
and RegF, x_c8l
pop x_cx

ENDM

SetFlagBits MACRO args:VARARG

push x_cx
GetBitMask x_cx, args
or RegF, x_c8l
pop x_cx

ENDM

X86FlagsToZ80Flags MACRO args:VARARG
	
	LOCAL OF_SLICE
	OF_SLICE = OF - PVF

	push x_bx
	push x_ax
	pushf
	ResetFlagBits args
	pop x_a16	
	xor x_b16, x_b16
	FOR a, <args>		
		IF a EQ OF
			mov x_b8l, 1
			shl x_b8l, PVF
			not x_b8l
			and x_a8l, x_b8l
			mov x_b16, x_a16
			and x_b16, 0800h
			shr x_b16, OF_SLICE
			or RegF, x_b8l
		ENDIF	
	ENDM
	GetBitMask x_bx, args
	and x_a8l, x_b8l
	or RegF, x_a8l
	pop x_ax
	pop x_bx

ENDM

SetPVFromBC MACRO

push x_ax
ResetFlagBits PVF
mov x_a16, RegBC
test x_a16, x_a16
lahf
and x_a8h, 040h
xor x_a8h, 040h
shr x_a8h, ZF-PVF
or RegF, x_a8h
pop x_ax

ENDM

SetIOFlags MACRO value

push x_ax
mov x_a8l, value
test x_a8l, x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
pop x_ax

ENDM

LoadZ80CarryFlag MACRO

push x_ax
push x_bx
GetBitMaskNeg x_bx, CF
lahf
and x_a8h, x_b8l
not x_b8l
mov x_b8h, RegF
and x_b8h, x_b8l
or x_a8h, x_b8h
sahf
pop x_bx
pop x_ax

ENDM

TestZ80Flag MACRO flag

push x_cx
GetBitMask x_cx, flag
mov x_c8h, RegF
and x_c8h, x_c8l
test x_c8h, x_c8h
pop x_cx

ENDM


Z80HFCarryFromBit11 MACRO memptr16_a, memptr16_b, usecf

; (((a & 0xFFF) + (b & 0xFFF)) & 0x1000) == 0x1000

ResetFlagBits HF
mov x_a16, WORD PTR [memptr16_a]
mov x_b16, WORD PTR [memptr16_b]
and x_a16, 0FFFh
and x_b16, 0FFFh
IF usecf EQ 1
push x_d16
xor x_d16, x_d16
mov x_d8l, RegF
and x_d8l, 1
add x_a16, x_d16
pop x_d16
ENDIF
add x_b16, x_a16
and x_b16, 01000h
shr x_b16, 8
or RegF, x_b8l

ENDM

Z80HFBorrowFromBit12 MACRO memptr16_a, memptr16_b, usecf

; ((a & 0xFFF) - (b & 0xFFF)) & 0x1000) == 0x1000
ResetFlagBits HF
mov x_a16, WORD PTR [memptr16_a]
mov x_b16, WORD PTR [memptr16_b]
and x_a16, 0FFFh
and x_b16, 0FFFh
IF usecf EQ 1
push x_d16
xor x_d16, x_d16
mov x_d8l, RegF
and x_d8l, 1
add x_a16, x_d16
pop x_d16
ENDIF
sub x_b16, x_a16
and x_b16, 01000h
shr x_b16, 8
or RegF, x_b8l

ENDM

SetIOBlockFlagsOUT MACRO reg8ptr

push x_ax
push x_bx

ResetFlagBits HF, PVF, NF, CF

; SF, ZF flags Affected by decreasing register B
mov x_a8l, RegB
test x_a8l, x_a8l
X86FlagsToZ80Flags SF, ZF

;The N flag is a copy of bit 7 of the last value read from/written too the I/O port
mov x_a8l, [reg8ptr]
and x_a8l, 080h
shr x_a8l, SF-NF
or RegF, x_a8l

; HF and CF Both set if ((HL) + L > 255)
xor x_ax, x_ax
xor x_bx, x_bx
mov x_a8l, [reg8ptr]
mov x_b8l, RegL
add x_a16, x_b16
and x_a16, 0FF00h
test x_a8h, x_a8h
lahf
and x_a8h, 040h
xor x_a8h, 040h
shr x_a8h, ZF-CF
or RegF, x_a8h
shl x_a8h, HF-CF
or RegF, x_a8h

;PF The parity of ((((HL) + L) & 7) xor B)
xor x_ax, x_ax
xor x_bx, x_bx
mov x_a8l, [reg8ptr]
mov x_b8l, RegL
add x_a16, x_b16
and x_a16, 07h
mov x_b8l, RegB
xor x_a16, x_b16
lahf
and x_a8h, 04h
or RegF, x_a8h

pop x_bx
pop x_ax

ENDM

SetIOBlockFlagsIN MACRO reg8ptr, incdec

push x_ax
push x_bx

ResetFlagBits HF, PVF, NF, CF

; SF, ZF flags Affected by decreasing register B
mov x_a8l, RegB
test x_a8l, x_a8l
X86FlagsToZ80Flags SF, ZF

;The N flag is a copy of bit 7 of the last value read from/written too the I/O port
mov x_a8l, [reg8ptr]
and x_a8l, 080h
shr x_a8l, SF-NF
or RegF, x_a8l

;HF and CF Both set if ((HL) + ((C +/- 1) & 255) > 255)
xor x_ax, x_ax
xor x_bx, x_bx
mov x_a8l, [reg8ptr]
mov x_b8l, RegC
add x_b8l, incdec
add x_a16, x_b16
and x_a16, 0FFh
and x_a16, 0FF00h
test x_a8h, x_a8h
lahf
and x_a8h, 040h
xor x_a8h, 040h
shr x_a8h, ZF-CF
or RegF, x_a8h
shl x_a8h, HF-CF
or RegF, x_a8h

;PF The parity of (((HL) + ((C +/- 1) & 255)) & 7) xor B)
xor x_ax, x_ax
mov x_a8l, [reg8ptr]
add x_a8l, RegC
add x_a8l, incdec
and x_a8l, 0FFh
and x_a8l, 07h
xor x_a8l, RegB
lahf
and x_a8h, 04h
or RegF, x_a8h

pop x_bx
pop x_ax

ENDM


CALL_C_FUNC MACRO func_name

sub rsp, 020h
call func_name
add rsp, 020h

ENDM

SetYFXFByRegAQ MACRO

; YF = A.5 | (YFi ^ YQi)
; XF = A.3 | (XFi ^ XQi)

ResetFlagBits YF, XF
mov x_a8l, RegA
mov x_b8l, RegF
mov x_c8l, RegQ
xor x_b8l, x_c8l
or x_a8l, x_b8l
and x_a8l, 028h
or RegF, x_a8l

ENDM

SetXFYFFromReg8 MACRO reg8
	
   ResetFlagBits XF, YF
	push x_a16
	mov x_a8l, reg8
	and x_a8l, 28h
	or RegF, x_a8l
	pop x_a16

ENDM

SetXFYFForLDxR MACRO val8

; t = val8 + A
;((t & 2) << 4) |
; (t & XF))

ResetFlagBits YF, XF
push x_cx
push x_ax
mov x_a8l, val8
add x_a8l, RegA
push x_a16
GetBitMask x_cx, 01h
and x_a8l, x_c8l
shl x_a8l, YF - 01h
or RegF, x_a8l
pop x_a16
GetBitMask x_cx, XF
and x_a8l, x_c8l
or RegF, x_a8l
pop x_ax
pop x_cx

ENDM

SetXFYFForCPIx MACRO reg8

push x_ax
mov x_a8l, RegA ; Take the value of register A
sub x_a8l, reg8  ;  subtract the value of (HL)
; subtract the value of HF flag
GetBitMask x_cx, HF ; get flag index
mov x_a8h, RegF ; copy flags register to x_a8h
and x_a8h, x_c8l   ; extract H flag
shr x_a8h, HF ; mov flag to bit 0
sub x_a8l, x_a8h ; substract H flag from value
ResetFlagBits YF, XF ; reset undoc flags
GetBitMask x_cx, 01h
push x_a16
and x_a8l, x_c8l ; get bit 1 from value
shl x_a8l, YF - 01h ; move to YF position
or RegF, x_a8l ; copy to flags register
pop x_a16
GetBitMask x_cx, 03h 
and x_a8l, x_c8l ; get bit 3 value
or RegF, x_a8l ;copy to flags register
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
	inc WORD PTR RegWZ

ENDM

SET_WZ_FROM_REG_PC MACRO memPtr

push RegPC
pop RegWZ

ENDM

SET_WZ_FROM_REG_PC_WITH_INC MACRO memPtr

SET_WZ_FROM_REG_PC
inc WORD PTR RegWZ

ENDM

INC_WZ MACRO

inc WORD PTR RegWZ

ENDM

DEC_WZ MACRO

dec WORD PTR RegWZ

ENDM

SET_WZ_FROM_REG8_AND_VALUE16 MACRO reg8, v16

; wz = (reg8 << 8) | ((v16 + 1) & 0xFF);
push x_ax
xor x_a16, x_a16
mov x_a8h, reg8
mov x_b16, v16
inc x_b16
and x_b16, 0FFh
or x_a16, x_b16
SET_WZ_FROM_VALUE_16 x_a16
pop x_ax

ENDM

SET_WZ_FROM_REG8_AND_VALUE8 MACRO reg8, v8

; wz = (reg8 << 8) | ((v8 + 1) & 0xFF);
push x_ax
xor x_a16, x_a16
xor x_b16, x_b16
mov x_a8h, reg8
mov x_b8l, v8
inc x_b16
and x_b16, 0FFh
or x_a16, x_b16
SET_WZ_FROM_VALUE_16 x_a16
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
mov x_a8l, port
inc x_a8l
mov x_a8h, v8
SET_WZ_FROM_VALUE_16 x_a16
pop x_ax

ENDM

GET_REG_PC MACRO
xor x_ax, x_ax
mov x_a16, RegPC
ENDM

STORE8 MACRO addr64, value8
mov BYTE PTR [addr64], value8
ENDM

STORE16 MACRO addr64, value16
mov WORD PTR [addr64], value16
ENDM

FETCH8 MACRO addr64
mov x_a8l, BYTE PTR [addr64]
ENDM

FETCH16 MACRO addr64
mov x_a16, WORD PTR [addr64]
ENDM

GET_REG_PC_MEM_PTR MACRO
GET_REG_PC
add x_ax, memPtr
ENDM

INC_REG_PC MACRO
inc RegPC
ENDM

DEC_REG_PC MACRO
dec RegPC
ENDM

ADD_REG_PC MACRO value16
add RegPC, value16
ENDM

SUB_REG_PC MACRO value16
sub RegPC, value16
ENDM

SET_REG_PC MACRO value16
mov RegPC, value16
ENDM

ProcessNextOpcodeFromPC MACRO opcode, JumpTable
	xor x_ax, x_ax
	mov x_a16, opcode
	mov x_cx,OFFSET JumpTable   ; Load the base address of the jump table into RBP
	mov x_bx,[x_cx + x_ax*PTR_SIZE]      ; Load the function address from the table
	jmp x_bx
ENDM

ProcessNextOpcode MACRO JumpTable
	xor x_ax, x_ax
	xor x_cx, x_cx
	mov x_c16, RegPC
	add x_cx, memPtr
	FETCH8 x_cx
	mov x_cx,OFFSET JumpTable   ; Load the base address of the jump table into RBP
	mov x_bx,[x_cx + x_ax*PTR_SIZE]      ; Load the function address from the table
	inc RegPC
	;xor x_cx, x_cx
	;mov x_c16, x_a16
	;CALL_C_FUNC print_opcode
	jmp x_bx
ENDM