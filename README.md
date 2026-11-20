<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0f2027,50:203a43,100:2c5364&height=170&section=header&text=Hitbox%20Plus&fontSize=52&fontColor=ffffff&fontAlignY=36&desc=Lag-compensated%20spatial-query%20hitboxes%20for%20Roblox&descAlignY=58&descSize=16" alt="Hitbox Plus" width="100%" />

<p>
  <img src="https://img.shields.io/badge/Luau-00A2FF?style=for-the-badge&logo=roblox&logoColor=white" alt="Luau" />
  <a href="https://github.com/nsawill1405/Hitbox-Plus/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/nsawill1405/Hitbox-Plus/ci.yml?branch=main&style=for-the-badge&label=CI&logo=githubactions&logoColor=white" alt="CI" /></a>
  <a href="https://wally.run/package/nsawill1405/hitbox-plus"><img src="https://img.shields.io/badge/Wally-nsawill1405%2Fhitbox--plus-AD4646?style=for-the-badge" alt="Wally" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-2c5364?style=for-the-badge" alt="License" /></a>
</p>

<p><a href="#features">Features</a> · <a href="#install">Install</a> · <a href="#quick-start">Quick Start</a> · <a href="#config-notes">Config Notes</a> · <a href="#extending">Extending</a> · <a href="#studio-sandbox">Studio Sandbox</a></p>

</div>

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

## License

[MIT](LICENSE) © William North. Issues and pull requests are welcome.

---

<div align="center">

<sub>Made by <a href="https://github.com/nsawill1405">William North</a> · <a href="https://nsawill.co.uk">nsawill.co.uk</a></sub>

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:2c5364,50:203a43,100:0f2027&height=100&section=footer" alt="" width="100%" />

</div>
