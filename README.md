# Quality of Life Forever

<img src="https://raw.githubusercontent.com/PhenomDevel/Quality-of-Life-Forever/main/docs/logo/logo.png" alt="Quality of Life Forever logo" width="96" align="right">

[![Version](https://img.shields.io/github/v/release/PhenomDevel/Quality-of-Life-Forever?label=version)](https://github.com/PhenomDevel/Quality-of-Life-Forever/releases/latest)
[![CurseForge](https://img.shields.io/curseforge/dt/1748279?label=CurseForge)](https://www.curseforge.com/projects/1748279)
[![License](https://img.shields.io/github/license/PhenomDevel/Quality-of-Life-Forever)](https://github.com/PhenomDevel/Quality-of-Life-Forever/blob/main/LICENSE)

**Many small quality-of-life improvements for World of Warcraft Forever, each switchable on its own.**

Almost every feature is off until you turn it on. Features that change game
settings or act without asking are marked in the options, and turning them
off restores your previous settings. A feature that is off runs no code at
all.

## Supported versions

| Client | Interface |
| --- | --- |
| WoW: Forever | 16001 |

Retail, Classic Era and other clients are not supported.

## Installation

1. Install it with the [CurseForge](https://www.curseforge.com/projects/1748279)
   or [Wago](https://addons.wago.io/addons/L6JbyQ6v) app, or download the zip
   from [GitHub releases](https://github.com/PhenomDevel/Quality-of-Life-Forever/releases/latest).
2. Manual install: extract `QualityOfLifeForever` into
   `World of Warcraft/<client>/Interface/AddOns/` (currently `_classic_beta_`
   for the Forever beta).
3. Log in and type `/qol`.

What changed: [CHANGELOG.md](https://github.com/PhenomDevel/Quality-of-Life-Forever/blob/main/CHANGELOG.md)

## Features

| Category | Features |
|----------|----------|
| **Action bars** | Move the cooldown numbers to a corner or edge |
| **Bags & items** | Auto-sort on open · free or used slots on the backpack button · item level on gear, in bags and when inspecting · durability in % · repair costs |
| **Camera & graphics** | Larger max camera distance · extra graphics settings |
| **Character** | Custom or hidden player name · text size of health and mana on the player and target frames |
| **Chat** | Longer history · copy the chat as text · highlight your name and keywords · class colors · clickable URLs · short channel names · hide chat buttons · spam filter tab · guild ads in their own tab |
| **Cooldown Manager** | Keybinds on the cooldown icons · icons light up on key press · red keybind and gray icon while out of range · move the cooldown numbers |
| **Interface & Misc** | Hide error messages, zone text and banners · hide the objective tracker in combat · combat text on/off · skip cinematics · search on the statistics page · XP text on the standard XP bar |
| **Loot** | Auto-loot · fast loot · confirm BoP loot when solo · auto-greed on greens |
| **Merchant & trainer** | Auto-repair\* · sell junk\* · "Train all" button |
| **Quests** | Auto accept/turn in · skip single-option gossip · instant quest text · progress in chat, optionally shared with your party · sparkle on quest items |
| **Reminders** | Small popups, only out of combat: new skills at your trainer on level-up · unspent talent points (on login and an hour after a level-up) · missing self-buffs as clickable icons that cast the buff · low durability · unhappy pet |
| **Social** | Auto-accept invites and summons · auto-decline duels and guild invites |
| **Tooltip** | Position, scale and background opacity · guild rank, target, class color · item/spell IDs |
| **Widgets** | Movable overlays, optionally combined into one column, each with optional title, text outline and shadow: XP (rested and quest XP, XP per hour, adjustable bar size) · gold (session, gold per hour) · reputation · FPS & latency · ammo & reagents · five second rule with countdown · cheapest gray items, click to delete |
| **World map** | Movable, scalable map · zone level ranges, also on the minimap |

\* on by default

- **Options:** `/qol`, the minimap button or the addon menu next to the
  minimap. Features on the left, their settings on the right, plus a search.
- **Move widgets:** while the options are open, every widget is shown with
  its name so you can drag it into place. Right-click the minimap button (or
  *Esc → Edit Mode*) to scale them.
- **What's new:** after an update, a window shows the most important changes
  once.

### Commands

| Command | Effect |
|---------|--------|
| `/qol` | Open options |
| `/qol list` | Show all features and their state |
| `/qol toggle <feature>` | Turn a feature on/off (also `enable`, `disable`) |
| `/qol minimap` | Show/hide the minimap button |
| `/qol news` | Show what's new in this version |
| `/qol reset` | Reset all settings |

## Support

- Bugs: [GitHub issues](https://github.com/PhenomDevel/Quality-of-Life-Forever/issues)
- Missing a feature? [Request it on GitHub](https://github.com/PhenomDevel/Quality-of-Life-Forever/issues/new).
- If you like the addon, star it on GitHub or leave a tip on
  [Streamlabs](https://streamlabs.com/phenombutbetter/tip).

---

Developed with the help of AI ([Claude](https://claude.ai) by Anthropic).
Every change is reviewed by a professional software developer before it is
merged.
