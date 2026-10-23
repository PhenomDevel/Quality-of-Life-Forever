-- luacheck: read globals C_Spell C_SpellBook C_UnitAuras C_Timer CreateFrame CreateFont STANDARD_TEXT_FONT GameTooltip UnitClass UnitIsDeadOrGhost IsMounted UnitOnTaxi IsResting InCombatLockdown PlaySound SOUNDKIT
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Missing self-buffs",
		NOTE = "Your missing long-lasting buffs, click to cast",
		DESC = "Out of combat, a small movable bar shows the icons of your class's long-lasting buffs that are missing, e.g. Arcane Intellect, Inner Fire, Mark of the Wild or Demon Skin. Click an icon to cast the buff; the bar disappears once you have them all. Only buffs you have learned count; for buffs with alternatives (armors, auras, aspects) any one of them is enough. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: Missing buffs",
		NOTICE = "While this window or {Edit Mode} is open, all learned buffs of your class are shown so you can place the bar.",
		SECTION_WHEN = "When to remind",
		SECTION_HOW = "How to remind",
		SECTION_LOOK = "Appearance",
		NOT_RESTING = "Not in rest areas",
		NOT_RESTING_DESC = "No reminder in inns and cities.",
		SOUND = "Sound",
		SOUND_DESC = "Plays a sound when a buff goes missing.",
		ICON_SIZE = "Icon size",
		ICON_SIZE_DESC = "Size of the buff icons in pixels.",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the bar's background and border, 0 % (transparent) to 100 %.",
		HEADER = "Missing",
		CLICK_TO_CAST = "Click to cast",
	},
	deDE = {
		TITLE = "Fehlende Selbst-Buffs",
		NOTE = "Deine fehlenden lang anhaltenden Buffs, Klick zum Wirken",
		DESC = "Außerhalb des Kampfes zeigt eine kleine verschiebbare Leiste die Symbole der lang anhaltenden Buffs deiner Klasse, die fehlen, z. B. Arkane Intelligenz, Inneres Feuer, Mal der Wildnis oder Dämonenhaut. Ein Klick auf ein Symbol wirkt den Buff; die Leiste verschwindet, sobald du alle hast. Es zählen nur Buffs, die du gelernt hast; bei Buffs mit Alternativen (Rüstungen, Auren, Aspekte) reicht einer davon. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: Fehlende Buffs",
		NOTICE = "Solange dieses Fenster oder der {Bearbeitungsmodus} offen ist, werden alle gelernten Buffs deiner Klasse angezeigt, damit du die Leiste platzieren kannst.",
		SECTION_WHEN = "Wann erinnern",
		SECTION_HOW = "Wie erinnern",
		SECTION_LOOK = "Darstellung",
		NOT_RESTING = "Nicht in Erholungsgebieten",
		NOT_RESTING_DESC = "Keine Erinnerung in Gasthäusern und Städten.",
		SOUND = "Ton",
		SOUND_DESC = "Spielt einen Ton, wenn ein Buff fehlt.",
		ICON_SIZE = "Symbolgröße",
		ICON_SIZE_DESC = "Größe der Buff-Symbole in Pixeln.",
		BG_OPACITY = "Hintergrund-Deckkraft",
		BG_OPACITY_DESC = "Deckkraft von Hintergrund und Rahmen der Leiste, von 0 % (durchsichtig) bis 100 %.",
		HEADER = "Fehlt",
		CLICK_TO_CAST = "Klicken zum Wirken",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local function FormatPixels(value)
	return ("%d px"):format(value)
end

local module = ns:NewModule("MissingBuffs", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	notice = L.NOTICE,
	category = "REMINDERS",
	defaults = {
		notResting = true,
		sound = false,
		iconSize = 32,
		backgroundOpacity = 92,
	},
	options = {
		{ type = "header", label = L.SECTION_WHEN },
		{ key = "notResting", type = "checkbox", label = L.NOT_RESTING, tooltip = L.NOT_RESTING_DESC },
		{ type = "header", label = L.SECTION_HOW },
		{ key = "sound", type = "checkbox", label = L.SOUND, tooltip = L.SOUND_DESC },
		{ type = "header", label = L.SECTION_LOOK },
		{ key = "iconSize", type = "slider", label = L.ICON_SIZE, tooltip = L.ICON_SIZE_DESC, min = 20, max = 56, step = 2, format = FormatPixels },
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
	},
})

