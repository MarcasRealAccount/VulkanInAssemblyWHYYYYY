%include "Common.asminc"

%if BUILD_IS_SYSTEM_MACOSX && BUILD_IS_PLATFORM_AMD64
%include "Macosx-amd64/LibC.asminc"
%include "Macosx-amd64/GLFW.asminc"
%include "Macosx-amd64/Logger.asminc"
%include "Macosx-amd64/Window.asminc"

extern _AppLogger

section .rodata
    GLFWErrorFormat: db "GLFW (%d) => %s", 0

section .data
    GlobalLabel _WindowCount, { dq 0 }

section .text
    StaticLabel GLFWErrorCallback ; edi => errorCode, rsi => message
        mov rdx, rdi
        mov rcx, rsi
        lea rdi, [GLFWErrorFormat]
        lea rsi, [_AppLogger]
        jmp _LoggerLogError

    GlobalLabel _WindowAlloc
        mov rdi, Window_size
        jmp _malloc

    GlobalLabel _WindowFree ; rdi => window
        jmp _free

    GlobalLabel _WindowCtor ; rdi => window, esi => width, edx => height, rcx => title
        mov dword[rdi + Window.width], esi
        mov dword[rdi + Window.height], edx
        mov qword[rdi + Window.title], rcx
        mov qword[rdi + Window.windowPtr], 0
        ret

    GlobalLabel _WindowDtor ; rdi => window
        cmp qword[rdi + Window.windowPtr], 0
        je .exit
        jmp _WindowDestroy
        .exit:
            ret

    GlobalLabel _WindowCreate ; rdi => window
        cmp qword[rdi + Window.windowPtr], 0
        je .continue
        ret
        .continue:

        push rbp
        mov rbp, rsp
        sub rsp, 10h
        mov [rsp], rdi

        cmp qword[_WindowCount], 0
        jne .skipInit

        lea rdi, [GLFWErrorCallback]
        call _glfwSetErrorCallback

        call _glfwInit
        cmp rax, 0
        je .exit
        .skipInit:

        call _glfwDefaultWindowHints
        mov edi, 22001h
        mov esi, 0
        call _glfwWindowHint
        mov edi, 20003h
        mov edx, 1
        call _glfwWindowHint

        mov rax, [rsp]
        mov edi, [rax + Window.width]
        mov esi, [rax + Window.height]
        mov rdx, [rax + Window.title]
        mov rcx, 0
        mov r8, 0
        call _glfwCreateWindow
        cmp eax, 0
        je .exit
        mov rcx, [rsp]
        mov [rcx + Window.windowPtr], rax

        add qword[_WindowCount], 1

        .exit:
            mov rsp, rbp
            pop rbp
            ret

    GlobalLabel _WindowDestroy ; rdi => window
        cmp qword[rdi + Window.windowPtr], 0
        jne .continue
        ret
        .continue:

        push rbp
        mov rbp, rsp
        sub rsp, 10h
        mov [rsp], rdi

        mov rdi, [rdi + Window.windowPtr]
        call _glfwDestroyWindow
        mov rcx, [rsp]
        mov qword[rcx + Window.windowPtr], 0
        sub qword[_WindowCount], 1

        cmp qword[_WindowCount], 0
        jne .exit
        call _glfwTerminate

        .exit:
            mov rsp, rbp
            pop rbp
            ret

    GlobalLabel _WindowGetNative ; rdi => window
        mov rax, [rdi + Window.windowPtr]
        ret

    GlobalLabel _WindowShouldClose ; rdi => window
        mov rdi, [rdi + Window.windowPtr]
        jmp _glfwWindowShouldClose

    GlobalLabel _WindowsUpdate
        jmp _glfwPollEvents

%endif