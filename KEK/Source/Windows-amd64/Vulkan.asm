%include "Common.asminc"

%if BUILD_IS_SYSTEM_WINDOWS && BUILD_IS_PLATFORM_AMD64
%include "Windows-amd64/Vulkan.asminc"
%include "Windows-amd64/LibC.asminc"
%include "Windows-amd64/Logger.asminc"
%include "Windows-amd64/GLFW.asminc"

extern AppLogger

section .rdata
%if BUILD_IS_CONFIG_DEBUG
	VulkanCreateDebugUtilsMessengerEXTStr:  db "vkCreateDebugUtilsMessengerEXT", 0
	VulkanDestroyDebugUtilsMessengerEXTStr: db "vkDestroyDebugUtilsMessengerEXT", 0
%endif

	VulkanErrorFormat:          db "Vulkan %X", 0
	VulkanValidationFormat:     db "Vulkan Validation %s", 0
	VulkanDebugUtilsEXTStr:     db "VK_EXT_debug_utils", 0
	VulkanKhronosValidationStr: db "VK_LAYER_KHRONOS_validation", 0
	VulkanInstanceLayerNames:
%if BUILD_IS_CONFIG_DEBUG
		dq VulkanKhronosValidationStr
%endif
		.end:

section .data
%if BUILD_IS_CONFIG_DEBUG
	GlobalLabel VulkanCreateDebugUtilsMessengerEXTFunc,  { dq 0 }
	GlobalLabel VulkanDestroyDebugUtilsMessengerEXTFunc, { dq 0 }
%endif

section .text
	StaticLabel VulkanDebugCallback ; ecx => messageSeverity, edx => messageTypes, r8 => pCallbackData, r9 => pUserData
		mov [rsp + 8h], rcx
		mov [rsp + 10h], rdx
		mov [rsp + 18h], r8
		mov [rsp + 20h], r9
		sub rsp, 28h

		bsf rcx, [rsp + 8h]
		cmp rcx, 12
		jg .Error
		lea rax, [.jumpTable]
		jmp [rax + rcx * 8]

		.Verbose:
			lea rcx, [AppLogger]
			lea rdx, [VulkanValidationFormat]
			mov r8, [r8 + VkDebugUtilsMessengerCallbackDataEXT.pMessage]
			call LoggerLogInfo
			jmp .exit
		.Info:
			lea rcx, [AppLogger]
			lea rdx, [VulkanValidationFormat]
			mov r8, [r8 + VkDebugUtilsMessengerCallbackDataEXT.pMessage]
			call LoggerLogDebug
			jmp .exit
		.Warning:
			lea rcx, [AppLogger]
			lea rdx, [VulkanValidationFormat]
			mov r8, [r8 + VkDebugUtilsMessengerCallbackDataEXT.pMessage]
			call LoggerLogWarn
			jmp .exit
		.Error:
			lea rcx, [AppLogger]
			lea rdx, [VulkanValidationFormat]
			mov r8, [r8 + VkDebugUtilsMessengerCallbackDataEXT.pMessage]
			call LoggerLogError
			jmp .exit

		.exit:
			add rsp, 28h
			xor eax, eax
			ret
		.jumpTable:
			dq .Verbose
			dq .Verbose
			dq .Verbose
			dq .Verbose
			dq .Info
			dq .Info
			dq .Info
			dq .Info
			dq .Warning
			dq .Warning
			dq .Warning
			dq .Warning
			dq .Error

	StaticLabel VulkanPopulateDebugCreateInfo ; rcx => createInfo
		mov dword[rcx + VkDebugUtilsMessengerCreateInfoEXT.sType], 1000128004
		mov qword[rcx + VkDebugUtilsMessengerCreateInfoEXT.pNext], 0
		mov dword[rcx + VkDebugUtilsMessengerCreateInfoEXT.flags], 0
		mov dword[rcx + VkDebugUtilsMessengerCreateInfoEXT.messageSeverity], 1 | 16 | 256 | 4096
		mov dword[rcx + VkDebugUtilsMessengerCreateInfoEXT.messageType], 1 | 2 | 4
		lea rdx, [VulkanDebugCallback]
		mov qword[rcx + VkDebugUtilsMessengerCreateInfoEXT.pfnUserCallback], rdx
		mov qword[rcx + VkDebugUtilsMessengerCreateInfoEXT.pUserData], 0
		ret

	StaticLabel VulkanCreateInstance ; rcx => Vulkan
