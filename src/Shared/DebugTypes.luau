local function loadRobloxCompat()
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.RobloxCompat)
	end

	return require('./RobloxCompat.luau')
end

local RobloxCompat = loadRobloxCompat()
local Color3 = RobloxCompat.Color3
local Vector3 = RobloxCompat.Vector3

local DEFAULT_LIFETIME_SECONDS = 0.2
local DEFAULT_PALETTE = {
	query = Color3.fromRGB(0, 170, 255),
	hit = Color3.fromRGB(0, 255, 0),
	reject = Color3.fromRGB(255, 80, 80),
}

local DebugTypes = {}

local function normalizePalette(palette)
	return {
		query = palette and palette.query or DEFAULT_PALETTE.query,
		hit = palette and palette.hit or DEFAULT_PALETTE.hit,
		reject = palette and palette.reject or DEFAULT_PALETTE.reject,
	}
end

local function normalizeDirection(direction, length)
	if length == 0 or direction.Magnitude == 0 then
		return RobloxCompat.Vector3.zero
	end

	return direction.Unit
end

function DebugTypes.shapeFromQuery(query)
	assert(type(query) == 'table', 'query must be a table')

	if query.type == 'box' then
		return {
			kind = 'box',
			cframe = query.center,
			size = query.size,
		}
	end

	if query.type == 'radius' then
		return {
			kind = 'radius',
			position = query.position,
			radius = query.radius,
		}
	end

	if query.type == 'cast' then
		local length = query.length or (query.direction and query.direction.Magnitude) or 0
		return {
			kind = 'cast',
			origin = query.origin,
			direction = query.direction,
			directionUnit = query.directionUnit or normalizeDirection(query.direction, length),
			length = length,
			radius = query.radius or 0,
		}
	end

	error(string.format('unsupported debug query type %s', tostring(query.type)))
end

function DebugTypes.createPayload(data)
	assert(type(data) == 'table', 'data must be a table')

	local payload = {
		attackId = data.attackId,
		mode = data.mode,
		timestamp = data.timestamp,
		lifetimeSeconds = data.lifetimeSeconds or DEFAULT_LIFETIME_SECONDS,
		query = data.query,
		shape = DebugTypes.shapeFromQuery(data.query),
		hits = data.hits or {},
		rejections = data.rejections or {},
		palette = normalizePalette(data.palette),
	}

	payload.queryType = payload.shape.kind

	return payload
end

return DebugTypes
