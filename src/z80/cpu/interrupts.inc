.data

IFF_DELAY db 0

.code

inst_RST PROTO
inst_PUSH PROTO

.data

inst_RST PROTO
inst_PUSH PROTO

.code

interrupts_enable_request PROC
mov IFF_DELAY, 1
ret
interrupts_enable_request ENDP

interrupts_enable PROC

	mov IFF1, 1
	mov IFF2, 1
	ret

interrupts_enable ENDP

interrupts_disable PROC

	mov IFF1, 0
	mov IFF2, 0
	ret

interrupts_disable ENDP

interrupts_restore PROC

	mov al, IFF2
	mov IFF1, al
	ret

interrupts_restore ENDP

interrupts_execute_mi_0 PROC

lea rcx, data_bus_8 ; what happens with a multibly instruction ?
ProcessNextOpcode _TOp1B, rcx
ret

interrupts_execute_mi_0 ENDP

interrupts_execute_mi_1 PROC

; parameters
; memPtr:PTR BYTE -> x_cx

invoke inst_RST,x_cx, 038h
ret

interrupts_execute_mi_1 ENDP

interrupts_execute_mi_2 PROC

; parameters
; memPtr:PTR BYTE -> x_cx

; addr = (I << 8) | vector & 0xFE
xor x_ax, x_ax
mov ah, RegI
mov al, data_bus_8
and al, 0FEh
add x_ax, x_cx

;[memptr] = LOW
;[memptr+1] = HIGH
xor x_bx, x_bx
mov bx, WORD PTR [x_ax]
mov reg_pc, x_cx
add reg_pc, x_bx

; push pc
mov x_bx, reg_pc
sub x_bx, x_cx
invoke inst_PUSH,x_cx,bx

ret

interrupts_execute_mi_2 ENDP

interrupts_accept_nmi PROC

; parameter
; x_cx -> memPtr

IncRegR

mov NMI_LINE, 0

; backup and disable mi
mov IFF1, 0

; push pc
mov x_bx, reg_pc
sub x_bx, x_cx
invoke inst_PUSH,x_cx,bx

invoke inst_RST, x_cx, 066h

ret

interrupts_accept_nmi ENDP

interrupts_accept_mi PROC

; parameter
; x_cx -> memPtr

IncRegR

mov INT_LINE, 0
cmp IFF1, 1
jnz execute_MI_interrupt_exit

mov IFF1, 0
mov IFF2, 0

cmp IMF, 0
jz execute_MI_interrupt_m0
cmp IMF, 1
jz execute_MI_interrupt_m1
cmp IMF, 2
jz execute_MI_interrupt_m2
jmp execute_MI_interrupt_exit

execute_MI_interrupt_m0:

invoke interrupts_execute_mi_0, x_cx
jmp execute_MI_interrupt_exit

execute_MI_interrupt_m1:
invoke interrupts_execute_mi_1, x_cx
jmp execute_MI_interrupt_exit

execute_MI_interrupt_m2:
invoke interrupts_execute_mi_2, x_cx

execute_MI_interrupt_exit:
ret

interrupts_accept_mi ENDP

interrupts_accept PROC

; parameter
; x_cx -> memPtr

interrupts_accepts_start:
cmp NMI_LINE, 1
jnz check_IFF_DELAY
execute_interrupts_NMI:
invoke interrupts_accept_nmi, x_cx
jmp execute_interrupts_exit

check_IFF_DELAY:

cmp IFF_DELAY, 0
jz execute_interrupts_MI
mov IFF_DELAY, 0
invoke interrupts_enable
jmp execute_interrupts_exit

execute_interrupts_MI:
cmp INT_LINE, 1
jnz execute_interrupts_exit
invoke interrupts_accept_mi, x_cx
execute_interrupts_exit:
ret

interrupts_accept ENDP


interrupts_request_nmi PROC
	
  mov HALT, 0
  mov NMI_LINE, 1
  ret

interrupts_request_nmi ENDP

interrupts_request_mi PROC
	
  mov HALT, 0

  cmp NMI_LINE, 1
  jz interrupts_request_mi_exit
  cmp INT_LINE, 1
  jz interrupts_request_mi_exit
  mov INT_LINE, 1
  interrupts_request_mi_exit:
  ret

interrupts_request_mi ENDP



interrupts_set_im PROC

  ; parameters
  ; mode:BYTE -> cl

  mov IMF, cl
  ret

interrupts_set_im ENDP