%if BUILD_IS_CONFIG_DEBUG
		sub rsp, 48h + VkInstanceCreateInfo_size + VkApplicationInfo_size + VkDebugUtilsMessengerCreateInfoEXT_size + 8h ; 8 byte padding
%else
		sub rsp, 48h + VkInstanceCreateInfo_size + VkApplicationInfo_size + 8h ; 8 byte padding
%endif
		mov [rsp + 20h], rcx
		
		lea rcx, [rsp + 28h]
		call glfwGetRequiredInstanceExtensions
		mov [rsp + 30h], rax

%if BUILD_IS_CONFIG_DEBUG
		mov ecx, [rsp + 28h]
		add ecx, 1
		mov [rsp + 38h], ecx
		imul ecx, ecx, 8
		call malloc
		mov [rsp + 40h], rax

		mov ebx, 0
		mov rcx, [rsp + 40h]
		mov rdx, [rsp + 30h]
		.extensionLoop:
			mov r8, [rdx + rbx * 8]
			mov [rcx + rbx * 8], r8

			inc ebx
			cmp ebx, [rsp + 28h]
			jl .extensionLoop

		lea rdx, [VulkanDebugUtilsEXTStr]
		mov [rcx + rbx * 8], rdx

		mov [rsp + 30h], rcx
		mov rcx, [rsp + 38h]
		mov [rsp + 28h], rcx

		lea rcx, [rsp + 48h + VkInstanceCreateInfo_size + VkApplicationInfo_size]
		call VulkanPopulateDebugCreateInfo
%endif

		mov dword[rsp + 48h + VkInstanceCreateInfo_size + VkApplicationInfo.sType], 0
		mov qword[rsp + 48h + VkInstanceCreateInfo_size + VkApplicationInfo.pNext], 0
		mov rbx, [rsp + 20h]
		mov rcx, [rbx + Vulkan.applicationName]
		mov qword[rsp + 48h + VkInstanceCreateInfo_size + VkApplicationInfo.pApplicationName], rcx
		mov rcx, [rbx + Vulkan.applicationVersion]
		mov dword[rsp + 48h + VkInstanceCreateInfo_size + VkApplicationInfo.applicationVersion], ecx
		mov rcx, [rbx + Vulkan.engineName]
		mov qword[rsp + 48h + VkInstanceCreateInfo_size + VkApplicationInfo.pEngineName], rcx
		mov rcx, [rbx + Vulkan.engineVersion]
		mov dword[rsp + 48h + VkInstanceCreateInfo_size + VkApplicationInfo.engineVersion], ecx
		mov rcx, [rbx + Vulkan.apiVersion]
		mov dword[rsp + 48h + VkInstanceCreateInfo_size + VkApplicationInfo.apiVersion], ecx

		mov dword[rsp + 48h + VkInstanceCreateInfo.sType], 1
%if BUILD_IS_CONFIG_DEBUG
		lea rcx, [rsp + 48h + VkInstanceCreateInfo_size + VkApplicationInfo_size]
		mov qword[rsp + 48h + VkInstanceCreateInfo.pNext], rcx
%else
		mov qword[rsp + 48h + VkInstanceCreateInfo.pNext], 0
%endif
		mov dword[rsp + 48h + VkInstanceCreateInfo.flags], 0
		lea rcx, [rsp + 48h + VkInstanceCreateInfo_size]
		mov qword[rsp + 48h + VkInstanceCreateInfo.pApplicationInfo], rcx
		mov ecx, (VulkanInstanceLayerNames.end - VulkanInstanceLayerNames) / 8
		mov dword[rsp + 48h + VkInstanceCreateInfo.enabledLayerCount], ecx
		lea rcx, [VulkanInstanceLayerNames]
		mov qword[rsp + 48h + VkInstanceCreateInfo.ppEnabledLayerNames], rcx
		mov ecx, [rsp + 28h]
		mov dword[rsp + 48h + VkInstanceCreateInfo.enabledExtensionCount], ecx
		mov rcx, [rsp + 30h]
		mov qword[rsp + 48h + VkInstanceCreateInfo.ppEnabledExtensionNames], rcx

		mov rax, [rsp + 20h]
		lea rcx, [rsp + 48h]
		mov rdx, 0
		lea r8, [rax + Vulkan.instance]
		call vkCreateInstance
		
