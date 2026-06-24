# zapret2-v1.0.1

This repository contains a local `zapret2` v1.0.1 package plus Windows-focused helper scripts for running a Roblox DPI bypass scenario with `winws2.exe`.

## What is included

- Upstream `zapret2` sources, docs, Lua scripts, and prebuilt binaries
- Windows helper scripts such as `start_roblox_dpi_bypass.ps1`
- A narrow Roblox-oriented config in `roblox-bypass.conf`

## Local customization

The Windows startup script loads:

- `lua/zapret-lib.lua`
- `lua/zapret-antidpi.lua`

It then applies a small set of TLS ClientHello desync rules against selected Roblox-related IP ranges and resolved hosts.

## Notes

- Runtime logs and backup files are intentionally excluded from git.
- The original upstream documentation remains under `docs/`.

