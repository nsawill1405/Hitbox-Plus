return function(loadModule)
	local Roblox = require('@lune/roblox')
	local Vector3 = Roblox.Vector3

	local History = loadModule('src/Server/History.luau')

	local closestHistory = History.create({
		retentionSeconds = 1.0,
	})

	closestHistory:push({
		timestamp = 1.0,
		entities = {
			{ id = 'enemy-a', position = Vector3.new(0, 0, 0), radius = 2 },
		},
	})

	closestHistory:push({
		timestamp = 1.2,
		entities = {
			{ id = 'enemy-a', position = Vector3.new(4, 0, 0), radius = 2 },
		},
	})

	closestHistory:push({
		timestamp = 1.7,
		entities = {
			{ id = 'enemy-a', position = Vector3.new(12, 0, 0), radius = 2 },
		},
	})

	assert(closestHistory:getClosest(1.25).timestamp == 1.2)
	assert(closestHistory:getClosest(0.8).timestamp == 1.0)
	assert(closestHistory:getClosest(2.0).timestamp == 1.7)

	local retainedHistory = History.create({
		retentionSeconds = 0.5,
	})

	retainedHistory:push({
		timestamp = 1.0,
		entities = {},
	})

	retainedHistory:push({
		timestamp = 1.2,
		entities = {},
	})

	retainedHistory:push({
		timestamp = 1.7,
		entities = {},
	})

	assert(#retainedHistory:getSnapshots() == 2)
	assert(retainedHistory:getSnapshots()[1].timestamp == 1.2)
	assert(retainedHistory:getSnapshots()[2].timestamp == 1.7)
end
