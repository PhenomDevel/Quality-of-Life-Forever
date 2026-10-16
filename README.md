# Quality of Life Forever

Many small quality-of-life improvements for World of Warcraft **Forever**.
Every feature can be turned on or off individually.

## Features

Every module is off by default unless marked *(on by default)*. Turning a
module off restores your previous game settings.

### Interface

#### Game font
Replaces the standard interface font with one of the game's fonts and
changes its size. Chat windows switch after `/reload`.
- Font: Friz Quadrata, Arial Narrow, Skurri, Morpheus (previewed in the list)
- Size: 80–150%

#### Skip cinematics
Skips in-game cinematics and pre-rendered movies. Hold Shift when one starts to
watch it.
- In-game cinematics
- Movies
- Only seen movies – play each movie once, skip it afterwards

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

#### Show durability
Durability of each equipped item in percent on the character frame.
- Hide at 100%

### Tooltip

#### Tooltip tweaks
- Position: Blizzard default, at the cursor, right or left of the cursor
- Appearance: scale, background opacity

### Camera

#### Max camera distance
Lets you zoom the camera out further.
- Zoom factor (1.0–4.0)

### Graphics

#### Advanced graphics
Graphics settings not available in the game options. Higher values cost
performance. Adjust the sliders, then press *Apply*.
- Ground clutter: density, distance, fade distance
- View distance: object view distance, object cull size, terrain detail
  distance
- Effects: always sharpen, water reflections, weather density
- Actions: Apply, Restore

### Merchant

#### Auto repair *(on by default)*
Repairs all items at a merchant that can repair.
- Use guild funds – falls back to your own gold

#### Auto sell junk *(on by default)*
Sells all grey items at a merchant.
- Show summary – number of items and gold earned

### Loot

#### Auto-confirm BoP loot
Confirms the Bind on Pickup loot dialog while you are not in a group.

#### Auto loot
Turns on the game's auto loot.

#### Fast loot
Loots everything instantly when auto loot is on.

### Quests

#### Instant quest text
Shows quest text at once instead of fading it in.

#### Quest progress in chat
Copies quest progress messages (e.g. "Wolf slain: 3/10") into the chat.

### Social

#### Auto-accept: group invites
Accepts group invites. Role checks and invites that would remove you from a
queue are left to you.
- Accept from: friends, guild members
- Messages: notify in chat

#### Auto-accept: summons
Accepts summons and resurrections while out of combat and outside boss
encounters.
- Accept: summons, resurrections
- Messages: notify in chat

#### Auto-decline: duels
Declines all duel requests.
- Notify in chat

#### Auto-decline: guild
Declines guild invites and guild charters (never your own charter).
- Decline: guild invites, guild charters
- Messages: notify in chat

### Chat

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

### World map

#### Movable world map
Scales the windowed world map (map and quest log) and lets you move it by
dragging its title bar. The fullscreen map stays unchanged.
- Scale (default 80%)
- Movable – position is saved
- Reset position

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
