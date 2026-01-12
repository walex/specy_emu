.code

immediate_addressing_mode PROC 

; parameters 
; memPtr -> x_cx

xor x_ax,x_ax
mov al,[reg_pc]                
mov Reg_Tmp,x_ax
mov reg_di, OFFSET Reg_Tmp
inc reg_pc
ret
    
immediate_addressing_mode ENDP

immediate_addressing_mode_ext PROC

; parameters 
; memPtr -> x_cx

xor x_ax, x_ax
xor x_bx, x_bx
mov al, [reg_pc]
inc reg_pc
mov bl, [reg_pc]
inc reg_pc
shl bx, 8
or ax, bx
mov Reg_Tmp, x_ax
mov reg_di, OFFSET Reg_Tmp
ret

immediate_addressing_mode_ext ENDP

relative_addressing_mode PROC 

; parameters 
; memPtr -> x_cx

xor x_bx,x_bx
movsx x_bx, BYTE PTR [reg_pc] ;e
inc reg_pc ; PC+1 
add reg_pc, x_bx ;PC + e
ret

relative_addressing_mode ENDP

extended_indirect_addressing_mode PROC 

; parameters 
; memPtr -> x_cx

xor x_ax, x_ax
mov ax, [reg_pc]
inc reg_pc
mov bx, [reg_pc]
inc reg_pc
shl bx, 8
or ax, bx
mov reg_di, x_ax

ret

extended_indirect_addressing_mode ENDP

indexed_addressing_mode PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; Reg:WORD -> dx

xor reg_si,reg_si
mov si,dx
movsx x_ax,BYTE PTR [reg_pc]
add si,ax
mov reg_di,x_cx
add reg_di,reg_si
inc reg_pc
ret

indexed_addressing_mode ENDP

register_indirect_addressing_mode PROC

; parameters
; memPtr:PTR BYTE -> x_cx
; Reg:WORD -> dx

xor reg_si,reg_si
mov si,dx
mov reg_di,x_cx
add reg_di,reg_si 
ret 

register_indirect_addressing_mode ENDP