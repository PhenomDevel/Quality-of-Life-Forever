--[[
	Test runner. Run from the repository root:

		lua5.1 tests/run.lua

	Every test boots a fresh copy of the addon in an isolated mock environment.
]]

package.path = "./tests/?.lua;" .. package.path
local WoWMock = require("wowmock")

local tests = {}
local function test(name, func)
	tests[#tests + 1] = { name = name, func = func }
end

local function assertEquals(actual, expected, message)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(message or "assertEquals", tostring(expected), tostring(actual)), 2)
	end
end

local function assertContains(list, pattern, message)
	for _, entry in ipairs(list) do
		if tostring(entry):find(pattern) then
			return
		end
	end
	error(("%s: no entry matches %q"):format(message or "assertContains", pattern), 2)
end

local function assertNoErrors(state)
	if #state.errors > 0 then
		error("Unexpected Lua errors:\n  " .. table.concat(state.errors, "\n  "), 2)
	end
end

--------------------------------------------------------------------------------
-- Core
--------------------------------------------------------------------------------

test("loads without errors and registers modules", function()
	local state = WoWMock.Boot()
	assertNoErrors(state)
	local ns = state.ns
	assert(#ns.moduleOrder > 0, "no modules registered")
	assert(state.env.QualityOfLifeForeverDB, "saved variables not created")
	assertEquals(state.env.QualityOfLifeForeverDB.version, 1, "db version")
	assert(state.env.SlashCmdList.QOLFOREVER, "slash command not registered")
end)

test("every module has a title, description and localized strings", function()
	for _, locale in ipairs({ "enUS", "deDE" }) do
		local state = WoWMock.Boot({ locale = locale })
		for _, module in state.ns:IterateModules() do
			assert(module.title ~= module.name, module.name .. ": missing title")
			assert(module.description ~= "", module.name .. ": missing description")
			assert(not module.title:match("^[%u_]+$"), module.name .. ": title is an untranslated key")
			assert(not module.description:match("^[%u_]+$"), module.name .. ": description is an untranslated key")
			for _, option in ipairs(module.options) do
				assert(not option.label:match("^[%u_]+$"), module.name .. "." .. option.key .. ": untranslated label")
				assert(module.defaults[option.key] ~= nil, module.name .. "." .. option.key .. ": option has no default")
			end
		end
	end
end)

test("deDE translates every enUS key", function()
	local function LoadLocale(locale)
		local env = setmetatable({ GetLocale = function() return locale end }, { __index = _G })
		local ns = {}
		for _, file in ipairs({ "enUS", "deDE" }) do
			local chunk = assert(loadfile("QualityOfLifeForever/Locales/" .. file .. ".lua"))
			setfenv(chunk, env)
			chunk("QualityOfLifeForever", ns)
		end
		return ns.L
	end
	local enUS, deDE = {}, LoadLocale("deDE")
	for key, value in pairs(LoadLocale("enUS")) do
		enUS[key] = value
	end
	local missing = {}
	for key, value in pairs(enUS) do
		if rawget(deDE, key) == value and key ~= "UNKNOWN_VERSION" and key ~= "CATEGORY_QUESTS" and key ~= "CATEGORY_CHAT" then
			missing[#missing + 1] = key
		end
	end
	table.sort(missing)
	assertEquals(#missing, 0, "untranslated deDE keys: " .. table.concat(missing, ", "))
end)

test("modules follow their default enabled state", function()
	local state = WoWMock.Boot()
	for _, module in state.ns:IterateModules() do
		assertEquals(module.enabled, module.defaultEnabled, module.name .. " enabled")
	end
end)

test("saved state is respected and missing defaults are added", function()
	local state = WoWMock.Boot({
		savedVariables = { version = 1, modules = { AutoRepair = { enabled = false } } },
	})
	local module = state.ns:GetModule("AutoRepair")
	assertEquals(module.enabled, false, "AutoRepair enabled")
	assertEquals(module.db.useGuildFunds, true, "default useGuildFunds")
	assertEquals(state.env.QualityOfLifeForeverDB.global.printMessages, true, "global default")
end)

test("settings panel registers one checkbox per module plus options", function()
	local state = WoWMock.Boot()
	assertNoErrors(state)
	assert(state.registeredCategory, "settings category not registered")
	for _, module in state.ns:IterateModules() do
		assert(state.settings["QOLFOREVER_" .. module.name .. "_enabled"], module.name .. ": no enable setting")
		for _, option in ipairs(module.options) do
			assert(state.settings["QOLFOREVER_" .. module.name .. "_" .. option.key], module.name .. ": no setting for " .. option.key)
		end
	end
end)

test("toggling a module in the settings panel enables and disables it", function()
	local state = WoWMock.Boot()
	local module = state.ns:GetModule("AutoRepair")
	local setting = state.settings.QOLFOREVER_AutoRepair_enabled

	setting:SetValue(false)
	assertEquals(module.enabled, false, "after disable")
	assertEquals(module.db.enabled, false, "saved after disable")
	assertEquals(state.CountEventListeners("MERCHANT_SHOW"), 1, "only AutoSellJunk listens to MERCHANT_SHOW")

	setting:SetValue(true)
	assertEquals(module.enabled, true, "after enable")
	assertEquals(state.CountEventListeners("MERCHANT_SHOW"), 2, "both merchant modules listen")
	assertNoErrors(state)
end)

test("slash commands toggle modules and keep the settings in sync", function()
	local state = WoWMock.Boot()
	local slash = state.env.SlashCmdList.QOLFOREVER
	local module = state.ns:GetModule("FastLoot")

	slash("enable fastloot")
	assertEquals(module.enabled, true, "enabled via slash")
	assertEquals(state.settings.QOLFOREVER_FastLoot_enabled:GetValue(), true, "setting synced")

	slash("toggle FastLoot")
	assertEquals(module.enabled, false, "toggled via slash")

	slash("enable doesnotexist")
	assertContains(state.messages, "doesnotexist", "unknown module message")

	slash("")
	assertEquals(state.openedCategory, state.registeredCategory:GetID(), "opens settings")

	slash("debug")
	assertEquals(state.env.QualityOfLifeForeverDB.global.debug, true, "debug toggled")

	slash("list")
	assertContains(state.messages, "FastLoot", "module list")
	assertNoErrors(state)
end)

test("combat protected modules are switched after combat", function()
	local state = WoWMock.Boot()
	local ns = state.ns
	local calls = 0
	local module = ns:NewModule("TestProtected", { combatProtected = true, defaultEnabled = false })
	function module:OnEnable()
		calls = calls + 1
	end
	module.db = ns:GetModuleDB(module)

	state.inCombat = true
	ns:SetModuleEnabled(module, true)
	assertEquals(module.enabled, false, "not enabled in combat")
	assertContains(state.messages, "after combat", "queued message")

	state.inCombat = false
	state.FireEvent("PLAYER_REGEN_ENABLED")
	assertEquals(module.enabled, true, "enabled after combat")
	assertEquals(calls, 1, "OnEnable calls")
end)

test("a failing module does not break the others", function()
	local state = WoWMock.Boot({
		login = false,
		setup = function() end,
	})
	local ns = state.ns
	local broken = ns:NewModule("Broken", { defaultEnabled = true })
	function broken:OnEnable()
		error("boom")
	end
	state.FireEvent("ADDON_LOADED", "QualityOfLifeForever")
	state.FireEvent("PLAYER_LOGIN")
	assertEquals(#state.errors, 1, "error was reported")
	assertEquals(ns:GetModule("AutoRepair").enabled, true, "other modules still enabled")
end)

test("secure hooks only fire while the module is enabled", function()
	local state = WoWMock.Boot()
	local ns = state.ns
	local hits = 0
	state.env.SomeBlizzardFunction = function() end
	local module = ns:NewModule("TestHook", { defaultEnabled = true })
	module.db = ns:GetModuleDB(module)
	module:SecureHook("SomeBlizzardFunction", function()
		hits = hits + 1
	end)
	ns:ApplyModuleState(module)

	state.env.SomeBlizzardFunction()
	ns:SetModuleEnabled(module, false)
	state.env.SomeBlizzardFunction()
	assertEquals(hits, 1, "hook calls")
end)

test("requiresReload modules ask for a reload when disabled", function()
	local state = WoWMock.Boot()
	local ns = state.ns
	local module = ns:NewModule("TestReload", { requiresReload = true, defaultEnabled = true })
	module.db = ns:GetModuleDB(module)
	ns:ApplyModuleState(module)
	ns:SetModuleEnabled(module, false)
	assertEquals(state.popups[1] and state.popups[1].name, "QOLFOREVER_RELOAD", "reload popup")
end)

--------------------------------------------------------------------------------
-- Modules
--------------------------------------------------------------------------------

local function MerchantSetup(merchant)
	return function(env)
		env.CanMerchantRepair = function()
			return true
		end
		env.GetRepairAllCost = function()
			return merchant.cost, merchant.cost > 0
		end
		env.RepairAllItems = function(guild)
			merchant.repairs[#merchant.repairs + 1] = guild and "guild" or "own"
			if not guild or merchant.guildHasMoney then
				merchant.cost = 0
			end
		end
		env.GetMoney = function()
			return merchant.money
		end
		env.IsInGuild = function()
			return merchant.inGuild
		end
		env.CanGuildBankRepair = function()
			return merchant.inGuild
		end
		env.GetGuildBankWithdrawMoney = function()
			return -1
		end
	end
end

test("AutoRepair repairs with own money", function()
	local merchant = { cost = 500, money = 1000, inGuild = false, repairs = {} }
	local state = WoWMock.Boot({ setup = MerchantSetup(merchant) })
	state.FireEvent("MERCHANT_SHOW")
	assertEquals(merchant.repairs[1], "own", "repair type")
	assertContains(state.messages, "500c", "repair message")
	assertNoErrors(state)
end)

test("AutoRepair falls back to own money when the guild bank is empty", function()
	local merchant = { cost = 500, money = 1000, inGuild = true, guildHasMoney = false, repairs = {} }
	local state = WoWMock.Boot({ setup = MerchantSetup(merchant) })
	state.FireEvent("MERCHANT_SHOW")
	state.RunTimers()
	assertEquals(table.concat(merchant.repairs, ","), "guild,own", "repair order")
	assertNoErrors(state)
end)

test("AutoRepair does nothing without enough money", function()
	local merchant = { cost = 500, money = 10, inGuild = false, repairs = {} }
	local state = WoWMock.Boot({ setup = MerchantSetup(merchant) })
	state.FireEvent("MERCHANT_SHOW")
	assertEquals(#merchant.repairs, 0, "repairs")
	assertContains(state.messages, "Not enough gold", "message")
end)

test("AutoSellJunk sells only grey items in batches", function()
	local bags = { [0] = {}, [1] = {} }
	for slot = 1, 12 do
		bags[0][slot] = { itemID = 100, quality = 0, stackCount = 1, hasNoValue = false }
	end
	bags[1][1] = { itemID = 200, quality = 1, stackCount = 1 }
	bags[1][2] = { itemID = 300, quality = 0, stackCount = 2, hasNoValue = true }
	local sold = {}

	local state = WoWMock.Boot({
		setup = function(env)
			env.BACKPACK_CONTAINER = 0
			env.NUM_BAG_SLOTS = 1
			env.Enum = { ItemQuality = { Poor = 0 } }
			env.C_Container = {
				GetContainerNumSlots = function(bag)
					return 16 * (bags[bag] and 1 or 0)
				end,
				GetContainerItemInfo = function(bag, slot)
					return bags[bag] and bags[bag][slot]
				end,
				UseContainerItem = function(bag, slot)
					sold[#sold + 1] = bags[bag][slot].itemID
					bags[bag][slot] = nil
				end,
			}
			env.C_Item = {
				GetItemInfo = function()
					return nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 25
				end,
			}
		end,
	})

	state.FireEvent("MERCHANT_SHOW")
	assertEquals(#sold, 10, "first batch")
	state.RunTimers()
	assertEquals(#sold, 12, "second batch")
	state.RunTimers()
	assertContains(state.messages, "Sold 12 junk item%(s%) for 300c", "summary")
	assertNoErrors(state)
end)

test("FastLoot loots every slot when auto loot is active", function()
	local looted = {}
	local state = WoWMock.Boot({
		savedVariables = { modules = { FastLoot = { enabled = true } } },
		setup = function(env)
			env.GetNumLootItems = function()
				return 3
			end
			env.LootSlot = function(slot)
				looted[#looted + 1] = slot
			end
		end,
	})
	state.FireEvent("LOOT_READY", false)
	assertEquals(#looted, 0, "no auto loot")
	state.FireEvent("LOOT_READY", true)
	assertEquals(table.concat(looted, ","), "3,2,1", "looted slots")
	assertNoErrors(state)
end)

test("AutoDeclineDuels declines duel requests", function()
	local cancelled = 0
	local state = WoWMock.Boot({
		savedVariables = { modules = { AutoDeclineDuels = { enabled = true } } },
		setup = function(env)
			env.CancelDuel = function()
				cancelled = cancelled + 1
			end
		end,
	})
	state.FireEvent("DUEL_REQUESTED", "Thrall")
	assertEquals(cancelled, 1, "duels cancelled")
	assertContains(state.messages, "Thrall", "notification")
	assertNoErrors(state)
end)

--------------------------------------------------------------------------------

local failed = 0
for _, entry in ipairs(tests) do
	local ok, err = pcall(entry.func)
	if ok then
		print("  ok    " .. entry.name)
	else
		failed = failed + 1
		print("  FAIL  " .. entry.name .. "\n        " .. tostring(err))
	end
end
print(("\n%d tests, %d failed"):format(#tests, failed))
os.exit(failed == 0 and 0 or 1)
