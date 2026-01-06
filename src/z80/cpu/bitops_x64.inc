.data

.code

LD_SetFlagIR PROC

; parameters
; Reg -> x_cx

mov cl, [x_cx]
test cl,cl
X86FlagsToZ80Flags SF, ZF
ResetFlagBits HF, NF, PVF
mov al, IFF2
shl al, PVF
or RegF, al
ret

LD_SetFlagIR ENDP