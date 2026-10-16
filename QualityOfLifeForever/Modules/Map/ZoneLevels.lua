-- luacheck: read globals WorldMapFrame C_Map Enum UnitLevel CreateFrame
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Zone level ranges",
		NOTE = "Level range on the world map",
		DESC = "Shows the level range of a zone on the world map, colored by your level.",
		ZONE_MAP = "On zone maps",
		ZONE_MAP_DESC = "Shows the range of the zone the map shows.",
		CONTINENT_MAP = "On continent maps",
		CONTINENT_MAP_DESC = "Shows the range of the zone under the cursor.",
		RANGE = "Level %d–%d",
		NAMED_RANGE = "%s: level %d–%d",
	},
	deDE = {
		TITLE = "Zonen-Levelbereiche",
		NOTE = "Levelbereich auf der Weltkarte",
		DESC = "Zeigt den Levelbereich einer Zone auf der Weltkarte, eingefärbt nach deiner Stufe.",
		ZONE_MAP = "Auf Zonenkarten",
		ZONE_MAP_DESC = "Zeigt den Bereich der angezeigten Zone.",
		CONTINENT_MAP = "Auf Kontinentkarten",
		CONTINENT_MAP_DESC = "Zeigt den Bereich der Zone unter dem Mauszeiger.",
		RANGE = "Stufe %d–%d",
		NAMED_RANGE = "%s: Stufe %d–%d",
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
-- TODO: Zephras Isle (1-12), Riverglades (35-45), Mount Hyjal (60) – uiMapIDs unknown.
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
}

local UPDATE_INTERVAL = 0.1

local frame, text

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

-- Zone the text is about, or nil: the shown zone map, or on a continent map
-- the zone under the cursor.
function module:GetTargetMap()
	local mapID = WorldMapFrame:GetMapID()
	local info = mapID and C_Map.GetMapInfo(mapID)
	if not info then
		return
	end
	if info.mapType == Enum.UIMapType.Continent then
		if not self.db.continentMap or not WorldMapFrame.ScrollContainer:IsMouseOver() then
			return
		end
		local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
		local child = x and C_Map.GetMapInfoAtPosition(mapID, x, y)
		if child then
			return child.mapID, child.name
		end
	elseif self.db.zoneMap then
		return mapID
	end
end

function module:Update()
	local mapID, name = self:GetTargetMap()
	local range = mapID and LEVELS[mapID]
	if not range then
		text:Hide()
		return
	end
	local minLevel, maxLevel = range[1], range[2]
	if name then
		text:SetFormattedText(L.NAMED_RANGE, name, minLevel, maxLevel)
	else
		text:SetFormattedText(L.RANGE, minLevel, maxLevel)
	end
	text:SetTextColor(GetColor(minLevel, maxLevel))
	text:Show()
end

function module:OnEnable()
	if not frame then
		local container = WorldMapFrame.ScrollContainer
		frame = CreateFrame("Frame", nil, container)
		frame:SetAllPoints(container)
		frame:SetFrameLevel(container:GetFrameLevel() + 20)
		text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		text:SetPoint("BOTTOM", frame, "BOTTOM", 0, 16)
		local elapsed = 0
		frame:SetScript("OnUpdate", function(_, delta)
			elapsed = elapsed + delta
			if elapsed >= UPDATE_INTERVAL then
				elapsed = 0
				module:Update()
			end
		end)
	end
	frame:Show()
end

function module:OnDisable()
	if frame then
		frame:Hide()
	end
end
