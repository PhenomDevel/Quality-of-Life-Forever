-- luacheck: read globals WorldMapFrame C_Map C_Timer Enum UnitLevel CreateFrame GameFontNormal
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Zone level ranges",
		NOTE = "Level range on the world map",
		DESC = "Shows the level range of zones on the world map, colored by your level.",
		ZONE_MAP = "On zone maps",
		ZONE_MAP_DESC = "Shows the range of the zone in the top right corner of the map.",
		CONTINENT_MAP = "On continent maps",
		CONTINENT_MAP_DESC = "Shows the range on every zone of the continent.",
		LEVEL = "Level %s",
	},
	deDE = {
		TITLE = "Zonen-Levelbereiche",
		NOTE = "Levelbereich auf der Weltkarte",
		DESC = "Zeigt den Levelbereich der Zonen auf der Weltkarte, eingefärbt nach deiner Stufe.",
		ZONE_MAP = "Auf Zonenkarten",
		ZONE_MAP_DESC = "Zeigt den Bereich der Zone oben rechts auf der Karte.",
		CONTINENT_MAP = "Auf Kontinentkarten",
		CONTINENT_MAP_DESC = "Zeigt den Bereich auf jeder Zone des Kontinents.",
		LEVEL = "Stufe %s",
	},
})

local module = ns:NewModule("ZoneLevels", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "MAP",
	defaults = {
		zoneMap = true,
		continentMap = true,
	},
	options = {
		{ key = "zoneMap", type = "checkbox", label = L.ZONE_MAP, tooltip = L.ZONE_MAP_DESC },
		{ key = "continentMap", type = "checkbox", label = L.CONTINENT_MAP, tooltip = L.CONTINENT_MAP_DESC },
	},
})

-- C_Map.GetMapLevels returns 0 in Forever, so the ranges are a static table.
-- uiMapID = { min, max }. Derived from the leveling routes in
-- https://mobalytics.gg/wow-forever/guides/zone-map-level-ranges: lowest start
-- and highest end of all route steps that name the zone.
local LEVELS = {
	-- Eastern Kingdoms
	[1429] = { 1, 10 }, -- Elwynn Forest
	[1426] = { 1, 10 }, -- Dun Morogh
	[1420] = { 1, 10 }, -- Tirisfal Glades
	[1436] = { 10, 19 }, -- Westfall
	[1432] = { 10, 19 }, -- Loch Modan
	[1421] = { 10, 18 }, -- Silverpine Forest
	[1433] = { 15, 30 }, -- Redridge Mountains
	[1431] = { 18, 30 }, -- Duskwood
	[1437] = { 20, 30 }, -- Wetlands
	[1424] = { 22, 30 }, -- Hillsbrad Foothills
	[1417] = { 30, 40 }, -- Arathi Highlands
	[1434] = { 30, 45 }, -- Stranglethorn Vale
	[1418] = { 35, 45 }, -- Badlands
	[1435] = { 35, 45 }, -- Swamp of Sorrows
	[1425] = { 40, 50 }, -- The Hinterlands
	[1427] = { 43, 55 }, -- Searing Gorge
	[1419] = { 43, 55 }, -- Blasted Lands
	[1428] = { 50, 60 }, -- Burning Steppes
	[1422] = { 50, 60 }, -- Western Plaguelands
	[1423] = { 50, 60 }, -- Eastern Plaguelands
	[2548] = { 35, 45 }, -- Riverglades
	-- Kalimdor
	[1438] = { 1, 11 }, -- Teldrassil
	[1411] = { 1, 10 }, -- Durotar
	[1412] = { 1, 10 }, -- Mulgore
	[1439] = { 11, 20 }, -- Darkshore
	[1413] = { 10, 25 }, -- The Barrens
	[1442] = { 15, 30 }, -- Stonetalon Mountains
	[1440] = { 19, 30 }, -- Ashenvale
	[1441] = { 25, 35 }, -- Thousand Needles
	[1443] = { 30, 40 }, -- Desolace
	[1445] = { 35, 45 }, -- Dustwallow Marsh
	[1446] = { 40, 50 }, -- Tanaris
	[1444] = { 40, 50 }, -- Feralas
	[1447] = { 43, 55 }, -- Azshara
	[1449] = { 48, 55 }, -- Un'Goro Crater
	[1448] = { 48, 55 }, -- Felwood
	[1452] = { 50, 60 }, -- Winterspring
	[1451] = { 50, 60 }, -- Silithus
	[2482] = { 60, 60 }, -- Mount Hyjal
	-- Skyborne starting zone
	[2521] = { 1, 12 }, -- Zephras Isle
}

