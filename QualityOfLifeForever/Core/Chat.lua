-- luacheck: read globals ChatFrameUtil ChatFrame_AddMessageEventFilter ChatFrame_RemoveMessageEventFilter Constants NUM_CHAT_WINDOWS strtrim GetChatWindowInfo GetChannelList FCF_OpenNewWindow FCFDock_GetSelectedWindow FCFDock_SelectWindow GENERAL_CHAT_DOCK
local _, ns = ...

-- Shared helpers for the chat modules.
local Chat = {}
ns.Chat = Chat

Chat.MAX_WINDOWS = Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows or NUM_CHAT_WINDOWS

local AddFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
local RemoveFilter = ChatFrameUtil and ChatFrameUtil.RemoveMessageEventFilter or ChatFrame_RemoveMessageEventFilter

-- Calls func(frame, editBox) for every existing ChatFrame1..n.
function Chat.ForEachFrame(func)
	for i = 1, Chat.MAX_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		if frame then
			func(frame, _G["ChatFrame" .. i .. "EditBox"])
		end
	end
end

function Chat.AddFilters(events, filter)
	for _, event in ipairs(events) do
		AddFilter(event, filter)
	end
end

function Chat.RemoveFilters(events, filter)
	for _, event in ipairs(events) do
		RemoveFilter(event, filter)
	end
end

-- Comma-separated words, trimmed and lower-cased; empty entries are skipped.
-- Appends to `list` (a new table without one) and returns it.
function Chat.ParseList(text, list)
	list = list or {}
	for word in text:gmatch("[^,]+") do
		word = strtrim(word):lower()
		if word ~= "" then
			list[#list + 1] = word
		end
	end
	return list
end

-- Whether text contains one of the lower-case words, case-insensitively.
function Chat.ContainsAny(text, words)
	text = text:lower()
	for _, word in ipairs(words) do
		if text:find(word, 1, true) then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- Tab filters
--------------------------------------------------------------------------------
-- Channel, say and yell messages containing one of the module's keywords are
-- shown only in the module's own chat tab (SpamFilter, GuildRecruitTab).
--
-- Chat.NewTabFilter(module, spec) installs the methods and callbacks on a
-- module created with ns:NewModule. The module needs the options `keywords`
-- (string) and `tabCreated` (boolean, default false).
--   spec.L              module locale with TAB, TAB_CREATED, TAB_EXISTS,
--                       NO_FREE_WINDOW and TAB_MISSING
--   spec.keepOtherTabs  matches are not dropped from the tabs of other enabled
--                       tab filters
-- module:CreateTabButton() is the onClick of the module's {Create} button.

local TAB_EVENTS = { "CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_YELL" }
local TAB_GROUPS = { "SAY", "YELL", "CHANNEL" }

local tabFilters = {}

local function IsOtherTab(module, chatFrame)
	for _, other in ipairs(tabFilters) do
		if other ~= module and other.enabled and chatFrame == other:GetTabFrame() then
			return true
		end
	end
	return false
end

function Chat.NewTabFilter(module, spec)
	local L = spec.L
	local keywords = {}
	-- The same message reaches the filter once per chat frame showing it.
	local lastText, lastMatch
	-- Window index of the tab found last.
	local tabIndex

	tabFilters[#tabFilters + 1] = module

	function module:ParseKeywords()
		wipe(keywords)
		Chat.ParseList(self.db.keywords, keywords)
		lastText = nil
	end

	local function IsTabWindow(index)
		local name, _, _, _, _, _, shown, _, docked = GetChatWindowInfo(index)
		return name == L.TAB and (shown or docked)
	end

	local function ResetTabIndex()
		tabIndex = nil
	end

	-- The shown chat window named like the tab, if any. The cached index is
	-- checked on every call, so a renamed or closed tab is noticed at once.
	function module:GetTabFrame()
		if not (tabIndex and IsTabWindow(tabIndex)) then
			tabIndex = nil
			for i = 1, Chat.MAX_WINDOWS do
				if IsTabWindow(i) then
					tabIndex = i
					break
				end
			end
		end
		return tabIndex and _G["ChatFrame" .. tabIndex]
	end

	function module:CreateTabFrame()
		-- FCF_OpenNewWindow selects the new tab; keep the current one selected.
		local selected = FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
		local frame = FCF_OpenNewWindow(L.TAB, true)
		if not frame then
			self:Print(L.NO_FREE_WINDOW)
			return
		end
		ResetTabIndex()
		if selected then
			FCFDock_SelectWindow(GENERAL_CHAT_DOCK, selected)
			if ChatFrameUtil and ChatFrameUtil.SetLastActiveWindow and selected.editBox then
				ChatFrameUtil.SetLastActiveWindow(selected.editBox)
			end
		end
		for _, group in ipairs(TAB_GROUPS) do
			frame:AddMessageGroup(group)
		end
		local channels = { GetChannelList() }
		for i = 2, #channels, 3 do
			frame:AddChannel(channels[i])
		end
		self:Print(L.TAB_CREATED)
		return frame
	end

	function module:CreateTabButton()
		if self:GetTabFrame() then
			self:Print(L.TAB_EXISTS)
		else
			self:CreateTabFrame()
		end
	end

	-- tabCreated is true while the module is enabled with its tab. Enabled with
	-- tabCreated set but no tab means the tab was closed since the last session
	-- (the check runs at login): turn the module off instead of recreating it.
	-- Turning it off clears the flag, so the next enable creates the tab again.
	function module:CheckTabFrame()
		if self:GetTabFrame() then
			self.db.tabCreated = true
		elseif self.db.tabCreated then
			self:Print(L.TAB_MISSING)
			ns:SetModuleEnabled(self, false)
		elseif self:CreateTabFrame() then
			self.db.tabCreated = true
		end
	end

	-- Runs once per chat frame that receives the message: matches are dropped
	-- everywhere except the tab, which in turn drops everything else. Without
	-- the tab nothing is dropped. Blizzard only calls filters when all args are
	-- accessible (no secret values).
	local function Filter(chatFrame, _, text)
		if type(text) ~= "string" then
			return false
		end
		local tabFrame = module:GetTabFrame()
		if not tabFrame then
			return false
		end
		if text ~= lastText then
			lastText, lastMatch = text, Chat.ContainsAny(text, keywords)
		end
		if chatFrame == tabFrame then
			return not lastMatch
		end
		if spec.keepOtherTabs then
			return lastMatch and not IsOtherTab(module, chatFrame)
		end
		return lastMatch
	end

	function module:OnOptionChanged(key)
		if key == "keywords" then
			self:ParseKeywords()
		end
	end

	function module:OnEnable()
		self:ParseKeywords()
		ResetTabIndex()
		-- Window order or names may have changed; the next lookup scans again.
		self:RegisterEvent("UPDATE_CHAT_WINDOWS", ResetTabIndex)
		self:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", ResetTabIndex)
		-- Delayed because chat windows are set up after PLAYER_LOGIN.
		C_Timer.After(2, function()
			if self.enabled then
				self:CheckTabFrame()
			end
		end)
		Chat.AddFilters(TAB_EVENTS, Filter)
	end

	function module:OnDisable()
		self.db.tabCreated = false
		Chat.RemoveFilters(TAB_EVENTS, Filter)
	end

	return module
end
