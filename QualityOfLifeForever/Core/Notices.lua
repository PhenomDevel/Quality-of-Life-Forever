-- luacheck: read globals GameFontNormal GameFontHighlightSmall InCombatLockdown
local _, ns = ...

local L = ns.L

--[[
	Notices: small popups for hints and reminders (e.g. new trainer skills,
	unspent talent points). They only appear out of combat; notices raised in
	combat, or still shown when combat starts, wait until it ends. Placed off
	screen center by default and movable in Edit Mode. With the global
	`notices` setting off they go to the chat instead.

		ns:ShowNotice({
			key   = optional id; a newer notice with the same key replaces it
			title = string
			text  = string (markup like ns:Print)
			icon  = optional texture path or file ID
		})

	While the options window is open, every enabled module with a
	PreviewNotice() method (returning text, icon) shows a preview that stays
	until the window closes.
]]

local WIDTH = 300
local PADDING = 8
local ICON_SIZE = 32
local GAP = 6
local MAX_SHOWN = 3
local DURATION = 20

local anchor
local shown = {} -- toast frames in stacking order
local queue = {} -- notices waiting for combat to end or a free slot
local pool = {}

local function Matches(notice, key)
	return key ~= nil and notice.key == key
end

-- Notices stack away from the screen edge the anchor is closer to.
local function GrowsUp()
	local _, y = anchor:GetCenter()
	return y and y * anchor:GetEffectiveScale() < UIParent:GetHeight() * UIParent:GetEffectiveScale() / 2
end

local function Relayout()
	local up = GrowsUp()
	for i, toast in ipairs(shown) do
		toast:ClearAllPoints()
		local previous = shown[i - 1]
		if up then
			toast:SetPoint("BOTTOM", previous or anchor, previous and "TOP" or "BOTTOM", 0, previous and GAP or 0)
		else
			toast:SetPoint("TOP", previous or anchor, previous and "BOTTOM" or "TOP", 0, previous and -GAP or 0)
		end
	end
end

local ShowNext

