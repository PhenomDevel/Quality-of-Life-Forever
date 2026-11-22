-- luacheck: read globals CreateFont STANDARD_TEXT_FONT C_Timer UnitGUID time RAID_CLASS_COLORS
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Profession cooldowns widget",
		NOTE = "Countdown of your profession cooldowns",
		DESC = "A small movable list of your profession cooldowns, e.g. Mooncloth, transmutes or the Salt Shaker, with a countdown until each is ready. Shows the cooldowns of your other characters too, from when you last played them. Hidden while no character has one. Recipes the addon doesn't know yet are picked up from the profession window after their first craft. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: Profession cooldowns widget",
		SECTION_SHOW = "Show",
		SECTION_LOOK = "Appearance",
		SHOW_OTHERS = "Other characters",
		SHOW_OTHERS_DESC = "Also lists the cooldowns of your other characters, below their name.",
		FONT_SIZE = "Text size",
		FONT_SIZE_DESC = "Size of the widget's text and icons. The widget grows with it.",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the widget's background and border, 0 % (transparent) to 100 %.",
		FORGET = "Other characters",
		FORGET_DESC = "Forgets the cooldowns of all other characters; they come back when you log in with them.",
		FORGET_BUTTON = "Forget",
		FORGET_DONE = "Profession cooldowns of other characters forgotten.",
		READY = "Ready",
		DAYS = "%dd %dh",
		HOURS = "%dh %dm",
		MINUTES = "%d:%02d",
	},
	deDE = {
		TITLE = "Berufs-Cooldown-Widget",
		NOTE = "Countdown deiner Berufs-Cooldowns",
		DESC = "Eine kleine verschiebbare Liste deiner Berufs-Cooldowns, z. B. Mondstoff, Transmutationen oder der Salzstreuer, mit einem Countdown, bis jeder bereit ist. Zeigt auch die Cooldowns deiner anderen Charaktere, Stand ihres letzten Logins. Ausgeblendet, solange kein Charakter einen hat. Rezepte, die das Addon noch nicht kennt, werden nach dem ersten Herstellen aus dem Berufsfenster übernommen. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: Berufs-Cooldown-Widget",
		SECTION_SHOW = "Anzeigen",
		SECTION_LOOK = "Darstellung",
		SHOW_OTHERS = "Andere Charaktere",
		SHOW_OTHERS_DESC = "Listet auch die Cooldowns deiner anderen Charaktere unter ihrem Namen auf.",
		FONT_SIZE = "Textgröße",
		FONT_SIZE_DESC = "Größe von Text und Symbolen des Widgets. Das Widget wächst mit.",
		BG_OPACITY = "Hintergrund-Deckkraft",
		BG_OPACITY_DESC = "Deckkraft von Hintergrund und Rahmen des Widgets, von 0 % (durchsichtig) bis 100 %.",
		FORGET = "Andere Charaktere",
		FORGET_DESC = "Vergisst die Cooldowns aller anderen Charaktere; sie kommen wieder, wenn du dich mit ihnen einloggst.",
		FORGET_BUTTON = "Vergessen",
		FORGET_DONE = "Berufs-Cooldowns anderer Charaktere vergessen.",
		READY = "Bereit",
		DAYS = "%d T %d h",
		HOURS = "%d h %d min",
		MINUTES = "%d:%02d",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local module = ns:NewModule("ProfessionCooldownWidget", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "WIDGETS",
	order = 65,
	defaults = {
		showOthers = true,
		fontSize = 11,
		backgroundOpacity = 92,
		textOutline = "NONE",
		textShadow = true,
		showTitle = false,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "showOthers", type = "checkbox", label = L.SHOW_OTHERS, tooltip = L.SHOW_OTHERS_DESC },
		{
			type = "button",
			label = L.FORGET,
			buttonText = L.FORGET_BUTTON,
			tooltip = L.FORGET_DESC,
			onClick = function(self)
				ns.ProfessionCooldowns.ForgetOthers()
				self:Update()
				self:Print(L.FORGET_DONE)
			end,
		},
		{ type = "header", label = L.SECTION_LOOK },
		{ key = "fontSize", type = "slider", label = L.FONT_SIZE, tooltip = L.FONT_SIZE_DESC, min = 8, max = 20, step = 1 },
		ns:TextOutlineOption(),
		ns:TextShadowOption(),
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
		ns:TitleOption(),
	},
})

