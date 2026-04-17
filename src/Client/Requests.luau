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

local Queries = loadShared('Queries', 'src/Shared/Queries.luau')

local Requests = {}

function Requests.build(config, payload)
	assert(type(payload) == 'table', 'payload must be a table')
	assert(type(payload.attackId) == 'string', 'payload.attackId must be a string')
	assert(type(payload.attackerId) == 'string', 'payload.attackerId must be a string')

	return {
		attackId = payload.attackId,
		attackerId = payload.attackerId,
		attackerPosition = payload.attackerPosition,
		attackerTeam = payload.attackerTeam,
		clientTime = payload.clientTime or config.timeSource(),
		query = Queries.normalize(payload.query),
		metadata = payload.metadata or {},
	}
end

return Requests
