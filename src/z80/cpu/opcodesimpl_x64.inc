.data

EXTERNDEF inst_OUT_Impl:PROC
EXTERNDEF inst_IN_Impl:PROC
EXTERNDEF inst_DAA_C:PROC
EXTERNDEF acumulate_opcode_cycles_c:PROC
EXTERNDEF cpu_call_opcode_notify:PROC

.code

acumulate_opcode_cycles PROC

CALL_C_FUNC acumulate_opcode_cycles_c

ret

acumulate_opcode_cycles ENDP

inst_LD8 PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx
; Reg_Dest:PTR BYTE -> x_dx

mov al,[x_cx]
mov [x_dx],al 
ret

inst_LD8 ENDP

inst_LD16 PROC

; parameters
; Reg_Ori:PTR WORD -> x_cx
; Reg_Dest:PTR WORD -> x_dx

mov ax, WORD PTR [x_cx]
mov WORD PTR [x_dx], ax
ret

inst_LD16 ENDP

inst_PUSH PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; Reg:WORD -> dx

xor x_bx,x_bx
mov bx,RegSP
add x_cx,x_bx
mov ax,dx			;ah Reg HIGH , al Reg LOW
dec x_cx			; (SP-1)
mov [x_cx],ah
dec x_cx			; (SP-2)
mov [x_cx],al
sub RegSP,2
ret

inst_PUSH ENDP

inst_POP PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; Reg: PTR WORD -> x_dx

xor x_bx,x_bx
mov bx,RegSP
add x_cx,x_bx
mov al,[x_cx]
inc x_cx			; (SP+1)
mov ah,[x_cx]
add RegSP,2
mov x_bx,x_dx
mov [x_bx],ax
ret

inst_POP ENDP

inst_EX PROC

; parameters
; Reg_Ori:PTR WORD -> x_cx
; Reg_Dest:PTR WORD -> x_dx

mov bx,WORD PTR [x_cx]
mov ax, WORD PTR[x_dx]
mov WORD PTR [x_cx],ax
mov WORD PTR [x_dx],bx 
ret

inst_EX ENDP

inst_EX8 PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx
; Reg_Dest:PTR BYTE -> x_dx

mov ah, [x_cx]
mov al, [x_dx]
mov [x_cx], al
mov [x_dx], ah
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
mov al,[reg_di]
invoke register_indirect_addressing_mode,x_cx,RegDE
mov [reg_di],al
inc RegDE
inc RegHL
dec RegBC
SetPVFromBC
ResetFlagBits HF, NF
ret

inst_LDI ENDP

inst_LDIR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

cmp RegBC, 0
jnz LDIR_start
mov RegBC, 0FFFFh
LDIR_start:
invoke inst_LDI, x_cx
cmp RegBC, 0
jz LDIR_end
sub reg_pc, 2
invoke acumulate_opcode_cycles, 21,5
jmp LDIR_exit
LDIR_end:
invoke acumulate_opcode_cycles, 16,4
LDIR_exit:
ret

inst_LDIR ENDP

inst_LDD PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode,x_cx,RegHL
mov al,[reg_di]
invoke register_indirect_addressing_mode,x_cx,RegDE
mov [reg_di],al
dec RegDE
dec RegHL
dec RegBC
SetPVFromBC
ResetFlagBits HF, NF
ret

inst_LDD ENDP

inst_LDDR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

cmp RegBC, 0
jnz LDDR_start
mov RegBC, 0FFFFh
LDDR_start:
invoke inst_LDD, x_cx
cmp RegBC, 0
jz LDDR_end
sub reg_pc, 2
invoke acumulate_opcode_cycles, 21,5
jmp LDDR_exit
LDDR_end:
invoke acumulate_opcode_cycles, 16,4
LDDR_exit:
ret

inst_LDDR ENDP

inst_CPI PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode,x_cx,RegHL
mov bl, BYTE PTR [reg_di]
cmp RegA,bl
X86FlagsToZ80Flags SF, ZF, HF
inc RegHL
dec RegBC
SetPVFromBC
SetFlagBits NF
ret

inst_CPI ENDP

inst_CPIR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

