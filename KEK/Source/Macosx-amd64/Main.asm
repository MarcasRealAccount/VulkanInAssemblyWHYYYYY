%include "Common.asminc"

%if BUILD_IS_SYSTEM_MACOSX && BUILD_IS_PLATFORM_AMD64
%include "Macosx-amd64/LibC.asminc"
%include "Macosx-amd64/Logger.asminc"
%include "Macosx-amd64/Window.asminc"
%include "Macosx-amd64/Vulkan.asminc"

section .rodata
    GlobalLabel _AppName,      { db "OkForReal", 0 }
	GlobalLabel _EngineName,   { db "LikeComonDude", 0 }
    GlobalLabel _LogArgFormat, { db "Arg %d => %s", 0 }

section .data
    GlobalLabel _AppLogger, { times Logger_size db 0 }
    GlobalLabel _AppVulkan, { times Vulkan_size db 0 }
    GlobalLabel _AppWindow, { dq 0 }

section .text
    GlobalLabel _main ; edi => argc, rsi => argv
        push rbp
        push rbx
        mov rbp, rsp
        sub rsp, 28h
        mov [rsp + 10h], rdi
        mov [rsp + 18h], rsi

        lea rdi, [_AppLogger]
        lea rsi, [_AppName]
        call _LoggerCtor

        mov rbx, 0
        .argLoop:
            lea rdi, [_AppLogger]
            lea rsi, [_LogArgFormat]
            mov rdx, rbx
            mov rcx, [rsp + 18h]
            mov rcx, [rcx + rbx * 8h]
            xor al, al
            call _LoggerLogDebug

            inc rbx
            cmp rbx, [rsp + 10h]
            jl .argLoop

        lea rdi, [_AppVulkan]
        mov esi, 1280
        mov edx, 720
        lea rcx, [_AppName]
        lea r8, [_AppName]
        lea r9, [_EngineName]
        mov dword[rsp], 0
        mov dword[rsp + 8h], 0
        call _VulkanCtor

        ; lea rdi, [_AppVulkan]
        ; call _VulkanTest

        lea rcx, [_AppVulkan + Vulkan.window]
        mov [_AppWindow], rcx

        mov rdi, [_AppWindow]
        call _WindowCreate
        cmp rax, 0
        je .loopEnd

        lea rdi, [_AppVulkan]
        call _VulkanInit

        .loop:
            call _WindowsUpdate

            lea rdi, [_AppWindow]
            call _WindowShouldClose
            cmp rax, 0
            je .loop
        .loopEnd:

        lea rdi, [_AppVulkan]
        call _VulkanDtor

        lea rdi, [_AppLogger]
        call _LoggerDtor

        mov rsp, rbp
        pop rbx
        pop rbp
        ret

%endif