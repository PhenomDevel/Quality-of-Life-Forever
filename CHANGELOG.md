# Changelog

## Unreleased

### Camera
- Max camera distance has its own category

### Chat
- New: chat comfort – longer chat history (up to 4096 lines), Shift + mouse
  wheel jumps to the first/newest message
- New: chat highlight – your name and keywords are colored in other players'
  messages, with a sound; optional loud whisper sound
- New: guild recruitment tab – guild ads go to their own "Guilds" chat tab
- New: hide chat buttons – hides the menu, channel and voice buttons

### Cooldown Manager
- New: keybinds – the key of the action button on each cooldown manager
  icon; size, position and offset adjustable per bar

### Interface
- New: declutter interface – hide red error messages, zone names and event
  banners
- New: hide objective tracker in combat
- New: repair costs – what repairing all equipped items costs, at the bottom
  of the character frame
- Item level and durability moved here from Character
- Item level: no longer shown on the bag bar

### Merchant & Trainer
- New: add train all button – a button in the trainer window that learns every
  available skill at once (professions excluded)
- New: trainer reminder – on level-up, a chat message lists the new skills at
  your class trainer and their cost

### Quests
- New: auto quests – accept and turn in quests without clicking; stops at
  reward choices and quests that cost money; skips gray quests; Shift pauses
- New: skip gossip – selects the only dialog option of NPCs without quests;
  Shift pauses
- New: quest item sparkle – quest items and objects sparkle again (keeps the
  outline mode off, also after graphics presets)
- Quest progress in chat: marked with the addon prefix; new option to share
  it with your party

### Statistics
- New: statistics search – a search box on the statistics page of the
  character window

### Tooltip
- New: tooltip extras – guild rank, target and class colored names on unit
  tooltips
- New: IDs in tooltips – item and spell IDs

### World map
- New: movable world map – scale the windowed map and drag it by its title
  bar; the position is saved

### XP Bar
- New: XP bar text – current / needed XP always on the bar, optionally with
  XP per hour and time to level
- New: XP info – XP per hour, time to level and gains to level in the XP bar
  tooltip

### Settings
- New categories: Camera, Statistics, XP Bar; *Graphics & Camera* is now
  *Graphics*, *Merchant* is now *Merchant & Trainer*; categories are sorted
  alphabetically
- Module titles unified ("Auto-accept …", "Auto-decline …", "Auto-sell junk",
  …) and option labels clarified; your settings are kept
- Options of a module are only shown while it is enabled; modules are
  separated by a line; larger modules group their options under headings

## v0.3.0 (2026-10-16)

### Character
- New: item level on the character frame, on weapons and armor in your bags
  and in the inspect frame, colored by quality

### Chat
- New: short channel names, e.g. `[1. General - Elwynn Forest]` → `[1.G]`
- New: copyable URLs – web addresses in chat become links; click one to copy it
- New: spam filter – messages with your keywords go to a separate "Spam" tab
  (default keywords: boost, goldselling, carry)

### Settings
- Modules are sorted alphabetically on every page and in `/qol list`
- Options of larger modules are grouped under small headings

## v0.2.0 (2026-10-16)

### World map
- New: zone level ranges, colored by your level
  - On continent maps on every zone and in the zone name on hover
  - On zone maps at the bottom of the map
  - At the bottom of the minimap for your current zone

### Graphics
- Object view distance and terrain detail distance are limited to 1000
- Note that higher values cost performance

## v0.1.1 (2026-10-16)

- New addon icon in the addon list and the addon compartment

## v0.1.0 (2026-10-16)

Initial release. Every feature is a module that can be toggled individually
in Options → AddOns → Quality of Life Forever (or via `/qol`).

### Interface
- Skip cinematics and movies (optionally only already seen ones)

### Character
- Hide or replace your name on the player frame
- Durability in percent on the character frame

### Tooltip
- Anchor tooltips to the cursor, tooltip scale and background opacity

### Camera
- Zoom the camera out further

### Graphics
- Extra graphics settings not available in the game options

### Merchant
- Auto repair (optionally with guild funds)
- Auto sell junk

### Loot
- Auto loot, fast loot
- Auto-confirm Bind on Pickup loot when not in a group

### Quests
- Instant quest text
- Quest progress in chat

### Social
- Auto-accept group invites from friends and guild members
- Auto-accept summons and resurrections out of combat
- Auto-decline duels, guild invites and charters

### Chat
- Class colors for player names in chat
