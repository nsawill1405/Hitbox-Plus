local function loadRobloxCompat()
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.RobloxCompat)
	end

	return require('./RobloxCompat.luau')
end

local RobloxCompat = loadRobloxCompat()

local CFrame = RobloxCompat.CFrame
local Color3 = RobloxCompat.Color3
local Enum = RobloxCompat.Enum
local Instance = RobloxCompat.Instance
local Vector3 = RobloxCompat.Vector3

local DebugVisualizer = {}

local function makePart(name, color)
	local part = Instance.new('Part')
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	if Enum ~= nil then
		part.Material = Enum.Material.Neon
	end
	part.Color = color
	return part
end

local function appendMarker(created, container, name, position, color)
	local marker = makePart(name, color)
	if Enum ~= nil then
		marker.Shape = Enum.PartType.Ball
	end
	marker.Size = Vector3.new(0.5, 0.5, 0.5)
	marker.CFrame = CFrame.new(position)
	marker.Parent = container
	table.insert(created, marker)
end

local function getCleanupScheduler(payload)
	if type(payload.cleanupScheduler) == 'function' then
		return payload.cleanupScheduler
	end

	if task ~= nil and type(task.delay) == 'function' then
		return task.delay
	end

	return nil
end

local function scheduleCleanup(created, payload)
	local lifetimeSeconds = payload.lifetimeSeconds
	if type(lifetimeSeconds) ~= 'number' or lifetimeSeconds <= 0 then
		return
	end

	local schedule = getCleanupScheduler(payload)
	if schedule == nil then
		return
	end

	for _, instance in created do
		schedule(lifetimeSeconds, function()
			if instance.Parent ~= nil then
				instance:Destroy()
			end
		end)
	end
end

local function renderShape(container, payload, created)
	local shape = payload.shape
	local queryPart = makePart('HitboxPlusQuery', payload.palette.query)

	if shape.kind == 'box' then
		queryPart.Size = shape.size
		queryPart.CFrame = shape.cframe
	elseif shape.kind == 'radius' then
		local diameter = shape.radius * 2
		if Enum ~= nil then
			queryPart.Shape = Enum.PartType.Ball
		end
		queryPart.Size = Vector3.new(diameter, diameter, diameter)
		queryPart.CFrame = CFrame.new(shape.position)
	elseif shape.kind == 'cast' then
		local diameter = shape.radius * 2
		local directionUnit = shape.directionUnit
		local length = shape.length
		local origin = shape.origin
		local target = origin + directionUnit * length
		queryPart.Size = Vector3.new(math.max(diameter, 0.05), math.max(diameter, 0.05), length)
		queryPart.CFrame = CFrame.lookAt(origin + directionUnit * (length / 2), target)
	else
		error(string.format('unsupported debug shape kind %s', tostring(shape.kind)))
	end

	queryPart.Parent = container
	table.insert(created, queryPart)
end

function DebugVisualizer.render(container, payload)
	assert(container ~= nil, 'container is required')
	assert(type(payload) == 'table', 'payload must be a table')

	local created = {}
	renderShape(container, payload, created)

	for _, hit in payload.hits do
		appendMarker(created, container, 'HitboxPlusHit', hit.entity.position, payload.palette.hit)
	end

	for _, rejection in payload.rejections do
		appendMarker(
			created,
			container,
			'HitboxPlusReject',
			rejection.entity.position,
			payload.palette.reject
		)
	end

	scheduleCleanup(created, payload)

	return created
end

return DebugVisualizer
