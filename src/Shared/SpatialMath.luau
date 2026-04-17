local function loadRobloxCompat()
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.RobloxCompat)
	end

	return require('./RobloxCompat.luau')
end

local RobloxCompat = loadRobloxCompat()
local Vector3 = RobloxCompat.Vector3

local SpatialMath = {}

function SpatialMath.entityRadius(entity)
	if type(entity.radius) == 'number' then
		return entity.radius
	end

	if typeof(entity.size) == 'Vector3' then
		return entity.size.Magnitude * 0.5
	end

	return 0
end

function SpatialMath.entityExtents(entity)
	if typeof(entity.size) == 'Vector3' then
		return entity.size * 0.5
	end

	local radius = SpatialMath.entityRadius(entity)
	return Vector3.new(radius, radius, radius)
end

function SpatialMath.distance(left, right)
	return (left - right).Magnitude
end

function SpatialMath.closestPointOnSegment(point, startPosition, endPosition)
	local delta = endPosition - startPosition
	local lengthSquared = delta:Dot(delta)

	if lengthSquared == 0 then
		return startPosition, 0
	end

	local t = math.clamp((point - startPosition):Dot(delta) / lengthSquared, 0, 1)
	return startPosition + delta * t, t
end

function SpatialMath.segmentDistance(point, startPosition, endPosition)
	local closest, t = SpatialMath.closestPointOnSegment(point, startPosition, endPosition)
	return (point - closest).Magnitude, t
end

function SpatialMath.segmentIntersectsSphere(startPosition, endPosition, center, radius)
	local distance = SpatialMath.segmentDistance(center, startPosition, endPosition)
	return distance <= radius
end

function SpatialMath.pointInExpandedBox(point, center, size, expansion)
	local localPoint = center:PointToObjectSpace(point)
	local halfSize = size * 0.5 + expansion

	return math.abs(localPoint.X) <= halfSize.X
		and math.abs(localPoint.Y) <= halfSize.Y
		and math.abs(localPoint.Z) <= halfSize.Z
end

return SpatialMath
