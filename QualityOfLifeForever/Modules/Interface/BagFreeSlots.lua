-- luacheck: read globals EventRegistry C_Container Enum ContainerFrameUtil_EnumerateContainerFrames RED_FONT_COLOR HIGHLIGHT_FONT_COLOR DISPLAY_FREE_BAG_SLOTS
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Free bag slots",
		NOTE = "Shown in the backpack window",
		DESC = "Shows how many slots are free in all your bags in the title bar of the backpack window (also with combined bags). Red when your bags are full. The game's option \"%s\" (Interface) shows the number on the backpack button.",
		FREE = "%d free",
	},
	deDE = {
		TITLE = "Freie Taschenplätze",
		NOTE = "Im Rucksackfenster angezeigt",
		DESC = "Zeigt in der Titelleiste des Rucksackfensters (auch bei kombinierten Taschen), wie viele Plätze in all deinen Taschen frei sind. Rot, wenn deine Taschen voll sind. Die Spieloption „%s“ (Interface) zeigt die Zahl auf dem Rucksack-Button.",
		FREE = "%d frei",
	},
})

local module = ns:NewModule("BagFreeSlots", {
	title = L.TITLE,
	-- Blizzard's own label, so the option name matches the client language.
	description = L.DESC:format(DISPLAY_FREE_BAG_SLOTS or ""),
	note = L.NOTE,
	category = "INTERFACE",
})

-- Container frames are reused for any bag, so a label stays with its frame
-- and is only shown while the frame holds the backpack.
local labels = {}

local function IsBackpack(frame)
	return frame:GetBagID() == Enum.BagIndex.Backpack
end

function module:UpdateLabel(frame)
	local label = labels[frame]
	if not label then
		return
	end
	if not (self.enabled and IsBackpack(frame)) then
		label:Hide()
		return
	end
	local free = C_Container.CalculateTotalNumberOfFreeBagSlots()
	local color = free == 0 and RED_FONT_COLOR or HIGHLIGHT_FONT_COLOR
	label:SetText(L.FREE:format(free))
	label:SetTextColor(color:GetRGB())
	label:Show()
end

function module:OnBagOpened(frame)
	if not labels[frame] then
		if not (IsBackpack(frame) and frame.CloseButton) then
			return
		end
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("RIGHT", frame.CloseButton, "LEFT", -2, 0)
		labels[frame] = label
	end
	self:UpdateLabel(frame)
end

function module:UpdateShown()
	for frame in pairs(labels) do
		if frame:IsShown() then
			self:UpdateLabel(frame)
		end
	end
end

function module:OnEnable()
	EventRegistry:RegisterCallback("ContainerFrame.OpenBag", self.OnBagOpened, self)
	self:RegisterEvent("BAG_UPDATE_DELAYED", self.UpdateShown)
	for _, frame in ContainerFrameUtil_EnumerateContainerFrames() do
		if frame:IsShown() then
			self:OnBagOpened(frame)
		end
	end
end

function module:OnDisable()
	EventRegistry:UnregisterCallback("ContainerFrame.OpenBag", self)
	for _, label in pairs(labels) do
		label:Hide()
	end
end
