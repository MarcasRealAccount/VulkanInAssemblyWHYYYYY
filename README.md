# VulkanInAssemblyWHYYYYY
Please tell me why I'm doing this

For some very dumb reason I decided to try out drawing a triangle with vulkan only using assembly.  
Please just tell me, why did I even start this??

Enough of that.  

# How to build
To build this project you will need Visual Studio and NASM installed to the PATH environment variable, so it's visible to Visual Studio.  
You also need Premake.  
After getting those dependencies just write `premake5 vs20xx` where `xx` is the version of Visual Studio you have, for me 22 as in `vs2022`.  
Now open the `.sln` file in the root directory and select the build mode `Debug`, `Release` or `Dist` and hit the build button or the run button.  

As of writing this the only Vulkan thing created is the `VkInstance` and `VkDebugUtilsMessengerEXT`.

| Date | LOC |
|-|-|
| 17. January. 2022 | 900 |