local ProfessionCooldowns = ns.ProfessionCooldowns

-- Sizes at the default text size of 11; they scale with the text size.
local BASE_FONT_SIZE = 11
local PADDING = 6
local ICON_GAP = 4
local COLUMN_GAP = 12
local ROW_GAP = 3
local HEADER_GAP = 5
local READY_COLOR = { 0.45, 0.9, 0.45 }
local WAIT_COLOR = { 0.9, 0.9, 0.9 }
local HEADER_COLOR = { 0.72, 0.72, 0.74 }

local frame, ticker
local rows = {}

local function Scaled(value)
	return math.floor(value * module.db.fontSize / BASE_FONT_SIZE + 0.5)
end

local function CreateText(justify)
	local text = frame:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(module.font)
	text:SetJustifyH(justify)
	text:SetWordWrap(false)
	return text
end

local function GetRow(index)
	local row = rows[index]
	if not row then
		row = {}
		row.icon = frame:CreateTexture(nil, "ARTWORK")
		row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.name = CreateText("LEFT")
		row.time = CreateText("RIGHT")
		rows[index] = row
	end
	return row
end

local function HideRow(row)
	row.icon:Hide()
	row.name:Hide()
	row.time:Hide()
end

local function CreateWidget()
	frame = ns:CreateOverlay("ProfessionCooldownWidget", {
		title = L.EDIT_MODE_NAME,
		module = module,
		width = 160,
		height = 26,
		default = { point = "TOP", x = 0, y = -380 },
	})
end

local function FormatRemaining(seconds)
	if seconds <= 0 then
		return L.READY
	end
	if seconds >= 86400 then
		return L.DAYS:format(math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600))
	end
	if seconds >= 3600 then
		return L.HOURS:format(math.floor(seconds / 3600), math.floor(seconds % 3600 / 60))
	end
	return L.MINUTES:format(math.floor(seconds / 60), math.floor(seconds % 60))
end

local function CharacterName(record)
	local name = record.name or "?"
	local color = record.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[record.class]
	if color then
		return color:WrapTextInColorCode(name)
	end
	return name
end

