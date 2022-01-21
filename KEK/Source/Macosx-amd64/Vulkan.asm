%include "Common.asminc"

%if BUILD_IS_SYSTEM_MACOSX && BUILD_IS_PLATFORM_AMD64
%include "Macosx-amd64/LibC.asminc"
%include "Macosx-amd64/GLFW.asminc"
%include "Macosx-amd64/Logger.asminc"
%include "Macosx-amd64/Vulkan.asminc"

extern _AppLogger

section .rodata
%if BUILD_IS_CONFIG_DEBUG
    GlobalLabel _VulkanCreateDebugUtilsMessengerEXTStr,  { db "vkCreateDebugUtilsMessengerEXT", 0 }
    GlobalLabel _VulkanDestroyDebugUtilsMessengerEXTStr, { db "vkDestroyDebugUtilsMessengerEXT", 0 }
    GlobalLabel _VulkanDebugUtilsEXTStr,                 { db "VK_EXT_debug_utils", 0 }
    GlobalLabel _VulkanKhronosValidationStr,             { db "VK_LAYER_KHRONOS_validation", 0 }
%endif

    VulkanErrorFormat:      db "Vulkan %X", 0
    VulkanValidationFormat: db "Vulkan Validation %s", 0
    VulkanInstanceLayerNames:
%if BUILD_IS_CONFIG_DEBUG
        dq _VulkanKhronosValidationStr
%endif
        .end:

section .data
%if BUILD_IS_CONFIG_DEBUG
    GlobalLabel _VulkanCreateDebugUtilsMessengerEXTFunc,  { dq 0 }
    GlobalLabel _VulkanDestroyDebugUtilsMessengerEXTFunc, { dq 0 }
%endif

section .text
    StaticLabel VulkanDebugCallback ; edi => messageSeverity, esi => messageTypes, rdx => pCallbackData, rcx => pUserData
        push rbp,
        mov rsp, rbp
        sub rsp, 10h

        mov [rsp], rdi
        mov [rsp + 8h], rsi

        bsf rax, [rsp]
        cmp rax, 12
        mov rcx, 12
        cmovg rax, rcx
        mov rcx, 4
        mov [rsp], rdx
        xor rdx, rdx
        idiv rcx
        lea rsi, [.jumpTable]
        mov rax, [rsi + rax * 8]
        add rax, rsi
        lea rdi, [_AppLogger]
        lea rsi, [VulkanValidationFormat]
        mov rdx, [rsp]
        mov rdx, [rdx + VkDebugUtilsMessengerCallbackDataEXT.pMessage]
        jmp rax
        .jumpTable:
            dq .Verbose - .jumpTable
            dq .Info - .jumpTable
            dq .Warning - .jumpTable
            dq .Error - .jumpTable
        .Verbose:
            call _LoggerLogInfo
            jmp .exit
        .Info:
            call _LoggerLogDebug
            jmp .exit
        .Warning:
            call _LoggerLogWarn
            jmp .exit
        .Error:
            call _LoggerLogError
            jmp .exit

        .exit:
            mov rsp, rbp
            pop rbp
            xor rax, rax
            ret

    StaticLabel VulkanPopulateDebugCreateInfo ; rdi => createInfo
        mov dword[rcx + VkDebugUtilsMessengerCreateInfoEXT.sType], 1000128004
        mov qword[rcx + VkDebugUtilsMessengerCreateInfoEXT.pNext], 0
        mov dword[rcx + VkDebugUtilsMessengerCreateInfoEXT.flags], 0
        mov dword[rcx + VkDebugUtilsMessengerCreateInfoEXT.messageSeverity], 1h | 10h | 100h | 1000h
        mov dword[rcx + VkDebugUtilsMessengerCreateInfoEXT.messageType], 1 | 2 | 4
        lea rdx, [VulkanDebugCallback]
        mov qword[rcx + VkDebugUtilsMessengerCreateInfoEXT.pfnUserCallback], rdx
        mov qword[rcx + VkDebugUtilsMessengerCreateInfoEXT.pUserData], 0
        ret

    StaticLabel VulkanCreateInstance ; rdi => Vulkan
        push rbp
        push rbx
        mov rbp, rsp
