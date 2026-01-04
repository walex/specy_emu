; https://ps4star.github.io/z80studio/
;https://clrhome.org/table/


.data

include x64_arch.inc
include invoke.inc
include macros.inc	  
include cpuregs.inc
include interrupts.inc
include bitops_x64.inc
include dirs_x64.inc	
include opcodesimpl_x64.inc

.code

Z80_CPU_MAIN_LOOP MACRO

			mov reg_pc,rcx
			mov memPtr,reg_pc
			add reg_pc,rdx
Z80Halt:
			IncRegR
			jmp Op00			
Z80IsNop:
			cmp Rec_Opcode,0
			jz Z80IsNopNoLog
			PRINT_HEXA_64 Rec_Opcode
Z80IsNopNoLog:
Z80Loop:
			mov Rec_Opcode,0

			invoke execute_interrupts,memPtr
			cmp HALT,1
			jz Z80Halt
			invoke CLK_reset
			ProcesarOpcodeFromRom _TOp1B

ENDM

Z80_CPU_MAIN_LOOP_TEST MACRO

			mov reg_pc,rcx
			mov memPtr,reg_pc
			xor x_bx,x_bx
			mov bx,reg_pc_tmp
			add reg_pc,x_bx
			IncRegR
			invoke CLK_reset
			ProcesarOpcodeFromRom _TOp1B
Z80IsNop:
			xor x_ax,x_ax
			not x_ax
Z80Loop:			
			xor rcx,rcx
			mov rcx,reg_pc
			sub rcx,memPtr
			mov reg_pc_tmp,cx
			ret
ENDM

Z80CPU PROC

; params
; mem:PTR BYTE -> rcx
; pc init value: PTR BYTE -> rdx

.data

BYTE_PTR TYPEDEF PTR BYTE
memPtr BYTE_PTR 0
Rec_Opcode PTR_DATA_TYPE 0

include opcodesdef.inc  

