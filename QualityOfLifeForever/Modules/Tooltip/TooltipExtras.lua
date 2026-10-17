-- luacheck: read globals TooltipDataProcessor Enum UnitIsPlayer UnitIsUnit UnitClass UnitExists UnitName GetGuildInfo C_ClassColor HIGHLIGHT_FONT_COLOR
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Tooltip extras",
		SECTION_UNITS = "Units",
		SECTION_ITEMS = "Items & spells",
		NOTE = "Guild rank, target, class color, IDs",
		DESC = "Adds more information to unit, item and spell tooltips.",
		GUILD_RANK = "Guild rank",
		GUILD_RANK_DESC = "Adds the guild rank to the guild line of players.",
		TARGET = "Unit's target",
		TARGET_DESC = "Shows whom the unit is targeting.",
		CLASS_COLOR = "Class colored names",
		CLASS_COLOR_DESC = "Colors the name of players in their class color.",
		IDS = "Item and spell IDs",
		IDS_DESC = "Shows the ID of items and spells (for guides and databases).",
		TARGET_LINE = "Target: %s",
		TARGET_YOU = ">> You <<",
		ITEM_ID = "Item ID: %d",
		SPELL_ID = "Spell ID: %d",
	},
	deDE = {
		TITLE = "Tooltip-Extras",
		SECTION_UNITS = "Einheiten",
		SECTION_ITEMS = "Gegenstände & Zauber",
		NOTE = "Gildenrang, Ziel, Klassenfarbe, IDs",
		DESC = "Ergänzt Tooltips von Einheiten, Gegenständen und Zaubern um weitere Informationen.",
		GUILD_RANK = "Gildenrang",
		GUILD_RANK_DESC = "Ergänzt bei Spielern den Gildenrang in der Gildenzeile.",
		TARGET = "Ziel der Einheit",
		TARGET_DESC = "Zeigt, wen die Einheit im Ziel hat.",
		CLASS_COLOR = "Namen in Klassenfarbe",
		CLASS_COLOR_DESC = "Färbt den Namen von Spielern in ihrer Klassenfarbe.",
		IDS = "Gegenstands- und Zauber-IDs",
		IDS_DESC = "Zeigt die ID von Gegenständen und Zaubern (für Guides und Datenbanken).",
		TARGET_LINE = "Ziel: %s",
		TARGET_YOU = ">> Du <<",
		ITEM_ID = "Gegenstands-ID: %d",
		SPELL_ID = "Zauber-ID: %d",
	},
})

local module = ns:NewModule("TooltipExtras", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "TOOLTIP",
	defaults = {
		guildRank = true,
		target = true,
		classColor = true,
		ids = false,
	},
	options = {
		{ type = "header", label = L.SECTION_UNITS },
		{ key = "guildRank", type = "checkbox", label = L.GUILD_RANK, tooltip = L.GUILD_RANK_DESC },
		{ key = "target", type = "checkbox", label = L.TARGET, tooltip = L.TARGET_DESC },
		{ key = "classColor", type = "checkbox", label = L.CLASS_COLOR, tooltip = L.CLASS_COLOR_DESC },
		{ type = "header", label = L.SECTION_ITEMS },
		{ key = "ids", type = "checkbox", label = L.IDS, tooltip = L.IDS_DESC },
	},
})

local IsSecret = ns.Utils.IsSecret

local function Usable(...)
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		if value == nil or IsSecret(value) then
			return false
		end
	end
	return true
end

-- Boolean API results may be secret in combat; treat those as false.
local function Is(value)
	return not IsSecret(value) and value == true
end

local function GetLine(tooltip, index)
	local name = tooltip:GetName()
	return name and _G[name .. "TextLeft" .. index]
end

local function ClassColor(unit)
	local _, classFile = UnitClass(unit)
	if Usable(classFile) then
		return C_ClassColor.GetClassColor(classFile)
	end
end

local function AddGuildRank(tooltip, unit)
	local guildName, rankName = GetGuildInfo(unit)
	if not Usable(guildName, rankName) then
		return
	end
	for i = 2, tooltip:NumLines() do
		local line = GetLine(tooltip, i)
		local text = line and line:GetText()
		if Usable(text) and text:find(guildName, 1, true) then
			line:SetText(("%s (%s)"):format(text, rankName))
			return
		end
	end
end

local function AddTarget(tooltip, unit)
	local target = unit .. "target"
	if not Is(UnitExists(target)) then
		return
	end
	local name
	if Is(UnitIsUnit(target, "player")) then
		name = L.TARGET_YOU
	else
		name = UnitName(target)
	end
	if not Usable(name) then
		return
	end
	local color = Is(UnitIsPlayer(target)) and ClassColor(target) or HIGHLIGHT_FONT_COLOR
	tooltip:AddLine(L.TARGET_LINE:format(color:WrapTextInColorCode(name)))
end

local function OnUnit(tooltip)
	if not module.enabled then
		return
	end
	local _, unit = tooltip:GetUnit()
	if not Usable(unit) then
		return
	end
	local db = module.db
	if Is(UnitIsPlayer(unit)) then
		if db.classColor then
			local color, line = ClassColor(unit), GetLine(tooltip, 1)
			if color and line then
				line:SetTextColor(color:GetRGB())
			end
		end
		if db.guildRank then
			AddGuildRank(tooltip, unit)
		end
	end
	if db.target then
		AddTarget(tooltip, unit)
	end
end

local function AddID(format)
	return function(tooltip, data)
		if module.enabled and module.db.ids and data and Usable(data.id) then
			tooltip:AddLine(format:format(data.id), 0.6, 0.6, 0.6)
		end
	end
end

function module:OnInitialize()
	-- Post-calls can't be removed: they check module.enabled.
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnUnit)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddID(L.ITEM_ID))
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, AddID(L.SPELL_ID))
end
