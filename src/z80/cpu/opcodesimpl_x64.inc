.data

EXTERNDEF inst_OUT_Impl:PROC
EXTERNDEF inst_IN_Impl:PROC
EXTERNDEF inst_DAA_C:PROC
EXTERNDEF acumulate_opcode_cycles_c:PROC
EXTERNDEF acumulate_opcode_cycles_zero_c:PROC
EXTERNDEF cpu_on_call_interceptor:PROC

.code

acumulate_opcode_cycles_zero PROC

CALL_C_FUNC acumulate_opcode_cycles_zero_c
ret

acumulate_opcode_cycles_zero ENDP

acumulate_opcode_cycles PROC

CALL_C_FUNC acumulate_opcode_cycles_c
ret

acumulate_opcode_cycles ENDP

inst_LD8 PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx
; Reg_Dest:PTR BYTE -> x_dx


FETCH8 x_cx
STORE8 x_dx, x_a8l
ret

inst_LD8 ENDP

inst_LD16 PROC

; parameters
; Reg_Ori:PTR WORD -> x_cx
; Reg_Dest:PTR WORD -> x_dx

FETCH16 x_cx
STORE16 x_dx, x_a16
ret

inst_LD16 ENDP

inst_PUSH PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; Reg:WORD -> x_d16

sub RegSP,2
xor x_ax, x_ax
mov x_a16, RegSP
add x_cx, x_ax
STORE16 x_cx, x_d16
ret

inst_PUSH ENDP

inst_POP PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; Reg: PTR WORD -> x_dx

xor x_ax, x_ax
mov x_a16, RegSP
add x_cx, x_ax
FETCH16 x_cx
add RegSP,2
STORE16 x_dx, x_a16

ret

inst_POP ENDP

inst_EX PROC

; parameters
; Reg_Ori:PTR WORD -> x_cx
; Reg_Dest:PTR WORD -> x_dx

FETCH16 x_cx
mov x_b16,x_a16
FETCH16 x_dx
STORE16 x_cx, x_a16
STORE16 x_dx, x_b16
ret

inst_EX ENDP

inst_EX8 PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx
; Reg_Dest:PTR BYTE -> x_dx

FETCH8 x_cx
mov x_b8l, x_a8l
FETCH8 x_dx
STORE8 x_cx, x_a8l
STORE8 x_dx, x_b8l
ret

inst_EX8 ENDP

inst_EXX PROC

	invoke inst_EX,OFFSET RegBC_ESP,OFFSET RegBC
	invoke inst_EX,OFFSET RegDE_ESP,OFFSET RegDE
	invoke inst_EX,OFFSET RegHL_ESP,OFFSET RegHL
	ret

inst_EXX ENDP

inst_LDI PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode,x_cx,RegHL
push reg_di
invoke register_indirect_addressing_mode,x_cx,RegDE
pop reg_si
invoke inst_LD8,reg_si,reg_di
inc WORD PTR RegDE
inc WORD PTR RegHL
dec WORD PTR RegBC
SetPVFromBC
ResetFlagBits HF, NF
SetXFYFForLDxR [reg_di]
ret

inst_LDI ENDP

inst_LDIR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

LDIR_start:
push x_cx
invoke inst_LDI, x_cx
pop x_cx
cmp RegBC, 0
jz LDIR_end
SUB_REG_PC 2
invoke SetLDxRInterblockYFXF
SET_WZ_FROM_REG_PC_WITH_INC x_cx
LDIR_end:
ret

inst_LDIR ENDP

inst_LDD PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode,x_cx,RegHL
push reg_di
invoke register_indirect_addressing_mode,x_cx,RegDE
pop reg_si
invoke inst_LD8,reg_si,reg_di
dec WORD PTR RegDE
dec WORD PTR RegHL
dec WORD PTR RegBC
SetPVFromBC
ResetFlagBits HF, NF
SetXFYFForLDxR x_a8l
ret