cmp RegBC, 0
jnz CPIR_start
mov RegBC, 0FFFFh
CPIR_start:
invoke inst_CPI, x_cx
TestZ80Flag ZF
jnz CPIR_end
cmp RegBC, 0
jz CPIR_end
sub reg_pc, 2
invoke acumulate_opcode_cycles, 21,5
jmp CPIR_exit
CPIR_end:
invoke acumulate_opcode_cycles, 16,4
CPIR_exit:
ret

inst_CPIR ENDP

inst_CPD PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode,x_cx,RegHL
mov bl, BYTE PTR [reg_di]
dec RegHL
dec RegBC
cmp RegA,bl
X86FlagsToZ80Flags SF, ZF, HF
SetPVFromBC
SetFlagBits NF
ret

inst_CPD ENDP

inst_CPDR PROC

; parameters
; memPtr:PTR BYTE -> x_cx


cmp RegBC, 0
jnz CPDR_start
mov RegBC, 0FFFFh
CPDR_start:
invoke inst_CPD, x_cx
TestZ80Flag ZF
jnz CPDR_end
cmp RegBC, 0
jz CPDR_end
sub reg_pc, 2
invoke acumulate_opcode_cycles, 21,5
jmp CPDR_exit
CPDR_end:
invoke acumulate_opcode_cycles, 16,4
CPDR_exit:
ret

inst_CPDR ENDP

inst_ADD8 PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx

mov al,[x_cx]	
add RegA, al
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
ResetFlagBits NF
ret

inst_ADD8 ENDP

inst_ADC8 PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx

mov al,[x_cx]	
LoadZ80CarryFlag
adc RegA, al
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
ResetFlagBits NF
ret

inst_ADC8 ENDP

inst_SUB PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx

mov al,[x_cx]	
sub RegA,al
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
SetFlagBits NF
ret

inst_SUB ENDP

inst_SBC8 PROC

; parameters
; Reg_Ori:PTR BYTE -> x_cx

LoadZ80CarryFlag
mov al,[x_cx]	
sbb RegA, al
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
SetFlagBits NF
ret

inst_SBC8 ENDP

inst_AND PROC

; parameters
; Valor:BYTE -> cl

ResetFlagBits SF, ZF, NF, PVF, CF
and RegA,cl
X86FlagsToZ80Flags SF, ZF, PVF
SetFlagBits HF
mov al, RegF
ret

inst_AND ENDP

inst_OR PROC

; parameters
; Valor:BYTE -> cl

ResetFlagBits SF, ZF, HF, NF, PVF, CF
or RegA,cl
X86FlagsToZ80Flags SF, ZF, PVF
ret

inst_OR ENDP

inst_XOR PROC

; parameters
; Valor:BYTE -> cl

xor RegA,cl		
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF, CF
ret

inst_XOR ENDP

inst_CP PROC

; parameters
; Reg:PTR BYTE -> x_cx

mov al,[x_cx]
cmp RegA,al
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
SetFlagBits NF
ret

inst_CP ENDP

inst_INC8 PROC

; parameters
; Reg_Dest:PTR BYTE -> x_cx

inc BYTE PTR [x_cx]
X86FlagsToZ80Flags SF, ZF, HF, OF
ResetFlagBits NF
ret

inst_INC8 ENDP

inst_DEC8 PROC

; parameters
; Reg_Dest:PTR BYTE -> x_cx

dec BYTE PTR [x_cx]
X86FlagsToZ80Flags SF, ZF, HF, OF
SetFlagBits NF
ret

inst_DEC8 ENDP

inst_DAA PROC

mov rcx, OFFSET RegA
mov rdx, OFFSET RegF
CALL_C_FUNC inst_DAA_C

ret

inst_DAA ENDP

inst_CPL PROC

not RegA
SetFlagBits HF, NF
ret

inst_CPL ENDP

inst_NEG PROC

neg RegA
X86FlagsToZ80Flags SF, ZF, HF, OF, CF
SetFlagBits NF
ret

inst_NEG ENDP

inst_CCF PROC

mov dl, RegF
and dl, 1
shl dl, HF
ResetFlagBits HF, NF, XF, YF
xor RegF, 1

; undoc flags
mov al, RegA
and al, 028h
or al, dl
or RegF, al
ret

inst_CCF ENDP

inst_SCF PROC

ResetFlagBits HF, NF, XF, YF
SetFlagBits CF

