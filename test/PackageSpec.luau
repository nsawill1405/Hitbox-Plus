return function(loadModule)
	local function expect(condition, message)
		assert(condition, message or 'package expectation failed')
	end

	local Roblox = require('@lune/roblox')
	local Vector3 = Roblox.Vector3

	local HitboxPlus = loadModule('src/init.luau')

	local client = HitboxPlus.Client.create({
		timeSource = function()
			return 5.0
		end,
	})

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

	expect(request.clientTime == 5.0)
	expect(request.query.type == 'radius')

	local trace = client:recordDebug('request-built', {
		attackId = request.attackId,
	})

	expect(trace.name == 'request-built')
	expect(trace.payload.attackId == 'slash-1')

	local prediction = client:predict({
		timestamp = 5.0,
		entities = {},
	}, request)

	expect(prediction.query.type == 'radius')
	expect(prediction.snapshotTimestamp == 5.0)

	local server = HitboxPlus.Server.create({})
	expect(type(server.resolve) == 'function')
	expect(type(server.pushSnapshot) == 'function')
end