inst_LDD ENDP

inst_LDDR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

LDDR_start:
push x_cx
invoke inst_LDD, x_cx
pop x_cx
cmp RegBC, 0
jz LDDR_end
SUB_REG_PC 2
invoke SetLDxRInterblockYFXF
SET_WZ_FROM_REG_PC_WITH_INC x_cx
LDDR_end:
ret

inst_LDDR ENDP

inst_CPI PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode,x_cx,RegHL
FETCH8 reg_di
mov x_b8l,x_a8l
cmp RegA,x_b8l
X86FlagsToZ80Flags SF, ZF, HF
inc WORD PTR RegHL
dec WORD PTR RegBC
SetPVFromBC
SetFlagBits NF
SetXFYFForCPIx x_b8l
INC_WZ
ret

inst_CPI ENDP

inst_CPIR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

CPIR_start:
invoke inst_CPI, x_cx
TestZ80Flag ZF
jnz CPIR_end
cmp RegBC, 0
jz CPIR_end
SUB_REG_PC 2
SET_WZ_FROM_REG_PC memPtr
INC_WZ
CPIR_end:
ret

inst_CPIR ENDP

inst_CPD PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode,x_cx,RegHL
FETCH8 reg_di
mov x_b8l,x_a8l
dec WORD PTR RegHL
dec WORD PTR RegBC
cmp RegA,x_b8l
X86FlagsToZ80Flags SF, ZF, HF
SetPVFromBC
SetFlagBits NF
SetXFYFForCPIx x_b8l
DEC_WZ
DEC_WZ

ret

inst_CPD ENDP

inst_CPDR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

CPDR_start:
invoke inst_CPD, x_cx
TestZ80Flag ZF
jnz CPDR_end
cmp RegBC, 0
jz CPDR_end
SUB_REG_PC 2
CPDR_end:
INC_WZ
ret

inst_CPDR ENDP

inst_ADD8 PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx

FETCH8 x_cx
add RegA, x_a8l
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
ResetFlagBits NF
SetXFYFFromReg8 RegA
ret

inst_ADD8 ENDP

inst_ADC8 PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx

FETCH8 x_cx
LoadZ80CarryFlag
adc RegA, x_a8l
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
ResetFlagBits NF
SetXFYFFromReg8 RegA
ret

inst_ADC8 ENDP

inst_SUB PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx

FETCH8 x_cx
sub RegA,x_a8l
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
SetFlagBits NF
SetXFYFFromReg8 RegA
ret

inst_SUB ENDP

inst_SBC8 PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx

LoadZ80CarryFlag
FETCH8 x_cx
sbb RegA, x_a8l
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
SetFlagBits NF
SetXFYFFromReg8 RegA
ret

inst_SBC8 ENDP

inst_AND PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx

ResetFlagBits SF, ZF, NF, PVF, CF
FETCH8 x_cx
and RegA,x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
SetFlagBits HF
SetXFYFFromReg8 RegA
ret

inst_AND ENDP

inst_OR PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx

ResetFlagBits SF, ZF, HF, NF, PVF, CF
FETCH8 x_cx
or RegA,x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
SetXFYFFromReg8 RegA
ret

inst_OR ENDP

inst_XOR PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx
		
FETCH8 x_cx
xor RegA,x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF, CF
SetXFYFFromReg8 RegA
ret

inst_XOR ENDP

inst_CP PROC

; parameters
; Reg:PTR BYTE -> x_cx

FETCH8 x_cx
cmp RegA,x_a8l
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
SetFlagBits NF
SetXFYFFromReg8 x_a8l
ret

inst_CP ENDP

inst_INC8 PROC

; parameters
; Reg_Dest:PTR BYTE -> x_cx

FETCH8 x_cx
inc x_a8l
STORE8 x_cx, x_a8l
X86FlagsToZ80Flags SF, ZF, HF, OF
ResetFlagBits NF
SetXFYFFromReg8 x_a8l
ret

