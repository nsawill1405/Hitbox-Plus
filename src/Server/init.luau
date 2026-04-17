local Process = nil

do
	local ok, loaded = pcall(require, '@lune/process')
	if ok then
		Process = loaded
	end
end

local function loadResolver()
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.Resolver)
	end

	return require(string.format('%ssrc/Server/Resolver.luau', Process.cwd))
end

local Resolver = loadResolver()

local Server = {}

function Server.create(config)
	return Resolver.create(config)
end

return Server
