# Hitbox Plus

Hitbox Plus is a Wally-first Roblox community library for spatial query-based hit detection with snapshot-backed lag compensation hooks and built-in hit validation helpers.

## Features

- `HitboxPlus.Server.create(config)` for authoritative hit resolution
- `HitboxPlus.Client.create(config)` for client request building, prediction hooks, and debug traces
- box, radius, and cast-oriented query support
- snapshot history and rewind lookup for lag compensation
- default validation rules for latency, team checks, max distance, duplicate attacks, cooldowns, and optional line-of-sight
- structured hit/rejection results for gameplay code and debugging

## Install

```toml
[dependencies]
HitboxPlus = "nsawill1405/hitbox-plus@0.1.0"
```

## Quick Start

```luau
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
for _, hit in result.hits do
	print('accepted', hit.id)
end
```

## Config Notes

- `history.retentionSeconds`: how long snapshots remain available for rewind lookup
- `validation.maxLatencySeconds`: rejects requests that arrive too far past their client timestamp
- `validation.maxDistance`: caps how far away accepted targets can be from the attacker
- `validation.allowFriendlyFire`: allows same-team hits when set to `true`
- `validation.duplicateWindowSeconds`: rejects repeated `attackId` values inside the configured window
- `validation.targetCooldownSeconds`: rejects rapid repeat hits on the same target for the same attacker
- `validation.lineOfSight`: checks `snapshot.occluders` against the attacker-to-target segment

## Extending

- Replace query backends by passing `queryBackends = { box = fn, radius = fn, cast = fn }` into `HitboxPlus.Server.create`.
- Replace history storage by passing `historyStore` into `HitboxPlus.Server.create`.
- Replace the default validator state machine by passing `validators` into `HitboxPlus.Server.create`.
- Supply `predictor` or `debug.sink` in `HitboxPlus.Client.create` for client-side hooks.

## Studio Sandbox

- `examples/SandboxServer.luau` is the source of truth for the server sandbox flow, including sandbox dummy setup, one auto-run attack, and the `TriggerAttack` retrigger path.
- `examples/SandboxClient.luau` is the source of truth for local debug rendering and the `F` key retrigger input.
- The Studio mirror should install those scripts at `game.ServerScriptService.HitboxPlusSandbox` and `game.StarterPlayer.StarterPlayerScripts.HitboxPlusClientExample`.
- The matching remotes live under `game.ReplicatedStorage.HitboxPlusSandboxRemotes` with `DebugPayload` and `TriggerAttack`.

## Local Development

```bash
aftman install
lune run test/run.luau
stylua src test examples
selene src test examples
```
