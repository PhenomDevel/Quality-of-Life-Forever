# Roadmap

Agreed module list, ordered by **feasibility and effort** – we work top to
bottom. Estimates are based on the modern WoW API; every assumption (e.g. "the
CVar exists") is verified in the Forever client, which has its own limits and
the Midnight addon restrictions (secret values, protected functions).

All modules are **written from scratch** – no code or data from other addons
(see `CLAUDE.md`).

`[x]` done · `[ ]` planned

## Done
- [x] Auto repair (`AutoRepair`)
- [x] Auto sell junk (`AutoSellJunk`)
- [x] Fast loot (`FastLoot`)
- [x] Auto decline duels (`AutoDeclineDuels`)

## Tier 1 – very easy
Single CVar or event, hardly any UI. All merged; the risk column lists what
still needs in-game verification.

| # | Idea | Area | Approach | Risk |
|---|------|------|----------|------|
| 1 | [x] Auto loot (`AutoLoot`) | Loot | CVar `autoLootDefault` | low |
| 2 | [x] Hide name on player frame (`HidePlayerName`) | Character | alpha on the player frame name | low: region name in Forever |
| 3 | [x] Max camera distance, default 4.0 (`CameraZoom`) | Camera | CVar `cameraDistanceMaxZoomFactor` | medium: client may cap below 4.0 |
| 4 | [x] Advanced graphics settings (`GraphicsTweaks`) | Graphics | per-CVar sliders + Apply/Restore buttons | low: ranges estimated, values may be clamped |
| 5 | [x] Class colors in chat (`ChatClassColors`) | Chat | CVar `chatClassColorOverride` | low: value semantics unverified |
| 6 | [x] Instant quest text (`InstantQuestText`) | Quests | CVar `questFadingDisable` | medium: CVar may not exist → tier 2 hook |
| 7 | [x] Decline guild invites/charters (`AutoDeclineGuildInvites`) | Social | events → `DeclineGuild` / `ClosePetition` | low |
| 8 | [x] Confirm bind on pickup when solo (`AutoConfirmBindOnPickup`) | Loot | `LOOT_BIND_CONFIRM` → `ConfirmLootSlot` | low |
| 9 | [x] Accept summons/resurrections (`AutoAcceptSummonResurrect`) | Social | events, only out of combat/encounter | low |
| 10 | [x] Anchor tooltip to cursor (`TooltipAnchor`) | Tooltip | post-hook `GameTooltip_SetDefaultAnchor` | low |

Graphics defaults for #4:
```
/console groundEffectDensity 256
/console groundEffectFade 370
/console groundEffectDist 500
/console lodObjectFadeScale 200
/console lodObjectCullSize 8
/console terrainLodDist 1000
/console ResampleAlwaysSharpen 1
/console reflectionMode 3
/console weatherdensity 3
```

## Tier 2 – easy
One hook or event, some logic or a small display.

| # | Idea | Area | Approach | Risk |
|---|------|------|----------|------|
| 11 | [ ] Custom name on player frame | Character | re-apply custom text after Blizzard name updates (hook); text entry via button + popup edit box (Settings API has no text field) | low: region name in Forever |
| 12 | [ ] Tooltip font size | Tooltip | scale the tooltip font objects | low |
| 13 | [ ] Tooltip transparency | Tooltip | set tooltip background alpha | low |
| 14 | [ ] Vendor price in tooltip | Merchant | item tooltip post-call, sell price × stack | low |
| 15 | [ ] Accept group invites from friends/guild | Social | check inviter against friends list/guild | low |
| 16 | [ ] Skip cinematics | Interface | cancel on start, optionally only already seen ones | medium: some can't be cancelled |
| 17 | [ ] Buy full stack with Shift | Merchant | hook merchant item click, buy max stack | low |
| 18 | [ ] Quest progress in chat | Quests | forward progress messages to chat | low |
| 19 | [ ] Durability on character frame | Interface | percentage per equipment slot | low |
| 20 | [ ] Zone level ranges | World map | level range from the map API | medium: only if the API returns data in Forever |

## Tier 3 – medium
Several hooks, own UI or noticeable Forever restrictions.

| # | Idea | Area | Approach | Risk |
|---|------|------|----------|------|
| 21 | [ ] Item level (equipment + bags) | Interface | character frame easy, bags more work | low |
| 22 | [ ] Mail: collect all | Merchant | mailbox button, throttled processing, full bags | medium |
| 23 | [ ] Shorten channel prefixes | Chat | replace channel names in messages | medium: chat restrictions in instances |
| 24 | [ ] Copyable URLs | Chat | turn URLs into links, click opens a copy box | medium: chat restrictions in instances |
| 25 | [ ] Cooldown manager: keybinds (show, position, size, font) | Cooldown manager | map spells to action bar bindings, overlay text; position/size/font as options of one module | medium: verify cooldown manager structure in Forever |
| 26 | [ ] Player notes | Social | store notes, show in tooltip, edit via context menu | medium: player names may be secret |
| 27 | [ ] Spam filter (optional guild recruitment tab) | Chat | message filter with own keyword list | medium: chat restrictions, false positives |
| 28 | [ ] Smaller/movable world map | World map | change and persist map size/position | medium |

## Tier 4 – complex or unclear

| # | Idea | Area | Why |
|---|------|------|-----|
| 29 | [ ] Move/scale Blizzard frames | Interface | many frames, some protected in combat or load-on-demand, persist positions |
| 30 | [ ] Semi-transparent fog of war | World map | The API only returns *explored* map tiles. Unexplored areas would need our own map data collected in-game (other addons' data is off-limits). Feasibility open. |
