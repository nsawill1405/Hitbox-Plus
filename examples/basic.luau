local Packages = game:GetService('ReplicatedStorage'):WaitForChild('Packages')
local HitboxPlus = require(Packages:WaitForChild('HitboxPlus'))

local server = HitboxPlus.Server.create({
	history = {
		retentionSeconds = 0.25,
	},
	validation = {
		maxLatencySeconds = 0.2,
		maxDistance = 14,
	},
})

server:pushSnapshot({
	timestamp = 12.0,
	entities = {
		{ id = 'enemy-a', position = Vector3.new(4, 0, 0), radius = 2, team = 'Red' },
	},
})

local client = HitboxPlus.Client.create({})
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

local result = server:resolve(request)
print(result.hits[1] and result.hits[1].id)
