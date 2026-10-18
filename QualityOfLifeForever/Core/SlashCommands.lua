local _, ns = ...

local L = ns.L

local commands = {}

local function PrintHelp()
	ns:Print(L.SLASH_HELP_HEADER)
	ns:Print(L.SLASH_HELP_CONFIG)
	ns:Print(L.SLASH_HELP_LIST)
	ns:Print(L.SLASH_HELP_ENABLE)
	ns:Print(L.SLASH_HELP_DISABLE)
	ns:Print(L.SLASH_HELP_TOGGLE)
	ns:Print(L.SLASH_HELP_MINIMAP)
	ns:Print(L.SLASH_HELP_DEBUG)
	ns:Print(L.SLASH_HELP_RESET)
	ns:Print(L.SLASH_HELP_CVARINFO)
end

local function ChangeModule(argument, getNewState)
	local module = ns:FindModule(argument)
	if not module then
		ns:Print(L.MODULE_NOT_FOUND:format(tostring(argument)))
		return
	end
	local enabled = getNewState(module)
	ns:SetModuleEnabled(module, enabled)
	ns:Print((enabled and L.MODULE_ENABLED or L.MODULE_DISABLED):format(module.title))
end

commands.help = PrintHelp

commands.config = function()
	ns:ToggleSettings()
end

commands.list = function()
	ns:Print(L.MODULE_LIST_HEADER)
	for _, module in ipairs(ns:GetSortedModules()) do
		local state = module.db.enabled and L.MODULE_STATE_ON or L.MODULE_STATE_OFF
		ns:Print(("  %s (|cff999999%s|r): %s"):format(module.title, module.name, state))
	end
end

commands.enable = function(argument)
	ChangeModule(argument, function()
		return true
	end)
end

commands.disable = function(argument)
	ChangeModule(argument, function()
		return false
	end)
end

commands.toggle = function(argument)
	ChangeModule(argument, function(module)
		return not module.db.enabled
	end)
end

commands.minimap = function()
	local shown = not ns.db.global.minimapButton
	ns.db.global.minimapButton = shown
	ns:UpdateMinimapButton()
	ns:RefreshOptionValues()
	ns:Print(shown and L.MINIMAP_SHOWN or L.MINIMAP_HIDDEN)
end

commands.debug = function()
	local enabled = not ns.db.global.debug
	ns.db.global.debug = enabled
	ns:RefreshOptionValues()
	ns:Print(enabled and L.DEBUG_ON or L.DEBUG_OFF)
end

-- Developer helper: engine help text, default and effective range of CVars.
-- The engine silently rejects out-of-range values (the CVar keeps its value),
-- so each bound is found by binary search over integers: the largest/smallest
-- value that GetCVar reports back after SetCVar. "none" = +/-1e6 accepted.
-- The original value is restored afterwards. Results are also stored in
-- QualityOfLifeForeverDB.global.cvarInfo for copying.
local PROBE_LIMIT = 1000000

local function FindConsoleHelp(name)
	local lower = name:lower()
	for _, info in ipairs(ConsoleGetAllCommands()) do
		if info.command:lower() == lower then
			return info.help
		end
	end
	return nil
end

local function Accepts(name, value)
	C_CVar.SetCVar(name, tostring(value))
	return tonumber(C_CVar.GetCVar(name)) == value
end

-- `inside` is an accepted value, `outside` a rejected one; narrows to the last
-- accepted integer between them.
local function SearchBound(name, inside, outside)
	while math.abs(outside - inside) > 1 do
		local middle = math.floor((inside + outside) / 2)
		if Accepts(name, middle) then
			inside = middle
		else
			outside = middle
		end
	end
	return inside
end

local function ProbeLimits(name, original)
	local start = math.floor(tonumber(original))
	local min, max = "none", "none"
	if not Accepts(name, -PROBE_LIMIT) then
		min = Accepts(name, start) and SearchBound(name, start, -PROBE_LIMIT) or "?"
	end
	if not Accepts(name, PROBE_LIMIT) then
		max = Accepts(name, start) and SearchBound(name, start, PROBE_LIMIT) or "?"
	end
	C_CVar.SetCVar(name, original)
	return min, max
end

local function InspectCVar(name)
	local value, default, _, _, isLocked, isSecure, isReadOnly = C_CVar.GetCVarInfo(name)
	if value == nil then
		return { name = name, missing = true }
	end
	local info = { name = name, value = value, default = default, help = FindConsoleHelp(name) }
	if tonumber(value) and not (isLocked or isSecure or isReadOnly) and not InCombatLockdown() then
		info.min, info.max = ProbeLimits(name, value)
	end
	return info
end

commands.cvarinfo = function(argument)
	if not argument then
		ns:Print(L.SLASH_HELP_CVARINFO)
		return
	end
	local build, buildNumber = GetBuildInfo()
	local results = { build = ("%s.%s"):format(build, buildNumber) }
	for name in argument:gmatch("%S+") do
		local info = InspectCVar(name)
		results[#results + 1] = info
		if info.missing then
			ns:Print(L.CVARINFO_MISSING:format(name))
		else
			ns:Print(L.CVARINFO_LINE:format(name, info.value, info.default,
				tostring(info.min or "-"), tostring(info.max or "-"), info.help or ""))
		end
	end
	ns.db.global.cvarInfo = results
	ns:Print(L.CVARINFO_SAVED)
end

function ns:ConfirmReset()
	StaticPopupDialogs.QOLFOREVER_RESET = StaticPopupDialogs.QOLFOREVER_RESET or {
		text = L.RESET_CONFIRM,
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			ns:ResetDatabase()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		showAlert = true,
	}
	StaticPopup_Show("QOLFOREVER_RESET")
end

commands.reset = function()
	ns:ConfirmReset()
end

function ns:HandleSlashCommand(input)
	local command, argument = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
	command = command:lower()
	if command == "" then
		command = "config"
	end
	local handler = commands[command]
	if handler then
		handler(argument ~= "" and argument or nil)
	else
		PrintHelp()
	end
end

SLASH_QOLFOREVER1 = "/qol"
SLASH_QOLFOREVER2 = "/qolforever"
SlashCmdList.QOLFOREVER = function(input)
	ns:HandleSlashCommand(input)
end
