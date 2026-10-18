local addonName, ns = ...

-- Shared private namespace. Every file receives the same `ns` table via `...`.
ns.name = addonName
ns.title = "Quality of Life Forever"
ns.shortTitle = "QoL Forever"
-- Accent color (chat prefix, options window, minimap button, overlays).
ns.color = "3a8ee6"

local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local version = getMetadata and getMetadata(addonName, "Version")
if not version or version:find("@project%-version@") then
	version = ns.L.UNKNOWN_VERSION
end
ns.version = version

-- Public handle, mainly for debugging with /dump QualityOfLifeForever.
_G.QualityOfLifeForever = ns

--------------------------------------------------------------------------------
-- Core event dispatcher
--------------------------------------------------------------------------------
-- Core events are dispatched to plain callbacks. Modules have their own,
-- independent event frames (see ModuleManager.lua) so that disabling a module
-- can simply unregister everything it listens to.

local eventFrame = CreateFrame("Frame")
local callbacks = {}

eventFrame:SetScript("OnEvent", function(_, event, ...)
	local list = callbacks[event]
	if not list then
		return
	end
	-- Iterate over a snapshot so callbacks may unregister themselves.
	local snapshot = { unpack(list) }
	for i = 1, #snapshot do
		snapshot[i](event, ...)
	end
end)

function ns:RegisterEvent(event, callback)
	local list = callbacks[event]
	if not list then
		list = {}
		callbacks[event] = list
		eventFrame:RegisterEvent(event)
	end
	list[#list + 1] = callback
end

function ns:UnregisterEvent(event, callback)
	local list = callbacks[event]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		if list[i] == callback then
			table.remove(list, i)
		end
	end
	if #list == 0 then
		callbacks[event] = nil
		eventFrame:UnregisterEvent(event)
	end
end
