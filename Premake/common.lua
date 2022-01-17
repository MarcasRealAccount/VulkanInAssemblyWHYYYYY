local common = {
	binDir = "%{wks.location}/Bin/%{cfg.system}-%{cfg.platform}-%{cfg.buildcfg}/",
	objDir = "%{wks.location}/Bin/Int-%{cfg.system}-%{cfg.platform}-%{cfg.buildcfg}/%{prj.name}/",
	host = os.host(),
	target = os.target(),
	arch = nil,
	targetArchs = nil
}

newoption({
	trigger = "target-arch",
	description = "Comma separated list of architectures to build (host == only host architecture)",
	value = "architectures",
	default = "host"
})

function common:executableOutDirs()
	targetdir(self.binDir)
	objdir(self.objDir)
end

function common:sharedLibOutDirs()
	kind("SharedLib")
	targetdir(self.binDir)
	objdir(self.objDir)
end

function common:staticLibOutDirs()
	kind("StaticLib")
	targetdir(self.objDir)
	objdir(self.objDir)
end

function common:debugDir()
	if _ACTION == "xcode4" then
		local projectName = self:projectName()
		local projectLocation = self:projectLocation()

		print([[The xcode4 action doesn't support using debug directory.
So you have to edit the scheme of ']] .. projectName .. [[' (Top center) to use this as the debug directory:
]] .. projectLocation .. "/Run")
	elseif _ACTION == "gmake" or _ACTION == "gmake2" or _ACTION == "cmake" then
		local projectName = self:projectName()
		local projectLocation = self:projectLocation()

		print("The " .. _ACTION .. [[ action doesn't support using debug directory.
So you have to manually 'cd' into the debug directory:
]] .. projectLocation .. "/Run")
	end

	debugdir("%{prj.location}/Run/")
end

function common:escapeChars(str)
	local res = str:gsub("\\", "\\\\")
	return res
end

function common:copyDirCommand(from, to)
	local realFrom = path.translate(os.realpath(from .. "/"), "/")
	local realTo = path.translate(os.realpath(to .. "/"), "/")
	
	if self.host == "windows" then
		return "xcopy /Q /E /Y /I \"" .. realFrom .. "\" \"" .. realTo .. "\""
	else
		return "cp -rf \"" .. realFrom .. "\" \"" .. realTo .. "\""
	end
end

function common:getScriptActionCommand(action)
	local commandArgs = "\"--file=" .. _MAIN_SCRIPT .. "\" "

	for k,v in pairs(_OPTIONS) do
		if k == "target-arch" then
			commandArgs = commandArgs .. "\"--" .. k .. "=%{cfg.architecture}\" "
		else
			commandArgs = commandArgs .. "\"--" .. k .. "=" .. v .. "\" "
		end
	end

	commandArgs = commandArgs .. action

	if self.host == "windows" then
		return self:escapeChars("\"" .. _PREMAKE_COMMAND .. "\" " .. commandArgs)
	else
		return self:escapeChars("'" .. _PREMAKE_COMMAND .. "' " .. commandArgs)
	end
end

function common:addPCH(source, header)
	pchsource(source)
	filter("action:xcode4")
		pchheader(header)

	filter("action:not xcode4")
		pchheader(path.getname(header))

	filter({})

	prebuildcommands({ self:getScriptActionCommand("force-pch") })
end

function common:addActions()
	filter("files:**.inl")
		runclangformat(true)

	filter("files:**.h")
		runclangformat(true)

	filter("files:**.cpp")
		runclangformat(true)
		runclangtidy(true)
		allowforcepch(true)

	filter({})
end

function common:addCoreDefines()
	filter("configurations:Debug")
		defines({ "BUILD_CONFIG=BUILD_CONFIG_DEBUG" })
		optimize("Off")
		symbols("On")

	filter("configurations:Release")
		defines({ "BUILD_CONFIG=BUILD_CONFIG_RELEASE" })
		optimize("Full")
		symbols("On")

	filter("configurations:Dist")
		defines({ "BUILD_CONFIG=BUILD_CONFIG_DIST" })
		optimize("Full")
		symbols("Off")

	filter("system:windows")
		toolset("msc")
		defines({
			"BUILD_SYSTEM=BUILD_SYSTEM_WINDOWS",
			"NOMINMAX", -- Windows.h disables
			"WIN32_LEAN_AND_MEAN",
			"_CRT_SECURE_NO_WARNINGS"
		})

	filter("system:macosx")
		toolset("clang")
		defines({ "BUILD_SYSTEM=BUILD_SYSTEM_MACOSX" })

	filter("system:linux")
		toolset("clang") -- Yes we hate gnu so why use gcc as the default toolset, just deal with it
		defines({ "BUILD_SYSTEM=BUILD_SYSTEM_LINUX" })

	filter("toolset:msc")
		defines({ "BUILD_TOOLSET=BUILD_TOOLSET_MSVC" })

	filter("toolset:clang")
		defines({ "BUILD_TOOLSET=BUILD_TOOLSET_CLANG" })

	filter("toolset:gcc")
		defines({ "BUILD_TOOLSET=BUILD_TOOLSET_GCC" })

	filter({})
end

