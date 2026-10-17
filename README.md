# Quality of Life Forever

Many small quality-of-life improvements for World of Warcraft **Forever**.
Every feature can be turned on or off individually.

## Missing a feature?

New quality-of-life features can be requested at any time:
[open an issue on GitHub](https://github.com/PhenomDevel/Quality-of-Life-Forever/issues/new)
and describe what you would like the addon to do.

## Features

Every module is off by default unless marked *(on by default)*. Turning a
module off restores your previous game settings. Categories and modules are
listed in the same order as in the options.

### Character

#### Custom player name
Shows a name of your choice on your player frame (only visible to you).
- Name – set via a button

#### Hide player name
Hides your name on the player frame.

#### Item level
Shows the item level on equipment, colored by quality.
- Show on: character frame, bags (weapons and armor), inspect frame
- Display: color by quality

#### Repair costs
Shows what repairing all equipped items costs at the top of the character
frame. Hidden when nothing needs repairing.

#### Show durability
Durability of each equipped item in percent on the character frame.
- Hide at 100%

### Chat

#### Chat comfort
Small improvements for the chat windows.
- History: number of lines per chat window (128–4096, default 1024)
- Display: Shift + mouse wheel jumps to the first or newest message, hide the
  menu, channel and voice buttons

#### Chat highlight
Colors your name and your keywords in other players' messages and plays a
sound.
- Mentions: your name, keywords (editable list), sound on mention
- Whispers: loud whisper sound – also when sound effects are muted

#### Class colors in chat
Colors player names in chat by class.

#### Copyable URLs
Turns web addresses in chat into links. Click one to get it in a box, ready to
copy.

#### Short channel names
`[1. General - Elwynn Forest]` → `[1.G]`, `[2. Trade]` → `[2.T]`. Custom
channels keep their name.

#### Spam filter
Channel, say and yell messages with one of your keywords are shown only in a
separate "Spam" chat tab. Nothing is deleted.
- Keywords – editable list, default `boost, goldselling, carry`
- Spam tab – recreate the tab if it was closed

### Cooldown Manager

#### Keybinds
Shows the keybind of the matching action button on the icons of the cooldown
manager.
- Separately for essential and utility cooldowns: show, font size (8–38 px),
  position (corners, edges, center), horizontal/vertical offset (±30 px)

### Graphics & Camera

#### Max camera distance
Lets you zoom the camera out further.
- Zoom factor (1.0–4.0)

#### Advanced graphics
Graphics settings not available in the game options. Higher values cost
performance. Adjust the sliders, then press *Apply*.
- Ground clutter: density, distance, fade distance
- View distance: object view distance, object cull size, terrain detail
  distance
- Effects: always sharpen, water reflections, weather density
- Actions: Apply, Restore

### Interface

#### Declutter interface
Hides on-screen messages and frames you don't need.
- Messages: red error messages, zone names, event
  banners such as "Level up"
- In combat: hide the objective tracker

#### Skip cinematics
Skips in-game cinematics and pre-rendered movies. Hold Shift when one starts to
watch it.
- In-game cinematics
- Movies
- Only seen movies – play each movie once, skip it afterwards

### Loot

#### Auto-confirm BoP loot
Confirms the Bind on Pickup loot dialog while you are not in a group.

#### Auto loot
Turns on the game's auto loot.

#### Fast loot
Loots everything instantly when auto loot is on.

### Merchant & trainer

#### Auto-repair *(on by default)*
Repairs all items at a merchant that can repair.
- Use guild funds – falls back to your own gold

#### Auto-sell junk *(on by default)*
Sells all grey items at a merchant.
- Show summary – number of items and gold earned

#### Train all
Adds a *Train all* button to the trainer window that learns every available
skill at once. Professions are left out. Hover the button to see the total
cost; with too little gold it learns in list order until the money runs out.

### Quests

#### Auto quests
Accepts offered quests and turns in completed ones. Stops when you have to
choose a reward or a quest costs money. Hold Shift while talking to the NPC to
do it yourself.
- Actions: accept quests, turn in quests
- Filter: skip low-level (gray) quests

#### Instant quest text
Shows quest text at once instead of fading it in.

#### Quest progress in chat
Copies quest progress messages (e.g. "Wolf slain: 3/10") into the chat.

#### Skip gossip
Selects the only dialog option of an NPC without quests (flight master,
innkeeper, …). Hold Shift while talking to the NPC to see the dialog.

### Social

#### Auto-accept group invites
Accepts group invites. Role checks and invites that would remove you from a
queue are left to you.
- Accept from: friends, guild members
- Messages: notify in chat

#### Auto-accept summons
Accepts summons and resurrections while out of combat and outside boss
encounters.
- Accept: summons, resurrections
- Messages: notify in chat

#### Auto-decline duels
Declines all duel requests.
- Notify in chat

#### Auto-decline guild invites
Declines guild invites and guild charters (never your own charter).
- Decline: guild invites, guild charters
- Messages: notify in chat

### Tooltip

#### Tooltip extras
Adds more information to unit, item and spell tooltips.
- Units: guild rank, target, class colored names
- Items & spells: item and spell IDs

#### Tooltip tweaks
- Position: Blizzard default, at the cursor, right or left of the cursor
- Appearance: scale, background opacity

### World map

#### Movable world map
Scales the windowed world map (map and quest log) and lets you move it by
dragging its title bar. The fullscreen map stays unchanged.
- Size: scale (default 80%)
- Position: movable – position is saved, reset position

#### Zone level ranges
Level ranges of the zones, colored by your level.
- World map: on zone maps, on continent maps, in the zone name on hover
- Minimap: range of your current zone

## Usage

Open the options via *Esc → Options → AddOns → Quality of Life Forever*, the
addon button next to the minimap, or `/qol`.

| Command                 | Effect                                        |
|-------------------------|-----------------------------------------------|
| `/qol`                  | Open options                                  |
| `/qol list`             | List all features and whether they are on     |
| `/qol enable <feature>` | Turn a feature on (e.g. `/qol enable fastloot`) |
| `/qol disable <feature>`| Turn a feature off                            |
| `/qol toggle <feature>` | Toggle a feature                              |
| `/qol reset`            | Reset all settings                            |

Settings are shared by all characters on your account.

## Bugs and suggestions

Please report bugs and ideas on
[GitHub](https://github.com/PhenomDevel/Quality-of-Life-Forever/issues).

## AI-assisted development

This addon is developed with the help of AI ([Claude](https://claude.ai) by
Anthropic). **Every part of the code is reviewed by a professional software
developer before it is merged.**
