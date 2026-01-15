.data

inst_RST PROTO
.code

trigger_MI PROC
; parameters will depend of interrupt mode
; mode 0
; opcode:BYTE -> x_cx
; mode 1
; not used
; mode 2
; interrupt vector low addr:PTR BYTE -> x_cx
; PC = (I*256)+addr
cmp NMI_LINE, 1
jz trigger_MI_exit
cmp INT_LINE, 1
jz trigger_MI_exit
mov INT_LINE, 1
mov data_bus_8, cl
trigger_MI_exit:
ret

trigger_MI ENDP

trigger_NMI PROC

cmp NMI_LINE, 1
jz trigger_NMI_exit

cmp INT_LINE, 1
jnz trigger_NMI_run
supend_MI_interrupt:

trigger_NMI_run:
mov NMI_LINE, 1
trigger_NMI_exit:
ret

trigger_NMI ENDP

ExecuteNMIInterrupt MACRO memPtr

mov HALT, 0
mov al, IFF1
mov IFF2, al
mov IFF1, 0
invoke inst_RST, memPtr, 066h

ENDM

ExecuteMIInterrupt MACRO memPtr

mov INT_LINE, 0
cmp IFF1, 1
jnz execute_MI_interrupt_exit
cmp IMF, 0
jz execute_MI_interrupt_m0
cmp IMF, 1
jz execute_MI_interrupt_m1
cmp IMF, 2
jz execute_MI_interrupt_m2
jmp execute_MI_interrupt_exit

execute_MI_interrupt_m0:
mov HALT, 0
xor al,al
mov IFF1,al
mov IFF2,al
lea rax, [data_bus_8] ; what happens with a multibly instruction
ProcessNextOpcode _TOp1B, rax
jmp execute_MI_interrupt_exit

execute_MI_interrupt_m1:
mov HALT, 0
xor al,al
mov IFF1,al
mov IFF2,al
invoke inst_RST, memPtr, 038h
jmp execute_MI_interrupt_exit

execute_MI_interrupt_m2:
mov HALT, 0
; save pc
invoke inst_RST, memPtr, 0
push memPtr
xor al,al
mov IFF1,al
mov IFF2,al
mov ah, RegI
mov al, data_bus_8
add memPtr, x_ax
mov ax, WORD PTR [memPtr]
pop memPtr
add memPtr, x_ax
mov reg_pc, memPtr

execute_MI_interrupt_exit:

ENDM

ExecuteInterrupts MACRO memPtr

cmp NMI_LINE, 1
jnz execute_interrupts_MI
execute_interrupts_NMI:
ExecuteNMIInterrupt memPtr
jmp execute_interrupts_exit
execute_interrupts_MI:
cmp INT_LINE, 1
jnz execute_interrupts_exit
ExecuteMIInterrupt memPtr
execute_interrupts_exit:

ENDM