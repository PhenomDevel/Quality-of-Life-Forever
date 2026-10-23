-- luacheck: read globals EventRegistry C_Container C_Timer Enum InCombatLockdown GetCursorInfo
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Auto-sort bags",
		NOTE = "Sorts your bags when you open them",
		DESC = "Runs the game's bag cleanup every time you open your backpack. Skipped in combat and while you hold an item on the cursor.",
		NOTICE = "Moves the items in your bags every time you open your backpack. Bags you excluded from cleanup stay untouched.",
	},
	deDE = {
		TITLE = "Taschen automatisch sortieren",
		NOTE = "Sortiert deine Taschen beim Öffnen",
		DESC = "Führt die Taschen-Aufräumfunktion des Spiels bei jedem Öffnen deines Rucksacks aus. Wird im Kampf und mit einem Gegenstand am Mauszeiger übersprungen.",
		NOTICE = "Verschiebt die Gegenstände in deinen Taschen bei jedem Öffnen des Rucksacks. Taschen, die du vom Aufräumen ausgenommen hast, bleiben unberührt.",
	},
})

local module = ns:NewModule("AutoSortBags", {
	title = L.TITLE,
	description = L.DESC,
	notice = L.NOTICE,
	note = L.NOTE,
	category = "BAGS",
	order = 30,
})

local pending = false

local function Sort()
	pending = false
	if module.enabled and not InCombatLockdown() and not GetCursorInfo() then
		C_Container.SortBags()
	end
end

-- Fires for every bag frame that opens; opening all bags sorts once.
function module:OnBagOpened(frame)
	if not self.enabled or pending or frame:GetBagID() ~= Enum.BagIndex.Backpack then
		return
	end
	pending = true
	C_Timer.After(0, Sort)
end

function module:OnEnable()
	EventRegistry:RegisterCallback("ContainerFrame.OpenBag", self.OnBagOpened, self)
end

function module:OnDisable()
	EventRegistry:UnregisterCallback("ContainerFrame.OpenBag", self)
end
