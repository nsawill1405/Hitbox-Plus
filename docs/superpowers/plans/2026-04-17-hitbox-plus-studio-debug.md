# Hitbox Plus Studio Debug Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add library-backed debug visualization, a character-driven Studio sandbox demo, and a push-safe Git email fix for Hitbox Plus.

**Architecture:** Extend the existing runtime with normalized debug payload emission and shared rendering primitives, then wire those payloads through a server debug emitter and a client-side renderer. Keep the playable sandbox in Studio-owned scripts and remotes so the core package remains transport-agnostic and reusable.

**Tech Stack:** Luau, Roblox Studio MCP, Lune, Stylua, Selene, Git, GitHub CLI

---

## Planned File Structure

- `src/Shared/DebugTypes.luau`: normalized debug payload helpers and query-to-shape conversion
- `src/Shared/DebugVisualizer.luau`: shape rendering helpers for box, radius, and cast payloads
- `src/Shared/RobloxCompat.luau`: extend compatibility exports for `Instance`, `Color3`, and `Enum`
- `src/Shared/Config.luau`: add debug defaults (`enabled`, `mode`, `lifetimeSeconds`, color palette)
- `src/Client/Debug.luau`: local payload renderer plus trace sink
- `src/Client/init.luau`: expose a `renderDebugPayload` entrypoint
- `src/Server/DebugEmitter.luau`: route payloads to shared/client sinks
- `src/Server/Resolver.luau`: emit debug payloads from real resolver state when enabled
- `test/DebugSpec.luau`: payload and visualizer tests
- `test/ResolverSpec.luau`: emitter routing and resolver emission tests
- `test/PackageSpec.luau`: client debug API tests
- `test/ToolingSpec.luau`: require new example file coverage
- `test/run.luau`: include the new debug test file
- `examples/SandboxServer.luau`: server-side sandbox script source of truth
- `examples/SandboxClient.luau`: client-side sandbox script source of truth
- `README.md`: document debug modes and sandbox usage
- `game.ReplicatedStorage.HitboxPlus.*`: Studio mirror of runtime modules
- `game.ReplicatedStorage.HitboxPlusSandboxRemotes`: Studio demo remotes
- `game.ServerScriptService.HitboxPlusSandbox`: Studio autorun + retrigger sandbox
- `game.StarterPlayer.StarterPlayerScripts.HitboxPlusClientExample`: Studio local debug renderer and retrigger input

### Task 1: Add Shared Debug Payload And Visualization Primitives

**Files:**
- Create: `src/Shared/DebugTypes.luau`
- Create: `src/Shared/DebugVisualizer.luau`
- Modify: `src/Shared/RobloxCompat.luau`
- Modify: `test/run.luau`
- Test: `test/DebugSpec.luau`

- [ ] **Step 1: Write the failing test**

