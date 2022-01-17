%include "Common.asminc"

%if BUILD_IS_SYSTEM_WINDOWS && BUILD_IS_PLATFORM_AMD64
%include "Windows-amd64/LibC.asminc"
%include "Windows-amd64/Logger.asminc"
%include "Windows-amd64/Window.asminc"
%include "Windows-amd64/Vulkan.asminc"

section .rdata
	GlobalLabel AppName,      { db "OkForReal", 0 }
	GlobalLabel EngineName,   { db "LikeComonDude", 0 }
	GlobalLabel LogArgFormat, { db "Arg %d => %s", 0 }

section .data
	GlobalLabel AppLogger, { times Logger_size db 0 }
	GlobalLabel AppVulkan, { times Vulkan_size db 0 }
	GlobalLabel AppWindow, { dq 0 }

section .text
	GlobalLabel WinMain ; rcx => hInstance, rdx => hPrevInstance, r8 => lpCmdLine, r9d => nShowCmd
		sub rsp, 28h

		call __p___argc
		mov ebx, eax

		call __p___argv

		mov ecx, ebx
		mov rdx, rax
		call main

		add rsp, 28h
		ret
	
	GlobalLabel main ; ecx => argc, rdx => argv
		mov [rsp + 8h], rcx
		mov [rsp + 10h], rdx
		mov [rsp + 18h], rbx
		sub rsp, 48h

		lea rcx, [AppLogger]
		lea rdx, [AppName]
		call LoggerCtor

		mov rbx, 0
		.argLoop:
			lea rcx, [AppLogger]
			lea rdx, [LogArgFormat]
			mov r8, rbx
			mov r9, [rsp + 48h + 10h]
			mov r9, [r9 + 8h * rbx]
			call LoggerLogDebug
			
			inc rbx
			cmp rbx, [rsp + 48h + 8h]
			jl .argLoop

		lea rcx, [AppVulkan]
		mov edx, 1280
		mov r8d, 720
		lea r9, [AppName]
		lea rax, [AppName]
		mov [rsp + 20h], rax
		lea rax, [EngineName]
		mov [rsp + 28h], rax
		mov dword[rsp + 30h], 0
		mov dword[rsp + 38h], 0
		call VulkanCtor

		lea rcx, [AppVulkan + Vulkan.window]
		mov [AppWindow], rcx

		mov rcx, [AppWindow]
		call WindowCreate
		cmp rax, 0
		je .loopEnd

		lea rcx, [AppVulkan]
		call VulkanInit

		.loop:
			call WindowsUpdate
			
			mov rcx, [AppWindow]
			call WindowShouldClose
			cmp rax, 0
			je .loop
		.loopEnd:

		lea rcx, [AppVulkan]
		call VulkanDtor
		
		lea rcx, [AppLogger]
		call LoggerDtor

		add rsp, 48h
		mov rbx, [rsp + 18h]
		ret

%endif