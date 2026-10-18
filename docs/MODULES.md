# Writing modules

Every feature is a self-contained **module** that can be toggled individually
in the options window (`/qol`, the minimap or *Options → AddOns → Quality of
Life Forever → Open options*) or via
`/qol enable|disable|toggle <module>`.

## New module

A module is a single file containing code, strings (enUS + deDE) and its
luacheck globals, so parallel module PRs don't collide in shared files.

1. Copy `docs/ModuleTemplate.lua` to `QualityOfLifeForever/Modules/<Category>/<Name>.lua`.
2. Add it to its category section in the `.toc` (alphabetical).
3. Strings via `ns.NewLocale({ enUS = {...}, deDE = {...} })` in the module file
   (lookup: client locale → enUS → key). Mark references in user-facing
   texts so they are highlighted: `` `cvarName` `` for game settings (CVars)
   and `{Label}` for options and buttons of this addon or the game (rendered
   by `ns.Utils.Markup` in the options window and chat output).
4. Declare used WoW API in the first line:
   `-- luacheck: read globals SomeApi C_Something`
5. Run `luacheck .`, test in-game.

## `ns:NewModule(name, info)`

| Field             | Type    | Description |
|-------------------|---------|-------------|
| `title`           | string  | Name in the options window (localized) |
| `description`     | string  | Tooltip of the module title (localized) |
| `note`            | string  | Optional gray line below the title (localized); keep titles short (~28 chars) and put details here |
| `notice`          | string  | Optional hint the user should not miss (localized), e.g. which game settings the module changes or what it does on its own; shown highlighted in the module's card, also while it is disabled. Keep it out of `description` |
| `status`          | function | Optional `function(module)` returning a hint (localized) while the module can't work yet, else `nil`; shown in the options window |
| `category`        | string  | `INTERFACE` (default), `BAGS`, `CAMERA`, `CHARACTER`, `CHAT`, `COOLDOWN_MANAGER`, `GRAPHICS`, `LOOT`, `MAP`, `MERCHANT`, `QUESTS`, `SOCIAL`, `STATISTICS`, `TOOLTIP`, `WIDGETS`, `XP_BAR` |
| `order`           | number  | Position within the category; lower comes first, ties sorted by title (default 0) |
| `defaultEnabled`  | boolean | Initial state for new users (default `false`) |
| `defaults`        | table   | Option defaults, merged into `self.db` |
| `options`         | table   | Option descriptors for the options window (see below) |
| `combatProtected` | boolean | Enable/disable is deferred until combat ends (protected frames) |
| `requiresReload`  | boolean | Offer a `/reload` after disabling |

The module name is the SavedVariables key – **don't rename a released module**
without a migration in `Core/Database.lua`.

### Options

```lua
{ key = "showSummary", type = "checkbox", label = L.X, tooltip = L.X_DESC }
{ key = "amount", type = "slider", label = L.X, tooltip = L.X_DESC, min = 1, max = 10, step = 1 }
{ key = "mode", type = "dropdown", label = L.X, tooltip = L.X_DESC,
  values = { { value = "a", label = L.A }, { value = "b", label = L.B } } }
{ key = "keywords", type = "text", label = L.X, tooltip = L.X_DESC,
  multiline = true, placeholder = L.X_HINT, maxLetters = 1000 }   -- saved on Enter / focus loss
{ type = "header", label = L.X }   -- section title inside the module's options
{ type = "button", label = L.X, buttonText = L.APPLY, tooltip = L.X_DESC,
  onClick = function(module) ... end }   -- no key/default; only runs while enabled
```

Any option may have a `note` (gray line below it). Every option except buttons and headers needs an entry in `defaults`. Options are only
editable while the module is enabled.

## Lifecycle

| Callback                      | When |
|-------------------------------|------|
| `OnInitialize()`              | once, after SavedVariables are loaded (`ADDON_LOADED`) |
| `OnEnable()`                  | on login (if enabled) and every time the module is switched on |
| `OnDisable()`                 | every time the module is switched off – undo everything it changed; events are unregistered and CVars restored afterwards |
| `OnOptionChanged(key, value)` | an option changed while the module is enabled |

Callback errors are caught and routed to the error handler, so a broken module
doesn't take others down.

## Helpers

| Method                                    | Description |
|-------------------------------------------|-------------|
| `self:RegisterEvent(event[, handler])`    | Without a handler `self:<EVENT>(...)` is called. All events are unregistered on disable. |
| `self:UnregisterEvent(event)`             | Unregister a single event |
| `self:SecureHook([table,] "func", handler)` | `hooksecurefunc` that only fires while enabled |
| `self:HookScript(frame, "OnShow", handler)` | `frame:HookScript` that only fires while enabled |
| `self:Print(...)`                         | Chat output (respects the global "Show chat messages" option) |
| `self:Notice(text[, icon[, key]])`        | Small popup for hints and reminders, shown only out of combat (queued during combat); falls back to chat when the global "Popup notices" option is off. A newer notice with the same key (default: the module name) replaces the older one |
| `self:Debug(...)`                         | Output only in debug mode (`/qol debug`) |
| `self:GetOption(key)` / `self:SetOption(key, value)` | Read/write options (keeps the options window in sync) |
| `self:SetCVar(name, value)`               | Set a CVar; the original value is persisted in the module DB and restored on disable. Returns `false` for unknown CVars. |
| `self:RestoreCVars()`                     | Restore saved CVars now |
| `self.db`                                 | The module's saved data (account-wide) |
| `ns.Utils.FormatMoney(copper)`            | Money string with coin icons |
| `ns.Utils.IsSecret(value)`                | Checks for secret values (see below) |

## Overlays (2.0)

Small frames the player drags directly or moves and scales in Blizzard's Edit
Mode (via the embedded LibEditMode). Position and scale are stored
account-wide per Edit Mode layout.

```lua
local frame = ns:CreateOverlay("MyWidget", {
	title = L.EDIT_MODE_NAME,                     -- name in Edit Mode
	width = 200, height = 40,
	default = { point = "TOP", x = 0, y = -120 }, -- relative to UIParent
	settings = { ... },                           -- optional extra LibEditMode settings
})
```

- Create the overlay once (first `OnEnable`); show it in `OnEnable`, hide it in
  `OnDisable`. Frames can't be unregistered from Edit Mode; hidden ones don't
  appear there.
- The frame comes with the shared flat background and border; use
  `ns.overlayFont` for text. `ns:SetOverlayBackgroundAlpha(frame, alpha)`
  changes the opacity of background and border (0–1), e.g. for a user option.
- `ns:OpenEditMode()` opens Edit Mode (not in combat), also bound to
  right-clicking the minimap button.

## WoW Forever specifics

* Forever runs on the **modern mainline API** (Midnight base, `C_*` namespaces),
  not the old Classic Era API.
* The **Midnight addon restrictions** apply: some combat data (e.g. other
  units' health) are *secret values* – they may be displayed but not read,
  compared or used in arithmetic. Check with `ns.Utils.IsSecret(value)` first.
* Protected frames (action bars, unit frames, …) can't be modified in combat →
  set `combatProtected = true`.
