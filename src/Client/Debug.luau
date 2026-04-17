local Debug = {}
Debug.__index = Debug

function Debug.create(config)
	local debugConfig = config.debug or {}

	return setmetatable({
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

function Debug:getTraces()
	return self.traces
end

return Debug
