# Changelog

## v0.10.0 (2026-10-19)

### Options
- Category pages show a list of modules on the left and the selected
  module's options on the right; modules can be switched on and off right in
  the list, and the description is shown at the top of the options
- The selected module is remembered per page; the search uses the same layout
- Minimum window width is now 900 px

### Chat
- New: copy chat – a small button on every chat window opens its history as
  plain text, ready to copy with Ctrl+C
- Chat filters (spam filter, guild ads tab, highlight, clickable URLs) do less
  work per message

### Reminders
- New: missing self-buffs – a popup out of combat when a long-lasting class
  buff you know is missing (e.g. Arcane Intellect, Inner Fire, Mark of the
  Wild); optional sound, not in rest areas by default

### Widgets
- New: junk widget – the cheapest gray items in your bags with their vendor
  value; click an item to delete it (no confirmation, gray items only)
- Five second rule: countdown of the seconds left in the middle of the bar,
  with adjustable size

## v0.9.0 (2026-10-18)

### Options
- Categories reorganized: new **Reminders** category; Bags become **Bags &
  items** (item level, durability, repair costs); Camera and Graphics merged;
  statistics search and experience bar moved to Interface
- Hints and reminders appear as small popups (bottom right, movable in Edit
  Mode) and only out of combat; click to close. Turn them off under General
  to get chat messages instead; a test button shows a sample popup
- Every reminder has a preview button

### Widgets
- New category for movable overlays; the XP widget moved here
- New: gold widget – gold, gain/loss this session and gold per hour,
  horizontal or vertical
- New: reputation widget
- New: FPS & latency widget
- New: ammo & reagents widget – ammo while a bow, gun or crossbow is
  equipped, and your class reagents; turns red when running low
- New: energy tick & five second rule – bar to the next energy tick, and in
  combat a 5 second countdown after you spend mana; preview while the
  options or Edit Mode are open
- Combine widgets: all widgets in one column, moved together (switch at the
  top of the Widgets page)
- Gold and XP sessions start over on login, daily (server reset) or only
  manually; per character, counting online time only
- XP widget: last 1–5 level times; hidden at max level

### Reminders
- New: talent point reminder – on login and when points from a level-up are
  still unspent after a while (default 60 min); count on the talent button
- New: durability warning when an item drops below a threshold
- Trainer reminder lists new skills in a popup, with icons
- Pet happiness warning as a popup

### Interface
- New: combat text on/off (damage, healing, scrolling text)
- Cooldown manager: icons light up while their key is held

### Loot
- New: auto-greed on green items (optionally blue), skips BoP items

### Map
- Zone level range on the minimap can be moved and resized

### Bags & items
- Item level only on items inside bag windows, no longer on the bag bar

## v0.8.0 (2026-10-18)

### Options
- The addon version is shown in the options window header and in the
  minimap button tooltip

### XP Bar
- XP widget: new layout option – horizontal (as before) or vertical, with
  the bar on the left filling from bottom to top and the texts stacked next
  to it

## v0.7.0 (2026-10-18)

### Options
- Game settings (CVars) and option names in descriptions, notices and chat
  messages are highlighted, so you can tell what a text refers to

### XP Bar
- XP widget: background opacity 0–100 %, the border fades along

## v0.6.0 (2026-10-18)

### Bags
- New category for bag features
- New: auto-sort bags – runs the game's bag cleanup when you open your
  backpack (not in combat or with an item on the cursor)
- New: free bag slots – free/total slots on the backpack button, red when
  full, adjustable text size

### Options
- Notices in the module cards highlight game settings a module changes and
  things it does on its own, also while the module is off
- Labels, notes and sub-headers of all modules reviewed: clearer names,
  consistent wording, notices for auto-repair, auto-sell junk and the
  experience bar

### Quests
- Quest item sparkle works now: it turns on the game's sparkle effect and
  leaves the outline mode alone; your previous outline mode is restored.
  Applies to objects that appear after enabling it

## v0.5.0 (2026-10-18)

### Options and look
- New options window of its own (`/qol`, minimap button or addon menu):
  search, categories in a sidebar, option cards in up to three columns,
  resizable via the corner grip; the size is saved
- Keywords and names (spam filter, guild recruitment tab, chat highlight,
  custom player name) are edited in text fields directly in the options
- Hints in the options when a module still needs something from you
- New minimap button: click opens the options, right-click opens Edit Mode;
  drag it around the minimap, hide it with `/qol minimap`
- New accent color (blue) and logo; higher contrast throughout
- The Blizzard settings page now only opens the options window

### Character
- New: pet happiness warning – chat, screen message and sound when your
  hunter pet becomes unhappy, with the food it eats

### Merchant & Trainer
- Trainer reminder: skill icons in the chat message; the options tell you to
  visit your class trainer once while no skill data is known yet

### Quests
- Auto accept/turn in quests: pauses after a game error (e.g. full bags)
  until you close the conversation

### World map
- Movable world map: scale up to 150 %

### XP Bar
- New: XP widget – a small movable XP display with level, progress, rested
  XP, XP of quests ready to turn in, XP per hour and time to level; drag it
  directly, scale it in Edit Mode, adjustable text size, optionally hides the
  standard XP bar
- XP per hour keeps counting through combat and after a /reload, refreshes
  every 3 seconds and shows "< 1 Min" just before a level-up

## v0.4.0 (2026-10-17)

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
- Train all button: new option to use it at pet trainers too (spends your
  pet's training points)

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
- New: experience bar – XP text always visible; XP per hour and time to level
  in the text and/or the tooltip, with gains to level in the tooltip

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
