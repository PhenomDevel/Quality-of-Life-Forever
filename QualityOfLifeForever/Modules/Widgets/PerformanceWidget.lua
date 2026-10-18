-- luacheck: read globals CreateFont STANDARD_TEXT_FONT C_Timer GetFramerate GetNetStats
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "FPS & latency widget",
		NOTE = "Frame rate and latency at a glance",
		DESC = "A small movable display of your frame rate and latency, updated every second. Drag it to move it; scale it in {Edit Mode}.",
		EDIT_MODE_NAME = "QoL Forever: FPS & latency",
		SECTION_SHOW = "Show",
		SECTION_LOOK = "Appearance",
		SHOW_FPS = "Frame rate",
		SHOW_FPS_DESC = "Frames per second.",
		SHOW_LATENCY = "Latency",
		SHOW_LATENCY_DESC = "Round trip time to the server in milliseconds.",
		LATENCY_SOURCE = "Latency source",
		LATENCY_SOURCE_DESC = "Home: chat, auction house and other realm services. World: combat, movement and other players. Higher: whichever is worse.",
		SOURCE_HOME = "Home",
		SOURCE_WORLD = "World",
		SOURCE_MAX = "Higher of both",
		COLORED = "Color by value",
		COLORED_DESC = "Green, yellow or red depending on how good the value is.",
		LAYOUT = "Layout",
		LAYOUT_DESC = "Horizontal: both values in one line. Vertical: stacked.",
		LAYOUT_HORIZONTAL = "Horizontal",
		LAYOUT_VERTICAL = "Vertical",
		FONT_SIZE = "Text size",
		FONT_SIZE_DESC = "Size of the widget's text. The widget grows with it.",
		BG_OPACITY = "Background opacity",
		BG_OPACITY_DESC = "Opacity of the widget's background and border, 0 % (transparent) to 100 %.",
		FPS = "%d fps",
		LATENCY = "%d ms",
	},
	deDE = {
		TITLE = "FPS- & Latenz-Widget",
		NOTE = "Bildrate und Latenz auf einen Blick",
		DESC = "Eine kleine verschiebbare Anzeige deiner Bildrate und Latenz, jede Sekunde aktualisiert. Zum Verschieben ziehen; skalieren im {Bearbeitungsmodus}.",
		EDIT_MODE_NAME = "QoL Forever: FPS & Latenz",
		SECTION_SHOW = "Anzeigen",
		SECTION_LOOK = "Darstellung",
		SHOW_FPS = "Bildrate",
		SHOW_FPS_DESC = "Bilder pro Sekunde.",
		SHOW_LATENCY = "Latenz",
		SHOW_LATENCY_DESC = "Antwortzeit des Servers in Millisekunden.",
		LATENCY_SOURCE = "Latenz-Quelle",
		LATENCY_SOURCE_DESC = "Heimat: Chat, Auktionshaus und andere Realm-Dienste. Welt: Kampf, Bewegung und andere Spieler. Höhere: der schlechtere der beiden Werte.",
		SOURCE_HOME = "Heimat",
		SOURCE_WORLD = "Welt",
		SOURCE_MAX = "Höhere der beiden",
		COLORED = "Nach Wert färben",
		COLORED_DESC = "Grün, gelb oder rot, je nachdem wie gut der Wert ist.",
		LAYOUT = "Ausrichtung",
		LAYOUT_DESC = "Horizontal: beide Werte in einer Zeile. Vertikal: untereinander.",
		LAYOUT_HORIZONTAL = "Horizontal",
		LAYOUT_VERTICAL = "Vertikal",
		FONT_SIZE = "Textgröße",
		FONT_SIZE_DESC = "Schriftgröße des Widgets. Das Widget wächst mit.",
		BG_OPACITY = "Hintergrund-Deckkraft",
		BG_OPACITY_DESC = "Deckkraft von Hintergrund und Rahmen des Widgets, von 0 % (durchsichtig) bis 100 %.",
		FPS = "%d fps",
		LATENCY = "%d ms",
	},
})

local function FormatPercent(value)
	return ("%d%%"):format(value)
end

local module = ns:NewModule("PerformanceWidget", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "WIDGETS",
	defaults = {
		showFps = true,
		showLatency = true,
		latencySource = "WORLD",
		colored = true,
		layout = "HORIZONTAL",
		fontSize = 11,
		backgroundOpacity = 92,
	},
	options = {
		{ type = "header", label = L.SECTION_SHOW },
		{ key = "showFps", type = "checkbox", label = L.SHOW_FPS, tooltip = L.SHOW_FPS_DESC },
		{ key = "showLatency", type = "checkbox", label = L.SHOW_LATENCY, tooltip = L.SHOW_LATENCY_DESC },
		{
			key = "latencySource",
			type = "dropdown",
			label = L.LATENCY_SOURCE,
			tooltip = L.LATENCY_SOURCE_DESC,
			values = {
				{ value = "HOME", label = L.SOURCE_HOME },
				{ value = "WORLD", label = L.SOURCE_WORLD },
				{ value = "MAX", label = L.SOURCE_MAX },
			},
		},
		{ type = "header", label = L.SECTION_LOOK },
		{ key = "colored", type = "checkbox", label = L.COLORED, tooltip = L.COLORED_DESC },
		{
			key = "layout",
			type = "dropdown",
			label = L.LAYOUT,
			tooltip = L.LAYOUT_DESC,
			values = {
				{ value = "HORIZONTAL", label = L.LAYOUT_HORIZONTAL },
				{ value = "VERTICAL", label = L.LAYOUT_VERTICAL },
			},
		},
		{ key = "fontSize", type = "slider", label = L.FONT_SIZE, tooltip = L.FONT_SIZE_DESC, min = 8, max = 20, step = 1 },
		{ key = "backgroundOpacity", type = "slider", label = L.BG_OPACITY, tooltip = L.BG_OPACITY_DESC, min = 0, max = 100, step = 1, format = FormatPercent },
	},
})