; undoc flags
mov al, RegA
and al, 028h
or RegF, al
ret

inst_SCF ENDP

inst_ADD16 PROC

; parameters
; Reg_Ori:PTR WORD -> x_cx
; Reg_Dest:PTR WORD -> x_dx

Z80HFCarryFromBit11 x_cx, x_dx, 0
mov bx, WORD PTR [x_cx]
add WORD PTR [x_dx],bx
X86FlagsToZ80Flags CF
ResetFlagBits NF
ret

inst_ADD16 ENDP

inst_ADC16 PROC

; parameters
; Reg_Ori:PTR WORD -> x_cx

mov x_dx, OFFSET RegHL
Z80HFCarryFromBit11 x_cx, x_dx, 1
LoadZ80CarryFlag
mov ax, WORD PTR [x_cx]	
adc RegHL,ax
X86FlagsToZ80Flags SF, ZF, OF, CF
ResetFlagBits NF
ret

inst_ADC16 ENDP

inst_SBC16 PROC

; parameters
; Reg_Ori:PTR WORD -> x_cx

mov x_dx, OFFSET RegHL
Z80HFBorrowFromBit12 x_cx, x_dx, 1
LoadZ80CarryFlag
mov ax,WORD PTR [x_cx]	
sbb RegHL,ax
X86FlagsToZ80Flags SF, ZF, OF, CF
SetFlagBits NF
ret

inst_SBC16 ENDP

inst_INC16 PROC

; parameters
; Reg_Dest:PTR WORD -> x_cx

inc WORD PTR [x_cx]
ret

inst_INC16 ENDP

inst_DEC16 PROC

; parameters
; Reg_Dest:PTR WORD -> x_cx

dec WORD PTR [x_cx]
ret

inst_DEC16 ENDP

inst_RLCA PROC

rol RegA,1
X86FlagsToZ80Flags CF
ResetFlagBits HF, NF
ret

inst_RLCA ENDP

inst_RLA PROC

LoadZ80CarryFlag
rcl RegA,1
X86FlagsToZ80Flags CF
ResetFlagBits HF, NF
ret

inst_RLA ENDP

inst_RRCA PROC

ror RegA,1
X86FlagsToZ80Flags CF
ResetFlagBits HF, NF
ret

inst_RRCA ENDP

inst_RRA PROC

LoadZ80CarryFlag
rcr RegA,1
X86FlagsToZ80Flags CF
ResetFlagBits HF, NF
ret

inst_RRA ENDP

inst_RLC PROC

; parameters
; Reg:PTR BYTE -> x_cx

mov bl,[x_cx]
rol bl,1
mov [x_cx],bl
X86FlagsToZ80Flags CF
test bl, bl
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
ret

inst_RLC ENDP

inst_RL PROC

; parameters
; Reg:PTR BYTE -> x_cx

LoadZ80CarryFlag
mov bl,[x_cx]
rcl bl,1
mov [x_cx],bl
X86FlagsToZ80Flags CF
test bl, bl
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
ret

inst_RL ENDP

inst_RRC PROC

; parameters
; Reg:PTR BYTE -> x_cx

mov bl,[x_cx]
ror bl,1
mov [x_cx],bl
X86FlagsToZ80Flags CF
test bl, bl
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
ret

inst_RRC ENDP

inst_RR PROC

; parameters
; Reg:PTR BYTE -> x_cx

LoadZ80CarryFlag
mov bl,[x_cx]
rcr bl,1
mov [x_cx],bl
X86FlagsToZ80Flags CF
test bl, bl
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
ret

inst_RR ENDP

inst_SLA PROC

; parameters
; Reg:PTR BYTE -> x_cx

mov bl,[x_cx]
sal bl,1
mov [x_cx],bl
X86FlagsToZ80Flags CF
test bl, bl
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
ret

inst_SLA ENDP

inst_SLL PROC

; parameters
; Reg:PTR BYTE -> x_cx
; S and Z by definition,
;H and N reset, ;
;C from bit 7, P/V set if result is even.

ResetFlagBits HF, NF, CF

mov bl,[x_cx]
mov dl, bl
and dl, 080h
shr dl, 7

sal bl,1
or bl, 1
mov [x_cx],bl
test bl, bl
X86FlagsToZ80Flags SF, ZF, PVF
or RegF, dl

ret

