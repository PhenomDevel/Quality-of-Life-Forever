# Quality of Life Forever – notes for Claude

World of Warcraft **Forever** addon (Interface 16001, launch 2026-11-04). Forever
runs on the modern mainline API (Midnight base, `C_*` namespaces, Settings API)
including the Midnight addon restrictions (secret values). Do not assume the
old Classic Era API.

## Layout
- `QualityOfLifeForever/` is the addon folder that gets installed; everything
  else (docs, tests, tools, CI) stays in the repo only.
- Load order is defined in `QualityOfLifeForever.toc`: Locales → Core → Modules → `Core/Bootstrap.lua` (last).
- Every feature is a module created with `ns:NewModule(name, info)` in
  `Modules/<Category>/<Name>.lua`. API reference: `docs/MODULES.md`, template: `docs/ModuleTemplate.lua`.

## Conventions
- Lua 5.1, tabs for indentation, English code comments, no external libraries (no Ace3).
- All user-facing strings go through `ns.L`; add every key to `Locales/enUS.lua`
  and translate it in `Locales/deDE.lua` (a test fails on untranslated keys).
- Module names are SavedVariables keys – never rename a released module without a migration in `Core/Database.lua`.
- `OnDisable` must undo everything `OnEnable` did; events are unregistered automatically.
- Each option in `info.options` needs a default in `info.defaults`.
- New WoW API globals must be added to `read_globals` in `.luacheckrc`.
- When a module uses new WoW API, add a mock for it in `tests/wowmock.lua` (or in the test's `setup`).

## Checks (must pass before committing)
```bash
luacheck .
lua5.1 tests/run.lua
```
Install locally with `apt-get install lua5.1 luarocks && luarocks install luacheck`.
