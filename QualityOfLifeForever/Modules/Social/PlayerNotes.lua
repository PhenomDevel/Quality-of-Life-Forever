-- luacheck: read globals Menu TooltipDataProcessor Enum UnitIsPlayer UnitName GetNormalizedRealmName StaticPopup_Show ACCEPT CANCEL strtrim
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Player notes",
		NOTE = "Right-click a player → Note",
		DESC = "Write a note about any player via the right-click menu (unit frames, chat names, friends, guild, group). The note is shown in the player's tooltip. Notes are shared by all your characters.",
		TOOLTIP = "Show in tooltip",
		TOOLTIP_DESC = "Adds the note to the tooltip of the player.",
		MENU_ADD = "Add note",
		MENU_EDIT = "Edit note",
		DIALOG = "Note for %s (empty to delete):",
		TOOLTIP_LINE = "Note: %s",
	},
	deDE = {
		TITLE = "Spielernotizen",
		NOTE = "Rechtsklick auf Spieler → Notiz",
		DESC = "Notiz zu einem beliebigen Spieler über das Rechtsklickmenü (Einheitenfenster, Namen im Chat, Freunde, Gilde, Gruppe). Die Notiz erscheint im Tooltip des Spielers. Notizen gelten für alle deine Charaktere.",
		TOOLTIP = "Im Tooltip anzeigen",
		TOOLTIP_DESC = "Zeigt die Notiz im Tooltip des Spielers.",
		MENU_ADD = "Notiz hinzufügen",
		MENU_EDIT = "Notiz bearbeiten",
		DIALOG = "Notiz für %s (leer zum Löschen):",
		TOOLTIP_LINE = "Notiz: %s",
	},
})

local DIALOG = "QUALITYOFLIFEFOREVER_PLAYER_NOTE"

-- Unit popup menus of other players (tag "MENU_UNIT_<which>").
local MENUS = {
	"PLAYER", "ENEMY_PLAYER", "PARTY", "RAID_PLAYER", "TARGET", "FOCUS",
	"FRIEND", "FRIEND_OFFLINE", "GUILD", "GUILD_OFFLINE", "CHAT_ROSTER",
	"COMMUNITIES_WOW_MEMBER", "COMMUNITIES_GUILD_MEMBER",
	"RECENT_ALLY", "RECENT_ALLY_OFFLINE",
}

local module = ns:NewModule("PlayerNotes", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "SOCIAL",
	defaults = {
		tooltip = true,
		notes = {},
	},
	options = {
		{ key = "tooltip", type = "checkbox", label = L.TOOLTIP, tooltip = L.TOOLTIP_DESC },
	},
})

local IsSecret = ns.Utils.IsSecret

-- "Name-Realm" with the normalized realm (no spaces or hyphens), so names from
-- units, chat links and rosters map to the same key.
local function GetKey(name, realm)
	if not name or IsSecret(name) or IsSecret(realm) or name == "" then
		return
	end
	if not realm or realm == "" then
		realm = GetNormalizedRealmName()
	end
	if not realm then
		return
	end
	return name .. "-" .. realm:gsub("[%s%-]", "")
end

local function OnTooltipUnit(tooltip)
	if not module.enabled or not module.db.tooltip then
		return
	end
	local _, unit = tooltip:GetUnit()
	if not unit or IsSecret(unit) or not UnitIsPlayer(unit) then
		return
	end
	local note = module.db.notes[GetKey(UnitName(unit)) or ""]
	if note then
		tooltip:AddLine(L.TOOLTIP_LINE:format(note), 1, 0.82, 0, true)
	end
end

local function OnMenu(_, rootDescription, contextData)
	if not module.enabled or not contextData then
		return
	end
	local key = GetKey(contextData.name, contextData.server)
	if not key then
		return
	end
	local label = module.db.notes[key] and L.MENU_EDIT or L.MENU_ADD
	rootDescription:CreateDivider()
	rootDescription:CreateButton(label, function()
		StaticPopup_Show(DIALOG, key, nil, key)
	end)
end

function module:OnInitialize()
	StaticPopupDialogs[DIALOG] = {
		text = L.DIALOG,
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		editBoxWidth = 350,
		maxLetters = 255,
		OnShow = function(dialog, key)
			local editBox = dialog:GetEditBox()
			editBox:SetText(self.db.notes[key] or "")
			editBox:HighlightText()
		end,
		OnAccept = function(dialog, key)
			local text = strtrim(dialog:GetEditBox():GetText())
			self.db.notes[key] = text ~= "" and text or nil
		end,
		EditBoxOnEnterPressed = function(editBox)
			editBox:GetParent():GetButton1():Click()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}
	-- Neither API can remove a callback: both check module.enabled instead.
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipUnit)
	for _, which in ipairs(MENUS) do
		Menu.ModifyMenu("MENU_UNIT_" .. which, OnMenu)
	end
end
