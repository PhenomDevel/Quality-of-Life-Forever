-- luacheck: read globals PlayerFrame PlayerName
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Hide player name",
		NOTE = "On the player frame",
		DESC = "Hides your character name on the player unit frame.",
	},
	deDE = {
		TITLE = "Spielername ausblenden",
		NOTE = "Im Spielerrahmen",
		DESC = "Blendet deinen Charakternamen im Spielerrahmen aus.",
	},
})

local module = ns:NewModule("HidePlayerName", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
})

local function GetNameText()
	return PlayerName or (PlayerFrame and PlayerFrame.name)
end

-- Alpha instead of Hide(): Blizzard re-shows the font string on unit updates.
function module:OnEnable()
	local nameText = GetNameText()
	if nameText then
		nameText:SetAlpha(0)
	else
		self:Debug("player frame name not found")
	end
end

function module:OnDisable()
	local nameText = GetNameText()
	if nameText then
		nameText:SetAlpha(1)
	end
end