local ZONE_FONT_SIZE = 22
-- In canvas units; the canvas is scaled with the map zoom.
local LABEL_FONT_SIZE = 26

-- zoneText: top right of the map frame (zone maps).
-- labels: font strings on the map canvas (continent maps), reused.
local zoneText, labelFrame
local labels = {}

local function GetColor(minLevel, maxLevel)
	local level = UnitLevel("player")
	if level < minLevel - 2 then
		return 1, 0.1, 0.1
	elseif level < minLevel then
		return 1, 0.5, 0.25
	elseif level <= maxLevel then
		return 1, 0.82, 0
	elseif level <= maxLevel + 5 then
		return 0.25, 0.75, 0.25
	end
	return 0.5, 0.5, 0.5
end

-- Colored "10–20" (or "60"), for embedding in a white text.
local function FormatRange(range)
	local minLevel, maxLevel = range[1], range[2]
	local r, g, b = GetColor(minLevel, maxLevel)
	local text = minLevel == maxLevel and tostring(minLevel) or ("%d–%d"):format(minLevel, maxLevel)
	return ("|cff%02x%02x%02x%s|r"):format(r * 255, g * 255, b * 255, text)
end

local function CreateText(parent, size)
	local text = parent:CreateFontString(nil, "OVERLAY")
	local font = GameFontNormal:GetFont()
	text:SetFont(font, size, "OUTLINE")
	text:SetTextColor(1, 1, 1)
	return text
end

function module:ShowContinentLabels(mapID)
	local canvas = WorldMapFrame.ScrollContainer.Child
	local width, height = canvas:GetSize()
	local count = 0
	for _, child in ipairs(C_Map.GetMapChildrenInfo(mapID) or {}) do
		local range = LEVELS[child.mapID]
		if range then
			local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(child.mapID, mapID)
			if minX then
				count = count + 1
				local label = labels[count]
				if not label then
					label = CreateText(labelFrame, LABEL_FONT_SIZE)
					labels[count] = label
				end
				label:ClearAllPoints()
				label:SetPoint("CENTER", canvas, "TOPLEFT", (minX + maxX) / 2 * width, -(minY + maxY) / 2 * height)
				label:SetText(FormatRange(range))
				label:Show()
			end
		end
	end
end

function module:Update()
	if not zoneText then
		return
	end
	zoneText:Hide()
	for _, label in ipairs(labels) do
		label:Hide()
	end
	local mapID = WorldMapFrame:GetMapID()
	local info = mapID and C_Map.GetMapInfo(mapID)
	if not info then
		return
	end
	if info.mapType == Enum.UIMapType.Continent then
		if self.db.continentMap then
			self:ShowContinentLabels(mapID)
		end
	elseif self.db.zoneMap and LEVELS[mapID] then
		zoneText:SetFormattedText(L.LEVEL, FormatRange(LEVELS[mapID]))
		zoneText:Show()
	end
end

-- The canvas gets its size for the new map during the change; update after it.
function module:QueueUpdate()
	C_Timer.After(0, function()
		if self.enabled and WorldMapFrame:IsShown() then
			self:Update()
		end
	end)
end

function module:OnEnable()
	if not zoneText then
		local container = WorldMapFrame.ScrollContainer
		local overlay = CreateFrame("Frame", nil, container)
		overlay:SetAllPoints(container)
		overlay:SetFrameLevel(container:GetFrameLevel() + 20)
		zoneText = CreateText(overlay, ZONE_FONT_SIZE)
		zoneText:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -16, -48)

		local canvas = container.Child
		labelFrame = CreateFrame("Frame", nil, canvas)
		labelFrame:SetAllPoints(canvas)
		labelFrame:SetFrameLevel(canvas:GetFrameLevel() + 10)
	end
	self:SecureHook(WorldMapFrame, "OnMapChanged", self.QueueUpdate)
	self:HookScript(WorldMapFrame, "OnShow", self.QueueUpdate)
	self:RegisterEvent("PLAYER_LEVEL_UP", "QueueUpdate")
	self:QueueUpdate()
end

function module:OnDisable()
	if zoneText then
		zoneText:Hide()
		for _, label in ipairs(labels) do
			label:Hide()
		end
	end
end

function module:OnOptionChanged()
	self:QueueUpdate()
end