```luau
return function(loadModule)
	local Roblox = require('@lune/roblox')
	local CFrame = Roblox.CFrame
	local Color3 = Roblox.Color3
	local Instance = Roblox.Instance
	local Vector3 = Roblox.Vector3

	local function expect(condition, message)
		assert(condition, message or 'debug expectation failed')
	end

	local DebugTypes = loadModule('src/Shared/DebugTypes.luau')
	local DebugVisualizer = loadModule('src/Shared/DebugVisualizer.luau')

	local payload = DebugTypes.createPayload({
		attackId = 'swing-1',
		mode = 'both',
		timestamp = 12,
		lifetimeSeconds = 0.2,
		query = {
			type = 'box',
			center = CFrame.new(0, 3, 0),
			size = Vector3.new(6, 4, 8),
		},
		hits = {
			{ id = 'enemy-a', entity = { id = 'enemy-a', position = Vector3.new(2, 3, 0) } },
		},
		rejections = {
			{ id = 'ally-a', entity = { id = 'ally-a', position = Vector3.new(-2, 3, 0) }, reason = 'same-team' },
		},
		palette = {
			query = Color3.fromRGB(0, 170, 255),
			hit = Color3.fromRGB(0, 255, 0),
			reject = Color3.fromRGB(255, 80, 80),
		},
	})

	expect(payload.shape.kind == 'box', 'shape should normalize from query type')
	expect(payload.mode == 'both', 'mode should be preserved')
	expect(payload.hits[1].id == 'enemy-a', 'hits should be preserved')

	local container = Instance.new('Folder')
	container.Name = 'DebugRoot'

	local created = DebugVisualizer.render(container, payload)
	expect(#created == 3, 'query volume, hit marker, and rejection marker should be created')
	expect(created[1].Name == 'HitboxPlusQuery', 'query part name should be stable')
	expect(created[1].Size == Vector3.new(6, 4, 8), 'box size should match payload')
	expect(created[2].Color == Color3.fromRGB(0, 255, 0), 'hit marker should use hit color')
	expect(created[3].Color == Color3.fromRGB(255, 80, 80), 'rejection marker should use rejection color')
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lune run test/run.luau DebugSpec`
Expected: FAIL because `src/Shared/DebugTypes.luau` and `src/Shared/DebugVisualizer.luau` do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```luau
-- src/Shared/DebugTypes.luau
local function loadRobloxCompat()
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.RobloxCompat)
	end

	return require('./RobloxCompat.luau')
end

local RobloxCompat = loadRobloxCompat()
local Color3 = RobloxCompat.Color3

local DebugTypes = {}

function DebugTypes.shapeFromQuery(query)
	if query.type == 'box' then
		return {
			kind = 'box',
			cframe = query.center,
			size = query.size,
		}
	end

	if query.type == 'radius' then
		return {
			kind = 'radius',
			position = query.position,
			radius = query.radius,
		}
	end

	if query.type == 'cast' then
		return {
			kind = 'cast',
			origin = query.origin,
			directionUnit = query.directionUnit,
			length = query.length,
			radius = query.radius,
		}
	end

	error(string.format('unsupported debug query %s', tostring(query.type)))
end

function DebugTypes.createPayload(data)
	return {
		attackId = data.attackId,
		mode = data.mode,
		timestamp = data.timestamp,
		lifetimeSeconds = data.lifetimeSeconds or 0.2,
		queryType = data.query.type,
		shape = DebugTypes.shapeFromQuery(data.query),
		hits = data.hits or {},
		rejections = data.rejections or {},
		palette = data.palette or {
			query = Color3.fromRGB(0, 170, 255),
			hit = Color3.fromRGB(0, 255, 0),
			reject = Color3.fromRGB(255, 80, 80),
		},
	}
end

return DebugTypes
```

