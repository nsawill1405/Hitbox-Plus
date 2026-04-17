local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local HitboxPlus = require(ReplicatedStorage:WaitForChild('HitboxPlus'))
local Remotes = ReplicatedStorage:WaitForChild('HitboxPlusSandboxRemotes')
local DebugPayload = Remotes:WaitForChild('DebugPayload')

local sandboxRoot = Workspace:FindFirstChild('HitboxPlusSandbox') or Instance.new('Folder')
sandboxRoot.Name = 'HitboxPlusSandbox'
sandboxRoot.Parent = Workspace

local debugRoot = Workspace:FindFirstChild('HitboxPlusDebug') or Instance.new('Folder')
debugRoot.Name = 'HitboxPlusDebug'
debugRoot.Parent = Workspace

local server = HitboxPlus.Server.create({
	debug = {
		enabled = true,
		mode = 'both',
		container = debugRoot,
		clientSink = function(payload)
			DebugPayload:FireAllClients(payload)
		end,
	},
})

return server
