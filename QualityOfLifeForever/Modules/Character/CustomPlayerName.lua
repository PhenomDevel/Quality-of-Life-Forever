-- luacheck: read globals GetUnitName PlayerFrame PlayerName StaticPopup_Show ACCEPT CANCEL strtrim
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Custom player name",
		NOTE = "Shown on the player frame",
		DESC = "Shows a name of your choice on the player unit frame instead of your character name. Only visible to you.",
		SET = "Name",
		SET_BUTTON = "Change…",
		SET_DESC = "Enter the name to show. Leave empty to show your character name.",
		DIALOG = "Name on the player frame (empty = character name):",
	},
	deDE = {
		TITLE = "Eigener Spielername",
		NOTE = "Wird im Spielerrahmen angezeigt",
		DESC = "Zeigt im Spielerrahmen einen Namen deiner Wahl statt deines Charakternamens an. Nur für dich sichtbar.",
		SET = "Name",
		SET_BUTTON = "Ändern…",
		SET_DESC = "Den anzuzeigenden Namen eingeben. Leer lassen, um den Charakternamen anzuzeigen.",
		DIALOG = "Name im Spielerrahmen (leer = Charaktername):",
	},
})

local DIALOG = "QOLFOREVER_CUSTOM_PLAYER_NAME"
local MAX_LETTERS = 32

local module = ns:NewModule("CustomPlayerName", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
	defaults = {
		name = "",
	},
	options = {
		{
			type = "button",
			label = L.SET,
			buttonText = L.SET_BUTTON,
			tooltip = L.SET_DESC,
			onClick = function()
				StaticPopup_Show(DIALOG)
			end,
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

function module:SetName(name)
	self.db.name = strtrim(name or "")
	self:Refresh()
end

function module:OnInitialize()
	StaticPopupDialogs[DIALOG] = {
		text = L.DIALOG,
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = MAX_LETTERS,
		OnShow = function(dialog)
			local editBox = dialog:GetEditBox()
			editBox:SetText(self.db.name)
			editBox:HighlightText()
		end,
		OnAccept = function(dialog)
			self:SetName(dialog:GetEditBox():GetText())
		end,
		EditBoxOnEnterPressed = function(editBox)
			editBox:GetParent():GetButton1():Click()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}
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