.code
		Z80_CPU_MAIN_LOOP
		;Z80_CPU_MAIN_LOOP_TEST		            
       Op00:
			;00		NOP			4	1	1
            nop  		
			invoke CLK_sync,4,1
            jmp Z80IsNop
       Op01:
			;01 n n		LD BC,nn		10	2	
			invoke DIR_INMEDIATO_EXT,memPtr			
            invoke Inst_LD16,reg_di,OFFSET RegBC            			
			invoke CLK_sync,10,2
            jmp Z80Loop
       Op02:
			;02		LD (BC),A		7	2				
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegBC									
            invoke Inst_LD8,OFFSET RegA,reg_di						
			invoke CLK_sync,7,2
            jmp Z80Loop
       Op03:
			;03		INC BC			6	1	1
			invoke Inst_INC16,OFFSET RegBC					
			invoke CLK_sync,6,1
			jmp Z80Loop
       Op04:
			;04		INC B			4	1	1
			invoke Inst_INC8,OFFSET RegB			
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op05:
			;05		DEC B			4	1	1
			invoke Inst_DEC8,OFFSET RegB			
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op06:
			;06 n		LD B,n			7	2	
			invoke DIR_INMEDIATO,memPtr			
            invoke Inst_LD8,reg_di,OFFSET RegB			
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op07:
			;07		RLCA			4	1	1
			invoke Inst_RLCA		
			invoke CLK_sync,4,1	
			jmp Z80Loop	
       Op08:
			;08		EX AF,AF’		4	1	1
			invoke Inst_EX,OFFSET RegAF_ESP,OFFSET RegAF			
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op09:
			;09		ADD HL,BC		11	3	1
			invoke Inst_ADD16,OFFSET RegBC,OFFSET RegHL			
			invoke CLK_sync,11,3
			jmp Z80Loop
       Op0A:
			;0A		LD A,(BC)		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegBC
            invoke Inst_LD8,reg_di,OFFSET RegA			 			
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op0B:
			;0B		DEC BC			6	1	1
			invoke Inst_DEC16,OFFSET RegBC							
			invoke CLK_sync,6,1
			jmp Z80Loop
       Op0C:
			;0C		INC C			4	1	1
			invoke Inst_INC8,OFFSET RegC			
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op0D:
			;0D		DEC C			4	1	1
			invoke Inst_DEC8,OFFSET RegC			
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op0E:
			;0E n		LD C,n			7	2	
			invoke DIR_INMEDIATO,memPtr			
            invoke Inst_LD8,reg_di,OFFSET RegC			
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op0F:
			;0F		RRCA			4	1	1
			invoke Inst_RRCA		
			invoke CLK_sync,4,1	
			jmp Z80Loop			
       Op10:
			;10 e		DJNZ (PC+e)		8/13	2/3	1/1	(met/not met)
			dec RegB			
			jnz Op18
			INC_REG_PC memPtr	
			invoke CLK_sync,8,2					
			jmp Z80Loop
       Op11:
			;11 n n		LD DE,nn		10	2	
			invoke DIR_INMEDIATO_EXT,memPtr							
            invoke Inst_LD16,reg_di,OFFSET RegDE            												
			invoke CLK_sync,10,2
            jmp Z80Loop
       Op12:
			;12		LD (DE),A		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegDE						
            invoke Inst_LD8,OFFSET RegA,reg_di            
			invoke CLK_sync,7,2
            jmp Z80Loop
       Op13:
			;13		INC DE			6	1	1
			invoke Inst_INC16,OFFSET RegDE		
			invoke CLK_sync,6,1
			jmp Z80Loop
       Op14:
			;14		INC D			6	1	1
			invoke Inst_INC8,OFFSET RegD
			invoke CLK_sync,6,1
			jmp Z80Loop
       Op15:
			;15		DEC D			4	1	1
			invoke Inst_DEC8,OFFSET RegD
			invoke CLK_sync,4,1
			jmp Z80Loop	
       Op16:
			;16 n		LD D,n			7	2	
			invoke DIR_INMEDIATO,memPtr			
            invoke Inst_LD8,reg_di,OFFSET RegD
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op17:
			;17		RLA			4	1	1
			invoke Inst_RLA
			invoke CLK_sync,4,1
			jmp Z80Loop		
       Op18:
			;18 e		JR (PC+e)		12	3	1			 
			invoke DIR_RELATIVO				
			invoke CLK_sync,12,3		
			jmp Z80Loop
       Op19:
			;19		ADD HL,DE		11	3	1
			invoke Inst_ADD16,OFFSET RegDE,OFFSET RegHL
			invoke CLK_sync,11,3
			jmp Z80Loop
       Op1A:
			;1A		LD A,(DE)		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegDE
            invoke Inst_LD8,reg_di,OFFSET RegA			 
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op1B:
			;1B		DEC DE			6	1	1
			invoke Inst_DEC16,OFFSET RegDE					
			invoke CLK_sync,6,1
			jmp Z80Loop
       Op1C:
			;1C		INC E			4	1	1
			invoke Inst_INC8,OFFSET RegE
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op1D:
			;1D		DEC E			4	1	1
			invoke Inst_DEC8,OFFSET RegE
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op1E:
			;1E n		LD E,n			7	2	
			invoke DIR_INMEDIATO,memPtr			
            invoke Inst_LD8,reg_di,OFFSET RegE
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op1F:
			;1F		RRA			4	1	1
			invoke Inst_RRA
			invoke CLK_sync,4,1
			jmp Z80Loop		
       Op20:
			;20 e		JR NZ,(PC+e)		12/7	3/2	1/1	(met/not met)						
			test RegF,40h
			jz Op18
			INC_REG_PC memPtr			
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op21:
			;21 n n		LD HL,nn		10	2	
			invoke DIR_INMEDIATO_EXT,memPtr			
            invoke Inst_LD16,reg_di,OFFSET RegHL            
			invoke CLK_sync,10,2
            jmp Z80Loop
       Op22:
			;22 n n		LD (nn),HL		16	5	
			invoke DIR_EXT,memPtr	   	 	   	  	  	  
			invoke DIR_REGISTRO_INDIRECTO,memPtr,di
			invoke Inst_LD16,OFFSET RegHL,reg_di	
			invoke CLK_sync,16,5
			jmp Z80Loop
       Op23:
			;23		INC HL			6	1	1
			invoke Inst_INC16,OFFSET RegHL			
			invoke CLK_sync,6,1
			jmp Z80Loop			
       Op24:
			;24		INC H			4	1	1
			invoke Inst_INC8,OFFSET RegH
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op25:
			;25		DEC H			4	1	1
			invoke Inst_DEC8,OFFSET RegH
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op26:
			;26 n		LD H,n			7	2	
			invoke DIR_INMEDIATO,memPtr			
            invoke Inst_LD8,reg_di,OFFSET RegH
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op27:
			;27		DAA			4	1	1
			invoke Inst_DAA
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op28:
			;28 e		JR Z,(PC+e)		12/7	3/2	1/1	(met/not met)
			test RegF,40h
			jnz Op18
			INC_REG_PC memPtr
			invoke CLK_sync,7,3
			jmp Z80Loop
       Op29:
			;29		ADD HL,HL		11	3	1
			invoke Inst_ADD16,OFFSET RegHL,OFFSET RegHL
			invoke CLK_sync,11,3
			jmp Z80Loop
       Op2A:
			;2A n n		LD HL,(nn)		16	5	
			invoke DIR_EXT,memPtr
			add reg_di,memPtr	 						
			invoke Inst_LD16,reg_di,OFFSET RegHL	
			invoke CLK_sync,16,5
			jmp Z80Loop
       Op2B:
			;2B		DEC HL			6	1	1			
			invoke Inst_DEC16,OFFSET RegHL				
			invoke CLK_sync,6,1
			jmp Z80Loop
       Op2C:
			;2C		INC L			4	1	1
			invoke Inst_INC8,OFFSET RegL
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op2D:
			;2D		DEC L			4	1	1
			invoke Inst_DEC8,OFFSET RegL
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op2E:
			;2E n		LD L,n			7	2	
			invoke DIR_INMEDIATO,memPtr			
            invoke Inst_LD8,reg_di,OFFSET RegL
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op2F:
			;2F		CPL			4	1	1
			invoke Inst_CPL
			invoke CLK_sync,4,1
			jmp Z80Loop				
       Op30:
			;30 e		JR NC,(PC+e)		12/7	3/2	1/1	(met/not met)
			test RegF,1
			jz Op18
			INC_REG_PC memPtr
			invoke CLK_sync,7,2
			jmp Z80Loop

       Op31:
			;31 n n		LD SP,nn		10	2	
			invoke DIR_INMEDIATO_EXT,memPtr			
            invoke Inst_LD16,reg_di,OFFSET RegSP            
			invoke CLK_sync,10,2
            jmp Z80Loop	
       Op32:
			;32 n n		LD (nn),A		13	4				
			invoke DIR_EXT,memPtr	   	 	   	  	  	  
			invoke DIR_REGISTRO_INDIRECTO,memPtr,di
			invoke Inst_LD8,OFFSET RegA,reg_di	
			invoke CLK_sync,13,4
			jmp Z80Loop
       Op33:	
			;33		INC SP			6	1	1
			invoke Inst_INC16,OFFSET RegSP		
			invoke CLK_sync,6,1
			jmp Z80Loop
       Op34:
			;34		INC (HL)		11	3	1
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL			
			invoke Inst_INC8,reg_di
			invoke CLK_sync,11,3
			jmp Z80Loop
       Op35:
			;35		DEC (HL)		11	3	1
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL			
			invoke Inst_DEC8,reg_di
			invoke CLK_sync,11,3
			jmp Z80Loop
       Op36:
			;36 n		LD (HL),n		10	3	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			mov reg_si,reg_di
			invoke DIR_INMEDIATO,memPtr
			invoke Inst_LD8,reg_di,reg_si
			invoke CLK_sync,10,3
			jmp Z80Loop
       Op37:
			;37		SCF			4	1	1
			invoke Inst_SCF
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op38:
			;38 e		JR C,(PC+e)		12/7	3/2	1/1	(met/not met)
			test RegF,1
			jnz Op18
			INC_REG_PC memPtr
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op39:
			;39		ADD HL,SP		11	3	1
			invoke Inst_ADD16,OFFSET RegSP,OFFSET RegHL
			invoke CLK_sync,11,3
			jmp Z80Loop
       Op3A:
			;3A n n		LD A,(nn)		13	4	
			invoke DIR_EXT,memPtr
			add reg_di,memPtr  	  	  	  
			invoke Inst_LD8,reg_di,OFFSET RegA	
			invoke CLK_sync,13,4
			jmp Z80Loop
       Op3B:
			;3B		DEC SP			6	1	1
			invoke Inst_DEC16,OFFSET RegSP					
			invoke CLK_sync,6,1
			jmp Z80Loop	
       Op3C:
			;3C		INC A			4	1	1
			invoke Inst_INC8,OFFSET RegA
			invoke CLK_sync,4,1
			jmp Z80Loop 	
       Op3D:
			;3D		DEC A			4	1	1
			invoke Inst_DEC8,OFFSET RegA
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op3E:
			;3E n		LD A,n			7	2	
			invoke DIR_INMEDIATO,memPtr			
            invoke Inst_LD8,reg_di,OFFSET RegA
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op3F:
			;3F		CCF			4	1	1
			invoke Inst_CCF
			invoke CLK_sync,4,1
			jmp Z80Loop	
       Op40:
			;40		LD B,B			4	1	1
			invoke Inst_LD8,OFFSET RegB,OFFSET RegB            
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op41:
			;41		LD B,C			4	1	1
			invoke Inst_LD8,OFFSET RegC,OFFSET RegB
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op42:
			;42		LD B,D			4	1	1
			invoke Inst_LD8,OFFSET RegD,OFFSET RegB
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op43:
			;43		LD B,E			4	1	1
			invoke Inst_LD8,OFFSET RegE,OFFSET RegB
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op44:
			;44		LD B,H			4	1	1
			invoke Inst_LD8,OFFSET RegH,OFFSET RegB
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op45:
			;45		LD B,L			4	1	1
			invoke Inst_LD8,OFFSET RegL,OFFSET RegB
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op46:
			;46		LD B,(HL)		7	2				
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
            invoke Inst_LD8,reg_di,OFFSET RegB			 
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op47:
			;47		LD B,A			4	1	1
			invoke Inst_LD8,OFFSET RegA,OFFSET RegB
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op48:
			;48		LD C,B			4	1	1
			invoke Inst_LD8,OFFSET RegB,OFFSET RegC
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op49:
			;49		LD C,C			4	1	1
			invoke Inst_LD8,OFFSET RegC,OFFSET RegC
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op4A:
			;4A		LD C,D			4	1	1
			invoke Inst_LD8,OFFSET RegD,OFFSET RegC
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op4B:
			;4B		LD C,E			4	1	1
			invoke Inst_LD8,OFFSET RegE,OFFSET RegC
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op4C:
			;4C		LD C,H			4	1	1
			invoke Inst_LD8,OFFSET RegH,OFFSET RegC
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op4D:
			;4D		LD C,L			4	1	1
			invoke Inst_LD8,OFFSET RegL,OFFSET RegC
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op4E:
			;4E		LD C,(HL)		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
            invoke Inst_LD8,reg_di,OFFSET RegC
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op4F:
			;4F		LD C,A			4	1	1
			invoke Inst_LD8,OFFSET RegA,OFFSET RegC
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op50:
			;50		LD D,B			4	1	1
			invoke Inst_LD8,OFFSET RegB,OFFSET RegD
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op51:
			;51		LD D,C			4	1	1
			invoke Inst_LD8,OFFSET RegC,OFFSET RegD
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op52:
			;52		LD D,D			4	1	1
			invoke Inst_LD8,OFFSET RegD,OFFSET RegD
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op53:
			;53		LD D,E			4	1	1
			invoke Inst_LD8,OFFSET RegE,OFFSET RegD
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op54:
			;54		LD D,H			4	1	1
			invoke Inst_LD8,OFFSET RegH,OFFSET RegD
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op55:
			;55		LD D,L			4	1	1
			invoke Inst_LD8,OFFSET RegL,OFFSET RegD
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op56:
			;56		LD D,(HL)		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
            invoke Inst_LD8,reg_di,OFFSET RegD
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op57:
			;57		LD D,A			4	1	1
			invoke Inst_LD8,OFFSET RegA,OFFSET RegD
            invoke CLK_sync,4,1
			jmp Z80Loop	
       Op58:	
			;58		LD E,B			4	1	1
			invoke Inst_LD8,OFFSET RegB,OFFSET RegE
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op59:
			;59		LD E,C			4	1	1
			invoke Inst_LD8,OFFSET RegC,OFFSET RegE
			invoke CLK_sync,4,1
            jmp Z80Loop		
       Op5A:
			;5A		LD E,D			4	1	1
			invoke Inst_LD8,OFFSET RegD,OFFSET RegE
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op5B:
			;5B		LD E,E			4	1	1
			invoke Inst_LD8,OFFSET RegE,OFFSET RegE
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op5C:
			;5C		LD E,H			4	1	1
			invoke Inst_LD8,OFFSET RegH,OFFSET RegE
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op5D:
			;5D		LD E,L			4	1	1
			invoke Inst_LD8,OFFSET RegL,OFFSET RegE
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op5E:
			;5E		LD E,(HL)		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
            invoke Inst_LD8,reg_di,OFFSET RegE
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op5F:
			;5F		LD E,A			4	1	1
			invoke Inst_LD8,OFFSET RegA,OFFSET RegE
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op60:
			;60		LD H,B			4	1	1
			invoke Inst_LD8,OFFSET RegB,OFFSET RegH
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op61:
			;61		LD H,C			4	1	1
			invoke Inst_LD8,OFFSET RegC,OFFSET RegH
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op62:
			;62		LD H,D			4	1	1
			invoke Inst_LD8,OFFSET RegD,OFFSET RegH
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op63:
			;63		LD H,E			4	1	1
			invoke Inst_LD8,OFFSET RegE,OFFSET RegH
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op64:
			;64		LD H,H			4	1	1
			invoke Inst_LD8,OFFSET RegH,OFFSET RegH
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op65:
			;65		LD H,L			4	1	1
			invoke Inst_LD8,OFFSET RegL,OFFSET RegH
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op66:
			;66		LD H,(HL)		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL			
            invoke Inst_LD8,reg_di,OFFSET RegH
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op67:
			;67		LD H,A			4	1	1
			invoke Inst_LD8,OFFSET RegA,OFFSET RegH
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op68:
			;68		LD L,B			4	1	1
			invoke Inst_LD8,OFFSET RegB,OFFSET RegL
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op69:
			;69		LD L,C			4	1	1
			invoke Inst_LD8,OFFSET RegC,OFFSET RegL
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op6A:
			;6A		LD L,D			4	1	1
			invoke Inst_LD8,OFFSET RegD,OFFSET RegL
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op6B:
			;6B		LD L,E			4	1	1
			invoke Inst_LD8,OFFSET RegE,OFFSET RegL
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op6C:
			;6C		LD L,H			4	1	1
			invoke Inst_LD8,OFFSET RegH,OFFSET RegL
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op6D:
			;6D		LD L,L			4	1	1
			invoke Inst_LD8,OFFSET RegL,OFFSET RegL
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op6E:
			;6E		LD L,(HL)		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL			
            invoke Inst_LD8,reg_di,OFFSET RegL
			invoke CLK_sync,7,2
			jmp Z80Loop	
       Op6F:
			;6F		LD L,A			4	1	1
			invoke Inst_LD8,OFFSET RegA,OFFSET RegL
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op70:
			;70		LD (HL),B		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL									
            invoke Inst_LD8,OFFSET RegB,reg_di
			invoke CLK_sync,7,2
            jmp Z80Loop
       Op71:
			;71		LD (HL),C		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL									
            invoke Inst_LD8,OFFSET RegC,reg_di            
			invoke CLK_sync,7,2
            jmp Z80Loop

       Op72:
			;72		LD (HL),D		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL									
            invoke Inst_LD8,OFFSET RegD,reg_di           
			invoke CLK_sync,7,2
            jmp Z80Loop
       Op73:
			;73		LD (HL),E		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL									
            invoke Inst_LD8,OFFSET RegE,reg_di            
			invoke CLK_sync,7,2
            jmp Z80Loop
       Op74:
			;74		LD (HL),H		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL									
            invoke Inst_LD8,OFFSET RegH,reg_di         
			invoke CLK_sync,7,2
            jmp Z80Loop
       Op75:
			;75		LD (HL),L		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL									
            invoke Inst_LD8,OFFSET RegL,reg_di         
			invoke CLK_sync,7,2
            jmp Z80Loop
       Op76:
			 ;76		HALT			4	1	1	(repeated till next int)
			 mov HALT,1
			 invoke CLK_sync,4,1
			 jmp Z80Loop
       Op77:
			;77		LD (HL),A		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL									
            invoke Inst_LD8,OFFSET RegA,reg_di         
			invoke CLK_sync,7,2
            jmp Z80Loop
       Op78:
			;78		LD A,B			4	1	1
			invoke Inst_LD8,OFFSET RegB,OFFSET RegA
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op79:
			;79		LD A,C			4	1	1
			invoke Inst_LD8,OFFSET RegC,OFFSET RegA
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op7A:
			;7A		LD A,D			4	1	1
			invoke Inst_LD8,OFFSET RegD,OFFSET RegA
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op7B:
			;7B		LD A,E			4	1	1
			invoke Inst_LD8,OFFSET RegE,OFFSET RegA
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op7C:
			;7C		LD A,H			4	1	1
			invoke Inst_LD8,OFFSET RegH,OFFSET RegA
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op7D:
			;7D		LD A,L			4	1	1
			invoke Inst_LD8,OFFSET RegL,OFFSET RegA
			invoke CLK_sync,4,1
            jmp Z80Loop
       Op7E:
			;7E		LD A,(HL)		7	2	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
            invoke Inst_LD8,reg_di,OFFSET RegA
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op7F:
			;7F		LD A,A			4	1	1
			invoke Inst_LD8,OFFSET RegA,OFFSET RegA
			invoke CLK_sync,4,1
            jmp Z80Loop	
       Op80:
			;80		ADD A,B			4	1	1
			invoke Inst_ADD8,OFFSET RegB
			invoke CLK_sync,4,1
			jmp Z80Loop					
       Op81:
			;81		ADD A,C			4	1	1
			invoke Inst_ADD8,OFFSET RegC
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op82:
			;82		ADD A,D			4	1	1
			invoke Inst_ADD8,OFFSET RegD
			invoke CLK_sync,4,1
			jmp Z80Loop

       Op83:
		    ;83		ADD A,E			4	1	1
			 invoke Inst_ADD8,OFFSET RegE
			 invoke CLK_sync,4,1
			 jmp Z80Loop

       Op84:
			;84		ADD A,H			4	1	1
			invoke Inst_ADD8,OFFSET RegH
			invoke CLK_sync,4,1
			jmp Z80Loop

       Op85:
			;85		ADD A,L			4	1	1
			 invoke Inst_ADD8,OFFSET RegL
			 invoke CLK_sync,4,1
			 jmp Z80Loop

       Op86:
			;86		ADD A,(HL)		7	2	1
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			invoke Inst_ADD8,reg_di
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op87:
			 ;87		ADD A,A			4	1	1
			 invoke Inst_ADD8,OFFSET RegA
			 invoke CLK_sync,4,1
			 jmp Z80Loop
       Op88:
			;88		ADC A,B			4	1	1
			invoke Inst_ADC8,OFFSET RegB
			invoke CLK_sync,4,1
			jmp Z80Loop					
       Op89:
			;89		ADC A,C			4	1	1
			invoke Inst_ADC8,OFFSET RegC
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op8A:
			;8A		ADC A,D			4	1	1
			invoke Inst_ADC8,OFFSET RegD
			invoke CLK_sync,4,1
			jmp Z80Loop

       Op8B:
			;8B		ADC A,E			4	1	1
			invoke Inst_ADC8,OFFSET RegE
			invoke CLK_sync,4,1
			jmp Z80Loop

       Op8C:
			;8C		ADC A,H			4	1	1
			invoke Inst_ADC8,OFFSET RegH
			invoke CLK_sync,4,1
			jmp Z80Loop

       Op8D:
	        ;8D		ADC A,L			4	1	1
			 invoke Inst_ADC8,OFFSET RegL
			 invoke CLK_sync,4,1
			 jmp Z80Loop
       Op8E:
			;8E		ADC A,(HL)		7	2	1
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			invoke Inst_ADC8,reg_di
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op8F:
			;8F		ADC A,A			4	1	1
			 invoke Inst_ADC8,OFFSET RegA
			 invoke CLK_sync,4,1
			 jmp Z80Loop
       Op90:
			;90		SUB B			4	1	1
			invoke Inst_SUB,OFFSET RegB
			invoke CLK_sync,4,1
			jmp Z80Loop				
       Op91:
			;91		SUB C			4	1	1
			invoke Inst_SUB,OFFSET RegC
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op92:
			;92		SUB D			4	1	1
			invoke Inst_SUB,OFFSET RegD
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op93:
			;93		SUB E			4	1	1
			invoke Inst_SUB,OFFSET RegE
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op94:
			;94		SUB H			4	1	1
			invoke Inst_SUB,OFFSET RegH
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op95:
			;95		SUB L			4	1	1
			invoke Inst_SUB,OFFSET RegL
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op96:
			;96		SUB (HL)		7	2	1
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
            invoke Inst_SUB,reg_di
			invoke CLK_sync,7,2
			jmp Z80Loop
       Op97:
			;97		SUB A			4	1	1
			invoke Inst_SUB,OFFSET RegA
			invoke CLK_sync,4,1
			jmp Z80Loop

       Op98:
			;98		SBC A,B			4	1	1
			invoke Inst_SBC8,OFFSET RegB
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op99:
			;99		SBC A,C			4	1	1
			invoke Inst_SBC8,OFFSET RegC
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op9A:
			;9A		SBC A,D			4	1	1
			invoke Inst_SBC8,OFFSET RegD
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op9B:
			;9B		SBC A,E			4	1	1
			invoke Inst_SBC8,OFFSET RegE
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op9C:
			;9C		SBC A,H			4	1	1
			invoke Inst_SBC8,OFFSET RegH
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op9D:
			;9D		SBC A,L			4	1	1
			invoke Inst_SBC8,OFFSET RegL
			invoke CLK_sync,4,1
			jmp Z80Loop
       Op9E:
			;9E		SBC A,(HL)		7	2	1
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			invoke Inst_SBC8,reg_di
			invoke CLK_sync,7,2
			jmp Z80Loop

       Op9F:
			;9F		SBC A,A			4	1	1
			invoke Inst_SBC8,OFFSET RegA
			invoke CLK_sync,4,1
			jmp Z80Loop

       OpA0:
			;A0		AND B			4	1	1
			invoke Inst_AND,RegB
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpA1:
			;A1		AND C			4	1	1
			invoke Inst_AND,RegC
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpA2:
			;A2		AND D			4	1	1
			invoke Inst_AND,RegD
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpA3:
			;A3		AND E			4	1	1
			invoke Inst_AND,RegE
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpA4:
			;A4		AND H			4	1	1
			invoke Inst_AND,RegH
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpA5:
			;A5		AND L			4	1	1
			invoke Inst_AND,RegL
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpA6:
			;A6		AND (HL)		7	2	1
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL		
			invoke Inst_AND,BYTE PTR [reg_di]
			invoke CLK_sync,7,2
			jmp Z80Loop
       OpA7:
			;A7		AND A			4	1	1
			invoke Inst_AND,RegA
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpA8:
			;A8		XOR B			4	1	1
			invoke Inst_XOR,RegB
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpA9:
			;A9		XOR C			4	1	1
			invoke Inst_XOR,RegC
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpAA:
			;AA		XOR D			4	1	1
			invoke Inst_XOR,RegD
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpAB:
			;AB		XOR E			4	1	1
			invoke Inst_XOR,RegE
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpAC:
			;AC		XOR H			4	1	1
			invoke Inst_XOR,RegH
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpAD:
			;AD		XOR L			4	1	1
			invoke Inst_XOR,RegL
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpAE:
			;AE		XOR (HL)		7	2	1
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			mov al,[reg_di]
			invoke Inst_XOR,al
			invoke CLK_sync,7,2
			jmp Z80Loop
       OpAF:
			;AF		XOR A			4	1	1						
			invoke Inst_XOR,RegA	
			invoke CLK_sync,4,1		
			jmp Z80Loop
       OpB0:
			;B0		OR B			4	1	1
			invoke Inst_OR,RegB
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpB1:
			;B1		OR C			4	1	1
			invoke Inst_OR,RegC
			invoke CLK_sync,4,1
			jmp Z80Loop	

       OpB2:
			;B2		OR D			4	1	1
			invoke Inst_OR,RegD
			invoke CLK_sync,4,1
			jmp Z80Loop	
       OpB3:
			;B3		OR E			4	1	1
			invoke Inst_OR,RegE
			invoke CLK_sync,4,1
			jmp Z80Loop	

       OpB4:
			;B4		OR H			4	1	1
			invoke Inst_OR,RegH
			invoke CLK_sync,4,1
			jmp Z80Loop	

       OpB5:
			;B5		OR L			4	1	1
			invoke Inst_OR,RegL
			invoke CLK_sync,4,1
			jmp Z80Loop	

       OpB6:
			;B6		OR (HL)			7	2	1
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			mov al,[reg_di]
			invoke Inst_OR,al
			invoke CLK_sync,7,2
			jmp Z80Loop

       OpB7:
			;B7		OR A			4	1	1
			invoke Inst_OR,RegA
			invoke CLK_sync,4,1
			jmp Z80Loop

       OpB8:
			;B8		CP B			4	1	1
			invoke Inst_CP,OFFSET RegB
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpB9:
			;B9		CP C			4	1	1
			invoke Inst_CP,OFFSET RegC
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpBA:
			;BA		CP D			4	1	1
			invoke Inst_CP,OFFSET RegD
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpBB:
			;BB		CP E			4	1	1
			invoke Inst_CP,OFFSET RegE
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpBC:
			;BC		CP H			4	1	1
			invoke Inst_CP,OFFSET RegH
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpBD:
			;BD		CP L			4	1	1
			 invoke Inst_CP,OFFSET RegL
			 invoke CLK_sync,4,1
			 jmp Z80Loop
       OpBE:
			;BE		CP (HL)			7	2	1
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
            invoke Inst_CP,reg_di
			invoke CLK_sync,7,2
			jmp Z80Loop

       OpBF:
			;BF		CP A			4	1	1
			 invoke Inst_CP,OFFSET RegA
			 invoke CLK_sync,4,1
			 jmp Z80Loop
       OpC0:
			;C0		RET NZ			11/5	3/1	1/1	(met/not met)
			test RegF,40h
			jz OpC9
			invoke CLK_sync,5,1
			jmp Z80Loop	
       OpC1:
			;C1		POP BC			10	3	1
			invoke Inst_POP,memPtr,OFFSET RegBC
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpC2:
			;C2 n n		JP NZ,(nn)		10	3	1	(met or not)
			test RegF,40h			
			jz OpC3
			ADD_REG_PC memPtr,2			
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpC3:
			;C3 n n		JP (nn)			10	3	1
			invoke DIR_INMEDIATO_EXT,memPtr			
			invoke Inst_JP,memPtr,WORD PTR[reg_di]
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpC4:
			;C4 n n		CALL NZ,(nn)		17/10	5/3	1/1	(met/not met)
			test RegF,40h
			jz OpCD
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpC5:
			;C5		PUSH BC			11	3	1
			invoke Inst_PUSH,memPtr,RegBC
			invoke CLK_sync,11,3
			jmp Z80Loop	
       OpC6:
			;C6 n		ADD A,n			7	2	1
			invoke DIR_INMEDIATO,memPtr
			invoke Inst_ADD8,reg_di
			invoke CLK_sync,7,2
			jmp Z80Loop

       OpC7:
			;C7		RST 0H			11	3	1			
			invoke Inst_RST,memPtr,0h
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpC8:
			;C8		RET Z			11/5	3/1	1/1	(met/not met)
			test RegF,40h
			jnz OpC9
			invoke CLK_sync,5,1
			jmp Z80Loop	
       OpC9:
			;C9		RET			10	3	1
			invoke Inst_RET,memPtr			
			invoke CLK_sync,10,3			
			jmp Z80Loop
       OpCA:
			;CA n n		JP Z,(nn)		10	3	1	(always same)
			test RegF,40h
			jnz OpC3
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpCB:									
			IncRegR	
			ProcesarOpcodeFromRom _TOpCB
       OpCC:
			;CC n n		CALL Z,(nn)		17/10	5/3	1/1	(met/not met)
			test RegF,40h
			jnz OpCD
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpCD:
			;CD n n		CALL (nn)		17	5	1
			invoke DIR_INMEDIATO_EXT,memPtr			
			invoke Inst_CALL,memPtr,WORD PTR[reg_di]			
			invoke CLK_sync,17,5
			jmp Z80Loop	
       OpCE:
			;CE n		ADC A,n			7	2	1
			invoke DIR_INMEDIATO,memPtr
			invoke Inst_ADC8,reg_di
			invoke CLK_sync,7,2
			jmp Z80Loop

       OpCF:
			;CF		RST 8H			11	3	1
			invoke Inst_RST,memPtr,8h
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpD0:
			;D0		RET NC			5	1	1
			test RegF,1h
			jz OpC9
			invoke CLK_sync,5,1
			jmp Z80Loop	
       OpD1:
			;D1		POP DE			10	3	1
			Invoke Inst_POP,memPtr,OFFSET RegDE
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpD2:
			;D2 n n		JP NC,(nn)		10	3	1	(met or not)
			test RegF,1h
			jz OpC3
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop

       OpD3:
			; D3 OUT (n),A	11	3
			invoke DIR_INMEDIATO,memPtr
			xor x_bx,x_bx
			mov bl,[reg_di]
			mov bh,RegA
			invoke INST_OUT,bx,RegA
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpD4:
			;D4 n n		CALL NC,(nn)		17/10	5/3	1/1	(met/not met)
			test RegF,1h
			jz OpCD
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpD5:
			;D5		PUSH DE			11	3	1
			invoke Inst_PUSH,memPtr,RegDE
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpD6:
			;D6 n		SUB n			7	2	1
			invoke DIR_INMEDIATO,memPtr		
			invoke Inst_SUB,reg_di
			invoke CLK_sync,7,2
			jmp Z80Loop
       OpD7:
			;D7		RST 10H			11	3	1
			invoke Inst_RST,memPtr,10h
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpD8:
			;D8		RET C			5	1	1
			test RegF,1h
			jnz OpC9
			invoke CLK_sync,5,1
			jmp Z80Loop	
       OpD9:
			;D9		EXX			4	1	1			
			invoke Inst_EXX			
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpDA:
			;DA n n		JP C,(nn)		10	3	1	(met or not)
			test RegF,1h
			jnz OpC3
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpDB:
			; DB IN A,(n) 			11	3
			invoke DIR_INMEDIATO,memPtr
			xor x_ax,x_ax
			mov al,[reg_di]
			mov ah,RegA
			invoke INST_IN,ax,OFFSET RegA
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpDC:
			;DC n n		CALL C,(nn)		17/10	5/3	1			
			test RegF,1h
			jnz OpCD
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpDD:
			IncRegR 
			ProcesarOpcodeFromRom _TOpDD
       OpDE:
			;DE n		SBC A,n 7 2
			invoke DIR_INMEDIATO,memPtr
			invoke Inst_SBC8,reg_di
			invoke CLK_sync,7,2
			jmp Z80Loop
       OpDF:
			;DF		RST 18H 11 3
			invoke Inst_RST,memPtr,18h
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpE0:
			;E0		RET PO 11 3
			test RegF,4h
			jz OpC9
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpE1:
			;E1		POP HL 11 3
			invoke Inst_POP,memPtr,OFFSET RegHL
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpE2:
			;E2 n n		JP PO,(nn) 10 3
			test RegF,4h
			jz OpC3
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop

       OpE3:
			;E3		EX (SP),HL 19 5	
			invoke DIR_REGISTRO_INDIRECTO,memPtr,RegSP
			invoke Inst_EX8,OFFSET RegL,reg_di,
			mov x_cx,reg_di
			sub x_cx,memPtr
			inc cx
			mov reg_di,memPtr
			add reg_di,x_cx
            invoke Inst_EX8,OFFSET RegH,reg_di
			invoke CLK_sync,19,5
			jmp Z80Loop
       OpE4:
			;E4 n n		CALL PO,(nn) 10 3			
			test RegF,4h
			jz OpCD
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpE5:
			;E5		PUSH HL 11 3
			invoke Inst_PUSH,memPtr,RegHL
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpE6:
			;E6 n		AND n	7 2		
			invoke DIR_INMEDIATO,memPtr
			invoke Inst_AND,BYTE PTR [reg_di]
			invoke CLK_sync,7,2
			jmp Z80Loop

       OpE7:
			;E7		RST 20H 11 3
			invoke Inst_RST,memPtr,20h
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpE8:
			;E8		RET PE 11 3
			test RegF,4h
			jnz OpC9
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpE9:
			;E9		JP (HL) 4 1
			 invoke Inst_JP,memPtr,RegHL
			 invoke CLK_sync,4,1
			 jmp Z80Loop

       OpEA:
			;EA n n		JP PE,(nn) 10 3
			test RegF,4h
			jnz OpC3
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpEB:
			;EB		EX DE,HL 4 1
			invoke Inst_EX,OFFSET RegHL,OFFSET RegDE
			invoke CLK_sync,4,1
			jmp Z80Loop
	   OpEC:
			;EC n n		CALL PE,(nn) 17 5
			test RegF,4h
			jnz OpCD
			ADD_REG_PC memPtr,2
			invoke CLK_sync,17,5
			jmp Z80Loop
       OpED:			
			IncRegR	
			ProcesarOpcodeFromRom _TOpED
	   OpED00:
	        ;ED00  IN  B,(n)	12	3
			invoke DIR_INMEDIATO,memPtr
			xor x_bx,x_bx
			mov bl,[reg_di]
			invoke INST_IN,bx,OFFSET RegB
			SetIOFlags RegB
			invoke CLK_sync,12,3
			jmp Z80Loop
	   OpED01:
			;ED01  OUT  (n), B	12	3
			invoke DIR_INMEDIATO,memPtr
			xor x_bx,x_bx
			mov bl,[reg_di]
			invoke INST_OUT,bx,RegB
			invoke CLK_sync,13,3
			jmp Z80Loop
	   OpED08:
			;ED08  IN  C,(n)	12	3
			invoke DIR_INMEDIATO,memPtr
			xor x_bx,x_bx
			mov bl,[reg_di]
			invoke INST_IN,bx,OFFSET RegC
			SetIOFlags RegB
			invoke CLK_sync,12,3
			jmp Z80Loop
	   OpED09:
			;ED09  OUT  (n), C	12	3
			invoke DIR_INMEDIATO,memPtr
			xor x_bx,x_bx
			mov bl,[reg_di]
			invoke INST_OUT,bx,RegC
			invoke CLK_sync,13,3
			jmp Z80Loop
	   OpED10:
	        ;ED00  IN  D,(n)	12	3
			invoke DIR_INMEDIATO,memPtr
			xor x_bx,x_bx
			mov bl,[reg_di]
			invoke INST_IN,bx,OFFSET RegD
			SetIOFlags RegD
			invoke CLK_sync,12,3
			jmp Z80Loop
	   OpED40:
			  ;ED40  IN  B,(C)	12	3
			  invoke INST_IN,RegBC,OFFSET RegB
			  SetIOFlags RegB
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED41:
			  ;ED41		OUT (C),B	12	3
			  invoke INST_OUT,RegBC,RegB
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED42:
			  ;ED42		SBC HL,BC 15 4
			  invoke Inst_SBC16,OFFSET RegBC
			  invoke CLK_sync,15,4
			  jmp Z80Loop	
       OpED43:
			  ;ED43 n n	LD (nn),BC	10 6 
			  invoke DIR_EXT,memPtr	   	 			    	  	  	  
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,di
			  invoke Inst_LD16,OFFSET RegBC,reg_di				  
			  invoke CLK_sync,20,6
			  jmp Z80Loop
       OpED44:
			  ;ED44		NEG 8 2
			  invoke Inst_NEG
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpED45:
			  ;ED45		RETN 14 4
			  invoke Inst_RET,memPtr						
			  mov al,IFF2
			  mov IFF1,al
			  invoke CLK_sync,14,4
			  jmp Z80Loop
       OpED46:
			  ;ED46		IM 0 8 2
			  mov IMF,0
			  invoke CLK_sync,8,2
			 jmp Z80Loop	 
       OpED47:
			  ;ED47		LD I,A 9 2 	  
			  invoke Inst_LD8,OFFSET RegA,OFFSET RegI			  			  
			  invoke CLK_sync,9,2
			  jmp Z80Loop 
       OpED48:
			  ;ED48  IN  C,(C)	12	3
			  invoke INST_IN,RegBC,OFFSET RegC
			  SetIOFlags RegC
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED49:
			  ;ED49		OUT (C),C	12	3
			  invoke INST_OUT,RegBC,RegC
			  invoke CLK_sync,12,3
			  jmp Z80Loop	
       OpED4A:
			  ;ED4A		ADC HL,BC	15 4			
			  invoke Inst_ADC16,OFFSET RegBC
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpED4B:
			  ;ED4B n n	LD BC,(nn) 20 6 
			  invoke DIR_EXT,memPtr
			  add reg_di,memPtr	 	   	  	  	  
			  invoke Inst_LD16,reg_di,OFFSET RegBC
			  invoke CLK_sync,20,6
			  jmp Z80Loop
       OpED4C:
			  ;ED4C NEG 8 2
			  invoke Inst_NEG
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpED4D:
			  ;ED4D		RETI 14 4
			  invoke Inst_RET,memPtr
			  mov al,IFF2
			  mov IFF1,al
			  invoke CLK_sync,14,4
			  jmp Z80Loop
       OpED4E:
			 ;ED46E		IM 0 8 2
			  mov IMF,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpED4F:
			  ;ED4F		LD R,A 9 2 
			  invoke Inst_LD8,OFFSET RegA,OFFSET RegR			  
			  invoke CLK_sync,9,2
			  jmp Z80Loop 
       OpED50:
			  ;ED50  IN  D,(C)	12	3
			  invoke INST_IN,RegBC,OFFSET RegD
			  SetIOFlags RegD
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED51:
			  ;ED51		OUT (C),D	12	3
			  invoke INST_OUT,RegBC,RegD
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED52:
			  ;ED52		SBC HL,DE 15 4
			  invoke Inst_SBC16,OFFSET RegDE
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpED53:
			  ;ED53 n n	LD (nn),DE 20 6 
			  invoke DIR_EXT,memPtr	   	 	   	  	  	  
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,di
		      invoke Inst_LD16,OFFSET RegDE,reg_di	
			  invoke CLK_sync,20,6
			  jmp Z80Loop
       OpED54:
			  ;ED54		NEG 8 2
			  invoke Inst_NEG
			  invoke CLK_sync,8,2
			  jmp Z80Loop			 
       OpED55:
			  ;ED55		RETN 14 4
			  invoke Inst_RET,memPtr						
			  mov al,IFF2
			  mov IFF1,al
			  invoke CLK_sync,14,4
			  jmp Z80Loop
       OpED56:
			  ;ED56		IM 1 8 2
			  mov IMF,1
			  invoke CLK_sync,8,2
			 jmp Z80Loop	
       OpED57:
			  ;ED57		LD A,I 9 2 
			  invoke Inst_LD8,OFFSET RegI,OFFSET RegA
			  invoke LD_SetFlagIR,OFFSET RegI
			  invoke CLK_sync,9,2	  
			  jmp Z80Loop 
       OpED58:
			  ;ED58  IN  E,(C)	12	3
			  invoke INST_IN,RegBC,OFFSET RegE
			  SetIOFlags RegE
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED59:			  
			  ;ED59		OUT (C),E	12	3
			  invoke INST_OUT,RegBC,RegE
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED5A:
			  ;ED5A		ADC HL,DE	15 4		  
			  invoke Inst_ADC16,OFFSET RegDE
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpED5B:
		      ;ED5B n n	LD DE,(nn)	20 6 
			  invoke DIR_EXT,memPtr
			  add reg_di,memPtr	 	   	  	  	  
			  invoke Inst_LD16,reg_di,OFFSET RegDE
			  invoke CLK_sync,20,6
			  jmp Z80Loop
       OpED5C:
			  ;ED5C		NEG 8 2
			  invoke Inst_NEG
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpED5D:
			  ;ED5D		RETN 14 4
			  invoke Inst_RET,memPtr						
			  mov al,IFF2
			  mov IFF1,al
			  invoke CLK_sync,14,4
			  jmp Z80Loop
       OpED5E:
			 ;ED5E		IM 2 8 2
			 mov IMF,2
			 invoke CLK_sync,8,2
			 jmp Z80Loop	
       OpED5F:
			  ;ED5F		LD A,R 9 2 
			  invoke Inst_LD8,OFFSET RegR,OFFSET RegA
			  invoke LD_SetFlagIR,OFFSET RegR
			  invoke CLK_sync,9,2		  
			  jmp Z80Loop 
       OpED60:
			  ;ED60  IN  H,(C)	12	3
			  invoke INST_IN,RegBC,OFFSET RegH
			  SetIOFlags RegH
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED61:
			  ;ED61		OUT (C),H	12	3
			  invoke INST_OUT,RegBC,RegH
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED62:
			;ED62		SBC HL,HL 15 4
			invoke Inst_SBC16,OFFSET RegHL
			invoke CLK_sync,15,4
			jmp Z80Loop
       OpED63:
			;ED63 n n	LD (nn),HL		16	5
			invoke DIR_EXT,memPtr	   	 	   	  	  	  
			invoke DIR_REGISTRO_INDIRECTO,memPtr,di
			invoke Inst_LD16,OFFSET RegHL,reg_di	
			invoke CLK_sync,16,5
			jmp Z80Loop
	   OpED64:
			  ;ED64 NEG 8 2
			  invoke Inst_NEG
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpED65:
			  ;ED64		RETN 14 4
			  invoke Inst_RET,memPtr						
			  mov al,IFF2
			  mov IFF1,al
			  invoke CLK_sync,14,4
			  jmp Z80Loop       
       OpED66:
			 ;ED66		IM 0 8 2
			  mov IMF,0
			  invoke CLK_sync,8,2
			 jmp Z80Loop	
       OpED67:
			   ;ED67		RRD 18 5
			   invoke Inst_RRD,memPtr
			   invoke CLK_sync,18,5
			   jmp Z80Loop
       OpED68:
			  ;ED68  IN  L,(C)	12	3
			  invoke INST_IN,RegBC,OFFSET RegL
			  SetIOFlags RegL
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED69:
			  ;ED69		OUT (C),L	12	3
			  invoke INST_OUT,RegBC,RegL
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED6A:
			  ;ED6A		ADC HL,HL 15 4
			  invoke Inst_ADC16,OFFSET RegHL
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpED6B:
			  ;ED6B n n	LD HL,(nn) 16 5 
			  invoke DIR_EXT,memPtr
			  add reg_di,memPtr	 	   	  	  	  
			  invoke Inst_LD16,reg_di,OFFSET RegHL	
			  invoke CLK_sync,16,5
			  jmp Z80Loop
       OpED6C:
			  ;ED6C NEG 8 2
			  invoke Inst_NEG
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpED6D:
			  ;ED6D		RETN 14 4
			  invoke Inst_RET,memPtr						
			  mov al,IFF2
			  mov IFF1,al
			  invoke CLK_sync,14,4
			  jmp Z80Loop
       OpED6E:
			  ;ED6E		IM 0 8 2
			  mov IMF,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpED6F:
				;ED6F RLD 18 5 
				invoke Inst_RLD,memPtr 
				invoke CLK_sync,18,5
				jmp Z80Loop
       OpED70:
			  ;ED70  IN  F,(C)	12	3			  
			  invoke INST_IN,RegBC,OFFSET Reg_Tmp8
			  SetIOFlags Reg_Tmp8
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED71:
			  ;ED71  OUT  (C),F	12	3
			  invoke INST_OUT,RegBC,RegF
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED72:
			  ;ED72		SBC HL,SP 15 4
			  invoke Inst_SBC16,OFFSET RegSP
			  invoke CLK_sync,15,4
			  jmp Z80Loop	
       OpED73:
			  ;ED73 n n	LD (nn),SP	20 6 
			  invoke DIR_EXT,memPtr	   	 	   	  	  	  
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,di
			  invoke Inst_LD16,OFFSET RegSP,reg_di	
			  invoke CLK_sync,20,6
			  jmp Z80Loop
       OpED74:
			  ;ED74 NEG 8 2
			  invoke Inst_NEG
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpED75:
			  ;ED75		RETN 14 4
			  invoke Inst_RET,memPtr						
			  mov al,IFF2
			  mov IFF1,al
			  invoke CLK_sync,14,4
			  jmp Z80Loop
       OpED76:
			  ;ED76		IM 1 8 2
			  mov IMF,1
			  invoke CLK_sync,8,2
			 jmp Z80Loop
       OpED78:
			  ;ED78  IN  A,(C)	12	3
			  invoke INST_IN,RegBC,OFFSET RegA
			  SetIOFlags RegA
			  invoke CLK_sync,12,3
			  jmp Z80Loop	
       OpED79:
			  ;ED79  OUT (C),A	12	3
			  invoke INST_OUT,RegBC,RegA
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpED7A:
			  ;ED7A		ADC HL,SP 15 4
			  invoke Inst_ADC16,OFFSET RegSP
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpED7B:
			   ;ED7B n n	LD SP,(nn) 20 6 
			   invoke DIR_EXT,memPtr
			   add reg_di,memPtr	 	   	  	  	  
			   invoke Inst_LD16,reg_di,OFFSET RegSP
			   invoke CLK_sync,20,6
			   jmp Z80Loop
       OpED7C:
			  ;ED7C NEG 8 2
			  invoke Inst_NEG
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpED7D:
			  ;ED7D		RETN 14 4
			  invoke Inst_RET,memPtr						
			  mov al,IFF2
			  mov IFF1,al
			  invoke CLK_sync,14,4
			  jmp Z80Loop
       OpED7E:
			  ;ED7E		IM 2 8 2
			  mov IMF,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpEDA0:
			  ;EDA0		LDI 16 4
			  invoke Inst_LDI,memPtr
			  invoke CLK_sync,16,4
			  jmp Z80Loop
       OpEDA1:
			  ;EDA1		CPI 16 4			  
			  invoke Inst_CPI,memPtr
			  invoke CLK_sync,16,4
			  jmp Z80Loop	
       OpEDA2:
			  ;EDA2		INI	16	4			 
			  invoke INST_INI,memPtr
			  invoke CLK_sync,16,4
			  jmp Z80Loop
       OpEDA3:
			  ;EDA3		OUTI	16	4
			  invoke INST_OUTI,memPtr			  
			  invoke CLK_sync,16,4
			  jmp Z80Loop
       OpEDA8:
			  ;EDA8		LDD	 16 4		  
			  invoke Inst_LDD,memPtr
			  invoke CLK_sync,16,4
			  jmp Z80Loop
       OpEDA9:
			  ;EDA9		CPD 16 4
			  invoke Inst_CPD,memPtr
			  invoke CLK_sync,16,4
			  jmp Z80Loop
       OpEDAA:
			  ;EDAA		IND	16	4
			  invoke INST_IND,memPtr		  
			  invoke CLK_sync,16,4
			  jmp Z80Loop
       OpEDAB:
			  ;EDAB		OUTD	16	4
			  invoke INST_OUTD,memPtr	  
			  invoke CLK_sync,16,4
			  jmp Z80Loop
       OpEDB0:
			  ;EDB0		LDIR		  
			  invoke Inst_LDIR,memPtr
			  ; invoke CLK_sync,is in Inst_LDIR -> BC != 0 ? 21 5 : 16 4	
			  jmp Z80Loop
       OpEDB1:
			  ;EDB1		CPIR
			  invoke Inst_CPIR,memPtr
			  ; invoke CLK_sync,is in Inst_CPIR -> BC != 0 ? 21 5 : 16 4	
			  jmp Z80Loop
       OpEDB2:
			  ;EDB2		INIR	21/16 	4/3
			  invoke INST_INIR,memPtr		  
			  ; invoke CLK_sync,is in Inst_CPIR -> BC != 0 ? 21 5 : 16 4
			  jmp Z80Loop
       OpEDB3:
			  ;EDB3		OTIR	21/16 	4/3
			  invoke INST_OTIR,memPtr		  
			 ; invoke CLK_sync,is in Inst_CPIR -> BC != 0 ? 21 5 : 16 4
			  jmp Z80Loop
       OpEDB8:
			  ;EDB8		LDDR
			  invoke Inst_LDDR,memPtr
			  ; invoke CLK_sync,is in Inst_LDDR -> BC != 0 ? 21 5 : 16 4
			  jmp Z80Loop
       OpEDB9:
			  ;EDB9		CPDR
			  invoke Inst_CPDR,memPtr
			 ; invoke CLK_sync,is in Inst_CPIR -> BC != 0 ? 21 5 : 16 4
			  jmp Z80Loop
       OpEDBA:
			  ;EDBA		INDR	21/16	4/3
			  invoke INST_INDR,memPtr	  
			  ; invoke CLK_sync,is in Inst_CPIR -> BC != 0 ? 21 5 : 16 4
			  jmp Z80Loop
       OpEDBB:			 
			  ;EDBB		OTDR	21/16	4/3
			  invoke INST_OTDR,memPtr			  
			  ; invoke CLK_sync,is in Inst_CPIR -> BC != 0 ? 21 5 : 16 4
			  jmp Z80Loop
       OpEE:
			;EE n		XOR n 7 2
			invoke DIR_INMEDIATO,memPtr
			invoke Inst_XOR,BYTE PTR [reg_di]
			invoke CLK_sync,7,2
			jmp Z80Loop
       OpEF:
			;EF		RST 28H  11 3
			invoke Inst_RST,memPtr,28h
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpF0:
			;F0		RET P 11 3
			test RegF,80h
			jz OpC9
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpF1:
			;F1		POP AF 10 3
			invoke Inst_POP,memPtr,OFFSET RegAF
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpF2:
			;F2 n n		JP P,(nn) 10 3 
			test RegF,80h
			jz OpC3
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpF3:	   
			;F3		DI 4 1
			xor al,al
	        mov IFF1,al
			mov IFF2,al	
			invoke CLK_sync,4,1		
			jmp Z80Loop
       OpF4:
			;F4 n n		CALL P,(nn) 17 5
			test RegF,80h
			jz OpCD
			ADD_REG_PC memPtr,2
			invoke CLK_sync,17,5
			jmp Z80Loop
       OpF5:
			;F5		PUSH AF 11 3
			invoke Inst_PUSH,memPtr,RegAF
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpF6:
			;F6 n		OR n 7 2
			invoke DIR_INMEDIATO,memPtr
			invoke Inst_OR,BYTE PTR [reg_di]
			invoke CLK_sync,7,2
			jmp Z80Loop
       OpF7:
			;F7		RST 30H 11 3
			invoke Inst_RST,memPtr,30h
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpF8:
			;F8		RET M 11 3
			test RegF,80h
			jnz OpC9
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpF9:
			;F9		LD SP,HL 6 1 1
			invoke Inst_LD16,OFFSET RegHL,OFFSET RegSP
			invoke CLK_sync,6,1
			jmp Z80Loop
       OpFA:
			;FA n n		JP M,(nn) 10 3
			test RegF,80h
			jnz OpC3
			ADD_REG_PC memPtr,2
			invoke CLK_sync,10,3
			jmp Z80Loop
       OpFB:
			;FB		EI 4 1
	        mov IFF1,1
			mov IFF2,1			
			invoke CLK_sync,4,1
			jmp Z80Loop
       OpFC:
			;FC n n		CALL M,(nn) 17 5
			test RegF,80h
			jnz OpCD
			ADD_REG_PC memPtr,2
			invoke CLK_sync,17,5
			jmp Z80Loop
       OpFD:
			IncRegR 
			ProcesarOpcodeFromRom _TOpFD
       OpFE:
			;FE n		CP n 7 2
			invoke DIR_INMEDIATO,memPtr
			invoke Inst_CP,reg_di
			invoke CLK_sync,7,2
			jmp Z80Loop
       OpFF:
			;FF		RST 38H 11 3
			invoke Inst_RST,memPtr,38h
			invoke CLK_sync,11,3
			jmp Z80Loop
       OpCB00:
			  ;CB00		RLC B			8	2	2
			  invoke Inst_RLC,OFFSET RegB
			  invoke CLK_sync,8,2
			  jmp Z80Loop				
       OpCB01:
			  ;CB01		RLC C			8	2	2
			  invoke Inst_RLC,OFFSET RegC
			  invoke CLK_sync,8,2
			  jmp Z80Loop 

       OpCB02:
			  ;CB02		RLC D			8	2	2
			  invoke Inst_RLC,OFFSET RegD
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB03:
			  ;CB03		RLC E			8	2	2
			  invoke Inst_RLC,OFFSET RegE
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB04:
			  ;CB04		RLC H			8	2	2
			  invoke Inst_RLC,OFFSET RegH
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB05:
			  ;CB05		RLC L			8	2	2
			  invoke Inst_RLC,OFFSET RegL
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB06:
			  ;CB06		RLC (HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL 
			  invoke Inst_RLC,reg_di
			  invoke CLK_sync,15,4
			  jmp Z80Loop

       OpCB07:
			 ;CB07		RLC A			8	2	2
			 invoke Inst_RLC,OFFSET RegA
			 invoke CLK_sync,8,2
			 jmp Z80Loop	
       OpCB08:
			  ;CB08		RRC B			8	2	2
			  invoke Inst_RRC,OFFSET RegB
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB09:
			  ;CB09		RRC C			8	2	2
			  invoke Inst_RRC,OFFSET RegC
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB0A:
			  ;CB0A		RRC D			8	2	2
			  invoke Inst_RRC,OFFSET RegD
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB0B:
			  ;CB0B		RRC E			8	2	2
			  invoke Inst_RRC,OFFSET RegE
			  invoke CLK_sync,8,2
			  jmp Z80Loop	

       OpCB0C:
			  ;CB0C		RRC H			8	2	2
			  invoke Inst_RRC,OFFSET RegH
			  invoke CLK_sync,8,2
			  jmp Z80Loop	

       OpCB0D:
			  ;CB0D		RRC L			8	2	2
			  invoke Inst_RRC,OFFSET RegL
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB0E:
			  ;CB0E		RRC (HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL 
			  invoke Inst_RRC,reg_di
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpCB0F:
			  ;CB0F		RRC A			8	2	2
			  invoke Inst_RRC,OFFSET RegA
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB10:
			  ;CB10		RL B			8	2	2
			  invoke Inst_RL,OFFSET RegB
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB11:
			  ;CB11		RL C			8	2	2
			  invoke Inst_RL,OFFSET RegC
			  invoke CLK_sync,8,2
			  jmp Z80Loop			
       OpCB12:
			  ;CB12		RL D			8	2	2
			  invoke Inst_RL,OFFSET RegD
			  invoke CLK_sync,8,2
			  jmp Z80Loop 	
       OpCB13:
			  ;CB13		RL E			8	2	2
			  invoke Inst_RL,OFFSET RegE
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB14:
			  ;CB14		RL H			8	2	2
			  invoke Inst_RL,OFFSET RegH
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB15:
			  ;CB15		RL L			8	2	2
			  invoke Inst_RL,OFFSET RegL
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB16:
			  ;CB16		RL (HL)			15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL 
			  invoke Inst_RL,reg_di
			  invoke CLK_sync,15,4
			  jmp Z80Loop		
       OpCB17:
			  ;CB17		RL A			8	2	2
			  invoke Inst_RL,OFFSET RegA
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB18:
			  ;CB18		RR B			8	2	2
			  invoke Inst_RR,OFFSET RegB
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB19:
			  ;CB19		RR C			8	2	2
			  invoke Inst_RR,OFFSET RegC
			  invoke CLK_sync,8,2
			  jmp Z80Loop	 	
       OpCB1A:
			  ;CB1A		RR D			8	2	2
			  invoke Inst_RR,OFFSET RegD
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB1B:
			  ;CB1B		RR E			8	2	2
			  invoke Inst_RR,OFFSET RegE
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB1C:
			  ;CB1C		RR H			8	2	2
			  invoke Inst_RR,OFFSET RegH
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB1D:
			  ;CB1D		RR L			8	2	2
			  invoke Inst_RR,OFFSET RegL
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB1E:
			  ;CB1E		RR (HL)			15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL 
			  invoke Inst_RR,reg_di
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpCB1F:
			  ;CB1F		RR A			8	2	2
			  invoke Inst_RR,OFFSET RegA
			  invoke CLK_sync,8,2
			  jmp Z80Loop			
       OpCB20:
			  ;CB20		SLA B			8	2	2
			  invoke Inst_SLA,OFFSET RegB
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB21:
			  ;CB21		SLA C			8	2	2
			  invoke Inst_SLA,OFFSET RegC
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB22:
			  ;CB22		SLA D			8	2	2
			  invoke Inst_SLA,OFFSET RegD
			  invoke CLK_sync,8,2
			  jmp Z80Loop			
       OpCB23:
			  ;CB23		SLA E			8	2	2
			  invoke Inst_SLA,OFFSET RegE
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB24:
			  ;CB24		SLA H			8	2	2
			  invoke Inst_SLA,OFFSET RegH
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB25:
			  ;CB25		SLA L			8	2	2
			  invoke Inst_SLA,OFFSET RegL
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB26:
			  ;CB26		SLA (HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL 
			  invoke Inst_SLA,reg_di
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpCB27:
			  ;CB27		SLA A			8	2	2
			  invoke Inst_SLA,OFFSET RegA
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB28:
			  ;CB28		SRA B			8	2	2
			  invoke Inst_SRA,OFFSET RegB
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB29:
			  ;CB29		SRA C			8	2	2
			  invoke Inst_SRA,OFFSET RegC
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB2A:
			  ;CB2A		SRA D			8	2	2
			  invoke Inst_SRA,OFFSET RegD
			  invoke CLK_sync,8,2
			  jmp Z80Loop 
       OpCB2B:
			  ;CB2B		SRA E			8	2	2
			  invoke Inst_SRA,OFFSET RegE
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB2C:
			  ;CB2C		SRA H			8	2	2
			  invoke Inst_SRA,OFFSET RegH
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB2D:
			 ;CB2D		SRA L			8	2	2
		     invoke Inst_SRA,OFFSET RegL
			 invoke CLK_sync,8,2
			 jmp Z80Loop		 
       OpCB2E:
			  ;CB2E		SRA (HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL 
			  invoke Inst_SRA,reg_di
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpCB2F:
			  ;CB2F		SRA A			8	2	2
			  invoke Inst_SRA,OFFSET RegA
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB30:
			  ;CB30		SLL B*			8	2	2
			  invoke Inst_SLL,OFFSET RegB
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB31:
			  ;CB31		SLL C*			8	2	2
			  invoke Inst_SLL,OFFSET RegC
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB32:
			 ;CB32		SLL D*			8	2	2
			 invoke Inst_SLL,OFFSET RegD
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCB33:
			 ;CB33		SLL E*			8	2	2
			 invoke Inst_SLL,OFFSET RegE
			 invoke CLK_sync,8,2
			 jmp Z80Loop		
       OpCB34:
			 ;CB34		SLL H*			8	2	2
			 invoke Inst_SLL,OFFSET RegH
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCB35:
			 ;CB35		SLL L*			8	2	2
			 invoke Inst_SLL,OFFSET RegL
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCB36:
			;CB36		SLL (HL)*		15	4	2
			 invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL 
			 invoke Inst_SLL,reg_di
			 invoke CLK_sync,15,4
			 jmp Z80Loop

       OpCB37:
			  ;CB37		SLL A*			8	2	2
			  invoke Inst_SLL,OFFSET RegA
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB38:
			  ;CB38		SRL B			8	2	2
			  invoke Inst_SRL,OFFSET RegB
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB39:
			  ;CB39		SRL C			8	2	2
			  invoke Inst_SRL,OFFSET RegC
			  invoke CLK_sync,8,2
			  jmp Z80Loop			  	
       OpCB3A:
			 ;CB3A		SRL D			8	2	2
			 invoke Inst_SRL,OFFSET RegD
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCB3B:
			 ;CB3B		SRL E			8	2	2
			 invoke Inst_SRL,OFFSET RegE
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCB3C:
			 ;CB3C		SRL H			8	2	2
			 invoke Inst_SRL,OFFSET RegH
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCB3D:
			  ;CB3D		SRL L			8	2	2
			  invoke Inst_SRL,OFFSET RegL
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB3E:
			  ;CB3E		SRL (HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL 
			  invoke Inst_SRL,reg_di
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpCB3F:
			 ;CB3F		SRL A			8	2	2
			 invoke Inst_SRL,OFFSET RegA
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCB40:
			  ;CB40		BIT 0,B			8	2	2
			  invoke Inst_BIT,OFFSET RegB,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop 
       OpCB41:
			  ;CB41		BIT 0,C			8	2	2
			   invoke Inst_BIT,OFFSET RegC,0
			   invoke CLK_sync,8,2
			   jmp Z80Loop 
       OpCB42:
			  ;CB42		BIT 0,D			8	2	2
			   invoke Inst_BIT,OFFSET RegD,0
			   invoke CLK_sync,8,2
			   jmp Z80Loop 	
       OpCB43:
			  ;CB43		BIT 0,E			8	2	2
			   invoke Inst_BIT,OFFSET RegE,0
			   invoke CLK_sync,8,2
			   jmp Z80Loop 		

       OpCB44:
			  ;CB44	 	BIT 0,H			8	2	2
			   invoke Inst_BIT,OFFSET RegH,0
			   invoke CLK_sync,8,2
			   jmp Z80Loop 		
       OpCB45:
			  ;CB45	 	BIT 0,L			8	2	2
			   invoke Inst_BIT,OFFSET RegL,0
			   invoke CLK_sync,8,2
			   jmp Z80Loop 	
       OpCB46:
			  ;CB46	 	BIT 0,(HL)		12	3	2
			   invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			   invoke Inst_BIT,reg_di,0
			   invoke CLK_sync,12,3
			   jmp Z80Loop	
       OpCB47:
			   ;CB47	 	BIT 0,A			8	2	2	
			   invoke Inst_BIT,OFFSET RegA,0
			   invoke CLK_sync,8,2
			   jmp Z80Loop
       OpCB48:
			  ;CB48		BIT 1,B			8	2	2
			   invoke Inst_BIT,OFFSET RegB,1
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB49:
			  ;CB49	 	BIT 1,C			8	2	2
			   invoke Inst_BIT,OFFSET RegC,1
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB4A:
			  ;CB4A	 	BIT 1,D			8	2	2
			   invoke Inst_BIT,OFFSET RegD,1
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB4B:
			  ;CB4B	 	BIT 1,E			8	2	2	
			   invoke Inst_BIT,OFFSET RegE,1
			   invoke CLK_sync,8,2
			   jmp Z80Loop
       OpCB4C:
			  ;CB4C	 	BIT 1,H			8	2	2
			   invoke Inst_BIT,OFFSET RegH,1
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB4D:
			  ;CB4D	 	BIT 1,L			8	2	2
			   invoke Inst_BIT,OFFSET RegL,1
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB4E:
			  ;CB4E	 	BIT 1,(HL)		12	3	2
			   invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			   invoke Inst_BIT,reg_di,1
			   invoke CLK_sync,12,3
			   jmp Z80Loop	
       OpCB4F:
			  ;CB4F	 	BIT 1,A			8	2	2
			   invoke Inst_BIT,OFFSET RegA,1
			   invoke CLK_sync,8,2
			   jmp Z80Loop			
       OpCB50:
			  ;CB50		BIT 2,B			8	2	2
			   invoke Inst_BIT,OFFSET RegB,2
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB51:
			  ;CB51	 	BIT 2,C			8	2	2
			   invoke Inst_BIT,OFFSET RegC,2
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB52:
			  ;CB52	 	BIT 2,D			8	2	2
			   invoke Inst_BIT,OFFSET RegD,2
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB53:
			  ;CB53	 	BIT 2,E			8	2	2
			   invoke Inst_BIT,OFFSET RegE,2
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB54:
			  ;CB54	 	BIT 2,H			8	2	2
			   invoke Inst_BIT,OFFSET RegH,2
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB55:
			  ;CB55	 	BIT 2,L			8	2	2
			   invoke Inst_BIT,OFFSET RegL,2
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB56:
			  ;CB56	 	BIT 2,(HL)		12	3	2
			   invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			   invoke Inst_BIT,reg_di,2
			   invoke CLK_sync,12,3
			   jmp Z80Loop	
       OpCB57:
			  ;CB57	 	BIT 2,A			8	2	2
			   invoke Inst_BIT,OFFSET RegA,2
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB58:
			  ;CB58		BIT 3,B			8	2	2
			   invoke Inst_BIT,OFFSET RegB,3
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB59:
			   ;CB59	 	BIT 3,C			8	2	2
			   invoke Inst_BIT,OFFSET RegC,3
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB5A:
			   ;CB5A	 	BIT 3,D			8	2	2
			   invoke Inst_BIT,OFFSET RegD,3
			   invoke CLK_sync,8,2
			   jmp Z80Loop
       OpCB5B:
			   ;CB5B	 	BIT 3,E			8	2	2
			   invoke Inst_BIT,OFFSET RegE,3
			   invoke CLK_sync,8,2
			   jmp Z80Loop

       OpCB5C:
			  ;CB5C	 	BIT 3,H			8	2	2
			   invoke Inst_BIT,OFFSET RegH,3
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB5D:
			  ;CB5D	 	BIT 3,L			8	2	2
			   invoke Inst_BIT,OFFSET RegL,3
			   invoke CLK_sync,8,2
			   jmp Z80Loop	

       OpCB5E:
			  ;CB5E	 	BIT 3,(HL)		12	3	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_BIT,reg_di,3
			  invoke CLK_sync,12,3
			  jmp Z80Loop

       OpCB5F:
			  ;CB5F	 	BIT 3,A			8	2	2
			  invoke Inst_BIT,OFFSET RegA,3
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB60:
			  ;CB60		BIT 4,B			8	2	2
			  invoke Inst_BIT,OFFSET RegB,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB61:
			  ;CB61	 	BIT 4,C			8	2	2
			  invoke Inst_BIT,OFFSET RegC,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB62:
			 ;CB62	 	BIT 4,D			8	2	2
			  invoke Inst_BIT,OFFSET RegD,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB63:
			 ;CB63	 	BIT 4,E			8	2	2
			  invoke Inst_BIT,OFFSET RegE,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB64:
			 ;CB64	 	BIT 4,H			8	2	2
			  invoke Inst_BIT,OFFSET RegH,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB65:
			  ;CB65	 	BIT 4,L			8	2	2
			  invoke Inst_BIT,OFFSET RegL,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB66:
			  ;CB66	 	BIT 4,(HL)		12	3	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_BIT,reg_di,4
			  invoke CLK_sync,12,3
			  jmp Z80Loop	

       OpCB67:
			 ;CB67	 	BIT 4,A			8	2	2
			  invoke Inst_BIT,OFFSET RegA,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB68:
			 ;CB68		BIT 5,B			8	2	2
			 invoke Inst_BIT,OFFSET RegB,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB69:
			 ;CB69	 	BIT 5,C			8	2	2
			 invoke Inst_BIT,OFFSET RegC,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB6A:
			 ;CB6A	 	BIT 5,D			8	2	2
			 invoke Inst_BIT,OFFSET RegD,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB6B:
			 ;CB6B	 	BIT 5,E			8	2	2
			 invoke Inst_BIT,OFFSET RegE,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB6C:
			 ;CB6C	 	BIT 5,H			8	2	2
			 invoke Inst_BIT,OFFSET RegH,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB6D:
			 ;CB6D	 	BIT 5,L			8	2	2
			 invoke Inst_BIT,OFFSET RegL,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB6E:
			  ;CB6E	 	BIT 5,(HL)		12	3	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_BIT,reg_di,5
			  invoke CLK_sync,12,3
			  jmp Z80Loop

       OpCB6F:
			  ;CB6F	 	BIT 5,A			8	2	2
			  invoke Inst_BIT,OFFSET RegA,5
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB70:
			  ;CB70		BIT 6,B			8	2	2
			  invoke Inst_BIT,OFFSET RegB,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB71:
			  ;CB71	 	BIT 6,C			8	2	2
			  invoke Inst_BIT,OFFSET RegC,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop
			  	 
       OpCB72:
			  ;CB72	 	BIT 6,D			8	2	2
			  invoke Inst_BIT,OFFSET RegD,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB73:
			  ;CB73	 	BIT 6,E			8	2	2
			  invoke Inst_BIT,OFFSET RegE,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB74:	
			 ;CB74	 	BIT 6,H			8	2	2
			 invoke Inst_BIT,OFFSET RegH,6
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB75:
			  ;CB75	 	BIT 6,L			8	2	2
			  invoke Inst_BIT,OFFSET RegL,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB76:
			  ;CB76	 	BIT 6,(HL)		12	3	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_BIT,reg_di,6
			  invoke CLK_sync,12,3
			  jmp Z80Loop
       OpCB77:
			  ;CB77	 	BIT 6,A			8	2	2
			   invoke Inst_BIT,OFFSET RegA,6
			   invoke CLK_sync,8,2
			   jmp Z80Loop	
       OpCB78:
			 ;CB78		BIT 7,B			8	2	2
			 invoke Inst_BIT,OFFSET RegB,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB79:
			 ;CB79	 	BIT 7,C			8	2	2
			 invoke Inst_BIT,OFFSET RegC,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB7A:
			 ;CB7A	 	BIT 7,D			8	2	2
			 invoke Inst_BIT,OFFSET RegD,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop
			
       OpCB7B:
			 ;CB7B	 	BIT 7,E			8	2	2
			 invoke Inst_BIT,OFFSET RegE,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCB7C:
			 ;CB7C	 	BIT 7,H			8	2	2
			 invoke Inst_BIT,OFFSET RegH,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB7D:
			 ;CB7D	 	BIT 7,L			8	2	2
			 invoke Inst_BIT,OFFSET RegL,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB7E:
			 ;CB7E	 	BIT 7,(HL)		12	3	2
			 invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			 invoke Inst_BIT,reg_di,7
			 invoke CLK_sync,12,3
			 jmp Z80Loop

       OpCB7F:
			 ;CB7F	 	BIT 7,A			8	2	2
			 invoke Inst_BIT,OFFSET RegA,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB80:
			  ;CB80		RES 0,B			8	2	2
			  invoke Inst_RES,OFFSET RegB,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB81:
			  ;CB81		RES 0,C			8	2	2
			  invoke Inst_RES,OFFSET RegC,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB82:
			  ;CB82		RES 0,D			8	2	2
			  invoke Inst_RES,OFFSET RegD,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB83:
			  ;CB83		RES 0,E			8	2	2
			  invoke Inst_RES,OFFSET RegE,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB84:
			  ;CB84	 	RES 0,H			8	2	2
			  invoke Inst_RES,OFFSET RegH,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop 		
       OpCB85:
			  ;CB85	 	RES 0,L			8	2	2
			  invoke Inst_RES,OFFSET RegL,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB86:
			 ;CB86	 	RES 0,(HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_RES,reg_di,0
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpCB87:
			  ;CB87	 	RES 0,A			8	2	2
			  invoke Inst_RES,OFFSET RegA,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCB88:
			  ;CB88		RES 1,B			8	2	2
		      invoke Inst_RES,OFFSET RegB,1
			  invoke CLK_sync,8,2
			  jmp Z80Loop 		
       OpCB89:
			  ;CB89	 	RES 1,C			8	2	2
			  invoke Inst_RES,OFFSET RegC,1
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB8A:
			  ;CB8A	 	RES 1,D			8	2	2
			  invoke Inst_RES,OFFSET RegD,1
			  invoke CLK_sync,8,2
			  jmp Z80Loop 		

       OpCB8B:
			 ;CB8B	 	RES 1,E			8	2	2
			 invoke Inst_RES,OFFSET RegE,1
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB8C:
			  ;CB8C	 	RES 1,H			8	2	2
			  invoke Inst_RES,OFFSET RegH,1
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB8D:
			  ;CB8D	 	RES 1,L			8	2	2
			  invoke Inst_RES,OFFSET RegL,1
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB8E:
			 ;CB8E	 	RES 1,(HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_RES,reg_di,1
			  invoke CLK_sync,15,4
			  jmp Z80Loop

       OpCB8F:
			  ;CB8F	 	RES 1,A			8	2	2
			  invoke Inst_RES,OFFSET RegA,1
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCB90:
			  ;CB90		RES 2,B			8	2	2
			  invoke Inst_RES,OFFSET RegB,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB91:
			  ;CB91	 	RES 2,C			8	2	2
			  invoke Inst_RES,OFFSET RegC,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop	

       OpCB92:
			 ;CB92	 	RES 2,D			8	2	2
			  invoke Inst_RES,OFFSET RegD,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB93:
			  ;CB93	 	RES 2,E			8	2	2
			  invoke Inst_RES,OFFSET RegE,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop	

       OpCB94:
			  ;CB94	 	RES 2,H			8	2	2
			  invoke Inst_RES,OFFSET RegH,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB95:
			 ;CB95	 	RES 2,L			8	2	2
			 invoke Inst_RES,OFFSET RegL,2
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB96:
			 ;CB96	 	RES 2,(HL)		15	4	2
			 invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			 invoke Inst_RES,reg_di,2
			 invoke CLK_sync,15,4
			 jmp Z80Loop			 

       OpCB97:
			 ;CB97	 	RES 2,A			8	2	2
			 invoke Inst_RES,OFFSET RegA,2
			 invoke CLK_sync,8,2
			 jmp Z80Loop	
       OpCB98:
			 ;CB98		RES 3,B			8	2	2
			 invoke Inst_RES,OFFSET RegB,3
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB99:
			 ;CB99	 	RES 3,C			8	2	2
			 invoke Inst_RES,OFFSET RegC,3
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB9A:
			  ;CB9A	 	RES 3,D			8	2	2
			  invoke Inst_RES,OFFSET RegD,3
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCB9B:
			 ;CB9B	 	RES 3,E			8	2	2
			 invoke Inst_RES,OFFSET RegE,3
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB9C:
			 ;CB9C	 	RES 3,H			8	2	2
			 invoke Inst_RES,OFFSET RegH,3
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCB9D:
			 ;CB9D	 	RES 3,L			8	2	2
			 invoke Inst_RES,OFFSET RegL,3
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCB9E:
			  ;CB9E	 	RES 3,(HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_RES,reg_di,3
			  invoke CLK_sync,15,4
			  jmp Z80Loop

       OpCB9F:
			  ;CB9F	 	RES 3,A			8	2	2
			  invoke Inst_RES,OFFSET RegA,3
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBA0:
			  ;CBA0		RES 4,B			8	2	2
			  invoke Inst_RES,OFFSET RegB,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBA1:
			  ;CBA1	 	RES 4,C			8	2	2
			  invoke Inst_RES,OFFSET RegC,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCBA2:
			  ;CBA2	 	RES 4,D			8	2	2
			  invoke Inst_RES,OFFSET RegD,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBA3:
		      ;CBA3	 	RES 4,E			8	2	2
			  invoke Inst_RES,OFFSET RegE,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBA4:
		      ;CBA4	 	RES 4,H			8	2	2
			  invoke Inst_RES,OFFSET RegH,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
			
       OpCBA5:
			  ;CBA5	 	RES 4,L			8	2	2
			  invoke Inst_RES,OFFSET RegL,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop			  	

       OpCBA6:
			  ;CBA6	 	RES 4,(HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_RES,reg_di,4
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpCBA7:
			  ;CBA7	 	RES 4,A			8	2	2
			  invoke Inst_RES,OFFSET RegA,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBA8:
			 ;CBA8		RES 5,B			8	2	2
			 invoke Inst_RES,OFFSET RegB,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBA9:
			 ;CBA9	 	RES 5,C			8	2	2
			 invoke Inst_RES,OFFSET RegC,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop	

       OpCBAA:
			 ;CBAA	 	RES 5,D			8	2	2
			 invoke Inst_RES,OFFSET RegD,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop

       OpCBAB:
			  ;CBAB	 	RES 5,E			8	2	2
			  invoke Inst_RES,OFFSET RegE,5
			  invoke CLK_sync,8,2
			  jmp Z80Loop 

       OpCBAC:
			  ;CBAC	 	RES 5,H			8	2	2
			  invoke Inst_RES,OFFSET RegH,5
			  invoke CLK_sync,8,2
			  jmp Z80Loop 

       OpCBAD:
			  ;CBAD	 	RES 5,L			8	2	2
			  invoke Inst_RES,OFFSET RegL,5
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBAE:
			  ;CBAE	 	RES 5,(HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_RES,reg_di,5
			  invoke CLK_sync,15,4
			  jmp Z80Loop	

       OpCBAF:
			  ;CBAF	 	RES 5,A			8	2	2
			  invoke Inst_RES,OFFSET RegA,5
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBB0:
			  ;CBB0		RES 6,B			8	2	2
			  invoke Inst_RES,OFFSET RegB,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBB1:
			  ;CBB1	 	RES 6,C			8	2	2
			  invoke Inst_RES,OFFSET RegC,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBB2:
			  ;CBB2	 	RES 6,D			8	2	2
			  invoke Inst_RES,OFFSET RegD,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBB3:
			  ;CBB3	 	RES 6,E			8	2	2
			  invoke Inst_RES,OFFSET RegE,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBB4:
			  ;CBB4	 	RES 6,H			8	2	2
			  invoke Inst_RES,OFFSET RegH,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop	

       OpCBB5:
			  ;CBB5	 	RES 6,L			8	2	2
			  invoke Inst_RES,OFFSET RegL,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBB6:
			 ;CBB6	 	RES 6,(HL)		15	4	2
			 invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			 invoke Inst_RES,reg_di,6
			 invoke CLK_sync,15,4
			 jmp Z80Loop

       OpCBB7:
	          ;CBB7	 	RES 6,A			8	2	2
			  invoke Inst_RES,OFFSET RegA,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBB8:
			  ;CBB8		RES 7,B			8	2	2
			  invoke Inst_RES,OFFSET RegB,7
			  invoke CLK_sync,8,2
			  jmp Z80Loop	

       OpCBB9:
			  ;CBB9	 	RES 7,C			8	2	2
			  invoke Inst_RES,OFFSET RegC,7
			  invoke CLK_sync,8,2
			  jmp Z80Loop	

       OpCBBA:
			  ;CBBA	 	RES 7,D			8	2	2
			  invoke Inst_RES,OFFSET RegD,7
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBBB:
			  ;CBBB	 	RES 7,E			8	2	2
			  invoke Inst_RES,OFFSET RegE,7
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBBC:
			  ;CBBC	 	RES 7,H			8	2	2
			  invoke Inst_RES,OFFSET RegH,7
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBBD:
			  ;CBBD	 	RES 7,L			8	2	2
			  invoke Inst_RES,OFFSET RegL,7
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBBE:
			  ;CBBE	 	RES 7,(HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_RES,reg_di,7
			  invoke CLK_sync,15,4
			  jmp Z80Loop

       OpCBBF:
			  ;CBBF	 	RES 7,A			8	2	2
			  invoke Inst_RES,OFFSET RegA,7
			  invoke CLK_sync,8,2
			  jmp Z80Loop

       OpCBC0:
			  ;CBC0		SET 0,B			8	2	2
			  invoke Inst_Set,OFFSET RegB,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop 		

       OpCBC1:
			  ;CBC1		SET 0,C			8	2	2
			  invoke Inst_Set,OFFSET RegC,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBC2:
			  ; CBC2		SET 0,D			8	2	2
			  invoke Inst_Set,OFFSET RegD,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBC3:
			  ;CBC3		SET 0,E			8	2	2
			  invoke Inst_Set,OFFSET RegE,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBC4:
			  ;CBC4	 	SET 0,H			8	2	2
			  invoke Inst_Set,OFFSET RegH,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBC5:
			  ;CBC5	 	SET 0,L			8	2	2
			  invoke Inst_Set,OFFSET RegL,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBC6:
			 ;CBC6	 	SET 0,(HL)		15	4	2
			 invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			 invoke Inst_Set,reg_di,0
			 invoke CLK_sync,15,4
			 jmp Z80Loop
       OpCBC7:
			  ;CBC7	 	SET 0,A			8	2	2
			  invoke Inst_Set,OFFSET RegA,0
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBC8:
			 ;CBC8		SET 1,B			8	2	2
			 invoke Inst_Set,OFFSET RegB,1
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBC9:
			 ;CBC9	 	SET 1,C			8	2	2
			 invoke Inst_Set,OFFSET RegC,1
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBCA:
			 ;CBCA	 	SET 1,D			8	2	2
			 invoke Inst_Set,OFFSET RegD,1
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBCB:
			 ;CBCB	 	SET 1,E			8	2	2
			 invoke Inst_Set,OFFSET RegE,1
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBCC:
			 ;CBCC	 	SET 1,H			8	2	2
			 invoke Inst_Set,OFFSET RegH,1
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBCD:
			  ;CBCD	 	SET 1,L			8	2	2
			  invoke Inst_Set,OFFSET RegL,1
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBCE:
			  ;CBCE	 	SET 1,(HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_Set,reg_di,1
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpCBCF:
			  ;CBCF	 	SET 1,A			8	2	2
			  invoke Inst_Set,OFFSET RegA,1
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBD0:
			  ;CBD0		SET 2,B			8	2	2
			  invoke Inst_Set,OFFSET RegB,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBD1:
			  ;CBD1	 	SET 2,C			8	2	2
			  invoke Inst_Set,OFFSET RegC,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBD2:
			  ;CBD2	 	SET 2,D			8	2	2
			  invoke Inst_Set,OFFSET RegD,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBD3:
			  ;CBD3	 	SET 2,E			8	2	2
			  invoke Inst_Set,OFFSET RegE,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCBD4:
			  ;CBD4	 	SET 2,H			8	2	2
			  invoke Inst_Set,OFFSET RegH,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBD5:
			  ;CBD5	 	SET 2,L			8	2	2
			  invoke Inst_Set,OFFSET RegL,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBD6:
			  ;CBD6	 	SET 2,(HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_Set,reg_di,2
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpCBD7:
			  ;CBD7	 	SET 2,A			8	2	2
			  invoke Inst_Set,OFFSET RegA,2
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBD8:
			  ;CBD8		SET 3,B			8	2	2
			  invoke Inst_Set,OFFSET RegB,3
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBD9:
			 ;CBD9	 	SET 3,C			8	2	2
			 invoke Inst_Set,OFFSET RegC,3
			 invoke CLK_sync,8,2
			 jmp Z80Loop 
       OpCBDA:
			 ;CBDA	 	SET 3,D			8	2	2
			 invoke Inst_Set,OFFSET RegD,3
			 invoke CLK_sync,8,2
			 jmp Z80Loop 
       OpCBDB:
			  ;CBDB	 	SET 3,E			8	2	2
			  invoke Inst_Set,OFFSET RegE,3
			  invoke CLK_sync,8,2
			  jmp Z80Loop 
       OpCBDC:
			  ;CBDC	 	SET 3,H			8	2	2
			  invoke Inst_Set,OFFSET RegH,3
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBDD:
			 ;CBDD	 	SET 3,L			8	2	2
		     invoke Inst_Set,OFFSET RegL,3
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBDE:
			 ;CBDE	 	SET 3,(HL)		15	4	2
			 invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			 invoke Inst_Set,reg_di,3
			 invoke CLK_sync,15,4
			 jmp Z80Loop
       OpCBDF:
			 ;CBDF	 	SET 3,A			8	2	2
			 invoke Inst_Set,OFFSET RegA,3
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBE0:
			  ;CBE0		SET 4,B			8	2	2
			  invoke Inst_Set,OFFSET RegB,4
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBE1:
			 ;CBE1	 	SET 4,C			8	2	2
			 invoke Inst_Set,OFFSET RegC,4
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBE2:
			 ;CBE2	 	SET 4,D			8	2	2
			 invoke Inst_Set,OFFSET RegD,4
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBE3:
			 ;CBE3	 	SET 4,E			8	2	2
			 invoke Inst_Set,OFFSET RegE,4
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBE4:
			 ;CBE4	 	SET 4,H			8	2	2
			 invoke Inst_Set,OFFSET RegH,4
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBE5:
			 ;CBE5	 	SET 4,L			8	2	2
			 invoke Inst_Set,OFFSET RegL,4
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBE6:
			 ;CBE6	 	SET 4,(HL)		15	4	2
			 invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			 invoke Inst_Set,reg_di,4
			 invoke CLK_sync,15,4
			 jmp Z80Loop
       OpCBE7:
			 ;CBE7	 	SET 4,A			8	2	2
			 invoke Inst_Set,OFFSET RegA,4
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBE8:
			 ;CBE8		SET 5,B			8	2	2
			 invoke Inst_Set,OFFSET RegB,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBE9:
			 ;CBE9	 	SET 5,C			8	2	2
			 invoke Inst_Set,OFFSET RegC,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBEA:
			 ;CBEA	 	SET 5,D			8	2	2
			 invoke Inst_Set,OFFSET RegD,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBEB:
			 ;CBEB	 	SET 5,E			8	2	2
			 invoke Inst_Set,OFFSET RegE,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBEC:
			 ;CBEC	 	SET 5,H			8	2	2
			 invoke Inst_Set,OFFSET RegH,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBED:
			 ;CBED	 	SET 5,L			8	2	2
			 invoke Inst_Set,OFFSET RegL,5
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBEE:
			  ;CBEE	 	SET 5,(HL)		15	4	2
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			  invoke Inst_Set,reg_di,5
			  invoke CLK_sync,15,4
			  jmp Z80Loop	
       OpCBEF:
			  ;CBEF	 	SET 5,A			8	2	2
			  invoke Inst_Set,OFFSET RegA,5
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBF0:	
			  ;CBF0		SET 6,B			8	2	2
			  invoke Inst_Set,OFFSET RegB,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBF1:
			  ;CBF1	 	SET 6,C			8	2	2
			  invoke Inst_Set,OFFSET RegC,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBF2:
			 ;CBF2	 	SET 6,D			8	2	2
			 invoke Inst_Set,OFFSET RegD,6
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBF3:
			 ;CBF3	 	SET 6,E			8	2	2
			 invoke Inst_Set,OFFSET RegE,6
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBF4:
			 ;CBF4	 	SET 6,H			8	2	2
			 invoke Inst_Set,OFFSET RegH,6
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBF5:
			 ;CBF5	 	SET 6,L			8	2	2
			 invoke Inst_Set,OFFSET RegL,6
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBF6:
			 ;CBF6	 	SET 6,(HL)		15	4	2
		     invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			 invoke Inst_Set,reg_di,6
			 invoke CLK_sync,15,4
			 jmp Z80Loop
       OpCBF7:
			  ;CBF7	 	SET 6,A			8	2	2
			  invoke Inst_Set,OFFSET RegA,6
			  invoke CLK_sync,8,2
			  jmp Z80Loop
       OpCBF8:
			  ;CBF8		SET 7,B			8	2	2
			  invoke Inst_Set,OFFSET RegB,7
			  invoke CLK_sync,8,2
			  jmp Z80Loop	
       OpCBF9:
			 ;CBF9	 	SET 7,C			8	2	2
			 invoke Inst_Set,OFFSET RegC,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBFA:
			 ;CBFA	 	SET 7,D			8	2	2
			 invoke Inst_Set,OFFSET RegD,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBFB:
			 ;CBFB	 	SET 7,E			8	2	2
			 invoke Inst_Set,OFFSET RegE,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop 			
       OpCBFC:
			 ;CBFC	 	SET 7,H			8	2	2
			 invoke Inst_Set,OFFSET RegH,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBFD:
			 ;CBFD	 	SET 7,L			8	2	2
			 invoke Inst_Set,OFFSET RegL,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpCBFE:
			 ;CBFE	 	SET 7,(HL)		15	4	2
			 invoke DIR_REGISTRO_INDIRECTO,memPtr,RegHL
			 invoke Inst_Set,reg_di,7
			 invoke CLK_sync,15,4
			 jmp Z80Loop
       OpCBFF:
			 ;CBFF	 	SET 7,A			8	2	2
			 invoke Inst_Set,OFFSET RegA,7
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpDD09:
			  ;DD09		ADD IX,BC	15 4
			  invoke Inst_ADD16,OFFSET RegBC,OFFSET RegIX
			  invoke CLK_sync,15,4
			  jmp Z80Loop	
       OpDD19:
			  ;DD19		ADD IX,DE	15 4	  
			  invoke Inst_ADD16,OFFSET RegDE,OFFSET RegIX
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpDD21:
			  ;DD21 n n	LD IX,nn 14 4 
			  invoke DIR_INMEDIATO_EXT,memPtr
			  invoke Inst_LD16,reg_di,OFFSET RegIX
			  invoke CLK_sync,14,4
			  jmp Z80Loop
       OpDD22:
			  ;DD22 n n	LD (nn),IX 20 6 
			  invoke DIR_EXT,memPtr	   	 	   	  	  	  
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,di
			  invoke Inst_LD16,OFFSET RegIX,reg_di	
			  invoke CLK_sync,20,6
			  jmp Z80Loop	
       OpDD23:
			;DD23		INC IX  10 2				  
			invoke Inst_INC16,OFFSET RegIX			
			invoke CLK_sync,10,2
			jmp Z80Loop
       OpDD24:
			 ;DD24		INC  IXH	8	2
			 invoke Inst_INC8,OFFSET RegIXH			
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpDD25:
			 ;DD25		DEC  IXH	8	2
			 invoke Inst_DEC8,OFFSET RegIXH	
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpDD26:
			;26 n		LD   IXH,n			11	3
			invoke DIR_INMEDIATO,memPtr			
            invoke Inst_LD8,reg_di,OFFSET RegIXH
			invoke CLK_sync,11,3
			jmp Z80Loop	
       OpDD29:
			  ;DD29		ADD IX,IX  15 4			  
			  invoke Inst_ADD16,OFFSET RegIX,OFFSET RegIX
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpDD2A:
			  ;DD2A n n	LD IX,(nn) 20 6 
			  invoke DIR_EXT,memPtr
			  add reg_di,memPtr	 	   	  	  	  
			  invoke Inst_LD16,reg_di,OFFSET RegIX
			  invoke CLK_sync,20,6
			  jmp Z80Loop
       OpDD2B:
			;DD2B		DEC IX  10 2
			invoke Inst_DEC16,OFFSET RegIX					
			invoke CLK_sync,10,2
			jmp Z80Loop	
       OpDD2C:
			 ;DD2C		INC  IXL	8	2
			 invoke Inst_INC8,OFFSET RegIXL
			 invoke CLK_sync,8,2
			 jmp Z80Loop	
       OpDD2D:
			  ;DD2D		DEC  IXL	8	2
			 invoke Inst_DEC8,OFFSET RegIXL
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpDD2E:
			 ;OpDD2E LD   IXL,n	 11 3
			 invoke DIR_INMEDIATO,memPtr			
             invoke Inst_LD8,reg_di,OFFSET RegIXL
			 invoke CLK_sync,11,3
			 jmp Z80Loop			 
       OpDD34:
			  ;DD34 d		INC (IX+d) 23 6
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_INC8,reg_di
			  invoke CLK_sync,23,6
			  jmp Z80Loop
       OpDD35:
			  ;DD35 d		DEC (IX+d) 23 6
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_DEC8,reg_di
			  invoke CLK_sync,23,6
			  jmp Z80Loop
       OpDD36:
			  ;DD36 d n	LD (IX+d),n 19 5
			   invoke DIR_INDEXADO,memPtr,RegIX
			   mov reg_si,reg_di
			   invoke DIR_INMEDIATO,memPtr
			   invoke Inst_LD8,reg_di,reg_si
			   invoke CLK_sync,19,5
			   jmp Z80Loop
       OpDD39:
			  ;DD39		ADD IX,SP	15 4		  
			  invoke Inst_ADD16,OFFSET RegSP,OFFSET RegIX
			  invoke CLK_sync,15,4
			  jmp Z80Loop
	   OpDD40:
			  jmp Op40
       OpDD41:
			  jmp Op41
       OpDD42:
			  jmp Op42
       OpDD43:
			  jmp Op43
       OpDD44:
			 ;DD44		LD   B,IXH			8	2
			 invoke Inst_LD8,OFFSET RegIXH,OFFSET RegB
			 invoke CLK_sync,8,2
             jmp Z80Loop
       OpDD45:
			 ; DD45		LD   B,IXL			8	2
			 invoke Inst_LD8,OFFSET RegIXL,OFFSET RegB
			 invoke CLK_sync,8,2
             jmp Z80Loop
       OpDD46:
			  ;DD46 d		LD B,(IX+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,reg_di,OFFSET RegB
			  invoke CLK_sync,19,5
			  jmp Z80Loop
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
			  ;DD4C		LD   C,IXH			8	2
			  invoke Inst_LD8,OFFSET RegIXH,OFFSET RegC
			  invoke CLK_sync,8,2
              jmp Z80Loop	
       OpDD4D:
			  ;DD4D		LD   C,IXL			8	2
			  invoke Inst_LD8,OFFSET RegIXL,OFFSET RegC
			  invoke CLK_sync,8,2
              jmp Z80Loop	
       OpDD4E:
			  ;DD4E d		LD C,(IX+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,reg_di,OFFSET RegC
			  invoke CLK_sync,19,5
			  jmp Z80Loop		
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
			;DD54		D,IXH			8	2
			invoke Inst_LD8,OFFSET RegIXH,OFFSET RegD
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD55:
			;DD55		D,IXL			8	2
			invoke Inst_LD8,OFFSET RegIXL,OFFSET RegD
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD56:
			  ;DD56 d		LD D,(IX+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,reg_di,OFFSET RegD
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
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
			;DD5C		LD E,IXH			8	2
			invoke Inst_LD8,OFFSET RegIXH,OFFSET RegE
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpDD5D:
			;DD5D		LD E,IXL			8	2
			invoke Inst_LD8,OFFSET RegIXL,OFFSET RegE
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpDD5E:
			  ;DD5E d		LD E,(IX+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,reg_di,OFFSET RegE
			  invoke CLK_sync,19,5
			  jmp Z80Loop
	    OpDD5F:
			  jmp Op5F
        OpDD60:
			;DD60		LD IXH,B			8	2
			invoke Inst_LD8,OFFSET RegB,OFFSET RegIXH
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpDD61:
			;DD61		LD IXH,C			8	2
			invoke Inst_LD8,OFFSET RegC,OFFSET RegIXH
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpDD62:
			;DD62		LD IXH,D			8	2
			invoke Inst_LD8,OFFSET RegD,OFFSET RegIXH
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpDD63:
			;DD63		LD IXH,E			8	2
			invoke Inst_LD8,OFFSET RegE,OFFSET RegIXH
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpDD64:
			;DD64		LD IXH,IXH			8	2
			invoke Inst_LD8,OFFSET RegIXH,OFFSET RegIXH
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD65:
			;DD65		LD IXH,IXL			8	2
			invoke Inst_LD8,OFFSET RegIXL,OFFSET RegIXH
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD66:
			  ;DD66 d		LD H,(IX+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,reg_di,OFFSET RegH
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpDD67:
			;DD67		LD IXH,A			8	2
			invoke Inst_LD8,OFFSET RegA,OFFSET RegIXH
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD68:
			;DD68		LD IXL,B			8	2
			invoke Inst_LD8,OFFSET RegB,OFFSET RegIXL
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD69:
			;DD69		LD IXL,C			8	2
			invoke Inst_LD8,OFFSET RegC,OFFSET RegIXL
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD6A:
			;DD6A		LD IXL,D			8	2
			invoke Inst_LD8,OFFSET RegD,OFFSET RegIXL
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpDD6B:
			;DD6B		LD IXL,E			8	2
			invoke Inst_LD8,OFFSET RegE,OFFSET RegIXL
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD6C:
			;DD6C		LD IXL,IXH			8	2
			invoke Inst_LD8,OFFSET RegIXH,OFFSET RegIXL
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD6D:
			;DD6D		LD IXL,IXL			8	2
			invoke Inst_LD8,OFFSET RegIXL,OFFSET RegIXL
			invoke CLK_sync,8,2
            jmp Z80Loop		
       OpDD6E:
			  ;DD6E d		LD L,(IX+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,reg_di,OFFSET RegL
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpDD6F:
			;DD6F		LD IXL,A			8	2
			invoke Inst_LD8,OFFSET RegA,OFFSET RegIXL
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD70:
			  ;DD70 d		LD (IX+d),B 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,OFFSET RegB,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpDD71:
			  ;DD71 d		LD (IX+d),C 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,OFFSET RegC,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpDD72:
			  ;DD72 d		LD (IX+d),D 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,OFFSET RegD,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpDD73:
			  ;DD73 d		LD (IX+d),E 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,OFFSET RegE,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop	 
       OpDD74:
			  ;DD74 d		LD (IX+d),H 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,OFFSET RegH,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpDD75:	
			  ;DD75 d		LD (IX+d),L 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,OFFSET RegL,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
	   OpDD76:
			  jmp Z80Loop
       OpDD77:
			  ;DD77 d		LD (IX+d),A 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,OFFSET RegA,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
		OpDD78:
			  jmp Op78
		OpDD79:
			  jmp Op79
		OpDD7A:
			  jmp Op7A
		OpDD7B:
			  jmp Op7B
        OpDD7C:
			;DD7C		LD A,IXH			8	2
			invoke Inst_LD8,OFFSET RegIXH,OFFSET RegA
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpDD7D:
			;DD7D		LD A,IXL			8	2
			invoke Inst_LD8,OFFSET RegIXL,OFFSET RegA
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpDD7E:
			  ;DD7E d		LD A,(IX+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_LD8,reg_di,OFFSET RegA
			  invoke CLK_sync,19,5
			  jmp Z80Loop
	   OpDD7F:
			  jmp Op7F	
       OpDD84:
			;DD84		ADD A,IXH			8	2
			invoke Inst_ADD8,OFFSET RegIXH
			invoke CLK_sync,8,2
			jmp Z80Loop

       OpDD85:
			;DD85		ADD A,IXL			8	2
			 invoke Inst_ADD8,OFFSET RegIXL
			 invoke CLK_sync,8,2
			 jmp Z80Loop	
       OpDD86:
			   ;DD86 d		ADD A,(IX+d) 19 5
			   invoke DIR_INDEXADO,memPtr,RegIX
			   invoke Inst_ADD8,reg_di
			   invoke CLK_sync,19,5
			   jmp Z80Loop
       OpDD8C:
			;DD8C		ADC A,IXH			8	2
			invoke Inst_ADC8,OFFSET RegIXH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDD8D:
	        ;DD8D		ADC A,IXL			8	2
			 invoke Inst_ADC8,OFFSET RegIXL
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpDD8E:
			  ;DD8E d		ADC A,(IX+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_ADC8,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpDD94:
			;DD94		SUB IXH			8	2
			invoke Inst_SUB,OFFSET RegIXH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDD95:
			;DD95		SUB IXL			8	2
			invoke Inst_SUB,OFFSET RegIXL
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDD96:
			  ;DD96 d		SUB (IX+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_SUB,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
       OpDD9C:
			;DD9C		SBC A,IXH			8	2
			invoke Inst_SBC8,OFFSET RegIXH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDD9D:
			;DD9D		SBC A,IXL			8	2
			invoke Inst_SBC8,OFFSET RegIXL
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDD9E:
			  ;DD9E d		SBC A,(IX+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_SBC8,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpDDA4:
			;DDA4		AND IXH			8	2
			invoke Inst_AND,RegIXH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDDA5:
			;DDA5		AND IXL			8	2
			invoke Inst_AND,RegIXL
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDDA6:
			  ;DDA6 d		AND (IX+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_AND,BYTE PTR [reg_di]
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
       OpDDAC:
			;DDAC		XOR IXH			8	2
			invoke Inst_XOR,RegIXH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDDAD:
			;DDAD		XOR IXL			8	2
			invoke Inst_XOR,RegIXL
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDDAE:
			  ;DDAE d		XOR (IX+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_XOR,BYTE PTR [reg_di]
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpDDB4:
			;DDB4		OR IXH			8	2
			invoke Inst_OR,RegIXH
			invoke CLK_sync,8,2
			jmp Z80Loop	

       OpDDB5:
			;DDB5		OR IXL			8	2
			invoke Inst_OR,RegIXL
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDDB6:
			  ;DDB6 d		OR (IX+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_OR,BYTE PTR [reg_di]
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
      OpDDBC:
			;DDBC		CP IXH			8	2
			invoke Inst_CP,OFFSET RegIXH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpDDBD:
			;DDBD		CP IXL			8	2
			 invoke Inst_CP,OFFSET RegIXL
			 invoke CLK_sync,8,2
			 jmp Z80Loop	
       OpDDBE:
			  ;DDBE d		CP (IX+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIX
			  invoke Inst_CP,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpDDCB:
			   invoke DIR_INDEXADO,memPtr,RegIX
			   ProcesarOpcodeFromRom _TOpDDCB
	   OpDDCB00:
				;DDCB d 00	RLC (IX+d),B  23 6
				invoke Inst_RLC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB01:
				;DDCB d 01	RLC (IX+d),C  23 6
				invoke Inst_RLC,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
		OpDDCB02:
				;DDCB d 02	RLC (IX+d),D  23 6
				invoke Inst_RLC,reg_di		
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB03:
				;DDCB d 03	RLC (IX+d),E  23 6
				invoke Inst_RLC,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB04:
				;DDCB d 04	RLC (IX+d),H  23 6
				invoke Inst_RLC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB05:
				;DDCB d 05	RLC (IX+d),L  23 6
				invoke Inst_RLC,reg_di		
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
		OpDDCB06:
				;DDCB d 06	RLC (IX+d)  23 6
				invoke Inst_RLC,reg_di	
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB07:
				;DDCB d 07	RLC (IX+d),A  23 6
				invoke Inst_RLC,reg_di		
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB08:
				;RRC  (IX+nn)   &  LD   B,(IX+nn)	
				invoke Inst_RRC,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop	   
	   OpDDCB09:
				;RRC  (IX+nn)   &  LD   C,(IX+nn)	
				invoke Inst_RRC,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB0A:
				;RRC  (IX+nn)   &  LD   D,(IX+nn)	
				invoke Inst_RRC,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB0B:
				;RRC  (IX+nn)   &  LD   E,(IX+nn)	
				invoke Inst_RRC,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB0C:
				;RRC  (IX+nn)   &  LD   H,(IX+nn)	
				invoke Inst_RRC,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB0D:
				;RRC  (IX+nn)   &  LD   L,(IX+nn)	
				invoke Inst_RRC,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB0E:
				;DDCB d 0E	RRC (IX+d)	15 4			
			    invoke Inst_RRC,reg_di
				invoke CLK_sync,15,4
			    jmp Z80Loop
	   OpDDCB0F:
				;RRC  (IX+nn)   &  LD   A,(IX+nn)	
				invoke Inst_RRC,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB10:
				;RL   (IX+nn)   &  LD   B,(IX+nn)
				invoke Inst_RL,reg_di		
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB11:
				;RL   (IX+nn)   &  LD   C,(IX+nn)
				invoke Inst_RL,reg_di		
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB12:
				;RL   (IX+nn)   &  LD   D,(IX+nn)
				invoke Inst_RL,reg_di		
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB13:
				;RL   (IX+nn)   &  LD   E,(IX+nn)
				invoke Inst_RL,reg_di		
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB14:
				;RL   (IX+nn)   &  LD   H,(IX+nn)
				invoke Inst_RL,reg_di		
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB15:
				;RL   (IX+nn)   &  LD   L,(IX+nn)
				invoke Inst_RL,reg_di		
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB16:
				;DDCB d 16	RL (IX+d)	23  6			
				invoke Inst_RL,reg_di 
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB17:
				;RL   (IX+nn)   &  LD   A,(IX+nn)
				invoke Inst_RL,reg_di		
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB18:
				;RR   (IX+nn)   &  LD   B,(IX+nn)
				invoke Inst_RR,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB19:
				;RR   (IX+nn)   &  LD   C,(IX+nn)
				invoke Inst_RR,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB1A:
				;RR   (IX+nn)   &  LD   D,(IX+nn)
				invoke Inst_RR,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB1B:
				;RR   (IX+nn)   &  LD   E,(IX+nn)
				invoke Inst_RR,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB1C:
				;RR   (IX+nn)   &  LD   H,(IX+nn)
				invoke Inst_RR,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB1D:
				;RR   (IX+nn)   &  LD   L,(IX+nn)
				invoke Inst_RR,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
       OpDDCB1E:
				;DDCB d 1E	RR (IX+d)	23  6			
				invoke Inst_RR,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB1F::
				;RR   (IX+nn)   &  LD   A,(IX+nn)
				invoke Inst_RR,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB20:
				;SLA  (IX+nn)   &  LD   B,(IX+nn)
				invoke Inst_SLA,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB21:
				;SLA  (IX+nn)   &  LD   C,(IX+nn)
				invoke Inst_SLA,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB22:
				;SLA  (IX+nn)   &  LD   D,(IX+nn)
				invoke Inst_SLA,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB23:
			    ;SLA  (IX+nn)   &  LD   E,(IX+nn)
				invoke Inst_SLA,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB24:
				;SLA  (IX+nn)   &  LD   H,(IX+nn)
				invoke Inst_SLA,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB25:
				;SLA  (IX+nn)   &  LD   L,(IX+nn)
				invoke Inst_SLA,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
       OpDDCB26:
			    ;DDCB d 26	SLA (IX+d)	23  6			
				invoke Inst_SLA,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB27:
			    ;SLA  (IX+nn)   &  LD   A,(IX+nn)
				invoke Inst_SLA,reg_di	
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB28:
				;SRA  (IX+nn)   &  LD   B,(IX+nn)
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB29:
			    ;SRA  (IX+nn)   &  LD   C,(IX+nn)
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB2A:
				;SRA  (IX+nn)   &  LD   D,(IX+nn)
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB2B:
			   ;SRA  (IX+nn)   &  LD   E,(IX+nn)
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB2C:
				;SRA  (IX+nn)   &  LD   H,(IX+nn)
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB2D:
			    ;SRA  (IX+nn)   &  LD   L,(IX+nn)
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
       OpDDCB2E:
				;DDCB d 2E	SRA (IX+d)	23  6			
				invoke Inst_SRA,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB2F:
				;SRA  (IX+nn)   &  LD   A,(IX+nn)
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB30:
				;SLL  (IX+nn)   &  LD   B,(IX+nn)
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB31:
				;SLL  (IX+nn)   &  LD   C,(IX+nn)
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB32:
				;SLL  (IX+nn)   &  LD   D,(IX+nn)
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB33:
				;SLL  (IX+nn)   &  LD   E,(IX+nn)
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB34:
				;SLL  (IX+nn)   &  LD   H,(IX+nn)
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB35:
				;SLL  (IX+nn)   &  LD   L,(IX+nn)
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB36:
				 ;DDCB d 36		SLL (IX+d) 23 6
				 invoke Inst_SLL,reg_di
				 invoke CLK_sync,23,6
				 jmp Z80Loop
	   OpDDCB37:
				;SLL  (IX+nn)   &  LD   A,(IX+nn)
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB38:
				;SRL  (IX+nn)   &  LD   B,(IX+nn)
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB39:
				;SRL  (IX+nn)   &  LD   C,(IX+nn)
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB3A:
				;FDCB d 3D	SRL (IX+d),D 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	  OpDDCB3B:
				;FDCB d 3B	SRL (IX+d),E 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB3C:
				;FDCB d 3D	SRL (IX+d),H 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB3D:
				;DDCB d 3D	SRL (IX+d),L 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB3E:
			    ;DDCB d 3E	SRL (IX+d) 23 6				
				invoke Inst_SRL,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpDDCB3F:
			    ;FDCB d 3F	SRL (IX+d),A 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
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
				;DDCB d 46	BIT 0,(IX+d) 20 5
				invoke Inst_BIT,reg_di,0
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;DDCB d 4E	BIT 1,(IX+d) 20 5				
				invoke Inst_BIT,reg_di,1
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;DDCB d 56	BIT 2,(IX+d) 20 5				
				invoke Inst_BIT,reg_di,2
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;DDCB d 5E	BIT 3,(IX+d) 20 5				
				invoke Inst_BIT,reg_di,3
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;DDCB d 66	BIT 4,(IX+d) 20 5				
				invoke Inst_BIT,reg_di,4
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;DDCB d 6E	BIT 5,(IX+d) 20 5				
				invoke Inst_BIT,reg_di,5
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;DDCB d 76	BIT 6,(IX+d) 20 5				
				invoke Inst_BIT,reg_di,6
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;DDCB d 7E	BIT 7,(IX+d) 20 5				
				invoke Inst_BIT,reg_di,7
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB7F:
				jmp OpDDCB7E	   
	   OpDDCB80:
				;RES  0,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB81:
				;RES  0,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB82:
				;RES  0,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB83:
				;RES  0,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB84:
				;RES  0,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB85:
				;RES  0,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCB86:
				;DDCB d 86	RES 0,(IX+d) 20 5				
				invoke Inst_RES,reg_di,0
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB87:
				;RES  0,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB88:
				;RES  1,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB89:
				;RES  1,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB8A:
				;RES  1,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB8B:
				;RES  1,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB8C:
				;RES  1,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB8D:
				;RES  1,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCB8E:
				;DDCB d 8E	RES 1,(IX+d) 23 6			
				invoke Inst_RES,reg_di,1
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpDDCB8F:
				;RES  1,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB90:
				;RES  2,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB91:
				;RES  2,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB92:
				;RES  2,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB93:
				;RES  2,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB94:
				;RES  2,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB95:
				;RES  2,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCB96:
				;DDCB d 96	RES 2,(IX+d) 23 6				
				invoke Inst_RES,reg_di,2
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpDDCB97:
				;RES  2,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB98:
				;RES  3,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB99:
				;RES  3,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB9A:
				;RES  3,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB9B:
				;RES  3,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB9C:
				;RES  3,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCB9D:
				;RES  3,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCB9E:
				;DDCB d 9E	RES 3,(IX+d) 23  6				
				invoke Inst_RES,reg_di,3
				invoke CLK_sync,23,6 
				jmp Z80Loop
	   OpDDCB9F:
				;RES  3,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBA0:
				;RES  4,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBA1:
				;RES  4,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBA2:
				;RES  4,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBA3:
				;RES  4,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBA4:
				;RES  4,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBA5:
				;RES  4,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBA6:
				;DDCB d A6	RES 4,(IX+d) 23 6				
				invoke Inst_RES,reg_di,4
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpDDCBA7:
				;RES  4,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBA8:
				;RES  5,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBA9:
				;RES  5,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBAA:
				;RES  5,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBAB:
				;RES  5,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBAC:
				;RES  5,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBAD:
				;RES  5,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBAE:
				;DDCB d AE	RES 5,(IX+d) 23 6				
				invoke Inst_RES,reg_di,5
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpDDCBAF:
				;RES  5,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBB0:
				;RES  6,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBB1:
				;RES  6,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBB2:
				;RES  6,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBB3:
				;RES  6,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBB4:
				;RES  6,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBB5:
				;RES  6,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBB6:
				;DDCB d B6	RES 6,(IX+d) 23 6				
				invoke Inst_RES,reg_di,6
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpDDCBB7:
				;RES  6,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBB8:
				;RES  7,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBB9:
				;RES  7,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBBA:
				;RES  7,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBBB:
				;RES  7,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBBC:
				;RES  7,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBBD:
				;RES  7,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBBE:
				;DDCB d BE	RES 7,(IX+d) 23 6				
				invoke Inst_RES,reg_di,7
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpDDCBBF:
				;RES  7,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBC0:
				;SET  0,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBC1:
				;SET  0,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBC2:
				;SET  0,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBC3:
				;SET  0,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBC4:
				;SET  0,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBC5:
				;SET  0,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBC6:
				;DDCB d C6	SET 0,(IX+d) 23 6				
				invoke Inst_Set,reg_di,0
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpDDCBC7:
				;SET  0,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBC8:
				;SET  1,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBC9:
				;SET  1,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBCA:
				;SET  1,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBCB:
				;SET  1,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBCC:
				;SET  1,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBCD:
				;SET  1,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBCE:
				;DDCB d CE	SET 1,(IX+d) 23 6				
				invoke Inst_Set,reg_di,1
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpDDCBCF:
				;SET  1,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBD0:
				;SET  2,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBD1:
				;SET  2,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBD2:
				;SET  2,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBD3:
				;SET  2,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBD4:
				;SET  2,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBD5:
				;SET  2,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBD6:
				;DDCB d D6	SET 2,(IX+d) 23 6				
				invoke Inst_Set,reg_di,2
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpDDCBD7:
				;SET  2,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBD8:
				;SET  3,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBD9:
				;SET  3,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBDA:
				;SET  3,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBDB:
				;SET  3,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBDC:
				;SET  3,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBDD:
				;SET  3,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBDE:
				;DDCB d DE	SET 3,(IX+d) 23 6				
				invoke Inst_Set,reg_di,3
				invoke CLK_sync,23,6
				jmp Z80Loop
		OpDDCBDF:
				;SET  3,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	    OpDDCBE0:
				;SET  4,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop	
	   OpDDCBE1:
				;SET  4,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop	
	   OpDDCBE2:
				;SET  4,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop	
	   OpDDCBE3:
				;SET  4,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBE4:
				;SET  4,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBE5:
				;SET  4,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBE6:
				;DDCB d E6	SET 4,(IX+d) 23 6				
				invoke Inst_Set,reg_di,4
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpDDCBE7:
				;SET  4,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBE8:
				;SET  5,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop	
       OpDDCBE9:
				;SET  5,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBEA:
				;SET  5,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBEB:
				;SET  5,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBEC:
				;SET  5,(IX+nn) &  LD   H,IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBED:
				;SET  5,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBEE:
				;DDCB d EE	SET 5,(IX+d) 23 6				
				invoke Inst_Set,reg_di,5
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpDDCBEF:
				;SET  5,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBF0:
				;SET  6,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop	
	   OpDDCBF1:
				;SET  6,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBF2:
				;SET  6,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBF3:
				;SET  6,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBF4:
				;SET  6,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBF5:
				;SET  6,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBF6:
				;DDCB d F6	SET 6,(IX+d) 23 6				
				invoke Inst_Set,reg_di,6
				invoke CLK_sync,23,6 
				jmp Z80Loop
	   OpDDCBF7:
				;SET  6,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBF8:
				;SET  7,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop	
	   OpDDCBF9:
				;SET  7,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBFA:
				;SET  7,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBFB:
				;SET  7,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBFC:
				;SET  7,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDCBFD:
				;SET  7,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpDDCBFE:
				;DDCB d FE	SET 7,(IX+d) 23 6				
				invoke Inst_Set,reg_di,7
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpDDCBFF:
				;SET  7,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpDDE1:
			   ;DDE1		POP IX 14 4
			   invoke Inst_POP,memPtr,OFFSET RegIX
			   invoke CLK_sync,14,4
			   jmp Z80Loop
       OpDDE3:
			  ;DDE3		EX (SP),IX 23 6
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegSP
			  invoke Inst_EX8,OFFSET RegIXL,reg_di,
			  mov x_cx,reg_di
			  sub x_cx,memPtr
			  inc cx
			  mov reg_di,memPtr
			  add reg_di,x_cx
              invoke Inst_EX8,OFFSET RegIXH,reg_di
			  invoke CLK_sync,23,6
			  jmp Z80Loop
       OpDDE5:
			  ;DDE5		PUSH IX 15 4
			  invoke Inst_PUSH,memPtr,RegIX
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpDDE9:
			  ;DDE9		JP (IX) 8 2
			   invoke Inst_JP,memPtr,RegIX
			   invoke CLK_sync,8,2
			   jmp Z80Loop
       OpDDF9:
			  ;DDF9		LD SP,IX 10 2 
			  invoke Inst_LD16,OFFSET RegIX,OFFSET RegSP
			  invoke CLK_sync,10,2
			  jmp Z80Loop
       
       OpFD09:
			  ;FD09		ADD IY,BC	15 4		  
			  invoke Inst_ADD16,OFFSET RegBC,OFFSET RegIY
			  invoke CLK_sync,15,4
			  jmp Z80Loop
		
       OpFD19:
			   ;FD19		ADD IY,DE 15 4			  
			  invoke Inst_ADD16,OFFSET RegDE,OFFSET RegIY
			  invoke CLK_sync,15,4
			  jmp Z80Loop
       OpFD21:
			  ;FD21 n n	LD IY,nn 14 4 
			  invoke DIR_INMEDIATO_EXT,memPtr
			  invoke Inst_LD16,reg_di,OFFSET RegIY
			  invoke CLK_sync,14,4
			  jmp Z80Loop
       OpFD22:
			  ;FD22 n n	LD (nn),IY 20 6 
			  invoke DIR_EXT,memPtr	   	 	   	  	  	  
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,di
			  invoke Inst_LD16,OFFSET RegIY,reg_di	
			  invoke CLK_sync,20,6
			  jmp Z80Loop
       OpFD23:
			  ;FD23		INC IY 10 2
			invoke Inst_INC16,OFFSET RegIY		
			invoke CLK_sync,10,2
			jmp Z80Loop
      OpFD24:
			 ;FD24       INC  IYH	8	2
			 invoke Inst_INC8,OFFSET RegIYH
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpFD25:
			 ;FD25       DEC  IYH	8	2
			 invoke Inst_DEC8,OFFSET RegIYH
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpFD26:
			;FD26 n		LD   IYH,n			11	3
			invoke DIR_INMEDIATO,memPtr			
            invoke Inst_LD8,reg_di,OFFSET RegIYH
			invoke CLK_sync,11,3
			jmp Z80Loop	
       OpFD29:
			  ; FD29		ADD IY,IY 15 4			  
			  invoke Inst_ADD16,OFFSET RegIY,OFFSET RegIY
			  invoke CLK_sync,15,4
			  jmp Z80Loop	
       OpFD2A:
			  ;FD2A n n	LD IY,(nn) 20 6 
			  invoke DIR_EXT,memPtr
			  add reg_di,memPtr	 	   	  	  	  
			  invoke Inst_LD16,reg_di,OFFSET RegIY	
			  invoke CLK_sync,20,6
			  jmp Z80Loop
       OpFD2B:
			;FD2B		DEC IY 10 2
			invoke Inst_DEC16,OFFSET RegIY				
			invoke CLK_sync,10,2
			jmp Z80Loop	
       OpFD2C:
			 ;FD2C		INC  IYL	8	2
			 invoke Inst_INC8,OFFSET RegIYL
			 invoke CLK_sync,8,2
			 jmp Z80Loop	
       OpFD2D:
			  ;FD2D		DEC  IYL	8	2
			 invoke Inst_DEC8,OFFSET RegIYL
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpFD2E:
			 ;FD2E LD   IYL,n	 11	3
			 invoke DIR_INMEDIATO,memPtr			
             invoke Inst_LD8,reg_di,OFFSET RegIYL
			 invoke CLK_sync,11,3
			 jmp Z80Loop			 
       OpFD34:
			  ;FD34 d		INC (IY+d) 23 6
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_INC8,reg_di
			  invoke CLK_sync,23,6
			  jmp Z80Loop
       OpFD35:
			  ;FD35 d		DEC (IY+d) 23 6	
			  invoke DIR_INDEXADO,memPtr,RegIY				  		  
			  invoke Inst_DEC8,reg_di			  
			  invoke CLK_sync,23,6	
			  jmp Z80Loop	
       OpFD36:
			 ;FD36 d n	LD (IY+d),n 19  5 0
			 invoke DIR_INDEXADO,memPtr,RegIY
			 mov reg_si,reg_di
			 invoke DIR_INMEDIATO,memPtr
			 invoke Inst_LD8,reg_di,reg_si
			 invoke CLK_sync,19,50
			 jmp Z80Loop
       OpFD39:
			  ;FD39		ADD IY,SP 15 4
			  invoke Inst_ADD16,OFFSET RegSP,OFFSET RegIY
			  invoke CLK_sync,15,4
			  jmp Z80Loop		
       OpFD40:
			  jmp Op40
       OpFD41:
			  jmp Op41
       OpFD42:
			  jmp Op42
       OpFD43:
			  jmp Op43
       OpFD44:
			 ;DD44		LD   B,IYH			8	2
			 invoke Inst_LD8,OFFSET RegIYH,OFFSET RegB
			 invoke CLK_sync,8,2
             jmp Z80Loop
       OpFD45:
			 ; DD45		LD   B,IYL			8	2
			 invoke Inst_LD8,OFFSET RegIYL,OFFSET RegB
			 invoke CLK_sync,8,2
             jmp Z80Loop
       OpFD46:
			 ;FD46 d		LD B,(IY+d) 19 5 
			 invoke DIR_INDEXADO,memPtr,RegIY
			 invoke Inst_LD8,reg_di,OFFSET RegB
			 invoke CLK_sync,19,5
			 jmp Z80Loop	
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
			  ;FD4C		LD   C,IYH			8	2
			  invoke Inst_LD8,OFFSET RegIYH,OFFSET RegC
			  invoke CLK_sync,8,2
              jmp Z80Loop	
       OpFD4D:
			  ;FD4D		LD   C,IYL			8	2
			  invoke Inst_LD8,OFFSET RegIYL,OFFSET RegC
			  invoke CLK_sync,8,2
              jmp Z80Loop
       OpFD4E:
			  ;FD4E d		LD C,(IY+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,reg_di,OFFSET RegC
			  invoke CLK_sync,19,5
			  jmp Z80Loop
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
			;FD54		D,IYH			8	2
			invoke Inst_LD8,OFFSET RegIYH,OFFSET RegD
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpFD55:
			;FD55		D,IYL			8	2
			invoke Inst_LD8,OFFSET RegIYL,OFFSET RegD
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpFD56:
			  ;FD56 d		LD D,(IY+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,reg_di,OFFSET RegD
			  invoke CLK_sync,19,5
			  jmp Z80Loop
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
			;FD5C		LD E,IYH			8	2
			invoke Inst_LD8,OFFSET RegIYH,OFFSET RegE
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD5D:
			;FD5D		LD E,IYL			8	2
			invoke Inst_LD8,OFFSET RegIYL,OFFSET RegE
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD5E:
			  ;FD5E d		LD E,(IY+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,reg_di,OFFSET RegE
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
		OpFD5F:
			  jmp Op5F
        OpFD60:
			;DD60		LD IYH,B			8	2
			invoke Inst_LD8,OFFSET RegB,OFFSET RegIYH
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD61:
			;FD61		LD IYH,C			8	2
			invoke Inst_LD8,OFFSET RegC,OFFSET RegIYH
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD62:
			;FD62		LD IYH,D			8	2
			invoke Inst_LD8,OFFSET RegD,OFFSET RegIYH
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD63:
			;FD63		LD IYH,E			8	2
			invoke Inst_LD8,OFFSET RegE,OFFSET RegIYH
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD64:
			;FD64		LD IYH,IYH			8	2
			invoke Inst_LD8,OFFSET RegIYH,OFFSET RegIYH
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpFD65:
			;FD65		LD IYH,IYL			8	2
			invoke Inst_LD8,OFFSET RegIYL,OFFSET RegIYH
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD66:
			  ;FD66 d		LD H,(IY+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,reg_di,OFFSET RegH
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpFD67:
			;FD67		LD IYH,A			8	2
			invoke Inst_LD8,OFFSET RegA,OFFSET RegIYH
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD68:
			;FD68		LD IYL,B			8	2
			invoke Inst_LD8,OFFSET RegB,OFFSET RegIYL
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpFD69:
			;FD69		LD IYL,C			8	2
			invoke Inst_LD8,OFFSET RegC,OFFSET RegIYL
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD6A:
			;FD6A		LD IYL,D			8	2
			invoke Inst_LD8,OFFSET RegD,OFFSET RegIYL
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpFD6B:
			;FD6B		LD IYL,E			8	2
			invoke Inst_LD8,OFFSET RegE,OFFSET RegIYL
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpFD6C:
			;FD6C		LD IYL,IYH			8	2
			invoke Inst_LD8,OFFSET RegIYH,OFFSET RegIYL
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpFD6D:
			;FD6D		LD IYL,IYL			8	2
			invoke Inst_LD8,OFFSET RegIYL,OFFSET RegIYL
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD6E:
			  ;FD6E d		LD L,(IY+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,reg_di,OFFSET RegL
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
       OpFD6F:
			;FD6F		LD IYL,A			8	2
			invoke Inst_LD8,OFFSET RegA,OFFSET RegIYL
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpFD70:
			  ;FD70 d		LD (IY+d),B 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,OFFSET RegB,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpFD71:
			  ;FD71 d		LD (IY+d),C 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,OFFSET RegC,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop		
       OpFD72:
			  ;FD72 d		LD (IY+d),D 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,OFFSET RegD,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop 					
       OpFD73:
			  ;FD73 d		LD (IY+d),E 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,OFFSET RegE,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpFD74:
			  ;FD74 d		LD (IY+d),H 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,OFFSET RegH,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
       OpFD75:
			 ;FD75 d		LD (IY+d),L 19 5 
			 invoke DIR_INDEXADO,memPtr,RegIY
			 invoke Inst_LD8,OFFSET RegL,reg_di
			 invoke CLK_sync,19,5
			 jmp Z80Loop
	   OpFD76:
			 jmp Z80Loop
       OpFD77:
			  ;FD77 d		LD (IY+d),A 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,OFFSET RegA,reg_di
			  invoke CLK_sync,19,5,
			  jmp Z80Loop		
		OpFD78:
			  jmp Op78
		OpFD79:
			  jmp Op79
		OpFD7A:
			  jmp Op7A
		OpFD7B:
			  jmp op7B
		OpFD7C:
			;FD7C		LD A,IYH			8	2
			invoke Inst_LD8,OFFSET RegIYH,OFFSET RegA
			invoke CLK_sync,8,2
            jmp Z80Loop
       OpFD7D:
			;FD7D		LD A,IYL			8	2
			invoke Inst_LD8,OFFSET RegIYL,OFFSET RegA
			invoke CLK_sync,8,2
            jmp Z80Loop	
       OpFD7E:
			  ;FD7E d		LD A,(IY+d) 19 5 
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_LD8,reg_di,OFFSET RegA
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
	   OpFD7F:
			  jmp Op7F
       OpFD84:
			;FD84		ADD A,IYH			8	2
			invoke Inst_ADD8,OFFSET RegIYH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFD85:
			 ;FD85		ADD A,IYL			8	2
			 invoke Inst_ADD8,OFFSET RegIYL
			 invoke CLK_sync,8,2
			 jmp Z80Loop	
       OpFD86:
			  ;FD86 d		ADD A,(IY+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_ADD8,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop			  
      OpFD8C:
			;DD8C		ADC A,IYH			8	2
			invoke Inst_ADC8,OFFSET RegIYH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFD8D:
	        ;DD8D		ADC A,IYL			8	2
			 invoke Inst_ADC8,OFFSET RegIYL
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpFD8E:
			  ;FD8E d		ADC A,(IY+d)  19 5
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_ADC8,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
      OpFD94:
			;FD94		SUB IYH			8	2
			invoke Inst_SUB,OFFSET RegIYH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFD95:
			;FD95		SUB IYL			8	2
			invoke Inst_SUB,OFFSET RegIYL
			invoke CLK_sync,8,2
			jmp Z80Loop	
       OpFD96:
			  ;FD96 d		SUB (IY+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_SUB,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpFD9C:
			;FD9C		SBC A,IYH			8	2
			invoke Inst_SBC8,OFFSET RegIYH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFD9D:
			;FD9D		SBC A,IYL			8	2
			invoke Inst_SBC8,OFFSET RegIYL
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFD9E:
			  ;FD9E d		SBC A,(IY+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_SBC8,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpFDA4:
			;FDA4		AND IYH			8	2
			invoke Inst_AND,RegIYH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFDA5:
			;FDA5		AND IYL			8	2
			invoke Inst_AND,RegIYL
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFDA6:
			  ;FDA6 d		AND (IY+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_AND,BYTE PTR [reg_di]
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
       OpFDAC:
			;FDAC		XOR IYH			8	2
			invoke Inst_XOR,RegIYH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFDAD:
			;FDAD		XOR IYL			8	2
			invoke Inst_XOR,RegIYL
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFDAE:
			  ;FDAE d		XOR (IY+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_XOR,BYTE PTR [reg_di]
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpFDB4:
			;FDB4		OR IYH			8	2
			invoke Inst_OR,RegIYH
			invoke CLK_sync,8,2
			jmp Z80Loop	

       OpFDB5:
			;FDB5		OR IYL			8	2
			invoke Inst_OR,RegIYL
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFDB6:
			  ;FDB6 d		OR (IY+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_OR,BYTE PTR [reg_di]
			  invoke CLK_sync,19,5
			  jmp Z80Loop
       OpFDBC:
			;FDBC		CP IYH			8	2
			invoke Inst_CP,OFFSET RegIYH
			invoke CLK_sync,8,2
			jmp Z80Loop
       OpFDBD:
			 ;FDBD		CP IYL			8	2
			 invoke Inst_CP,OFFSET RegIYL
			 invoke CLK_sync,8,2
			 jmp Z80Loop
       OpFDBE:
			  ;FDBE d		CP (IY+d) 19 5
			  invoke DIR_INDEXADO,memPtr,RegIY
			  invoke Inst_CP,reg_di
			  invoke CLK_sync,19,5
			  jmp Z80Loop	
       OpFDCB:
			   invoke DIR_INDEXADO,memPtr,RegIY
			   ProcesarOpcodeFromRom _TOpFDCB
	   OpFDCB00:
			    ;FDCB d 06	RLC (IY+d),B 23 6
				invoke Inst_RLC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB01:
				;FDCB d 06	RLC (IY+d),C 23 6
				invoke Inst_RLC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB02:
				;FDCB d 06	RLC (IY+d),D 23 6
				invoke Inst_RLC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB03:
				;FDCB d 06	RLC (IY+d),E 23 6
				invoke Inst_RLC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB04:
				;FDCB d 06	RLC (IY+d),H 23 6
				invoke Inst_RLC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB05:
				;FDCB d 06	RLC (IY+d),L 23 6
				invoke Inst_RLC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB06:
				;FDCB d 06	RLC (IY+d) 23 6
				invoke Inst_RLC,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB07:
				;FDCB d 06	RLC (IY+d),A 23 6
				invoke Inst_RLC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB08:
				;FDCB d 0E	RRC (IY+d),B	23 6			
				invoke Inst_RRC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB09:
				;FDCB d 0E	RRC (IY+d),C	23 6			
				invoke Inst_RRC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB0A:
				;FDCB d 0E	RRC (IY+d),D	23 6			
				invoke Inst_RRC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB0B:
				;FDCB d 0E	RRC (IY+d),E	23 6			
				invoke Inst_RRC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB0C:
				;FDCB d 0E	RRC (IY+d),H	23 6			
				invoke Inst_RRC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB0D:
				;FDCB d 0E	RRC (IY+d),L	23 6			
				invoke Inst_RRC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB0E:
				;FDCB d 0E	RRC (IY+d)	23 6			
				invoke Inst_RRC,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB0F:
				;FDCB d 0E	RRC (IY+d),A	23 6			
				invoke Inst_RRC,reg_di
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB10:
				;FDCB d 10	RL (IY+d),B 23 6
				invoke Inst_RL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB11:
				;FDCB d 11	RL (IY+d),C 23 6
				invoke Inst_RL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB12:
				;FDCB d 12	RL (IY+d),D 23 6
				invoke Inst_RL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB13:
				;FDCB d 13	RL (IY+d),E 23 6
				invoke Inst_RL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB14:
				;FDCB d 14	RL (IY+d),H 23 6
				invoke Inst_RL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB15:
				;FDCB d 15	RL (IY+d),L 23 6
				invoke Inst_RL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB16:
				;FDCB d 16	RL (IY+d) 23 6
				invoke Inst_RL,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB17:
				;FDCB d 15	RL (IY+d),A 23 6
				invoke Inst_RL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB18:
				;FDCB d 18	RR (IY+d),B 23 6
				invoke Inst_RR,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB19:
				;FDCB d 19	RR (IY+d),C 23 6
				invoke Inst_RR,reg_di
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB1A:
				;FDCB d 1A	RR (IY+d),D 23 6
				invoke Inst_RR,reg_di
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB1B:
				;FDCB d 1B	RR (IY+d),E 23 6
				invoke Inst_RR,reg_di
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB1C:
				;FDCB d 1C	RR (IY+d),H 23 6
				invoke Inst_RR,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB1D:
				;FDCB d 1D	RR (IY+d),L 23 6
				invoke Inst_RR,reg_di
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
       OpFDCB1E:
				;FDCB d 1E	RR (IY+d) 23 6
				invoke Inst_RR,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB1F:
				;FDCB d 1D	RR (IY+d),A 23 6
				invoke Inst_RR,reg_di
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB20:
			   ;FDCB d 20	SLA (IY+d),B 23 6
			   invoke Inst_SLA,reg_di
			   CopyMemToMem8 reg_di,OFFSET RegB
			   invoke CLK_sync,23,6
			   jmp Z80Loop
	   OpFDCB21:
			   ;FDCB d 21	SLA (IY+d),C 23 6
			   invoke Inst_SLA,reg_di
			   CopyMemToMem8 reg_di,OFFSET RegC
			   invoke CLK_sync,23,6
			   jmp Z80Loop
	   OpFDCB22:
			   ;FDCB d 22	SLA (IY+d),D 23 6
			   invoke Inst_SLA,reg_di
			   CopyMemToMem8 reg_di,OFFSET RegD
			   invoke CLK_sync,23,6
			   jmp Z80Loop
	   OpFDCB23:
			   ;FDCB d 23	SLA (IY+d),E 23 6
			   invoke Inst_SLA,reg_di
			   CopyMemToMem8 reg_di,OFFSET RegE
			   invoke CLK_sync,23,6
			   jmp Z80Loop
	   OpFDCB24:
	           ;FDCB d 24	SLA (IY+d),H 23 6
			   invoke Inst_SLA,reg_di
			   CopyMemToMem8 reg_di,OFFSET RegH
			   invoke CLK_sync,23,6
			   jmp Z80Loop
	   OpFDCB25:
			   ;FDCB d 25	SLA (IY+d),L 23 6
			   invoke Inst_SLA,reg_di
			   CopyMemToMem8 reg_di,OFFSET RegL
			   invoke CLK_sync,23,6
			   jmp Z80Loop
       OpFDCB26:
			    ;FDCB d 26	SLA (IY+d) 23 6
				invoke Inst_SLA,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB27:
			    ;FDCB d 27	SLA (IY+d),A 23 6
			    invoke Inst_SLA,reg_di
			    CopyMemToMem8 reg_di,OFFSET RegA
			    invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB28:
			    ;FDCB d 28	SRA (IY+d),B 23 6
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB29:
				;FDCB d 29	SRA (IY+d),C 23 6
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB2A:
				;FDCB d 2A	SRA (IY+d),D 23 6
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB2B:
				;FDCB d 2B	SRA (IY+d),E 23 6
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB2C:
				;FDCB d 2C	SRA (IY+d),H 23 6
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB2D:
				;FDCB d 2D	SRA (IY+d),L 23 6
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
       OpFDCB2E:
				;FDCB d 2E	SRA (IY+d) 23 6
				invoke Inst_SRA,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB2F:
				;FDCB d 2F	SRA (IY+d) 23 6
				invoke Inst_SRA,reg_di
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB30:
				;FDCB d 30		SLL (IY+d),B 23 6
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,15,4
				jmp Z80Loop
	   OpFDCB31:
				;FDCB d 31		SLL (IY+d),C 23 6
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,15,4
				jmp Z80Loop
	   OpFDCB32:
				;FDCB d 32		SLL (IY+d),D 23 6
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,15,4
				jmp Z80Loop
	   OpFDCB33:
				;FDCB d 33		SLL (IY+d),E 23 6
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,15,4
				jmp Z80Loop
	   OpFDCB34:
				;FDCB d 34		SLL (IY+d),H 23 6
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,15,4
				jmp Z80Loop
	   OpFDCB35:
				;FDCB d 35		SLL (IY+d),L 23 6
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,15,4
				jmp Z80Loop
	   OpFDCB36:
				 ;FDCB d 36		SLL (IY+d) 23 6
				 invoke Inst_SLL,reg_di
				 invoke CLK_sync,15,4
				 jmp Z80Loop
	   OpFDCB37:
				;FDCB d 37		SLL (IY+d),A 23 6
				invoke Inst_SLL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,15,4
				jmp Z80Loop
	   OpFDCB38:
				;FDCB d 38		SRL (IY+d),B 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,15,4
				jmp Z80Loop
	   OpFDCB39:
				;FDCB d 39		SRL (IY+d),C 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,15,4
				jmp Z80Loop
	   OpFDCB3A:
				;FDCB d 3D	SRL (IY+d),D 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
			    jmp Z80Loop
	  OpFDCB3B:
				;FDCB d 3B	SRL (IY+d),E 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB3C:
				;FDCB d 3D	SRL (IY+d),H 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB3D:
				;FDCB d 3D	SRL (IY+d),L 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
			    jmp Z80Loop
	   OpFDCB3E:
			    ;FDCB d 3E	SRL (IY+d) 23 6
				invoke Inst_SRL,reg_di
				invoke CLK_sync,23,6
			    jmp Z80Loop	   
	   OpFDCB3F:
			    ;FDCB d 3F	SRL (IY+d) 23 6
				invoke Inst_SRL,reg_di
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
			    jmp Z80Loop
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
				;FDCB d 46	BIT 0,(IY+d) 20 5
				invoke Inst_BIT,reg_di,0
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;FDCB d 4E	BIT 1,(IY+d) 20 5			
				invoke Inst_BIT,reg_di,1
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;FDCB d 56	BIT 2,(IY+d) 20 5
				invoke Inst_BIT,reg_di,2
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;FDCB d 5E	BIT 3,(IY+d) 20 5
				invoke Inst_BIT,reg_di,3
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;FDCB d 66	BIT 4,(IY+d) 20 5
				invoke Inst_BIT,reg_di,4
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;FDCB d 6E	BIT 5,(IY+d) 20 5
				invoke Inst_BIT,reg_di,5
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;FDCB d 76	BIT 6,(IY+d) 20 5
				invoke Inst_BIT,reg_di,6
				invoke CLK_sync,20,5
				jmp Z80Loop
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
				;FDCB d 7E	BIT 7,(IY+d) 20 5
				invoke Inst_BIT,reg_di,7
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCB7F:
				jmp OpFDCB7E
	   OpFDCB80:
				;FDCB d 80	RES 0,(IY+d),B 23 6
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB81:
				;FDCB d 81	RES 0,(IY+d),C 23 6
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB82:
				;FDCB d 82	RES 0,(IY+d),D 23 6
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB83:
				;FDCB d 83	RES 0,(IY+d),E 23 6
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB84:
				;FDCB d 84	RES 0,(IY+d),H 23 6
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB85:
				;FDCB d 85	RES 0,(IY+d),L 23 6
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpFDCB86:
				;FDCB d 86	RES 0,(IY+d) 23 6
				invoke Inst_RES,reg_di,0
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB87:
				;FDCB d 87	RES 0,(IY+d),A 23 6
				invoke Inst_RES,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB88:
				;FDCB d 88	RES 1,(IY+d),B 23 6
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB89:
				;FDCB d 89	RES 1,(IY+d),C 23 6
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB8A:
				;FDCB d 8A	RES 1,(IY+d),D 23 6
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB8B:
				;FDCB d 8B	RES 1,(IY+d),E 23 6
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB8C:
				;FDCB d 8C	RES 1,(IY+d),H 23 6
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB8D:
				;FDCB d 8D	RES 1,(IY+d),L 23 6
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpFDCB8E:
				;FDCB d 8E	RES 1,(IY+d) 23 6
				invoke Inst_RES,reg_di,1
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB8F:
				;FDCB d 8F	RES 1,(IY+d),A 23 6
				invoke Inst_RES,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB90:
				;FDCB d 90	RES 2,(IY+d),B 23 6
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB91:
				;FDCB d 91	RES 2,(IY+d),C 23 6
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB92:
				;FDCB d 92	RES 2,(IY+d),D 23 6
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB93:
				;FDCB d 93	RES 2,(IY+d),E 23 6
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB94:
				;FDCB d 94	RES 2,(IY+d),H 23 6
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB95:
				;FDCB d 95	RES 2,(IY+d),L 23 6
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpFDCB96:
				;FDCB d 96	RES 2,(IY+d) 23 6
				invoke Inst_RES,reg_di,2
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB97:
				;FDCB d 97	RES 2,(IY+d),A 23 6
				invoke Inst_RES,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB98:
				;FDCB d 98	RES 3,(IY+d),B 23 6
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB99:
				;FDCB d 99	RES 3,(IY+d),C 23 6
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB9A:
				;FDCB d 9A	RES 3,(IY+d),D 23 6
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB9B:
				;FDCB d 9B	RES 3,(IY+d),E 23 6
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB9C:
				;FDCB d 9C	RES 3,(IY+d),H 23 6
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB9D:
				;FDCB d 9D	RES 3,(IY+d),L 23 6
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpFDCB9E:
				;FDCB d 9E	RES 3,(IY+d) 23 6
				invoke Inst_RES,reg_di,3
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCB9F:
				;FDCB d 9D	RES 3,(IY+d),A 23 6
				invoke Inst_RES,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBA0:
				;FDCB d A0	RES 4,(IY+d),B 23 6
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBA1:
				;FDCB d A1	RES 4,(IY+d),C 23 6
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBA2:
				;FDCB d A2	RES 4,(IY+d),D 23 6
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBA3:
				;FDCB d A3	RES 4,(IY+d),E 23 6
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBA4:
				;FDCB d A4	RES 4,(IY+d),H 23 6
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBA5:
				;FDCB d A5	RES 4,(IY+d),L 23 6
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpFDCBA6:
				;FDCB d A6	RES 4,(IY+d) 23 6
				invoke Inst_RES,reg_di,4
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBA7:
				;FDCB d A7	RES 4,(IY+d),A 23 6
				invoke Inst_RES,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBA8:
				;FDCB d A8	RES 5,(IY+d),B 23 6
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBA9:
				;FDCB d A9	RES 5,(IY+d),C 23 6
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBAA:
				;FDCB d AA	RES 5,(IY+d),D 23 6
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBAB:
				;FDCB d AB	RES 5,(IY+d),E 23 6
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBAC:
				;FDCB d AC	RES 5,(IY+d),H 23 6
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBAD:
				;FDCB d AD	RES 5,(IY+d),L 23 6
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpFDCBAE:
				;FDCB d AE	RES 5,(IY+d) 23 6
				invoke Inst_RES,reg_di,5
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBAF:
				;FDCB d AF	RES 5,(IY+d),A 23 6
				invoke Inst_RES,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBB0:
				;FDCB d B0	RES 6,(IY+d),B 23 6
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBB1:
				;FDCB d B1	RES 6,(IY+d),C 23 6
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBB2:
				;FDCB d B2	RES 6,(IY+d),D 23 6
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBB3:
				;FDCB d B3	RES 6,(IY+d),E 23 6
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBB4:
				;FDCB d B4	RES 6,(IY+d),H 23 6
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBB5:
				;FDCB d B5	RES 6,(IY+d),L 23 6
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpFDCBB6:
				;FDCB d B6	RES 6,(IY+d) 23 6
				invoke Inst_RES,reg_di,6
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBB7:
				;FDCB d B7	RES 6,(IY+d),A 23 6
				invoke Inst_RES,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBB8:
				;FDCB d B8	RES 7,(IY+d),B 23 6
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBB9:
				;FDCB d B9	RES 7,(IY+d),C 23 6
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBBA:
				;FDCB d BA	RES 7,(IY+d),D 23 6
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBBB:
				;FDCB d BB	RES 7,(IY+d),E 23 6
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBBC:
				;FDCB d BC	RES 7,(IY+d),H 23 6
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBBD:
				;FDCB d BD	RES 7,(IY+d),L 23 6
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpFDCBBE:
				;FDCB d BE	RES 7,(IY+d) 23 6
				invoke Inst_RES,reg_di,7
				invoke CLK_sync,23,6
				jmp Z80Loop
	  OpFDCBBF:
				;FDCB d BF	RES 7,(IY+d),A 23 6
				invoke Inst_RES,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,23,6
				jmp Z80Loop
	  OpFDCBC0:
				;SET  0,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBC1:
				;SET  0,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBC2:
				;SET  0,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBC3:
				;SET  0,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBC4:
				;SET  0,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBC5:
				;SET  0,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBC6:
				;FDCB d C6	SET 0,(IY+d) 23 6
				invoke Inst_Set,reg_di,0
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBC7:
				;SET  0,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,0
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBC8:
				;SET  1,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBC9:
				;SET  1,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBCA:
				;SET  1,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBCB:
				;SET  1,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBCC:
				;SET  1,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBCD:
				;SET  1,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBCE:
				;FDCB d CE	SET 1,(IY+d) 23 6				
				invoke Inst_Set,reg_di,1
				invoke CLK_sync,23,6
				jmp Z80Loop
		OpFDCBCF:
				;SET  1,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,1
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
		OpFDCBD0:
				;SET  2,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
		OpFDCBD1:
				;SET  2,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
		OpFDCBD2:
				;SET  2,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
		OpFDCBD3:
				;SET  2,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
		OpFDCBD4:
				;SET  2,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
		OpFDCBD5:
				;SET  2,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
        OpFDCBD6:
				;FDCB d D6	SET 2,(IY+d) 23 6				
				invoke Inst_Set,reg_di,2
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBD7:
				;SET  2,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,2
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBD8:
				;SET  3,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBD9:
				;SET  3,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBDA:
				;SET  3,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBDB:
				;SET  3,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBDC:
				;SET  3,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBDD:
				;SET  3,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBDE:
				;FDCB d DE	SET 3,(IY+d) 23 6				
				invoke Inst_Set,reg_di,3
				invoke CLK_sync,23,6
				jmp Z80Loop
       OpFDCBDF:
				;SET  3,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,3
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBE0:
				;SET  4,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBE1:
				;SET  4,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBE2:
				;SET  4,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBE3:
				;SET  4,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBE4:
				;SET  4,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBE5:
				;SET  4,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBE6:
				;FDCB d E6	SET 4,(IY+d) 23 6				
				invoke Inst_Set,reg_di,4
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBE7:
				;SET  4,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,4
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBE8:
				;SET  5,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBE9:
				;SET  5,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBEA:
				;SET  5,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBEB:
				;SET  5,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBEC:
				;SET  5,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBED:
				;SET  5,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBEE:
				;FDCB d EE	SET 5,(IY+d) 23 6				
				invoke Inst_Set,reg_di,5
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBEF:
				;SET  5,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,5
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBF0:
				;SET  6,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBF1:
				;SET  6,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBF2:
				;SET  6,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBF3:
				;SET  6,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBF4:
				;SET  6,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBF5:
				;SET  6,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBF6:
				;FDCB d F6	SET 6,(IY+d) 23 6				
				invoke Inst_Set,reg_di,6
				invoke CLK_sync,23,6
				jmp Z80Loop
	   OpFDCBF7:
				;SET  6,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,6
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBF8:
				;SET  7,(IX+nn) &  LD   B,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegB
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBF9:
				;SET  7,(IX+nn) &  LD   C,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegC
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBFA:
				;SET  7,(IX+nn) &  LD   D,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegD
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBFB:
				;SET  7,(IX+nn) &  LD   E,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegE
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBFC:
				;SET  7,(IX+nn) &  LD   H,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegH
				invoke CLK_sync,20,5
				jmp Z80Loop
	   OpFDCBFD:
				;SET  7,(IX+nn) &  LD   L,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegL
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDCBFE:
				;FDCB d FE	SET 7,(IY+d) 23 6				
				invoke Inst_Set,reg_di,7
				invoke CLK_sync,23,6
				jmp Z80Loop 
	   OpFDCBFF:
				;SET  7,(IX+nn) &  LD   A,(IX+nn)
				invoke Inst_Set,reg_di,7
				CopyMemToMem8 reg_di,OFFSET RegA
				invoke CLK_sync,20,5
				jmp Z80Loop
       OpFDE1:
			  ;FDE1		POP IY 14 4
			  invoke Inst_POP,memPtr,OFFSET RegIY
			  invoke CLK_sync,14,4
			  jmp Z80Loop
       OpFDE3:
			  ;FDE3		EX (SP),IY	23 6
			  invoke DIR_REGISTRO_INDIRECTO,memPtr,RegSP
			  invoke Inst_EX8,OFFSET RegIYL,reg_di,
			  mov x_cx,reg_di
			  sub x_cx,memPtr
			  inc cx
			  mov reg_di,memPtr
			  add reg_di,x_cx
              invoke Inst_EX8,OFFSET RegIYH,reg_di
			  invoke CLK_sync,23,6
			  jmp Z80Loop 	
       OpFDE5:
			   ;FDE5		PUSH IY 15 4
			   invoke Inst_PUSH,memPtr,RegIY
			   invoke CLK_sync,15,4
			   jmp Z80Loop
       OpFDE9:
			   ;FDE9		JP (IY) 8 2
			   invoke Inst_JP,memPtr,RegIY
			   invoke CLK_sync,8,2
			   jmp Z80Loop
       OpFDF9:
			  ;FDF9		LD SP,IY 10 2 	
			  invoke Inst_LD16,OFFSET RegIY,OFFSET RegSP
			  invoke CLK_sync,10,2
			  jmp Z80Loop
FinZ80Emu:
		  xor rax,rax
		  ret

Z80CPU ENDP

END