%if BUILD_IS_CONFIG_DEBUG
        sub rsp, 30h + VkInstanceCreateInfo_size + VkApplicationInfo_size + VkDebugUtilsMessengerCreateInfoEXT_size + 8h ; 8 byte padding
%else
        sub rsp, 30h + VkInstanceCreateInfo_size + VkApplicationInfo_size + 8h ; 8 byte padding
%endif

        mov [rsp], rdi

        lea rdi, [rsp + 8h]
        call _glfwGetRequiredInstanceExtensions
        mov [rsp + 10h], rax

%if BUILD_IS_CONFIG_DEBUG
        mov rdi, [rsp + 8h]
        add rdi, 1
        mov [rsp + 18h], rdi
        imul rdi, rdi, 8
        call _malloc
        mov [rsp + 20h], rax

        mov ebx, 0
        mov rcx, [rsp + 20h]
        mov rdx, [rsp + 10h]
        .extensionLoop:
            mov r8, [rdx + rbx * 8]
            mov [rcx + rbx * 8], r8

            inc ebx
            cmp ebx, [rsp + 8h]
            jl .extensionLoop

        lea rdx, [_VulkanDebugUtilsEXTStr]
        mov [rcx + rbx * 8], rdx

        mov [rsp + 10h], rax
        mov rcx, [rsp + 18h]
        mov [rsp + 8h], rcx

        lea rcx, [rsp + 30h + VkInstanceCreateInfo_size + VkApplicationInfo_size]
        call VulkanPopulateDebugCreateInfo
%endif

        mov dword[rsp + 30h + VkInstanceCreateInfo_size + VkApplicationInfo.sType], 0
        mov qword[rsp + 30h + VkInstanceCreateInfo_size + VkApplicationInfo.pNext], 0
        mov rbx, [rsp]
        mov rcx, [rbx + Vulkan.applicationName]
        mov qword[rsp + 30h + VkInstanceCreateInfo_size + VkApplicationInfo.pApplicationName], rcx
        mov ecx, [rbx + Vulkan.applicationVersion]
        mov dword[rsp + 30h + VkInstanceCreateInfo_size + VkApplicationInfo.applicationVersion], ecx
        mov rcx, [rbx + Vulkan.engineName]
        mov qword[rsp + 30h + VkInstanceCreateInfo_size + VkApplicationInfo.pEngineName], rcx
        mov ecx, [rbx + Vulkan.engineVersion]
        mov dword[rsp + 30h + VkInstanceCreateInfo_size + VkApplicationInfo.engineVersion], ecx
        mov ecx, [rbx + Vulkan.apiVersion]
        mov dword[rsp + 30h + VkInstanceCreateInfo_size + VkApplicationInfo.apiVersion], ecx

        mov dword[rsp + 30h + VkInstanceCreateInfo.sType], 1
%if BUILD_IS_CONFIG_DEBUG
        ; lea rcx, [rsp + 30h + VkInstanceCreateInfo_size + VkApplicationInfo_size]
        ; mov qword[rsp + 30h + VkInstanceCreateInfo.pNext], rcx
        ; TODO(MarcasRealAccount): Currently the macosx vulkan icd loader fails when passing a correct debug utils messenger
        ; so to mitigate it will be disabled.
        mov qword[rsp + 30h + VkInstanceCreateInfo.pNext], 0
%else
        mov qword[rsp + 30h + VkInstanceCreateInfo.pNext], 0
%endif
        mov dword[rsp + 30h + VkInstanceCreateInfo.flags], 0
        lea rcx, [rsp + 30h + VkInstanceCreateInfo_size]
        mov qword[rsp + 30h + VkInstanceCreateInfo.pApplicationInfo], rcx
        mov dword[rsp + 30h + VkInstanceCreateInfo.enabledLayerCount], (VulkanInstanceLayerNames.end - VulkanInstanceLayerNames) / 8
        lea rcx, [VulkanInstanceLayerNames]
        mov qword[rsp + 30h + VkInstanceCreateInfo.ppEnabledLayerNames], rcx
        mov ecx, [rsp + 8h]
        mov dword[rsp + 30h + VkInstanceCreateInfo.enabledExtensionCount], ecx
        mov rcx, [rsp + 10h]
        mov qword[rsp + 30h + VkInstanceCreateInfo.ppEnabledExtensionNames], rcx

        mov rbx, [rsp]
        lea rdi, [rsp + 30h]
        mov rsi, 0
        lea rdx, [rbx + Vulkan.instance]
        call _vkCreateInstance

