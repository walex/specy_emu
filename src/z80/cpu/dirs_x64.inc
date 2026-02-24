.code

immediate_addressing_mode PROC 

; parameters 
; memPtr -> x_cx

GET_REG_PC_MEM_PTR
mov reg_di, x_ax
INC_REG_PC
ret
    
immediate_addressing_mode ENDP

immediate_addressing_mode_ext PROC

; parameters 
; memPtr -> x_cx

GET_REG_PC_MEM_PTR
mov reg_di, x_ax
ADD_REG_PC 2
ret

immediate_addressing_mode_ext ENDP

relative_addressing_mode PROC 

; parameters 
; memPtr -> x_cx

GET_REG_PC
add x_cx, x_ax
FETCH8 x_cx
movsx x_dx, al
INC_REG_PC ; PC+1 
ADD_REG_PC dx ;PC + e
ret

relative_addressing_mode ENDP

extended_indirect_addressing_mode PROC 

; parameters 
; memPtr -> x_cx

GET_REG_PC
add x_cx,x_ax
FETCH16 x_cx
mov reg_di, x_ax
ADD_REG_PC 2
ret

extended_indirect_addressing_mode ENDP

indexed_addressing_mode PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; Reg:WORD -> dx

mov reg_di,x_cx
xor reg_si,reg_si
mov si,dx
GET_REG_PC
add x_cx, x_ax
FETCH8 x_cx
movsx x_ax,al
add si,ax
add reg_di,reg_si
INC_REG_PC
ret

indexed_addressing_mode ENDP

register_indirect_addressing_mode PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; Reg:WORD -> dx


xor reg_di,reg_di
mov di,dx
add reg_di,x_cx
ret 

register_indirect_addressing_mode ENDP