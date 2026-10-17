-- luacheck: read globals StatisticsFrame C_AddOns CreateFrame CreateTreeDataProvider ScrollBoxConstants
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Statistics search",
		NOTE = "Search box on the statistics page",
		DESC = "Adds a search box to the statistics page of the character window. Shows only statistics and categories whose name contains the search text.",
	},
	deDE = {
		TITLE = "Statistiksuche",
		NOTE = "Suchfeld auf der Statistikseite",
		DESC = "Ergänzt die Statistikseite des Charakterfensters um ein Suchfeld. Zeigt nur Statistiken und Kategorien, deren Name den Suchtext enthält.",
	},
})

local module = ns:NewModule("StatisticsSearch", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "CHARACTER",
})

local box
-- Blizzard rebuilds the complete provider on every Update; we keep it to
-- restore it when the search is cleared.
local fullProvider

local function Matches(data, query)
	local name = data.name
	return type(name) == "string" and name:lower():find(query, 1, true) ~= nil
end

-- Returns the matching part of a subtree as { data, children } entries. A
-- matching category keeps all its children; otherwise only matching
-- descendants and the categories leading to them stay.
local function Collect(nodes, query, keepAll)
	local result = {}
	for _, node in ipairs(nodes) do
		local data = node:GetData()
		local keep = keepAll or Matches(data, query)
		local children = data.isCategory and Collect(node:GetNodes(), query, keep) or {}
		if keep or #children > 0 then
			result[#result + 1] = { data = data, children = children }
		end
	end
	return result
end

local function InsertAll(target, entries)
	for _, entry in ipairs(entries) do
		InsertAll(target:Insert(entry.data), entry.children)
	end
end

local function GetQuery()
	local text = box and box:GetText() or ""
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	return text:lower()
end

function module:ApplyFilter()
	if not fullProvider then
		return
	end
	local query = self.enabled and GetQuery() or ""
	local provider = fullProvider
	if query ~= "" then
		provider = CreateTreeDataProvider()
		InsertAll(provider, Collect(fullProvider:GetChildrenNodes(), query, false))
	end
	if StatisticsFrame.ScrollBox:GetDataProvider() ~= provider then
		StatisticsFrame.ScrollBox:SetDataProvider(provider, ScrollBoxConstants.RetainScrollPosition)
	end
end

function module:OnStatisticsUpdate(frame)
	fullProvider = frame.ScrollBox:GetDataProvider()
	self:ApplyFilter()
end

function module:CreateBox()
	if box or not StatisticsFrame or not StatisticsFrame.ScrollBox then
		return
	end
	local scrollBox = StatisticsFrame.ScrollBox
	box = CreateFrame("EditBox", nil, StatisticsFrame, "SearchBoxTemplate")
	box:SetHeight(20)
	box:SetFrameStrata(scrollBox:GetFrameStrata())
	-- In the free space above the list, left of the pane's collapse button.
	box:SetPoint("BOTTOMLEFT", scrollBox, "TOPLEFT", 8, 8)
	box:SetPoint("BOTTOMRIGHT", scrollBox, "TOPRIGHT", -10, 8)
	box:SetAutoFocus(false)
	box:HookScript("OnTextChanged", function()
		module:ApplyFilter()
	end)

	fullProvider = scrollBox:GetDataProvider()
	self:SecureHook(StatisticsFrame, "Update", self.OnStatisticsUpdate)
	self:HookScript(StatisticsFrame, "OnHide", function()
		box:SetText("")
	end)
	box:SetShown(self.enabled)
end

function module:ADDON_LOADED(name)
	if name == "Blizzard_Statistics" then
		self:UnregisterEvent("ADDON_LOADED")
		self:CreateBox()
	end
end

function module:OnEnable()
	if C_AddOns.IsAddOnLoaded("Blizzard_Statistics") then
		self:CreateBox()
	else
		self:RegisterEvent("ADDON_LOADED")
	end
	if box then
		box:Show()
	end
end

function module:OnDisable()
	if box then
		box:SetText("")
		box:Hide()
		self:ApplyFilter()
	end
end
