local Process = nil

do
	local ok, loaded = pcall(require, '@lune/process')
	if ok then
		Process = loaded
	end
end

local function loadShared(moduleName, relativePath)
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.Parent.Shared[moduleName])
	end

	return require(string.format('%s%s', Process.cwd, relativePath))
end

local DebugVisualizer = loadShared('DebugVisualizer', 'src/Shared/DebugVisualizer.luau')

local Debug = {}
Debug.__index = Debug

function Debug.create(config)
	local debugConfig = config.debug or {}

	return setmetatable({
		container = debugConfig.container,
		sink = debugConfig.sink,
		traces = {},
	}, Debug)
end

function Debug:record(name, payload)
	local trace = {
		name = name,
		payload = payload or {},
	}

	table.insert(self.traces, trace)

	if type(self.sink) == 'function' then
		self.sink(trace)
	end

	return trace
end

function Debug:render(payload)
	if self.container == nil then
		return {}
	end

	return DebugVisualizer.render(self.container, payload)
end

function Debug:getTraces()
	return self.traces
end

return Debug
