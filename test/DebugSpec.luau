return function(loadModule)
	local Roblox = require('@lune/roblox')
	local CFrame = Roblox.CFrame
	local Color3 = Roblox.Color3
	local Enum = Roblox.Enum
	local Instance = Roblox.Instance
	local Vector3 = Roblox.Vector3

	local function expect(condition, message)
		assert(condition, message or 'debug expectation failed')
	end

	local DebugTypes = loadModule('src/Shared/DebugTypes.luau')
	local DebugVisualizer = loadModule('src/Shared/DebugVisualizer.luau')

	local function makeContainer(name)
		local container = Instance.new('Folder')
		container.Name = name
		return container
	end

	local boxPayload = DebugTypes.createPayload({
		attackId = 'swing-1',
		mode = 'both',
		timestamp = 12,
		query = {
			type = 'box',
			center = CFrame.new(0, 3, 0),
			size = Vector3.new(6, 4, 8),
		},
		hits = {
			{ id = 'enemy-a', entity = { id = 'enemy-a', position = Vector3.new(2, 3, 0) } },
		},
		rejections = {
			{
				id = 'ally-a',
				entity = { id = 'ally-a', position = Vector3.new(-2, 3, 0) },
				reason = 'same-team',
			},
		},
	})

	expect(boxPayload.shape.kind == 'box', 'shape should normalize from query type')
	expect(boxPayload.queryType == 'box', 'queryType should mirror the normalized shape kind')
	expect(boxPayload.shape.cframe == CFrame.new(0, 3, 0), 'box shape should expose cframe')
	expect(boxPayload.mode == 'both', 'mode should be preserved')
	expect(boxPayload.hits[1].id == 'enemy-a', 'hits should be preserved')
	expect(boxPayload.lifetimeSeconds == 0.2, 'default lifetime should match the task default')
	expect(
		boxPayload.palette.query == Color3.fromRGB(0, 170, 255),
		'default query palette should be normalized'
	)
	expect(
		boxPayload.palette.hit == Color3.fromRGB(0, 255, 0),
		'default hit palette should be normalized'
	)
	expect(
		boxPayload.palette.reject == Color3.fromRGB(255, 80, 80),
		'default reject palette should be normalized'
	)

	local created = DebugVisualizer.render(makeContainer('BoxRoot'), boxPayload)
	expect(#created == 3, 'query volume, hit marker, and rejection marker should be created')
	expect(created[1].Name == 'HitboxPlusQuery', 'query part name should be stable')
	expect(created[1].Size == Vector3.new(6, 4, 8), 'box size should match payload')
	expect(created[2].Color == Color3.fromRGB(0, 255, 0), 'hit marker should use hit color')
	expect(
		created[3].Color == Color3.fromRGB(255, 80, 80),
		'rejection marker should use rejection color'
	)

	local cleanupPayload = DebugTypes.createPayload({
		attackId = 'cleanup-1',
		mode = 'shared',
		timestamp = 20,
		lifetimeSeconds = 0.4,
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 3,
		},
	})

	local cleanupContainer = makeContainer('CleanupRoot')
	local scheduled = {}
	cleanupPayload.cleanupScheduler = function(delaySeconds, callback)
		table.insert(scheduled, {
			delaySeconds = delaySeconds,
			callback = callback,
		})
	end

	local cleanupCreated = DebugVisualizer.render(cleanupContainer, cleanupPayload)
	expect(#cleanupCreated == 1, 'cleanup probe should render one query part')
	expect(#scheduled == #cleanupCreated, 'each created part should schedule its own cleanup')
	expect(scheduled[1].delaySeconds == 0.4, 'cleanup should honor payload lifetimeSeconds')

	for _, scheduledEntry in scheduled do
		scheduledEntry.callback()
	end

	expect(#cleanupContainer:GetChildren() == 0, 'scheduled cleanup should destroy rendered parts')

	local radiusPayload = DebugTypes.createPayload({
		attackId = 'pulse-1',
		mode = 'query',
		timestamp = 15,
		query = {
			type = 'radius',
			position = Vector3.new(1, 2, 3),
			radius = 2.5,
		},
	})

	expect(radiusPayload.shape.kind == 'radius', 'radius queries should normalize to radius shapes')
	expect(
		radiusPayload.queryType == 'radius',
		'radius queryType should mirror the normalized shape kind'
	)

	local radiusCreated = DebugVisualizer.render(makeContainer('RadiusRoot'), radiusPayload)
	expect(
		#radiusCreated == 1,
		'radius rendering should only create the query volume when there are no hits'
	)
	expect(radiusCreated[1].Shape == Enum.PartType.Ball, 'radius query should render as a ball')
	expect(
		radiusCreated[1].Size == Vector3.new(5, 5, 5),
		'radius query size should use the diameter'
	)
	expect(
		radiusCreated[1].CFrame == CFrame.new(1, 2, 3),
		'radius query should be centered at the query position'
	)

	local castPayload = DebugTypes.createPayload({
		attackId = 'beam-1',
		mode = 'query',
		timestamp = 18,
		query = {
			type = 'cast',
			origin = Vector3.new(0, 0, 0),
			direction = Vector3.new(0, 0, 10),
			radius = 1.5,
		},
	})

	expect(castPayload.shape.kind == 'cast', 'cast queries should normalize to cast shapes')
	expect(
		castPayload.queryType == 'cast',
		'cast queryType should mirror the normalized shape kind'
	)
	expect(
		castPayload.shape.length == 10,
		'cast length should default from the direction magnitude'
	)

	local castCreated = DebugVisualizer.render(makeContainer('CastRoot'), castPayload)
	expect(
		#castCreated == 1,
		'cast rendering should only create the query volume when there are no hits'
	)
	expect(
		castCreated[1].Size == Vector3.new(3, 3, 10),
		'cast query size should use the diameter and length'
	)
	expect(
		castCreated[1].CFrame == CFrame.lookAt(Vector3.new(0, 0, 5), Vector3.new(0, 0, 10)),
		'cast query should face the target using a shared-runtime-safe constructor'
	)
end
