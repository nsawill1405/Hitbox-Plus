# Hitbox Plus Studio Debug And Sandbox Design

Date: 2026-04-17
Project: Hitbox Plus
Repository owner: `williamnorth1405`

## Summary

This document defines the first Studio-focused debug and example upgrade for Hitbox Plus. The goal is to make the imported library easier to inspect in Roblox Studio without Wally by adding honest debug visualization and better sandbox scripts built on top of the real resolver pipeline.

The upgrade adds optional debug payload emission to the runtime, dual debug rendering modes (`client`, `shared`, `both`), and a self-contained sandbox demo with spawned characters, automatic first-run playback, and manual retriggers.

## Goals

- Make query coverage visible in Studio with solid translucent debug volumes.
- Ensure debug visuals reflect the real normalized query data used by the resolver.
- Support local-only and shared debug rendering without changing gameplay authority.
- Ship a self-contained character-driven sandbox example that proves the library works end to end.
- Keep demo logic separate from core runtime logic so the package remains reusable.

## Non-Goals

- Building a full combat framework, UI-heavy demo, or production-ready minigame.
- Moving gameplay-specific character spawning or arena logic into the core library.
- Adding advanced editor tooling or Studio plugins in this iteration.
- Solving GitHub publishing workflow inside the runtime itself.

## Recommended Architecture

`ReplicatedStorage.HitboxPlus` remains the core package. The runtime gains an optional debug path that emits structured payloads from the same query and validation flow the resolver already uses. Those payloads are then consumed by renderers instead of inventing separate visualization-only logic.

The debug system supports three modes:

- `client`: render local-only visuals for one tester
- `shared`: render world-space visuals in a shared container for everyone in the session
- `both`: emit both local and shared visualization paths

The Studio sandbox sits on top of that runtime:

- `ServerScriptService.HitboxPlusSandbox` owns arena setup, spawned characters, automatic first attack playback, and later retriggers
- `StarterPlayerScripts.HitboxPlusClientExample` handles client-local rendering and retrigger input
- `ReplicatedStorage.HitboxPlusSandboxRemotes` carries sandbox-specific demo traffic only

This keeps the resolver authoritative while making the visual debugging path reusable in Studio and test sessions.

## Components And Data Flow

### Runtime Additions

The runtime should gain a focused debug surface rather than ad hoc printing or one-off example visuals.

Expected additions:

- shared debug payload definitions for query visualization
- server-side debug emission from the resolver when enabled
- a server-side debug emitter/router that handles `client`, `shared`, and `both`
- a client-side debug renderer that can consume payloads and create local-only visuals

Each debug event should carry enough information to recreate what the resolver actually did:

- `attackId`
- `queryType`
- timestamp
- selected debug mode
- shape data for box, radius, or cast queries
- accepted hits
- rejected candidates
- optional color and lifetime hints

### Shared Debug Data

The debug payload format should stay normalized across query types so renderers do not need to know resolver internals. Query-specific fields are acceptable, but the top-level event contract should remain stable.

### Server Flow

The authoritative flow remains:

1. request arrives
2. resolver normalizes the query
3. rewind snapshot is selected
4. query dispatcher gathers candidates
5. validators accept or reject candidates
6. structured result object is returned

When debug is enabled, the resolver should also emit a payload built from those same normalized values and outcomes. That emission should be optional and should not affect hit results.

### Renderers

`shared` mode should create temporary debug parts under `Workspace.HitboxPlusDebug`.

`client` mode should forward payloads to players through sandbox or runtime debug remotes so a local renderer can create equivalent visuals only for that player.

`both` mode performs both actions from the same payload.

## Visual Behavior

Debug visualization should use solid translucent parts by default because they are the most readable in Studio.

Default rendering rules:

- `radius`: render a translucent spherical volume centered on the query position
- `box`: render a translucent part matching the query `CFrame` and `size`
- `cast`: render a translucent stretched volume aligned from origin through direction, with optional endpoint markers

Outcome overlays:

- accepted hits should be highlighted with an accepted color
- rejected targets should be marked with a rejected color
- attack volumes should use a neutral debug color distinct from result markers

All generated debug visuals should:

- live under a dedicated container
- use a short configurable lifetime
- self-clean automatically
- avoid accumulating stale parts across repeated retriggers

## Sandbox Example Scope

The sandbox should be self-contained and character-driven, not just script-driven.

Required elements:

- one attacker character
- one valid enemy dummy
- one invalid or rejected target case
- one automatic attack when play begins
- one manual retrigger path afterward

This is enough to prove:

- snapshot history and resolver flow are working
- accepted and rejected targets are both visible
- debug payloads map to what the resolver actually processed
- the Studio setup is useful without turning the repo into a demo game framework

## Script Responsibilities

### `ServerScriptService.HitboxPlusSandbox`

Responsibilities:

- create or reset the demo arena
- spawn attacker and target characters/dummies
- configure the library with debug enabled
- run one attack automatically on startup
- support later manual retriggers
- own shared debug rendering setup

### `StarterPlayerScripts.HitboxPlusClientExample`

Responsibilities:

- receive local debug payloads
- render client-only translucent debug parts
- display or log a minimal local trace for debugging
- expose manual retrigger input after the initial autorun

### `ReplicatedStorage.HitboxPlusSandboxRemotes`

Responsibilities:

- carry sandbox-specific retrigger and local debug events
- stay outside the core library API so the package does not become transport-opinionated

## Boundaries

The core library should emit debug payloads and stay responsible for real hit resolution. The sandbox should own characters, arena setup, playback timing, and demo-only remotes.

That boundary is important because it allows:

- reuse of debug emission in real games later
- replacement of demo scripts without changing the core package
- honest examples that still reflect the actual runtime

## Error Handling And Cleanup

Debug emission must be optional. If debug is disabled or a renderer path is missing, hit resolution should still complete normally.

Sandbox scripts should also be defensive about cleanup:

- clear stale debug containers before reruns
- avoid duplicate remotes or duplicate dummy spawns
- make retriggers idempotent enough for repeated Studio testing

## Testing Expectations

Implementation should verify:

- debug payloads are emitted only when enabled
- each query type produces enough shape data for rendering
- shared debug rendering places parts in the correct container and cleans them up
- local debug rendering can consume the same payload format
- the sandbox autorun produces at least one visible accepted case and one rejected case
- the manual retrigger path works after the initial run

## Delivery Follow-Up

The GitHub push failure caused by private email protection is a delivery issue, not a runtime requirement. After implementation, the local repository configuration should be updated to the GitHub noreply email and the local commits should be rewritten so `git push -u origin main` succeeds without exposing a private address.