local function Dismiss(toast)
	for i, other in ipairs(shown) do
		if other == toast then
			table.remove(shown, i)
			break
		end
	end
	toast:Hide()
	toast.notice = nil
	pool[#pool + 1] = toast
	Relayout()
	ShowNext()
end

local function OnUpdate(toast, elapsed)
	if toast:IsMouseOver() then
		return
	end
	toast.remaining = toast.remaining - elapsed
	if toast.remaining <= 0 then
		Dismiss(toast)
	end
end

local function CreateToast()
	local toast = CreateFrame("Button", nil, UIParent)
	toast:SetWidth(WIDTH)
	toast:SetFrameStrata("HIGH")
	toast:SetClampedToScreen(true)
	toast:RegisterForClicks("AnyUp")
	ns:AddPanelBackground(toast)

	toast.Icon = toast:CreateTexture(nil, "ARTWORK")
	toast.Icon:SetSize(ICON_SIZE, ICON_SIZE)
	toast.Icon:SetPoint("TOPLEFT", PADDING, -PADDING)
	toast.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	toast.Title = toast:CreateFontString(nil, "OVERLAY")
	toast.Title:SetFontObject(GameFontNormal)
	toast.Title:SetJustifyH("LEFT")
	toast.Title:SetWordWrap(false)

	toast.Text = toast:CreateFontString(nil, "OVERLAY")
	toast.Text:SetFontObject(GameFontHighlightSmall)
	toast.Text:SetJustifyH("LEFT")
	toast.Text:SetSpacing(2)

	toast:SetScript("OnClick", Dismiss)
	toast:SetScript("OnUpdate", OnUpdate)
	toast:Hide()
	return toast
end

local function Fill(toast, notice)
	toast.notice = notice
	toast.remaining = notice.preview and math.huge or DURATION
	local left = PADDING
	if notice.icon then
		toast.Icon:SetTexture(notice.icon)
		toast.Icon:Show()
		left = PADDING + ICON_SIZE + PADDING
	else
		toast.Icon:Hide()
	end
	local textWidth = WIDTH - left - PADDING
	toast.Title:ClearAllPoints()
	toast.Title:SetPoint("TOPLEFT", left, -PADDING)
	toast.Title:SetWidth(textWidth)
	toast.Title:SetText(notice.title or "")
	toast.Text:ClearAllPoints()
	toast.Text:SetPoint("TOPLEFT", toast.Title, "BOTTOMLEFT", 0, -3)
	toast.Text:SetWidth(textWidth)
	toast.Text:SetText(ns.Utils.Markup(notice.text))
	local textHeight = toast.Title:GetStringHeight() + 3 + toast.Text:GetStringHeight()
	toast:SetHeight(PADDING * 2 + math.max(notice.icon and ICON_SIZE or 0, textHeight))
end

function ShowNext()
	if InCombatLockdown() then
		return
	end
	-- Previews may exceed the limit; they all belong on screen together.
	while #queue > 0 and (#shown < MAX_SHOWN or queue[1].preview) do
		local toast = table.remove(pool) or CreateToast()
		Fill(toast, table.remove(queue, 1))
		shown[#shown + 1] = toast
		toast:Show()
	end
	Relayout()
end

-- Combat started: shown notices go back to the front of the queue.
local function HideAll()
	for i = #shown, 1, -1 do
		local toast = shown[i]
		table.insert(queue, 1, toast.notice)
		toast:Hide()
		toast.notice = nil
		pool[#pool + 1] = toast
		shown[i] = nil
	end
end

function ns:ShowNotice(notice)
	if not ns.db.global.notices then
		ns:Notify(notice.title and ("%s: %s"):format(notice.title, notice.text) or notice.text)
		return
	end
	for i = #queue, 1, -1 do
		if Matches(queue[i], notice.key) then
			table.remove(queue, i)
		end
	end
	for _, toast in ipairs(shown) do
		if Matches(toast.notice, notice.key) then
			Fill(toast, notice)
			Relayout()
			return
		end
	end
	queue[#queue + 1] = notice
	ShowNext()
end

local function RemovePreviews()
	for i = #queue, 1, -1 do
		if queue[i].preview then
			table.remove(queue, i)
		end
	end
	for i = #shown, 1, -1 do
		if shown[i].notice.preview then
			Dismiss(shown[i])
		end
	end
end

-- Shows or removes the module previews. optionsShown: the options window
-- opened or closed; nil to rebuild them after a module was turned on or off.
local previewsShown = false
function ns:UpdateNoticePreviews(optionsShown)
	if optionsShown ~= nil then
		previewsShown = optionsShown
	end
	RemovePreviews()
	if not previewsShown or not ns.db.global.notices then
		return
	end
	for _, module in ipairs(ns:GetSortedModules("REMINDERS")) do
		if module.enabled and module.PreviewNotice then
			local ok, text, icon = ns.Utils.SafeCall(module.PreviewNotice, module)
			if ok and text then
				ns:ShowNotice({ key = "preview:" .. module.name, title = module.title, text = text, icon = icon, preview = true })
			end
		end
	end
end

-- Called once on login, after the database is loaded.
function ns:InitializeNotices()
	-- Invisible and click-through; only Edit Mode's selection shows it.
	anchor = ns:CreateOverlay("Notices", {
		title = L.NOTICES_EDIT_MODE_NAME,
		noTitle = true,
		width = WIDTH,
		height = 48,
		default = { point = "BOTTOMRIGHT", x = -20, y = 220 },
	})
	ns:SetOverlayBackgroundAlpha(anchor, 0)
	anchor:EnableMouse(false)
	anchor:Show()

	local events = CreateFrame("Frame")
	events:RegisterEvent("PLAYER_REGEN_DISABLED")
	events:RegisterEvent("PLAYER_REGEN_ENABLED")
	events:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_REGEN_DISABLED" then
			HideAll()
		else
			ShowNext()
		end
	end)
end

function ns:ShowTestNotice()
	ns:ShowNotice({
		key = "test",
		title = L.NOTICES_TEST_TITLE,
		text = L.NOTICES_TEST_TEXT,
		icon = 134400,
	})
end
