-- luacheck: read globals MainStatusTrackingBarContainer SecondaryStatusTrackingBarContainer
local _, ns = ...

-- Hiding the standard status tracking bars (XP, reputation) for the widgets
-- that replace them. A bar is made invisible through the alpha of its
-- container (bar, frame art and dividers together) instead of Hide(): its
-- shown state feeds the action bar layout, which addon code must not change.
-- Blizzard fades the container in when it switches bars, so the alpha is
-- re-applied after that (see StatusBars.Hook).

local StatusBars = {}
ns.StatusBars = StatusBars

local CONTAINERS = { "MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer" }
local hiddenBars = {} -- [barIndex] = true
local hiddenContainers = {}

function StatusBars.Apply()
	for _, name in ipairs(CONTAINERS) do
		local container = _G[name]
		if container then
			local bar = container.GetShownBar and container:GetShownBar()
			if bar and hiddenBars[bar.barIndex] then
				hiddenContainers[container] = true
				container:SetAlpha(0)
				bar:EnableMouse(false)
			elseif hiddenContainers[container] then
				hiddenContainers[container] = nil
				container:SetAlpha(1)
				for _, containerBar in pairs(container.bars or {}) do
					containerBar:EnableMouse(true)
				end
			end
		end
	end
end

-- barIndex is a StatusTrackingBarInfo.BarsEnum value.
function StatusBars.SetHidden(barIndex, hide)
	hiddenBars[barIndex] = hide or nil
	StatusBars.Apply()
end

-- Re-applies the alpha when Blizzard switches or fades in a bar; the hooks
-- belong to the module so they stop while it is disabled.
function StatusBars.Hook(module)
	for _, name in ipairs(CONTAINERS) do
		local container = _G[name]
		if container then
			module:SecureHook(container, "ApplyPendingBarToShow", StatusBars.Apply)
			if container.FadeInAnimation then
				module:HookScript(container.FadeInAnimation, "OnFinished", StatusBars.Apply)
			end
		end
	end
end
