%include "Common.asminc"

%if BUILD_IS_SYSTEM_MACOSX && BUILD_IS_PLATFORM_AMD64
%include "Macosx-amd64/LibC.asminc"
%include "Macosx-amd64/Logger.asminc"
%include "Macosx-amd64/Window.asminc"

section .rodata
    GlobalLabel _AppName,      { db "OkForReal", 0 }
    GlobalLabel _LogArgFormat, { db "Arg %d => %s", 0 }

section .data
    GlobalLabel _AppLogger, { times Logger_size db 0 }
    GlobalLabel _AppWindow, { times Window_size db 0 }

section .text
    GlobalLabel _main ; edi => argc, rsi => argv
        push rbp
        mov rbp, rsp
        sub rsp, 20h
        mov [rsp], rbx
        mov [rsp + 8h], rdi
        mov [rsp + 16h], rsi

        lea rdi, [_AppLogger]
        lea rsi, [_AppName]
        call _LoggerCtor

        mov rbx, 0
        .argLoop:
            lea rdi, [_AppLogger]
            lea rsi, [_LogArgFormat]
            mov rdx, rbx
            mov rcx, [rsp + 16h]
            mov rcx, [rcx + rbx * 8h]
            xor al, al
            call _LoggerLogDebug

            inc rbx
            cmp rbx, [rsp + 8h]
            jl .argLoop

        lea rdi, [_AppWindow]
        mov esi, 1280
        mov edx, 720
        lea rcx, [_AppName]
        call _WindowCtor

        lea rdi, [_AppWindow]
        call _WindowCreate
        cmp rax, 0
        je .loopEnd

        .loop:
            call _WindowsUpdate

            lea rdi, [_AppWindow]
            call _WindowShouldClose
            cmp rax, 0
            je .loop
        .loopEnd:

        lea rdi, [_AppWindow]
        call _WindowDtor

        lea rdi, [_AppLogger]
        call _LoggerDtor

        mov rbx, [rsp]
        mov rsp, rbp
        pop rbp
        ret

%endif