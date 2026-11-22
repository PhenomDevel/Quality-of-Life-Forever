-- luacheck: read globals C_Spell C_Item C_Container C_TradeSkillUI C_Timer IsPlayerSpell InCombatLockdown GetTime time UnitGUID UnitName UnitClass GetRealmName GetNumTradeSkills GetTradeSkillInfo GetTradeSkillCooldown GetTradeSkillRecipeLink
local _, ns = ...

--[[
	Profession cooldowns (Mooncloth, transmutes, Salt Shaker, ...) of every
	character, used by the ProfessionCooldownReminder and
	ProfessionCooldownWidget modules. Durations come from the game, never
	from this file, so Forever's own cooldown lengths just work.

	Sources of a character's cooldowns:
	- KNOWN_SPELLS / KNOWN_ITEMS below, read with the spell and item cooldown
	  API whenever the character knows the spell or carries the item;
	- recipes the trade skill window lists with a running cooldown; they are
	  remembered per character, so recipes missing from the lists (or added
	  by Forever) are picked up after their first craft.

	Saved in ns.db.global.professionCooldowns:
	[GUID] = { name, realm, class, learned = { [spellID] = true },
	           entries = { [key] = { name, icon, readyAt, family } } }
	readyAt is a time() timestamp (0 = ready), so it survives logouts.

	Runs only while at least one owner holds it (see Acquire/Release).
]]

local ProfessionCooldowns = {}
ns.ProfessionCooldowns = ProfessionCooldowns

-- Spell IDs from Wowhead (Classic) and warcraft.wiki.gg.
local KNOWN_SPELLS = {
	18560, -- Tailoring: Mooncloth
	11479, -- Alchemy: Transmute: Iron to Gold
	11480, -- Alchemy: Transmute: Mithril to Truesilver
	17187, -- Alchemy: Transmute: Arcanite
	17559, -- Alchemy: Transmute: Air to Fire
	17560, -- Alchemy: Transmute: Fire to Earth
	17561, -- Alchemy: Transmute: Earth to Water
	17562, -- Alchemy: Transmute: Water to Air
	17563, -- Alchemy: Transmute: Undeath to Water
	17564, -- Alchemy: Transmute: Water to Undeath
	17565, -- Alchemy: Transmute: Life to Earth
	17566, -- Alchemy: Transmute: Earth to Life
}
local KNOWN_ITEMS = {
	15846, -- Leatherworking: Salt Shaker (Refined Deeprock Salt)
}
-- Its name up to the colon ("Transmute") names the transmute family.
local TRANSMUTE_SPELL = 17187

-- Shorter cooldowns are the global cooldown or casts, not crafting cooldowns.
local MIN_COOLDOWN = 2
-- Entries of a family ready within this many seconds of each other are one
-- cooldown (shared transmute cooldown).
local SAME_COOLDOWN = 60
-- Cooldowns are not always known right at login.
local LOGIN_DELAY = 3
local SCAN_THROTTLE = 1

local IsSecret = ns.Utils.IsSecret

local owners = {}
local loginScanDone = false
local scanPending = false
local frame

local function Store()
	ns.db.global.professionCooldowns = ns.db.global.professionCooldowns or {}
	return ns.db.global.professionCooldowns
end

local function Readable(...)
	for i = 1, select("#", ...) do
		if IsSecret((select(i, ...))) then
			return false
		end
	end
	return true
end

-- time() at which a cooldown started at GetTime() `start` ends, or nil when
-- none is running.
local function ReadyAt(start, duration)
	if type(start) ~= "number" or type(duration) ~= "number" or not Readable(start, duration)
		or duration <= MIN_COOLDOWN or start <= 0 then
		return nil
	end
	return math.floor(time() + start + duration - GetTime() + 0.5)
end

local function TransmuteFamily()
	local name = C_Spell.GetSpellName(TRANSMUTE_SPELL)
	if type(name) ~= "string" or IsSecret(name) then
		return nil
	end
	return name:match("^(.-)%s*:")
end