inst_SLL ENDP

inst_SRA PROC

; parameters
; Reg:PTR BYTE -> x_cx

mov bl,[x_cx]
sar bl,1
mov [x_cx],bl
X86FlagsToZ80Flags CF
test bl, bl
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
ret

inst_SRA ENDP

inst_SRL PROC

; parameters
; Reg:PTR BYTE -> x_cx

mov bl,[x_cx]
shr bl,1
mov [x_cx],bl
X86FlagsToZ80Flags CF
test bl, bl
X86FlagsToZ80Flags ZF, PVF
ResetFlagBits SF, HF, NF
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

xor cx, cx
mov ch, RegA ;WX
mov cl, [reg_di] ;YZ 
push cx
and ch, 0fh  ;0X
shl cl, 4	 ;Z0
or cl, ch	 ;ZX
mov [reg_di], cl
pop cx ;WX ;YZ
and ch, 0F0h ;W0
shr cl, 4 ;Y
or ch, cl ; WY
mov RegA, ch
test ch, ch
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
ret

inst_RLD ENDP

inst_RRD PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode,x_cx,RegHL		

xor cx, cx
mov cl, [reg_di]
mov ch, cl
and cl, 0fh	 ; low (HL)
and ch, 0f0h  ; high (HL)		 

xor ax, ax
mov al, RegA
mov ah, al
and al, 0fh ; low A
and ah, 0f0h ; high A

; NEW A
or cl, ah
mov RegA, cl

; new (HL)
shl al, 4
shr ch, 4
or al, ch
mov [reg_di], al

test cl, cl
X86FlagsToZ80Flags SF, ZF, PVF
ResetFlagBits HF, NF
ret

inst_RRD ENDP

inst_BIT PROC

; parameters
; Reg:PTR BYTE -> x_cx
; Idx:BYTE -> dl


ResetFlagBits SF, ZF, NF, PVF
SetFlagBits HF

xor  ax, ax
mov al, [x_cx]
mov bl, al
mov cl, dl
GetBitMask x_cx, cl
and al, cl
xor al, cl
mov cl, dl
shr al, cl
shl al, ZF
or RegF, al
; undoc PVF behaviour
shr al, ZF-PVF
or RegF, al
; undoc SF behaviour
mov cl, dl
sub dl, 7
GetBitMask x_cx, cl
and bl, cl
xor bl, cl
add dl, bl
lahf
GetBitMask x_cx, ZF
and ah, cl
shl ah, SF-ZF
or RegF, ah
ret

inst_BIT ENDP

inst_SET PROC

; parameters
; Reg:PTR BYTE -> x_cx
; Idx:BYTE -> dl

push x_cx
mov cl, dl
GetBitMask x_cx, cl
mov dl, cl
pop x_cx
or [x_cx], dl
ret

inst_SET ENDP

inst_RES PROC

; parameters
; Reg:PTR BYTE -> x_cx
; Idx:BYTE -> dl

push x_cx
mov cl, dl
GetBitMaskNeg x_cx, cl
mov dl, cl
pop x_cx
and [x_cx], dl
ret

inst_RES ENDP

inst_JP PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; dir:WORD -> dx

xor x_bx,x_bx
mov x_ax,x_cx
mov bx,dx
add x_ax,x_bx
mov reg_pc,x_ax
ret

inst_JP ENDP

inst_CALL PROC

; parameters 
; memPtr:PTR BYTE -> x_cx
; dir: WORD -> dx

xor x_bx,x_bx
xor x_ax,x_ax
mov x_ax,x_cx
sub reg_pc,x_cx
mov bx,RegSP
add x_cx,x_bx
dec x_cx
push x_dx
mov x_dx, reg_pc
mov [x_cx],dh
dec x_cx
mov [x_cx],dl
sub bx,2
mov RegSP,bx
xor x_bx,x_bx
pop x_dx
mov bx,dx
add x_ax,x_bx
mov reg_pc,x_ax

mov cx, bx
CALL_C_FUNC cpu_call_opcode_notify

ret

inst_CALL ENDP

inst_RET PROC

; parameters
; memPtr:PTR BYTE -> x_cx

xor x_bx,x_bx
xor x_ax,x_ax
mov reg_pc,x_cx
mov bx,RegSP
add x_cx,x_bx
mov al,[x_cx]
inc x_cx
mov ah,[x_cx]
add reg_pc,x_ax
add RegSP,2
ret

