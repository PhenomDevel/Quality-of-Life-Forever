# Development

## Layout

```
QualityOfLifeForever/        addon folder (the only thing that gets installed)
  QualityOfLifeForever.toc   load order, interface version, SavedVariables
  Libs/                      embedded third-party libraries (unmodified)
  Locales/                   enUS (base) + deDE, What's new notes
  Media/                     Logo.tga (addon icon, 64x64, 32-bit TGA from docs/logo/logo.png)
  Core/                      setup (Init.lua), DB, module registry/lifecycle, slash commands
  UI/                        options window, widgets, settings panel, minimap button,
                             overlays, notices, What's new
  Modules/<Category>/        one file per module
docs/                        developer docs, module API, template, roadmap, release process,
                             logo/ (logo.svg, README logo)
tools/                       update-libs.sh (refreshes Libs/ from pinned upstream versions)
.pkgmeta                     packaging config (BigWigs packager)
```

* Module API and template: [`MODULES.md`](MODULES.md),
  [`ModuleTemplate.lua`](ModuleTemplate.lua). Roadmap: [`IDEAS.md`](IDEAS.md)
* Settings are stored account-wide in `QualityOfLifeForeverDB`.
* `/qol debug` toggles debug output.
* All code is original. No code or data is taken from other addons, except
  the embedded libraries below.

## Libraries

| Library | Version | Purpose | License |
|---------|---------|---------|---------|
| [LibEditMode](https://github.com/p3lim-wow/LibEditMode) | 18 | Movable frames in Blizzard's Edit Mode | Own license, may be embedded unmodified (`Libs/LibEditMode/LICENSE.txt`) |

Libraries are committed unmodified so the linked addon folder works without a
build step. To update one, bump its version in `tools/update-libs.sh`, run it
and commit the result. LibEditMode is loaded namespaced (`namespaced.lua`
before `embed.xml`), so it lives in `ns.LibEditMode` and needs no LibStub.

## Local setup

Link the addon folder into the client so `git pull` + `/reload` is enough. The
folder name must match the `.toc` name.

```powershell
# Windows – directory junction, no admin rights required
New-Item -ItemType Junction `
  -Path "D:\Games\World of Warcraft\_classic_beta_\Interface\AddOns\QualityOfLifeForever" `
  -Target "D:\Dev\Quality-of-Life-Forever\QualityOfLifeForever"
```

```bash
# macOS / Linux
ln -s "$PWD/QualityOfLifeForever" "/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/QualityOfLifeForever"
```

New files or `.toc` changes may require a client restart instead of `/reload`.

## Checks

Lint: `luacheck .` (also runs in CI on every push). Functionality is verified
in-game; there are no automated tests.

## Release

Rename `## Unreleased` in `CHANGELOG.md` to `## vX.Y.Z (YYYY-MM-DD)`, merge
it, then run *Actions → Release → Run workflow* on `main` with the version
(`v0.14.0`, or `v0.14.0-beta1` / `-alpha1` for test releases). Test releases
of the 2.0 redesign are started on `2.0` and must be alpha or beta versions.
The workflow tags the commit and uploads to CurseForge, Wago and GitHub. Details,
including the "What's new" notes and the local test build:
[`RELEASE.md`](RELEASE.md) (same process in all PhenomDevel addons).

## Interface version

The `.toc` declares `## Interface: 16001` (Forever beta). If the launch build
uses a different value, read it via `/dump select(4, GetBuildInfo())` and
update the `.toc`, otherwise the client flags the addon as out of date.

## License

MIT, see [`LICENSE`](../LICENSE). The embedded libraries keep their own
licenses (see *Libraries*).
