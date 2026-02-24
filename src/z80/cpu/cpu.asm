;https://ps4star.github.io/z80studio/
;https://clrhome.org/table/
.code

ProcessNextOpcode MACRO JumpTable
	xor x_ax, x_ax
	xor x_cx, x_cx
	mov cx, RegPC
	add x_cx, memPtr
	FETCH8 x_cx
	mov x_cx,OFFSET JumpTable   ; Load the base address of the jump table into RBP
	mov x_bx,[x_cx + x_ax*PTR_SIZE]      ; Load the function address from the table
	inc RegPC
	jmp x_bx
ENDM

.data

BYTE_PTR TYPEDEF PTR BYTE
memPtr BYTE_PTR 0
memPtrAlt BYTE_PTR 0

include x64_arch.inc
include invoke.inc
include macros.inc
include cpuregs.inc
include bitops_x64.inc
include dirs_x64.inc
include opcodesimpl_x64.inc
include interrupts.inc

.code

cpu_z80_init PROC
; params
; mem:PTR BYTE -> rcx
; pc init value: PTR BYTE -> rdx

mov memPtr,rcx
mov memPtrAlt,rcx
ADD_REG_PC dx
invoke interrupts_set_im,0

cpu_z80_init ENDP

cpu_z80_step PROC

.data

include opcodesdef.inc

.code

Z80Init:
	mov al,reg_f_ant
	mov ah,RegF
	mov reg_f_ant,ah
	test al,ah
	jz ResetRegQ
	mov RegQ,ah
	jmp AfterRegQ
Z80Halt:
	jmp Op00
ResetRegQ:
	mov RegQ,0
AfterRegQ:
	mov x_cx,memPtr
	invoke interrupts_accept
	cmp HALT,1
	jz Z80Halt
	IncRegR
	ProcessNextOpcode _TOp1B
Op00:
   ; NOP cycles: 4
	nop
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op01:
   ; LD BC,NN cycles: 10
	invoke immediate_addressing_mode_ext,memPtr
	invoke inst_LD16,reg_di,OFFSET RegBC
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
Op02:
   ; LD (BC),A cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegBC
	invoke inst_LD8,OFFSET RegA,reg_di
	SET_WZ_FROM_A_AND_VALUE16 RegBC
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op03:
   ; INC BC cycles: 6
	invoke inst_INC16,OFFSET RegBC
	invoke acumulate_opcode_cycles,6
	jmp Z80StepEnd
Op04:
   ; INC B cycles: 4
	invoke inst_INC8,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op05:
   ; DEC B cycles: 4
	invoke inst_DEC8,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op06:
   ; LD B,N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op07:
   ; RLCA cycles: 4
	invoke inst_RLCA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op08:
   ; EX AF,AF' cycles: 4
	invoke inst_EX,OFFSET RegAF_ESP,OFFSET RegAF
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op09:
   ; ADD HL,BC cycles: 11
	invoke inst_ADD16,OFFSET RegBC,OFFSET RegHL
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
Op0A:
   ; LD A,(BC) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegBC
	invoke inst_LD8,reg_di,OFFSET RegA
	SET_WZ_FROM_VALUE_16_AND_INC RegBC
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op0B:
   ; DEC BC cycles: 6
	invoke inst_DEC16,OFFSET RegBC
	invoke acumulate_opcode_cycles,6
	jmp Z80StepEnd
Op0C:
   ; INC C cycles: 4
	invoke inst_INC8,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op0D:
   ; DEC C cycles: 4
	invoke inst_DEC8,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op0E:
   ; LD C,N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op0F:
   ; RRCA cycles: 4
	invoke inst_RRCA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op10:
   ; DJNZ D cycles: 13/8
	invoke inst_DJNZ,memPtr
	mov ax, RegBC
	shr ax,8
	invoke acumulate_opcode_cycles_zero,8,13,ax
	jmp Z80StepEnd
Op11:
   ; LD DE,NN cycles: 10
	invoke immediate_addressing_mode_ext,memPtr
	invoke inst_LD16,reg_di,OFFSET RegDE
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
Op12:
   ; LD (DE),A cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegDE
	invoke inst_LD8,OFFSET RegA,reg_di
	SET_WZ_FROM_A_AND_VALUE16 RegDE
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op13:
   ; INC DE cycles: 6
	invoke inst_INC16,OFFSET RegDE
	invoke acumulate_opcode_cycles,6
	jmp Z80StepEnd
Op14:
   ; INC D cycles: 4
	invoke inst_INC8,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op15:
   ; DEC D cycles: 4
	invoke inst_DEC8,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op16:
   ; LD D,N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op17:
   ; RLA cycles: 4
	invoke inst_RLA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op18:
   ; JR D cycles: 12
	invoke relative_addressing_mode,memPtr
	SET_WZ_FROM_REG_PC memPtr
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
Op19:
   ; ADD HL,DE cycles: 11
	invoke inst_ADD16,OFFSET RegDE,OFFSET RegHL
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
Op1A:
   ; LD A,(DE) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegDE
	invoke inst_LD8,reg_di,OFFSET RegA
	SET_WZ_FROM_VALUE_16_AND_INC RegDE
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op1B:
   ; DEC DE cycles: 6
	invoke inst_DEC16,OFFSET RegDE
	invoke acumulate_opcode_cycles,6
	jmp Z80StepEnd
Op1C:
   ; INC E cycles: 4
	invoke inst_INC8,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op1D:
   ; DEC E cycles: 4
	invoke inst_DEC8,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op1E:
   ; LD E,N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op1F:
   ; RRA cycles: 4
	invoke inst_RRA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op20:
   ; JR NZ,D cycles: 12/7
	test RegF,40h
	jz Op18
	INC_REG_PC
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op21:
   ; LD HL,NN cycles: 10
	invoke immediate_addressing_mode_ext,memPtr
	invoke inst_LD16,reg_di,OFFSET RegHL
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
Op22:
   ; LD (NN),HL cycles: 16
	invoke extended_indirect_addressing_mode,memPtr
	push di
	invoke register_indirect_addressing_mode,memPtr,di
	invoke inst_LD16,OFFSET RegHL,reg_di
	pop di
	SET_WZ_FROM_VALUE_16_AND_INC di
	invoke acumulate_opcode_cycles,16
	jmp Z80StepEnd
Op23:
   ; INC HL cycles: 6
	invoke inst_INC16,OFFSET RegHL
	invoke acumulate_opcode_cycles,6
	jmp Z80StepEnd
Op24:
   ; INC H cycles: 4
	invoke inst_INC8,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op25:
   ; DEC H cycles: 4
	invoke inst_DEC8,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op26:
   ; LD H,N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op27:
   ; DAA cycles: 4
	invoke inst_DAA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op28:
   ; JR Z,D cycles: 12/7
	test RegF,40h
	jnz Op18
	INC_REG_PC
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op29:
   ; ADD HL,HL cycles: 11
	invoke inst_ADD16,OFFSET RegHL,OFFSET RegHL
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
Op2A:
   ; LD HL,(NN) cycles: 16
	invoke extended_indirect_addressing_mode,memPtr
	push di
	add reg_di,memPtr
	invoke inst_LD16,reg_di,OFFSET RegHL
	pop di
	SET_WZ_FROM_VALUE_16_AND_INC di
	invoke acumulate_opcode_cycles,16
	jmp Z80StepEnd
Op2B:
   ; DEC HL cycles: 6
	invoke inst_DEC16,OFFSET RegHL
	invoke acumulate_opcode_cycles,6
	jmp Z80StepEnd
Op2C:
   ; INC L cycles: 4
	invoke inst_INC8,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op2D:
   ; DEC L cycles: 4
	invoke inst_DEC8,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op2E:
   ; LD L,N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op2F:
   ; CPL cycles: 4
	invoke inst_CPL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op30:
   ; JR NC,D cycles: 12/7
	test RegF,1
	jz Op18
	INC_REG_PC
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op31:
   ; LD SP,NN cycles: 10
	invoke immediate_addressing_mode_ext,memPtr
	invoke inst_LD16,reg_di,OFFSET RegSP
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
Op32:
   ; LD (NN),A cycles: 13
	invoke extended_indirect_addressing_mode,memPtr
	push di
	invoke register_indirect_addressing_mode,memPtr,di
	invoke inst_LD8,OFFSET RegA,reg_di
	pop di
	SET_WZ_FROM_A_AND_VALUE16 di
	invoke acumulate_opcode_cycles,13
	jmp Z80StepEnd
Op33:
   ; INC SP cycles: 6
	invoke inst_INC16,OFFSET RegSP
	invoke acumulate_opcode_cycles,6
	jmp Z80StepEnd
Op34:
   ; INC (HL) cycles: 11
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_INC8,reg_di
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
Op35:
   ; DEC (HL) cycles: 11
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_DEC8,reg_di
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
Op36:
   ; LD (HL),N cycles: 10
	invoke register_indirect_addressing_mode,memPtr,RegHL
	mov reg_si,reg_di
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,reg_si
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
Op37:
   ; SCF cycles: 4
	invoke inst_SCF
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op38:
   ; JR C,D cycles: 12/7
	test RegF,1
	jnz Op18
	INC_REG_PC
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op39:
   ; ADD HL,SP cycles: 11
	invoke inst_ADD16,OFFSET RegSP,OFFSET RegHL
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
Op3A:
   ; LD A,(NN) cycles: 13
	invoke extended_indirect_addressing_mode,memPtr
	SET_WZ_FROM_VALUE_16_AND_INC di
	add reg_di,memPtr
	invoke inst_LD8,reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,13
	jmp Z80StepEnd
Op3B:
   ; DEC SP cycles: 6
	invoke inst_DEC16,OFFSET RegSP
	invoke acumulate_opcode_cycles,6
	jmp Z80StepEnd
