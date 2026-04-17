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

local DebugTypes = loadShared('DebugTypes', 'src/Shared/DebugTypes.luau')
local DebugVisualizer = loadShared('DebugVisualizer', 'src/Shared/DebugVisualizer.luau')

local DebugEmitter = {}
DebugEmitter.__index = DebugEmitter

function DebugEmitter.create(config)
	local source = config or {}

	return setmetatable({
		enabled = source.enabled == true,
		mode = source.mode or 'client',
		lifetimeSeconds = source.lifetimeSeconds or 0.2,
		container = source.container,
		sharedSink = source.sharedSink,
		clientSink = source.clientSink,
		palette = source.palette,
	}, DebugEmitter)
end

function DebugEmitter:emit(request, result)
	if not self.enabled then
		return nil
	end

	local payload = DebugTypes.createPayload({
		attackId = request.attackId,
		mode = self.mode,
		timestamp = request.serverTime,
		lifetimeSeconds = self.lifetimeSeconds,
		query = request.query,
		hits = result.hits,
		rejections = result.rejections,
		palette = self.palette,
	})

	if self.mode == 'shared' or self.mode == 'both' then
		if self.container ~= nil then
			DebugVisualizer.render(self.container, payload)
		end

		if type(self.sharedSink) == 'function' then
			self.sharedSink(payload)
		end
	end

	if self.mode == 'client' or self.mode == 'both' then
		if type(self.clientSink) == 'function' then
			self.clientSink(payload)
		end
	end

	return payload
end

return DebugEmitter
