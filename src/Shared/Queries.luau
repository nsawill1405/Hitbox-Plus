local function loadTypes()
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.Types)
	end

	return require('./Types.luau')
end

local Types = loadTypes()

local Queries = {}
local Roblox = nil

do
	local ok, loaded = pcall(require, '@lune/roblox')
	if ok then
		Roblox = loaded
	end
end

local function readMaxTargets(query)
	return query.maxTargets or math.huge
end

local function normalizeDirection(direction, length)
	if length == 0 then
		if Roblox ~= nil then
			return Roblox.Vector3.zero
		end

		return Vector3.zero
	end

	return direction.Unit
end

function Queries.normalize(query)
	assert(type(query) == 'table', 'query must be a table')

	if query.type == Types.QueryType.Box then
		assert(typeof(query.center) == 'CFrame', 'box queries require center')
		assert(typeof(query.size) == 'Vector3', 'box queries require size')

		return {
			type = Types.QueryType.Box,
			center = query.center,
			size = query.size,
			maxTargets = readMaxTargets(query),
			params = query.params,
			debug = query.debug,
		}
	end

	if query.type == Types.QueryType.Radius then
		assert(typeof(query.position) == 'Vector3', 'radius queries require position')
		assert(type(query.radius) == 'number', 'radius queries require radius')

		return {
			type = Types.QueryType.Radius,
			position = query.position,
			radius = query.radius,
			maxTargets = readMaxTargets(query),
			params = query.params,
			debug = query.debug,
		}
	end

	if query.type == Types.QueryType.Cast then
		assert(typeof(query.origin) == 'Vector3', 'cast queries require origin')
		assert(typeof(query.direction) == 'Vector3', 'cast queries require direction')

		local length = query.length or query.direction.Magnitude

		return {
			type = Types.QueryType.Cast,
			origin = query.origin,
			direction = query.direction,
			directionUnit = normalizeDirection(query.direction, length),
			length = length,
			radius = query.radius or 0,
			maxTargets = readMaxTargets(query),
			params = query.params,
			debug = query.debug,
		}
	end

	error(string.format('unsupported query type %s', tostring(query.type)))
end

return Queries
