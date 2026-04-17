return function(loadModule)
	local Roblox = require('@lune/roblox')
	local CFrame = Roblox.CFrame
	local Color3 = Roblox.Color3
	local Instance = Roblox.Instance
	local Vector3 = Roblox.Vector3

	local function expect(condition, message)
		assert(condition, message or 'debug expectation failed')
	end

	local DebugTypes = loadModule('src/Shared/DebugTypes.luau')
	local DebugVisualizer = loadModule('src/Shared/DebugVisualizer.luau')

	local payload = DebugTypes.createPayload({
		attackId = 'swing-1',
		mode = 'both',
		timestamp = 12,
		lifetimeSeconds = 0.2,
		query = {
			type = 'box',
			center = CFrame.new(0, 3, 0),
			size = Vector3.new(6, 4, 8),
		},
		hits = {
			{ id = 'enemy-a', entity = { id = 'enemy-a', position = Vector3.new(2, 3, 0) } },
		},
		rejections = {
			{ id = 'ally-a', entity = { id = 'ally-a', position = Vector3.new(-2, 3, 0) }, reason = 'same-team' },
		},
		palette = {
			query = Color3.fromRGB(0, 170, 255),
			hit = Color3.fromRGB(0, 255, 0),
			reject = Color3.fromRGB(255, 80, 80),
		},
	})

	expect(payload.shape.kind == 'box', 'shape should normalize from query type')
	expect(payload.shape.cframe == CFrame.new(0, 3, 0), 'box shape should expose cframe')
	expect(payload.mode == 'both', 'mode should be preserved')
	expect(payload.hits[1].id == 'enemy-a', 'hits should be preserved')

	local container = Instance.new('Folder')
	container.Name = 'DebugRoot'

	local created = DebugVisualizer.render(container, payload)
	expect(#created == 3, 'query volume, hit marker, and rejection marker should be created')
	expect(created[1].Name == 'HitboxPlusQuery', 'query part name should be stable')
	expect(created[1].Size == Vector3.new(6, 4, 8), 'box size should match payload')
	expect(created[2].Color == Color3.fromRGB(0, 255, 0), 'hit marker should use hit color')
	expect(created[3].Color == Color3.fromRGB(255, 80, 80), 'rejection marker should use rejection color')
end