```luau
-- src/Shared/DebugVisualizer.luau
local function loadRobloxCompat()
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.RobloxCompat)
	end

	return require('./RobloxCompat.luau')
end

local RobloxCompat = loadRobloxCompat()
local CFrame = RobloxCompat.CFrame
local Instance = RobloxCompat.Instance
local Vector3 = RobloxCompat.Vector3

local DebugVisualizer = {}

local function newMarker(name, color)
	local marker = Instance.new('Part')
	marker.Name = name
	marker.Anchored = true
	marker.CanCollide = false
	marker.Material = Enum.Material.ForceField
	marker.Transparency = 0.45
	marker.Color = color
	return marker
end

local function renderQuery(payload)
	local part = newMarker('HitboxPlusQuery', payload.palette.query)

	if payload.shape.kind == 'box' then
		part.Size = payload.shape.size
		part.CFrame = payload.shape.cframe
	elseif payload.shape.kind == 'radius' then
		local diameter = payload.shape.radius * 2
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(diameter, diameter, diameter)
		part.CFrame = CFrame.new(payload.shape.position)
	elseif payload.shape.kind == 'cast' then
		local diameter = math.max(payload.shape.radius * 2, 0.2)
		part.Size = Vector3.new(diameter, diameter, payload.shape.length)
		part.CFrame = CFrame.lookAt(payload.shape.origin, payload.shape.origin + payload.shape.directionUnit)
			* CFrame.new(0, 0, -payload.shape.length / 2)
	end

	return part
end

function DebugVisualizer.render(container, payload)
	local created = {}

	local queryPart = renderQuery(payload)
	queryPart.Parent = container
	table.insert(created, queryPart)

	for _, hit in payload.hits do
		local marker = newMarker('HitboxPlusHit', payload.palette.hit)
		marker.Shape = Enum.PartType.Ball
		marker.Size = Vector3.new(1, 1, 1)
		marker.CFrame = CFrame.new(hit.entity.position)
		marker.Parent = container
		table.insert(created, marker)
	end

	for _, rejection in payload.rejections do
		local marker = newMarker('HitboxPlusReject', payload.palette.reject)
		marker.Shape = Enum.PartType.Ball
		marker.Size = Vector3.new(1, 1, 1)
		marker.CFrame = CFrame.new(rejection.entity.position)
		marker.Parent = container
		table.insert(created, marker)
	end

	return created
end

return DebugVisualizer
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lune run test/run.luau DebugSpec`
Expected: PASS with the normalized payload and 3 created debug parts.

- [ ] **Step 5: Commit**

```bash
git add src/Shared/DebugTypes.luau src/Shared/DebugVisualizer.luau src/Shared/RobloxCompat.luau test/DebugSpec.luau test/run.luau
git commit -m "feat: add shared debug visualization primitives"
```

### Task 2: Emit Resolver Debug Payloads And Shared Rendering

**Files:**
- Create: `src/Server/DebugEmitter.luau`
- Modify: `src/Shared/Config.luau`
- Modify: `src/Server/Resolver.luau`
- Test: `test/ResolverSpec.luau`

- [ ] **Step 1: Write the failing test**

```luau
local Roblox = require('@lune/roblox')
local Color3 = Roblox.Color3
local Instance = Roblox.Instance
local Vector3 = Roblox.Vector3

local Resolver = loadModule('src/Server/Resolver.luau')

local sharedRoot = Instance.new('Folder')
local resolver = Resolver.create({
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

resolver:pushSnapshot({
	timestamp = 10,
	entities = {
		{ id = 'enemy-a', position = Vector3.new(4, 0, 0), radius = 2, team = 'Red' },
	},
})

local result = resolver:resolve({
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

expect(result.ok == true, 'resolver should still resolve normally')
expect(sharedRoot:FindFirstChild('HitboxPlusQuery') ~= nil, 'shared debug volume should be rendered')
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lune run test/run.luau ResolverSpec`
Expected: FAIL because `Resolver.create` does not yet know about `debug.enabled`, `debug.mode`, or a shared debug emitter.

- [ ] **Step 3: Write minimal implementation**

```luau
-- src/Server/DebugEmitter.luau
local function loadShared(moduleName, relativePath)
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.Parent.Shared[moduleName])
	end

	return require(relativePath)
end

local DebugTypes = loadShared('DebugTypes', 'src/Shared/DebugTypes.luau')
local DebugVisualizer = loadShared('DebugVisualizer', 'src/Shared/DebugVisualizer.luau')

local DebugEmitter = {}
DebugEmitter.__index = DebugEmitter

function DebugEmitter.create(config)
	local source = config or {}

	return setmetatable({
		enabled = source.enabled == true,
		mode = source.mode or 'client',
		lifetimeSeconds = source.lifetimeSeconds or 0.2,
		container = source.container,
		sharedSink = source.sharedSink,
		clientSink = source.clientSink,
		palette = source.palette,
	}, DebugEmitter)
end

function DebugEmitter:emit(request, result)
	if not self.enabled then
		return nil
	end

	local payload = DebugTypes.createPayload({
		attackId = request.attackId,
		mode = self.mode,
		timestamp = request.serverTime,
		lifetimeSeconds = self.lifetimeSeconds,
		query = request.query,
		hits = result.hits,
		rejections = result.rejections,
		palette = self.palette,
	})

	if (self.mode == 'shared' or self.mode == 'both') and self.container ~= nil then
		DebugVisualizer.render(self.container, payload)
	end

	if (self.mode == 'shared' or self.mode == 'both') and type(self.sharedSink) == 'function' then
		self.sharedSink(payload)
	end

	if (self.mode == 'client' or self.mode == 'both') and type(self.clientSink) == 'function' then
		self.clientSink(payload)
	end

	return payload
end

return DebugEmitter
```

