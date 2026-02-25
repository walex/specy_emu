.data

.code

LD_SetFlagIR PROC

; parameters
; Reg -> x_cx

ResetFlagBits HF, NF, PVF, XF, YF
mov x_c8l, [x_cx]
test x_c8l,x_c8l
X86FlagsToZ80Flags SF, ZF
and x_c8l, 028h
mov x_a8l, IFF2
shl x_a8l, PVF
or RegF, x_a8l
or RegF, x_c8l
ret

LD_SetFlagIR ENDP

SetLDxRInterblockYFXF PROC

;YF = PC.13
;XF = PC.11

ResetFlagBits YF, XF
GET_REG_PC
shr x_ax, 8
and x_a8l, 028h
or RegF, x_a8l
ret

SetLDxRInterblockYFXF ENDP