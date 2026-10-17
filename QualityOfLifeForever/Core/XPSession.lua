-- luacheck: read globals UnitXP UnitXPMax GetTime CreateFrame
local _, ns = ...

--[[
	XP gained since login (or the last reset), used by the XPBar module.
	Costs one subtraction per PLAYER_XP_UPDATE; rates are computed on demand.
	Listeners are called after every XP gain with (owner, gain).
]]

local XPSession = {}
ns.XPSession = XPSession

-- Below this the rate is too noisy to show.
local MIN_SESSION_SECONDS = 60

-- Started at load so getters work before PLAYER_LOGIN resets it.
local sessionStart, sessionXP = GetTime(), 0
local lastXP, lastMaxXP, lastGain
local listeners = {}

-- Current and max XP, or nil while they are secret.
function XPSession.Read()
	local xp, maxXP = UnitXP("player"), UnitXPMax("player")
	if ns.Utils.IsSecret(xp) or ns.Utils.IsSecret(maxXP) then
		return nil
	end
	return xp, maxXP
end

function XPSession.Reset()
	sessionStart = GetTime()
	sessionXP = 0
	lastGain = nil
	lastXP, lastMaxXP = XPSession.Read()
end

function XPSession.GetSessionXP()
	return sessionXP
end

function XPSession.GetLastGain()
	return lastGain
end

-- XP per hour, or nil while the session is too short to tell.
function XPSession.GetPerHour()
	local elapsed = GetTime() - sessionStart
	if sessionXP <= 0 or elapsed < MIN_SESSION_SECONDS then
		return nil
	end
	return sessionXP / elapsed * 3600
end

-- Seconds to the next level at the current rate, or nil.
function XPSession.GetTimeToLevel()
	local perHour = XPSession.GetPerHour()
	local xp, maxXP = XPSession.Read()
	if not perHour or not xp then
		return nil
	end
	return (maxXP - xp) / perHour * 3600
end

function XPSession.RegisterListener(owner, callback)
	listeners[owner] = callback
end

local function OnXPUpdate()
	local xp, maxXP = XPSession.Read()
	if not xp or not lastXP then
		lastXP, lastMaxXP = xp, maxXP
		return
	end
	local gain
	if xp >= lastXP then
		gain = xp - lastXP
	else
		-- Level up: the rest of the old level plus the progress in the new one.
		gain = (lastMaxXP - lastXP) + xp
	end
	lastXP, lastMaxXP = xp, maxXP
	if gain <= 0 then
		return
	end
	sessionXP = sessionXP + gain
	lastGain = gain
	for owner, callback in pairs(listeners) do
		ns.Utils.SafeCall(callback, owner, gain)
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterUnitEvent("PLAYER_XP_UPDATE", "player")
frame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		XPSession.Reset()
	else
		OnXPUpdate()
	end
end)
