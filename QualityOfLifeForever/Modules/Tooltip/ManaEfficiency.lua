-- luacheck: read globals Enum C_Spell
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Mana efficiency",
		NOTE = "Healing and damage per mana in spell tooltips",
		DESC = "Adds how much healing, damage or absorption a spell gives per point of mana to its tooltip. The amounts are read from the spell description; ranges count with their average and effects over time with their total.",
		HEAL = "Healing",
		HEAL_DESC = "Shows the healing per mana.",
		DAMAGE = "Damage",
		DAMAGE_DESC = "Shows the damage per mana.",
		ABSORB = "Absorption",
		ABSORB_DESC = "Shows the absorbed damage per mana, e.g. for shields.",
		HEAL_LINE = "%s healing per mana",
		DAMAGE_LINE = "%s damage per mana",
		ABSORB_LINE = "%s absorption per mana",
		DECIMAL = ".",
	},
	deDE = {
		TITLE = "Mana-Effizienz",
		NOTE = "Heilung und Schaden pro Mana in Zauber-Tooltips",
		DESC = "Ergänzt Zauber-Tooltips darum, wie viel Heilung, Schaden oder Absorption der Zauber pro Manapunkt bringt. Die Werte stammen aus der Zauberbeschreibung; Spannen zählen mit ihrem Mittelwert, Effekte über Zeit mit ihrer Summe.",
		HEAL = "Heilung",
		HEAL_DESC = "Zeigt die Heilung pro Mana.",
		DAMAGE = "Schaden",
		DAMAGE_DESC = "Zeigt den Schaden pro Mana.",
		ABSORB = "Absorption",
		ABSORB_DESC = "Zeigt den absorbierten Schaden pro Mana, z. B. bei Schilden.",
		HEAL_LINE = "%s Heilung pro Mana",
		DAMAGE_LINE = "%s Schaden pro Mana",
		ABSORB_LINE = "%s Absorption pro Mana",
		DECIMAL = ",",
	},
})

local module = ns:NewModule("ManaEfficiency", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "TOOLTIP",
	order = 40,
	defaults = {
		heal = true,
		damage = true,
		absorb = true,
	},
	options = {
		{ key = "heal", type = "checkbox", label = L.HEAL, tooltip = L.HEAL_DESC },
		{ key = "damage", type = "checkbox", label = L.DAMAGE, tooltip = L.DAMAGE_DESC },
		{ key = "absorb", type = "checkbox", label = L.ABSORB, tooltip = L.ABSORB_DESC },
	},
})

local IsSecret = ns.Utils.IsSecret

--------------------------------------------------------------------------------
-- Description parser
--
-- Spell descriptions name their amounts in plain text, e.g. "Heals a friendly
-- target for 193 to 237." or "Verursacht 14 bis 22 Feuerschaden". Every
-- number is a boundary; a number counts as an amount when it is followed by
-- punctuation, a connector ("over", "and", "Punkt(e)") or an effect keyword
-- within the next words. Durations, distances and percentages are followed
-- by their unit and therefore never count.
--------------------------------------------------------------------------------

-- Keywords of both client languages, lowercase, matched as substrings.
-- Checked in this order: "absorbing 44 damage" is an absorption, "Heals the
-- target of 45 damage over 15 sec" a heal.
local KINDS = { "absorb", "heal", "damage" }
local KEYWORDS = {
	absorb = { "absorb" },
	heal = { "heal", "heilt", "heilung", "geheilt", "heilen" },
	damage = { "damage", "schaden" },
}

-- Words that may directly follow an amount without naming the effect.
local CONNECTORS = {
	["over"] = true, ["and"] = true, ["plus"] = true, ["every"] = true,
	["über"] = true, ["und"] = true, ["sowie"] = true, ["im"] = true,
	["punkt"] = true, ["punkte"] = true, ["punkt(e)"] = true,
}

local RANGE_SEPARATORS = { "^%s*to%s*", "^%s*bis%s*", "^%s*%-%s*", "^%s*–%s*" }

local function KindOf(text)
	text = text:lower()
	for _, kind in ipairs(KINDS) do
		for _, keyword in ipairs(KEYWORDS[kind]) do
			if text:find(keyword, 1, true) then
				return kind
			end
		end
	end
end

-- Last keyword before position `stop`, for amounts like Holy Nova's
-- "... and healing all party members within 10 yards for 54 to 63."
local function LastKindBefore(text, stop)
	local lower = text:sub(1, stop - 1):lower()
	local best, bestPos
	for kind, keywords in pairs(KEYWORDS) do
		for _, keyword in ipairs(keywords) do
			local init = 1
			while true do
				local pos = lower:find(keyword, init, true)
				if not pos then
					break
				end
				if not bestPos or pos > bestPos then
					best, bestPos = kind, pos
				end
				init = pos + 1
			end
		end
	end
	return best
end

