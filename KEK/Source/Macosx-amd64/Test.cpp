#define BUILD_CONFIG_UNKNOWN 0
#define BUILD_CONFIG_DEBUG   1
#define BUILD_CONFIG_RELEASE 2
#define BUILD_CONFIG_DIST    3

#define BUILD_PLATFORM_UNKNOWN 0
#define BUILD_PLATFORM_X86     1
#define BUILD_PLATFORM_AMD64   2

#define BUILD_SYSTEM_UNKNOWN 0
#define BUILD_SYSTEM_WINDOWS 1
#define BUILD_SYSTEM_LINUX   2
#define BUILD_SYSTEM_MACOSX  3

#define BUILD_IS_CONFIG_DEBUG (BUILD_CONFIG == BUILD_CONFIG_DEBUG)
#define BUILD_IS_CONFIG_DIST  ((BUILD_CONFIG == BUILD_CONFIG_RELEASE) || (BUILD_CONFIG == BUILD_CONFIG_DIST))

#define BUILD_IS_PLATFORM_X86   (BUILD_PLATFORM == BUILD_PLATFORM_X86)
#define BUILD_IS_PLATFORM_AMD64 (BUILD_PLATFORM == BUILD_PLATFORM_AMD64)

#define BUILD_IS_SYSTEM_WINDOWS (BUILD_SYSTEM == BUILD_SYSTEM_WINDOWS)
#define BUILD_IS_SYSTEM_LINUX   (BUILD_SYSTEM == BUILD_SYSTEM_LINUX)
#define BUILD_IS_SYSTEM_MACOSX  (BUILD_SYSTEM == BUILD_SYSTEM_MACOSX)
#define BUILD_IS_SYSTEM_UNIX    (BUILD_IS_SYSTEM_LINUX || BUILD_IS_SYSTEM_MACOSX)

#if BUILD_IS_SYSTEM_MACOSX
#define GLFW_INCLUDE_NONE
#include <glfw/glfw3.h>

#include <vulkan/vulkan.h>

#include <cstdint>

extern "C" VkResult vkCreateInstanceTest(const VkInstanceCreateInfo* pCreateInfo, [[maybe_unused]] const VkAllocationCallbacks* pAllocator, [[maybe_unused]] VkInstance* pInstance)
{
	[[maybe_unused]] const VkDebugUtilsMessengerCreateInfoEXT* pMsg = reinterpret_cast<const VkDebugUtilsMessengerCreateInfoEXT*>(pCreateInfo->pNext);
	return VK_SUCCESS;
}

struct Window
{
	std::uint32_t width, height;
	const char*   title;
	GLFWwindow*   windowPtr;
};

struct Vulkan
{
	Window        window;
	const char*   applicationName;
	const char*   engineName;
	std::uint32_t applicationVersion;
	std::uint32_t engineVersion;
	std::uint32_t apiVersion;
	VkInstance    instance;
#if BUILD_IS_CONFIG_DEBUG
	VkDebugUtilsMessengerEXT debugMessenger;
#endif
	VkSurfaceKHR             surface;
	VkPhysicalDevice         physicalDevice;
	VkSurfaceCapabilitiesKHR physicalDeviceCapabilities;
	VkDevice                 device;
	VkQueue                  graphicsPresentQueue;
	uint32_t                 graphicsPresentQueueIndex;
	VkFormat                 swapchainFormat;
	VkPresentModeKHR         swapchainPresentMode;
	VkSwapchainKHR           swapchain;
	uint32_t                 swapchainImageCount;
	VkImage*                 swapchainImages;
	VkImageView*             swapchainImageViews;
};

extern "C" bool VulkanTest([[maybe_unused]] Vulkan* vulkan)
{
	return true;
}

#endif