inst_INC8 ENDP

inst_DEC8 PROC

; parameters
; Reg_Dest:PTR BYTE -> x_cx

FETCH8 x_cx
dec x_a8l
STORE8 x_cx, x_a8l
X86FlagsToZ80Flags SF, ZF, HF, OF
SetFlagBits NF
SetXFYFFromReg8 x_a8l
ret

inst_DEC8 ENDP

inst_DAA PROC

mov x_cx, OFFSET RegA
mov x_dx, OFFSET RegF
CALL_C_FUNC inst_DAA_C
ret

inst_DAA ENDP

inst_CPL PROC

mov x_a8l, RegA
not RegA
SetFlagBits HF, NF
SetXFYFFromReg8 RegA
ret

inst_CPL ENDP

inst_NEG PROC

neg RegA
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
SetFlagBits NF
SetXFYFFromReg8 RegA
ret

inst_NEG ENDP

inst_CCF PROC

mov x_a8l, RegF
and x_a8l, 1
shl x_a8l, HF
ResetFlagBits HF, NF
xor RegF, 1
or RegF, x_a8l
; undoc flags
SetYFXFByRegAQ
ret

inst_CCF ENDP

inst_SCF PROC

ResetFlagBits YF, HF, XF, NF, CF
SetFlagBits CF
; undoc flags
SetYFXFByRegAQ
ret

inst_SCF ENDP

inst_ADD16 PROC

; parameters
; Reg_Ori:PTR WORD -> x_cx
; Reg_Dest:PTR WORD -> x_dx


Z80HFCarryFromBit11 x_cx, x_dx, 0
FETCH16 x_cx
mov x_b16, x_a16
FETCH16 x_dx
add x_a16,x_b16
STORE16 x_dx, x_a16
X86FlagsToZ80Flags CF
ResetFlagBits NF
SetXFYFFromReg8 x_a8h
SET_WZ_FROM_VALUE_16_AND_INC x_a16
ret

inst_ADD16 ENDP

inst_ADC16 PROC

; parameters
; Reg_Ori:PTR WORD -> x_cx

mov x_dx, OFFSET RegHL
Z80HFCarryFromBit11 x_cx, x_dx, 1
LoadZ80CarryFlag
FETCH16 x_cx
adc RegHL,x_a16
X86FlagsToZ80Flags SF, ZF, OF, CF
ResetFlagBits NF
SetXFYFFromReg8 RegH
ret

inst_ADC16 ENDP

inst_SBC16 PROC

; parameters
; Reg_Ori:PTR WORD -> x_cx

push RegHL
mov x_dx, OFFSET RegHL
Z80HFBorrowFromBit12 x_cx, x_dx, 1
LoadZ80CarryFlag
FETCH16 x_cx
sbb RegHL,x_a16
X86FlagsToZ80Flags SF, ZF, OF, CF
SetFlagBits NF
SetXFYFFromReg8 RegH
pop x_a16
SET_WZ_FROM_VALUE_16_AND_INC x_a16
ret

inst_SBC16 ENDP

inst_INC16 PROC

; parameters
; Reg_Dest:PTR WORD -> x_cx

FETCH16 x_cx
inc x_a16
STORE16 x_cx, x_a16
ret

inst_INC16 ENDP

inst_DEC16 PROC

; parameters
; Reg_Dest:PTR WORD -> x_cx

FETCH16 x_cx
dec x_a16
STORE16 x_cx, x_a16
ret

inst_DEC16 ENDP

inst_RLCA PROC

rol RegA,1
X86FlagsToZ80Flags CF
ResetFlagBits HF, NF
SetXFYFFromReg8 RegA
ret

inst_RLCA ENDP

inst_RLA PROC

LoadZ80CarryFlag
rcl RegA,1
X86FlagsToZ80Flags CF
ResetFlagBits HF, NF
SetXFYFFromReg8 RegA
ret

