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
	ns:OpenSettings()
end

commands.list = function()
	ns:Print(L.MODULE_LIST_HEADER)
	for _, module in ns:IterateModules() do
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

commands.debug = function()
	local enabled = not ns.db.global.debug
	if ns.debugSetting then
		ns.debugSetting:SetValue(enabled)
	else
		ns.db.global.debug = enabled
	end
	ns:Print(enabled and L.DEBUG_ON or L.DEBUG_OFF)
end

-- Developer helper: engine help text, default and effective range of CVars.
-- The range is measured by writing extreme values and reading back what the
-- engine keeps; the original value is restored right after. Results are also
-- stored in QualityOfLifeForeverDB.global.cvarInfo for copying.
local PROBE_LOW, PROBE_HIGH = "-1000000", "1000000"

local function FindConsoleHelp(name)
	local lower = name:lower()
	for _, info in ipairs(ConsoleGetAllCommands()) do
		if info.command:lower() == lower then
			return info.help
		end
	end
	return nil
end

local function ProbeLimit(name, probe, original)
	if not C_CVar.SetCVar(name, probe) then
		return "rejected"
	end
	local value = C_CVar.GetCVar(name)
	C_CVar.SetCVar(name, original)
	return value == probe and "none" or value
end

local function InspectCVar(name)
	local value, default, _, _, isLocked, isSecure, isReadOnly = C_CVar.GetCVarInfo(name)
	if value == nil then
		return { name = name, missing = true }
	end
	local info = { name = name, value = value, default = default, help = FindConsoleHelp(name) }
	if tonumber(value) and not (isLocked or isSecure or isReadOnly) and not InCombatLockdown() then
		info.min = ProbeLimit(name, PROBE_LOW, value)
		info.max = ProbeLimit(name, PROBE_HIGH, value)
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

commands.reset = function()
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
