-- luacheck: read globals ClassTrainerFrame ClassTrainerTrainButton C_AddOns CreateFrame GameTooltip GetMoney GetNumTrainerServices GetTrainerServiceInfo GetTrainerServiceCost BuyTrainerService RED_FONT_COLOR HIGHLIGHT_FONT_COLOR
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Train all",
		NOTE = "Button at trainers to learn everything",
		DESC = "Adds a \"Train all\" button to the trainer window that learns every available skill at once. Professions are left out. Hover the button to see the total cost.",
		BUTTON = "Train all",
		COUNT = "%d skills",
		TOTAL = "Total: %s",
		NOT_ENOUGH = "Not enough money for everything; learns in list order until it runs out.",
	},
	deDE = {
		TITLE = "Alles lernen",
		NOTE = "Knopf beim Lehrer, um alles zu lernen",
		DESC = "Ergänzt das Lehrerfenster um einen Knopf „Alles lernen“, der alle verfügbaren Fähigkeiten auf einmal lernt. Berufe sind ausgenommen. Mit der Maus über dem Knopf siehst du die Gesamtkosten.",
		BUTTON = "Alles lernen",
		COUNT = "%d Fähigkeiten",
		TOTAL = "Gesamt: %s",
		NOT_ENOUGH = "Nicht genug Gold für alles; lernt in Listenreihenfolge, bis es nicht mehr reicht.",
	},
})

local module = ns:NewModule("TrainAll", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "MERCHANT",
})

local FormatMoney = ns.Utils.FormatMoney
local button

-- Indexes and total cost of all learnable services (professions excluded:
-- they need a free profession slot and Blizzard asks for confirmation).
local function GetAvailable()
	local indexes, total = {}, 0
	for i = 1, GetNumTrainerServices() do
		local _, serviceType = GetTrainerServiceInfo(i)
		if serviceType == "available" then
			local cost, isProfession = GetTrainerServiceCost(i)
			if not isProfession then
				indexes[#indexes + 1] = i
				total = total + (cost or 0)
			end
		end
	end
	return indexes, total
end

local function UpdateButton()
	if not button then
		return
	end
	button:SetShown(module.enabled)
	button:SetEnabled(#GetAvailable() > 0)
end

-- Buys from the end of the list so the lower indexes stay valid while the
-- list updates.
local function TrainAll()
	local indexes = GetAvailable()
	local money = GetMoney()
	for n = #indexes, 1, -1 do
		local index = indexes[n]
		local cost = GetTrainerServiceCost(index) or 0
		if cost <= money then
			BuyTrainerService(index)
			money = money - cost
		end
	end
end

local function ShowTooltip(self)
	local indexes, total = GetAvailable()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(L.BUTTON)
	GameTooltip:AddLine(L.COUNT:format(#indexes), HIGHLIGHT_FONT_COLOR:GetRGB())
	GameTooltip:AddLine(L.TOTAL:format(FormatMoney(total)), HIGHLIGHT_FONT_COLOR:GetRGB())
	if total > GetMoney() then
		GameTooltip:AddLine(L.NOT_ENOUGH, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
	end
	GameTooltip:Show()
end

function module:CreateButton()
	if button or not ClassTrainerFrame or not ClassTrainerTrainButton then
		return
	end
	button = CreateFrame("Button", nil, ClassTrainerFrame, "UIPanelButtonTemplate")
	button:SetText(L.BUTTON)
	button:SetSize(ClassTrainerTrainButton:GetWidth(), ClassTrainerTrainButton:GetHeight())
	button:SetPoint("RIGHT", ClassTrainerTrainButton, "LEFT", -2, 0)
	button:SetMotionScriptsWhileDisabled(true)
	button:SetScript("OnClick", TrainAll)
	button:SetScript("OnEnter", ShowTooltip)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	self:HookScript(ClassTrainerFrame, "OnShow", UpdateButton)
	UpdateButton()
end

function module:ADDON_LOADED(name)
	if name == "Blizzard_TrainerUI" then
		self:UnregisterEvent("ADDON_LOADED")
		self:CreateButton()
	end
end

function module:OnEnable()
	self:RegisterEvent("TRAINER_UPDATE", UpdateButton)
	self:RegisterEvent("PLAYER_MONEY", UpdateButton)
	if C_AddOns.IsAddOnLoaded("Blizzard_TrainerUI") then
		self:CreateButton()
	else
		self:RegisterEvent("ADDON_LOADED")
	end
	UpdateButton()
end

function module:OnDisable()
	if button then
		button:Hide()
	end
end
