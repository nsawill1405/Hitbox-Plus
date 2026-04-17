local function loadSnapshotBackend()
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.SnapshotBackend)
	end

	return require('./SnapshotBackend.luau')
end

local SnapshotBackend = loadSnapshotBackend()

local QueryDispatcher = {}

function QueryDispatcher.execute(query, snapshot, backends)
	local overrides = backends or {}
	local backend = overrides[query.type] or SnapshotBackend.execute

	return backend(query, snapshot)
end

return QueryDispatcher
