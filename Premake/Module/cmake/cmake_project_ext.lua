local p = premake
local cmake = p.extensions.cmake
local m = cmake.project

m.props = function(prj)
    return {
        m.enableNASM,
        m.kind,
        m.files,
        m.configs
    }
end

m.configProps = function(prj, cfg)
    return {
        m.dependencies,
        m.sourceFileProperties,
        m.outputDirs,
        m.includeDirs,
        m.defines,
        m.libDirs,
        m.libs,
        m.buildOptions,
        m.linkOptions,
        m.compileOptions,
        m.cppStandard,
        m.pch,
        m.prebuildCommands,
        m.postbuildCommands,
        m.prelinkCommands,
        m.customCommands,
        m.nasmFlags
    }
end

function m.enableNASM(prj)
    p.w("enable_language(ASM_NASM)")
end

function m.nasmFlags(prj, cfg)
    local flags = "-Xgnu"
    for _, def in ipairs(cfg.defines) do
        flags = flags .. " \"-d" .. def .. "\""
    end

    for _, udef in ipairs(cfg.undefines) do
        flags = flags .. " \"-u" .. udef .. "\""
    end

    if cfg.symbols == "On" then
        flags = flags .. " -g"
    end

    if cfg.optimize == "Off" then
        flags = flags .. " -O0"
    elseif cfg.optimize == "On" or cfg.optimize == "Debug" then
        flags = flags .. " -O1"
    elseif cfg.optimize == "Size" or cfg.optimize == "Speed" or cfg.optimize == "Full" then
        flags = flags .. " -Ox"
    end
    p.push("set(CMAKE_ASM_NASM_FLAGS_%s", cmake.common.configName(cfg, #prj.workspace.platforms > 1):upper())
    p.w("\"%s\"", cmake.common.escapeStrings(flags))
    p.pop(")")
end