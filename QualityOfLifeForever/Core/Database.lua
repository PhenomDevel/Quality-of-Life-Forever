local _, ns = ...

local Utils = ns.Utils

-- Bump this and add an entry to `migrations` whenever the saved data layout
-- changes in a way that defaults alone cannot handle.
local DB_VERSION = 1

local GLOBAL_DEFAULTS = {
	printMessages = true,
	notices = true,
	stackWidgets = false,
	debug = false,
	minimapButton = true,
	minimapAngle = 225,
	optionsPreview = true,
	whatsNew = true,
	-- [overlay key][Edit Mode layout name] = { point, x, y, scale }
	overlays = {},
}

-- migrations[n] upgrades a database from version n - 1 to version n.
local migrations = {
	-- [2] = function(db) ... end,
}

local function Migrate(db)
	local current = db.version or DB_VERSION
	for version = current + 1, DB_VERSION do
		if migrations[version] then
			migrations[version](db)
		end
	end
	db.version = DB_VERSION
end

--[[
	Layout of QualityOfLifeForeverDB (account wide):
	{
		version = 1,
		global = { printMessages = true, notices = true, stackWidgets = false, debug = false, minimapButton = true, minimapAngle = 225, optionsPreview = true, whatsNew = true, lastVersion = "v0.11.0", overlays = {} },
		modules = {
			AutoRepair = { enabled = true, useGuildFunds = true },
			...
		},
	}
]]
function ns:InitializeDatabase()
	if type(QualityOfLifeForeverDB) ~= "table" then
		QualityOfLifeForeverDB = {}
		ns.isNewInstall = true
	end
	local db = QualityOfLifeForeverDB

	Migrate(db)
	db.global = Utils.ApplyDefaults(type(db.global) == "table" and db.global or {}, GLOBAL_DEFAULTS)
	db.modules = type(db.modules) == "table" and db.modules or {}

	ns.db = db
end

-- Returns the saved table of a module, filled with its defaults.
function ns:GetModuleDB(module)
	local modules = ns.db.modules
	local moduleDB = modules[module.name]
	if type(moduleDB) ~= "table" then
		moduleDB = {}
		modules[module.name] = moduleDB
	end
	if moduleDB.enabled == nil then
		moduleDB.enabled = module.defaultEnabled
	end
	return Utils.ApplyDefaults(moduleDB, module.defaults)
end

function ns:ResetDatabase()
	QualityOfLifeForeverDB = nil
	ReloadUI()
end