-- All numbers with their position. Uses the client's decimal mark: "1.5"
-- is one and a half in enUS, "1.234" is 1234 in deDE; the other mark
-- followed by exactly three digits groups thousands ("1,234" / "1.234").
local DECIMAL_MARK = L.DECIMAL
local GROUP_MARK = DECIMAL_MARK == "," and "." or ","

local function FindNumbers(text)
	local numbers = {}
	local init = 1
	while true do
		local first, last = text:find("%d+", init)
		if not first then
			break
		end
		local digits = text:sub(first, last)
		while true do
			local group = text:match("^%" .. GROUP_MARK .. "(%d%d%d)", last + 1)
			if not group or text:find("^%d", last + 5) then
				break
			end
			digits = digits .. group
			last = last + 4
		end
		local decimals = text:match("^%" .. DECIMAL_MARK .. "(%d+)", last + 1)
		if decimals then
			digits = digits .. "." .. decimals
			last = last + 1 + #decimals
		end
		numbers[#numbers + 1] = { first = first, last = last, value = tonumber(digits) }
		init = last + 1
	end
	return numbers
end

-- Merges "X to Y" ranges into one amount with the average value.
local function MergeRanges(text, numbers)
	local merged = {}
	local i = 1
	while i <= #numbers do
		local number = numbers[i]
		local nextNumber = numbers[i + 1]
		if nextNumber then
			local between = text:sub(number.last + 1, nextNumber.first - 1)
			for _, pattern in ipairs(RANGE_SEPARATORS) do
				local separator = between:match(pattern)
				if separator and #separator == #between then
					number = {
						first = number.first,
						last = nextNumber.last,
						value = (number.value + nextNumber.value) / 2,
					}
					i = i + 1
					break
				end
			end
		end
		merged[#merged + 1] = number
		i = i + 1
	end
	return merged
end

-- Whether the text after a number makes it an amount; returns the kind named
-- right after it, if any. The keyword must be the next word or follow a
-- capitalized school name ("26 Arcane damage"), so "within 10 yards and
-- healing" does not count the 10.
local function ReadAfter(after)
	local trimmed = after:match("^%s*(.-)%s*$")
	if trimmed == "" or trimmed:find("^[%.,;:%)]") then
		return true
	end
	local first, second = trimmed:match("^(%S+)%s*(%S*)")
	local kind = KindOf(first)
	if kind then
		return true, kind
	end
	if CONNECTORS[(first:lower():gsub("[%.,;:]$", ""))] then
		return true
	end
	kind = first:find("^%u") and KindOf(second)
	if kind then
		return true, kind
	end
	return false
end

-- Returns the summed amounts per kind, e.g. { heal = 215 }.
local function ParseDescription(text)
	local totals = {}
	local numbers = MergeRanges(text, FindNumbers(text))
	for i, number in ipairs(numbers) do
		local previous, following = numbers[i - 1], numbers[i + 1]
		local after = text:sub(number.last + 1, following and following.first - 1 or #text)
		local isAmount, kindAfter = ReadAfter(after)
		if isAmount then
			local before = text:sub(previous and previous.last + 1 or 1, number.first - 1)
			local kind = KindOf(before .. " " .. after) or kindAfter or LastKindBefore(text, number.first)
			if kind then
				totals[kind] = (totals[kind] or 0) + number.value
			end
		end
	end
	return totals
end

--------------------------------------------------------------------------------
-- Tooltip
--------------------------------------------------------------------------------

local function GetManaCost(spellID)
	for _, cost in ipairs(C_Spell.GetSpellPowerCost(spellID) or {}) do
		if not IsSecret(cost.type) and cost.type == Enum.PowerType.Mana
			and not IsSecret(cost.cost) and cost.cost > 0 then
			return cost.cost
		end
	end
end

local function FormatRatio(value)
	local text = ("%.2f"):format(value):gsub("0$", ""):gsub("%.$", "")
	return (text:gsub("%.", L.DECIMAL))
end

local LINES = { heal = L.HEAL_LINE, damage = L.DAMAGE_LINE, absorb = L.ABSORB_LINE }

function module:OnSpellTooltip(tooltip, data)
	local spellID = data and data.id
	if spellID == nil or IsSecret(spellID) then
		return
	end
	local ok, cost = pcall(GetManaCost, spellID)
	if not ok or not cost then
		return
	end
	local description = C_Spell.GetSpellDescription(spellID)
	if type(description) ~= "string" or IsSecret(description) or description == "" then
		return
	end

	local totals = ParseDescription(description)
	for _, kind in ipairs(KINDS) do
		local total = totals[kind]
		-- Below 0.01 per mana the parsed amount is almost certainly not the
		-- spell's real effect, so show nothing rather than "0".
		if total and total / cost >= 0.01 and self.db[kind] then
			tooltip:AddLine(LINES[kind]:format(FormatRatio(total / cost)), 0.4, 0.8, 1)
		end
	end
end

function module:OnInitialize()
	self:AddTooltipPostCall(Enum.TooltipDataType.Spell, self.OnSpellTooltip)
end
