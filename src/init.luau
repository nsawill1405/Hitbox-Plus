local Process = nil

do
	local ok, loaded = pcall(require, '@lune/process')
	if ok then
		Process = loaded
	end
end

local function loadChild(moduleName, relativePath)
	if script ~= nil and script.Parent ~= nil then
		if moduleName == 'Server' then
			return require(script.Parent.Server.init)
		end

		if moduleName == 'Client' then
			return require(script.Parent.Client.init)
		end
	end

	return require(string.format('%ssrc/%s', Process.cwd, relativePath))
end

local Server = loadChild('Server', 'Server/init.luau')
local Client = loadChild('Client', 'Client/init.luau')
local SharedQueries = if script ~= nil and script.Parent ~= nil
	then require(script.Parent.Shared.Queries)
	else require(string.format('%ssrc/Shared/Queries.luau', Process.cwd))

return {
	Server = Server,
	Client = Client,
	Shared = {
		Queries = SharedQueries,
	},
}
