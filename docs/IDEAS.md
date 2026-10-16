# Roadmap

Agreed module list, ordered by **feasibility and effort** – we work top to
bottom. Estimates are based on the modern WoW API; every assumption (e.g. "the
CVar exists") is verified in the Forever client, which has its own limits and
the Midnight addon restrictions (secret values, protected functions).

All modules are **written from scratch** – no code or data from other addons
(see `CLAUDE.md`).

`[x]` done · `[ ]` planned · `[-]` dropped

## Done
- [x] Auto repair (`AutoRepair`)
- [x] Auto sell junk (`AutoSellJunk`)
- [x] Fast loot (`FastLoot`)
- [x] Auto decline duels (`AutoDeclineDuels`)
- [-] ~~Remember buff bar state~~ – dropped: setting `BuffFrame.isExpanded` from addon code taints the buff frame, which then fails on secret aura fields

## Tier 1 – very easy
Single CVar or event, hardly any UI. All merged; the risk column lists what
still needs in-game verification.

| # | Idea | Area | Approach | Risk |
|---|------|------|----------|------|
| 1 | [x] Auto loot (`AutoLoot`) | Loot | CVar `autoLootDefault` | low |
| 2 | [x] Hide name on player frame (`HidePlayerName`) | Character | alpha on the player frame name | low: region name in Forever |
| 3 | [x] Max camera distance, default 4.0 (`CameraZoom`) | Camera | CVar `cameraDistanceMaxZoomFactor` | medium: client may cap below 4.0 |
| 4 | [x] Advanced graphics settings (`GraphicsTweaks`) | Graphics | per-CVar sliders + Apply/Restore buttons | low: ranges measured with `/qol cvarinfo` (Forever 1.60.1) |
| 5 | [x] Class colors in chat (`ChatClassColors`) | Chat | CVar `chatClassColorOverride` | low: value semantics unverified |
| 6 | [x] Instant quest text (`InstantQuestText`) | Quests | CVar `instantQuestText` (read by `QuestFrameDetailPanel_OnShow`) | low |
| 7 | [x] Auto-decline guild invites/charters (`AutoDeclineGuildInvites`) | Social | events → `DeclineGuild` / `ClosePetition` | low |
| 8 | [x] Confirm bind on pickup when solo (`AutoConfirmBindOnPickup`) | Loot | `LOOT_BIND_CONFIRM` → `ConfirmLootSlot` | low |
| 9 | [x] Auto-accept summons/resurrections (`AutoAcceptSummonResurrect`) | Social | events, only out of combat/encounter | low |
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
| 11 | [x] Custom name on player frame (`CustomPlayerName`) | Character | re-apply custom text after Blizzard name updates (hook); text entry via button + popup edit box (Settings API has no text field) | low: region name in Forever |
| 12 | [x] Tooltip font size (`TooltipAnchor`: scale) | Tooltip | scale the tooltip font objects | low |
| 13 | [x] Tooltip transparency (`TooltipAnchor`) | Tooltip | set tooltip background alpha | low |
| 14 | [-] ~~Vendor price in tooltip~~ | Merchant | dropped: Forever shows the sell price natively | – |
| 15 | [x] Accept group invites from friends/guild (`AutoAcceptGroupInvites`) | Social | check inviter against friends list/guild | low |
| 16 | [x] Skip cinematics (`SkipCinematics`) | Interface | cancel on start, optionally only already seen ones | medium: some can't be cancelled |
| 18 | [x] Quest progress in chat (`QuestProgress`) | Quests | forward progress messages to chat | low |
| 19 | [x] Durability on character frame (`ShowDurability`) | Interface | percentage per equipment slot | low |
| 20 | [x] Zone level ranges (`ZoneLevels`) | World map | `C_Map.GetMapLevels` returns 0 in Forever → static table from mobalytics leveling routes | done |

## Tier 3 – medium
Several hooks, own UI or noticeable Forever restrictions.

| # | Idea | Area | Approach | Risk |
|---|------|------|----------|------|
| 21 | [x] Item level (equipment + bags) (`ItemLevel`) | Interface | character frame easy, bags more work | low |
| 22 | [-] ~~Mail: collect all~~ | Merchant | dropped: Blizzard's mailbox already has "Open All" | – |
| 23 | [x] Shorten channel prefixes (`ShortChannelNames`) | Chat | replace channel names in messages | medium: chat restrictions in instances |
| 24 | [x] Copyable URLs (`CopyableURLs`) | Chat | turn URLs into links, click opens a copy box | medium: chat restrictions in instances |
| 25 | [x] Cooldown manager: keybinds (`CooldownKeybinds`) (show, position, size, font) | Cooldown manager | map spells to action bar bindings, overlay text; position/size/font as options of one module | medium: verify cooldown manager structure in Forever |
| 26 | [-] ~~Player notes~~ | Social | dropped | – |
| 27 | [x] Spam filter, matches moved to a "Spam" tab (`SpamFilter`) | Chat | message filter with own keyword list | medium: chat restrictions, false positives |
| 28 | [x] Smaller/movable world map (`WorldMapWindow`) | World map | change and persist map size/position | medium |

## Tier 4 – complex or unclear

| # | Idea | Area | Why |
|---|------|------|-----|
| 29 | [-] ~~Move/scale Blizzard frames~~ | Interface | dropped: a fixed frame list covers too little; dedicated addons do this better |
| 30 | [-] ~~Semi-transparent fog of war~~ | World map | dropped: the API only returns *explored* map tiles; unexplored areas would need overlay data collected in-game for every zone (other addons' data is off-limits) |

## Round 2

Agreed after closing tiers 1–4. Ordered by effort.

| # | Idea | Area | Approach | Risk |
|---|------|------|----------|------|
| 31 | [ ] Chat comfort | Chat | arrow keys in the edit box without Alt (`SetAltArrowKeyMode`), longer chat history (`SetMaxLines`), hide chat buttons, Shift + mouse wheel jumps to top/bottom | low: `SetMaxLines` clears the frame once |
| 32 | [-] ~~Nameplate settings~~ | Interface | dropped | – |
| 33 | [ ] Skip single gossip option | Quests | `GOSSIP_SHOW` → select the only option when there are no quests; Shift pauses | low |
| 34 | [ ] Auto accept / turn in quests | Quests | `QUEST_DETAIL`/`QUEST_PROGRESS`/`QUEST_COMPLETE`, gossip and greeting quest lists; stops at reward choices; Shift pauses | medium: quests with item/money costs |
| 35 | [ ] Tooltip extras | Tooltip | unit post-call: guild rank, target of target, class colored name; item/spell post-call: IDs | medium: unit names/lines may be secret |
| 36 | [ ] Train all | Merchant | button in the trainer frame that buys every available service (`GetNumTrainerServices`/`BuyTrainerService`), total cost in its tooltip | low: trainer frame is load-on-demand |
| 37 | [ ] Repair costs on the character frame | Character | sum of `C_TooltipInfo.GetInventoryItem` repair costs of equipped items, shown on the character frame | low |
