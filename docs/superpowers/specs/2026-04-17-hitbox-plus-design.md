# Hitbox Plus Design

Date: 2026-04-17
Project: Hitbox Plus
Repository owner: `williamnorth1405`
Planned Wally package: `williamnorth1405/hitbox-plus`

## Summary

Hitbox Plus is a Roblox community library for authoritative hit detection built on spatial queries. The package targets shared distribution through Wally and splits responsibility across shared, server, and client modules. Server code remains authoritative for hit resolution. Client code is limited to request shaping, prediction hooks, and optional debug helpers.

The first release will support box, radius, and cast-oriented query workflows, a built-in lag compensation stack, and a default hit validation pipeline with extension points for custom rules and backends.

## Goals

- Provide a Wally-installable Roblox package for spatial query-based hit detection.
- Ship a default end-to-end pipeline that works without requiring users to build lag compensation or validation from scratch.
- Keep authority on the server while still exposing client-side helpers for request assembly and prediction.
- Make major subsystems replaceable so advanced users can customize history storage, validation rules, or query dispatch without forking the package.
- Keep the initial public API small enough to document and test well.

## Non-Goals

- Shipping a network transport framework or remote event abstraction.
- Bundling effect replication, damage systems, or gameplay-specific combat logic.
- Providing editor plugins, Studio widgets, or authoring tools in `v1`.
- Solving general anti-cheat beyond the hit validation and adjudication concerns directly related to hit resolution.

## Recommended Architecture

Hitbox Plus will be a single Wally package with explicit `Shared`, `Server`, and `Client` module trees under one top-level entrypoint. The shared layer defines types, query descriptions, result objects, and configuration contracts. The server layer owns authoritative history capture, rewind execution, spatial query dispatch, validation, and final adjudication. The client layer only supports request creation, optional local prediction, and debug visualization.

The default runtime flow is:

1. A client module builds an attack request with timing and trace metadata.
2. The server receives the request and resolves the requested attack definition.
3. The server rewinds tracked state for the relevant timestamp.
4. The server runs the configured query path for box, radius, or cast-oriented resolution.
5. The server passes candidates through the default validation pipeline.
6. The server returns a structured resolution result with accepted hits and rejection metadata.

This architecture balances usability and maintainability. Most users get a single pipeline that works out of the box, while maintainers and advanced consumers still have explicit seams for replacing subsystems.

## Public API Shape

The package will expose one primary constructor for authoritative server use and one primary constructor for client-side helper usage:

- `HitboxPlus.Server.create(config)`
- `HitboxPlus.Client.create(config)`

These constructors should be the documented default entrypoints. Lower-level modules remain public for advanced composition, but the first-run experience should not require users to assemble the pipeline by hand.

Expected module layout:

- `Shared/Types`
- `Shared/Queries`
- `Shared/Results`
- `Shared/Config`
- `Server/History`
- `Server/Queries`
- `Server/Validators`
- `Server/Resolver`
- `Server/Rewind`
- `Client/Requests`
- `Client/Prediction`
- `Client/Debug`

### Shared Layer

The shared layer defines:

- request payload shapes for attack resolution
- query description formats for box, radius, and cast workflows
- config contracts used by both server and client constructors
- result objects for accepted hits, rejected candidates, and trace metadata

### Server Layer

The server layer defines:

- snapshot capture and retention behavior
- rewind lookup and replay helpers
- query execution adapters for supported spatial query paths
- the default validation pipeline
- the final resolver that produces authoritative results

The server API should support replacement of the history backend, validation stages, and query executors through configuration rather than requiring consumers to patch internal files.

### Client Layer

The client layer defines:

- request builders that stamp timing and trace data
- optional local prediction helpers
- optional debug visualization helpers for development workflows

The client layer does not decide authoritative hits and should never be documented as security-relevant.

## Query Model

`v1` will ship with first-class support for three query primitives:

- box
- radius
- cast

In this design, `cast` means a shared API path for raycast-style and shapecast-backed helpers where the runtime supports them. The public API should treat these as one family so users do not have to learn separate top-level systems for linear or swept hit detection.