inst_RET ENDP

inst_RST PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; dir:BYTE -> dl

push x_dx
mov x_dx, reg_pc
xor x_bx,x_bx
xor x_ax,x_ax
mov x_ax,x_cx
sub reg_pc,x_cx
mov bx,RegSP
add x_cx,x_bx
dec x_cx
mov x_dx, reg_pc
mov [x_cx],dh
dec x_cx
mov [x_cx],dl
sub bx,2
mov RegSP,bx
xor x_bx,x_bx
pop x_dx
mov bl,dl
add x_ax,x_bx
mov reg_pc,x_ax
ret

inst_RST ENDP

inst_IN PROC 

; parameters
; port:WORD -> cx
; dest:PTR BYTE -> x_dx


CALL_C_FUNC inst_IN_Impl

ret

inst_IN ENDP

INST_INI PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode, x_cx, RegHL 
invoke INST_IN, RegBC, reg_di
inc RegHL
dec RegB
SetIOBlockFlagsIN reg_di, 1
ret

INST_INI ENDP

INST_INIR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

INIR_start:
invoke INST_INI, x_cx
cmp RegB, 0
jz INIR_end
sub reg_pc, 2
invoke acumulate_opcode_cycles, 21,5
jmp INIR_exit
INIR_end:
invoke acumulate_opcode_cycles, 16,4
INIR_exit:
ret

INST_INIR ENDP

INST_IND PROC 

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode, x_cx, RegHL 
invoke INST_IN, RegBC, reg_di
dec RegHL
dec RegB
SetIOBlockFlagsIN reg_di, 0ffh
ret

INST_IND ENDP

INST_INDR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

INDR_start:
invoke INST_IND, x_cx
cmp RegB, 0
jz INDR_end
sub reg_pc, 2
invoke acumulate_opcode_cycles, 21,5
jmp INDR_exit
INDR_end:
invoke acumulate_opcode_cycles, 16,4
INDR_exit:
ret

INST_INDR ENDP

inst_OUT PROC

; parameters
; port:WORD -> cx
; value:BYTE -> dl

CALL_C_FUNC inst_OUT_Impl, cx, dl

ret

inst_OUT ENDP

INST_OUTI PROC 

; parameters
; memPtr:PTR BYTE  -> x_cx

invoke register_indirect_addressing_mode, x_cx, RegHL
dec RegB
invoke INST_OUT, RegBC, dl	 
inc RegHL
mov Reg_Tmp8, dl
mov x_cx, OFFSET Reg_Tmp8
SetIOBlockFlagsOUT x_cx
ret

INST_OUTI ENDP

INST_OTIR PROC

; parameters
; memPtr:PTR BYTE  -> x_cx

OTIR_start:
invoke INST_OUTI, x_cx
cmp RegB, 0
jz OTIR_end
sub reg_pc, 2
invoke acumulate_opcode_cycles, 21,5
jmp OTIR_exit
OTIR_end:
invoke acumulate_opcode_cycles, 16,4
OTIR_exit:
ret

INST_OTIR ENDP

INST_OUTD PROC 

; parameters
; memPtr:PTR BYTE -> x_cx

invoke register_indirect_addressing_mode, x_cx, RegHL 
dec RegB
mov dl, [reg_di]
invoke INST_OUT, RegBC, dl
dec RegHL
mov Reg_Tmp8, dl
mov x_cx, OFFSET Reg_Tmp8
SetIOBlockFlagsOUT x_cx
ret

INST_OUTD ENDP

INST_OTDR PROC

; parameters
; memPtr:PTR BYTE -> x_cx

OTDR_start:
invoke INST_OUTD, x_cx
cmp RegB, 0
jz OTDR_end
sub reg_pc, 2
invoke acumulate_opcode_cycles, 21,5
jmp OTDR_exit
OTDR_end:
invoke acumulate_opcode_cycles, 16,4
OTDR_exit:
ret

INST_OTDR ENDP

;-----------------------------------------

Noemu PROC

; parameters 
; p: WORD -> cx
ret

Noemu ENDP

Undoc PROC

; parameters 
; p: WORD -> cx
ret

Undoc ENDP

