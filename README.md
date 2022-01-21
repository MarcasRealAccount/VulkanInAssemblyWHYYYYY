# VulkanInAssemblyWHYYYYY
Please tell me why I am doing this

For some very dumb reason I decided to try out drawing a triangle with vulkan only using assembly.  
Please just tell me, why did I even start this??

Enough of that.  

# LOC timeline
| Date | LOC MacOSX | LOC Windows |
|-|-|-|
| 17. January. 2022 | 0 | 900 |
| 21. January. 2022 9:17 CET | 1024 | 890 |

# How to build
## Windows
To build this project you will need premake, Visual Studio and NASM installed to the PATH environment variable, so it's visible to Visual Studio.  
After getting those dependencies just write `premake5 vs20xx` where `xx` is the version of Visual Studio you have, for me 22 as in `vs2022`.  
Now open the `.sln` file in the root directory and select the build mode `Debug`, `Release` or `Dist` and hit the build button or the run button.  

As of writing this the current Vulkan things created is:
- VkInstance
- VkDebugUtilsMessengerEXT

## MacOSX
To build this project you will need premake and NASM installed to the PATH environment variable.  
After getting those dependencies just write `premake5 cmake` (Requires [premake-cmake](https://github.com/MarcasRealAccount/premake-cmake), I do plan on getting gnu Makefile support, but not today cuz I don't use it myself so...).  
Now build as you would normally with those build systems, and select the build mode `Debug`, `Release` or `Dist`, and lastly run the executable produced.  

As of writing this the current Vulkan things created is:
- VkInstance
- VkDebugUtilsMessengerEXT
- VkSurfaceKHR
