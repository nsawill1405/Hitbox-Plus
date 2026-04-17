# Hitbox Plus Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and verify the first publishable Wally package for Hitbox Plus with shared server/client modules, snapshot-backed lag compensation, spatial query helpers, validation helpers, docs, and maintainer tooling.

**Architecture:** The package exposes `HitboxPlus.Server.create(config)` and `HitboxPlus.Client.create(config)` from `src/`. Server resolution is composed from focused modules for history, rewind, query dispatch, and validators. Query execution runs against normalized snapshot entities so lag compensation works in local tests without mutating a live Roblox workspace.

**Tech Stack:** Luau, Wally, Lune, Stylua, Selene

---

## Planned File Structure

- `aftman.toml`: toolchain versions for `lune`, `stylua`, and `selene`
- `wally.toml`: package metadata for `williamnorth1405/hitbox-plus`
- `README.md`: installation, setup, example, and extension points
- `stylua.toml`: formatting config
- `selene.toml`: lint config
- `src/init.luau`: top-level package export
- `src/Shared/Config.luau`: config normalization and defaults
- `src/Shared/Queries.luau`: query normalization and validation
- `src/Shared/Results.luau`: structured result builders
- `src/Shared/Types.luau`: shared Luau type exports
- `src/Server/init.luau`: server constructor export
- `src/Server/History.luau`: snapshot buffer and retention
- `src/Server/Rewind.luau`: rewind lookup helper
- `src/Server/Queries/init.luau`: query dispatch entrypoint
- `src/Server/Queries/SnapshotBackend.luau`: snapshot-based box/radius/cast tests
- `src/Server/Validators.luau`: default validation pipeline and stateful duplicate gating
- `src/Server/Resolver.luau`: authoritative hit resolution orchestration
- `src/Client/init.luau`: client constructor export
- `src/Client/Requests.luau`: attack request builder
- `src/Client/Prediction.luau`: local prediction hook
- `src/Client/Debug.luau`: debug trace sink helper
- `test/TestRunner.luau`: tiny assertion runner for Lune
- `test/QuerySpec.luau`: query normalization and backend behavior tests
- `test/HistorySpec.luau`: snapshot retention and rewind lookup tests
- `test/ResolverSpec.luau`: validator and resolver end-to-end tests
- `test/run.luau`: entrypoint to execute the test suite in Lune
- `examples/basic.luau`: end-to-end sample usage

### Task 1: Scaffold Tooling And Package Metadata

**Files:**
- Create: `aftman.toml`
- Create: `wally.toml`
- Create: `stylua.toml`
- Create: `selene.toml`
- Create: `README.md`

- [ ] **Step 1: Write the failing tooling smoke test**

```luau
local fs = require("@lune/fs")

local requiredFiles = {
	"aftman.toml",
	"wally.toml",
	"stylua.toml",
	"selene.toml",
	"README.md",
}

for _, path in requiredFiles do
	assert(fs.isFile(path), string.format("missing repo file %s", path))
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lune run test/run.luau`
Expected: FAIL with at least one missing top-level config file.

- [ ] **Step 3: Write minimal implementation**

```toml
# aftman.toml
[tools]
lune = "lune-org/lune@0.8.9"
stylua = "johnnymorganz/stylua@0.20.0"
selene = "Kampfkarren/selene@0.27.1"
```

```toml
# wally.toml
[package]
name = "williamnorth1405/hitbox-plus"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"
license = "MIT"
description = "Spatial query-based hitbox system with lag compensation hooks and hit validation helpers."
exclude = ["docs", "examples", "test", ".gitignore"]
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lune run test/run.luau`
Expected: PASS for the repo file existence test.

- [ ] **Step 5: Commit**

```bash
git add aftman.toml wally.toml stylua.toml selene.toml README.md test/TestRunner.luau test/run.luau
git commit -m "chore: scaffold hitbox plus package tooling"
```

### Task 2: Build Shared Query And Result Primitives

**Files:**
- Create: `src/Shared/Config.luau`
- Create: `src/Shared/Queries.luau`
- Create: `src/Shared/Results.luau`
- Create: `src/Shared/Types.luau`
- Test: `test/QuerySpec.luau`

- [ ] **Step 1: Write the failing test**