Op3C:
   ; INC A cycles: 4
	invoke inst_INC8,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op3D:
   ; DEC A cycles: 4
	invoke inst_DEC8,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op3E:
   ; LD A,N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op3F:
   ; CCF cycles: 4
	invoke inst_CCF
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op40:
   ; LD B,B cycles: 4
	invoke inst_LD8,OFFSET RegB,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op41:
   ; LD B,C cycles: 4
	invoke inst_LD8,OFFSET RegC,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op42:
   ; LD B,D cycles: 4
	invoke inst_LD8,OFFSET RegD,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op43:
   ; LD B,E cycles: 4
	invoke inst_LD8,OFFSET RegE,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op44:
   ; LD B,H cycles: 4
	invoke inst_LD8,OFFSET RegH,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op45:
   ; LD B,L cycles: 4
	invoke inst_LD8,OFFSET RegL,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op46:
   ; LD B,(HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op47:
   ; LD B,A cycles: 4
	invoke inst_LD8,OFFSET RegA,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op48:
   ; LD C,B cycles: 4
	invoke inst_LD8,OFFSET RegB,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op49:
   ; LD C,C cycles: 4
	invoke inst_LD8,OFFSET RegC,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op4A:
   ; LD C,D cycles: 4
	invoke inst_LD8,OFFSET RegD,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op4B:
   ; LD C,E cycles: 4
	invoke inst_LD8,OFFSET RegE,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op4C:
   ; LD C,H cycles: 4
	invoke inst_LD8,OFFSET RegH,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op4D:
   ; LD C,L cycles: 4
	invoke inst_LD8,OFFSET RegL,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op4E:
   ; LD C,(HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op4F:
   ; LD C,A cycles: 4
	invoke inst_LD8,OFFSET RegA,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op50:
   ; LD D,B cycles: 4
	invoke inst_LD8,OFFSET RegB,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op51:
   ; LD D,C cycles: 4
	invoke inst_LD8,OFFSET RegC,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op52:
   ; LD D,D cycles: 4
	invoke inst_LD8,OFFSET RegD,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op53:
   ; LD D,E cycles: 4
	invoke inst_LD8,OFFSET RegE,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op54:
   ; LD D,H cycles: 4
	invoke inst_LD8,OFFSET RegH,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op55:
   ; LD D,L cycles: 4
	invoke inst_LD8,OFFSET RegL,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op56:
   ; LD D,(HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op57:
   ; LD D,A cycles: 4
	invoke inst_LD8,OFFSET RegA,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op58:
   ; LD E,B cycles: 4
	invoke inst_LD8,OFFSET RegB,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op59:
   ; LD E,C cycles: 4
	invoke inst_LD8,OFFSET RegC,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op5A:
   ; LD E,D cycles: 4
	invoke inst_LD8,OFFSET RegD,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op5B:
   ; LD E,E cycles: 4
	invoke inst_LD8,OFFSET RegE,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op5C:
   ; LD E,H cycles: 4
	invoke inst_LD8,OFFSET RegH,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op5D:
   ; LD E,L cycles: 4
	invoke inst_LD8,OFFSET RegL,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op5E:
   ; LD E,(HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op5F:
   ; LD E,A cycles: 4
	invoke inst_LD8,OFFSET RegA,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op60:
   ; LD H,B cycles: 4
	invoke inst_LD8,OFFSET RegB,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op61:
   ; LD H,C cycles: 4
	invoke inst_LD8,OFFSET RegC,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op62:
   ; LD H,D cycles: 4
	invoke inst_LD8,OFFSET RegD,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op63:
   ; LD H,E cycles: 4
	invoke inst_LD8,OFFSET RegE,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op64:
   ; LD H,H cycles: 4
	invoke inst_LD8,OFFSET RegH,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op65:
   ; LD H,L cycles: 4
	invoke inst_LD8,OFFSET RegL,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op66:
   ; LD H,(HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op67:
   ; LD H,A cycles: 4
	invoke inst_LD8,OFFSET RegA,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op68:
   ; LD L,B cycles: 4
	invoke inst_LD8,OFFSET RegB,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op69:
   ; LD L,C cycles: 4
	invoke inst_LD8,OFFSET RegC,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op6A:
   ; LD L,D cycles: 4
	invoke inst_LD8,OFFSET RegD,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op6B:
   ; LD L,E cycles: 4
	invoke inst_LD8,OFFSET RegE,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op6C:
   ; LD L,H cycles: 4
	invoke inst_LD8,OFFSET RegH,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op6D:
   ; LD L,L cycles: 4
	invoke inst_LD8,OFFSET RegL,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op6E:
   ; LD L,(HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op6F:
   ; LD L,A cycles: 4
	invoke inst_LD8,OFFSET RegA,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op70:
   ; LD (HL),B cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,OFFSET RegB,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op71:
   ; LD (HL),C cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,OFFSET RegC,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op72:
   ; LD (HL),D cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,OFFSET RegD,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op73:
   ; LD (HL),E cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,OFFSET RegE,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op74:
   ; LD (HL),H cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,OFFSET RegH,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op75:
   ; LD (HL),L cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,OFFSET RegL,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op76:
   ; HALT cycles: 4
	mov HALT,1
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op77:
   ; LD (HL),A cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,OFFSET RegA,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op78:
   ; LD A,B cycles: 4
	invoke inst_LD8,OFFSET RegB,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op79:
   ; LD A,C cycles: 4
	invoke inst_LD8,OFFSET RegC,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op7A:
   ; LD A,D cycles: 4
	invoke inst_LD8,OFFSET RegD,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op7B:
   ; LD A,E cycles: 4
	invoke inst_LD8,OFFSET RegE,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op7C:
   ; LD A,H cycles: 4
	invoke inst_LD8,OFFSET RegH,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op7D:
   ; LD A,L cycles: 4
	invoke inst_LD8,OFFSET RegL,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op7E:
   ; LD A,(HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_LD8,reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op7F:
   ; LD A,A cycles: 4
	invoke inst_LD8,OFFSET RegA,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op80:
   ; ADD A,B cycles: 4
	invoke inst_ADD8,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op81:
   ; ADD A,C cycles: 4
	invoke inst_ADD8,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op82:
   ; ADD A,D cycles: 4
	invoke inst_ADD8,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op83:
   ; ADD A,E cycles: 4
	invoke inst_ADD8,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op84:
   ; ADD A,H cycles: 4
	invoke inst_ADD8,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op85:
   ; ADD A,L cycles: 4
	invoke inst_ADD8,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op86:
   ; ADD A,(HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_ADD8,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op87:
   ; ADD A,A cycles: 4
	invoke inst_ADD8,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op88:
   ; ADC A,B cycles: 4
	invoke inst_ADC8,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op89:
   ; ADC A,C cycles: 4
	invoke inst_ADC8,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op8A:
   ; ADC A,D cycles: 4
	invoke inst_ADC8,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op8B:
   ; ADC A,E cycles: 4
	invoke inst_ADC8,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op8C:
   ; ADC A,H cycles: 4
	invoke inst_ADC8,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op8D:
   ; ADC A,L cycles: 4
	invoke inst_ADC8,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op8E:
   ; ADC A,(HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_ADC8,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op8F:
   ; ADC A,A cycles: 4
	invoke inst_ADC8,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op90:
   ; SUB B cycles: 4
	invoke inst_SUB,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op91:
   ; SUB C cycles: 4
	invoke inst_SUB,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op92:
   ; SUB D cycles: 4
	invoke inst_SUB,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op93:
   ; SUB E cycles: 4
	invoke inst_SUB,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op94:
   ; SUB H cycles: 4
	invoke inst_SUB,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op95:
   ; SUB L cycles: 4
	invoke inst_SUB,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op96:
   ; SUB (HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_SUB,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op97:
   ; SUB A cycles: 4
	invoke inst_SUB,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op98:
   ; SBC A,B cycles: 4
	invoke inst_SBC8,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op99:
   ; SBC A,C cycles: 4
	invoke inst_SBC8,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op9A:
   ; SBC A,D cycles: 4
	invoke inst_SBC8,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op9B:
   ; SBC A,E cycles: 4
	invoke inst_SBC8,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op9C:
   ; SBC A,H cycles: 4
	invoke inst_SBC8,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op9D:
   ; SBC A,L cycles: 4
	invoke inst_SBC8,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
Op9E:
   ; SBC A,(HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_SBC8,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
Op9F:
   ; SBC A,A cycles: 4
	invoke inst_SBC8,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpA0:
   ; AND B cycles: 4
	invoke inst_AND,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpA1:
   ; AND C cycles: 4
	invoke inst_AND,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpA2:
   ; AND D cycles: 4
	invoke inst_AND,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpA3:
   ; AND E cycles: 4
	invoke inst_AND,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpA4:
   ; AND H cycles: 4
	invoke inst_AND,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpA5:
   ; AND L cycles: 4
	invoke inst_AND,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpA6:
   ; AND (HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_AND,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpA7:
   ; AND A cycles: 4
	invoke inst_AND,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpA8:
   ; XOR B cycles: 4
	invoke inst_XOR,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpA9:
   ; XOR C cycles: 4
	invoke inst_XOR,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpAA:
   ; XOR D cycles: 4
	invoke inst_XOR,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpAB:
   ; XOR E cycles: 4
	invoke inst_XOR,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpAC:
   ; XOR H cycles: 4
	invoke inst_XOR,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpAD:
   ; XOR L cycles: 4
	invoke inst_XOR,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpAE:
   ; XOR (HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_XOR,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpAF:
   ; XOR A cycles: 4
	invoke inst_XOR,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpB0:
   ; OR B cycles: 4
	invoke inst_OR,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpB1:
   ; OR C cycles: 4
	invoke inst_OR,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpB2:
   ; OR D cycles: 4
	invoke inst_OR,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpB3:
   ; OR E cycles: 4
	invoke inst_OR,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpB4:
   ; OR H cycles: 4
	invoke inst_OR,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpB5:
   ; OR L cycles: 4
	invoke inst_OR,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpB6:
   ; OR (HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_OR,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpB7:
   ; OR A cycles: 4
	invoke inst_OR,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpB8:
   ; CP B cycles: 4
	invoke inst_CP,OFFSET RegB
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpB9:
   ; CP C cycles: 4
	invoke inst_CP,OFFSET RegC
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpBA:
   ; CP D cycles: 4
	invoke inst_CP,OFFSET RegD
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpBB:
   ; CP E cycles: 4
	invoke inst_CP,OFFSET RegE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpBC:
   ; CP H cycles: 4
	invoke inst_CP,OFFSET RegH
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpBD:
   ; CP L cycles: 4
	invoke inst_CP,OFFSET RegL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpBE:
   ; CP (HL) cycles: 7
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_CP,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpBF:
   ; CP A cycles: 4
	invoke inst_CP,OFFSET RegA
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpC0:
   ; RET NZ cycles: 11/5
	xor ax,ax
	mov al, RegF
	and al, 40h
	jnz OpC0_exit
	invoke inst_RET,memPtr
	OpC0_exit:
	invoke acumulate_opcode_cycles_zero,5,11,ax
	jmp Z80StepEnd
OpC1:
   ; POP BC cycles: 10
	invoke inst_POP,memPtr,OFFSET RegBC
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpC2:
   ; JP NZ,NN cycles: 10
	test RegF,40h
	jz OpC3
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpC3:
   ; JP NN cycles: 10
	invoke immediate_addressing_mode_ext,memPtr
	invoke inst_JP,reg_di
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpC4:
   ; CALL NZ,NN cycles: 17/10
	test RegF,40h
	jz OpCD
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpC5:
   ; PUSH BC cycles: 11
	invoke inst_PUSH,memPtr,RegBC
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpC6:
   ; ADD A,N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_ADD8,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpC7:
   ; RST 00H cycles: 11
	invoke inst_RST,memPtr,0h
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpC8:
   ; RET Z cycles: 11/5
	xor ax,ax
	mov al, RegF
	and al, 40h
	jz OpC8_exit
	invoke inst_RET,memPtr
	OpC8_exit:
	invoke acumulate_opcode_cycles_zero,11,5,ax
	jmp Z80StepEnd
OpC9:
   ; RET cycles: 10
	invoke inst_RET,memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpCA:
   ; JP Z,NN cycles: 10
	test RegF,40h
	jnz OpC3
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpCB:
	IncRegR
	ProcessNextOpcode _TOpCB
OpCC:
   ; CALL Z,NN cycles: 17/10
	test RegF,40h
	jnz OpCD
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpCD:
   ; CALL NN cycles: 17
	invoke immediate_addressing_mode_ext,memPtr
	invoke inst_CALL,memPtr,reg_di
	invoke acumulate_opcode_cycles,17
	jmp Z80StepEnd
OpCE:
   ; ADC A,N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_ADC8,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpCF:
   ; RST 08H cycles: 11
	invoke inst_RST,memPtr,8h
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpD0:
   ; RET NC cycles: 11/5
	xor ax,ax
	mov al, RegF
	and al, 1h
	jnz OpD0_exit
	invoke inst_RET,memPtr
	OpD0_exit:
	invoke acumulate_opcode_cycles_zero,5,11,ax
	jmp Z80StepEnd
OpD1:
   ; POP DE cycles: 10
	Invoke inst_POP,memPtr,OFFSET RegDE
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpD2:
   ; JP NC,NN cycles: 10
	test RegF,1h
	jz OpC3
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpD3:
   ; OUT (N),A cycles: 11
	invoke immediate_addressing_mode,memPtr
	xor x_bx,x_bx
	mov bl,[reg_di]
	mov bh,RegA
	push bx
	invoke INST_OUT,bx,RegA
	pop bx
   ; wz = (port + 1) | (z->a << 8);
	SET_WZ_FROM_PORT_AND_VALUE8 bl,RegA
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpD4:
   ; CALL NC,NN cycles: 17/10
	test RegF,1h
	jz OpCD
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpD5:
   ; PUSH DE cycles: 11
	invoke inst_PUSH,memPtr,RegDE
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpD6:
   ; SUB N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_SUB,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpD7:
   ; RST 10H cycles: 11
	invoke inst_RST,memPtr,10h
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpD8:
   ; RET C cycles: 11/5
	xor ax,ax
	mov al, RegF
	and al, 1h
	jz OpD8_exit
	invoke inst_RET,memPtr
	OpD8_exit:
	invoke acumulate_opcode_cycles_zero,11,5,ax
	jmp Z80StepEnd
OpD9:
   ; EXX cycles: 4
	invoke inst_EXX
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpDA:
   ; JP C,NN cycles: 10
	test RegF,1h
	jnz OpC3
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpDB:
   ; IN A,(N) cycles: 11
	invoke immediate_addressing_mode,memPtr
	xor x_ax,x_ax
	mov al,[reg_di]
	mov ah,RegA
	push ax
	invoke INST_IN,ax,OFFSET RegA
	pop ax
   ; wz = (a << 8) | (z->a + 1);
	SET_WZ_FROM_REG8_AND_VALUE8 al,RegA
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpDC:
   ; CALL C,NN cycles: 17/10
	test RegF,1h
	jnz OpCD
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpDD:
	IncRegR
	ProcessNextOpcode _TOpDD
OpDE:
   ; SBC A,N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_SBC8,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpDF:
   ; RST 18H cycles: 11
	invoke inst_RST,memPtr,18h
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpE0:
   ; RET PO cycles: 11/5
	xor ax,ax
	mov al, RegF
	and al, 4h
	jnz OpE0_exit
	invoke inst_RET,memPtr
	OpE0_exit:
	invoke acumulate_opcode_cycles_zero,5,11,ax
	jmp Z80StepEnd
OpE1:
   ; POP HL cycles: 10
	invoke inst_POP,memPtr,OFFSET RegHL
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpE2:
   ; JP PO,NN cycles: 10
	test RegF,4h
	jz OpC3
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpE3:
   ; EX (SP),HL cycles: 19
	invoke register_indirect_addressing_mode,memPtr,RegSP
	invoke inst_EX,OFFSET RegHL,reg_di
	SET_WZ_FROM_VALUE_16 di
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpE4:
   ; CALL PO,NN cycles: 17/10
	test RegF,4h
	jz OpCD
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpE5:
   ; PUSH HL cycles: 11
	invoke inst_PUSH,memPtr,RegHL
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpE6:
   ; AND N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_AND,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpE7:
   ; RST 20H cycles: 11
	invoke inst_RST,memPtr,20h
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpE8:
   ; RET PE cycles: 11/5
	xor ax,ax
	mov al, RegF
	and al, 4h
	jz OpE8_exit
	invoke inst_RET,memPtr
	OpE8_exit:
	invoke acumulate_opcode_cycles_zero,11,5,ax
	jmp Z80StepEnd
OpE9:
   ; JP (HL) cycles: 4
	invoke inst_JP,OFFSET RegHL
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpEA:
   ; JP PE,NN cycles: 10
	test RegF,4h
	jnz OpC3
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpEB:
   ; EX DE,HL cycles: 4
	invoke inst_EX,OFFSET RegHL,OFFSET RegDE
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpEC:
   ; CALL PE,NN cycles: 17/10
	test RegF,4h
	jnz OpCD
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpED:
	IncRegR
	ProcessNextOpcode _TOpED
OpED00:
   ; IN0 B,(N) cycles: 12
	invoke immediate_addressing_mode,memPtr
	xor x_bx,x_bx
	mov bl,[reg_di]
	invoke INST_IN,bx,OFFSET RegB
	SetIOFlags RegB
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED01:
   ; OUT0 (N),B cycles: 13
	invoke immediate_addressing_mode,memPtr
	xor x_bx,x_bx
	mov bl,[reg_di]
	invoke INST_OUT,bx,RegB
	invoke acumulate_opcode_cycles,13
	jmp Z80StepEnd
OpED08:
   ; IN0 C,(N) cycles: 12
	invoke immediate_addressing_mode,memPtr
	xor x_bx,x_bx
	mov bl,[reg_di]
	invoke INST_IN,bx,OFFSET RegC
	SetIOFlags RegB
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED09:
   ; OUT0 (N),C cycles: 13
	invoke immediate_addressing_mode,memPtr
	xor x_bx,x_bx
	mov bl,[reg_di]
	invoke INST_OUT,bx,RegC
	invoke acumulate_opcode_cycles,13
	jmp Z80StepEnd
OpED10:
   ; IN0 D,(N) cycles: 12
	invoke immediate_addressing_mode,memPtr
	xor x_bx,x_bx
	mov bl,[reg_di]
	invoke INST_IN,bx,OFFSET RegD
	SetIOFlags RegD
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED40:
   ; IN B,(C) cycles: 12
	invoke INST_IN,RegBC,OFFSET RegB
	SetIOFlags RegB
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED41:
   ; OUT (C),B cycles: 12
	invoke INST_OUT,RegBC,RegB
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED42:
   ; SBC HL,BC cycles: 15
	invoke inst_SBC16,OFFSET RegBC
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpED43:
   ; LD (NN),BC cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	push di
	invoke register_indirect_addressing_mode,memPtr,di
	invoke inst_LD16,OFFSET RegBC,reg_di
	pop di
	SET_WZ_FROM_VALUE_16_AND_INC di
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpED44:
   ; NEG cycles: 8
	invoke inst_NEG
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpED45:
   ; RETN cycles: 14
	invoke inst_RET,memPtr
	invoke interrupts_restore
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpED46:
   ; IM 0 cycles: 8
	invoke interrupts_set_im,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpED47:
   ; LD I,A cycles: 9
	invoke inst_LD8,OFFSET RegA,OFFSET RegI
	invoke acumulate_opcode_cycles,9
	jmp Z80StepEnd
OpED48:
   ; IN C,(C) cycles: 12
	invoke INST_IN,RegBC,OFFSET RegC
	SetIOFlags RegC
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED49:
   ; OUT (C),C cycles: 12
	invoke INST_OUT,RegBC,RegC
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED4A:
   ; ADC HL,BC cycles: 15
	invoke inst_ADC16,OFFSET RegBC
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpED4B:
   ; LD BC,(NN) cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	push di
	add reg_di,memPtr
	invoke inst_LD16,reg_di,OFFSET RegBC
	pop di
	SET_WZ_FROM_VALUE_16_AND_INC di
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpED4C:
   ; MLT BC cycles: 17
	invoke inst_NEG
	invoke acumulate_opcode_cycles,17
	jmp Z80StepEnd
OpED4D:
   ; RETI cycles: 14
	invoke inst_RET,memPtr
	invoke interrupts_restore
   ; FixME: Signal an I/O device that the interrupt routine is completed
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpED4E:
   ;ED46E IM 0 8 2
	invoke interrupts_set_im,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpED4F:
   ; LD R,A cycles: 9
	invoke inst_LD8,OFFSET RegA,OFFSET RegR
	invoke acumulate_opcode_cycles,9
	jmp Z80StepEnd
OpED50:
   ; IN D,(C) cycles: 12
	invoke INST_IN,RegBC,OFFSET RegD
	SetIOFlags RegD
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED51:
   ; OUT (C),D cycles: 12
	invoke INST_OUT,RegBC,RegD
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED52:
   ; SBC HL,DE cycles: 15
	invoke inst_SBC16,OFFSET RegDE
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpED53:
   ; LD (NN),DE cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	push di
	invoke register_indirect_addressing_mode,memPtr,di
	invoke inst_LD16,OFFSET RegDE,reg_di
	pop di
	SET_WZ_FROM_VALUE_16_AND_INC di
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpED54:
   ;ED54 NEG 8 2
	invoke inst_NEG
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpED55:
   ;ED55 RETN 14 4
	invoke inst_RET,memPtr
	invoke interrupts_restore
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpED56:
   ; IM 1 cycles: 8
	invoke interrupts_set_im,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpED57:
   ; LD A,I cycles: 9
	invoke inst_LD8,OFFSET RegI,OFFSET RegA
	invoke LD_SetFlagIR,OFFSET RegI
	invoke acumulate_opcode_cycles,9
	jmp Z80StepEnd
OpED58:
   ; IN E,(C) cycles: 12
	invoke INST_IN,RegBC,OFFSET RegE
	SetIOFlags RegE
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED59:
   ; OUT (C),E cycles: 12
	invoke INST_OUT,RegBC,RegE
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED5A:
   ; ADC HL,DE cycles: 15
	invoke inst_ADC16,OFFSET RegDE
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpED5B:
   ; LD DE,(NN) cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	push di
	add reg_di,memPtr
	invoke inst_LD16,reg_di,OFFSET RegDE
	pop di
	SET_WZ_FROM_VALUE_16_AND_INC di
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpED5C:
   ; MLT DE cycles: 17
	invoke inst_NEG
	invoke acumulate_opcode_cycles,17
	jmp Z80StepEnd
OpED5D:
   ;ED5D RETN 14 4
	invoke inst_RET,memPtr
	invoke interrupts_restore
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpED5E:
   ; IM 2 cycles: 8
	invoke interrupts_set_im,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpED5F:
   ; LD A,R cycles: 9
	invoke inst_LD8,OFFSET RegR,OFFSET RegA
	invoke LD_SetFlagIR,OFFSET RegR
	invoke acumulate_opcode_cycles,9
	jmp Z80StepEnd
OpED60:
   ; IN H,(C) cycles: 12
	invoke INST_IN,RegBC,OFFSET RegH
	SetIOFlags RegH
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED61:
   ; OUT (C),H cycles: 12
	invoke INST_OUT,RegBC,RegH
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED62:
   ; SBC HL,HL cycles: 15
	invoke inst_SBC16,OFFSET RegHL
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpED63:
   ; LD (NN),HL cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	push di
	invoke register_indirect_addressing_mode,memPtr,di
	invoke inst_LD16,OFFSET RegHL,reg_di
	pop di
	SET_WZ_FROM_VALUE_16_AND_INC di
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpED64:
   ; TST N cycles: 10
	invoke inst_NEG
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpED65:
   ;ED64 RETN 14 4
	invoke inst_RET,memPtr
	invoke interrupts_restore
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpED66:
   ;ED66 IM 0 8 2
	invoke interrupts_set_im,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpED67:
   ; RRD cycles: 18
	invoke inst_RRD,memPtr
	invoke acumulate_opcode_cycles,18
	jmp Z80StepEnd
OpED68:
   ; IN L,(C) cycles: 12
	invoke INST_IN,RegBC,OFFSET RegL
	SetIOFlags RegL
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED69:
   ; OUT (C),L cycles: 12
	invoke INST_OUT,RegBC,RegL
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED6A:
   ; ADC HL,HL cycles: 15
	invoke inst_ADC16,OFFSET RegHL
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpED6B:
   ; LD HL,(NN) cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	push di
	add reg_di,memPtr
	invoke inst_LD16,reg_di,OFFSET RegHL
	pop di
	SET_WZ_FROM_VALUE_16_AND_INC di
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpED6C:
   ; MLT HL cycles: 17
	invoke inst_NEG
	invoke acumulate_opcode_cycles,17
	jmp Z80StepEnd
OpED6D:
   ;ED6D RETN 14 4
	invoke inst_RET,memPtr
	invoke interrupts_restore
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpED6E:
   ;ED6E IM 0 8 2
	invoke interrupts_set_im,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpED6F:
   ; RLD cycles: 18
	invoke inst_RLD,memPtr
	invoke acumulate_opcode_cycles,18
	jmp Z80StepEnd
OpED70:
   ; IN (C) cycles: 12
	invoke INST_IN,RegBC,OFFSET reg_tmp8
	SetIOFlags reg_tmp8
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED71:
   ; OUT (C),0 cycles: 12
	invoke INST_OUT,RegBC,RegF
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED72:
   ; SBC HL,SP cycles: 15
	invoke inst_SBC16,OFFSET RegSP
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpED73:
   ; LD (NN),SP cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	push di
	invoke register_indirect_addressing_mode,memPtr,di
	invoke inst_LD16,OFFSET RegSP,reg_di
	pop di
	SET_WZ_FROM_VALUE_16_AND_INC di
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpED74:
   ; TSTIO N cycles: 12
	invoke inst_NEG
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED75:
   ;ED75 RETN 14 4
	invoke inst_RET,memPtr
	invoke interrupts_restore
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpED76:
   ; SLP cycles: 8
	invoke interrupts_set_im,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpED78:
   ; IN A,(C) cycles: 12
	invoke INST_IN,RegBC,OFFSET RegA
	SetIOFlags RegA
	SET_WZ_FROM_VALUE_16_AND_INC RegBC
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED79:
   ; OUT (C),A cycles: 12
	invoke INST_OUT,RegBC,RegA
	SET_WZ_FROM_VALUE_16_AND_INC RegBC
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpED7A:
   ; ADC HL,SP cycles: 15
	invoke inst_ADC16,OFFSET RegSP
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpED7B:
   ; LD SP,(NN) cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	push di
	add reg_di,memPtr
	invoke inst_LD16,reg_di,OFFSET RegSP
	pop di
	SET_WZ_FROM_VALUE_16_AND_INC di
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpED7C:
   ; MLT SP cycles: 17
	invoke inst_NEG
	invoke acumulate_opcode_cycles,17
	jmp Z80StepEnd
OpED7D:
   ;ED7D RETN 14 4
	invoke inst_RET,memPtr
	invoke interrupts_restore
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpED7E:
   ;ED7E IM 2 8 2
	invoke interrupts_set_im,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpEDA0:
   ; LDI cycles: 16
	invoke inst_LDI,memPtr
	invoke acumulate_opcode_cycles,16
	jmp Z80StepEnd
OpEDA1:
   ; CPI cycles: 16
	invoke inst_CPI,memPtr
	invoke acumulate_opcode_cycles,16
	jmp Z80StepEnd
OpEDA2:
   ; INI cycles: 16
	invoke INST_INI,memPtr
	invoke acumulate_opcode_cycles,16
	jmp Z80StepEnd
OpEDA3:
   ; OUTI cycles: 16
	invoke INST_OUTI,memPtr
	invoke acumulate_opcode_cycles,16
	jmp Z80StepEnd
OpEDA8:
   ; LDD cycles: 16
	invoke inst_LDD,memPtr
	invoke acumulate_opcode_cycles,16
	jmp Z80StepEnd
OpEDA9:
   ; CPD cycles: 16
	invoke inst_CPD,memPtr
	invoke acumulate_opcode_cycles,16
	jmp Z80StepEnd
OpEDAA:
   ; IND cycles: 16
	invoke INST_IND,memPtr
	invoke acumulate_opcode_cycles,16
	jmp Z80StepEnd
OpEDAB:
   ; OUTD cycles: 16
	invoke INST_OUTD,memPtr
	invoke acumulate_opcode_cycles,16
	jmp Z80StepEnd
OpEDB0:
   ; LDIR cycles: 21/16
	invoke inst_LDIR,memPtr
	invoke acumulate_opcode_cycles_zero,16,21,RegBC ; Variable cycles 21/16
	jmp Z80StepEnd
OpEDB1:
   ; CPIR cycles: 21/16
	invoke inst_CPIR,memPtr
	invoke acumulate_opcode_cycles_zero,16,21,RegBC ; Variable cycles 21/16
	jmp Z80StepEnd
OpEDB2:
   ; INIR cycles: 21/16
	invoke INST_INIR,memPtr
	invoke acumulate_opcode_cycles_zero,16,21,RegBC ; Variable cycles 21/16
	jmp Z80StepEnd
OpEDB3:
   ; OTIR cycles: 21/16
	invoke INST_OTIR,memPtr
	invoke acumulate_opcode_cycles_zero,16,21,RegBC ; Variable cycles 21/16
	jmp Z80StepEnd
OpEDB8:
   ; LDDR cycles: 21/16
	invoke inst_LDDR,memPtr
	invoke acumulate_opcode_cycles_zero,16,21,RegBC ; Variable cycles 21/16
	jmp Z80StepEnd
OpEDB9:
   ; CPDR cycles: 21/16
	invoke inst_CPDR,memPtr
	invoke acumulate_opcode_cycles_zero,16,21,RegBC ; Variable cycles 21/16
	jmp Z80StepEnd
OpEDBA:
   ; INDR cycles: 21/16
	invoke INST_INDR,memPtr
	invoke acumulate_opcode_cycles_zero,16,21,RegBC ; Variable cycles 21/16
	jmp Z80StepEnd
OpEDBB:
   ; OTDR cycles: 21/16
	invoke INST_OTDR,memPtr
	invoke acumulate_opcode_cycles_zero,16,21,RegBC ; Variable cycles 21/16
	jmp Z80StepEnd
OpEE:
   ; XOR N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_XOR,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpEF:
   ; RST 28H cycles: 11
	invoke inst_RST,memPtr,28h
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpF0:
   ; RET P cycles: 11/5
	xor ax,ax
	mov al, RegF
	and al, 80h
	jnz OpF0_exit
	invoke inst_RET,memPtr
	OpF0_exit:
	invoke acumulate_opcode_cycles_zero,5,11,ax
	jmp Z80StepEnd
OpF1:
   ; POP AF cycles: 10
	invoke inst_POP,memPtr,OFFSET RegAF
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpF2:
   ; JP P,NN cycles: 10
	test RegF,80h
	jz OpC3
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpF3:
   ; DI cycles: 4
	invoke interrupts_disable
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpF4:
   ; CALL P,NN cycles: 17/10
	test RegF,80h
	jz OpCD
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpF5:
   ; PUSH AF cycles: 11
	invoke inst_PUSH,memPtr,RegAF
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpF6:
   ; OR N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_OR,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpF7:
   ; RST 30H cycles: 11
	invoke inst_RST,memPtr,30h
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpF8:
   ; RET M cycles: 11/5
	xor ax,ax
	mov al, RegF
	and al, 80h
	jz OpF8_exit
	invoke inst_RET,memPtr
	OpF8_exit:
	invoke acumulate_opcode_cycles_zero,11,5,ax
	jmp Z80StepEnd
OpF9:
   ; LD SP,HL cycles: 6
	invoke inst_LD16,OFFSET RegHL,OFFSET RegSP
	invoke acumulate_opcode_cycles,6
	jmp Z80StepEnd
OpFA:
   ; JP M,NN cycles: 10
	test RegF,80h
	jnz OpC3
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpFB:
   ; EI cycles: 4
	invoke interrupts_enable_request
	invoke acumulate_opcode_cycles,4
	jmp Z80StepEnd
OpFC:
   ; CALL M,NN cycles: 17/10
	test RegF,80h
	jnz OpCD
	SET_WZ_FROM_NN_ADDRESS memPtr
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpFD:
	IncRegR
	ProcessNextOpcode _TOpFD
OpFE:
   ; CP N cycles: 7
	invoke immediate_addressing_mode,memPtr
	invoke inst_CP,reg_di
	invoke acumulate_opcode_cycles,7
	jmp Z80StepEnd
OpFF:
   ; RST 38H cycles: 11
	invoke inst_RST,memPtr,38h
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpCB00:
   ; RLC B cycles: 8
	invoke inst_RLC,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB01:
   ; RLC C cycles: 8
	invoke inst_RLC,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB02:
   ; RLC D cycles: 8
	invoke inst_RLC,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB03:
   ; RLC E cycles: 8
	invoke inst_RLC,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB04:
   ; RLC H cycles: 8
	invoke inst_RLC,OFFSET RegH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB05:
   ; RLC L cycles: 8
	invoke inst_RLC,OFFSET RegL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB06:
   ; RLC (HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RLC,reg_di
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB07:
   ; RLC A cycles: 8
	invoke inst_RLC,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB08:
   ; RRC B cycles: 8
	invoke inst_RRC,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB09:
   ; RRC C cycles: 8
	invoke inst_RRC,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB0A:
   ; RRC D cycles: 8
	invoke inst_RRC,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB0B:
   ; RRC E cycles: 8
	invoke inst_RRC,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB0C:
   ; RRC H cycles: 8
	invoke inst_RRC,OFFSET RegH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB0D:
   ; RRC L cycles: 8
	invoke inst_RRC,OFFSET RegL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB0E:
   ; RRC (HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RRC,reg_di
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB0F:
   ; RRC A cycles: 8
	invoke inst_RRC,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB10:
   ; RL B cycles: 8
	invoke inst_RL,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB11:
   ; RL C cycles: 8
	invoke inst_RL,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB12:
   ; RL D cycles: 8
	invoke inst_RL,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB13:
   ; RL E cycles: 8
	invoke inst_RL,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB14:
   ; RL H cycles: 8
	invoke inst_RL,OFFSET RegH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB15:
   ; RL L cycles: 8
	invoke inst_RL,OFFSET RegL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB16:
   ; RL (HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RL,reg_di
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB17:
   ; RL A cycles: 8
	invoke inst_RL,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB18:
   ; RR B cycles: 8
	invoke inst_RR,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB19:
   ; RR C cycles: 8
	invoke inst_RR,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB1A:
   ; RR D cycles: 8
	invoke inst_RR,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB1B:
   ; RR E cycles: 8
	invoke inst_RR,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB1C:
   ; RR H cycles: 8
	invoke inst_RR,OFFSET RegH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB1D:
   ; RR L cycles: 8
	invoke inst_RR,OFFSET RegL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB1E:
   ; RR (HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RR,reg_di
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB1F:
   ; RR A cycles: 8
	invoke inst_RR,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB20:
   ; SLA B cycles: 8
	invoke inst_SLA,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB21:
   ; SLA C cycles: 8
	invoke inst_SLA,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB22:
   ; SLA D cycles: 8
	invoke inst_SLA,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB23:
   ; SLA E cycles: 8
	invoke inst_SLA,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB24:
   ; SLA H cycles: 8
	invoke inst_SLA,OFFSET RegH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB25:
   ; SLA L cycles: 8
	invoke inst_SLA,OFFSET RegL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB26:
   ; SLA (HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_SLA,reg_di
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB27:
   ; SLA A cycles: 8
	invoke inst_SLA,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB28:
   ; SRA B cycles: 8
	invoke inst_SRA,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB29:
   ; SRA C cycles: 8
	invoke inst_SRA,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB2A:
   ; SRA D cycles: 8
	invoke inst_SRA,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB2B:
   ; SRA E cycles: 8
	invoke inst_SRA,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB2C:
   ; SRA H cycles: 8
	invoke inst_SRA,OFFSET RegH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB2D:
   ; SRA L cycles: 8
	invoke inst_SRA,OFFSET RegL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB2E:
   ; SRA (HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_SRA,reg_di
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB2F:
   ; SRA A cycles: 8
	invoke inst_SRA,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB30:
   ; SLL B cycles: 8
	invoke inst_SLL,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB31:
   ; SLL C cycles: 8
	invoke inst_SLL,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB32:
   ; SLL D cycles: 8
	invoke inst_SLL,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB33:
   ; SLL E cycles: 8
	invoke inst_SLL,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB34:
   ; SLL H cycles: 8
	invoke inst_SLL,OFFSET RegH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB35:
   ; SLL L cycles: 8
	invoke inst_SLL,OFFSET RegL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB36:
   ; SLL (HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_SLL,reg_di
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB37:
   ; SLL A cycles: 8
	invoke inst_SLL,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB38:
   ; SRL B cycles: 8
	invoke inst_SRL,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB39:
   ; SRL C cycles: 8
	invoke inst_SRL,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB3A:
   ; SRL D cycles: 8
	invoke inst_SRL,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB3B:
   ; SRL E cycles: 8
	invoke inst_SRL,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB3C:
   ; SRL H cycles: 8
	invoke inst_SRL,OFFSET RegH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB3D:
   ; SRL L cycles: 8
	invoke inst_SRL,OFFSET RegL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB3E:
   ; SRL (HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_SRL,reg_di
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB3F:
   ; SRL A cycles: 8
	invoke inst_SRL,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB40:
   ; BIT 0,B cycles: 8
	invoke inst_BIT,OFFSET RegB,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB41:
   ; BIT 0,C cycles: 8
	invoke inst_BIT,OFFSET RegC,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB42:
   ; BIT 0,D cycles: 8
	invoke inst_BIT,OFFSET RegD,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB43:
   ; BIT 0,E cycles: 8
	invoke inst_BIT,OFFSET RegE,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB44:
   ; BIT 0,H cycles: 8
	invoke inst_BIT,OFFSET RegH,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB45:
   ; BIT 0,L cycles: 8
	invoke inst_BIT,OFFSET RegL,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB46:
   ; BIT 0,(HL) cycles: 12
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_BIT_HL,reg_di,0
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpCB47:
   ; BIT 0,A cycles: 8
	invoke inst_BIT,OFFSET RegA,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB48:
   ; BIT 1,B cycles: 8
	invoke inst_BIT,OFFSET RegB,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB49:
   ; BIT 1,C cycles: 8
	invoke inst_BIT,OFFSET RegC,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB4A:
   ; BIT 1,D cycles: 8
	invoke inst_BIT,OFFSET RegD,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB4B:
   ; BIT 1,E cycles: 8
	invoke inst_BIT,OFFSET RegE,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB4C:
   ; BIT 1,H cycles: 8
	invoke inst_BIT,OFFSET RegH,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB4D:
   ; BIT 1,L cycles: 8
	invoke inst_BIT,OFFSET RegL,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB4E:
   ; BIT 1,(HL) cycles: 12
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_BIT_HL,reg_di,1
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpCB4F:
   ; BIT 1,A cycles: 8
	invoke inst_BIT,OFFSET RegA,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB50:
   ; BIT 2,B cycles: 8
	invoke inst_BIT,OFFSET RegB,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB51:
   ; BIT 2,C cycles: 8
	invoke inst_BIT,OFFSET RegC,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB52:
   ; BIT 2,D cycles: 8
	invoke inst_BIT,OFFSET RegD,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB53:
   ; BIT 2,E cycles: 8
	invoke inst_BIT,OFFSET RegE,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB54:
   ; BIT 2,H cycles: 8
	invoke inst_BIT,OFFSET RegH,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB55:
   ; BIT 2,L cycles: 8
	invoke inst_BIT,OFFSET RegL,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB56:
   ; BIT 2,(HL) cycles: 12
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_BIT_HL,reg_di,2
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpCB57:
   ; BIT 2,A cycles: 8
	invoke inst_BIT,OFFSET RegA,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB58:
   ; BIT 3,B cycles: 8
	invoke inst_BIT,OFFSET RegB,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB59:
   ; BIT 3,C cycles: 8
	invoke inst_BIT,OFFSET RegC,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB5A:
   ; BIT 3,D cycles: 8
	invoke inst_BIT,OFFSET RegD,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB5B:
   ; BIT 3,E cycles: 8
	invoke inst_BIT,OFFSET RegE,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB5C:
   ; BIT 3,H cycles: 8
	invoke inst_BIT,OFFSET RegH,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB5D:
   ; BIT 3,L cycles: 8
	invoke inst_BIT,OFFSET RegL,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB5E:
   ; BIT 3,(HL) cycles: 12
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_BIT_HL,reg_di,3
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpCB5F:
   ; BIT 3,A cycles: 8
	invoke inst_BIT,OFFSET RegA,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB60:
   ; BIT 4,B cycles: 8
	invoke inst_BIT,OFFSET RegB,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB61:
   ; BIT 4,C cycles: 8
	invoke inst_BIT,OFFSET RegC,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB62:
   ; BIT 4,D cycles: 8
	invoke inst_BIT,OFFSET RegD,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB63:
   ; BIT 4,E cycles: 8
	invoke inst_BIT,OFFSET RegE,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB64:
   ; BIT 4,H cycles: 8
	invoke inst_BIT,OFFSET RegH,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB65:
   ; BIT 4,L cycles: 8
	invoke inst_BIT,OFFSET RegL,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB66:
   ; BIT 4,(HL) cycles: 12
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_BIT_HL,reg_di,4
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpCB67:
   ; BIT 4,A cycles: 8
	invoke inst_BIT,OFFSET RegA,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB68:
   ; BIT 5,B cycles: 8
	invoke inst_BIT,OFFSET RegB,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB69:
   ; BIT 5,C cycles: 8
	invoke inst_BIT,OFFSET RegC,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB6A:
   ; BIT 5,D cycles: 8
	invoke inst_BIT,OFFSET RegD,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB6B:
   ; BIT 5,E cycles: 8
	invoke inst_BIT,OFFSET RegE,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB6C:
   ; BIT 5,H cycles: 8
	invoke inst_BIT,OFFSET RegH,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB6D:
   ; BIT 5,L cycles: 8
	invoke inst_BIT,OFFSET RegL,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB6E:
   ; BIT 5,(HL) cycles: 12
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_BIT_HL,reg_di,5
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpCB6F:
   ; BIT 5,A cycles: 8
	invoke inst_BIT,OFFSET RegA,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB70:
   ; BIT 6,B cycles: 8
	invoke inst_BIT,OFFSET RegB,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB71:
   ; BIT 6,C cycles: 8
	invoke inst_BIT,OFFSET RegC,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB72:
   ; BIT 6,D cycles: 8
	invoke inst_BIT,OFFSET RegD,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB73:
   ; BIT 6,E cycles: 8
	invoke inst_BIT,OFFSET RegE,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB74:
   ; BIT 6,H cycles: 8
	invoke inst_BIT,OFFSET RegH,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB75:
   ; BIT 6,L cycles: 8
	invoke inst_BIT,OFFSET RegL,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB76:
   ; BIT 6,(HL) cycles: 12
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_BIT_HL,reg_di,6
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpCB77:
   ; BIT 6,A cycles: 8
	invoke inst_BIT,OFFSET RegA,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB78:
   ; BIT 7,B cycles: 8
	invoke inst_BIT,OFFSET RegB,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB79:
   ; BIT 7,C cycles: 8
	invoke inst_BIT,OFFSET RegC,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB7A:
   ; BIT 7,D cycles: 8
	invoke inst_BIT,OFFSET RegD,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB7B:
   ; BIT 7,E cycles: 8
	invoke inst_BIT,OFFSET RegE,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB7C:
   ; BIT 7,H cycles: 8
	invoke inst_BIT,OFFSET RegH,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB7D:
   ; BIT 7,L cycles: 8
	invoke inst_BIT,OFFSET RegL,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB7E:
   ; BIT 7,(HL) cycles: 12
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_BIT_HL,reg_di,7
	invoke acumulate_opcode_cycles,12
	jmp Z80StepEnd
OpCB7F:
   ; BIT 7,A cycles: 8
	invoke inst_BIT,OFFSET RegA,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB80:
   ; RES 0,B cycles: 8
	invoke inst_RES,OFFSET RegB,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB81:
   ; RES 0,C cycles: 8
	invoke inst_RES,OFFSET RegC,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB82:
   ; RES 0,D cycles: 8
	invoke inst_RES,OFFSET RegD,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB83:
   ; RES 0,E cycles: 8
	invoke inst_RES,OFFSET RegE,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB84:
   ; RES 0,H cycles: 8
	invoke inst_RES,OFFSET RegH,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB85:
   ; RES 0,L cycles: 8
	invoke inst_RES,OFFSET RegL,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB86:
   ; RES 0,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RES,reg_di,0
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB87:
   ; RES 0,A cycles: 8
	invoke inst_RES,OFFSET RegA,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB88:
   ; RES 1,B cycles: 8
	invoke inst_RES,OFFSET RegB,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB89:
   ; RES 1,C cycles: 8
	invoke inst_RES,OFFSET RegC,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB8A:
   ; RES 1,D cycles: 8
	invoke inst_RES,OFFSET RegD,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB8B:
   ; RES 1,E cycles: 8
	invoke inst_RES,OFFSET RegE,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB8C:
   ; RES 1,H cycles: 8
	invoke inst_RES,OFFSET RegH,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB8D:
   ; RES 1,L cycles: 8
	invoke inst_RES,OFFSET RegL,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB8E:
   ; RES 1,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RES,reg_di,1
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB8F:
   ; RES 1,A cycles: 8
	invoke inst_RES,OFFSET RegA,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB90:
   ; RES 2,B cycles: 8
	invoke inst_RES,OFFSET RegB,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB91:
   ; RES 2,C cycles: 8
	invoke inst_RES,OFFSET RegC,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB92:
   ; RES 2,D cycles: 8
	invoke inst_RES,OFFSET RegD,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB93:
   ; RES 2,E cycles: 8
	invoke inst_RES,OFFSET RegE,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB94:
   ; RES 2,H cycles: 8
	invoke inst_RES,OFFSET RegH,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB95:
   ; RES 2,L cycles: 8
	invoke inst_RES,OFFSET RegL,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB96:
   ; RES 2,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RES,reg_di,2
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB97:
   ; RES 2,A cycles: 8
	invoke inst_RES,OFFSET RegA,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB98:
   ; RES 3,B cycles: 8
	invoke inst_RES,OFFSET RegB,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB99:
   ; RES 3,C cycles: 8
	invoke inst_RES,OFFSET RegC,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB9A:
   ; RES 3,D cycles: 8
	invoke inst_RES,OFFSET RegD,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB9B:
   ; RES 3,E cycles: 8
	invoke inst_RES,OFFSET RegE,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB9C:
   ; RES 3,H cycles: 8
	invoke inst_RES,OFFSET RegH,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB9D:
   ; RES 3,L cycles: 8
	invoke inst_RES,OFFSET RegL,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCB9E:
   ; RES 3,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RES,reg_di,3
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCB9F:
   ; RES 3,A cycles: 8
	invoke inst_RES,OFFSET RegA,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBA0:
   ; RES 4,B cycles: 8
	invoke inst_RES,OFFSET RegB,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBA1:
   ; RES 4,C cycles: 8
	invoke inst_RES,OFFSET RegC,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBA2:
   ; RES 4,D cycles: 8
	invoke inst_RES,OFFSET RegD,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBA3:
   ; RES 4,E cycles: 8
	invoke inst_RES,OFFSET RegE,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBA4:
   ; RES 4,H cycles: 8
	invoke inst_RES,OFFSET RegH,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBA5:
   ; RES 4,L cycles: 8
	invoke inst_RES,OFFSET RegL,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBA6:
   ; RES 4,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RES,reg_di,4
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBA7:
   ; RES 4,A cycles: 8
	invoke inst_RES,OFFSET RegA,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBA8:
   ; RES 5,B cycles: 8
	invoke inst_RES,OFFSET RegB,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBA9:
   ; RES 5,C cycles: 8
	invoke inst_RES,OFFSET RegC,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBAA:
   ; RES 5,D cycles: 8
	invoke inst_RES,OFFSET RegD,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBAB:
   ; RES 5,E cycles: 8
	invoke inst_RES,OFFSET RegE,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBAC:
   ; RES 5,H cycles: 8
	invoke inst_RES,OFFSET RegH,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBAD:
   ; RES 5,L cycles: 8
	invoke inst_RES,OFFSET RegL,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBAE:
   ; RES 5,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RES,reg_di,5
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBAF:
   ; RES 5,A cycles: 8
	invoke inst_RES,OFFSET RegA,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBB0:
   ; RES 6,B cycles: 8
	invoke inst_RES,OFFSET RegB,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBB1:
   ; RES 6,C cycles: 8
	invoke inst_RES,OFFSET RegC,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBB2:
   ; RES 6,D cycles: 8
	invoke inst_RES,OFFSET RegD,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBB3:
   ; RES 6,E cycles: 8
	invoke inst_RES,OFFSET RegE,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBB4:
   ; RES 6,H cycles: 8
	invoke inst_RES,OFFSET RegH,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBB5:
   ; RES 6,L cycles: 8
	invoke inst_RES,OFFSET RegL,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBB6:
   ; RES 6,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RES,reg_di,6
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBB7:
   ; RES 6,A cycles: 8
	invoke inst_RES,OFFSET RegA,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBB8:
   ; RES 7,B cycles: 8
	invoke inst_RES,OFFSET RegB,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBB9:
   ; RES 7,C cycles: 8
	invoke inst_RES,OFFSET RegC,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBBA:
   ; RES 7,D cycles: 8
	invoke inst_RES,OFFSET RegD,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBBB:
   ; RES 7,E cycles: 8
	invoke inst_RES,OFFSET RegE,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBBC:
   ; RES 7,H cycles: 8
	invoke inst_RES,OFFSET RegH,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBBD:
   ; RES 7,L cycles: 8
	invoke inst_RES,OFFSET RegL,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBBE:
   ; RES 7,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_RES,reg_di,7
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBBF:
   ; RES 7,A cycles: 8
	invoke inst_RES,OFFSET RegA,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBC0:
   ; SET 0,B cycles: 8
	invoke inst_Set,OFFSET RegB,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBC1:
   ; SET 0,C cycles: 8
	invoke inst_Set,OFFSET RegC,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBC2:
   ; SET 0,D cycles: 8
	invoke inst_Set,OFFSET RegD,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBC3:
   ; SET 0,E cycles: 8
	invoke inst_Set,OFFSET RegE,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBC4:
   ; SET 0,H cycles: 8
	invoke inst_Set,OFFSET RegH,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBC5:
   ; SET 0,L cycles: 8
	invoke inst_Set,OFFSET RegL,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBC6:
   ; SET 0,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_Set,reg_di,0
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBC7:
   ; SET 0,A cycles: 8
	invoke inst_Set,OFFSET RegA,0
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBC8:
   ; SET 1,B cycles: 8
	invoke inst_Set,OFFSET RegB,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBC9:
   ; SET 1,C cycles: 8
	invoke inst_Set,OFFSET RegC,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBCA:
   ; SET 1,D cycles: 8
	invoke inst_Set,OFFSET RegD,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBCB:
   ; SET 1,E cycles: 8
	invoke inst_Set,OFFSET RegE,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBCC:
   ; SET 1,H cycles: 8
	invoke inst_Set,OFFSET RegH,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBCD:
   ; SET 1,L cycles: 8
	invoke inst_Set,OFFSET RegL,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBCE:
   ; SET 1,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_Set,reg_di,1
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBCF:
   ; SET 1,A cycles: 8
	invoke inst_Set,OFFSET RegA,1
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBD0:
   ; SET 2,B cycles: 8
	invoke inst_Set,OFFSET RegB,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBD1:
   ; SET 2,C cycles: 8
	invoke inst_Set,OFFSET RegC,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBD2:
   ; SET 2,D cycles: 8
	invoke inst_Set,OFFSET RegD,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBD3:
   ; SET 2,E cycles: 8
	invoke inst_Set,OFFSET RegE,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBD4:
   ; SET 2,H cycles: 8
	invoke inst_Set,OFFSET RegH,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBD5:
   ; SET 2,L cycles: 8
	invoke inst_Set,OFFSET RegL,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBD6:
   ; SET 2,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_Set,reg_di,2
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBD7:
   ; SET 2,A cycles: 8
	invoke inst_Set,OFFSET RegA,2
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBD8:
   ; SET 3,B cycles: 8
	invoke inst_Set,OFFSET RegB,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBD9:
   ; SET 3,C cycles: 8
	invoke inst_Set,OFFSET RegC,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBDA:
   ; SET 3,D cycles: 8
	invoke inst_Set,OFFSET RegD,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBDB:
   ; SET 3,E cycles: 8
	invoke inst_Set,OFFSET RegE,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBDC:
   ; SET 3,H cycles: 8
	invoke inst_Set,OFFSET RegH,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBDD:
   ; SET 3,L cycles: 8
	invoke inst_Set,OFFSET RegL,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBDE:
   ; SET 3,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_Set,reg_di,3
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBDF:
   ; SET 3,A cycles: 8
	invoke inst_Set,OFFSET RegA,3
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBE0:
   ; SET 4,B cycles: 8
	invoke inst_Set,OFFSET RegB,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBE1:
   ; SET 4,C cycles: 8
	invoke inst_Set,OFFSET RegC,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBE2:
   ; SET 4,D cycles: 8
	invoke inst_Set,OFFSET RegD,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBE3:
   ; SET 4,E cycles: 8
	invoke inst_Set,OFFSET RegE,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBE4:
   ; SET 4,H cycles: 8
	invoke inst_Set,OFFSET RegH,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBE5:
   ; SET 4,L cycles: 8
	invoke inst_Set,OFFSET RegL,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBE6:
   ; SET 4,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_Set,reg_di,4
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBE7:
   ; SET 4,A cycles: 8
	invoke inst_Set,OFFSET RegA,4
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBE8:
   ; SET 5,B cycles: 8
	invoke inst_Set,OFFSET RegB,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBE9:
   ; SET 5,C cycles: 8
	invoke inst_Set,OFFSET RegC,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBEA:
   ; SET 5,D cycles: 8
	invoke inst_Set,OFFSET RegD,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBEB:
   ; SET 5,E cycles: 8
	invoke inst_Set,OFFSET RegE,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBEC:
   ; SET 5,H cycles: 8
	invoke inst_Set,OFFSET RegH,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBED:
   ; SET 5,L cycles: 8
	invoke inst_Set,OFFSET RegL,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBEE:
   ; SET 5,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_Set,reg_di,5
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBEF:
   ; SET 5,A cycles: 8
	invoke inst_Set,OFFSET RegA,5
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBF0:
   ; SET 6,B cycles: 8
	invoke inst_Set,OFFSET RegB,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBF1:
   ; SET 6,C cycles: 8
	invoke inst_Set,OFFSET RegC,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBF2:
   ; SET 6,D cycles: 8
	invoke inst_Set,OFFSET RegD,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBF3:
   ; SET 6,E cycles: 8
	invoke inst_Set,OFFSET RegE,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBF4:
   ; SET 6,H cycles: 8
	invoke inst_Set,OFFSET RegH,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBF5:
   ; SET 6,L cycles: 8
	invoke inst_Set,OFFSET RegL,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBF6:
   ; SET 6,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_Set,reg_di,6
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBF7:
   ; SET 6,A cycles: 8
	invoke inst_Set,OFFSET RegA,6
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBF8:
   ; SET 7,B cycles: 8
	invoke inst_Set,OFFSET RegB,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBF9:
   ; SET 7,C cycles: 8
	invoke inst_Set,OFFSET RegC,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBFA:
   ; SET 7,D cycles: 8
	invoke inst_Set,OFFSET RegD,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBFB:
   ; SET 7,E cycles: 8
	invoke inst_Set,OFFSET RegE,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBFC:
   ; SET 7,H cycles: 8
	invoke inst_Set,OFFSET RegH,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBFD:
   ; SET 7,L cycles: 8
	invoke inst_Set,OFFSET RegL,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpCBFE:
   ; SET 7,(HL) cycles: 15
	invoke register_indirect_addressing_mode,memPtr,RegHL
	invoke inst_Set,reg_di,7
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpCBFF:
   ; SET 7,A cycles: 8
	invoke inst_Set,OFFSET RegA,7
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD04:
	jmp Op04
OpDD05:
	jmp Op05
OpDD06:
	jmp Op06
OpDD09:
   ; ADD IX,BC cycles: 15
	invoke inst_ADD16,OFFSET RegBC,OFFSET RegIX
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpDD0C:
	jmp Op0C
OpDD0D:
	jmp Op0D
OpDD0E:
	jmp Op0E
OpDD14:
	jmp Op14
OpDD15:
	jmp Op15
OpDD16:
	jmp Op16
OpDD19:
   ; ADD IX,DE cycles: 15
	invoke inst_ADD16,OFFSET RegDE,OFFSET RegIX
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpDD1C:
	jmp Op1C
OpDD1D:
	jmp Op1D
OpDD1E:
	jmp Op1E
OpDD21:
   ; LD IX,NN cycles: 14
	invoke immediate_addressing_mode_ext,memPtr
	invoke inst_LD16,reg_di,OFFSET RegIX
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpDD22:
   ; LD (NN),IX cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	invoke register_indirect_addressing_mode,memPtr,di
	invoke inst_LD16,OFFSET RegIX,reg_di
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpDD23:
   ; INC IX cycles: 10
	invoke inst_INC16,OFFSET RegIX
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpDD24:
   ; INC IXH cycles: 8
	invoke inst_INC8,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD25:
   ; DEC IXH cycles: 8
	invoke inst_DEC8,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD26:
   ; LD IXH,N cycles: 11
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegIXH
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpDD29:
   ; ADD IX,IX cycles: 15
	invoke inst_ADD16,OFFSET RegIX,OFFSET RegIX
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpDD2A:
   ; LD IX,(NN) cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	add reg_di,memPtr
	invoke inst_LD16,reg_di,OFFSET RegIX
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpDD2B:
   ; DEC IX cycles: 10
	invoke inst_DEC16,OFFSET RegIX
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpDD2C:
   ; INC IXL cycles: 8
	invoke inst_INC8,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD2D:
   ; DEC IXL cycles: 8
	invoke inst_DEC8,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD2E:
   ; LD IXL,N cycles: 11
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegIXL
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpDD34:
   ; INC (IX+D) cycles: 23
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_INC8,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDD35:
   ; DEC (IX+D) cycles: 23
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_DEC8,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDD36:
   ; LD (IX+D),N cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	mov reg_si,reg_di
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,reg_si
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD39:
   ; ADD IX,SP cycles: 15
	invoke inst_ADD16,OFFSET RegSP,OFFSET RegIX
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpDD3C:
	jmp Op3C
OpDD3D:
	jmp Op3D
OpDD3E:
	jmp Op3E
OpDD40:
	jmp Op40
OpDD41:
	jmp Op41
OpDD42:
	jmp Op42
OpDD43:
	jmp Op43
OpDD44:
   ; LD B,IXH cycles: 8
	invoke inst_LD8,OFFSET RegIXH,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD45:
   ; LD B,IXL cycles: 8
	invoke inst_LD8,OFFSET RegIXL,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD46:
   ; LD B,(IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,reg_di,OFFSET RegB
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD47:
	jmp Op47
OpDD48:
	jmp Op48
OpDD49:
	jmp Op49
OpDD4A:
	jmp Op4A
OpDD4B:
	jmp Op4B
OpDD4C:
   ; LD C,IXH cycles: 8
	invoke inst_LD8,OFFSET RegIXH,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD4D:
   ; LD C,IXL cycles: 8
	invoke inst_LD8,OFFSET RegIXL,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD4E:
   ; LD C,(IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,reg_di,OFFSET RegC
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD4F:
	jmp Op4F
OpDD50:
	jmp Op50
OpDD51:
	jmp Op51
OpDD52:
	jmp Op52
OpDD53:
	jmp Op53
OpDD54:
   ; LD D,IXH cycles: 8
	invoke inst_LD8,OFFSET RegIXH,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD55:
   ; LD D,IXL cycles: 8
	invoke inst_LD8,OFFSET RegIXL,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD56:
   ; LD D,(IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,reg_di,OFFSET RegD
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD57:
	jmp Op57
OpDD58:
	jmp Op58
OpDD59:
	jmp Op59
OpDD5A:
	jmp Op5A
OpDD5B:
	jmp Op5B
OpDD5C:
   ; LD E,IXH cycles: 8
	invoke inst_LD8,OFFSET RegIXH,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD5D:
   ; LD E,IXL cycles: 8
	invoke inst_LD8,OFFSET RegIXL,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD5E:
   ; LD E,(IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,reg_di,OFFSET RegE
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD5F:
	jmp Op5F
OpDD60:
   ; LD IXH,B cycles: 8
	invoke inst_LD8,OFFSET RegB,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD61:
   ; LD IXH,C cycles: 8
	invoke inst_LD8,OFFSET RegC,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD62:
   ; LD IXH,D cycles: 8
	invoke inst_LD8,OFFSET RegD,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD63:
   ; LD IXH,E cycles: 8
	invoke inst_LD8,OFFSET RegE,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD64:
   ; LD IXH,IXH cycles: 8
	invoke inst_LD8,OFFSET RegIXH,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD65:
   ; LD IXH,IXL cycles: 8
	invoke inst_LD8,OFFSET RegIXL,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD66:
   ; LD H,(IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,reg_di,OFFSET RegH
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD67:
   ; LD IXH,A cycles: 8
	invoke inst_LD8,OFFSET RegA,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD68:
   ; LD IXL,B cycles: 8
	invoke inst_LD8,OFFSET RegB,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD69:
   ; LD IXL,C cycles: 8
	invoke inst_LD8,OFFSET RegC,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD6A:
   ; LD IXL,D cycles: 8
	invoke inst_LD8,OFFSET RegD,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD6B:
   ; LD IXL,E cycles: 8
	invoke inst_LD8,OFFSET RegE,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD6C:
   ; LD IXL,IXH cycles: 8
	invoke inst_LD8,OFFSET RegIXH,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD6D:
   ; LD IXL,IXL cycles: 8
	invoke inst_LD8,OFFSET RegIXL,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD6E:
   ; LD L,(IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,reg_di,OFFSET RegL
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD6F:
   ; LD IXL,A cycles: 8
	invoke inst_LD8,OFFSET RegA,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD70:
   ; LD (IX+D),B cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,OFFSET RegB,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD71:
   ; LD (IX+D),C cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,OFFSET RegC,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD72:
   ; LD (IX+D),D cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,OFFSET RegD,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD73:
   ; LD (IX+D),E cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,OFFSET RegE,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD74:
   ; LD (IX+D),H cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,OFFSET RegH,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD75:
   ; LD (IX+D),L cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,OFFSET RegL,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD77:
   ; LD (IX+D),A cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,OFFSET RegA,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD78:
	jmp Op78
OpDD79:
	jmp Op79
OpDD7A:
	jmp Op7A
OpDD7B:
	jmp Op7B
OpDD7C:
   ; LD A,IXH cycles: 8
	invoke inst_LD8,OFFSET RegIXH,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD7D:
   ; LD A,IXL cycles: 8
	invoke inst_LD8,OFFSET RegIXL,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD7E:
   ; LD A,(IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_LD8,reg_di,OFFSET RegA
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD7F:
	jmp Op7F
OpDD80:
	jmp Op80
OpDD81:
	jmp Op81
OpDD82:
	jmp Op82
OpDD83:
	jmp Op83
OpDD84:
   ; ADD A,IXH cycles: 8
	invoke inst_ADD8,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD85:
   ; ADD A,IXL cycles: 8
	invoke inst_ADD8,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD86:
   ; ADD A,(IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_ADD8,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD87:
	jmp Op87
OpDD88:
	jmp Op88
OpDD89:
	jmp Op89
OpDD8A:
	jmp Op8A
OpDD8B:
	jmp Op8B
OpDD8C:
   ; ADC A,IXH cycles: 8
	invoke inst_ADC8,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD8D:
   ; ADC A,IXL cycles: 8
	invoke inst_ADC8,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD8E:
   ; ADC A,(IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_ADC8,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD8F:
	jmp Op8F
OpDD90:
	jmp Op90
OpDD91:
	jmp Op91
OpDD92:
	jmp Op92
OpDD93:
	jmp Op93
OpDD94:
   ; SUB IXH cycles: 8
	invoke inst_SUB,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD95:
   ; SUB IXL cycles: 8
	invoke inst_SUB,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD96:
   ; SUB (IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_SUB,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD97:
	jmp Op97
OpDD98:
	jmp Op98
OpDD99:
	jmp Op99
OpDD9A:
	jmp Op9A
OpDD9B:
	jmp Op9B
OpDD9C:
   ; SBC A,IXH cycles: 8
	invoke inst_SBC8,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD9D:
   ; SBC A,IXL cycles: 8
	invoke inst_SBC8,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDD9E:
   ; SBC A,(IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_SBC8,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDD9F:
	jmp Op9F
OpDDA0:
	jmp OpA0
OpDDA1:
	jmp OpA1
OpDDA2:
	jmp OpA2
OpDDA3:
	jmp OpA3
OpDDA4:
   ; AND IXH cycles: 8
	invoke inst_AND,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDDA5:
   ; AND IXL cycles: 8
	invoke inst_AND,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDDA6:
   ; AND (IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_AND,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDDA7:
	jmp OpA7
OpDDA8:
	jmp OpA8
OpDDA9:
	jmp OpA9
OpDDAA:
	jmp OpAA
OpDDAB:
	jmp OpAB
OpDDAC:
   ; XOR IXH cycles: 8
	invoke inst_XOR,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDDAD:
   ; XOR IXL cycles: 8
	invoke inst_XOR,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDDAE:
   ; XOR (IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_XOR,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDDAF:
	jmp OpAF
OpDDB0:
	jmp OpB0
OpDDB1:
	jmp OpB1
OpDDB2:
	jmp OpB2
OpDDB3:
	jmp OpB3
OpDDB4:
   ; OR IXH cycles: 8
	invoke inst_OR,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDDB5:
   ; OR IXL cycles: 8
	invoke inst_OR,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDDB6:
   ; OR (IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_OR,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDDB7:
	jmp OpB7
OpDDB8:
	jmp OpB8
OpDDB9:
	jmp OpB9
OpDDBA:
	jmp OpBA
OpDDBB:
	jmp OpBB
OpDDBC:
   ; CP IXH cycles: 8
	invoke inst_CP,OFFSET RegIXH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDDBD:
   ; CP IXL cycles: 8
	invoke inst_CP,OFFSET RegIXL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDDBE:
   ; CP (IX+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIX
	invoke inst_CP,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpDDBF:
	jmp OpBF
OpDDCB:
	invoke indexed_addressing_mode,memPtr,RegIX
	SET_WZ_FROM_VALUE_16 reg_tmp16
	ProcessNextOpcode _TOpDDCB
OpDDCB00:
   ; RLC (IX+D),B cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB01:
   ; RLC (IX+D),C cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB02:
   ; RLC (IX+D),D cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB03:
   ; RLC (IX+D),E cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB04:
   ; RLC (IX+D),H cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB05:
   ; RLC (IX+D),L cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB06:
   ; RLC (IX+D) cycles: 23
	invoke inst_RLC,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB07:
   ; RLC (IX+D),A cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB08:
   ; RRC (IX+D),B cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB09:
   ; RRC (IX+D),C cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB0A:
   ; RRC (IX+D),D cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB0B:
   ; RRC (IX+D),E cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB0C:
   ; RRC (IX+D),H cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB0D:
   ; RRC (IX+D),L cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB0E:
   ; RRC (IX+D) cycles: 23
	invoke inst_RRC,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB0F:
   ; RRC (IX+D),A cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB10:
   ; RL (IX+D),B cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB11:
   ; RL (IX+D),C cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB12:
   ; RL (IX+D),D cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB13:
   ; RL (IX+D),E cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB14:
   ; RL (IX+D),H cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB15:
   ; RL (IX+D),L cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB16:
   ; RL (IX+D) cycles: 23
	invoke inst_RL,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB17:
   ; RL (IX+D),A cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB18:
   ; RR (IX+D),B cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB19:
   ; RR (IX+D),C cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB1A:
   ; RR (IX+D),D cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB1B:
   ; RR (IX+D),E cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB1C:
   ; RR (IX+D),H cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB1D:
   ; RR (IX+D),L cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB1E:
   ; RR (IX+D) cycles: 23
	invoke inst_RR,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB1F::
   ; RR (IX+D),A cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB20:
   ; SLA (IX+D),B cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB21:
   ; SLA (IX+D),C cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB22:
   ; SLA (IX+D),D cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB23:
   ; SLA (IX+D),E cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB24:
   ; SLA (IX+D),H cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB25:
   ; SLA (IX+D),L cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB26:
   ; SLA (IX+D) cycles: 23
	invoke inst_SLA,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB27:
   ; SLA (IX+D),A cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB28:
   ; SRA (IX+D),B cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB29:
   ; SRA (IX+D),C cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB2A:
   ; SRA (IX+D),D cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB2B:
   ; SRA (IX+D),E cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB2C:
   ; SRA (IX+D),H cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB2D:
   ; SRA (IX+D),L cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB2E:
   ; SRA (IX+D) cycles: 23
	invoke inst_SRA,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB2F:
   ; SRA (IX+D),A cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB30:
   ; SLL (IX+D),B cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB31:
   ; SLL (IX+D),C cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB32:
   ; SLL (IX+D),D cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB33:
   ; SLL (IX+D),E cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB34:
   ; SLL (IX+D),H cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB35:
   ; SLL (IX+D),L cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB36:
   ; SLL (IX+D) cycles: 23
	invoke inst_SLL,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB37:
   ; SLL (IX+D),A cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB38:
   ; SRL (IX+D),B cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB39:
   ; SRL (IX+D),C cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB3A:
   ; SRL (IX+D),D cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB3B:
   ; SRL (IX+D),E cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB3C:
   ; SRL (IX+D),H cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB3D:
   ; SRL (IX+D),L cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB3E:
   ; SRL (IX+D) cycles: 23
	invoke inst_SRL,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB3F:
   ; SRL (IX+D),A cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB40:
	jmp OpDDCB46
OpDDCB41:
	jmp OpDDCB46
OpDDCB42:
	jmp OpDDCB46
OpDDCB43:
	jmp OpDDCB46
OpDDCB44:
	jmp OpDDCB46
OpDDCB45:
	jmp OpDDCB46
OpDDCB46:
   ; BIT 0,(IX+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,0
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpDDCB47:
	jmp OpDDCB46
OpDDCB48:
	jmp OpDDCB4E
OpDDCB49:
	jmp OpDDCB4E
OpDDCB4A:
	jmp OpDDCB4E
OpDDCB4B:
	jmp OpDDCB4E
OpDDCB4C:
	jmp OpDDCB4E
OpDDCB4D:
	jmp OpDDCB4E
OpDDCB4E:
   ; BIT 1,(IX+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,1
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpDDCB4F:
	jmp OpDDCB4E
OpDDCB50:
	jmp OpDDCB56
OpDDCB51:
	jmp OpDDCB56
OpDDCB52:
	jmp OpDDCB56
OpDDCB53:
	jmp OpDDCB56
OpDDCB54:
	jmp OpDDCB56
OpDDCB55:
	jmp OpDDCB56
OpDDCB56:
   ; BIT 2,(IX+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,2
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpDDCB57:
	jmp OpDDCB56
OpDDCB58:
	jmp OpDDCB5E
OpDDCB59:
	jmp OpDDCB5E
OpDDCB5A:
	jmp OpDDCB5E
OpDDCB5B:
	jmp OpDDCB5E
OpDDCB5C:
	jmp OpDDCB5E
OpDDCB5D:
	jmp OpDDCB5E
OpDDCB5E:
   ; BIT 3,(IX+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,3
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpDDCB5F:
	jmp OpDDCB5E
OpDDCB60:
	jmp OpDDCB66
OpDDCB61:
	jmp OpDDCB66
OpDDCB62:
	jmp OpDDCB66
OpDDCB63:
	jmp OpDDCB66
OpDDCB64:
	jmp OpDDCB66
OpDDCB65:
	jmp OpDDCB66
OpDDCB66:
   ; BIT 4,(IX+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,4
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpDDCB67:
	jmp OpDDCB66
OpDDCB68:
	jmp OpDDCB6E
OpDDCB69:
	jmp OpDDCB6E
OpDDCB6A:
	jmp OpDDCB6E
OpDDCB6B:
	jmp OpDDCB6E
OpDDCB6C:
	jmp OpDDCB6E
OpDDCB6D:
	jmp OpDDCB6E
OpDDCB6E:
   ; BIT 5,(IX+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,5
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpDDCB6F:
	jmp OpDDCB6E
OpDDCB70:
	jmp OpDDCB76
OpDDCB71:
	jmp OpDDCB76
OpDDCB72:
	jmp OpDDCB76
OpDDCB73:
	jmp OpDDCB76
OpDDCB74:
	jmp OpDDCB76
OpDDCB75:
	jmp OpDDCB76
OpDDCB76:
   ; BIT 6,(IX+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,6
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpDDCB77:
	jmp OpDDCB76
OpDDCB78:
	jmp OpDDCB7E
OpDDCB79:
	jmp OpDDCB7E
OpDDCB7A:
	jmp OpDDCB7E
OpDDCB7B:
	jmp OpDDCB7E
OpDDCB7C:
	jmp OpDDCB7E
OpDDCB7D:
	jmp OpDDCB7E
OpDDCB7E:
   ; BIT 7,(IX+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,7
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpDDCB7F:
	jmp OpDDCB7E
OpDDCB80:
   ; RES 0,(IX+D),B cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB81:
   ; RES 0,(IX+D),C cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB82:
   ; RES 0,(IX+D),D cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB83:
   ; RES 0,(IX+D),E cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB84:
   ; RES 0,(IX+D),H cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB85:
   ; RES 0,(IX+D),L cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB86:
   ; RES 0,(IX+D) cycles: 23
	invoke inst_RES,reg_di,0
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB87:
   ; RES 0,(IX+D),A cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB88:
   ; RES 1,(IX+D),B cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB89:
   ; RES 1,(IX+D),C cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB8A:
   ; RES 1,(IX+D),D cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB8B:
   ; RES 1,(IX+D),E cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB8C:
   ; RES 1,(IX+D),H cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB8D:
   ; RES 1,(IX+D),L cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB8E:
   ; RES 1,(IX+D) cycles: 23
	invoke inst_RES,reg_di,1
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB8F:
   ; RES 1,(IX+D),A cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB90:
   ; RES 2,(IX+D),B cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB91:
   ; RES 2,(IX+D),C cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB92:
   ; RES 2,(IX+D),D cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB93:
   ; RES 2,(IX+D),E cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB94:
   ; RES 2,(IX+D),H cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB95:
   ; RES 2,(IX+D),L cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB96:
   ; RES 2,(IX+D) cycles: 23
	invoke inst_RES,reg_di,2
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB97:
   ; RES 2,(IX+D),A cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB98:
   ; RES 3,(IX+D),B cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB99:
   ; RES 3,(IX+D),C cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB9A:
   ; RES 3,(IX+D),D cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB9B:
   ; RES 3,(IX+D),E cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB9C:
   ; RES 3,(IX+D),H cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB9D:
   ; RES 3,(IX+D),L cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB9E:
   ; RES 3,(IX+D) cycles: 23
	invoke inst_RES,reg_di,3
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCB9F:
   ; RES 3,(IX+D),A cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBA0:
   ; RES 4,(IX+D),B cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBA1:
   ; RES 4,(IX+D),C cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBA2:
   ; RES 4,(IX+D),D cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBA3:
   ; RES 4,(IX+D),E cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBA4:
   ; RES 4,(IX+D),H cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBA5:
   ; RES 4,(IX+D),L cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBA6:
   ; RES 4,(IX+D) cycles: 23
	invoke inst_RES,reg_di,4
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBA7:
   ; RES 4,(IX+D),A cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBA8:
   ; RES 5,(IX+D),B cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBA9:
   ; RES 5,(IX+D),C cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBAA:
   ; RES 5,(IX+D),D cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBAB:
   ; RES 5,(IX+D),E cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBAC:
   ; RES 5,(IX+D),H cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBAD:
   ; RES 5,(IX+D),L cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBAE:
   ; RES 5,(IX+D) cycles: 23
	invoke inst_RES,reg_di,5
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBAF:
   ; RES 5,(IX+D),A cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBB0:
   ; RES 6,(IX+D),B cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBB1:
   ; RES 6,(IX+D),C cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBB2:
   ; RES 6,(IX+D),D cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBB3:
   ; RES 6,(IX+D),E cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBB4:
   ; RES 6,(IX+D),H cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBB5:
   ; RES 6,(IX+D),L cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBB6:
   ; RES 6,(IX+D) cycles: 23
	invoke inst_RES,reg_di,6
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBB7:
   ; RES 6,(IX+D),A cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBB8:
   ; RES 7,(IX+D),B cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBB9:
   ; RES 7,(IX+D),C cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBBA:
   ; RES 7,(IX+D),D cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBBB:
   ; RES 7,(IX+D),E cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBBC:
   ; RES 7,(IX+D),H cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBBD:
   ; RES 7,(IX+D),L cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBBE:
   ; RES 7,(IX+D) cycles: 23
	invoke inst_RES,reg_di,7
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBBF:
   ; RES 7,(IX+D),A cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBC0:
   ; SET 0,(IX+D),B cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBC1:
   ; SET 0,(IX+D),C cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBC2:
   ; SET 0,(IX+D),D cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBC3:
   ; SET 0,(IX+D),E cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBC4:
   ; SET 0,(IX+D),H cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBC5:
   ; SET 0,(IX+D),L cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBC6:
   ; SET 0,(IX+D) cycles: 23
	invoke inst_Set,reg_di,0
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBC7:
   ; SET 0,(IX+D),A cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBC8:
   ; SET 1,(IX+D),B cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBC9:
   ; SET 1,(IX+D),C cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBCA:
   ; SET 1,(IX+D),D cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBCB:
   ; SET 1,(IX+D),E cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBCC:
   ; SET 1,(IX+D),H cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBCD:
   ; SET 1,(IX+D),L cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBCE:
   ; SET 1,(IX+D) cycles: 23
	invoke inst_Set,reg_di,1
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBCF:
   ; SET 1,(IX+D),A cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBD0:
   ; SET 2,(IX+D),B cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBD1:
   ; SET 2,(IX+D),C cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBD2:
   ; SET 2,(IX+D),D cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBD3:
   ; SET 2,(IX+D),E cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBD4:
   ; SET 2,(IX+D),H cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBD5:
   ; SET 2,(IX+D),L cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBD6:
   ; SET 2,(IX+D) cycles: 23
	invoke inst_Set,reg_di,2
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBD7:
   ; SET 2,(IX+D),A cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBD8:
   ; SET 3,(IX+D),B cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBD9:
   ; SET 3,(IX+D),C cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBDA:
   ; SET 3,(IX+D),D cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBDB:
   ; SET 3,(IX+D),E cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBDC:
   ; SET 3,(IX+D),H cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBDD:
   ; SET 3,(IX+D),L cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBDE:
   ; SET 3,(IX+D) cycles: 23
	invoke inst_Set,reg_di,3
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBDF:
   ; SET 3,(IX+D),A cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBE0:
   ; SET 4,(IX+D),B cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBE1:
   ; SET 4,(IX+D),C cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBE2:
   ; SET 4,(IX+D),D cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBE3:
   ; SET 4,(IX+D),E cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBE4:
   ; SET 4,(IX+D),H cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBE5:
   ; SET 4,(IX+D),L cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBE6:
   ; SET 4,(IX+D) cycles: 23
	invoke inst_Set,reg_di,4
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBE7:
   ; SET 4,(IX+D),A cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBE8:
   ; SET 5,(IX+D),B cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBE9:
   ; SET 5,(IX+D),C cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBEA:
   ; SET 5,(IX+D),D cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBEB:
   ; SET 5,(IX+D),E cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBEC:
   ; SET 5,(IX+D),H cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBED:
   ; SET 5,(IX+D),L cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBEE:
   ; SET 5,(IX+D) cycles: 23
	invoke inst_Set,reg_di,5
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBEF:
   ; SET 5,(IX+D),A cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBF0:
   ; SET 6,(IX+D),B cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBF1:
   ; SET 6,(IX+D),C cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBF2:
   ; SET 6,(IX+D),D cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBF3:
   ; SET 6,(IX+D),E cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBF4:
   ; SET 6,(IX+D),H cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBF5:
   ; SET 6,(IX+D),L cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBF6:
   ; SET 6,(IX+D) cycles: 23
	invoke inst_Set,reg_di,6
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBF7:
   ; SET 6,(IX+D),A cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBF8:
   ; SET 7,(IX+D),B cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBF9:
   ; SET 7,(IX+D),C cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBFA:
   ; SET 7,(IX+D),D cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBFB:
   ; SET 7,(IX+D),E cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBFC:
   ; SET 7,(IX+D),H cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBFD:
   ; SET 7,(IX+D),L cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBFE:
   ; SET 7,(IX+D) cycles: 23
	invoke inst_Set,reg_di,7
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDCBFF:
   ; SET 7,(IX+D),A cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDE1:
   ; POP IX cycles: 14
	invoke inst_POP,memPtr,OFFSET RegIX
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpDDE3:
   ; EX (SP),IX cycles: 23
	invoke register_indirect_addressing_mode,memPtr,RegSP
	invoke inst_EX8,OFFSET RegIXL,reg_di,
	mov x_cx,reg_di
	sub x_cx,memPtr
	inc cx
	mov reg_di,memPtr
	add reg_di,x_cx
	invoke inst_EX8,OFFSET RegIXH,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpDDE5:
   ; PUSH IX cycles: 15
	invoke inst_PUSH,memPtr,RegIX
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpDDE9:
   ; JP (IX) cycles: 8
	invoke inst_JP,OFFSET RegIX
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpDDF9:
   ; LD SP,IX cycles: 10
	invoke inst_LD16,OFFSET RegIX,OFFSET RegSP
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpFD04:
	jmp Op04
OpFD05:
	jmp Op05
OpFD06:
	jmp Op06
OpFD09:
   ; ADD IY,BC cycles: 15
	invoke inst_ADD16,OFFSET RegBC,OFFSET RegIY
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpFD0C:
	jmp Op0C
OpFD0D:
	jmp Op0D
OpFD0E:
	jmp Op0E
OpFD14:
	jmp Op14
OpFD15:
	jmp Op15
OpFD16:
	jmp Op16
OpFD1C:
	jmp Op1C
OpFD1D:
	jmp Op1D
OpFD1E:
	jmp Op1E
OpFD19:
   ; ADD IY,DE cycles: 15
	invoke inst_ADD16,OFFSET RegDE,OFFSET RegIY
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpFD21:
   ; LD IY,NN cycles: 14
	invoke immediate_addressing_mode_ext,memPtr
	invoke inst_LD16,reg_di,OFFSET RegIY
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpFD22:
   ; LD (NN),IY cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	invoke register_indirect_addressing_mode,memPtr,di
	invoke inst_LD16,OFFSET RegIY,reg_di
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpFD23:
   ; INC IY cycles: 10
	invoke inst_INC16,OFFSET RegIY
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpFD24:
   ; INC IYH cycles: 8
	invoke inst_INC8,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD25:
   ; DEC IYH cycles: 8
	invoke inst_DEC8,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD26:
   ; LD IYH,N cycles: 11
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegIYH
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpFD29:
   ; ADD IY,IY cycles: 15
	invoke inst_ADD16,OFFSET RegIY,OFFSET RegIY
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpFD2A:
   ; LD IY,(NN) cycles: 20
	invoke extended_indirect_addressing_mode,memPtr
	add reg_di,memPtr
	invoke inst_LD16,reg_di,OFFSET RegIY
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpFD2B:
   ; DEC IY cycles: 10
	invoke inst_DEC16,OFFSET RegIY
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
OpFD2C:
   ; INC IYL cycles: 8
	invoke inst_INC8,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD2D:
   ; DEC IYL cycles: 8
	invoke inst_DEC8,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD2E:
   ; LD IYL,N cycles: 11
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,OFFSET RegIYL
	invoke acumulate_opcode_cycles,11
	jmp Z80StepEnd
OpFD34:
   ; INC (IY+D) cycles: 23
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_INC8,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFD35:
   ; DEC (IY+D) cycles: 23
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_DEC8,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFD36:
   ; LD (IY+D),N cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	mov reg_si,reg_di
	invoke immediate_addressing_mode,memPtr
	invoke inst_LD8,reg_di,reg_si
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD39:
   ; ADD IY,SP cycles: 15
	invoke inst_ADD16,OFFSET RegSP,OFFSET RegIY
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpFD3C:
	jmp Op3C
OpFD3D:
	jmp Op3D
OpFD3E:
	jmp Op3E
OpFD40:
	jmp Op40
OpFD41:
	jmp Op41
OpFD42:
	jmp Op42
OpFD43:
	jmp Op43
OpFD44:
   ; LD B,IYH cycles: 8
	invoke inst_LD8,OFFSET RegIYH,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD45:
   ; LD B,IYL cycles: 8
	invoke inst_LD8,OFFSET RegIYL,OFFSET RegB
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD46:
   ; LD B,(IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,reg_di,OFFSET RegB
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD47:
	jmp Op47
OpFD48:
	jmp Op48
OpFD49:
	jmp Op49
OpFD4A:
	jmp Op4A
OpFD4B:
	jmp Op4B
OpFD4C:
   ; LD C,IYH cycles: 8
	invoke inst_LD8,OFFSET RegIYH,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD4D:
   ; LD C,IYL cycles: 8
	invoke inst_LD8,OFFSET RegIYL,OFFSET RegC
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD4E:
   ; LD C,(IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,reg_di,OFFSET RegC
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD4F:
	jmp Op4F
OpFD50:
	jmp Op50
OpFD51:
	jmp Op51
OpFD52:
	jmp Op52
OpFD53:
	jmp Op53
OpFD54:
   ; LD D,IYH cycles: 8
	invoke inst_LD8,OFFSET RegIYH,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD55:
   ; LD D,IYL cycles: 8
	invoke inst_LD8,OFFSET RegIYL,OFFSET RegD
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD56:
   ; LD D,(IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,reg_di,OFFSET RegD
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD57:
	jmp Op57
OpFD58:
	jmp Op58
OpFD59:
	jmp Op59
OpFD5A:
	jmp Op5A
OpFD5B:
	jmp Op5B
OpFD5C:
   ; LD E,IYH cycles: 8
	invoke inst_LD8,OFFSET RegIYH,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD5D:
   ; LD E,IYL cycles: 8
	invoke inst_LD8,OFFSET RegIYL,OFFSET RegE
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD5E:
   ; LD E,(IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,reg_di,OFFSET RegE
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD5F:
	jmp Op5F
OpFD60:
   ; LD IYH,B cycles: 8
	invoke inst_LD8,OFFSET RegB,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD61:
   ; LD IYH,C cycles: 8
	invoke inst_LD8,OFFSET RegC,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD62:
   ; LD IYH,D cycles: 8
	invoke inst_LD8,OFFSET RegD,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD63:
   ; LD IYH,E cycles: 8
	invoke inst_LD8,OFFSET RegE,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD64:
   ; LD IYH,IYH cycles: 8
	invoke inst_LD8,OFFSET RegIYH,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD65:
   ; LD IYH,IYL cycles: 8
	invoke inst_LD8,OFFSET RegIYL,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD66:
   ; LD H,(IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,reg_di,OFFSET RegH
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD67:
   ; LD IYH,A cycles: 8
	invoke inst_LD8,OFFSET RegA,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD68:
   ; LD IYL,B cycles: 8
	invoke inst_LD8,OFFSET RegB,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD69:
   ; LD IYL,C cycles: 8
	invoke inst_LD8,OFFSET RegC,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD6A:
   ; LD IYL,D cycles: 8
	invoke inst_LD8,OFFSET RegD,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD6B:
   ; LD IYL,E cycles: 8
	invoke inst_LD8,OFFSET RegE,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD6C:
   ; LD IYL,IYH cycles: 8
	invoke inst_LD8,OFFSET RegIYH,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD6D:
   ; LD IYL,IYL cycles: 8
	invoke inst_LD8,OFFSET RegIYL,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD6E:
   ; LD L,(IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,reg_di,OFFSET RegL
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD6F:
   ; LD IYL,A cycles: 8
	invoke inst_LD8,OFFSET RegA,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD70:
   ; LD (IY+D),B cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,OFFSET RegB,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD71:
   ; LD (IY+D),C cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,OFFSET RegC,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD72:
   ; LD (IY+D),D cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,OFFSET RegD,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD73:
   ; LD (IY+D),E cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,OFFSET RegE,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD74:
   ; LD (IY+D),H cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,OFFSET RegH,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD75:
   ; LD (IY+D),L cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,OFFSET RegL,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD76:
	jmp Z80StepEnd
OpFD77:
   ; LD (IY+D),A cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,OFFSET RegA,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD78:
	jmp Op78
OpFD79:
	jmp Op79
OpFD7A:
	jmp Op7A
OpFD7B:
	jmp op7B
OpFD7C:
   ; LD A,IYH cycles: 8
	invoke inst_LD8,OFFSET RegIYH,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD7D:
   ; LD A,IYL cycles: 8
	invoke inst_LD8,OFFSET RegIYL,OFFSET RegA
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD7E:
   ; LD A,(IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_LD8,reg_di,OFFSET RegA
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD7F:
	jmp Op7F
OpFD80:
	jmp Op80
OpFD81:
	jmp Op81
OpFD82:
	jmp	Op82
OpFD83:
	jmp	Op83
OpFD84:
   ; ADD A,IYH cycles: 8
	invoke inst_ADD8,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD85:
   ; ADD A,IYL cycles: 8
	invoke inst_ADD8,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD86:
   ; ADD A,(IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_ADD8,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD87:
	jmp Op87
OpFD88:
	jmp Op88
OpFD89:
	jmp Op89
OpFD8A:
	jmp	Op8A
OpFD8B:
	jmp	Op8B
OpFD8C:
   ; ADC A,IYH cycles: 8
	invoke inst_ADC8,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD8D:
   ; ADC A,IYL cycles: 8
	invoke inst_ADC8,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD8E:
   ; ADC A,(IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_ADC8,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD8F:
	jmp Op8F
OpFD90:
	jmp	Op90
OpFD91:
	jmp	Op91
OpFD92:
	jmp	Op92
OpFD93:
	jmp	Op93
OpFD94:
   ; SUB IYH cycles: 8
	invoke inst_SUB,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD95:
   ; SUB IYL cycles: 8
	invoke inst_SUB,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD96:
   ; SUB (IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_SUB,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD97:
	jmp Op97
OpFD98:
	jmp Op98
OpFD99:
	jmp Op99
OpFD9A:
	jmp Op9A
OpFD9B:
	jmp Op9B
OpFD9C:
   ; SBC A,IYH cycles: 8
	invoke inst_SBC8,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD9D:
   ; SBC A,IYL cycles: 8
	invoke inst_SBC8,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFD9E:
   ; SBC A,(IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_SBC8,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFD9F:
	jmp Op9F
OpFDA0:
	jmp OpA0
OpFDA1:
	jmp OpA1
OpFDA2:
	jmp OpA2
OpFDA3:
	jmp	OpA3
OpFDA4:
   ; AND IYH cycles: 8
	invoke inst_AND,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFDA5:
   ; AND IYL cycles: 8
	invoke inst_AND,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFDA6:
   ; AND (IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_AND,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFDA7:
	jmp OpA7
OpFDA8:
	jmp OpA8
OpFDA9:
	jmp OpA9
OpFDAA:
	jmp	OpAA
OpFDAB:
	jmp	OpAB
OpFDAC:
   ; XOR IYH cycles: 8
	invoke inst_XOR,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFDAD:
   ; XOR IYL cycles: 8
	invoke inst_XOR,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFDAE:
   ; XOR (IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_XOR,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFDAF:
	jmp OpAF
OpFDB0:
	jmp OpB0
OpFDB1:
	jmp OpB1
OpFDB2:
	jmp OpB2
OpFDB3:
	jmp	OpB3
OpFDB4:
   ; OR IYH cycles: 8
	invoke inst_OR,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFDB5:
   ; OR IYL cycles: 8
	invoke inst_OR,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFDB6:
   ; OR (IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_OR,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFDB7:
	jmp OpB7
OpFDB8:
	jmp	OpB8
OpFDB9:
	jmp	OpB9
OpFDBA:
	jmp OpBA
OpFDBB:
	jmp OpBB
OpFDBC:
   ; CP IYH cycles: 8
	invoke inst_CP,OFFSET RegIYH
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFDBD:
   ; CP IYL cycles: 8
	invoke inst_CP,OFFSET RegIYL
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFDBE:
   ; CP (IY+D) cycles: 19
	invoke indexed_addressing_mode,memPtr,RegIY
	invoke inst_CP,reg_di
	SET_WZ_FROM_VALUE_16 reg_tmp16
	invoke acumulate_opcode_cycles,19
	jmp Z80StepEnd
OpFDBF:
	jmp OpBF
OpFDCB:
	invoke indexed_addressing_mode,memPtr,RegIY
	SET_WZ_FROM_VALUE_16 reg_tmp16
	ProcessNextOpcode _TOpFDCB
OpFDCB00:
   ; RLC (IY+D),B cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB01:
   ; RLC (IY+D),C cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB02:
   ; RLC (IY+D),D cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB03:
   ; RLC (IY+D),E cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB04:
   ; RLC (IY+D),H cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB05:
   ; RLC (IY+D),L cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB06:
   ; RLC (IY+D) cycles: 23
	invoke inst_RLC,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB07:
   ; RLC (IY+D),A cycles: 23
	invoke inst_RLC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB08:
   ; RRC (IY+D),B cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB09:
   ; RRC (IY+D),C cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB0A:
   ; RRC (IY+D),D cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB0B:
   ; RRC (IY+D),E cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB0C:
   ; RRC (IY+D),H cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB0D:
   ; RRC (IY+D),L cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB0E:
   ; RRC (IY+D) cycles: 23
	invoke inst_RRC,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB0F:
   ; RRC (IY+D),A cycles: 23
	invoke inst_RRC,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB10:
   ; RL (IY+D),B cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB11:
   ; RL (IY+D),C cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB12:
   ; RL (IY+D),D cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB13:
   ; RL (IY+D),E cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB14:
   ; RL (IY+D),H cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB15:
   ; RL (IY+D),L cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB16:
   ; RL (IY+D) cycles: 23
	invoke inst_RL,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB17:
   ; RL (IY+D),A cycles: 23
	invoke inst_RL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB18:
   ; RR (IY+D),B cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB19:
   ; RR (IY+D),C cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB1A:
   ; RR (IY+D),D cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB1B:
   ; RR (IY+D),E cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB1C:
   ; RR (IY+D),H cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB1D:
   ; RR (IY+D),L cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB1E:
   ; RR (IY+D) cycles: 23
	invoke inst_RR,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB1F:
   ; RR (IY+D),A cycles: 23
	invoke inst_RR,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB20:
   ; SLA (IY+D),B cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB21:
   ; SLA (IY+D),C cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB22:
   ; SLA (IY+D),D cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB23:
   ; SLA (IY+D),E cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB24:
   ; SLA (IY+D),H cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB25:
   ; SLA (IY+D),L cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB26:
   ; SLA (IY+D) cycles: 23
	invoke inst_SLA,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB27:
   ; SLA (IY+D),A cycles: 23
	invoke inst_SLA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB28:
   ; SRA (IY+D),B cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB29:
   ; SRA (IY+D),C cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB2A:
   ; SRA (IY+D),D cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB2B:
   ; SRA (IY+D),E cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB2C:
   ; SRA (IY+D),H cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB2D:
   ; SRA (IY+D),L cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB2E:
   ; SRA (IY+D) cycles: 23
	invoke inst_SRA,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB2F:
   ; SRA (IY+D),A cycles: 23
	invoke inst_SRA,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB30:
   ; SLL (IY+D),B cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB31:
   ; SLL (IY+D),C cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB32:
   ; SLL (IY+D),D cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB33:
   ; SLL (IY+D),E cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB34:
   ; SLL (IY+D),H cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB35:
   ; SLL (IY+D),L cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB36:
   ; SLL (IY+D) cycles: 23
	invoke inst_SLL,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB37:
   ; SLL (IY+D),A cycles: 23
	invoke inst_SLL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB38:
   ; SRL (IY+D),B cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB39:
   ; SRL (IY+D),C cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB3A:
   ; SRL (IY+D),D cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB3B:
   ; SRL (IY+D),E cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB3C:
   ; SRL (IY+D),H cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB3D:
   ; SRL (IY+D),L cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB3E:
   ; SRL (IY+D) cycles: 23
	invoke inst_SRL,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB3F:
   ; SRL (IY+D),A cycles: 23
	invoke inst_SRL,reg_di
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB40:
	jmp OpFDCB46
OpFDCB41:
	jmp OpFDCB46
OpFDCB42:
	jmp OpFDCB46
OpFDCB43:
	jmp OpFDCB46
OpFDCB44:
	jmp OpFDCB46
OpFDCB45:
	jmp OpFDCB46
OpFDCB46:
   ; BIT 0,(IY+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,0
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpFDCB47:
	jmp OpFDCB46
OpFDCB48:
	jmp OpFDCB4E
OpFDCB49:
	jmp OpFDCB4E
OpFDCB4A:
	jmp OpFDCB4E
OpFDCB4B:
	jmp OpFDCB4E
OpFDCB4C:
	jmp OpFDCB4E
OpFDCB4D:
	jmp OpFDCB4E
OpFDCB4E:
   ; BIT 1,(IY+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,1
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpFDCB4F:
	jmp OpFDCB4E
OpFDCB50:
	jmp OpFDCB56
OpFDCB51:
	jmp OpFDCB56
OpFDCB52:
	jmp OpFDCB56
OpFDCB53:
	jmp OpFDCB56
OpFDCB54:
	jmp OpFDCB56
OpFDCB55:
	jmp OpFDCB56
OpFDCB56:
   ; BIT 2,(IY+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,2
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpFDCB57:
	jmp OpFDCB56
OpFDCB58:
	jmp OpFDCB5E
OpFDCB59:
	jmp OpFDCB5E
OpFDCB5A:
	jmp OpFDCB5E
OpFDCB5B:
	jmp OpFDCB5E
OpFDCB5C:
	jmp OpFDCB5E
OpFDCB5D:
	jmp OpFDCB5E
OpFDCB5E:
   ; BIT 3,(IY+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,3
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpFDCB5F:
	jmp OpFDCB5E
OpFDCB60:
	jmp OpFDCB66
OpFDCB61:
	jmp OpFDCB66
OpFDCB62:
	jmp OpFDCB66
OpFDCB63:
	jmp OpFDCB66
OpFDCB64:
	jmp OpFDCB66
OpFDCB65:
	jmp OpFDCB66
OpFDCB66:
   ; BIT 4,(IY+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,4
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpFDCB67:
	jmp OpFDCB66
OpFDCB68:
	jmp OpFDCB6E
OpFDCB69:
	jmp OpFDCB6E
OpFDCB6A:
	jmp OpFDCB6E
OpFDCB6B:
	jmp OpFDCB6E
OpFDCB6C:
	jmp OpFDCB6E
OpFDCB6D:
	jmp OpFDCB6E
OpFDCB6E:
   ; BIT 5,(IY+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,5
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpFDCB6F:
	jmp OpFDCB6E
OpFDCB70:
	jmp OpFDCB76
OpFDCB71:
	jmp OpFDCB76
OpFDCB72:
	jmp OpFDCB76
OpFDCB73:
	jmp OpFDCB76
OpFDCB74:
	jmp OpFDCB76
OpFDCB75:
	jmp OpFDCB76
OpFDCB76:
   ; BIT 6,(IY+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,6
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpFDCB77:
	jmp OpFDCB76
OpFDCB78:
	jmp OpFDCB7E
OpFDCB79:
	jmp OpFDCB7E
OpFDCB7A:
	jmp OpFDCB7E
OpFDCB7B:
	jmp OpFDCB7E
OpFDCB7C:
	jmp OpFDCB7E
OpFDCB7D:
	jmp OpFDCB7E
OpFDCB7E:
   ; BIT 7,(IY+D) cycles: 20
	invoke inst_BIT_IXIY,reg_di,7
	invoke acumulate_opcode_cycles,20
	jmp Z80StepEnd
OpFDCB7F:
	jmp OpFDCB7E
OpFDCB80:
   ; RES 0,(IY+D),B cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB81:
   ; RES 0,(IY+D),C cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB82:
   ; RES 0,(IY+D),D cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB83:
   ; RES 0,(IY+D),E cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB84:
   ; RES 0,(IY+D),H cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB85:
   ; RES 0,(IY+D),L cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB86:
   ; RES 0,(IY+D) cycles: 23
	invoke inst_RES,reg_di,0
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB87:
   ; RES 0,(IY+D),A cycles: 23
	invoke inst_RES,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB88:
   ; RES 1,(IY+D),B cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB89:
   ; RES 1,(IY+D),C cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB8A:
   ; RES 1,(IY+D),D cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB8B:
   ; RES 1,(IY+D),E cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB8C:
   ; RES 1,(IY+D),H cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB8D:
   ; RES 1,(IY+D),L cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB8E:
   ; RES 1,(IY+D) cycles: 23
	invoke inst_RES,reg_di,1
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB8F:
   ; RES 1,(IY+D),A cycles: 23
	invoke inst_RES,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB90:
   ; RES 2,(IY+D),B cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB91:
   ; RES 2,(IY+D),C cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB92:
   ; RES 2,(IY+D),D cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB93:
   ; RES 2,(IY+D),E cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB94:
   ; RES 2,(IY+D),H cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB95:
   ; RES 2,(IY+D),L cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB96:
   ; RES 2,(IY+D) cycles: 23
	invoke inst_RES,reg_di,2
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB97:
   ; RES 2,(IY+D),A cycles: 23
	invoke inst_RES,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB98:
   ; RES 3,(IY+D),B cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB99:
   ; RES 3,(IY+D),C cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB9A:
   ; RES 3,(IY+D),D cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB9B:
   ; RES 3,(IY+D),E cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB9C:
   ; RES 3,(IY+D),H cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB9D:
   ; RES 3,(IY+D),L cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB9E:
   ; RES 3,(IY+D) cycles: 23
	invoke inst_RES,reg_di,3
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCB9F:
   ; RES 3,(IY+D),A cycles: 23
	invoke inst_RES,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBA0:
   ; RES 4,(IY+D),B cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBA1:
   ; RES 4,(IY+D),C cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBA2:
   ; RES 4,(IY+D),D cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBA3:
   ; RES 4,(IY+D),E cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBA4:
   ; RES 4,(IY+D),H cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBA5:
   ; RES 4,(IY+D),L cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBA6:
   ; RES 4,(IY+D) cycles: 23
	invoke inst_RES,reg_di,4
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBA7:
   ; RES 4,(IY+D),A cycles: 23
	invoke inst_RES,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBA8:
   ; RES 5,(IY+D),B cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBA9:
   ; RES 5,(IY+D),C cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBAA:
   ; RES 5,(IY+D),D cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBAB:
   ; RES 5,(IY+D),E cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBAC:
   ; RES 5,(IY+D),H cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBAD:
   ; RES 5,(IY+D),L cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBAE:
   ; RES 5,(IY+D) cycles: 23
	invoke inst_RES,reg_di,5
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBAF:
   ; RES 5,(IY+D),A cycles: 23
	invoke inst_RES,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBB0:
   ; RES 6,(IY+D),B cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBB1:
   ; RES 6,(IY+D),C cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBB2:
   ; RES 6,(IY+D),D cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBB3:
   ; RES 6,(IY+D),E cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBB4:
   ; RES 6,(IY+D),H cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBB5:
   ; RES 6,(IY+D),L cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBB6:
   ; RES 6,(IY+D) cycles: 23
	invoke inst_RES,reg_di,6
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBB7:
   ; RES 6,(IY+D),A cycles: 23
	invoke inst_RES,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBB8:
   ; RES 7,(IY+D),B cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBB9:
   ; RES 7,(IY+D),C cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBBA:
   ; RES 7,(IY+D),D cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBBB:
   ; RES 7,(IY+D),E cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBBC:
   ; RES 7,(IY+D),H cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBBD:
   ; RES 7,(IY+D),L cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBBE:
   ; RES 7,(IY+D) cycles: 23
	invoke inst_RES,reg_di,7
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBBF:
   ; RES 7,(IY+D),A cycles: 23
	invoke inst_RES,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBC0:
   ; SET 0,(IY+D),B cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBC1:
   ; SET 0,(IY+D),C cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBC2:
   ; SET 0,(IY+D),D cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBC3:
   ; SET 0,(IY+D),E cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBC4:
   ; SET 0,(IY+D),H cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBC5:
   ; SET 0,(IY+D),L cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBC6:
   ; SET 0,(IY+D) cycles: 23
	invoke inst_Set,reg_di,0
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBC7:
   ; SET 0,(IY+D),A cycles: 23
	invoke inst_Set,reg_di,0
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBC8:
   ; SET 1,(IY+D),B cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBC9:
   ; SET 1,(IY+D),C cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBCA:
   ; SET 1,(IY+D),D cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBCB:
   ; SET 1,(IY+D),E cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBCC:
   ; SET 1,(IY+D),H cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBCD:
   ; SET 1,(IY+D),L cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBCE:
   ; SET 1,(IY+D) cycles: 23
	invoke inst_Set,reg_di,1
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBCF:
   ; SET 1,(IY+D),A cycles: 23
	invoke inst_Set,reg_di,1
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBD0:
   ; SET 2,(IY+D),B cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBD1:
   ; SET 2,(IY+D),C cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBD2:
   ; SET 2,(IY+D),D cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBD3:
   ; SET 2,(IY+D),E cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBD4:
   ; SET 2,(IY+D),H cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBD5:
   ; SET 2,(IY+D),L cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBD6:
   ; SET 2,(IY+D) cycles: 23
	invoke inst_Set,reg_di,2
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBD7:
   ; SET 2,(IY+D),A cycles: 23
	invoke inst_Set,reg_di,2
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBD8:
   ; SET 3,(IY+D),B cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBD9:
   ; SET 3,(IY+D),C cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBDA:
   ; SET 3,(IY+D),D cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBDB:
   ; SET 3,(IY+D),E cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBDC:
   ; SET 3,(IY+D),H cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBDD:
   ; SET 3,(IY+D),L cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBDE:
   ; SET 3,(IY+D) cycles: 23
	invoke inst_Set,reg_di,3
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBDF:
   ; SET 3,(IY+D),A cycles: 23
	invoke inst_Set,reg_di,3
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBE0:
   ; SET 4,(IY+D),B cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBE1:
   ; SET 4,(IY+D),C cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBE2:
   ; SET 4,(IY+D),D cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBE3:
   ; SET 4,(IY+D),E cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBE4:
   ; SET 4,(IY+D),H cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBE5:
   ; SET 4,(IY+D),L cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBE6:
   ; SET 4,(IY+D) cycles: 23
	invoke inst_Set,reg_di,4
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBE7:
   ; SET 4,(IY+D),A cycles: 23
	invoke inst_Set,reg_di,4
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBE8:
   ; SET 5,(IY+D),B cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBE9:
   ; SET 5,(IY+D),C cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBEA:
   ; SET 5,(IY+D),D cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBEB:
   ; SET 5,(IY+D),E cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBEC:
   ; SET 5,(IY+D),H cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBED:
   ; SET 5,(IY+D),L cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBEE:
   ; SET 5,(IY+D) cycles: 23
	invoke inst_Set,reg_di,5
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBEF:
   ; SET 5,(IY+D),A cycles: 23
	invoke inst_Set,reg_di,5
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBF0:
   ; SET 6,(IY+D),B cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBF1:
   ; SET 6,(IY+D),C cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBF2:
   ; SET 6,(IY+D),D cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBF3:
   ; SET 6,(IY+D),E cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBF4:
   ; SET 6,(IY+D),H cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBF5:
   ; SET 6,(IY+D),L cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBF6:
   ; SET 6,(IY+D) cycles: 23
	invoke inst_Set,reg_di,6
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBF7:
   ; SET 6,(IY+D),A cycles: 23
	invoke inst_Set,reg_di,6
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBF8:
   ; SET 7,(IY+D),B cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegB
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBF9:
   ; SET 7,(IY+D),C cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegC
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBFA:
   ; SET 7,(IY+D),D cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegD
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBFB:
   ; SET 7,(IY+D),E cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegE
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBFC:
   ; SET 7,(IY+D),H cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegH
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBFD:
   ; SET 7,(IY+D),L cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegL
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBFE:
   ; SET 7,(IY+D) cycles: 23
	invoke inst_Set,reg_di,7
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDCBFF:
   ; SET 7,(IY+D),A cycles: 23
	invoke inst_Set,reg_di,7
	CopyMemToMem8 reg_di,OFFSET RegA
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDE1:
   ; POP IY cycles: 14
	invoke inst_POP,memPtr,OFFSET RegIY
	invoke acumulate_opcode_cycles,14
	jmp Z80StepEnd
OpFDE3:
   ; EX (SP),IY cycles: 23
	invoke register_indirect_addressing_mode,memPtr,RegSP
	invoke inst_EX8,OFFSET RegIYL,reg_di,
	mov x_cx,reg_di
	sub x_cx,memPtr
	inc cx
	mov reg_di,memPtr
	add reg_di,x_cx
	invoke inst_EX8,OFFSET RegIYH,reg_di
	invoke acumulate_opcode_cycles,23
	jmp Z80StepEnd
OpFDE5:
   ; PUSH IY cycles: 15
	invoke inst_PUSH,memPtr,RegIY
	invoke acumulate_opcode_cycles,15
	jmp Z80StepEnd
OpFDE9:
   ; JP (IY) cycles: 8
	invoke inst_JP,OFFSET RegIY
	invoke acumulate_opcode_cycles,8
	jmp Z80StepEnd
OpFDF9:
   ; LD SP,IY cycles: 10
	invoke inst_LD16,OFFSET RegIY,OFFSET RegSP
	invoke acumulate_opcode_cycles,10
	jmp Z80StepEnd
Z80StepEnd:
	xor rax,rax
	ret
cpu_z80_step ENDP
END