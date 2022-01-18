%include "Common.asminc"

%if BUILD_IS_SYSTEM_MACOSX && BUILD_IS_PLATFORM_AMD64
%include "Macosx-amd64/LibC.asminc"
%include "Macosx-amd64/Logger.asminc"

section .rodata
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
    StaticLabel LoggerGetLevelStr ; edi => level
        cmp edi, 4
        mov esi, 3
        cmovge edi, esi
        lea rsi, [.jumpTable]
        mov rax, [rsi + rdi * 8]
        add rax, rsi
        jmp rax
        .jumpTable:
            dq .Info - .jumpTable  ; 00
            dq .Debug - .jumpTable ; 00
            dq .Warn - .jumpTable  ; 00
            dq .Error - .jumpTable ; 00
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

    StaticLabel LoggerGetLevelColor ; edi => level
        cmp edi, 4
        mov esi, 3
        cmovge edi, esi
        lea rsi, [.jumpTable]
        mov rax, [rsi + rdi * 8]
        add rax, rsi
        jmp rax
        .jumpTable:
            dq .Info - .jumpTable  ; 00
            dq .Debug - .jumpTable ; 00
            dq .Warn - .jumpTable  ; 00
            dq .Error - .jumpTable ; 00
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

    GlobalLabel _LoggerAlloc
        mov rdi, Logger_size
        jmp _malloc

    GlobalLabel _LoggerFree ; rdi => logger
        jmp _free

    GlobalLabel _LoggerCtor ; rdi => logger, rsi => name
        mov [rdi + Logger.name], rsi
        ret

    GlobalLabel _LoggerDtor ; rdi => logger
        ret

    GlobalLabel _LoggerLog ; rdi => logger, esi => level, rdx => format, rcx => va_list
        push rbp
        push rbx
        push r12
        push r13
        push r14
        push r15
        mov rbp, rsp
        sub rsp, 28h

        mov r13, rdx
        mov r14, rsi
        mov r15, rdi

        mov rax, [rcx + 10h]
        mov [rsp + 10h], rax
        movaps xmm0, [rcx]
        movaps [rsp], xmm0

        xor rdi, rdi
        xor rsi, rsi
        call _vsnprintf
        add rax, 1
        mov r12, rax
        mov rdi, rax
        call _malloc
        mov rbx, rax

        mov rdi, rax
        mov rsi, r12
        mov rdx, r13
        mov rcx, rsp
        call _vsnprintf

        mov rdi, r14
        call LoggerGetLevelStr
        mov r12, rax
        mov rdi, r14
        call LoggerGetLevelColor

        lea rdi, [LoggerFormat]
        mov rsi, rax
        mov rdx, r15
        mov rdx, [rdx + Logger.name]
        mov rcx, r12
        mov r8, rbx
        xor rax, rax
        call _printf

        mov rdi, rbx
        call _free

        mov rsp, rbp
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        pop rbp
        ret

    GlobalLabel _LoggerLogInfo ; rdi => logger, rsi => format, ...
        sub rsp, 0D8h
        mov r10, rsi
        mov [rsp + 30h], rdx
        mov [rsp + 38h], rcx
        mov [rsp + 40h], r8
        mov [rsp + 48h], r9
        test al, al
        je .skip
        movaps [rsp + 50h], xmm0
        movaps [rsp + 60h], xmm1
        movaps [rsp + 70h], xmm2
        movaps [rsp + 80h], xmm3
        movaps [rsp + 90h], xmm4
        movaps [rsp + 0A0h], xmm5
        movaps [rsp + 0B0h], xmm6
        movaps [rsp + 0C0h], xmm7
        .skip:
        lea rax, [rsp + 20h]
        mov [rsp + 10h], rax
        lea rax, [rsp + 0E0h]
        mov [rsp + 8h], rax
        mov rax, 3000000010h
        mov [rsp], rax
        mov rcx, rsp

        mov rdx, r10
        mov rsi, 0

        call _LoggerLog
        add rsp, 0D8h
        ret

    GlobalLabel _LoggerLogDebug ; rdi => logger, rsi => format, ...
        sub rsp, 0D8h
        mov r10, rsi
        mov [rsp + 30h], rdx
        mov [rsp + 38h], rcx
        mov [rsp + 40h], r8
        mov [rsp + 48h], r9
        test al, al
        je .skip
        movaps [rsp + 50h], xmm0
        movaps [rsp + 60h], xmm1
        movaps [rsp + 70h], xmm2
        movaps [rsp + 80h], xmm3
        movaps [rsp + 90h], xmm4
        movaps [rsp + 0A0h], xmm5
        movaps [rsp + 0B0h], xmm6
        movaps [rsp + 0C0h], xmm7
        .skip:
        lea rax, [rsp + 20h]
        mov [rsp + 10h], rax
        lea rax, [rsp + 0E0h]
        mov [rsp + 8h], rax
        mov rax, 3000000010h
        mov [rsp], rax
        mov rcx, rsp

        mov rdx, r10
        mov rsi, 1

        call _LoggerLog
        add rsp, 0D8h
        ret

    GlobalLabel _LoggerLogWarn ; rdi => logger, rsi => format, ...
        sub rsp, 0D8h
        mov r10, rsi
        mov [rsp + 30h], rdx
        mov [rsp + 38h], rcx
        mov [rsp + 40h], r8
        mov [rsp + 48h], r9
        test al, al
        je .skip
        movaps [rsp + 50h], xmm0
        movaps [rsp + 60h], xmm1
        movaps [rsp + 70h], xmm2
        movaps [rsp + 80h], xmm3
        movaps [rsp + 90h], xmm4
        movaps [rsp + 0A0h], xmm5
        movaps [rsp + 0B0h], xmm6
        movaps [rsp + 0C0h], xmm7
        .skip:
        lea rax, [rsp + 20h]
        mov [rsp + 10h], rax
        lea rax, [rsp + 0E0h]
        mov [rsp + 8h], rax
        mov rax, 3000000010h
        mov [rsp], rax
        mov rcx, rsp

        mov rdx, r10
        mov rsi, 2

        call _LoggerLog
        add rsp, 0D8h
        ret
    GlobalLabel _LoggerLogError ; rdi => logger, rsi => format, ...
        sub rsp, 0D8h
        mov r10, rsi
        mov [rsp + 30h], rdx
        mov [rsp + 38h], rcx
        mov [rsp + 40h], r8
        mov [rsp + 48h], r9
        test al, al
        je .skip
        movaps [rsp + 50h], xmm0
        movaps [rsp + 60h], xmm1
        movaps [rsp + 70h], xmm2
        movaps [rsp + 80h], xmm3
        movaps [rsp + 90h], xmm4
        movaps [rsp + 0A0h], xmm5
        movaps [rsp + 0B0h], xmm6
        movaps [rsp + 0C0h], xmm7
        .skip:
        lea rax, [rsp + 20h]
        mov [rsp + 10h], rax
        lea rax, [rsp + 0E0h]
        mov [rsp + 8h], rax
        mov rax, 3000000010h
        mov [rsp], rax
        mov rcx, rsp

        mov rdx, r10
        mov rsi, 3

        call _LoggerLog
        add rsp, 0D8h
        ret
%endif