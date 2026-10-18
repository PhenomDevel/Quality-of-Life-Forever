-- luacheck: read globals UnitXP UnitXPMax UnitGUID UnitLevel GetTime CreateFrame SecondsToTime time
local _, ns = ...

--[[
	XP gained in the current session, used by the XPBar and XPWidget modules.
	Costs one subtraction per PLAYER_XP_UPDATE; rates are computed on demand.
	Listeners are called after every XP gain with (owner, gain).

	The session is saved per character on logout. When a new one starts
	depends on the XP widget's reset mode (see Utils.IsSessionExpired); the
	rate counts online time only.
]]

local XPSession = {}
ns.XPSession = XPSession

-- Below this the rate is too noisy to show.
local MIN_SESSION_SECONDS = 60

-- Started at load so getters work before PLAYER_LOGIN resets it.
-- elapsed: online seconds before `mark` (GetTime() of this login).
local elapsed, mark, sessionXP, nextReset = 0, GetTime(), 0, nil
local lastXP, lastMaxXP, lastGain

local function ResetMode()
	local widget = ns.modules.XPWidget
	return widget and widget.db and widget.db.sessionReset or "LOGIN"
end

local function Elapsed()
	return elapsed + GetTime() - mark
end
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
	elapsed, mark = 0, GetTime()
	nextReset = ns.Utils.NextDailyReset()
	sessionXP = 0
	lastGain = nil
	lastXP, lastMaxXP = XPSession.Read()
end

-- A daily session ends at the reset even while logged in.
local function CheckDailyReset()
	if ResetMode() == "DAILY" and nextReset and time() >= nextReset then
		XPSession.Reset()
	end
end

function XPSession.GetSessionXP()
	CheckDailyReset()
	return sessionXP
end

function XPSession.GetLastGain()
	return lastGain
end

-- XP per hour, or nil while the session is too short to tell.
function XPSession.GetPerHour()
	CheckDailyReset()
	local seconds = Elapsed()
	if sessionXP <= 0 or seconds < MIN_SESSION_SECONDS then
		return nil
	end
	return sessionXP / seconds * 3600
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

-- Time to level as text. SecondsToTime without seconds returns "" below one
-- minute, so that case gets its own text.
function XPSession.FormatTimeToLevel()
	local seconds = XPSession.GetTimeToLevel()
	if not seconds then
		return nil
	end
	if seconds < 60 then
		return ns.L.XP_UNDER_A_MINUTE
	end
	return SecondsToTime(seconds, true)
end

function XPSession.RegisterListener(owner, callback)
	listeners[owner] = callback
end

-- While XP is secret (e.g. in combat) the last readable values are kept, so
-- the next readable update still counts everything gained in between.
local function OnXPUpdate()
	local xp, maxXP = XPSession.Read()
	if not xp then
		return
	end
	if not lastXP then
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

-- Level times ------------------------------------------------------------------
-- Played time per level, counted while logged in. A level only counts once
-- it was tracked from its start; /played (TIME_PLAYED_MSG) sets the exact
-- time of the current level and so completes it.
--
--	ns.db.global.levelTimes[guid] = {
--		current = { level, seconds, complete },
--		history = { { level, seconds }, ... }, -- newest first
--	}

local MAX_LEVEL_TIMES = 10
local levelRecord, levelMark

local function AccumulateLevelTime()
	if levelRecord then
		local now = GetTime()
		levelRecord.current.seconds = levelRecord.current.seconds + now - levelMark
		levelMark = now
	end
end

local function LoadLevelRecord()
	local store = ns.db.global.levelTimes or {}
	ns.db.global.levelTimes = store
	local guid = UnitGUID("player")
	levelRecord = store[guid] or { history = {} }
	store[guid] = levelRecord
	local level = UnitLevel("player")
	if not levelRecord.current or levelRecord.current.level ~= level then
		levelRecord.current = { level = level, seconds = 0, complete = false }
	end
	levelMark = GetTime()
end

local function OnLevelUp(level)
	if not levelRecord then
		return
	end
	AccumulateLevelTime()
	local current = levelRecord.current
	if current.complete and current.level == level - 1 then
		table.insert(levelRecord.history, 1, { level = current.level, seconds = current.seconds })
		for i = #levelRecord.history, MAX_LEVEL_TIMES + 1, -1 do
			levelRecord.history[i] = nil
		end
	end
	levelRecord.current = { level = level, seconds = 0, complete = true }
end

local function OnTimePlayed(levelSeconds)
	if levelRecord and type(levelSeconds) == "number" and not ns.Utils.IsSecret(levelSeconds) then
		levelRecord.current.seconds = levelSeconds
		levelRecord.current.complete = true
		levelMark = GetTime()
	end
end

-- Up to `count` finished levels, newest first: { { level, seconds }, ... }.
function XPSession.GetLevelTimes(count)
	local result = {}
	if levelRecord then
		for i = 1, math.min(count, #levelRecord.history) do
			result[i] = levelRecord.history[i]
		end
	end
	return result
end

local function Save()
	AccumulateLevelTime()
	ns.db.global.xpSessions = ns.db.global.xpSessions or {}
	ns.db.global.xpSessions[UnitGUID("player")] = {
		savedAt = GetTime(),
		elapsed = Elapsed(),
		xp = sessionXP,
		lastGain = lastGain,
		nextReset = nextReset,
	}
end

local function Resume()
	ns.db.global.xpSession = nil -- layout before the reset modes
	local saved = ns.db.global.xpSessions and ns.db.global.xpSessions[UnitGUID("player")]
	XPSession.Reset()
	if saved and saved.xp and not ns.Utils.IsSessionExpired(saved, ResetMode()) then
		elapsed, sessionXP, lastGain, nextReset = saved.elapsed or 0, saved.xp, saved.lastGain, saved.nextReset
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
-- Picks up gains made while XP was secret.
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterUnitEvent("PLAYER_XP_UPDATE", "player")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("TIME_PLAYED_MSG")
frame:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		Resume()
		LoadLevelRecord()
	elseif event == "PLAYER_LOGOUT" then
		Save()
	elseif event == "PLAYER_LEVEL_UP" then
		OnLevelUp(...)
	elseif event == "TIME_PLAYED_MSG" then
		OnTimePlayed(select(2, ...))
	else
		OnXPUpdate()
	end
end)
