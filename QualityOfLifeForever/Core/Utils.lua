-- luacheck: read globals GameRulesUtil GetMaxPlayerLevel UnitLevel
local _, ns = ...

local Utils = {}
ns.Utils = Utils

--------------------------------------------------------------------------------
-- Text markup
--------------------------------------------------------------------------------

-- Inline markup for texts shown to the user (descriptions, notices, tooltips,
-- notes, chat output), so references stand out from the prose:
--   `name`   game setting (CVar) or other technical name
--   {Label}  an option of this addon or of the game
local SETTING_COLOR = "|cff8fe3a8"
local OPTION_COLOR = "|cff8cc4ff"

function Utils.Markup(text)
	if type(text) ~= "string" then
		return text
	end
	text = text:gsub("`([^`]+)`", SETTING_COLOR .. "%1|r")
	return (text:gsub("{([^{}]+)}", OPTION_COLOR .. "%1|r"))
end

--------------------------------------------------------------------------------
-- Output
--------------------------------------------------------------------------------

local function Output(prefix, ...)
	local parts = { ... }
	for i = 1, select("#", ...) do
		parts[i] = Utils.Markup(tostring(parts[i]))
	end
	DEFAULT_CHAT_FRAME:AddMessage(prefix .. " " .. table.concat(parts, " "))
end

-- Always printed, used for direct responses to user actions (slash commands).
function ns:Print(...)
	Output(("|cff%s%s|r:"):format(ns.color, ns.shortTitle), ...)
end

-- Printed only when the user has chat feedback enabled (default: on).
function ns:Notify(...)
	if ns.db and not ns.db.global.printMessages then
		return
	end
	ns:Print(...)
end

function ns:Debug(...)
	if ns.db and ns.db.global.debug then
		Output(("|cff%s%s|r |cff999999[debug]|r:"):format(ns.color, ns.shortTitle), ...)
	end
end

--------------------------------------------------------------------------------
-- Locales
--------------------------------------------------------------------------------

-- Module-local strings: { enUS = {...}, deDE = {...} }. Lookup order:
-- client locale -> enUS -> key (missing strings stay visible in-game).
function ns.NewLocale(strings)
	local fallback = assert(strings.enUS, "NewLocale: enUS strings are required")
	local current = strings[GetLocale()] or fallback
	return setmetatable({}, {
		__index = function(_, key)
			local value = current[key]
			if value == nil then
				value = fallback[key]
			end
			if value == nil then
				return key
			end
			return value
		end,
	})
end

--------------------------------------------------------------------------------
-- Error handling
--------------------------------------------------------------------------------

-- Calls `func` and routes errors to the default error handler instead of
-- aborting the caller. One broken module must never break the others.
function Utils.SafeCall(func, ...)
	local args = { ... }
	local count = select("#", ...)
	return xpcall(function()
		return func(unpack(args, 1, count))
	end, geterrorhandler())
end

--------------------------------------------------------------------------------
-- Tables
--------------------------------------------------------------------------------

function Utils.CopyTable(source)
	local copy = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			copy[key] = Utils.CopyTable(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Adds every key from `defaults` that is missing in `target` (recursively).
-- Existing values are never overwritten.
function Utils.ApplyDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then
				target[key] = {}
			end
			Utils.ApplyDefaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end
	return target
end

--------------------------------------------------------------------------------
-- Formatting
--------------------------------------------------------------------------------

function Utils.FormatMoney(copper)
	if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
		return C_CurrencyInfo.GetCoinTextureString(copper)
	elseif GetCoinTextureString then
		return GetCoinTextureString(copper)
	end
	return tostring(copper)
end

--------------------------------------------------------------------------------
-- Secret values
--------------------------------------------------------------------------------

-- Forever ships with the Midnight addon restrictions: some combat related
-- values (e.g. unit health) are "secret" and may be displayed but not read,
-- compared or used in arithmetic. Check before doing logic with such values.
function Utils.IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value) or false
end

--------------------------------------------------------------------------------
-- Player
--------------------------------------------------------------------------------

-- The max level check lives in GameRulesUtil in Forever, not in a global
-- IsPlayerAtEffectiveMaxLevel().
function Utils.IsAtMaxLevel()
	if GameRulesUtil and GameRulesUtil.IsPlayerAtEffectiveMaxLevel then
		return GameRulesUtil.IsPlayerAtEffectiveMaxLevel()
	end
	return GetMaxPlayerLevel ~= nil and UnitLevel("player") >= GetMaxPlayerLevel()
end