%if BUILD_IS_CONFIG_DEBUG
        mov [rsp + 18h], eax
        mov rdi, [rsp + 10h]
        call _free

        cmp dword[rsp + 18h], 0
        js .exit

        mov rdi, [rbx + Vulkan.instance]
        lea rsi, [_VulkanCreateDebugUtilsMessengerEXTStr]
        call _vkGetInstanceProcAddr
        mov [_VulkanCreateDebugUtilsMessengerEXTFunc], rax

        mov rdi, [rbx + Vulkan.instance]
        lea rsi, [_VulkanDestroyDebugUtilsMessengerEXTStr]
        call _vkGetInstanceProcAddr
        mov [_VulkanDestroyDebugUtilsMessengerEXTFunc], rax

        mov rdi, [rbx + Vulkan.instance]
        lea rsi, [rsp + 30h + VkInstanceCreateInfo_size + VkApplicationInfo_size]
        mov rdx, 0
        lea rcx, [rbx + Vulkan.debugMessenger]
        call _vkCreateDebugUtilsMessengerEXT
%endif

        .exit:
            mov rsp, rbp
            pop rbx
            pop rbp
            ret

    GlobalLabel _VulkanAlloc
        mov rdi, Vulkan_size
        jmp _malloc

    GlobalLabel _VulkanFree ; rdi => Vulkan
        jmp _free

    GlobalLabel _VulkanCtor ; rdi => Vulkan, esi => width, edx => height, rcx => title, r8 => applicationName, r9 => engineName, rsp >= applicationVersion, rsp + 8h => engineVersion
        mov [rdi + Vulkan.applicationName], r8
        mov [rdi + Vulkan.engineName], r9
        mov rax, [rsp + 8h]
        mov [rdi + Vulkan.applicationVersion], rax
        mov rax, [rsp + 10h]
        mov [rdi + Vulkan.engineVersion], rax
        mov dword[rdi + Vulkan.apiVersion], 401000h
        lea rdi, [rdi + Vulkan.window]
        jmp _WindowCtor

    GlobalLabel _VulkanDtor ; rdi => Vulkan
        push rbp
        mov rbp, rsp
        sub rsp, 10h

        mov [rsp], rdi

        cmp qword[rdi + Vulkan.instance], 0
        je .skipDeinit
        call _VulkanDeinit
        .skipDeinit:
            mov rdi, [rsp]
            lea rdi, [rdi + Vulkan.window]
            call _WindowDtor
        .exit:
            mov rsp, rbp
            pop rbp
            ret

    GlobalLabel _VulkanInit ; rdi => Vulkan
        push rbp
        mov rbp, rsp

        call VulkanCreateInstance
        cmp eax, 0
        js .error

        .exit:
            mov rsp, rbp
            pop rbp
            ret

        .error:
            lea rdi, [_AppLogger]
            lea rsi, [VulkanErrorFormat]
            mov rdx, rax
            call _LoggerLogError
            jmp .exit

    GlobalLabel _VulkanDeinit ; rdi => Vulkan
        push rbp
        push rbx
        mov rbp, rsp
        sub rsp, 8h

        mov rbx, rdi

%if BUILD_IS_CONFIG_DEBUG
        mov rdi, [rbx + Vulkan.instance]
        mov rsi, [rbx + Vulkan.debugMessenger]
        mov rdx, 0
        call _vkDestroyDebugUtilsMessengerEXT
%endif

        mov rdi, [rbx + Vulkan.instance]
        mov rsi, 0
        call _vkDestroyInstance

        mov rsp, rbp
        pop rbx
        pop rbp
        ret

%if BUILD_IS_CONFIG_DEBUG
    GlobalLabel _vkCreateDebugUtilsMessengerEXT ; rdi => instance, rsi => pCreateInfo, rdx => pAllocator, rcx => pMessenger
        mov rax, [_VulkanCreateDebugUtilsMessengerEXTFunc]
        jmp rax

    GlobalLabel _vkDestroyDebugUtilsMessengerEXT ; rdi => instance, rsi => messenger, rdx => pAllocator
        mov rax, [_VulkanDestroyDebugUtilsMessengerEXTFunc]
        jmp rax
%endif

%endif