```luau
-- src/Shared/Config.luau (add under DEFAULT_CONFIG)
debug = {
	enabled = false,
	mode = 'client',
	lifetimeSeconds = 0.2,
	palette = {
		query = nil,
		hit = nil,
		reject = nil,
	},
},
```

```luau
-- src/Server/Resolver.luau (constructor + resolve path)
local DebugEmitter = loadServer('DebugEmitter', './DebugEmitter.luau')

function Resolver.create(config)
	local normalizedConfig = Config.normalize(config or {})
	local source = config or {}

	return setmetatable({
		config = normalizedConfig,
		history = source.historyStore or History.create(normalizedConfig.history),
		validators = source.validators or Validators.create(normalizedConfig.validation),
		queryBackends = source.queryBackends,
		debugEmitter = source.debugEmitter or DebugEmitter.create(normalizedConfig.debug),
	}, Resolver)
end

function Resolver:resolve(request)
	-- existing request normalization and result creation
	local resolution = Results.createResolution({
		query = normalizedQuery,
		hits = hits,
		rejections = rejections,
		metadata = {
			snapshotTimestamp = snapshot.timestamp,
			latencySeconds = serverTime - clientTime,
			candidateCount = #candidates,
		},
	})

	self.debugEmitter:emit(normalizedRequest, resolution)

	return resolution
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lune run test/run.luau ResolverSpec`
Expected: PASS with the shared debug query part present in the provided container.

- [ ] **Step 5: Commit**

```bash
git add src/Shared/Config.luau src/Server/DebugEmitter.luau src/Server/Resolver.luau test/ResolverSpec.luau
git commit -m "feat: emit resolver debug payloads"
```

### Task 3: Turn Client Debug Into A Local Renderer

**Files:**
- Modify: `src/Client/Debug.luau`
- Modify: `src/Client/init.luau`
- Test: `test/PackageSpec.luau`

- [ ] **Step 1: Write the failing test**

```luau
local Roblox = require('@lune/roblox')
local Color3 = Roblox.Color3
local Instance = Roblox.Instance
local Vector3 = Roblox.Vector3

local HitboxPlus = loadModule('src/init.luau')
local DebugTypes = loadModule('src/Shared/DebugTypes.luau')

local localRoot = Instance.new('Folder')
local client = HitboxPlus.Client.create({
	debug = {
		container = localRoot,
		palette = {
			query = Color3.fromRGB(0, 170, 255),
			hit = Color3.fromRGB(0, 255, 0),
			reject = Color3.fromRGB(255, 80, 80),
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

client:renderDebugPayload(payload)

expect(localRoot:FindFirstChild('HitboxPlusQuery') ~= nil, 'client renderer should create a local debug part')
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lune run test/run.luau PackageSpec`
Expected: FAIL because `Client` does not yet expose `renderDebugPayload`.

- [ ] **Step 3: Write minimal implementation**