inst_RLA ENDP

inst_RRCA PROC

ror RegA,1
X86FlagsToZ80Flags CF
ResetFlagBits HF, NF
SetXFYFFromReg8 RegA
ret

inst_RRCA ENDP

inst_RRA PROC

LoadZ80CarryFlag
rcr RegA,1
X86FlagsToZ80Flags CF
ResetFlagBits HF, NF
SetXFYFFromReg8 RegA
ret

inst_RRA ENDP

inst_RLC PROC

; parameters
; Reg:PTR BYTE -> x_cx

FETCH8 x_cx
rol x_a8l,1
STORE8 x_cx, x_a8l
X86FlagsToZ80Flags CF
test x_a8l, x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
SetXFYFFromReg8 x_a8l
ret

inst_RLC ENDP

inst_RL PROC

; parameters
; Reg:PTR BYTE -> x_cx

LoadZ80CarryFlag
FETCH8 x_cx
rcl x_a8l,1
STORE8 x_cx, x_a8l
X86FlagsToZ80Flags CF
test x_a8l, x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
SetXFYFFromReg8 x_a8l
ret

inst_RL ENDP

inst_RRC PROC

; parameters
; Reg:PTR BYTE -> x_cx

FETCH8 x_cx
ror x_a8l,1
STORE8 x_cx, x_a8l
X86FlagsToZ80Flags CF
test x_a8l, x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
SetXFYFFromReg8 x_a8l
ret

inst_RRC ENDP

inst_RR PROC

; parameters
; Reg:PTR BYTE -> x_cx

LoadZ80CarryFlag
FETCH8 x_cx
rcr x_a8l,1
STORE8 x_cx, x_a8l
X86FlagsToZ80Flags CF
test x_a8l, x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
SetXFYFFromReg8 x_a8l
ret

inst_RR ENDP

inst_SLA PROC

; parameters
; Reg:PTR BYTE -> x_cx

FETCH8 x_cx
sal x_a8l,1
STORE8 x_cx, x_a8l
X86FlagsToZ80Flags CF
test x_a8l, x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
SetXFYFFromReg8 x_a8l
ret

inst_SLA ENDP

inst_SLL PROC

; parameters
; Reg:PTR BYTE -> x_cx
; S and Z by definition,
;H and N reset, ;
;C from bit 7, P/V set if result is even.

ResetFlagBits HF, NF, CF

FETCH8 x_cx
mov x_d8l, x_a8l
and x_d8l, 080h
shr x_d8l, 7
sal x_a8l,1
or x_a8l, 1
STORE8 x_cx, x_a8l
test x_a8l, x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
or RegF, x_d8l
SetXFYFFromReg8 x_a8l
ret

inst_SLL ENDP

inst_SRA PROC

; parameters
; Reg:PTR BYTE -> x_cx

FETCH8 x_cx
sar x_a8l,1
STORE8 x_cx, x_a8l
X86FlagsToZ80Flags CF
test x_a8l, x_a8l
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
SetXFYFFromReg8 x_a8l
ret

inst_SRA ENDP

inst_SRL PROC

; parameters
; Reg:PTR BYTE -> x_cx

FETCH8 x_cx
shr x_a8l,1
STORE8 x_cx, x_a8l
X86FlagsToZ80Flags CF
test x_a8l, x_a8l
X86FlagsToZ80Flags ZF, PVF
ResetFlagBits SF, HF, NF
SetXFYFFromReg8 x_a8l
ret

inst_SRL ENDP

inst_RLD PROC

; parameters
; memPtr:PTR BYTE -> x_cx

;ld A,$WX
;ld (HL),$YZ
;RLD
; A = $WY -> 0908
; (HL) = $ZX -> 030f

