.data

ifdef rax
Inst_RST PROTO
else
Inst_RST PROTO memPtr:PTR BYTE , dir:BYTE
endif

.code

trigger_MI PROC

cmp NMI_LINE, 1
jz trigger_MI_exit
mov INT_LINE, 1
trigger_MI_exit:
ret

trigger_MI ENDP

trigger_NMI PROC

mov NMI_LINE, 1
ret

trigger_NMI ENDP

ifdef rax
execute_NMI_interrupt PROC
; parameters
; memPtr:PTR BYTE -> x_cx
else
execute_NMI_interrupt PROC memPtr:PTR BYTE
mov x_cx, memPtr
endif

mov NMI_LINE, 0
invoke Inst_RST, x_cx, 066h
ret

execute_NMI_interrupt ENDP

ifdef rax
execute_MI_interrupt PROC
; parameters
; memPtr:PTR BYTE -> x_cx
else
execute_MI_interrupt PROC memPtr:PTR BYTE
mov x_cx, memPtr
endif

mov INT_LINE, 0
cmp IFF1, 1
jnz execute_MI_interrupt_exit
cmp IMF, 0
jnz execute_MI_interrupt_m1
execute_MI_interrupt_m0:
; TODO invoke execute_MI_interrupt_m0
jmp execute_MI_interrupt_exit
execute_MI_interrupt_m1:
cmp IMF, 1
jnz execute_MI_interrupt_m2
invoke Inst_RST, x_cx, 038h
jmp execute_MI_interrupt_exit
execute_MI_interrupt_m2:
cmp IMF, 2
jnz execute_MI_interrupt_exit
; TODO invoke execute_MI_interrupt_m2
execute_MI_interrupt_exit:
ret

execute_MI_interrupt ENDP

ifdef rax
execute_interrupts PROC
; parameters
; memPtr:PTR BYTE -> x_cx
else
execute_interrupts PROC memPtr:PTR BYTE
mov x_cx, memPtr
endif

execute_interrupts_NMI:
cmp NMI_LINE, 1
jnz execute_interrupts_MI
invoke execute_NMI_interrupt, x_cx
mov HALT, 0
execute_interrupts_MI:
cmp INT_LINE, 1
jnz execute_interrupts_exit
invoke execute_MI_interrupt, x_cx
mov HALT, 0
execute_interrupts_exit:
ret

execute_interrupts ENDP