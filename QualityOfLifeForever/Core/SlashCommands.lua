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
