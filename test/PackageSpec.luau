return function(loadModule)
	local function expect(condition, message)
		assert(condition, message or 'package expectation failed')
	end

	local Roblox = require('@lune/roblox')
	local Color3 = Roblox.Color3
	local Instance = Roblox.Instance
	local Vector3 = Roblox.Vector3

	local DebugTypes = loadModule('src/Shared/DebugTypes.luau')
	local HitboxPlus = loadModule('src/init.luau')

	local localRoot = Instance.new('Folder')
	local client = HitboxPlus.Client.create({
		debug = {
			container = localRoot,
			palette = {
				query = Color3.fromRGB(255, 200, 0),
			},
		},
		timeSource = function()
			return 15.5
		end,
	})

	local payload = DebugTypes.createPayload({
		attackId = 'client-debug-1',
		mode = 'client',
		timestamp = 15.5,
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 6,
		},
		hits = {},
		rejections = {},
	})

	local created = client:renderDebugPayload(payload)
	local queryPart = localRoot:FindFirstChild('HitboxPlusQuery')

	expect(type(created) == 'table', 'client renderer should return created instances')
	expect(#created == 1, 'client renderer should return one created instance for a radius payload')
	expect(created[1] == queryPart, 'client renderer should return the created query part')
	expect(queryPart ~= nil, 'client renderer should create a local debug part')
	expect(
		queryPart.Color == Color3.fromRGB(255, 200, 0),
		'client renderer should honor the configured debug palette'
	)

	local clientWithoutContainer = HitboxPlus.Client.create({
		timeSource = function()
			return 15.5
		end,
	})

	local empty = clientWithoutContainer:renderDebugPayload(payload)

	expect(
		type(empty) == 'table',
		'client renderer without a container should still return a table'
	)
	expect(next(empty) == nil, 'client renderer without a container should return an empty table')

	local request = client:buildRequest({
		attackId = 'slash-1',
		attackerId = 'player-a',
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 6,
		},
	})

	expect(request.clientTime == 15.5)
	expect(request.query.type == 'radius')

	local trace = client:recordDebug('request-built', {
		attackId = request.attackId,
	})

	expect(trace.name == 'request-built')
	expect(trace.payload.attackId == 'slash-1')

	local prediction = client:predict({
		timestamp = 15.5,
		entities = {},
	}, request)

	expect(prediction.query.type == 'radius')
	expect(prediction.snapshotTimestamp == 15.5)

	local server = HitboxPlus.Server.create({})
	expect(type(server.resolve) == 'function')
	expect(type(server.pushSnapshot) == 'function')
end
