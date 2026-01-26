.data

.code

LD_SetFlagIR PROC

; parameters
; Reg -> x_cx

ResetFlagBits HF, NF, PVF, XF, YF
mov cl, [x_cx]
test cl,cl
X86FlagsToZ80Flags SF, ZF
and cl, 028h
mov al, IFF2
shl al, PVF
or RegF, al
or RegF, cl
ret

LD_SetFlagIR ENDP

SetLDxRInterblockYFXF PROC

;YF = PC.13
;XF = PC.11

ResetFlagBits YF, XF
GET_REG_PC
shr x_ax, 8
and al, 028h
or RegF, al
ret

SetLDxRInterblockYFXF ENDP