local function Family(name, transmute)
	if transmute and type(name) == "string" and name:sub(1, #transmute + 1) == transmute .. ":" then
		return transmute
	end
	return nil
end

local function CharacterRecord()
	local store = Store()
	local guid = UnitGUID("player")
	local record = store[guid]
	if not record then
		record = { learned = {}, entries = {} }
		store[guid] = record
	end
	record.name = UnitName("player")
	record.realm = GetRealmName()
	record.class = select(2, UnitClass("player"))
	record.learned = record.learned or {}
	record.entries = record.entries or {}
	return record
end

-- Keeps a remembered readyAt while the API reports no cooldown: the spell
-- API may not report trade skill cooldowns that the window did.
local function Put(entries, old, key, name, icon, readyAt, transmute)
	local previous = old[key]
	if not readyAt then
		readyAt = previous and previous.readyAt or 0
	end
	if readyAt <= time() then
		readyAt = 0
	end
	entries[key] = {
		name = name or (previous and previous.name) or "?",
		icon = icon or (previous and previous.icon),
		readyAt = readyAt,
		family = Family(name, transmute),
	}
end

local function SpellCooldown(spellID)
	local info = C_Spell.GetSpellCooldown(spellID)
	if type(info) ~= "table" then
		return nil
	end
	return ReadyAt(info.startTime, info.duration)
end

-- Rebuilds this character's entries; spells it no longer knows and items it
-- no longer has are dropped.
local function ScanCharacter()
	local record = CharacterRecord()
	local old, entries = record.entries, {}
	local transmute = TransmuteFamily()

	local spells = {}
	for _, spellID in ipairs(KNOWN_SPELLS) do
		spells[spellID] = IsPlayerSpell(spellID) or nil
	end
	for spellID in pairs(record.learned) do
		spells[spellID] = true
	end
	for spellID in pairs(spells) do
		Put(entries, old, "spell:" .. spellID, C_Spell.GetSpellName(spellID), C_Spell.GetSpellTexture(spellID),
			SpellCooldown(spellID), transmute)
	end

	for _, itemID in ipairs(KNOWN_ITEMS) do
		local count = C_Item.GetItemCount(itemID, true)
		if type(count) == "number" and Readable(count) and count > 0 then
			local start, duration = C_Container.GetItemCooldown(itemID)
			local name = C_Item.GetItemNameByID(itemID)
			if not name and C_Item.RequestLoadItemDataByID then
				C_Item.RequestLoadItemDataByID(itemID)
			end
			Put(entries, old, "item:" .. itemID, name, C_Item.GetItemIconByID(itemID), ReadyAt(start, duration), transmute)
		end
	end
	record.entries = entries
end

-- Remembers recipes the open trade skill window shows with a running
-- cooldown, with that cooldown. Supports both trade skill APIs.
local function LearnRecipe(record, spellID, remaining)
	if type(spellID) ~= "number" or type(remaining) ~= "number" or not Readable(spellID, remaining)
		or remaining <= MIN_COOLDOWN then
		return
	end
	record.learned[spellID] = true
	local key = "spell:" .. spellID
	record.entries[key] = record.entries[key] or {}
	record.entries[key].readyAt = math.floor(time() + remaining + 0.5)
end

local function ScanTradeSkillWindow()
	local record = CharacterRecord()
	if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeCooldown then
		for _, recipeID in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
			LearnRecipe(record, recipeID, (C_TradeSkillUI.GetRecipeCooldown(recipeID)))
		end
	elseif GetNumTradeSkills and GetTradeSkillCooldown and GetTradeSkillRecipeLink then
		for i = 1, GetNumTradeSkills() or 0 do
			local _, skillType = GetTradeSkillInfo(i)
			if skillType ~= "header" then
				local link = GetTradeSkillRecipeLink(i)
				local spellID = type(link) == "string" and not IsSecret(link)
					and tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)"))
				LearnRecipe(record, spellID or nil, GetTradeSkillCooldown(i))
			end
		end
	end
end

local function Notify(initial)
	for owner, callback in pairs(owners) do
		ns.Utils.SafeCall(callback, owner, initial)
	end
end