function common:setConfigsAndPlatforms()
	configurations({ "Debug", "Release", "Dist" })
	platforms(self.targetArchs)

	for _,v in ipairs(self.targetArchs) do
		filter("platforms:" .. v)
			defines({ "BUILD_PLATFORM=BUILD_PLATFORM_" .. v:upper() })
			architecture(v)
	end
	filter({})
end

function common:projectName()
	return premake.api.scope.current.name
end

function common:projectLocation()
	return premake.api.scope.current.current.location
end

function common:libname(names)
	if type(names) == "table" then
		local libnames = {}
		
		for _, v in ipairs(names) do
			local libname = v
			if self.target == "windows" then
				libname = libname .. ".lib"
			else
				libname = "lib" .. libname .. ".a"
			end
			table.insert(libnames, libname)
		end
		
		return libnames
	else
		return self:libname({ names })[1]
	end
end

function common:sharedlibname(names, withDebug)
	if type(names) == "table" then
		local libnames = {}
		
		for _, v in ipairs(names) do
			local libname = v
			if self.target == "windows" then
				if withDebug then
				    table.insert(libnames, libname .. ".pdb")
				end
				libname = libname .. ".dll"
			elseif self.target == "macosx" then
				libname = "lib" .. libname .. ".dylib"
			else
				libname = "lib" .. libname .. ".so"
			end
			table.insert(libnames, libname)
		end
		
		return libnames
	else
		local libnames = self:sharedlibname({ names })
		if #libnames == 1 then return libnames[1] end
		return libnames
	end
end

function common:hasLib(lib, searchPaths)
	for _, searchPath in ipairs(searchPaths) do
		return #os.matchfiles(searchPath .. "/" .. self:libname(lib)) > 0
	end
	return false
end

function common:hasSharedLib(lib, searchPaths)
    if type(searchPaths) ~= "table" then searchPaths = { searchPaths } end
	for _, searchPath in ipairs(searchPaths) do
		return #os.matchfiles(searchPath .. "/" .. self:sharedlibname(lib)) > 0
	end
	return false
end

function common:normalizedPath(filepath)
    return path.translate(filepath, "/")
end

function common:rmdir(dir)
	local realDir = self:normalizedPath(dir) .. "/"
	
	if not os.isdir(realDir) then
		return 1, "'" .. dir .. "' is not a directory!"
	end
	
	local code, err = os.rmdir(realDir)
	if not code then return -4, err end
	
	return 0
end

function common:mkdirs(dir)
	local realDir = self:normalizedPath(dir) .. "/"
	
	if not os.isdir(realDir) then
		local curPath = ""
		for _, v in ipairs(string.explode(realDir, "/")) do
			curPath = curPath .. v .. "/"
			local code, err = os.mkdir(curPath)
			if not code then return -2, err end
		end
	end
	
	return 0
end

function common:copyFile(from, to)
	local realFrom = self:normalizedPath(from)
	local realTo = self:normalizedPath(to)
	local realToDir = path.getdirectory(realTo) .. "/"
	
	local code, err = self:mkdirs(realToDir)
	if code < 0 then return code, err end
	
	code, err = os.copyfile(realFrom, realTo)
	if not code then return -3, err end
	
	return 0
end

function common:copyFiles(from, filenames, to)
	local realFrom = self:normalizedPath(from)
	local realTo = self:normalizedPath(to)
	
	for _, v in ipairs(filenames) do
		local code, err = self:copyFile(realFrom .. v, realTo .. v)
		if code < 0 then return code, err end
	end
	
	return 0
end

function common:copyDir(from, to)
	local realFrom = self:normalizedPath(from) .. "/"
	local realTo = self:normalizedPath(to) .. "/"

	if not os.isdir(realFrom) then
		return -1, "'" .. from .. "' is not a directory!"
	end
	
	local matches = os.matchfiles(realFrom .. "**")
	for _, v in ipairs(matches) do
		code, err = self:copyFile(v, realTo .. path.getrelative(realFrom, v))
		if code < 0 then return code, err end
	end
	
	return 0
end

local function toPremakeArch(name)
	local lc = name:lower()
	if lc == "i386" then
		return "x86"
	elseif lc == "x86_64" or lc == "x64" then
		return "amd64"
	elseif lc == "arm32" then
		return "arm"
	else
		return lc
	end
end

local function getHostArch()
	local arch
	if common.host == "windows" then
		arch = os.getenv("PROCESSOR_ARCHITECTURE")
		if arch == "x86" then
			local is64 = os.getenv("PROCESSOR_ARCHITEW6432")
			if is64 then
				arch = is64
			end
		end
	elseif common.host == "macosx" then
		arch = os.outputof("echo $HOSTTYPE")
	else
		arch = os.outputof("uname -m")
	end
	
	return toPremakeArch(arch)
end

local function getTargetArchs()
	if _OPTIONS["target-arch"] == "host" then
		return { common.arch }
	else
		local archs = string.explode(_OPTIONS["target-arch"], "%s*,%s*")
		local output = {}
		for _, arch in ipairs(archs) do
			table.insert(output, toPremakeArch(arch))
		end
		return output
	end
end

common.arch = getHostArch()
common.targetArchs = getTargetArchs()

return common