invoke register_indirect_addressing_mode,x_cx,RegHL
xor x_c16, x_c16
mov x_c8h, RegA ;WX
FETCH8 reg_di
mov x_c8l, x_a8l
push x_c16
and x_c8h, 0fh  ;0X
shl x_c8l, 4	 ;Z0
or x_c8l, x_c8h	 ;ZX
STORE8 reg_di, x_c8l
pop x_c16 ;WX ;YZ
and x_c8h, 0F0h ;W0
shr x_c8l, 4 ;Y
or x_c8h, x_c8l ; WY
mov RegA, x_c8h
test x_c8h, x_c8h
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
SetXFYFFromReg8 RegA
SET_WZ_FROM_VALUE_16_AND_INC RegHL
ret

inst_RLD ENDP

inst_RRD PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode,x_cx,RegHL
xor x_c16, x_c16
FETCH8 reg_di
mov x_c8l, x_a8l
mov x_c8h, x_c8l
and x_c8l, 0fh	 ; low (HL)
and x_c8h, 0f0h  ; high (HL) 
xor x_a16, x_a16
mov x_a8l, RegA
mov x_a8h, x_a8l
and x_a8l, 0fh ; low A
and x_a8h, 0f0h ; high A
; NEW A
or x_c8l, x_a8h
mov RegA, x_c8l
; new (HL)
shl x_a8l, 4
shr x_c8h, 4
or x_a8l, x_c8h
STORE8 reg_di, x_a8l
test x_c8l, x_c8l
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
SetXFYFFromReg8 RegA
SET_WZ_FROM_VALUE_16_AND_INC RegHL
ret

inst_RRD ENDP

inst_BIT_HL PROC

; parameters
; Reg:PTR BYTE -> x_cx
; Idx:BYTE -> x_d8l

;HF flag Always set.
;NF flag Always reset.
;CF flag Unchanged.
ResetFlagBits SF, ZF, NF, PVF, XF, YF
SetFlagBits HF
FETCH8 x_cx
mov x_c8l, x_d8l
mov x_b8l, 1
shl x_b8l, x_c8l
test x_a8l, x_b8l
;ZF flag Set if the tested bit is reset.
X86FlagsToZ80Flags ZF
;PVF flag Set just like ZF flag.
test RegF, 040h
jz skip_pvf_bit
SetFlagBits PVF
jmp skip_sf_bit
skip_pvf_bit:
;SF flag Set if n = 7 and tested bit is set.
cmp x_c8l, 7
jnz skip_sf_bit
SetFlagBits SF
; P/V, Z, S set as the other BIT instructions, but the 5 and 3 flags are
; different. Okay, brace yourself. They are a copy of an internal register of
; the Z80, which is set as follows:
; 
; ADD HL,xx      (use high byte of HL, i.e. H, before the addition)
; LD r,(IX/IY+d) (use high byte of the resulting address IX/IY+d)
; JR d           (use high byte target address of the jump)
; LD r,r'	       (not affected)
; others         not tested -- any additions welcome!
skip_sf_bit:
mov x_c8h, RegW
and x_c8h, 028h
or RegF, x_c8h 
bit_exit:
ret

inst_BIT_HL ENDP

inst_BIT_IXIY PROC

; parameters
; Reg:PTR BYTE -> x_cx
; Idx:BYTE -> x_d8l

;HF flag Always set.
;NF flag Always reset.
;CF flag Unchanged.
ResetFlagBits SF, ZF, NF, PVF, XF, YF
SetFlagBits HF
FETCH8 x_cx
mov x_c8l, x_d8l
mov x_b8l, 1
shl x_b8l, x_c8l
test x_a8l, x_b8l
;ZF flag Set if the tested bit is reset.
X86FlagsToZ80Flags ZF
;PVF flag Set just like ZF flag.
test RegF, 040h
jz skip_pvf_bit
SetFlagBits PVF
jmp skip_sf_bit
skip_pvf_bit:
;SF flag Set if n = 7 and tested bit is set.
cmp x_c8l, 7
jnz skip_sf_bit
SetFlagBits SF
; flags 5 and 3 flags are a copy of bit 5 and 3 of the high
; byte of IX/IY+d (the value after the addition of d to IX or IY).
skip_sf_bit:
mov x_c16, RegWZ
and x_c8h, 028h
or RegF, x_c8h 
bit_exit:
ret

