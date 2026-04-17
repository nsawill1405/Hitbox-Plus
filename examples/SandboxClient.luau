local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local HitboxPlus = require(ReplicatedStorage:WaitForChild('HitboxPlus'))
local Remotes = ReplicatedStorage:WaitForChild('HitboxPlusSandboxRemotes')
local DebugPayload = Remotes:WaitForChild('DebugPayload')

local localRoot = Workspace:FindFirstChild('HitboxPlusClientDebug') or Instance.new('Folder')
localRoot.Name = 'HitboxPlusClientDebug'
localRoot.Parent = Workspace

local client = HitboxPlus.Client.create({
	debug = {
		container = localRoot,
	},
})

DebugPayload.OnClientEvent:Connect(function(payload)
	client:renderDebugPayload(payload)
end)

return client