```luau
-- src/Client/Debug.luau
local function loadShared(moduleName, relativePath)
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.Parent.Shared[moduleName])
	end

	return require(relativePath)
end

local DebugVisualizer = loadShared('DebugVisualizer', 'src/Shared/DebugVisualizer.luau')

local Debug = {}
Debug.__index = Debug

function Debug.create(config)
	local debugConfig = config.debug or {}

	return setmetatable({
		sink = debugConfig.sink,
		container = debugConfig.container,
		traces = {},
	}, Debug)
end

function Debug:record(name, payload)
	local trace = {
		name = name,
		payload = payload or {},
	}

	table.insert(self.traces, trace)

	if type(self.sink) == 'function' then
		self.sink(trace)
	end

	return trace
end

function Debug:render(payload)
	if self.container == nil then
		return {}
	end

	return DebugVisualizer.render(self.container, payload)
end

return Debug
```

```luau
-- src/Client/init.luau
function Client:renderDebugPayload(payload)
	return self.debugger:render(payload)
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lune run test/run.luau PackageSpec`
Expected: PASS with a `HitboxPlusQuery` part created in the local container.

- [ ] **Step 5: Commit**

```bash
git add src/Client/Debug.luau src/Client/init.luau test/PackageSpec.luau
git commit -m "feat: add client debug rendering"
```

### Task 4: Add Better Sandbox Example Sources And Docs

**Files:**
- Create: `examples/SandboxServer.luau`
- Create: `examples/SandboxClient.luau`
- Modify: `README.md`
- Test: `test/ToolingSpec.luau`

- [ ] **Step 1: Write the failing test**

```luau
local fs = require('@lune/fs')

local requiredFiles = {
	'examples/SandboxServer.luau',
	'examples/SandboxClient.luau',
}

for _, path in requiredFiles do
	assert(fs.isFile(path), string.format('missing sandbox example file %s', path))
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lune run test/run.luau ToolingSpec`
Expected: FAIL because the sandbox example files do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```luau
-- examples/SandboxServer.luau
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local HitboxPlus = require(ReplicatedStorage:WaitForChild('HitboxPlus'))
local Remotes = ReplicatedStorage:WaitForChild('HitboxPlusSandboxRemotes')

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
			Remotes.DebugPayload:FireAllClients(payload)
		end,
	},
})

return server
```

```luau
-- examples/SandboxClient.luau
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local HitboxPlus = require(ReplicatedStorage:WaitForChild('HitboxPlus'))
local Remotes = ReplicatedStorage:WaitForChild('HitboxPlusSandboxRemotes')

local localRoot = Workspace:FindFirstChild('HitboxPlusClientDebug') or Instance.new('Folder')
localRoot.Name = 'HitboxPlusClientDebug'
localRoot.Parent = Workspace

local client = HitboxPlus.Client.create({
	debug = {
		container = localRoot,
	},
	timeSource = function()
		return workspace:GetServerTimeNow()
	end,
})

Remotes.DebugPayload.OnClientEvent:Connect(function(payload)
	client:renderDebugPayload(payload)
end)

return client
```

```md
<!-- README.md -->
## Studio Sandbox

- `examples/SandboxServer.luau` is the source of truth for the server sandbox flow.
- `examples/SandboxClient.luau` is the source of truth for local debug rendering and retrigger input.
- The Studio mirror should install those scripts into `ServerScriptService` and `StarterPlayerScripts`.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lune run test/run.luau ToolingSpec`
Expected: PASS with the two sandbox example files now present.

- [ ] **Step 5: Commit**

```bash
git add examples/SandboxServer.luau examples/SandboxClient.luau README.md test/ToolingSpec.luau
git commit -m "docs: add sandbox example source files"
```

### Task 5: Sync Runtime And Sandbox Into Roblox Studio

**Files:**
- Modify: `game.ReplicatedStorage.HitboxPlus.*`
- Create: `game.ReplicatedStorage.HitboxPlusSandboxRemotes`
- Create: `game.ServerScriptService.HitboxPlusSandbox`
- Modify: `game.StarterPlayer.StarterPlayerScripts.HitboxPlusClientExample`

- [ ] **Step 1: Write the failing Studio verification**

