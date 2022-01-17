require("vstudio")

local p = premake
local m = p.vstudio.vc2010

---
-- Override MASM to use NASM instead
---
m.categories.Masm = {
	name       = "Masm",
	extensions = ".asm",
	priority   = 9,
	
	emitFiles = function(prj, group)
		local fileCfgFunc = function(fcfg, condition)
			if fcfg then
				return {
					m.excludedFromBuild,
					m.buildNASMCommand,
					m.buildNASMOutputs,
					m.linkNASMObjects
				}
			else
				return {
					m.excludedFromBuild
				}
			end
		end
		
		m.emitFiles(prj, group, "CustomBuild", nil, fileCfgFunc)
	end,
	
	emitFilter = function(prj, group)
		m.filterGroup(prj, group, "CustomBuild")
	end
}

local function serialize(object, indents, seen)
	local typ = type(object)
	if typ == "table" then
		if not seen then seen = {} end
		if not indents then indents = "" end
		local innerIndent = indents .. " "
		
		if indents:len() > 3 or seen[object] then
			return tostring(object)
		end
		seen[object] = true
		
		local str = "{"
		local prevEl = false
		for k, v in pairs(object) do
			if prevEl then
				str = str .. ","
			end
			prevEl = true
			str = str .. "\n" .. innerIndent .. serialize(k, innerIndent, seen) .. " = " .. serialize(v, innerIndent, seen)
		end
		return str .. "\n" .. indents .. "}"
	elseif typ == "string" then
		return "\"" .. object .. "\""
	elseif typ == "number" or typ == "boolean" or typ == "nil" then
		return tostring(object)
	else
		return "?"
	end
end

local function archToNASM(architecture)
	if architecture == "x86" then
		return "win32"
	elseif architecture == "x86_64" then
		return "win64"
	end
end

function m.buildNASMCommand(fcfg, condition)
	local cfg = fcfg.config
	local command = "nasm -Xvc -f " .. archToNASM(cfg.architecture)
	
	if cfg.symbols == "On" then
		command = command .. " -g"
	end
	
	if cfg.optimize == "Off" then
		command = command .. " -O0"
	elseif cfg.optimize == "On" or cfg.optimize == "Debug" then
		command = command .. " -O1"
	elseif cfg.optimize == "Size" or cfg.optimize == "Speed" or cfg.optimize == "Full" then
		command = command .. " -Ox"
	end
	
	for _, includedir in ipairs(cfg.includedirs) do
		command = command .. " -i \"" .. includedir .. "\""
	end
	
	for _, define in ipairs(cfg.defines) do
		command = command .. " -d" .. define
	end
	
	for _, undefine in ipairs(cfg.undefines) do
		command = command .. " -u" .. undefine
	end
	
	m.element("Command", condition, "%s -o \"%s/%s.obj\" \"%s\"", command, cfg.objdir, fcfg.basename, fcfg.abspath)
end

function m.buildNASMOutputs(fcfg, condition)
	m.element("Outputs", condition, "%s/%s.obj", fcfg.config.objdir, fcfg.basename)
end

function m.linkNASMObjects(fcfg, condition)
	m.element("LinkObjects", condition, "true")
end