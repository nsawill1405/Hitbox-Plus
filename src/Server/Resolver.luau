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

local function loadServer(moduleName, relativePath)
	if script ~= nil and script.Parent ~= nil then
		if moduleName == 'Queries' then
			return require(script.Parent.Queries.init)
		end

		return require(script.Parent[moduleName])
	end

	return require(
		string.format('%ssrc/Server/%s', Process.cwd, string.gsub(relativePath, '^%./', ''))
	)
end

local Config = loadShared('Config', 'src/Shared/Config.luau')
local Queries = loadShared('Queries', 'src/Shared/Queries.luau')
local Results = loadShared('Results', 'src/Shared/Results.luau')
local Types = loadShared('Types', 'src/Shared/Types.luau')
local History = loadServer('History', './History.luau')
local DebugEmitter = loadServer('DebugEmitter', './DebugEmitter.luau')
local QueryDispatcher = loadServer('Queries', './Queries/init.luau')
local Validators = loadServer('Validators', './Validators.luau')

local Resolver = {}
Resolver.__index = Resolver

function Resolver.create(config)
	local normalizedConfig = Config.normalize(config or {})
	local source = config or {}

	return setmetatable({
		config = normalizedConfig,
		history = source.historyStore or History.create(normalizedConfig.history),
		validators = source.validators or Validators.create(normalizedConfig.validation),
		queryBackends = source.queryBackends,
		debugEmitter = source.debugEmitter or DebugEmitter.create(normalizedConfig.debug),
	}, Resolver)
end

function Resolver:pushSnapshot(snapshot)
	return self.history:push(snapshot)
end

function Resolver:resolve(request)
	assert(type(request) == 'table', 'request must be a table')
	assert(type(request.attackId) == 'string', 'request.attackId must be a string')

	local serverTime = request.serverTime or self.config.timeSource()
	local clientTime = request.clientTime or serverTime
	local normalizedQuery = Queries.normalize(request.query)

	local normalizedRequest = {
		attackId = request.attackId,
		attackerId = request.attackerId,
		attackerPosition = request.attackerPosition,
		attackerTeam = request.attackerTeam,
		serverTime = serverTime,
		clientTime = clientTime,
		query = normalizedQuery,
	}

	local requestOk, requestReason, requestMetadata =
		self.validators:validateRequest(normalizedRequest)
	if not requestOk then
		return Results.createFailure(requestReason, requestMetadata)
	end

	local snapshot = request.snapshot or self.history:getClosest(clientTime)
	if snapshot == nil then
		return Results.createFailure(Types.RejectReason.MissingSnapshot, {
			clientTime = clientTime,
		})
	end

	local candidates = QueryDispatcher.execute(normalizedQuery, snapshot, self.queryBackends)
	local hits = {}
	local rejections = {}

	for _, candidate in candidates do
		local accepted, reason, metadata =
			self.validators:validateCandidate(normalizedRequest, candidate, snapshot)
		if accepted then
			self.validators:markAccepted(normalizedRequest, candidate)
			table.insert(hits, Results.acceptHit(candidate, metadata))
		else
			table.insert(rejections, Results.rejectHit(candidate, reason, metadata))
		end
	end

	local resolution = Results.createResolution({
		query = normalizedQuery,
		hits = hits,
		rejections = rejections,
		metadata = {
			snapshotTimestamp = snapshot.timestamp,
			latencySeconds = serverTime - clientTime,
			candidateCount = #candidates,
		},
	})

	self.debugEmitter:emit(normalizedRequest, resolution)

	return resolution
end

return Resolver