-- Long-lasting self-buffs by class file name; each entry lists alternatives,
-- any one of them counts and the first known one is cast. Rank 1 spell IDs
-- from wowhead.com (Classic); auras are matched and spells cast by name, so
-- every rank counts and the highest known rank is cast.
local BUFFS = {
	DRUID = {
		{ 1126 }, -- Mark of the Wild
	},
	HUNTER = {
		{ 13165, 13163 }, -- Aspect of the Hawk, Aspect of the Monkey
	},
	MAGE = {
		{ 1459 }, -- Arcane Intellect
		{ 7302, 168, 6117 }, -- Ice Armor (replaces Frost Armor), Frost Armor, Mage Armor
	},
	PALADIN = {
		{ 465, 7294, 19746 }, -- Devotion, Retribution, Concentration Aura
	},
	PRIEST = {
		{ 1243 }, -- Power Word: Fortitude
		{ 588 }, -- Inner Fire
	},
	SHAMAN = {
		{ 324 }, -- Lightning Shield
	},
	WARLOCK = {
		{ 706, 687 }, -- Demon Armor (replaces Demon Skin), Demon Skin
	},
}

-- Short delay so a burst of UNIT_AURA events is handled once.
local CHECK_DELAY = 0.2
local PADDING = 6
local ICON_GAP = 4
local HEADER_GAP = 4

local IsSecret = ns.Utils.IsSecret
local LibEditMode = ns.LibEditMode
local pending
local frame
-- Secure action buttons, created out of combat only and reused.
local buttons = {}
-- Names of the missing buffs at the last check; the sound plays when it grows.
local lastMissing = {}
local editing, optionsShown = false, false

local function IsPreview()
	return editing or optionsShown
end

local function IsKnown(spellID)
	return C_SpellBook.IsSpellKnown(spellID) == true
end

local function HasBuff(name)
	local aura = C_UnitAuras.GetAuraDataBySpellName("player", name, "HELPFUL")
	return aura ~= nil and not IsSecret(aura)
end

