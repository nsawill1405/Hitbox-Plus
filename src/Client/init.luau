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

local function loadClient(moduleName, relativePath)
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent[moduleName])
	end

	return require(
		string.format('%ssrc/Client/%s', Process.cwd, string.gsub(relativePath, '^%./', ''))
	)
end

local Config = loadShared('Config', 'src/Shared/Config.luau')
local Requests = loadClient('Requests', './Requests.luau')
local Prediction = loadClient('Prediction', './Prediction.luau')
local Debug = loadClient('Debug', './Debug.luau')

local Client = {}
Client.__index = Client

function Client.create(config)
	local normalizedConfig = Config.normalize(config or {})

	return setmetatable({
		config = normalizedConfig,
		debugger = Debug.create(normalizedConfig),
	}, Client)
end

function Client:buildRequest(payload)
	return Requests.build(self.config, payload)
end

function Client:predict(snapshot, request)
	return Prediction.predict(self.config, snapshot, request)
end

function Client:recordDebug(name, payload)
	return self.debugger:record(name, payload)
end

function Client:renderDebugPayload(payload)
	return self.debugger:render(payload)
end

return Client
