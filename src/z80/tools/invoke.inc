ifdef rax

ifndef INVOKE_INC
	INVOKE_INC = 1

	MOVARG2REG macro pos, isdup, arg, qreg, dreg, wreg, breg
		strpos textequ %pos
		if (opattr(arg)) eq 0
	%		.err <The type of argument strpos is not supported>
			exitm
		endif
		if type arg gt 8
	%		.err <The size of argument strpos must not be greater than 8 bytes>
			exitm
		endif
		if ((opattr(arg)) and 00010000b) or ((opattr(arg)) and 00000010b)	;register or memory location
			if type arg eq 8
				ifdifi <arg>, <qreg>
					if type arg eq type real8
						strpos2 textequ %(pos - 1)
						xmmreg catstr <xmm>, strpos2
						movsd xmmreg, arg
						if isdup ne 0
							movq qreg, xmmreg
						endif
					else
						mov qreg, arg
					endif
				endif
			elseif type arg eq 4
				ifdifi <arg>, <dreg>
					if type arg eq type real4
						strpos2 textequ %(pos - 1)
						xmmreg catstr <xmm>, strpos2
						movss xmmreg, arg
						if isdup ne 0
							movd dreg, xmmreg
						endif
					else
						mov dreg, arg
					endif
				endif
			elseif type arg eq 2
				ifdifi <arg>, <wreg>
					mov wreg, arg
				endif
			elseif type arg eq 1
				ifdifi <arg>, <breg>
					mov breg, arg
				endif
			else
	%			.err <The size of argument strpos must be 1, 2, 4 or 8 bytes>
				exitm
			endif
		elseif (opattr(arg)) and 00000100b	;immediate value
			mov qreg, arg
		else
	%		.err <The type of argument strpos is unknown>
			exitm
		endif
	endm

	MOVARG2STK macro pos, arg, offset1
		strpos textequ %pos
		if (opattr(arg)) eq 0
	%		.err <The type of argument strpos is not supported>
			exitm
		endif
		if type arg gt 8
	%		.err <The size of argument strpos must not be greater than 8 bytes>
			exitm
		endif
		if offset1 mod 8 ne 0
	%		.err <Offset of argument strpos must be a multiple of 8>
			exitm
		endif
		offset2 = offset1 + 32
		if (opattr(arg)) and 00010000b	;register
			if type arg eq 8
				mov qword ptr [rsp+offset2], arg
			elseif type arg eq 4
				mov dword ptr [rsp+offset2], arg
			elseif type arg eq 2
				mov word ptr [rsp+offset2], arg
			elseif type arg eq 1
				mov byte ptr [rsp+offset2], arg
			else
	%			.err <The size of argument strpos must be 1, 2, 4 or 8 bytes>
				exitm
			endif
		elseif (opattr(arg)) and 00000010b	;memory location
			if type arg eq 8
				mov rax, arg
				mov [rsp+offset2], rax
			elseif type arg eq 4
				mov eax, arg
				mov [rsp+offset2], eax
			elseif (type arg eq 2) or (type arg eq 1)
				movzx eax, arg
				mov [rsp+offset2], eax
			else
	%			.err <The size of argument strpos must be 1, 2, 4 or 8 bytes>
				exitm
			endif
		elseif (opattr(arg)) and 00000100b	;immediate value
			if (arg ge -2147483648) and (arg le 2147483647)
				mov dword ptr [rsp+offset2], arg
			else
				mov rax, arg
				mov [rsp+offset2], rax
			endif
		else
	%		.err <The type of argument strpos is unknown>
			exitm
		endif
	endm

	PUSHARG macro pos, arg
		strpos textequ %pos
		if (opattr(arg)) eq 0
	%		.err <The type of argument strpos is not supported>
			exitm
		endif
		if type arg gt 8
	%		.err <The size of argument strpos must not be greater than 8 bytes>
			exitm
		endif
		if (opattr(arg)) and 00010000b	;register
			if type arg eq 8
				push arg
			elseif type arg eq 4
				mov eax, arg
				push rax
			elseif (type arg eq 2) or (type arg eq 1)
				movzx eax, arg
				push rax
			else
	%			.err <The size of argument strpos must be 1, 2, 4 or 8 bytes>
				exitm
			endif
		elseif (opattr(arg)) and 00000010b	;memory location
			if type arg eq 8
				mov rax, arg
				push rax
			elseif type arg eq 4
				mov eax, arg
				push rax
			elseif (type arg eq 2) or (type arg eq 1)
				movzx eax, arg
				push rax
			else
	%			.err <The size of argument strpos must be 1, 2, 4 or 8 bytes>
				exitm
			endif
		elseif (opattr(arg)) and 00000100b	;immediate value
			if (arg ge -2147483648) and (arg le 2147483647)
				push arg
			else
				mov rax, arg
				push rax
			endif
		else
	%		.err <The type of argument strpos is unknown>
			exitm
		endif
	endm

	REVARGS macro args:vararg
		revargs1 equ <>
		for arg, <args>
			local tmpvarargs, tmpnewvarargs
			tmpvarargs textequ revargs1
			tmpnewvarargs textequ @CatStr(arg, <,>, &tmpvarargs)
			revargs1 equ tmpnewvarargs
		endm
		length1 sizestr revargs1
		length1 = length1 - 1
		revargs2 substr revargs1, 1, length1
		revargs3 catstr <!<>, revargs2, <!>>
		exitm revargs3
	endm

	INVOKE macro func:req, arg1, arg2, arg3, arg4, args:vararg
		if ((opattr(func)) and 00000001b) eq 0	;code label
			.err <The first argument must be a code label>
			exitm
		endif
		ifnb <arg1>
			MOVARG2REG 1, 0, arg1, rcx, ecx, cx, cl
		endif
		ifnb <arg2>
			MOVARG2REG 2, 0, arg2, rdx, edx, dx, dl
		endif
		ifnb <arg3>
			MOVARG2REG 3, 0, arg3, r8, r8d, r8w, r8b
		endif
		ifnb <arg4>
			MOVARG2REG 4, 0, arg4, r9, r9d, r9w, r9b
		endif
		ifnb <args>
			counter = 0
			for arg, <args>
				MOVARG2STK counter + 5, arg, counter * 8
				counter = counter + 1
			endm
		endif
		call func
	endm

	INVOKED macro func:req, arg1, arg2, arg3, arg4, args:vararg
		if ((opattr(func)) and 00000001b) eq 0	;code label
			.err <The first argument must be a code label>
			exitm
		endif
		ifnb <arg1>
			MOVARG2REG 1, 1, arg1, rcx, ecx, cx, cl
		endif
		ifnb <arg2>
			MOVARG2REG 2, 1, arg2, rdx, edx, dx, dl
		endif
		ifnb <arg3>
			MOVARG2REG 3, 1, arg3, r8, r8d, r8w, r8b
		endif
		ifnb <arg4>
			MOVARG2REG 4, 1, arg4, r9, r9d, r9w, r9b
		endif
		ifnb <args>
			counter = 0
			for arg, <args>
				MOVARG2STK counter + 5, arg, counter * 8
				counter = counter + 1
			endm
		endif
		call func
	endm

	INVOKEB macro func:req, arg1, arg2, arg3, arg4, args:vararg
		if ((opattr(func)) and 00000001b) eq 0	;code label
			.err <The first argument must be a code label>
			exitm
		endif
		ifnb <arg1>
			MOVARG2REG 1, 0, arg1, rcx, ecx, cx, cl
		endif
		ifnb <arg2>
			MOVARG2REG 2, 0, arg2, rdx, edx, dx, dl
		endif
		ifnb <arg3>
			MOVARG2REG 3, 0, arg3, r8, r8d, r8w, r8b
		endif
		ifnb <arg4>
			MOVARG2REG 4, 0, arg4, r9, r9d, r9w, r9b
		endif
		ifnb <args>
			rargs equ REVARGS(args)
			nargs = 0
			counter = 0
			for arg, <args>
				nargs = nargs + 1
			endm
			if nargs mod 2
				push rax
			endif
	%		for arg, rargs
				PUSHARG counter + 5, arg
				counter = counter + 1
			endm
			sub rsp, 32
			call func
			if nargs mod 2
				add rsp, 40 + counter * 8
			else
				add rsp, 32 + counter * 8
			endif
		else
			sub rsp, 32
			call func
			add rsp, 32
		endif
	endm

	INVOKEBD macro func:req, arg1, arg2, arg3, arg4, args:vararg
		if ((opattr(func)) and 00000001b) eq 0	;code label
			.err <The first argument must be a code label>
			exitm
		endif
		ifnb <arg1>
			MOVARG2REG 1, 1, arg1, rcx, ecx, cx, cl
		endif
		ifnb <arg2>
			MOVARG2REG 2, 1, arg2, rdx, edx, dx, dl
		endif
		ifnb <arg3>
			MOVARG2REG 3, 1, arg3, r8, r8d, r8w, r8b
		endif
		ifnb <arg4>
			MOVARG2REG 4, 1, arg4, r9, r9d, r9w, r9b
		endif
		ifnb <args>
			rargs equ REVARGS(args)
			nargs = 0
			counter = 0
			for arg, <args>
				nargs = nargs + 1
			endm
			if nargs mod 2
				push rax
			endif
	%		for arg, rargs
				PUSHARG counter + 5, arg
				counter = counter + 1
			endm
			sub rsp, 32
			call func
			if nargs mod 2
				add rsp, 40 + counter * 8
			else
				add rsp, 32 + counter * 8
			endif
		else
			sub rsp, 32
			call func
			add rsp, 32
		endif
	endm
endif

endif