inst_BIT_IXIY ENDP

inst_BIT PROC

; parameters
; Reg:PTR BYTE -> x_cx
; Idx:BYTE -> x_d8l

;HF flag Always set.
;NF flag Always reset.
;CF flag Unchanged.
ResetFlagBits SF, ZF, NF, PVF, XF, YF
SetFlagBits HF
FETCH8 x_cx
push x_a16
mov x_c8l, x_d8l
mov x_b8l, 1
shl x_b8l, x_c8l
and x_a8l, x_b8l
;ZF flag Set if the tested bit is reset.
X86FlagsToZ80Flags ZF
;PVF flag Set just like ZF flag.
test RegF, 040h
jz skip_pvf_bit
SetFlagBits PVF
skip_pvf_bit:
; SF flag copy from result
and x_a8l, 080h
or RegF, x_a8l
; YF, XF flag copy from source
pop x_a16
and x_a8l, 028h
or RegF, x_a8l
ret

inst_BIT ENDP

inst_SET PROC

; parameters
; Reg:PTR BYTE -> x_cx
; Idx:BYTE -> x_d8l

push x_cx
mov x_c8l, x_d8l
GetBitMask x_cx, x_c8l
mov x_d8l, x_c8l
pop x_cx
FETCH8 x_cx
or x_a8l, x_d8l
STORE8 x_cx, x_a8l
ret

inst_SET ENDP

inst_RES PROC

; parameters
; Reg:PTR BYTE -> x_cx
; Idx:BYTE -> x_d8l

push x_cx
mov x_c8l, x_d8l
GetBitMaskNeg x_cx, x_c8l
mov x_d8l, x_c8l
pop x_cx
FETCH8 x_cx
and x_a8l, x_d8l
STORE8 x_cx, x_a8l
ret

inst_RES ENDP

inst_JP PROC

; parameters
; Reg:PTR BYTE -> x_cx

FETCH16 x_cx
SET_REG_PC x_a16
SET_WZ_FROM_VALUE_16 x_a16
ret

inst_JP ENDP

inst_CALL PROC

; parameters 
; memPtr:BYTE PTR -> x_cx
; dir: BYTE PTR -> x_dx

;(SP-1) <- PCh, (SP-2) <- PCl, PC <- nn

FETCH16 x_dx
mov x_d16, x_a16

push x_cx
push x_dx
mov x_c16, x_a16
CALL_C_FUNC cpu_on_call_interceptor
pop x_dx
pop x_cx

GET_REG_PC
dec RegSP
xor x_bx, x_bx
mov x_b16, RegSP
add x_bx, x_cx
STORE8 x_bx, x_a8h
dec RegSP
dec x_bx
STORE8 x_bx, x_a8l
SET_REG_PC x_d16
SET_WZ_FROM_VALUE_16 x_d16
ret

inst_CALL ENDP

inst_RET PROC

; parameters
; memPtr:BYTE PTR -> x_cx

; PCl <- (SP), PCh <- (SP+1)
xor x_dx, x_dx
mov x_d16, RegSP
add x_cx, x_dx
FETCH8 x_cx
mov x_d8l, x_a8l
inc RegSP
inc x_cx
FETCH8 x_cx
mov x_d8h, x_a8l
SET_REG_PC x_d16
inc RegSP
dec x_cx
SET_WZ_FROM_REG_PC x_cx
ret

inst_RET ENDP

inst_RST PROC

; parameters
; memPtr:BYTE PTR -> x_cx
; dir:BYTE -> x_d8l

; (SP-1) <- PCh, (SP-2) <- PCl, PCh <- $00, PCl <- p)

