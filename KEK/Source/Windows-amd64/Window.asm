%include "Common.asminc"

%if BUILD_IS_SYSTEM_WINDOWS && BUILD_IS_PLATFORM_AMD64
%include "Windows-amd64/Window.asminc"
%include "Windows-amd64/Logger.asminc"
%include "Windows-amd64/LibC.asminc"
%include "Windows-amd64/GLFW.asminc"

extern AppLogger

section .rdata
	GLFWErrorFormat: db "GLFW (%d) => %s", 0

section .data
	GlobalLabel WindowCount, { dq 0 }

section .text
	StaticLabel GLFWErrorCallback ; ecx => errorCode, rdx => message
		mov r8, rcx
		mov r9, rdx
		lea rcx, [AppLogger]
		lea rdx, [GLFWErrorFormat]
		jmp LoggerLogError

	GlobalLabel WindowAlloc
		mov rcx, Window_size
		jmp malloc

	GlobalLabel WindowFree ; rcx => window
		jmp free

	GlobalLabel WindowCtor ; rcx => window, edx => width, r8d => height, r9 => title
		mov dword[rcx + Window.width], edx
		mov dword[rcx + Window.height], r8d
		mov qword[rcx + Window.title], r9
		mov qword[rcx + Window.windowPtr], 0
		ret

	GlobalLabel WindowDtor ; rcx => window
		cmp qword[rcx + Window.windowPtr], 0
		je .exit
		jmp WindowDestroy
		.exit:
			ret

	GlobalLabel WindowCreate ; rcx => window
		cmp qword[rcx + Window.windowPtr], 0
		je .continue
		ret
		.continue:

		mov [rsp + 8h], rcx
		sub rsp, 28h

		cmp qword[WindowCount], 0
		jne .skipInit
		
		lea rcx, [GLFWErrorCallback]
		call glfwSetErrorCallback
		
		call glfwInit
		cmp rax, 0
		je .exit
		.skipInit:

		call glfwDefaultWindowHints
		mov ecx, 22001h
		mov edx, 0
		call glfwWindowHint
		mov ecx, 20003h
		mov edx, 1
		call glfwWindowHint

		mov rax, [rsp + 28h + 8h]
		mov ecx, [rax + Window.width]
		mov edx, [rax + Window.height]
		mov r8, [rax + Window.title]
		mov r9, 0
		mov qword[rsp + 20h], 0
		call glfwCreateWindow
		cmp rax, 0
		je .exit
		mov rcx, [rsp + 28h + 8h]
		mov [rcx + Window.windowPtr], rax
		
		add qword[WindowCount], 1

		.exit:
			add rsp, 28h
			ret
			
	GlobalLabel WindowDestroy ; rcx => window
		cmp qword[rcx + Window.windowPtr], 0
		jne .continue
		ret
		.continue:

		mov [rsp + 8h], rcx
		sub rsp, 28h

		mov rcx, [rcx + Window.windowPtr]
		call glfwDestroyWindow
		mov rcx, [rsp + 28h + 8h]
		mov qword[rcx + Window.windowPtr], 0
		sub qword[WindowCount], 1

		cmp qword[WindowCount], 0
		jne .exit
		call glfwTerminate

		.exit:
			add rsp, 28h
			ret

	GlobalLabel WindowGetNative ; rcx => window
		mov rax, [rcx + Window.windowPtr]
		ret

	GlobalLabel WindowShouldClose ; rcx => window
		mov rcx, [rcx + Window.windowPtr]
		jmp glfwWindowShouldClose

	GlobalLabel WindowsUpdate
		jmp glfwPollEvents

%endif