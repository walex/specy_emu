.code

DIR_INMEDIATO PROC 

; parameters 
; memPtr -> x_cx

xor x_ax,x_ax
mov al,[reg_pc]                
mov Reg_Tmp,x_ax
mov reg_di, OFFSET Reg_Tmp
INC_REG_PC x_cx
ret
    
DIR_INMEDIATO ENDP

DIR_INMEDIATO_EXT PROC

; parameters 
; memPtr -> x_cx

xor x_ax, x_ax
xor x_bx, x_bx
mov al, [reg_pc]
INC_REG_PC x_cx
mov bl, [reg_pc]
INC_REG_PC x_cx
shl bx, 8
or ax, bx
mov Reg_Tmp, x_ax
mov reg_di, OFFSET Reg_Tmp
ret

DIR_INMEDIATO_EXT ENDP

DIR_RELATIVO PROC 

; parameters 
; memPtr -> x_cx

xor x_bx,x_bx
movsx x_bx, BYTE PTR [reg_pc] ;e
INC_REG_PC x_cx ; PC+1 
ADD_REG_PC x_cx, bx ;PC + e
ret

DIR_RELATIVO ENDP

DIR_EXT PROC 

; parameters 
; memPtr -> x_cx

xor x_ax, x_ax
mov ax, [reg_pc]
INC_REG_PC x_cx
mov bx, [reg_pc]
INC_REG_PC x_cx
shl bx, 8
or ax, bx
mov reg_di, x_ax

ret

DIR_EXT ENDP

DIR_INDEXADO PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; Reg:WORD -> dx

xor reg_si,reg_si
mov si,dx
movsx x_ax,BYTE PTR [reg_pc]
add si,ax
mov reg_di,x_cx
add reg_di,reg_si
INC_REG_PC x_cx
ret

DIR_INDEXADO ENDP

DIR_REGISTRO_INDIRECTO PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; Reg:WORD -> dx

xor reg_si,reg_si
mov si,dx
mov reg_di,x_cx
add reg_di,reg_si 
ret 

DIR_REGISTRO_INDIRECTO ENDP

DCB_REGISTER_FROM_MASK PROC

; parameters
; value:BYTE -> cl

and cl, 07h
cmp cl , 00h
jz mask_RegB
cmp cl , 01h
jz mask_RegC
cmp cl , 02h
jz mask_RegD
cmp cl , 03h
jz mask_RegE
cmp cl , 04h
jz mask_RegH
cmp cl , 05h
jz mask_RegL
; 06h     (none: documented opcode)
cmp cl , 07h
jz mask_RegA
xor x_ax, x_ax
jmp mask_exit

mask_RegB:
mov x_ax, OFFSET RegB
jmp mask_exit

mask_RegC:
mov x_ax, OFFSET RegC
jmp mask_exit

mask_RegD:
mov x_ax, OFFSET RegD
jmp mask_exit

mask_RegE:
mov x_ax, OFFSET RegE
jmp mask_exit

mask_RegH:
mov x_ax, OFFSET RegH
jmp mask_exit

mask_RegL:
mov x_ax, OFFSET RegL
jmp mask_exit

mask_RegA:
mov x_ax, OFFSET RegA

mask_exit:
ret

DCB_REGISTER_FROM_MASK ENDP