# Quality of Life Forever – notes for Claude

World of Warcraft **Forever** addon (Interface 16001, launch 2026-11-04). Forever
runs on the modern mainline API (Midnight base, `C_*` namespaces, Settings API)
including the Midnight addon restrictions (secret values). Do not assume the
old Classic Era API.

## Layout
- Dev setup and checks: `docs/DEVELOPMENT.md`. Release and shared
  conventions: see *Shared with the other PhenomDevel addons* below.
- `QualityOfLifeForever/` is the addon folder that gets installed; everything
  else (docs, tools, CI) stays in the repo only.
- Load order is defined in `QualityOfLifeForever.toc`: Locales → Core → Modules → `Core/Bootstrap.lua` (last).
- Every feature is a module created with `ns:NewModule(name, info)` in
  `Modules/<Category>/<Name>.lua`. API reference: `docs/MODULES.md`, template: `docs/ModuleTemplate.lua`.

## Branches
- `main`: released addon. `2.0`: redesign (own options window, minimap button,
  movable overlays) that may never ship – Kevin decides.
- Redesign work: feature branch from `origin/2.0`, PR against `2.0`. Merge
  `main` into `2.0` regularly (merge commit, Kevin as author).
- Everything else keeps going through `main`.

## Original code only (strict)
- Every line of code, data table and asset in this repo must be written
  independently – except the embedded libraries in `QualityOfLifeForever/Libs/`
  (see *Libraries*). Never copy, port, translate or closely paraphrase code from
  other addons (e.g. Leatrix Plus/Maps, BlizzMove, ElvUI, …) – regardless of
  their license.
- Other addons may only be named as *feature inspiration* ("what"), never as a
  source for the implementation ("how"). Do not open or read their source code
  while implementing a feature.
- Data (e.g. map overlay coordinates, zone level ranges, item lists) comes
  from the game API at runtime, is collected by us in-game, or is taken from
  public references such as wikis (name the source in a comment) – never
  from another addon's data files.
- Allowed references: the official WoW API (function/event names and
  signatures, documented behavior) and Blizzard's UI only to learn which
  function/frame to hook – do not copy Blizzard UI code either.
- If a feature cannot be built without someone else's code or data, stop and
  tell Kevin instead of working around it.

## Libraries
- Only libraries Kevin approved: currently **LibEditMode** (frames in Blizzard's
  Edit Mode). No Ace3 – the options window, minimap button and widgets are our own.
- Embedded unmodified in `QualityOfLifeForever/Libs/<Name>/` with their license
  file, loaded first in the `.toc`. Update them only via `tools/update-libs.sh`
  (pinned versions); never edit a library file.
- LibEditMode is embedded namespaced (`ns.LibEditMode`), without LibStub.
- Libraries are excluded from luacheck.

## Conventions
- Lua 5.1, tabs for indentation, English code comments, no libraries beyond *Libraries*.
- All docs (`*.md`) in English; in-game strings in enUS + deDE.
- Modules are self-contained in one file: strings via `ns.NewLocale({ enUS = …, deDE = … })`,
  WoW API declared inline (`-- luacheck: read globals …`). Core strings stay in `Locales/`.
- One PR per module; a module PR only adds its file plus one line in its `.toc`
  category section. Don't touch `docs/IDEAS.md`/`README.md` in module PRs
  (updated in a separate docs PR) to avoid conflicts between parallel PRs.
- Module names are SavedVariables keys – never rename a released module without a migration in `Core/Database.lua`.
- `OnDisable` must undo everything `OnEnable` did; events are unregistered automatically.
- Each option in `info.options` (except buttons and headers) needs a default in `info.defaults`.
- Group options with `{ type = "header", label = … }` when a module has distinct sub-groups.
- `.luacheckrc` holds core globals only.
- Changing CVars: use `self:SetCVar()`, which restores the user's value on disable.

## Checks
- `luacheck .` must pass before committing
  (install with `apt-get install lua5.1 luarocks && luarocks install luacheck`).
- There are no automated tests: Kevin verifies every change in-game. Do not add
  a mocked WoW API. In the PR description, list what he should check in-game.

## Shared with the other PhenomDevel addons
PhenomRaidTools, BlizzHUDTweaks, Quality-of-Life-Forever and
Guild-Finder-Forever follow the same conventions below; this section is
identical in their `CLAUDE.md`. A change to a shared file or rule goes to all
four (one PR per repository).

- Release process: `docs/RELEASE.md`. `.github/workflows/release.yml`,
  `.github/workflows/ci.yml` and `docs/RELEASE.md` are identical in all four,
  except the `env` block of `release.yml` and the "This repository" section
  of `RELEASE.md`.
- Tags: `vX.Y.Z`, test releases `vX.Y.Z-alphaN` / `-betaN`. Releases are
  started by Kevin (*Actions → Release → Run workflow*); never push tags or
  start the release workflow without being asked.
- Every user-facing PR adds a line under `## Unreleased` in `CHANGELOG.md`
  (written for players). A release PR renames it to `## vX.Y.Z (YYYY-MM-DD)`
  and adds the "What's new" entry where the addon has one.
- READMEs are for players only, outline in this order:
  1. `# Name`, logo (`<img … width="96" align="right">` with an absolute
     `https://raw.githubusercontent.com/…` URL, so it also renders on
     CurseForge/Wago), badges: Version, CurseForge, License (same set in all
     four)
  2. summary: bold one-line tagline and a short abstract
  3. `## Supported versions`: table `Client | Interface`, matching the `.toc`
  4. `## Installation`: CurseForge/Wago app or GitHub releases, manual
     install folder, first command; then a link to `CHANGELOG.md`
  5. `## Features`, ending with `### Commands` (table)
  6. `## Support`: common issues, GitHub issues, Discord where the addon has
     one, tip link `https://streamlabs.com/phenombutbetter/tip`
  7. footer "Developed with the help of AI …"
- No developer, API, release or guide content in the README; that belongs in
  `docs/` (e.g. `docs/DEVELOPMENT.md`, `docs/RELEASE.md`).