-- Sizes at the default text size of 11; they scale with the text size.
-- Column width fits "999 fps" / "9999 ms", so the widget never resizes.
local BASE_FONT_SIZE = 11
local COLUMN_WIDTH = 52
local COLUMN_GAP = 10
local PADDING = 7
local ROW_GAP = 3
local REFRESH_SECONDS = 1

local GOOD_COLOR = { 0.45, 0.9, 0.45 }
local OK_COLOR = { 1, 0.82, 0 }
local BAD_COLOR = { 1, 0.45, 0.45 }
local PLAIN_COLOR = { 0.9, 0.9, 0.9 }

-- { good from, ok from }: fps counts higher as better, latency lower.
local FPS_LIMITS = { 50, 25 }
local LATENCY_LIMITS = { 100, 250 }

local frame, ticker

local function CreateText(parent)
	local text = parent:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(module.font)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	return text
end

local function CreateWidget()
	frame = ns:CreateOverlay("PerformanceWidget", {
		title = L.EDIT_MODE_NAME,
		width = 2 * COLUMN_WIDTH + COLUMN_GAP + 2 * PADDING,
		height = 26,
		default = { point = "TOP", x = 0, y = -60 },
	})
	frame.Fps = CreateText(frame)
	frame.Latency = CreateText(frame)
end

local function Scaled(value)
	return math.floor(value * module.db.fontSize / BASE_FONT_SIZE + 0.5)
end

local function ShownTexts()
	local texts = {}
	if module.db.showFps then
		texts[#texts + 1] = frame.Fps
	end
	if module.db.showLatency then
		texts[#texts + 1] = frame.Latency
	end
	return texts
end

local function Color(value, limits, higherIsBetter)
	if not module.db.colored then
		return PLAIN_COLOR
	end
	if higherIsBetter then
		return value >= limits[1] and GOOD_COLOR or value >= limits[2] and OK_COLOR or BAD_COLOR
	end
	return value <= limits[1] and GOOD_COLOR or value <= limits[2] and OK_COLOR or BAD_COLOR
end

local function Latency()
	local _, _, home, world = GetNetStats()
	local source = module.db.latencySource
	if source == "HOME" then
		return home
	elseif source == "MAX" then
		return math.max(home, world)
	end
	return world
end

function module:ApplyLayout()
	local size = self.db.fontSize
	self.font:SetFont(STANDARD_TEXT_FONT, size, "")
	frame.Fps:SetShown(self.db.showFps)
	frame.Latency:SetShown(self.db.showLatency)

	local texts, vertical = ShownTexts(), self.db.layout == "VERTICAL"
	local columnWidth = Scaled(COLUMN_WIDTH)
	for i, text in ipairs(texts) do
		text:SetWidth(columnWidth)
		text:ClearAllPoints()
		if i == 1 then
			text:SetPoint("TOPLEFT", PADDING, -PADDING)
		elseif vertical then
			text:SetPoint("TOPLEFT", texts[i - 1], "BOTTOMLEFT", 0, -ROW_GAP)
		else
			text:SetPoint("LEFT", texts[i - 1], "RIGHT", Scaled(COLUMN_GAP), 0)
		end
	end
	local count = math.max(#texts, 1)
	local columns = vertical and 1 or count
	local rows = vertical and count or 1
	frame:SetSize(
		PADDING * 2 + columns * columnWidth + (columns - 1) * Scaled(COLUMN_GAP),
		PADDING * 2 + rows * (size + 2) + (rows - 1) * ROW_GAP
	)
	ns:SetOverlayBackgroundAlpha(frame, self.db.backgroundOpacity / 100)
end

function module:Update()
	if not frame or not self.enabled then
		return
	end
	if self.db.showFps then
		local fps = math.floor(GetFramerate() + 0.5)
		frame.Fps:SetText(L.FPS:format(fps))
		frame.Fps:SetTextColor(unpack(Color(fps, FPS_LIMITS, true)))
	end
	if self.db.showLatency then
		local latency = Latency()
		frame.Latency:SetText(L.LATENCY:format(latency))
		frame.Latency:SetTextColor(unpack(Color(latency, LATENCY_LIMITS, false)))
	end
end

function module:OnOptionChanged()
	self:ApplyLayout()
	self:Update()
end

function module:OnInitialize()
	self.font = CreateFont("QualityOfLifeForeverPerformanceWidgetFont")
	self.font:SetFont(STANDARD_TEXT_FONT, BASE_FONT_SIZE, "")
	self.font:SetShadowOffset(1, -1)
	self.font:SetShadowColor(0, 0, 0, 0.8)
end

function module:OnEnable()
	if not frame then
		CreateWidget()
	end
	self:ApplyLayout()
	frame:Show()
	ticker = C_Timer.NewTicker(REFRESH_SECONDS, function()
		self:Update()
	end)
	self:Update()
end

function module:OnDisable()
	if ticker then
		ticker:Cancel()
		ticker = nil
	end
	frame:Hide()
end
