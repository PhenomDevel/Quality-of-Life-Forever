-- luacheck: read globals GetUnitName PlayerFrame PlayerName
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Custom player name",
		NOTE = "Shown on the player frame",
		DESC = "Shows a name of your choice on the player unit frame instead of your character name. Only visible to you.",
		SET = "Name",
		SET_DESC = "The name to show, saved with Enter. Leave empty to show your character name.",
		SET_HINT = "Character name",
	},
	deDE = {
		TITLE = "Eigener Spielername",
		NOTE = "Wird im Spielerrahmen angezeigt",
		DESC = "Zeigt im Spielerrahmen einen Namen deiner Wahl statt deines Charakternamens an. Nur für dich sichtbar.",
		SET = "Name",
		SET_DESC = "Der anzuzeigende Name, wird mit Enter gespeichert. Leer lassen, um den Charakternamen anzuzeigen.",
		SET_HINT = "Charaktername",
	},
})

local MAX_LETTERS = 32

local module = ns:NewModule("CustomPlayerName", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
	order = 30,
	defaults = {
		name = "",
	},
	options = {
		{
			key = "name",
			type = "text",
			label = L.SET,
			tooltip = L.SET_DESC,
			placeholder = L.SET_HINT,
			maxLetters = MAX_LETTERS,
		},
	},
})

local function GetNameText()
	return PlayerName or (PlayerFrame and PlayerFrame.name)
end

function module:Refresh()
	local nameText = GetNameText()
	if not nameText then
		self:Debug("player frame name not found")
		return
	end
	local name = self.enabled and self.db.name or ""
	nameText:SetText(name ~= "" and name or GetUnitName("player"))
end

function module:OnOptionChanged()
	self:Refresh()
end

function module:OnEnable()
	-- Blizzard re-sets the name on every unit update (UNIT_NAME_UPDATE, vehicle, ...).
	self:SecureHook("UnitFrame_Update", self.OnUnitFrameUpdate)
	self:Refresh()
end

function module:OnDisable()
	self:Refresh()
end

function module:OnUnitFrameUpdate(frame)
	if frame == PlayerFrame and self.db.name ~= "" then
		frame.name:SetText(self.db.name)
	end
end