```luau
local Queries = require("../src/Shared/Queries")

local normalizedBox = Queries.normalize({
	type = "box",
	center = CFrame.new(),
	size = Vector3.new(4, 4, 4),
})

assert(normalizedBox.type == "box")
assert(normalizedBox.maxTargets == math.huge)

local normalizedCast = Queries.normalize({
	type = "cast",
	origin = Vector3.new(),
	direction = Vector3.new(0, 0, -10),
	radius = 2,
})

assert(normalizedCast.length == 10)
assert(normalizedCast.radius == 2)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lune run test/run.luau QuerySpec`
Expected: FAIL because `src/Shared/Queries.luau` does not exist.

- [ ] **Step 3: Write minimal implementation**

```luau
local Queries = {}

local function inferLength(direction: Vector3): number
	return direction.Magnitude
end

function Queries.normalize(query)
	if query.type == "box" then
		return {
			type = "box",
			center = query.center,
			size = query.size,
			maxTargets = query.maxTargets or math.huge,
		}
	end

	if query.type == "cast" then
		return {
			type = "cast",
			origin = query.origin,
			direction = query.direction,
			radius = query.radius or 0,
			length = query.length or inferLength(query.direction),
			maxTargets = query.maxTargets or math.huge,
		}
	end

	error(string.format("unsupported query type %s", tostring(query.type)))
end

return Queries
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lune run test/run.luau QuerySpec`
Expected: PASS for query normalization cases.

- [ ] **Step 5: Commit**

```bash
git add src/Shared test/QuerySpec.luau
git commit -m "feat: add shared query and result primitives"
```

### Task 3: Add Snapshot History And Rewind Lookup

**Files:**
- Create: `src/Server/History.luau`
- Create: `src/Server/Rewind.luau`
- Test: `test/HistorySpec.luau`

- [ ] **Step 1: Write the failing test**

```luau
local History = require("../src/Server/History")

local history = History.create({
	retention = 0.25,
})

history:push({
	timestamp = 1.0,
	entities = {
		{ id = "enemy-a", position = Vector3.new(0, 0, 0), size = Vector3.new(4, 4, 4) },
	},
})

history:push({
	timestamp = 1.4,
	entities = {
		{ id = "enemy-a", position = Vector3.new(10, 0, 0), size = Vector3.new(4, 4, 4) },
	},
})

local rewinded = history:getClosest(1.05)
assert(rewinded.timestamp == 1.0)
assert(#history:getSnapshots() == 1)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lune run test/run.luau HistorySpec`
Expected: FAIL because history modules do not exist.

- [ ] **Step 3: Write minimal implementation**

```luau
local History = {}
History.__index = History

function History.create(config)
	return setmetatable({
		retention = config.retention or 0.2,
		snapshots = {},
	}, History)
end

function History:push(snapshot)
	table.insert(self.snapshots, snapshot)

	local newest = snapshot.timestamp
	local retained = {}

	for _, candidate in self.snapshots do
		if newest - candidate.timestamp <= self.retention then
			table.insert(retained, candidate)
		end
	end

	self.snapshots = retained
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lune run test/run.luau HistorySpec`
Expected: PASS with retention trimming and closest snapshot lookup.

- [ ] **Step 5: Commit**

```bash
git add src/Server/History.luau src/Server/Rewind.luau test/HistorySpec.luau
git commit -m "feat: add snapshot history and rewind lookup"
```

### Task 4: Implement Query Backend, Validators, And Resolver

**Files:**
- Create: `src/Server/Queries/init.luau`
- Create: `src/Server/Queries/SnapshotBackend.luau`
- Create: `src/Server/Validators.luau`
- Create: `src/Server/Resolver.luau`
- Test: `test/ResolverSpec.luau`

- [ ] **Step 1: Write the failing test**

```luau
local Resolver = require("../src/Server/Resolver")

local resolver = Resolver.create({
	maxLatency = 0.2,
	friendlyFire = false,
})

local result = resolver:resolve({
	attackId = "swing-1",
	attackerId = "player-a",
	serverTime = 10.0,
	clientTime = 9.92,
	attackerPosition = Vector3.new(0, 0, 0),
	attackerTeam = "Blue",
	query = {
		type = "radius",
		position = Vector3.new(0, 0, 0),
		radius = 8,
	},
	snapshot = {
		timestamp = 9.92,
		entities = {
			{ id = "enemy-a", position = Vector3.new(4, 0, 0), radius = 2, team = "Red" },
			{ id = "ally-a", position = Vector3.new(3, 0, 0), radius = 2, team = "Blue" },
		},
	},
})

assert(#result.hits == 1)
assert(result.hits[1].id == "enemy-a")
assert(#result.rejections == 1)
assert(result.rejections[1].reason == "same-team")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lune run test/run.luau ResolverSpec`
Expected: FAIL because resolver and validators do not exist.