-- { spellID, name, icon } of the first known spell of each buff group, all of
-- them or only those without an active aura.
local function Collect(missingOnly)
	local _, class = UnitClass("player")
	local list = {}
	for _, group in ipairs(BUFFS[class] or {}) do
		local known, active = nil, false
		for _, spellID in ipairs(group) do
			local name = C_Spell.GetSpellName(spellID)
			if name and not IsSecret(name) then
				if not known and IsKnown(spellID) then
					known = { spellID = spellID, name = name, icon = C_Spell.GetSpellTexture(spellID) }
				end
				if HasBuff(name) then
					active = true
				end
			end
		end
		if known and not (missingOnly and active) then
			list[#list + 1] = known
		end
	end
	return list
end

local function ShouldShow(self)
	return not InCombatLockdown() and not UnitIsDeadOrGhost("player") and not IsMounted()
		and not UnitOnTaxi("player") and not (self.db.notResting and IsResting())
end

local function OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_TOP")
	GameTooltip:SetSpellByID(button.spellID)
	GameTooltip:AddLine(L.CLICK_TO_CAST, 0.25, 0.55, 1)
	GameTooltip:Show()
end

local function OnLeave()
	GameTooltip:Hide()
end

local function GetButton(index)
	local button = buttons[index]
	if not button then
		button = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
		-- Both, so it follows the "cast on key down" setting.
		button:RegisterForClicks("AnyUp", "AnyDown")
		button:SetAttribute("type", "spell")
		button.Icon = button:CreateTexture(nil, "ARTWORK")
		button.Icon:SetAllPoints()
		button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		button:SetScript("OnEnter", OnEnter)
		button:SetScript("OnLeave", OnLeave)
		buttons[index] = button
	end
	return button
end

local function CreateBar()
	frame = ns:CreateOverlay("MissingBuffs", {
		title = L.EDIT_MODE_NAME,
		width = 80,
		height = 50,
		default = { point = "CENTER", x = 0, y = 120 },
	})
	frame.Header = frame:CreateFontString(nil, "OVERLAY")
	frame.Header:SetFontObject(module.font)
	frame.Header:SetPoint("TOP", 0, -PADDING)
	frame.Header:SetText(L.HEADER)
end

-- Fills and sizes the bar with `list`; out of combat only.
local function Layout(list)
	local size = module.db.iconSize
	local headerHeight = math.ceil(frame.Header:GetStringHeight())
	local top = PADDING + headerHeight + HEADER_GAP
	local rowWidth = #list * size + (#list - 1) * ICON_GAP
	local width = math.max(rowWidth, math.ceil(frame.Header:GetUnboundedStringWidth()))
	local left = PADDING + (width - rowWidth) / 2
	for i, data in ipairs(list) do
		local button = GetButton(i)
		button.spellID = data.spellID
		button:SetAttribute("spell", data.name)
		button.Icon:SetTexture(data.icon)
		button:SetSize(size, size)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", left + (i - 1) * (size + ICON_GAP), -top)
		button:Show()
	end
	for i = #list + 1, #buttons do
		buttons[i]:Hide()
	end
	frame:SetSize(width + PADDING * 2, top + size + PADDING)
end

function module:Update()
	pending = nil
	if not frame then
		return
	end
	-- The bar holds secure buttons, so it can't change in combat; combat end
	-- queues another update.
	if InCombatLockdown() then
		return
	end
	if not self.enabled then
		frame:Hide()
		return
	end
	local preview = IsPreview()
	local list = Collect(not preview)
	local show = #list > 0 and (preview or ShouldShow(self))
	if not preview then
		local missing = {}
		for _, data in ipairs(list) do
			missing[data.name] = true
			if show and self.db.sound and not lastMissing[data.name] then
				PlaySound(SOUNDKIT.RAID_WARNING, "Master")
			end
		end
		lastMissing = missing
	end
	if show then
		Layout(list)
	end
	frame:SetShown(show)
end

function module:QueueUpdate()
	if not pending then
		pending = C_Timer.NewTimer(CHECK_DELAY, function()
			self:Update()
		end)
	end
end

-- Last chance to hide the bar before combat locks it.
function module:OnCombatStart()
	if pending then
		pending:Cancel()
		pending = nil
	end
	if frame and not InCombatLockdown() and not IsPreview() then
		frame:Hide()
	end
end

function module:OnCombatEnd()
	self:QueueUpdate()
end

function module:ApplyLayout()
	self.font:SetFont(STANDARD_TEXT_FONT, math.max(11, math.floor(self.db.iconSize / 3)), "")
	ns:SetOverlayBackgroundAlpha(frame, self.db.backgroundOpacity / 100)
end

function module:OnOptionChanged()
	if not InCombatLockdown() then
		self:ApplyLayout()
	end
	self:QueueUpdate()
end

function module:OnOptionsShown(shown)
	optionsShown = shown
	self:QueueUpdate()
end

function module:OnInitialize()
	self.font = CreateFont("QualityOfLifeForeverMissingBuffsFont")
	self.font:SetFont(STANDARD_TEXT_FONT, 11, "")
	self.font:SetShadowOffset(1, -1)
	self.font:SetShadowColor(0, 0, 0, 0.8)
end

function module:OnEnable()
	if not frame then
		CreateBar()
	end
	if not InCombatLockdown() then
		self:ApplyLayout()
	end
	lastMissing = {}
	optionsShown = ns:IsOptionsShown()
	if not self.editModeHooked then
		self.editModeHooked = true
		LibEditMode:RegisterCallback("enter", function()
			editing = true
			self:QueueUpdate()
		end)
		LibEditMode:RegisterCallback("exit", function()
			editing = false
			self:QueueUpdate()
		end)
	end
	self:RegisterEvent("UNIT_AURA", function(_, unit)
		if unit == "player" then
			self:QueueUpdate()
		end
	end)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", self.OnCombatStart)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", self.OnCombatEnd)
	for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_UPDATE_RESTING", "PLAYER_MOUNT_DISPLAY_CHANGED", "PLAYER_UNGHOST", "PLAYER_ALIVE", "PLAYER_DEAD", "PLAYER_CONTROL_GAINED", "PLAYER_CONTROL_LOST", "SPELLS_CHANGED" }) do
		self:RegisterEvent(event, self.QueueUpdate)
	end
	self:QueueUpdate()
end

function module:OnDisable()
	if pending then
		pending:Cancel()
		pending = nil
	end
	if not InCombatLockdown() then
		frame:Hide()
		return
	end
	-- Module events are gone now, so hide it once combat ends.
	local function HideAfterCombat()
		ns:UnregisterEvent("PLAYER_REGEN_ENABLED", HideAfterCombat)
		if not module.enabled then
			frame:Hide()
		end
	end
	ns:RegisterEvent("PLAYER_REGEN_ENABLED", HideAfterCombat)
end
