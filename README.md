# Quality of Life Forever

Small quality-of-life improvements for World of Warcraft **Forever** in one
addon. Every feature can be switched on and off on its own; almost all are off
until you turn them on. Features that change game settings or act without
asking are marked in the options, and turning them off restores your previous
settings. A feature that is off runs no code at all: it sets nothing up until
you turn it on, and if you turn it off again, the addon offers a reload to
unload it completely.

**Open the options:** `/qol`, the button at the minimap, or the addon menu
next to the minimap. The options have their own window: features on the left,
the settings of the selected one on the right, plus a search. Drag its corner to
resize it.

**Move widgets:** while the options are open, every widget and a sample
reminder are shown with their names, so you can drag them into place; the
*Preview* switch in the title bar turns this off. Right-click the minimap button
(or *Esc → Edit Mode*) to scale them.

**What's new:** after an update to a new version, a window shows the most
important changes once (can be turned off under *General*; `/qol news` opens
it again).

**Missing a feature?**
[Request it on GitHub](https://github.com/PhenomDevel/Quality-of-Life-Forever/issues/new).

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

## Commands

| Command | Effect |
|---------|--------|
| `/qol` | Open options |
| `/qol list` | Show all features and their state |
| `/qol toggle <feature>` | Turn a feature on/off (also `enable`, `disable`) |
| `/qol minimap` | Show/hide the minimap button |
| `/qol news` | Show what's new in this version |
| `/qol reset` | Reset all settings |

## Bugs

Please report bugs on
[GitHub](https://github.com/PhenomDevel/Quality-of-Life-Forever/issues).

---

Developed with the help of AI ([Claude](https://claude.ai) by Anthropic).
Every change is reviewed by a professional software developer before it is
merged.
