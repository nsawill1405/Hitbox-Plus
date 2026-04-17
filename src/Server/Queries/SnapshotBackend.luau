local Process = nil

do
	local ok, loaded = pcall(require, '@lune/process')
	if ok then
		Process = loaded
	end
end

local function loadShared(moduleName, relativePath)
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.Parent.Parent.Shared[moduleName])
	end

	return require(string.format('%s%s', Process.cwd, relativePath))
end

local SpatialMath = loadShared('SpatialMath', 'src/Shared/SpatialMath.luau')

local SnapshotBackend = {}

local function sortCandidates(candidates)
	table.sort(candidates, function(left, right)
		return left.distance < right.distance
	end)
end

local function clampCandidates(candidates, maxTargets)
	sortCandidates(candidates)

	local limited = {}
	for index, candidate in candidates do
		if index > maxTargets then
			break
		end

		table.insert(limited, candidate.entity)
	end

	return limited
end

local function gatherRadius(query, snapshot)
	local matches = {}

	for _, entity in snapshot.entities or {} do
		local distance = SpatialMath.distance(entity.position, query.position)
		local combinedRadius = query.radius + SpatialMath.entityRadius(entity)
		if distance <= combinedRadius then
			table.insert(matches, {
				entity = entity,
				distance = distance,
			})
		end
	end

	return clampCandidates(matches, query.maxTargets)
end

local function gatherBox(query, snapshot)
	local matches = {}
	local queryCenterPosition = query.center.Position

	for _, entity in snapshot.entities or {} do
		local expansion = SpatialMath.entityExtents(entity)
		if SpatialMath.pointInExpandedBox(entity.position, query.center, query.size, expansion) then
			table.insert(matches, {
				entity = entity,
				distance = SpatialMath.distance(entity.position, queryCenterPosition),
			})
		end
	end

	return clampCandidates(matches, query.maxTargets)
end

local function gatherCast(query, snapshot)
	local matches = {}
	local castEnd = query.origin + query.directionUnit * query.length

	for _, entity in snapshot.entities or {} do
		local distance, t = SpatialMath.segmentDistance(entity.position, query.origin, castEnd)
		local combinedRadius = query.radius + SpatialMath.entityRadius(entity)

		if distance <= combinedRadius then
			table.insert(matches, {
				entity = entity,
				distance = t * query.length,
			})
		end
	end

	return clampCandidates(matches, query.maxTargets)
end

function SnapshotBackend.execute(query, snapshot)
	if query.type == 'radius' then
		return gatherRadius(query, snapshot)
	end

	if query.type == 'box' then
		return gatherBox(query, snapshot)
	end

	if query.type == 'cast' then
		return gatherCast(query, snapshot)
	end

	error(string.format('unsupported query type %s', tostring(query.type)))
end

return SnapshotBackend