function ProfessionCooldowns.Scan(initial)
	if not next(owners) then
		return
	end
	ScanCharacter()
	Notify(initial == true)
end

local function ScheduleScan()
	if scanPending then
		return
	end
	scanPending = true
	C_Timer.After(SCAN_THROTTLE, function()
		scanPending = false
		ProfessionCooldowns.Scan()
	end)
end

local function OnEvent(_, event, unit, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		local isInitialLogin, isReload = unit, ...
		if loginScanDone then
			return
		end
		C_Timer.After(LOGIN_DELAY, function()
			loginScanDone = true
			-- Only a real login counts for the login reminder, not /reload.
			ProfessionCooldowns.Scan(isInitialLogin and not isReload)
		end)
	elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE" or event == "TRADE_SKILL_LIST_UPDATE" then
		ScanTradeSkillWindow()
		ScheduleScan()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if not InCombatLockdown() then
			ScheduleScan()
		end
	else
		ScheduleScan()
	end
end

local EVENTS = {
	"TRADE_SKILL_SHOW",
	"TRADE_SKILL_UPDATE",
	"TRADE_SKILL_LIST_UPDATE",
	"BAG_UPDATE_COOLDOWN",
	"SKILL_LINES_CHANGED",
	"LEARNED_SPELL_IN_TAB",
}

local function SetActive(active)
	if not frame then
		frame = CreateFrame("Frame")
		frame:SetScript("OnEvent", OnEvent)
	end
	for _, event in ipairs(EVENTS) do
		if active then
			-- Not every client has every trade skill event.
			pcall(frame.RegisterEvent, frame, event)
		else
			frame:UnregisterEvent(event)
		end
	end
	if active then
		frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	else
		frame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end
end

-- callback(owner, initial) runs after every scan; initial is true once,
-- for the scan right after logging in.
function ProfessionCooldowns.Acquire(owner, callback)
	local wasActive = next(owners) ~= nil
	owners[owner] = callback
	if not wasActive then
		SetActive(true)
	end
	if loginScanDone then
		ScanCharacter()
		ns.Utils.SafeCall(callback, owner, false)
	end
end

function ProfessionCooldowns.Release(owner)
	owners[owner] = nil
	if not next(owners) then
		SetActive(false)
	end
end

-- Cooldowns of one character as shown to the player: entries of a family
-- that end together are merged into one, named after the family.
-- Returns a list of { name, icon, readyAt } sorted by readyAt, then name.
function ProfessionCooldowns.GetCooldowns(record)
	local now = time()
	local list, families = {}, {}
	for _, entry in pairs(record and record.entries or {}) do
		local readyAt = (entry.readyAt or 0) > now and entry.readyAt or 0
		local merged
		if entry.family then
			for _, item in ipairs(families[entry.family] or {}) do
				if math.abs(item.readyAt - readyAt) <= SAME_COOLDOWN then
					merged = item
					break
				end
			end
		end
		if merged then
			merged.name = entry.family
			merged.count = merged.count + 1
		else
			local item = { name = entry.name or "?", icon = entry.icon, readyAt = readyAt, count = 1 }
			list[#list + 1] = item
			if entry.family then
				families[entry.family] = families[entry.family] or {}
				table.insert(families[entry.family], item)
			end
		end
	end
	table.sort(list, function(a, b)
		if a.readyAt ~= b.readyAt then
			return a.readyAt < b.readyAt
		end
		return a.name < b.name
	end)
	return list
end

function ProfessionCooldowns.GetCurrentCharacter()
	return Store()[UnitGUID("player")]
end

-- { guid = record } of all characters with at least one cooldown.
function ProfessionCooldowns.GetCharacters()
	local result = {}
	for guid, record in pairs(Store()) do
		if type(record) == "table" and record.entries and next(record.entries) then
			result[guid] = record
		end
	end
	return result
end

-- Forgets every character except the current one.
function ProfessionCooldowns.ForgetOthers()
	local store = Store()
	local current = UnitGUID("player")
	for guid in pairs(store) do
		if guid ~= current then
			store[guid] = nil
		end
	end
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loginFrame:SetScript("OnEvent", OnEvent)