These should share a normalized request shape so the resolver can operate on a common interface after dispatch. The package should favor a small set of explicit query descriptors over a generic adapter registry at the top level. Internally, the query system can still use adapters to keep implementations isolated.

The design should leave room for future engine-specific additions, but `v1` should document only the supported primitives above.

## Lag Compensation Model

`v1` will include a full built-in lag compensation stack rather than hooks alone. That stack should include:

- tracked snapshot history for relevant character or hitbox state
- timestamp-based rewind lookup
- replay helpers that restore enough context to run authoritative spatial queries
- configuration hooks for retention windows, tracking scope, and replacement backends

The default implementation should be useful immediately in a typical Roblox combat game. At the same time, the public configuration surface should allow projects to replace the storage or rewind strategy later without abandoning the rest of the package.

## Validation Model

`v1` will ship with a default validation pipeline rather than only isolated helpers. The built-in pipeline should support composable rules such as:

- maximum distance checks
- team or faction filtering
- line-of-sight checks
- attack timing sanity checks
- duplicate hit rejection
- cooldown or repeat-hit gating

Validation results should be structured, not boolean-only. Rejected candidates should carry machine-readable reason data so games can debug behavior and optionally expose analytics or audit tooling later.

The default pipeline should still be overridable. Consumers must be able to add, remove, or replace validation stages through configuration.

## Error Handling and Result Contracts

The package should prefer structured result objects over thrown runtime errors for expected resolution outcomes. Invalid configuration and programmer misuse can still error during setup, but hit resolution should return stable result objects that distinguish:

- accepted hits
- rejected candidates
- resolution metadata
- timing and trace data
- failure states such as missing rewind data or unsupported query types

This keeps the package usable in production pipelines where rejected hits are normal and not exceptional.

## Repository Shape

The repository should start as a maintainer-ready package, not a full platform repo. Planned top-level contents:

- `src/` for package modules
- `test/` for automated tests
- `examples/` for one end-to-end sample flow
- `docs/` for design and usage documentation
- `README.md`
- `wally.toml`
- `.gitignore`
- `stylua.toml`
- `selene.toml`

Rojo project files, GitHub Actions workflows, and release automation are intentionally excluded from `v1` scope for now.

## Testing Strategy

The first release should test behavior, not only module import success. Required coverage areas:

- query normalization and dispatch for box, radius, and cast requests, including raycast-style and shapecast-backed paths
- snapshot buffering and rewind lookup behavior
- validation pipeline acceptance and rejection cases
- resolver end-to-end behavior across accepted and rejected hit results

The example app should demonstrate one clear melee or close-range flow:

1. the client builds an attack request
2. the server rewinds state
3. the server runs the configured query
4. the server validates candidates
5. the server returns structured results

That example should prioritize clarity over production completeness.

## Documentation Expectations

The initial README should cover:

- package purpose
- installation through Wally
- server and client setup
- one end-to-end usage example
- extension points for history and validation customization

Reference docs can stay light in `v1` as long as the README and example are sufficient to adopt the package.

## `v1` Scope

Included in `v1`:

- Wally package scaffold for `williamnorth1405/hitbox-plus`
- shared package with separate server and client modules
- box, radius, and cast query support, with cast covering raycast-style and shapecast-backed helpers
- built-in lag compensation stack
- default validation pipeline
- structured result contracts
- extension points for custom validation, history, and query backends
- maintainer-ready tooling with tests, formatting, and linting config

Excluded from `v1`:

- transport abstraction or remote framework integration
- combat effects or damage application systems
- advanced anti-cheat platform features outside hit adjudication
- Studio plugins or editor tooling
- CI, release automation, or Rojo integration

## Open Decisions Deferred Past Design

The following are implementation details that do not need to be locked in this design document:

- exact file names for individual modules under `src/`
- specific test framework package choice
- exact Luau type export organization
- exact internal data structure used for snapshot history retention

Those choices should be made in the implementation plan while staying within the boundaries above.
