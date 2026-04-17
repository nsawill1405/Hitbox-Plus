return function(loadModule)
	local function expect(condition, message)
		assert(condition, message or 'resolver expectation failed')
	end

	local Roblox = require('@lune/roblox')
	local CFrame = Roblox.CFrame
	local Vector3 = Roblox.Vector3

	local Resolver = loadModule('src/Server/Resolver.luau')

	local baseResolver = Resolver.create({
		validation = {
			maxLatencySeconds = 0.2,
			maxDistance = 20,
		},
	})

	baseResolver:pushSnapshot({
		timestamp = 9.92,
		entities = {
			{ id = 'enemy-a', position = Vector3.new(4, 0, 0), radius = 2, team = 'Red' },
			{ id = 'ally-a', position = Vector3.new(3, 0, 0), radius = 2, team = 'Blue' },
		},
	})

	local radiusResult = baseResolver:resolve({
		attackId = 'radius-1',
		attackerId = 'player-a',
		serverTime = 10.0,
		clientTime = 9.92,
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 8,
		},
	})

	expect(radiusResult.ok == true)
	expect(#radiusResult.hits == 1)
	expect(radiusResult.hits[1].id == 'enemy-a')
	expect(#radiusResult.rejections == 1)
	expect(radiusResult.rejections[1].reason == 'same-team')

	local boxResult = baseResolver:resolve({
		attackId = 'box-1',
		attackerId = 'player-a',
		serverTime = 10.5,
		clientTime = 10.5,
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		snapshot = {
			timestamp = 10.5,
			entities = {
				{
					id = 'enemy-box',
					position = Vector3.new(2, 0, 0),
					size = Vector3.new(2, 2, 2),
					team = 'Red',
				},
				{
					id = 'enemy-miss',
					position = Vector3.new(12, 0, 0),
					size = Vector3.new(2, 2, 2),
					team = 'Red',
				},
			},
		},
		query = {
			type = 'box',
			center = CFrame.new(0, 0, 0),
			size = Vector3.new(8, 8, 8),
		},
	})

	expect(#boxResult.hits == 1)
	expect(boxResult.hits[1].id == 'enemy-box')

	local castResult = baseResolver:resolve({
		attackId = 'cast-1',
		attackerId = 'player-a',
		serverTime = 11.0,
		clientTime = 11.0,
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		snapshot = {
			timestamp = 11.0,
			entities = {
				{ id = 'enemy-cast', position = Vector3.new(0, 0, -10), radius = 2, team = 'Red' },
				{
					id = 'enemy-cast-miss',
					position = Vector3.new(5, 0, -10),
					radius = 1,
					team = 'Red',
				},
			},
		},
		query = {
			type = 'cast',
			origin = Vector3.new(0, 0, 0),
			direction = Vector3.new(0, 0, -20),
			radius = 1,
		},
	})

	expect(#castResult.hits == 1)
	expect(castResult.hits[1].id == 'enemy-cast')

	local statefulResolver = Resolver.create({
		validation = {
			maxLatencySeconds = 0.2,
			maxDistance = 20,
			duplicateWindowSeconds = 0.2,
			targetCooldownSeconds = 0.5,
		},
	})

	local statefulSnapshot = {
		timestamp = 20.0,
		entities = {
			{ id = 'enemy-repeat', position = Vector3.new(4, 0, 0), radius = 1, team = 'Red' },
		},
	}

	local firstHit = statefulResolver:resolve({
		attackId = 'stateful-1',
		attackerId = 'player-a',
		serverTime = 20.0,
		clientTime = 20.0,
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		snapshot = statefulSnapshot,
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 8,
		},
	})

	expect(#firstHit.hits == 1)

	local duplicateAttack = statefulResolver:resolve({
		attackId = 'stateful-1',
		attackerId = 'player-a',
		serverTime = 20.05,
		clientTime = 20.0,
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		snapshot = statefulSnapshot,
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 8,
		},
	})

	expect(duplicateAttack.ok == false)
	expect(duplicateAttack.reason == 'duplicate-attack')

	local cooldownReject = statefulResolver:resolve({
		attackId = 'stateful-2',
		attackerId = 'player-a',
		serverTime = 20.1,
		clientTime = 20.1,
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		snapshot = statefulSnapshot,
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 8,
		},
	})

	expect(#cooldownReject.hits == 0)
	expect(#cooldownReject.rejections == 1)
	expect(cooldownReject.rejections[1].reason == 'target-cooldown')

	local lineOfSightResolver = Resolver.create({
		validation = {
			maxLatencySeconds = 0.2,
			maxDistance = 20,
			lineOfSight = true,
		},
	})

	local blocked = lineOfSightResolver:resolve({
		attackId = 'los-1',
		attackerId = 'player-a',
		serverTime = 30.0,
		clientTime = 30.0,
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		snapshot = {
			timestamp = 30.0,
			entities = {
				{ id = 'enemy-los', position = Vector3.new(8, 0, 0), radius = 1, team = 'Red' },
			},
			occluders = {
				{ position = Vector3.new(4, 0, 0), radius = 1.5 },
			},
		},
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 10,
		},
	})

	expect(#blocked.hits == 0)
	expect(#blocked.rejections == 1)
	expect(blocked.rejections[1].reason == 'line-of-sight')

	local stale = baseResolver:resolve({
		attackId = 'stale-1',
		attackerId = 'player-a',
		serverTime = 40.0,
		clientTime = 39.4,
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		snapshot = {
			timestamp = 39.4,
			entities = {},
		},
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 8,
		},
	})

	expect(stale.ok == false)
	expect(stale.reason == 'max-latency')

	local Color3 = Roblox.Color3
	local Instance = Roblox.Instance
	local sharedRoot = Instance.new('Folder')
	local sharedResolver = Resolver.create({
		debug = {
			enabled = true,
			mode = 'shared',
			lifetimeSeconds = 0.2,
			container = sharedRoot,
			palette = {
				query = Color3.fromRGB(0, 170, 255),
				hit = Color3.fromRGB(0, 255, 0),
				reject = Color3.fromRGB(255, 80, 80),
			},
		},
		validation = {
			maxLatencySeconds = 0.2,
			maxDistance = 20,
		},
	})

	sharedResolver:pushSnapshot({
		timestamp = 10,
		entities = {
			{ id = 'enemy-a', position = Vector3.new(4, 0, 0), radius = 2, team = 'Red' },
		},
	})

	local sharedResult = sharedResolver:resolve({
		attackId = 'debug-radius-1',
		attackerId = 'player-a',
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		serverTime = 10,
		clientTime = 10,
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 8,
		},
	})

	expect(sharedResult.ok == true, 'resolver should still resolve normally')
	expect(sharedRoot:FindFirstChild('HitboxPlusQuery') ~= nil, 'shared debug volume should be rendered')

	local DebugEmitter = loadModule('src/Server/DebugEmitter.luau')
	local debugRequest = {
		attackId = 'debug-radius-2',
		serverTime = 50,
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 8,
		},
	}
	local debugResult = {
		hits = {
			{
				entity = {
					position = Vector3.new(4, 0, 0),
				},
			},
		},
		rejections = {},
	}

	local disabledRoot = Instance.new('Folder')
	local disabledEmitter = DebugEmitter.create({
		enabled = false,
		mode = 'shared',
		container = disabledRoot,
		sharedSink = function()
			error('disabled emitter should not invoke sinks')
		end,
	})
	local disabledPayload = disabledEmitter:emit(debugRequest, debugResult)

	expect(disabledPayload == nil, 'disabled emitter should not emit a payload')
	expect(disabledRoot:FindFirstChild('HitboxPlusQuery') == nil, 'disabled emitter should not render shared debug')

	local sharedPayload
	local sharedSinkEmitter = DebugEmitter.create({
		enabled = true,
		mode = 'shared',
		container = Instance.new('Folder'),
		sharedSink = function(payload)
			sharedPayload = payload
		end,
	})

	sharedSinkEmitter:emit(debugRequest, debugResult)

	expect(sharedPayload ~= nil, 'shared sink should receive a payload')
	expect(sharedPayload.attackId == 'debug-radius-2', 'shared sink payload should include attackId')
	expect(sharedPayload.queryType == 'radius', 'shared sink payload should include normalized query type')

	local clientPayload
	local clientSinkEmitter = DebugEmitter.create({
		enabled = true,
		mode = 'client',
		clientSink = function(payload)
			clientPayload = payload
		end,
	})

	clientSinkEmitter:emit(debugRequest, debugResult)

	expect(clientPayload ~= nil, 'client sink should receive a payload')
	expect(clientPayload.attackId == 'debug-radius-2', 'client sink payload should include attackId')
	expect(clientPayload.shape ~= nil and clientPayload.shape.kind == 'radius', 'client sink payload should include normalized shape')

	local bothSharedPayload
	local bothClientPayload
	local bothEmitter = DebugEmitter.create({
		enabled = true,
		mode = 'both',
		container = Instance.new('Folder'),
		sharedSink = function(payload)
			bothSharedPayload = payload
		end,
		clientSink = function(payload)
			bothClientPayload = payload
		end,
	})

	bothEmitter:emit(debugRequest, debugResult)

	expect(bothSharedPayload ~= nil, 'both mode should drive the shared sink')
	expect(bothClientPayload ~= nil, 'both mode should drive the client sink')

	local guardedEmitter = DebugEmitter.create({
		enabled = true,
		mode = 'both',
		container = Instance.new('Folder'),
		sharedSink = {},
		clientSink = {},
	})

	local guardedOk = pcall(function()
		guardedEmitter:emit(debugRequest, debugResult)
	end)

	expect(guardedOk == true, 'non-function sinks should be ignored safely')

	local normalizedPayload
	local normalizedResolver = Resolver.create({
		debugEmitter = DebugEmitter.create({
			enabled = true,
			mode = 'shared',
			container = Instance.new('Folder'),
			sharedSink = function(payload)
				normalizedPayload = payload
			end,
		}),
		validation = {
			maxLatencySeconds = 0.2,
			maxDistance = 20,
		},
	})

	normalizedResolver:pushSnapshot({
		timestamp = 51,
		entities = {
			{ id = 'enemy-debug', position = Vector3.new(4, 0, 0), radius = 2, team = 'Red' },
		},
	})

	normalizedResolver:resolve({
		attackId = 'debug-radius-3',
		attackerId = 'player-a',
		attackerPosition = Vector3.new(0, 0, 0),
		attackerTeam = 'Blue',
		serverTime = 51,
		clientTime = 51,
		query = {
			type = 'radius',
			position = Vector3.new(0, 0, 0),
			radius = 8,
		},
	})

	expect(normalizedPayload ~= nil, 'resolver should emit a debug payload')
	expect(normalizedPayload.attackId == 'debug-radius-3', 'resolver payload should preserve attackId')
	expect(normalizedPayload.queryType == 'radius', 'resolver payload should be normalized')
	expect(normalizedPayload.shape ~= nil and normalizedPayload.shape.kind == 'radius', 'resolver payload should include normalized shape')
end
