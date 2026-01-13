.data
      _CPU STRUCT	
	   UNION
			Reg_AF dw 0
			STRUCT
				Reg_F db 0 	
           		Reg_A db 0                         
			ENDS
       ENDS
	 
	   UNION
			Reg_AF_ESP dw 0
			STRUCT
				Reg_F_ESP db 0	
           		Reg_A_ESP db 0                         
			ENDS
       ENDS

	   UNION
		    Reg_BC dw 0
	 	    STRUCT
				Reg_C db 0	
	       		Reg_B db 0	             
		    ENDS
       ENDS
	
	   UNION
		    Reg_BC_ESP dw 0
			STRUCT
				Reg_C_ESP db 0  
	       		Reg_B_ESP db 0	             
			ENDS
       ENDS


       UNION
		    Reg_DE dw 0
		    STRUCT
				Reg_E db 0 	
		        Reg_D db 0	               
			ENDS
       ENDS
         
	   UNION
		    Reg_DE_ESP dw 0
			STRUCT
				Reg_E_ESP db 0	
		        Reg_D_ESP db 0	               
			ENDS
       ENDS

       UNION
	  	    Reg_HL dw 0
			STRUCT
				Reg_L db 0		       	               
			    Reg_H db 0 
			ENDS
       ENDS             
	
       UNION
		    Reg_HL_ESP dw 0
			STRUCT
				Reg_L_ESP db 0 	
		        Reg_H_ESP db 0	               
			ENDS
       ENDS             
	             
	         
	   UNION
		    Reg_IR dw 0
			STRUCT
				Reg_R db 0 	
		        Reg_I db 0	               
			ENDS
       ENDS 
         
	 UNION
	  	Reg_IX dw 0
		STRUCT
			Reg_IXL db 0		       	               
			Reg_IXH db 0 
		ENDS
     ENDS 

	 UNION
	  	Reg_IY dw 0
		STRUCT
			Reg_IYL db 0		       	               
			Reg_IYH db 0 
		ENDS
     ENDS 

	 Reg_SP dw	0 
	
	 IMF		db	0 
	 IFF1		db  0
	 IFF2		db  0	
	 NMI_LINE	db	0
	 INT_LINE	db	0
	 D_LINE		db	0
	 A_LINE		dw  0
	 HALT		db  0

	 ;Reg_Tmp PTR_DATA_TYPE 0
	 ;Reg_Tmp16	dw	0
	 ;Reg_Tmp8	db	0

   _CPU ENDS		

   reg_pc_tmp dw 0

    OF EQU 11	; x86 oferflow flag

	SF EQU 7	;Bit 7 - Sign flag
	ZF EQU 6	;Bit 6 - Zero flag
	YF EQU 5	;Bit 5 - documented as unused (see note)
	HF EQU 4	;Bit 4 - Half-carry flag
	XF EQU 3    ;Bit 3 - documented as unused (see note)
	PVF EQU 2       ;Bit 2 - Parity/Overflow flag
	NF EQU 1	;Bit 1 - Subtract flag
	CF EQU 0	;Bit 0 - Carry flag


   Z80_CPU _CPU <>
	
RegAF EQU [Z80_CPU.Reg_AF]
RegA EQU [Z80_CPU.Reg_A]
RegF EQU [Z80_CPU.Reg_F]

RegBC EQU [Z80_CPU.Reg_BC]
RegB EQU [Z80_CPU.Reg_B]
RegC EQU [Z80_CPU.Reg_C]

RegDE EQU [Z80_CPU.Reg_DE]
RegD EQU [Z80_CPU.Reg_D]
RegE EQU [Z80_CPU.Reg_E]

RegHL EQU [Z80_CPU.Reg_HL]
RegH EQU [Z80_CPU.Reg_H]
RegL EQU [Z80_CPU.Reg_L]

RegAF_ESP EQU [Z80_CPU.Reg_AF_ESP]
RegA_ESP EQU [Z80_CPU.Reg_A_ESP]
RegF_ESP EQU [Z80_CPU.Reg_F_ESP]

RegBC_ESP EQU [Z80_CPU.Reg_BC_ESP]
RegB_ESP EQU [Z80_CPU.Reg_B_ESP]
RegC_ESP EQU [Z80_CPU.Reg_C_ESP]

RegDE_ESP EQU [Z80_CPU.Reg_DE_ESP]
RegD_ESP EQU [Z80_CPU.Reg_D_ESP]
RegE_ESP EQU [Z80_CPU.Reg_E_ESP]

RegHL_ESP EQU [Z80_CPU.Reg_HL_ESP]
RegH_ESP EQU [Z80_CPU.Reg_H_ESP]
RegL_ESP EQU [Z80_CPU.Reg_L_ESP]

