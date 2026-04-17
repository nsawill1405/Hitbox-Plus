return function(loadModule)
	local Roblox = require('@lune/roblox')
	local CFrame = Roblox.CFrame
	local Vector3 = Roblox.Vector3

	local Config = loadModule('src/Shared/Config.luau')
	local Queries = loadModule('src/Shared/Queries.luau')
	local Results = loadModule('src/Shared/Results.luau')

	local normalizedConfig = Config.normalize({
		history = {
			retentionSeconds = 0.35,
		},
	})

	assert(normalizedConfig.history.retentionSeconds == 0.35)
	assert(normalizedConfig.validation.maxLatencySeconds == 0.2)

	local normalizedBox = Queries.normalize({
		type = 'box',
		center = CFrame.new(0, 4, 0),
		size = Vector3.new(4, 6, 8),
	})

	assert(normalizedBox.type == 'box')
	assert(normalizedBox.center.Position == Vector3.new(0, 4, 0))
	assert(normalizedBox.maxTargets == math.huge)

	local normalizedRadius = Queries.normalize({
		type = 'radius',
		position = Vector3.new(2, 0, 0),
		radius = 9,
	})

	assert(normalizedRadius.type == 'radius')
	assert(normalizedRadius.radius == 9)

	local normalizedCast = Queries.normalize({
		type = 'cast',
		origin = Vector3.new(),
		direction = Vector3.new(0, 0, -12),
		radius = 2,
	})

	assert(normalizedCast.type == 'cast')
	assert(normalizedCast.length == 12)
	assert(normalizedCast.radius == 2)

	local resolution = Results.createResolution({
		query = normalizedRadius,
		hits = {
			Results.acceptHit({
				id = 'enemy-a',
			}, {
				distance = 4,
			}),
		},
		rejections = {
			Results.rejectHit({
				id = 'ally-a',
			}, 'same-team'),
		},
	})

	assert(resolution.ok == true)
	assert(#resolution.hits == 1)
	assert(resolution.rejections[1].reason == 'same-team')
end
