require("Premake/Module/vstudio/vs2010_vcxproj_ext")
require("Premake/Module/cmake/cmake_project_ext")

require("Premake/Actions/clean")
require("Premake/Actions/format-tidy")
require("Premake/Actions/pch")

common = require("Premake/common")

glfw   = require("Premake/Libs/glfw")
vma    = require("Premake/Libs/vma")
vulkan = require("Premake/Libs/vulkan")

workspace("VulkanInAssemblyWHYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY")
	common:setConfigsAndPlatforms()

	common:addCoreDefines()

	cppdialect("C++20")
	rtti("Off")
	exceptionhandling("Off")
	flags("MultiProcessorCompile")

	startproject("ForWhatPurposeIsThis")

	group("Dependencies")
	project("GLFW")
		location("ThirdParty/GLFW/")
		warnings("Off")
		glfw:setup()
		location("ThirdParty/")

	project("VMA")
		location("ThirdParty/VMA/")
		warnings("Off")
		vma:setup()
		location("ThirdParty/")

	project("VulkanHeaders")
		location("")
		warnings("Off")
		vulkan:setup()
		location("ThirdParty/")
	
	group("WTF")
	project("ForWhatPurposeIsThis")
		location("KEK")
		warnings("Extra")

		common:executableOutDirs()
		common:debugDir()

		filter("configurations:Debug")
			kind("ConsoleApp")
		
		filter("configurations:not Debug")
			kind("WindowedApp")

		filter({})

		includedirs({ "%{prj.location}/Source/" })

		if common.host == "windows" then
			filter("configurations:Debug")
				links({ "msvcrtd", "legacy_stdio_definitions" })

			filter("configurations:not Debug")
				links({ "msvcrt", "legacy_stdio_definitions" })

			filter({})
			linkoptions({ "/IGNORE:4899" })
		elseif common.host == "macosx" then
			linkoptions({ "-Wl,-rpath,'@executable_path'" })
		end

		glfw:setupDep()
		vma:setupDep()
		vulkan:setupDep(false)

		files({ "%{prj.location}/Source/**" })
		removefiles({ "*.DS_Store" })

		common:addActions()

		-- filter({ "files:**.asm", "configurations:Debug" })
			-- buildcommands({ "nasm \"%{file.relpath}\" -i \"%{prj.location}/Source/\" -dBUILD_CONFIG=BUILD_CONFIG_DEBUG -f Win64 -g -O0 -o \"%{cfg.objdir}/%{file.basename}.obj\"" })
			-- buildoutputs({ "%{cfg.objdir}/%{file.basename}.obj" })

		-- filter({ "files:**.asm", "configurations:Release" })
			-- buildcommands({ "nasm \"%{file.relpath}\" -i \"%{prj.location}/Source/\" -dBUILD_CONFIG=BUILD_CONFIG_RELEASE -f Win64 -g -Ox -o \"%{cfg.objdir}/%{file.basename}.obj\"" })
			-- buildoutputs({ "%{cfg.objdir}/%{file.basename}.obj" })

		-- filter({ "files:**.asm", "configurations:Dist" })
			-- buildcommands({ "nasm \"%{file.relpath}\" -i \"%{prj.location}/Source/\" -dBUILD_CONFIG=BUILD_CONFIG_DIST -f Win64 -Ox -o \"%{cfg.objdir}/%{file.basename}.obj\"" })
			-- buildoutputs({ "%{cfg.objdir}/%{file.basename}.obj" })
			
		-- filter({})