-- luacheck: read globals C_Trainer C_PetInfo Enum ClassTrainerFrame ClassTrainerTrainButton C_AddOns CreateFrame GameTooltip GetMoney GetNumTrainerServices GetTrainerServiceInfo GetTrainerServiceCost BuyTrainerService RED_FONT_COLOR HIGHLIGHT_FONT_COLOR
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Train all button",
		NOTE = "Button at trainers to learn everything",
		DESC = "Adds a \"Train all\" button to the trainer window that learns every available skill at once. Professions are left out. Hover the button to see the total cost.",
		BUTTON = "Train all",
		COUNT = "%d skills",
		TOTAL = "Total: %s",
		NOT_ENOUGH = "Not enough money for everything; learns in list order until it runs out.",
		TOTAL_POINTS = "Total: %d training points",
		NOT_ENOUGH_POINTS = "Not enough training points for everything; learns in list order until they run out.",
		PET_TRAINER = "Also at pet trainers",
		PET_TRAINER_DESC = "Shows the button at pet trainers too. It spends your pet's training points instead of gold.",
	},
	deDE = {
		TITLE = "Button „Alles lernen“",
		NOTE = "Button beim Lehrer, um alles zu lernen",
		DESC = "Ergänzt das Lehrerfenster um einen Button „Alles lernen“, der alle verfügbaren Fähigkeiten auf einmal lernt. Berufe sind ausgenommen. Mit der Maus über dem Button siehst du die Gesamtkosten.",
		BUTTON = "Alles lernen",
		COUNT = "%d Fähigkeiten",
		TOTAL = "Gesamt: %s",
		NOT_ENOUGH = "Nicht genug Gold für alles; lernt in Listenreihenfolge, bis es nicht mehr reicht.",
		TOTAL_POINTS = "Gesamt: %d Trainingspunkte",
		NOT_ENOUGH_POINTS = "Nicht genug Trainingspunkte für alles; lernt in Listenreihenfolge, bis sie nicht mehr reichen.",
		PET_TRAINER = "Auch bei Begleiterlehrern",
		PET_TRAINER_DESC = "Zeigt den Button auch bei Begleiterlehrern. Er verbraucht dort die Trainingspunkte deines Begleiters statt Gold.",
	},
})

local module = ns:NewModule("TrainAll", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "MERCHANT",
	defaults = {
		petTrainer = false,
	},
	options = {
		{ key = "petTrainer", type = "checkbox", label = L.PET_TRAINER, tooltip = L.PET_TRAINER_DESC },
	},
})

local FormatMoney = ns.Utils.FormatMoney
local button

-- Pet trainers (Forever) charge the pet's training points instead of gold;
-- GetTrainerServiceCost then returns points.
local function IsPetTrainer()
	local trainerType = C_Trainer and C_Trainer.GetTrainerType and C_Trainer.GetTrainerType()
	return Enum.TrainerType ~= nil and trainerType == Enum.TrainerType.Pet
end

-- Gold, or the pet's free training points at a pet trainer.
local function GetBudget()
	if IsPetTrainer() then
		local total, used = C_PetInfo.GetPetTrainingPoints()
		return math.max((total or 0) - (used or 0), 0)
	end
	return GetMoney()
end

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
	button:SetShown(module.enabled and (module.db.petTrainer or not IsPetTrainer()))
	button:SetEnabled(#GetAvailable() > 0)
end

-- Buys from the end of the list so the lower indexes stay valid while the
-- list updates.
local function TrainAll()
	local indexes = GetAvailable()
	local budget = GetBudget()
	for n = #indexes, 1, -1 do
		local index = indexes[n]
		local cost = GetTrainerServiceCost(index) or 0
		if cost <= budget then
			BuyTrainerService(index)
			budget = budget - cost
		end
	end
end

local function ShowTooltip(self)
	local indexes, total = GetAvailable()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(L.BUTTON)
	GameTooltip:AddLine(L.COUNT:format(#indexes), HIGHLIGHT_FONT_COLOR:GetRGB())
	local isPet = IsPetTrainer()
	local totalText = isPet and L.TOTAL_POINTS:format(total) or L.TOTAL:format(FormatMoney(total))
	GameTooltip:AddLine(totalText, HIGHLIGHT_FONT_COLOR:GetRGB())
	if total > GetBudget() then
		GameTooltip:AddLine(isPet and L.NOT_ENOUGH_POINTS or L.NOT_ENOUGH, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
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

function module:OnOptionChanged()
	UpdateButton()
end
