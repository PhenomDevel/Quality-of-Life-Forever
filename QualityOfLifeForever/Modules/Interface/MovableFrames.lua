-- luacheck: read globals UIParent CreateFrame InCombatLockdown
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Movable windows",
		NOTE = "Drag Blizzard windows by their title bar",
		DESC = "Lets you move Blizzard windows (character, merchant, mail, quests, friends, collections, …) by dragging their title bar. Protected windows are left out. The world map has its own module.",
		REMEMBER = "Remember positions",
		REMEMBER_DESC = "Windows open where you last moved them, also after a reload. Otherwise they return to their default place when closed.",
		RESET = "Positions",
		RESET_BUTTON = "Reset",
		RESET_DESC = "Forgets all saved positions. Windows use their default place the next time they open.",
	},
	deDE = {
		TITLE = "Verschiebbare Fenster",
		NOTE = "Blizzard-Fenster an der Titelleiste ziehen",
		DESC = "Blizzard-Fenster (Charakter, Händler, Post, Quests, Freunde, Sammlungen, …) lassen sich an ihrer Titelleiste verschieben. Geschützte Fenster sind ausgenommen. Die Weltkarte hat ein eigenes Modul.",
		REMEMBER = "Positionen merken",
		REMEMBER_DESC = "Fenster öffnen dort, wo du sie zuletzt hingeschoben hast, auch nach einem Neuladen. Sonst kehren sie beim Schließen an ihren Standardplatz zurück.",
		RESET = "Positionen",
		RESET_BUTTON = "Zurücksetzen",
		RESET_DESC = "Vergisst alle gespeicherten Positionen. Fenster öffnen beim nächsten Mal an ihrem Standardplatz.",
	},
})

-- Window names; load-on-demand ones are set up once their addon loads.
local FRAMES = {
	"AchievementFrame", "AddonList", "AuctionHouseFrame", "BankFrame",
	"CharacterFrame", "ClassTrainerFrame", "CollectionsJournal",
	"CommunitiesFrame", "DressUpFrame", "EncounterJournal", "FriendsFrame",
	"GossipFrame", "GuildRegistrarFrame", "InspectFrame", "ItemTextFrame",
	"MacroFrame", "MailFrame", "MerchantFrame", "PetitionFrame",
	"PlayerSpellsFrame", "ProfessionsBookFrame", "ProfessionsFrame",
	"PVEFrame", "QuestFrame", "QuestLogPopupDetailFrame", "TabardFrame",
	"TaxiFrame", "TradeFrame",
}

local module = ns:NewModule("MovableFrames", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
	defaults = {
		remember = true,
		positions = {},
	},
	options = {
		{ key = "remember", type = "checkbox", label = L.REMEMBER, tooltip = L.REMEMBER_DESC },
		{
			type = "button",
			label = L.RESET,
			buttonText = L.RESET_BUTTON,
			tooltip = L.RESET_DESC,
			onClick = function(self)
				wipe(self.db.positions)
				wipe(self.session)
			end,
		},
	},
})

-- Positions moved this session when "Remember positions" is off.
module.session = {}

-- frame -> drag handle
local handles = {}
local dragging

local function GetPositions()
	return module.db.remember and module.db.positions or module.session
end

-- Re-applies a moved window's position after Blizzard placed it. Saved in
-- UIParent coordinates of the top left corner, independent of the scale.
local function ApplyPosition(frame)
	local position = GetPositions()[frame:GetName()]
	if not position or not frame:IsShown() or frame == dragging then
		return
	end
	if InCombatLockdown() and frame:IsProtected() then
		return
	end
	local scale = frame:GetScale()
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", position.x / scale, position.y / scale)
end

local function StartDrag(frame)
	if not module.enabled or InCombatLockdown() then
		return
	end
	dragging = frame
	module.wasClamped = frame:IsClampedToScreen()
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:StartMoving()
end

local function StopDrag(frame)
	if dragging ~= frame then
		return
	end
	dragging = nil
	frame:StopMovingOrSizing()
	-- Not user placed: the client would otherwise restore the layout itself.
	frame:SetUserPlaced(false)
	frame:SetMovable(false)
	frame:SetClampedToScreen(module.wasClamped)
	local scale = frame:GetScale()
	GetPositions()[frame:GetName()] = { x = frame:GetLeft() * scale, y = frame:GetTop() * scale }
	ApplyPosition(frame)
end

-- The title bar, or the top strip of windows without one.
local function CreateHandle(frame)
	local handle = CreateFrame("Frame", nil, frame)
	local title = frame.TitleContainer
	if title then
		handle:SetAllPoints(title)
	else
		handle:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
		handle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, 0)
		handle:SetHeight(22)
	end
	-- Low frame level, so the title bar buttons (close, …) stay clickable.
	handle:SetFrameLevel(frame:GetFrameLevel() + 1)
	handle:EnableMouse(true)
	handle:RegisterForDrag("LeftButton")
	handle:SetScript("OnDragStart", function()
		StartDrag(frame)
	end)
	handle:SetScript("OnDragStop", function()
		StopDrag(frame)
	end)
	handles[frame] = handle
end

function module:SetupFrames()
	for _, name in ipairs(FRAMES) do
		local frame = _G[name]
		if frame and not handles[frame] and type(frame.GetObjectType) == "function" and not frame:IsProtected() then
			CreateHandle(frame)
			self:HookScript(frame, "OnShow", function()
				ApplyPosition(frame)
			end)
			self:HookScript(frame, "OnHide", function()
				StopDrag(frame)
				if not self.db.remember then
					self.session[frame:GetName()] = nil
				end
			end)
		end
		if frame and handles[frame] then
			handles[frame]:Show()
		end
	end
end

function module:ApplyAll()
	for frame in pairs(handles) do
		ApplyPosition(frame)
	end
end

function module:ADDON_LOADED()
	self:SetupFrames()
end

function module:OnEnable()
	self:RegisterEvent("ADDON_LOADED")
	-- The panel manager re-places open windows whenever another one opens.
	self:SecureHook("UpdateUIPanelPositions", self.ApplyAll)
	self:SetupFrames()
	self:ApplyAll()
end

function module:OnDisable()
	if dragging then
		StopDrag(dragging)
	end
	for _, handle in pairs(handles) do
		handle:Hide()
	end
end
