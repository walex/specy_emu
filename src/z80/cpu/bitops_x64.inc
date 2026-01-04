.data

EXTERNDEF clk_master_sync:PROC
EXTERNDEF clk_master_reset:PROC

.code

CLK_reset PROC

push reg_pc
push reg_si
push x_bp
push x_cx
push x_dx
invoke clk_master_reset
pop x_dx
pop x_cx
pop x_bp
pop reg_si
pop reg_pc
ret

CLK_reset ENDP

CLK_sync PROC

push reg_pc
push reg_si
push x_bp
push x_cx
push x_dx
invoke clk_master_sync, cx, dl
pop x_dx
pop x_cx
pop x_bp
pop reg_si
pop reg_pc
ret

CLK_sync ENDP

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