%if BUILD_IS_CONFIG_DEBUG
		mov [rsp + 38h], eax
		mov rcx, [rsp + 30h]
		call free

		cmp dword[rsp + 38h], 0
		js .exit

		mov rax, [rsp + 20h]
		mov rcx, [rax + Vulkan.instance]
		lea rdx, [VulkanCreateDebugUtilsMessengerEXTStr]
		call vkGetInstanceProcAddr
		mov [VulkanCreateDebugUtilsMessengerEXTFunc], rax

		mov rax, [rsp + 20h]
		mov rcx, [rax + Vulkan.instance]
		lea rdx, [VulkanDestroyDebugUtilsMessengerEXTStr]
		call vkGetInstanceProcAddr
		mov [VulkanDestroyDebugUtilsMessengerEXTFunc], rax

		mov rax, [rsp + 20h]
		mov rcx, [rax + Vulkan.instance]
		lea rdx, [rsp + 48h + VkInstanceCreateInfo_size + VkApplicationInfo_size]
		mov r8, 0
		lea r9, [rax + Vulkan.debugMessenger]
		call vkCreateDebugUtilsMessengerEXT
%endif

		.exit:
%if BUILD_IS_CONFIG_DEBUG
			add rsp, 48h + VkInstanceCreateInfo_size + VkApplicationInfo_size + VkDebugUtilsMessengerCreateInfoEXT_size + 8h ; 8 byte padding
%else
			add rsp, 48h + VkInstanceCreateInfo_size + VkApplicationInfo_size + 8h ; 8 byte padding
%endif
			ret

	GlobalLabel VulkanAlloc
		mov rcx, Vulkan_size
		jmp malloc

	GlobalLabel VulkanFree ; rcx => Vulkan
		jmp free

	GlobalLabel VulkanCtor ; rcx => Vulkan, edx => width, r8d => height, r9 => title, rsp + 20h => applicationName, rsp + 28h => engineName, rsp + 30h => applicationVersion, rsp + 38h => engineVersion
		mov rax, [rsp + 28h]
		mov [rcx + Vulkan.applicationName], rax
		mov rax, [rsp + 30h]
		mov [rcx + Vulkan.engineName], rax
		mov eax, [rsp + 38h]
		mov [rcx + Vulkan.applicationVersion], eax
		mov eax, [rsp + 40h]
		mov [rcx + Vulkan.engineVersion], eax
		mov dword[rcx + Vulkan.apiVersion], 402000h
		lea rcx, [rcx + Vulkan.window]
		jmp WindowCtor

	GlobalLabel VulkanDtor ; rcx => Vulkan
		mov [rsp + 8h], rcx
		sub rsp, 28h
		cmp qword[rcx + Vulkan.instance], 0
		je .exit
		call VulkanDeinit
		mov rcx, [rsp + 28h + 8h]
		lea rcx, [rcx + Vulkan.window]
		call WindowDtor
		.exit:
			add rsp, 28h
			ret

	GlobalLabel VulkanInit ; rcx => Vulkan
		mov [rsp + 8h], rcx
		sub rsp, 28h
		
		call VulkanCreateInstance
		cmp eax, 0
		js .error

		.exit:
			add rsp, 28h
			ret

		.error:
			lea rcx, [AppLogger]
			lea rdx, [VulkanErrorFormat]
			mov r8, rax
			call LoggerLogError
			jmp .exit

	GlobalLabel VulkanDeinit ; rcx => Vulkan
		mov [rsp + 8h], rcx
		sub rsp, 28h
		
%if BUILD_IS_CONFIG_DEBUG
		mov rax, [rsp + 28h + 8h]
		mov rcx, [rax + Vulkan.instance]
		mov rdx, [rax + Vulkan.debugMessenger]
		mov r8, 0
		call vkDestroyDebugUtilsMessengerEXT
%endif

		mov rax, [rsp + 28h + 8h]
		mov rcx, [rax + Vulkan.instance]
		call vkDestroyInstance

		add rsp, 28h
		ret
		
%if BUILD_IS_CONFIG_DEBUG
	GlobalLabel vkCreateDebugUtilsMessengerEXT ; rcx => instance, rdx => pCreateInfo, r8 => pAllocator, r9 => pMessenger
		mov rax, [VulkanCreateDebugUtilsMessengerEXTFunc]
		jmp rax

	GlobalLabel vkDestroyDebugUtilsMessengerEXT ; rcx => instance, rdx => messenger, r8 => pAllocator
		mov rax, [VulkanDestroyDebugUtilsMessengerEXTFunc]
		jmp rax
%endif

%endif