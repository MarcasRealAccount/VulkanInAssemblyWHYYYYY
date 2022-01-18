%include "Common.asminc"

%if BUILD_IS_SYSTEM_MACOSX && BUILD_IS_PLATFORM_AMD64
%include "Macosx-amd64/Logger.asminc"

section .rodata
    GlobalLabel AppName,      { db "OkForReal", 0 }
    GlobalLabel LogArgFormat, { db "Arg %d => %s", 0 }
    GlobalLabel LogFormat,    { db "Hi %s %X %d %p", 0 }
    GlobalLabel TestStr,      { db "Hmmm Odd" }

section .data
    GlobalLabel AppLogger, { times Logger_size db 0 }

section .text
    GlobalLabel _main ; edi => argc, rsi => argv
        push rbp
        mov rbp, rsp
        sub rsp, 20h
        mov [rsp], rbx
        mov [rsp + 8h], rdi
        mov [rsp + 16h], rsi

        lea rdi, [AppLogger]
        lea rsi, [AppName]
        call _LoggerCtor

        mov rbx, 0
        .argLoop:
            lea rdi, [AppLogger]
            lea rsi, [LogArgFormat]
            mov rdx, rbx
            mov rcx, [rsp + 16h]
            mov rcx, [rcx + rbx * 8h]
            xor al, al
            call _LoggerLogDebug

            inc rbx
            cmp rbx, [rsp + 8h]
            jl .argLoop

        lea rdi, [AppLogger]
        call _LoggerDtor

        mov rbx, [rsp]
        mov rsp, rbp
        pop rbp
        ret

%endif