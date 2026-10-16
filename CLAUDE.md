# Quality of Life Forever – notes for Claude

World of Warcraft **Forever** addon (Interface 16001, launch 2026-11-04). Forever
runs on the modern mainline API (Midnight base, `C_*` namespaces, Settings API)
including the Midnight addon restrictions (secret values). Do not assume the
old Classic Era API.

## Layout
- `QualityOfLifeForever/` is the addon folder that gets installed; everything
  else (docs, tools, CI) stays in the repo only.
- Load order is defined in `QualityOfLifeForever.toc`: Locales → Core → Modules → `Core/Bootstrap.lua` (last).
- Every feature is a module created with `ns:NewModule(name, info)` in
  `Modules/<Category>/<Name>.lua`. API reference: `docs/MODULES.md`, template: `docs/ModuleTemplate.lua`.

## Original code only (strict)
- Every line of code, data table and asset in this repo must be written
  independently. Never copy, port, translate or closely paraphrase code from
  other addons (e.g. Leatrix Plus/Maps, BlizzMove, ElvUI, …) – regardless of
  their license.
- Other addons may only be named as *feature inspiration* ("what"), never as a
  source for the implementation ("how"). Do not open or read their source code
  while implementing a feature.
- Data (e.g. map overlay coordinates, zone level ranges, item lists) must come
  from the game API at runtime or be collected by us in-game – never taken
  from another addon's data files.
- Allowed references: the official WoW API (function/event names and
  signatures, documented behavior) and Blizzard's UI only to learn which
  function/frame to hook – do not copy Blizzard UI code either.
- If a feature cannot be built without someone else's code or data, stop and
  tell Kevin instead of working around it.

## Conventions
- Lua 5.1, tabs for indentation, English code comments, no external libraries (no Ace3).
- All user-facing strings go through `ns.L`; add every key to `Locales/enUS.lua`
  and translate it in `Locales/deDE.lua`.
- Module names are SavedVariables keys – never rename a released module without a migration in `Core/Database.lua`.
- `OnDisable` must undo everything `OnEnable` did; events are unregistered automatically.
- Each option in `info.options` needs a default in `info.defaults`.
- New WoW API globals must be added to `read_globals` in `.luacheckrc`.

## Checks
- `luacheck .` must pass before committing
  (install with `apt-get install lua5.1 luarocks && luarocks install luacheck`).
- There are no automated tests: Kevin verifies every change in-game. Do not add
  a mocked WoW API. In the PR description, list what he should check in-game.