Use `mcp__roblox_studio__.execute_luau` with:

```luau
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')

assert(ReplicatedStorage:FindFirstChild('HitboxPlusSandboxRemotes') ~= nil, 'sandbox remotes missing')
assert(ServerScriptService:FindFirstChild('HitboxPlusSandbox') ~= nil, 'sandbox server script missing')
```

- [ ] **Step 2: Run verification to confirm it fails**

Expected: FAIL because the sandbox remotes and sandbox server script are not in Studio yet.

- [ ] **Step 3: Write minimal implementation**

Use `mcp__roblox_studio__.execute_luau` to ensure remotes:

```luau
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local remotes = ReplicatedStorage:FindFirstChild('HitboxPlusSandboxRemotes') or Instance.new('Folder')
remotes.Name = 'HitboxPlusSandboxRemotes'
remotes.Parent = ReplicatedStorage

local debugPayload = remotes:FindFirstChild('DebugPayload') or Instance.new('RemoteEvent')
debugPayload.Name = 'DebugPayload'
debugPayload.Parent = remotes

local triggerAttack = remotes:FindFirstChild('TriggerAttack') or Instance.new('RemoteEvent')
triggerAttack.Name = 'TriggerAttack'
triggerAttack.Parent = remotes
```

Use `mcp__roblox_studio__.multi_edit` to mirror the new runtime modules into `game.ReplicatedStorage.HitboxPlus.Shared.DebugTypes`, `game.ReplicatedStorage.HitboxPlus.Shared.DebugVisualizer`, `game.ReplicatedStorage.HitboxPlus.Server.DebugEmitter`, and the modified `Resolver`, `Config`, `Client.Debug`, and `Client.init`.

Use `mcp__roblox_studio__.multi_edit` to create the sandbox scripts:

```luau
-- game.ServerScriptService.HitboxPlusSandbox
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local HitboxPlus = require(ReplicatedStorage:WaitForChild('HitboxPlus'))
local Remotes = ReplicatedStorage:WaitForChild('HitboxPlusSandboxRemotes')

local function ensureFolder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:ClearAllChildren()
		return existing
	end

	local folder = Instance.new('Folder')
	folder.Name = name
	folder.Parent = parent
	return folder
end

local sandboxRoot = ensureFolder(Workspace, 'HitboxPlusSandbox')
local debugRoot = ensureFolder(Workspace, 'HitboxPlusDebug')

local server = HitboxPlus.Server.create({
	debug = {
		enabled = true,
		mode = 'both',
		container = debugRoot,
		clientSink = function(payload)
			Remotes.DebugPayload:FireAllClients(payload)
		end,
	},
	validation = {
		maxLatencySeconds = 0.2,
		maxDistance = 20,
	},
})

local function runAttack()
	server:pushSnapshot({
		timestamp = workspace:GetServerTimeNow(),
		entities = {
			{ id = 'enemy-a', position = Vector3.new(4, 3, 0), radius = 2, team = 'Red' },
			{ id = 'ally-a', position = Vector3.new(-4, 3, 0), radius = 2, team = 'Blue' },
		},
	})

	server:resolve({
		attackId = string.format('sandbox-%d', os.clock() * 1000),
		attackerId = 'sandbox-player',
		attackerPosition = Vector3.new(0, 3, 0),
		attackerTeam = 'Blue',
		serverTime = workspace:GetServerTimeNow(),
		clientTime = workspace:GetServerTimeNow(),
		query = {
			type = 'box',
			center = CFrame.new(0, 3, 0),
			size = Vector3.new(8, 6, 8),
		},
	})
end

runAttack()
Remotes.TriggerAttack.OnServerEvent:Connect(runAttack)
```

