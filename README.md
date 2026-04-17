# Hitbox Plus

Hitbox Plus is a Wally-first Roblox community library for spatial query-based hit detection with snapshot-backed lag compensation hooks and built-in hit validation helpers.

## Status

`v0.1.0` is the first scaffolded release target. It focuses on:

- shared server/client package entrypoints
- box, radius, and cast-oriented query support
- snapshot history and rewind lookup
- default validation rules with structured rejection reasons
- local verification through `lune`, `stylua`, and `selene`

## Tooling

This repository uses:

- `wally` for package metadata and installation
- `aftman` for local toolchain management
- `lune run test/run.luau` for tests
- `stylua src test examples` for formatting
- `selene src test examples` for linting