GET_REG_PC
dec RegSP
xor x_bx, x_bx
mov x_b16, RegSP
add x_bx, x_cx
STORE8 x_bx, x_a8h
dec RegSP
dec x_bx
STORE8 x_bx, x_a8l
mov x_d8h, 0
SET_REG_PC x_d16
ret

inst_RST ENDP

inst_IN PROC 

; parameters
; port:WORD -> x_c16
; dest:PTR BYTE -> x_dx

CALL_C_FUNC inst_IN_Impl
ret

inst_IN ENDP

INST_INI PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode, x_cx, RegHL 
invoke INST_IN, RegBC, reg_di
inc WORD PTR RegHL
dec BYTE PTR RegB
SetIOBlockFlagsIN reg_di, 1
SET_WZ_FROM_VALUE_16_AND_INC RegBC

ret

INST_INI ENDP

INST_INIR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

INIR_start:
invoke INST_INI, x_cx
cmp RegB, 0
jz INIR_end
SUB_REG_PC 2
INIR_end:
ret

INST_INIR ENDP

INST_IND PROC 

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode, x_cx, RegHL 
invoke INST_IN, RegBC, reg_di
dec WORD PTR RegHL
dec BYTE PTR RegB
SetIOBlockFlagsIN reg_di, 0ffh
SET_WZ_FROM_VALUE_16 RegBC
DEC_WZ
DEC_WZ
ret

INST_IND ENDP

INST_INDR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

INDR_start:
invoke INST_IND, x_cx
cmp RegB, 0
jz INDR_end
SUB_REG_PC 2
INDR_end:
ret

INST_INDR ENDP

inst_OUT PROC

; parameters
; port:WORD -> x_c16
; value:BYTE -> x_d8l

CALL_C_FUNC inst_OUT_Impl
ret

inst_OUT ENDP

INST_OUTI PROC 

; parameters
; memPtr:PTR BYTE  -> x_cx

invoke register_indirect_addressing_mode, x_cx, RegHL
dec BYTE PTR RegB
invoke INST_OUT, RegBC, x_d8l	 
inc WORD PTR RegHL
mov reg_tmp8, x_d8l
mov x_cx, OFFSET reg_tmp8
SetIOBlockFlagsOUT x_cx
SET_WZ_FROM_VALUE_16_AND_INC RegBC
ret

INST_OUTI ENDP

INST_OTIR PROC

; parameters
; memPtr:PTR BYTE  -> x_cx

OTIR_start:
invoke INST_OUTI, x_cx
cmp RegB, 0
jz OTIR_end
SUB_REG_PC 2
OTIR_end:
ret

INST_OTIR ENDP

INST_OUTD PROC 

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode, x_cx, RegHL 
dec BYTE PTR RegB
mov x_d8l, [reg_di]
invoke INST_OUT, RegBC, x_d8l
dec WORD PTR RegHL
mov reg_tmp8, x_d8l
mov x_cx, OFFSET reg_tmp8
SetIOBlockFlagsOUT x_cx
SET_WZ_FROM_VALUE_16 RegBC
DEC_WZ
DEC_WZ

ret

INST_OUTD ENDP

INST_OTDR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

OTDR_start:
invoke INST_OUTD, x_cx
cmp RegB, 0
jz OTDR_end
SUB_REG_PC 2
OTDR_end:
ret

INST_OTDR ENDP

inst_DJNZ PROC 

dec BYTE PTR RegB
jnz inst_DJNZ_bnz
INC_REG_PC
jmp inst_DJNZ_exit
inst_DJNZ_bnz:
invoke relative_addressing_mode
inst_DJNZ_exit:
ret

inst_DJNZ ENDP

;-----------------------------------------

Noemu PROC

; parameters 
; p: WORD -> x_c16
ret

Noemu ENDP

Undoc PROC

; parameters 
; p: WORD -> x_c16
ret

Undoc ENDP