- [ ] **Step 3: Write minimal implementation**

```luau
local Resolver = {}
Resolver.__index = Resolver

function Resolver.create(config)
	return setmetatable({
		maxLatency = config.maxLatency or 0.2,
		friendlyFire = config.friendlyFire or false,
	}, Resolver)
end

function Resolver:resolve(request)
	local hits = {}
	local rejections = {}

	for _, entity in request.snapshot.entities do
		local distance = (entity.position - request.query.position).Magnitude
		if distance <= (request.query.radius + (entity.radius or 0)) then
			if not self.friendlyFire and entity.team == request.attackerTeam then
				table.insert(rejections, {
					id = entity.id,
					reason = "same-team",
				})
			else
				table.insert(hits, entity)
			end
		end
	end

	return {
		hits = hits,
		rejections = rejections,
	}
end

return Resolver
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lune run test/run.luau ResolverSpec`
Expected: PASS for acceptance/rejection pipeline cases.

- [ ] **Step 5: Commit**

```bash
git add src/Server/Queries src/Server/Validators.luau src/Server/Resolver.luau test/ResolverSpec.luau
git commit -m "feat: add server resolver and validation pipeline"
```

### Task 5: Expose Client And Server APIs, Sample, And Docs

**Files:**
- Create: `src/Server/init.luau`
- Create: `src/Client/init.luau`
- Create: `src/Client/Requests.luau`
- Create: `src/Client/Prediction.luau`
- Create: `src/Client/Debug.luau`
- Create: `src/init.luau`
- Create: `examples/basic.luau`
- Modify: `README.md`
- Test: `test/ResolverSpec.luau`

- [ ] **Step 1: Write the failing test**

```luau
local HitboxPlus = require("../src")

local client = HitboxPlus.Client.create({
	timeSource = function()
		return 5.0
	end,
})

local request = client:buildRequest({
	attackId = "slash-1",
	attackerId = "player-a",
	query = {
		type = "radius",
		position = Vector3.new(),
		radius = 6,
	},
})

assert(request.clientTime == 5.0)
assert(request.query.type == "radius")

local server = HitboxPlus.Server.create({})
assert(type(server.resolve) == "function")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lune run test/run.luau ResolverSpec`
Expected: FAIL because package entrypoints do not exist.

- [ ] **Step 3: Write minimal implementation**

```luau
local Server = require(script.Server)
local Client = require(script.Client)

return {
	Server = Server,
	Client = Client,
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lune run test/run.luau`
Expected: PASS for the full test suite and entrypoint coverage.

- [ ] **Step 5: Commit**

```bash
git add src examples README.md
git commit -m "feat: publish first hitbox plus library surface"
```

### Task 6: Format, Lint, And Verify

**Files:**
- Modify: repo-wide formatting output only

- [ ] **Step 1: Run formatter**

Run: `stylua src test examples`
Expected: exit code `0`.

- [ ] **Step 2: Run linter**

Run: `selene src test examples`
Expected: exit code `0`.

- [ ] **Step 3: Run full test suite**

Run: `lune run test/run.luau`
Expected: PASS with zero failures.

- [ ] **Step 4: Inspect final status**

Run: `git status --short`
Expected: only intended project files modified or added.

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "chore: verify hitbox plus v1 scaffold"
```

## Self-Review

- Spec coverage: shared/server/client layout, snapshot history, rewind lookup, box/radius/cast queries, validation pipeline, structured results, tests, example, docs, and maintainer tooling all map to tasks above.
- Placeholder scan: no `TODO`, `TBD`, or deferred implementation placeholders were left in the task steps.
- Type consistency: the plan uses `HitboxPlus.Server.create(config)`, `HitboxPlus.Client.create(config)`, normalized `query` tables, snapshot history, and structured `result.hits`/`result.rejections` consistently across tasks.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-17-hitbox-plus.md`. The user explicitly asked to implement immediately, so execution should proceed inline in this session using `superpowers:executing-plans`.
