-- luacheck: read globals UISpecialFrames tinsert PlaySound SOUNDKIT C_Timer OKAY
local _, ns = ...

local L = ns.L
local Widgets = ns.OptionsWidgets
local colors, fonts = Widgets.colors, Widgets.fonts

--[[
	"What's new" window, shown once after an update to a new minor or major
	version (patch and test releases don't count). Notes come from
	ns.whatsNew (Locales/WhatsNew.lua); every version newer than the last
	one seen is listed. Fresh installs and dev builds show nothing.
]]

local WIDTH, MAX_HEIGHT = 480, 460
local PADDING = 16
local HEADER_HEIGHT = 48
local FOOTER_HEIGHT = 46
local LOGIN_DELAY = 5
local SCROLL_STEP = 40

local frame, scroll, content
local lines = {}

-- "v1.2.3" / "1.2.3-beta1" -> 1, 2, isPrerelease
local function ParseVersion(version)
	local major, minor = tostring(version or ""):match("^v?(%d+)%.(%d+)")
	if not major then
		return nil
	end
	return tonumber(major), tonumber(minor), version:find("-", 1, true) ~= nil
end

local function IsNewer(major, minor, otherMajor, otherMinor)
	return major > otherMajor or (major == otherMajor and minor > otherMinor)
end

-- Entries newer than major/minor of `since` (nil: only the newest), up to the
-- running version.
local function CollectEntries(since)
	local currentMajor, currentMinor = ParseVersion(ns.version)
	local sinceMajor, sinceMinor = ParseVersion(since)
	local entries = {}
	for _, entry in ipairs(ns.whatsNew) do
		local major, minor = ParseVersion(entry.version)
		local released = not currentMajor or not IsNewer(major, minor, currentMajor, currentMinor)
		if released and (not sinceMajor or IsNewer(major, minor, sinceMajor, sinceMinor)) then
			entries[#entries + 1] = entry
			if not sinceMajor then
				break
			end
		end
	end
	return entries
end

local function AcquireLine(index)
	local line = lines[index]
	if not line then
		line = Widgets.Text(content, fonts.body)
		line:SetWordWrap(true)
		lines[index] = line
	end
	line:Show()
	return line
end

local function Render(entries)
	local locale = GetLocale()
	local width = WIDTH - 2 * PADDING
	local y, count = 0, 0
	local function Add(font, text, gap, indent)
		count = count + 1
		local line = AcquireLine(count)
		line:SetFontObject(font)
		line:SetWidth(width - (indent or 0))
		line:SetText(text)
		y = y + gap
		line:SetPoint("TOPLEFT", indent or 0, -y)
		y = y + line:GetStringHeight()
	end
	for i, entry in ipairs(entries) do
		Add(fonts.title, L.WHATS_NEW_VERSION:format(entry.version), i == 1 and 0 or 18)
		for _, text in ipairs(entry[locale] or entry.enUS) do
			local heading = text:match("^# (.+)")
			if heading then
				Add(fonts.heading, ("|cff%s%s|r"):format(ns.color, heading), 12)
			else
				Add(fonts.body, "•  " .. text, 5, 4)
			end
		end
	end
	for i = count + 1, #lines do
		lines[i]:Hide()
	end
	content:SetSize(width, y)
	local height = math.min(MAX_HEIGHT, HEADER_HEIGHT + y + PADDING + FOOTER_HEIGHT)
	frame:SetHeight(height)
	scroll:SetVerticalScroll(0)
end

local function CreateWindow()
	frame = CreateFrame("Frame", "QualityOfLifeForeverWhatsNewFrame", UIParent)
	frame:SetWidth(WIDTH)
	frame:SetPoint("CENTER", 0, 60)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	Widgets.Fill(frame, colors.window)
	Widgets.Border(frame)
	tinsert(UISpecialFrames, frame:GetName())

	local logo = frame:CreateTexture(nil, "ARTWORK")
	logo:SetSize(24, 24)
	logo:SetPoint("TOPLEFT", PADDING, -12)
	logo:SetTexture("Interface\\AddOns\\QualityOfLifeForever\\Media\\Logo")

	local title = Widgets.Text(frame, fonts.heading)
	title:SetPoint("LEFT", logo, "RIGHT", 10, 0)
	title:SetText(("Quality of Life |cff%sForever|r  %s"):format(ns.color, L.WHATS_NEW_TITLE))

	local edge = frame:CreateTexture(nil, "BORDER")
	edge:SetColorTexture(unpack(colors.border))
	edge:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
	edge:SetPoint("TOPRIGHT", 0, -HEADER_HEIGHT)
	edge:SetHeight(1)

	scroll = CreateFrame("ScrollFrame", nil, frame)
	scroll:SetPoint("TOPLEFT", PADDING, -(HEADER_HEIGHT + PADDING))
	scroll:SetPoint("BOTTOMRIGHT", -PADDING, FOOTER_HEIGHT)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local offset = self:GetVerticalScroll() - delta * SCROLL_STEP
		self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), offset)))
	end)
	content = CreateFrame("Frame", nil, scroll)
	scroll:SetScrollChild(content)

	local hint = Widgets.Text(frame, fonts.dim)
	hint:SetPoint("BOTTOMLEFT", PADDING, 18)
	hint:SetPoint("RIGHT", -120, 0)
	hint:SetText(L.WHATS_NEW_HINT)

	local close = Widgets.CreateButton(frame)
	close:SetLabel(OKAY)
	close:SetPoint("BOTTOMRIGHT", -PADDING, 12)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	frame:SetScript("OnShow", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
	end)
	frame:SetScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
	end)
end

-- Shows the notes since `since` (a version string), or the newest notes.
-- Returns false if there is nothing to show.
function ns:ShowWhatsNew(since)
	local entries = CollectEntries(since)
	if #entries == 0 then
		return false
	end
	if not frame then
		CreateWindow()
	end
	Render(entries)
	frame:Show()
	return true
end

local pendingSince

local function OnRegenEnabled(event)
	ns:UnregisterEvent(event, OnRegenEnabled)
	ns:ShowWhatsNew(pendingSince)
end

local function ShowOutOfCombat(since)
	if InCombatLockdown() then
		pendingSince = since
		ns:RegisterEvent("PLAYER_REGEN_ENABLED", OnRegenEnabled)
	else
		ns:ShowWhatsNew(since)
	end
end

function ns:InitializeWhatsNew()
	local global = ns.db.global
	local major, minor, prerelease = ParseVersion(ns.version)
	if not major or prerelease then
		return
	end
	local last = global.lastVersion
	global.lastVersion = ns.version
	if not global.whatsNew then
		return
	end
	-- Installs from before this setting existed have no lastVersion; they get
	-- the newest notes. Fresh installs have nothing to catch up on.
	if not last and ns.isNewInstall then
		return
	end
	local lastMajor, lastMinor = ParseVersion(last)
	if lastMajor and not IsNewer(major, minor, lastMajor, lastMinor) then
		return
	end
	C_Timer.After(LOGIN_DELAY, function()
		ShowOutOfCombat(last)
	end)
end