-- Display lines: { header = text } or { icon, name, readyAt }.
-- The current character comes first, then the others by name.
local function Collect()
	local lines = {}
	local currentGUID = UnitGUID("player")
	local characters = ProfessionCooldowns.GetCharacters()
	local others = {}
	for guid, record in pairs(characters) do
		if guid ~= currentGUID and module.db.showOthers then
			others[#others + 1] = record
		end
	end
	table.sort(others, function(a, b)
		return (a.name or "") < (b.name or "")
	end)

	local current = characters[currentGUID]
	local withHeaders = #others > 0
	local function Add(record)
		if withHeaders then
			lines[#lines + 1] = { header = CharacterName(record) }
		end
		for _, cooldown in ipairs(ProfessionCooldowns.GetCooldowns(record)) do
			lines[#lines + 1] = cooldown
		end
	end
	if current then
		Add(current)
	end
	for _, record in ipairs(others) do
		Add(record)
	end
	return lines
end

-- True while a countdown is visible, so the ticker can stop otherwise.
function module:Update()
	if not frame or not self.enabled then
		return false
	end
	local lines = Collect()
	for i = #lines + 1, #rows do
		HideRow(rows[i])
	end
	if #lines == 0 then
		frame:Hide()
		return false
	end

	local now = time()
	local size = self.db.fontSize
	local iconSize = size + Scaled(3)
	local nameWidth, timeWidth, counting = 0, 0, false
	for i, line in ipairs(lines) do
		local row = GetRow(i)
		if line.header then
			row.name:SetText(line.header)
			row.name:SetTextColor(unpack(HEADER_COLOR))
			row.time:SetText("")
		else
			local remaining = line.readyAt - now
			counting = counting or remaining > 0
			row.name:SetText(line.name)
			row.name:SetTextColor(unpack(WAIT_COLOR))
			row.time:SetText(FormatRemaining(remaining))
			row.time:SetTextColor(unpack(remaining > 0 and WAIT_COLOR or READY_COLOR))
			timeWidth = math.max(timeWidth, math.ceil(row.time:GetUnboundedStringWidth()))
		end
		local width = math.ceil(row.name:GetUnboundedStringWidth())
		if not line.header then
			width = width + iconSize + Scaled(ICON_GAP)
		end
		nameWidth = math.max(nameWidth, width)
	end

	-- The countdown column only grows until the next layout change, so the
	-- widget doesn't twitch every second.
	timeWidth = math.max(timeWidth, frame.timeWidth or 0)
	frame.timeWidth = timeWidth
	local width = nameWidth + Scaled(COLUMN_GAP) + timeWidth
	local y = -PADDING
	for i, line in ipairs(lines) do
		local row = GetRow(i)
		if line.header and i > 1 then
			y = y - HEADER_GAP
		end
		row.name:ClearAllPoints()
		row.time:ClearAllPoints()
		if line.header then
			row.icon:Hide()
			row.name:SetPoint("TOPLEFT", PADDING, y)
			row.time:Hide()
		else
			row.icon:SetTexture(line.icon or 134400)
			row.icon:SetSize(iconSize, iconSize)
			row.icon:ClearAllPoints()
			row.icon:SetPoint("TOPLEFT", PADDING, y)
			row.icon:Show()
			row.name:SetPoint("LEFT", row.icon, "RIGHT", Scaled(ICON_GAP), 0)
			row.time:SetPoint("RIGHT", frame, "TOPLEFT", PADDING + width, y - iconSize / 2)
			row.time:Show()
		end
		row.name:Show()
		y = y - iconSize - ROW_GAP
	end
	frame:SetSize(PADDING * 2 + width, -y - ROW_GAP + PADDING)
	frame:Show()
	return counting
end

-- Ticks once a second while a countdown runs.
function module:Refresh()
	local counting = self:Update()
	if counting and not ticker then
		ticker = C_Timer.NewTicker(1, function()
			if not self:Update() and ticker then
				ticker:Cancel()
				ticker = nil
			end
		end)
	elseif not counting and ticker then
		ticker:Cancel()
		ticker = nil
	end
end

function module:ApplyLayout()
	ns:SetOverlayFont(self.font, self.db.fontSize, self.db)
	ns:SetOverlayBackgroundAlpha(frame, self.db.backgroundOpacity / 100)
	frame.timeWidth = 0
	-- String widths pick up the new font size only on the next frame.
	C_Timer.After(0, function()
		if self.enabled then
			self:Update()
		end
	end)
end

function module:OnOptionChanged()
	self:ApplyLayout()
	self:Refresh()
end

function module:OnInitialize()
	self.font = CreateFont("QualityOfLifeForeverProfessionCooldownWidgetFont")
	self.font:SetFont(STANDARD_TEXT_FONT, BASE_FONT_SIZE, "")
	self.font:SetShadowOffset(1, -1)
	self.font:SetShadowColor(0, 0, 0, 0.8)
end

function module:OnEnable()
	if not frame then
		CreateWidget()
	end
	self:ApplyLayout()
	ProfessionCooldowns.Acquire(self, self.Refresh)
	self:Refresh()
end

function module:OnDisable()
	ProfessionCooldowns.Release(self)
	if ticker then
		ticker:Cancel()
		ticker = nil
	end
	frame:Hide()
end
