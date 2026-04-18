local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local HitboxPlus = require(ReplicatedStorage:WaitForChild('HitboxPlus'))
local Remotes = ReplicatedStorage:WaitForChild('HitboxPlusSandboxRemotes')
local DebugPayload = Remotes:WaitForChild('DebugPayload')
local TriggerAttack = Remotes:WaitForChild('TriggerAttack')

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

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.F then
		TriggerAttack:FireServer()
	end
end)

print('[HitboxPlusClientExample] Press F to retrigger the sandbox hitbox.')

return client
