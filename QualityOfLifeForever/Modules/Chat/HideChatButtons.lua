local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Hide chat buttons",
		NOTE = "Menu, channel and voice buttons next to the chat",
		DESC = "Hides the menu, channel and voice buttons next to the chat. Disabling shows them again.",
	},
	deDE = {
		TITLE = "Chat-Knöpfe ausblenden",
		NOTE = "Menü-, Kanal- und Sprachchat-Knöpfe neben dem Chat",
		DESC = "Blendet die Menü-, Kanal- und Sprachchat-Knöpfe neben dem Chat aus. Beim Deaktivieren erscheinen sie wieder.",
	},
})

local module = ns:NewModule("HideChatButtons", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHAT",
	order = 70,
})

local BUTTONS = { "ChatFrameMenuButton", "ChatFrameChannelButton", "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton", "QuickJoinToastButton" }

-- Only buttons we hid, so ones Blizzard hides itself (voice) stay hidden.
local hiddenButtons = {}

local function HideButton(button)
	if button:IsShown() then
		hiddenButtons[button] = true
		button:Hide()
	end
end

function module:OnEnable()
	for _, name in ipairs(BUTTONS) do
		local button = _G[name]
		if button then
			HideButton(button)
			self:HookScript(button, "OnShow", function(_, shown)
				HideButton(shown)
			end)
		end
	end
end

function module:OnDisable()
	for button in pairs(hiddenButtons) do
		button:Show()
	end
	wipe(hiddenButtons)
end