```luau
-- game.StarterPlayer.StarterPlayerScripts.HitboxPlusClientExample
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local HitboxPlus = require(ReplicatedStorage:WaitForChild('HitboxPlus'))
local Remotes = ReplicatedStorage:WaitForChild('HitboxPlusSandboxRemotes')

local localRoot = Workspace:FindFirstChild('HitboxPlusClientDebug') or Instance.new('Folder')
localRoot.Name = 'HitboxPlusClientDebug'
localRoot.Parent = Workspace

local client = HitboxPlus.Client.create({
	debug = {
		container = localRoot,
	},
})

Remotes.DebugPayload.OnClientEvent:Connect(function(payload)
	client:renderDebugPayload(payload)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.F then
		Remotes.TriggerAttack:FireServer()
	end
end)
```

- [ ] **Step 4: Run Studio verification to confirm it passes**

Use `mcp__roblox_studio__.execute_luau` with:

```luau
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')

local remotes = ReplicatedStorage:WaitForChild('HitboxPlusSandboxRemotes')
assert(remotes:FindFirstChild('DebugPayload') ~= nil, 'DebugPayload remote missing')
assert(remotes:FindFirstChild('TriggerAttack') ~= nil, 'TriggerAttack remote missing')
assert(Workspace:FindFirstChild('HitboxPlusDebug') ~= nil, 'shared debug folder missing')
return 'Studio sandbox installed'
```

Expected: PASS with `'Studio sandbox installed'`.

- [ ] **Step 5: Commit**

```bash
git add src README.md examples test
git commit -m "feat: add studio sandbox debug pipeline"
```

### Task 6: Fix GitHub Email Privacy And Push Main

**Files:**
- Modify: local git config for this repository
- Rewrite: local commit author metadata on `main`

- [ ] **Step 1: Write the failing verification**

Run: `git log --format='%ae' --reverse | uniq`
Expected: output includes `williamnorth1405@gmail.com`, which GitHub is rejecting for push.

- [ ] **Step 2: Run verification to confirm it fails**

Run: `git push -u origin main`
Expected: FAIL with the private email protection error from GitHub.

- [ ] **Step 3: Write minimal implementation**

Run:

```bash
NOREPLY_EMAIL="$(gh api user/emails --jq '.[] | select(.email | endswith("@users.noreply.github.com")) | .email' | head -n1)"
test -n "$NOREPLY_EMAIL"
git config user.email "$NOREPLY_EMAIL"
git rebase --root --exec 'git commit --amend --no-edit --reset-author'
```

- [ ] **Step 4: Run verification to confirm it passes**

Run:

```bash
git log --format='%ae' --reverse | uniq
git push -u origin main
```

Expected:

- the email list shows only the GitHub noreply address
- `git push -u origin main` succeeds

- [ ] **Step 5: Commit**

```bash
git status --short
git log --oneline --decorate -5
```

Expected: clean worktree and rewritten commits on `main`; no extra commit required because the rebase rewrites the existing commits.

## Self-Review

- Spec coverage: Task 1 covers normalized debug payloads and solid visual primitives. Task 2 covers resolver emission and server-side shared rendering. Task 3 covers local client rendering. Task 4 covers better repo-side sandbox examples and docs. Task 5 covers the actual Studio mirror, remotes, sandbox autorun, and manual retrigger path. Task 6 covers the GitHub email privacy follow-up from the spec.
- Placeholder scan: no `TODO`, `TBD`, or unspecified “do the right thing” steps remain; each task lists exact files, exact commands, and exact code snippets.
- Type consistency: the plan consistently uses `debug.enabled`, `debug.mode`, `debug.lifetimeSeconds`, `HitboxPlus.Client.create`, `client:renderDebugPayload`, `HitboxPlusSandboxRemotes.DebugPayload`, and `HitboxPlusSandboxRemotes.TriggerAttack` throughout.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-17-hitbox-plus-studio-debug.md`. Two execution options:

1. Subagent-Driven (recommended) - I dispatch a fresh subagent per task, review between tasks, fast iteration
2. Inline Execution - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
