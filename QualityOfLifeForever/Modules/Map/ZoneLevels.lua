-- luacheck: read globals WorldMapFrame Minimap C_Map C_Timer Enum UnitLevel CreateFrame GameFontNormal
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Zone level ranges",
		NOTE = "Level range on the world map and minimap",
		DESC = "Shows the level range of zones on the world map, colored by your level.",
		ZONE_MAP = "On zone maps",
		ZONE_MAP_DESC = "Shows the range of the zone at the bottom of the map.",
		CONTINENT_MAP = "On continent maps",
		CONTINENT_MAP_DESC = "Shows the range on every zone of the continent.",
		HOVER = "In the zone name on hover",
		HOVER_DESC = "Adds the range to the zone name shown when hovering a zone on a continent map.",
		MINIMAP = "On the minimap",
		MINIMAP_DESC = "Shows the range of your current zone at the bottom of the minimap.",
		LEVEL = "Level %s",
	},
	deDE = {
		TITLE = "Zonen-Levelbereiche",
		NOTE = "Levelbereich auf Weltkarte und Minimap",
		DESC = "Zeigt den Levelbereich der Zonen auf der Weltkarte, eingefärbt nach deiner Stufe.",
		ZONE_MAP = "Auf Zonenkarten",
		ZONE_MAP_DESC = "Zeigt den Bereich der Zone unten auf der Karte.",
		CONTINENT_MAP = "Auf Kontinentkarten",
		CONTINENT_MAP_DESC = "Zeigt den Bereich auf jeder Zone des Kontinents.",
		HOVER = "Im Zonennamen beim Überfahren",
		HOVER_DESC = "Ergänzt den Bereich am Zonennamen, der beim Überfahren einer Zone auf der Kontinentkarte erscheint.",
		MINIMAP = "Auf der Minimap",
		MINIMAP_DESC = "Zeigt den Bereich deiner aktuellen Zone unten auf der Minimap.",
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
		hover = true,
		minimap = true,
	},
	options = {
		{ key = "zoneMap", type = "checkbox", label = L.ZONE_MAP, tooltip = L.ZONE_MAP_DESC },
		{ key = "continentMap", type = "checkbox", label = L.CONTINENT_MAP, tooltip = L.CONTINENT_MAP_DESC },
		{ key = "hover", type = "checkbox", label = L.HOVER, tooltip = L.HOVER_DESC },
		{ key = "minimap", type = "checkbox", label = L.MINIMAP, tooltip = L.MINIMAP_DESC },
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

local ZONE_FONT_SIZE = 26
local MINIMAP_FONT_SIZE = 13
-- In canvas units; the canvas is scaled with the map zoom.
local LABEL_FONT_SIZE = 16

-- zoneText: top right of the map frame (zone maps).
-- labels: font strings on the map canvas (continent maps), reused.
-- minimapText: bottom of the minimap (current zone).
local zoneText, labelFrame, minimapText
local labels = {}
-- Localized zone name -> uiMapID, for the hover label.
local zoneByName
local areaLabelHooked, settingAreaLabel

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

-- Zone the player is in; walks up from sub-zone, city and dungeon maps.
local function GetPlayerZone()
	local mapID = C_Map.GetBestMapForUnit("player")
	while mapID do
		if LEVELS[mapID] then
			return mapID
		end
		local info = C_Map.GetMapInfo(mapID)
		if not info or info.mapType <= Enum.UIMapType.Zone then
			return
		end
		mapID = info.parentMapID
	end
end

function module:UpdateMinimap()
	local mapID = self.db.minimap and GetPlayerZone()
	if mapID then
		minimapText:SetFormattedText(L.LEVEL, FormatRange(LEVELS[mapID]))
		minimapText:Show()
	else
		minimapText:Hide()
	end
end

-- Blizzard's hover label on the map (zone name on continent maps) belongs to
-- a map data provider; its Name font string is set whenever the hovered area
-- changes. Hooking SetText avoids depending on the provider's methods.
function module:HookAreaLabel()
	if areaLabelHooked then
		return
	end
	for provider in pairs(WorldMapFrame.dataProviders or {}) do
		local label = type(provider) == "table" and provider.Label
		if type(label) == "table" and label.Name and label.Name.SetText then
			areaLabelHooked = true
			self:SecureHook(label.Name, "SetText", self.OnAreaLabelSetText)
			return
		end
	end
	self:Debug("world map area label not found")
end

function module:OnAreaLabelSetText(fontString, name)
	if settingAreaLabel or not self.db.hover or type(name) ~= "string" then
		return
	end
	if not zoneByName then
		zoneByName = {}
		for mapID in pairs(LEVELS) do
			local info = C_Map.GetMapInfo(mapID)
			if info then
				zoneByName[info.name] = mapID
			end
		end
	end
	local mapID = zoneByName[name]
	if mapID then
		settingAreaLabel = true
		fontString:SetText(("%s (%s)"):format(name, FormatRange(LEVELS[mapID])))
		settingAreaLabel = false
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
		zoneText:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 16)

		local canvas = container.Child
		labelFrame = CreateFrame("Frame", nil, canvas)
		labelFrame:SetAllPoints(canvas)
		labelFrame:SetFrameLevel(canvas:GetFrameLevel() + 10)

		minimapText = CreateText(Minimap, MINIMAP_FONT_SIZE)
		-- Inside the minimap: the client shows player coordinates right below it.
		minimapText:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 12)
	end
	self:SecureHook(WorldMapFrame, "OnMapChanged", self.QueueUpdate)
	self:HookAreaLabel()
	self:HookScript(WorldMapFrame, "OnShow", self.QueueUpdate)
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnLevelUp")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateMinimap")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateMinimap")
	self:RegisterEvent("ZONE_CHANGED", "UpdateMinimap")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "UpdateMinimap")
	self:QueueUpdate()
	self:UpdateMinimap()
end

-- UnitLevel may still return the old level during the event.
function module:OnLevelUp()
	C_Timer.After(0, function()
		if self.enabled then
			self:UpdateMinimap()
		end
	end)
	self:QueueUpdate()
end

function module:OnDisable()
	if zoneText then
		minimapText:Hide()
		zoneText:Hide()
		for _, label in ipairs(labels) do
			label:Hide()
		end
	end
end

function module:OnOptionChanged()
	self:QueueUpdate()
	self:UpdateMinimap()
end