RegSP EQU [Z80_CPU.Reg_SP]

RegIY EQU [Z80_CPU.Reg_IY]
RegIX EQU [Z80_CPU.Reg_IX]
RegIXH EQU [Z80_CPU.Reg_IXH]
RegIXL EQU [Z80_CPU.Reg_IXL]
RegIYH EQU [Z80_CPU.Reg_IYH]
RegIYL EQU [Z80_CPU.Reg_IYL]

;RegIY EQU [Z80_CPU.Reg_IY]
;RegIX EQU [Z80_CPU.Reg_IX]

RegIR EQU [Z80_CPU.Reg_IR]
RegI EQU [Z80_CPU.Reg_I]
RegR EQU [Z80_CPU.Reg_R]

IMF EQU [Z80_CPU.IMF]
IFF1 EQU [Z80_CPU.IFF1]
IFF2 EQU [Z80_CPU.IFF2]
NMI_LINE EQU [Z80_CPU.NMI_LINE]
INT_LINE EQU [Z80_CPU.INT_LINE]
D_LINE EQU [Z80_CPU.D_LINE]
A_LINE EQU [Z80_CPU.A_LINE]
HALT EQU [Z80_CPU.HALT]

Reg_Tmp PTR_DATA_TYPE 0
Reg_Tmp16 dw 0
Reg_Tmp8 db	0
Reg_DataBus8 db 0
.code

InitRegisters PROC

.data

.code
; params
; regs values:PTR WORD -> rcx

SetRegValue16 reg_pc_tmp
SetRegValue16 RegSP
SetRegValue8 RegA
SetRegValue8 RegB
SetRegValue8 RegC
SetRegValue8 RegD
SetRegValue8 RegE
SetRegValue8 RegF
SetRegValue8 RegH
SetRegValue8 RegL
SetRegValue8 RegI
SetRegValue8 RegR

; not used ei,wz
SetRegValue16 ax
SetRegValue16 ax

SetRegValue16 RegIX
SetRegValue16 RegIY

SetRegValue16 RegAF_ESP
SetRegValue16 RegBC_ESP
SetRegValue16 RegDE_ESP
SetRegValue16 RegHL_ESP

SetRegValue8 IMF

; not used p,q
SetRegValue8 al
SetRegValue8 al

SetRegValue8 IFF1
SetRegValue8 IFF2

ret

InitRegisters ENDP

GetRegisters PROC

; params
; regs values:PTR WORD -> rcx

GetRegValue16 reg_pc_tmp
GetRegValue16 RegSP
GetRegValue8 RegA
GetRegValue8 RegB
GetRegValue8 RegC
GetRegValue8 RegD
GetRegValue8 RegE
GetRegValue8 RegF
GetRegValue8 RegH
GetRegValue8 RegL
GetRegValue8 RegI
GetRegValue8 RegR

; not used ei,wz
GetRegValue16 ax
GetRegValue16 ax

GetRegValue16 RegIX
GetRegValue16 RegIY

GetRegValue16 RegAF_ESP
GetRegValue16 RegBC_ESP
GetRegValue16 RegDE_ESP
GetRegValue16 RegHL_ESP

GetRegValue8 IMF

; not used p,q
GetRegValue8 al
GetRegValue8 al

GetRegValue8 IFF1
GetRegValue8 IFF2

ret

GetRegisters ENDP

GetRegPC PROC
	; params
	; regs memPtr:PTR WORD -> rcx
	; regs value:PTR WORD -> rdx
	mov rax, reg_pc
	sub ax, cx
	mov WORD PTR [rdx], ax
	ret
GetRegPC ENDP

SetRegPC PROC
	mov r10, rcx
	ret
SetRegPC ENDP

SetRegSP PROC
	mov RegSP, cx
	ret
SetRegSP ENDP

SetRegA PROC
	mov RegA, cl
	ret
SetRegA ENDP

SetRegB PROC
	mov RegB, cl
	ret
SetRegB ENDP

SetRegC PROC
	mov RegC, cl
	ret
SetRegC ENDP

SetRegD PROC
	mov RegD, cl
	ret
SetRegD ENDP

SetRegE PROC
	mov RegE, cl
	ret
SetRegE ENDP

SetRegF PROC
	mov RegF, cl
	ret
SetRegF ENDP

SetRegH PROC
	mov RegH, cl
	ret
SetRegH ENDP

SetRegL PROC
	mov RegL, cl
	ret
SetRegL ENDP

SetRegI PROC
	mov RegI, cl
	ret
SetRegI ENDP

SetRegR PROC
	mov RegR, cl
	ret
SetRegR ENDP

SetRegIX PROC
	mov RegIX, cx
	ret
SetRegIX ENDP

SetRegIY PROC
	mov RegIY, cx
	ret
SetRegIY ENDP