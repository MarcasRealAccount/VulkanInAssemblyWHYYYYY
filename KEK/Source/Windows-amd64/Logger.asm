%include "Common.asminc"

%if BUILD_IS_SYSTEM_WINDOWS && BUILD_IS_PLATFORM_AMD64
%include "Windows-amd64/LibC.asminc"
%include "Windows-amd64/Logger.asminc"

section .rdata
	LoggerFormat:     db 33o, "[38;2;%sm[%s] %s: %s", 33o, "[39m", 10, 0
	LoggerInfoStr:    db "Info", 0
	LoggerInfoColor:  db "255;255;255", 0
	LoggerDebugStr:   db "Debug", 0
	LoggerDebugColor: db "127;255;255", 0
	LoggerWarnStr:    db "Warn", 0
	LoggerWarnColor:  db "255;127;0", 0
	LoggerErrorStr:   db "Error", 0
	LoggerErrorColor: db "255;30;30", 0

section .text
	StaticLabel LoggerGetLevelStr ; ecx => level
		cmp ecx, 4
		jg .Error
		lea rax, [.jumpTable]
		jmp [rax + rcx * 8]
		.Info:
			lea rax, [LoggerInfoStr]
			ret
		.Debug:
			lea rax, [LoggerDebugStr]
			ret
		.Warn:
			lea rax, [LoggerWarnStr]
			ret
		.Error:
			lea rax, [LoggerErrorStr]
			ret
		.jumpTable:
			dq .Info  ; 00
			dq .Debug ; 08
			dq .Warn  ; 10
			dq .Error ; 18
			
	StaticLabel LoggerGetLevelColor ; ecx => level
		lea rax, [.jumpTable]
		jmp [rax + rcx * 8]
		.Info:
			lea rax, [LoggerInfoColor]
			ret
		.Debug:
			lea rax, [LoggerDebugColor]
			ret
		.Warn:
			lea rax, [LoggerWarnColor]
			ret
		.Error:
			lea rax, [LoggerErrorColor]
			ret
		.jumpTable:
			dq .Info  ; 00
			dq .Debug ; 08
			dq .Warn  ; 10
			dq .Error ; 18

	GlobalLabel LoggerAlloc
		mov rcx, Logger_size
		jmp malloc

	GlobalLabel LoggerFree ; rcx => logger
		jmp free

	GlobalLabel LoggerCtor ; rcx => logger, rdx => name
		mov [rcx + Logger.name], rdx
		ret

	GlobalLabel LoggerDtor ; rcx => logger
		ret

	GlobalLabel LoggerLog ; rcx => logger, edx => level, r8 => format, r9 => va_list
		mov [rsp + 8h], rcx
		mov [rsp + 10h], edx
		mov [rsp + 18h], r8
		mov [rsp + 20h], r9
		sub rsp, 38h

		xor rcx, rcx
		xor rdx, rdx
		call vsnprintf
		mov [rsp + 30h], rax
		inc rax
		mov [rsp + 28h], rax

		mov rcx, [rsp + 28h]
		call malloc
		mov [rsp + 20h], rax

		mov rcx, [rsp + 30h]
		mov byte[rax + rcx], 0

		mov rcx, rax
		mov edx, [rsp + 28h]
		mov r8, [rsp + 38h + 18h]
		mov r9, [rsp + 38h + 20h]
		call vsnprintf

		mov ecx, [rsp + 38h + 10h]
		call LoggerGetLevelStr
		mov [rsp + 28h], rax

		mov ecx, [rsp + 38h + 10h]
		call LoggerGetLevelColor
		mov [rsp + 30h], rax

		lea rcx, [LoggerFormat]
		mov rdx, [rsp + 30h]
		mov r8, [rsp + 38h + 8h]
		mov r8, [r8 + Logger.name]
		mov r9, [rsp + 28h]
		call printf

		mov rcx, [rsp + 20h]
		call free

		add rsp, 38h
		ret

	GlobalLabel LoggerLogInfo ; rcx => logger, rdx => format, ...
		mov [rsp + 10h], rdx
		mov [rsp + 18h], r8
		mov [rsp + 20h], r9
		sub rsp, 28h
		
		mov r8, rdx
		xor edx, edx
		lea r9, [rsp + 40h]
		call LoggerLog

		add rsp, 28h
		ret

	GlobalLabel LoggerLogDebug ; rcx => logger, rdx => format, ...
		mov [rsp + 10h], rdx
		mov [rsp + 18h], r8
		mov [rsp + 20h], r9
		sub rsp, 28h
		
		mov r8, rdx
		mov edx, 1
		lea r9, [rsp + 40h]
		call LoggerLog

		add rsp, 28h
		ret

	GlobalLabel LoggerLogWarn ; rcx => logger, rdx => format, ...
		mov [rsp + 10h], rdx
		mov [rsp + 18h], r8
		mov [rsp + 20h], r9
		sub rsp, 28h
		
		mov r8, rdx
		mov edx, 2
		lea r9, [rsp + 40h]
		call LoggerLog

		add rsp, 28h
		ret

	GlobalLabel LoggerLogError ; rcx => logger, rdx => format, ...
		mov [rsp + 10h], rdx
		mov [rsp + 18h], r8
		mov [rsp + 20h], r9
		sub rsp, 28h
		
		mov r8, rdx
		mov edx, 3
		lea r9, [rsp + 40h]
		call LoggerLog

		add rsp, 28h
		ret

%endif