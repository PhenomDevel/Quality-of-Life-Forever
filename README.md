# Quality of Life Forever

## AI-assisted development

This addon is developed with the help of AI ([Claude](https://claude.ai) by
Anthropic). Every part of the code is reviewed by a professional software
developer before it is merged.

## About

A World of Warcraft **Forever** addon bundling many small quality-of-life
improvements. Each improvement is a self-contained module that can be enabled
or disabled individually.

## Modules

| Module                          | Category  | Default | Description |
|---------------------------------|-----------|---------|-------------|
| Hide name on player frame       | Character | off     | Hides your name on the player unit frame |
| Anchor tooltip to cursor        | Tooltip   | off     | Default-anchored tooltips follow the cursor (3 positions) |
| Max camera distance             | Camera    | off     | Sets `cameraDistanceMaxZoomFactor` (1.0–4.0) |
| Advanced graphics settings      | Graphics  | off     | Sliders for hidden graphics CVars, Apply/Restore buttons |
| Auto repair                     | Merchant  | on      | Repairs all items at a merchant, optionally using guild funds |
| Auto sell junk                  | Merchant  | on      | Sells poor quality (grey) items at a merchant |
| Confirm bind on pickup when solo| Loot      | off     | Auto-confirms the BoP loot dialog outside of groups |
| Auto loot                       | Loot      | off     | Turns on the game's auto loot setting |
| Fast loot                       | Loot      | off     | Loots all slots instantly when auto loot is active |
| Instant quest text              | Quests    | off     | Shows quest text without fade-in |
| Auto-accept summons & resurrections | Social | off     | Auto-accepts out of combat and outside boss encounters |
| Auto decline duels              | Social    | off     | Declines duel requests |
| Auto-decline guild invites & charters | Social | off     | Declines guild invites and charter signature requests |
| Class colors in chat            | Chat      | off     | Colors player names in chat by class |

CVar-based modules restore your previous values when disabled.

Roadmap: [`docs/IDEAS.md`](docs/IDEAS.md)

## Usage

* **Options:** *Esc → Options → AddOns → Quality of Life Forever*, the addon
  compartment next to the minimap, or `/qol`.
* **Slash commands** (`/qol` or `/qolforever`):

  | Command                 | Effect |
  |-------------------------|--------|
  | `/qol`                  | Open options |
  | `/qol list`             | List modules and their state |
  | `/qol enable <module>`  | Enable a module (e.g. `/qol enable fastloot`) |
  | `/qol disable <module>` | Disable a module |
  | `/qol toggle <module>`  | Toggle a module |
  | `/qol debug`            | Toggle debug output |
  | `/qol reset`            | Reset all settings (with confirmation) |

Settings are stored account-wide in `QualityOfLifeForeverDB`.

## Installation

Copy the `QualityOfLifeForever` folder (not the whole repository) to
`World of Warcraft/_classic_beta_/Interface/AddOns/` (Forever beta; launch
client folder from 2026-11-04). The folder name must match the `.toc` name.

For development, link the folder into the client so `git pull` + `/reload` is
enough:

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

## Development

```
QualityOfLifeForever/        addon folder (the only thing that gets installed)
  QualityOfLifeForever.toc   load order, interface version, SavedVariables
  Locales/                   enUS (base) + deDE
  Core/                      DB, module registry/lifecycle, settings panel, slash commands
  Modules/<Category>/        one file per module
docs/                        module API, template, roadmap
.pkgmeta                     packaging config (BigWigs packager)
```

* Module API and template: [`docs/MODULES.md`](docs/MODULES.md),
  [`docs/ModuleTemplate.lua`](docs/ModuleTemplate.lua)
* Lint: `luacheck .` (also runs in CI on every push). Functionality is
  verified in-game; there are no automated tests.
* Release: update `CHANGELOG.md`, then push a `v*` tag (`v0.1.0`, or
  `v0.1.0-beta1` / `-alpha1` for test releases). The workflow lints and runs the
  [BigWigs packager](https://github.com/BigWigsMods/packager), which uploads to
  CurseForge (`## X-Curse-Project-ID`, secret `CF_API_KEY`) and GitHub
  releases. The CurseForge upload is skipped without ID or secret.
  Local test build without upload:
  `curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- -d`
  (zip in `.release/`).
* All code is original. No code or data is taken from other addons.

### Interface version

The `.toc` declares `## Interface: 16001` (Forever beta). If the launch build
uses a different value, read it via `/dump select(4, GetBuildInfo())` and
update the `.toc`, otherwise the client flags the addon as out of date.

## License

GPL-3.0, see [`LICENSE`](LICENSE).
