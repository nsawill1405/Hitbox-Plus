local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local HitboxPlus = require(ReplicatedStorage:WaitForChild('HitboxPlus'))
local Remotes = ReplicatedStorage:WaitForChild('HitboxPlusSandboxRemotes')
local DebugPayload = Remotes:WaitForChild('DebugPayload')
local TriggerAttack = Remotes:WaitForChild('TriggerAttack')

local function ensureFolder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA('Folder') then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local folder = Instance.new('Folder')
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function clearChildren(instance)
	for _, child in instance:GetChildren() do
		child:Destroy()
	end
end

local sandboxRoot = ensureFolder(Workspace, 'HitboxPlusSandbox')
local debugRoot = ensureFolder(Workspace, 'HitboxPlusDebug')

local function ensurePart(parent, name, size, color, transparency)
	local part = parent:FindFirstChild(name)
	if part == nil or not part:IsA('Part') then
		if part then
			part:Destroy()
		end

		part = Instance.new('Part')
		part.Name = name
		part.Parent = parent
	end

	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.Material = Enum.Material.SmoothPlastic
	part.Size = size
	part.Color = color
	part.Transparency = transparency or 0
	return part
end

local function ensureDummy(name, color, pivot)
	local model = sandboxRoot:FindFirstChild(name)
	if model == nil or not model:IsA('Model') then
		if model then
			model:Destroy()
		end

		model = Instance.new('Model')
		model.Name = name
		model.Parent = sandboxRoot
	end

	local humanoid = model:FindFirstChildOfClass('Humanoid')
	if humanoid == nil then
		humanoid = Instance.new('Humanoid')
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Parent = model
	end

	local root = ensurePart(model, 'HumanoidRootPart', Vector3.new(2, 2, 1), color, 1)
	local torso = ensurePart(model, 'Torso', Vector3.new(2.5, 3, 1.5), color, 0)
	local head =
		ensurePart(model, 'Head', Vector3.new(2, 1.5, 1.5), Color3.fromRGB(255, 226, 190), 0)

	root.CFrame = pivot
	torso.CFrame = pivot * CFrame.new(0, 0.5, 0)
	head.CFrame = pivot * CFrame.new(0, 2.75, 0)

	model.PrimaryPart = root
	return {
		model = model,
		root = root,
	}
end

local function ensurePlatform()
	local platform = sandboxRoot:FindFirstChild('Platform')
	if platform == nil or not platform:IsA('Part') then
		if platform then
			platform:Destroy()
		end

		platform = Instance.new('Part')
		platform.Name = 'Platform'
		platform.Parent = sandboxRoot
	end

	platform.Anchored = true
	platform.CanCollide = true
	platform.Material = Enum.Material.Concrete
	platform.Color = Color3.fromRGB(70, 70, 70)
	platform.Size = Vector3.new(28, 1, 16)
	platform.CFrame = CFrame.new(0, 0.5, 0)
	return platform
end

local function buildSandbox()
	ensurePlatform()

	local attacker = ensureDummy('AttackerDummy', Color3.fromRGB(80, 170, 255), CFrame.new(0, 2, 0))
	local enemy = ensureDummy('EnemyDummy', Color3.fromRGB(255, 95, 95), CFrame.new(4, 2, 0))
	local ally = ensureDummy('AllyDummy', Color3.fromRGB(95, 255, 140), CFrame.new(-4, 2, 0))

	return {
		attacker = attacker,
		enemy = enemy,
		ally = ally,
	}
end

local server = HitboxPlus.Server.create({
	debug = {
		enabled = true,
		mode = 'both',
		container = debugRoot,
		clientSink = function(payload)
			DebugPayload:FireAllClients(payload)
		end,
	},
	validation = {
		maxLatencySeconds = 0.2,
		maxDistance = 20,
	},
})

local sandboxState = buildSandbox()

local function runAttack()
	clearChildren(debugRoot)

	local now = Workspace:GetServerTimeNow()
	server:pushSnapshot({
		timestamp = now,
		entities = {
			{
				id = 'enemy-a',
				position = sandboxState.enemy.root.Position,
				radius = 2,
				team = 'Red',
			},
			{
				id = 'ally-a',
				position = sandboxState.ally.root.Position,
				radius = 2,
				team = 'Blue',
			},
		},
	})

	local result = server:resolve({
		attackId = string.format('sandbox-%d', math.floor(os.clock() * 1000)),
		attackerId = 'sandbox-player',
		attackerPosition = sandboxState.attacker.root.Position,
		attackerTeam = 'Blue',
		serverTime = now,
		clientTime = now,
		query = {
			type = 'box',
			center = sandboxState.attacker.root.CFrame,
			size = Vector3.new(8, 6, 8),
		},
	})

	print(
		string.format('[HitboxPlusSandbox] hits=%d rejections=%d', #result.hits, #result.rejections)
	)
	return result
end

runAttack()

TriggerAttack.OnServerEvent:Connect(function()
	runAttack()
end)

return server
