# Development

## Layout

```
QualityOfLifeForever/        addon folder (the only thing that gets installed)
  QualityOfLifeForever.toc   load order, interface version, SavedVariables
  Locales/                   enUS (base) + deDE
  Core/                      DB, module registry/lifecycle, settings panel, slash commands
  Modules/<Category>/        one file per module
  Media/                     Logo.tga (64x64, 32-bit TGA from docs/media/logo.png)
docs/                        module API, template, roadmap, logo source
.pkgmeta                     packaging config (BigWigs packager)
```

* Module API and template: [`MODULES.md`](MODULES.md),
  [`ModuleTemplate.lua`](ModuleTemplate.lua). Roadmap: [`IDEAS.md`](IDEAS.md)
* Settings are stored account-wide in `QualityOfLifeForeverDB`.
* `/qol debug` toggles debug output.
* All code is original. No code or data is taken from other addons.

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

Add a section for the version to `CHANGELOG.md` (the whole file is uploaded
as release notes, so keep it user-facing), then push a `v*` tag (`v0.1.0`, or
`v0.1.0-beta1` / `-alpha1` for test releases). The workflow lints and runs the
[BigWigs packager](https://github.com/BigWigsMods/packager), which uploads to
CurseForge (project ID 1748279 via `## X-Curse-Project-ID`, secret `CF_API_KEY`) and GitHub releases.
The CurseForge upload is skipped without ID or secret.

Local test build without upload (zip in `.release/`):

```bash
curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- -d
```

## Interface version

The `.toc` declares `## Interface: 16001` (Forever beta). If the launch build
uses a different value, read it via `/dump select(4, GetBuildInfo())` and
update the `.toc`, otherwise the client flags the addon as out of date.

## License

GPL-3.0, see [`LICENSE`](../LICENSE).
