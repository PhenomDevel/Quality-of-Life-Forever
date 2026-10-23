-- luacheck: read globals CanCancelScene CancelScene IsInCinematicScene IsShiftKeyDown MovieFrame StopCinematic
local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Skip cinematics",
		NOTE = "Hold Shift to watch one",
		SECTION_SKIP = "Skip",
		DESC = "Skips in-game cinematics and pre-rendered movies automatically. Hold Shift when one starts to watch it.",
		CINEMATICS = "In-game cinematics",
		CINEMATICS_DESC = "Cutscenes rendered by the game engine.",
		MOVIES = "Movies",
		MOVIES_DESC = "Pre-rendered videos.",
		ONLY_SEEN = "Only movies you have seen",
		ONLY_SEEN_DESC = "Plays each movie once and skips it afterwards. In-game cinematics can't be identified and are always skipped.",
	},
	deDE = {
		TITLE = "Filmsequenzen überspringen",
		NOTE = "Shift halten zum Ansehen",
		SECTION_SKIP = "Überspringen",
		DESC = "Überspringt Zwischensequenzen und vorgerenderte Videos automatisch. Shift gedrückt halten, wenn eine startet, um sie anzusehen.",
		CINEMATICS = "Zwischensequenzen",
		CINEMATICS_DESC = "Szenen, die von der Spielengine dargestellt werden.",
		MOVIES = "Videos",
		MOVIES_DESC = "Vorgerenderte Videos.",
		ONLY_SEEN = "Nur Videos, die du kennst",
		ONLY_SEEN_DESC = "Spielt jedes Video einmal ab und überspringt es danach. Zwischensequenzen lassen sich nicht unterscheiden und werden immer übersprungen.",
	},
})

local module = ns:NewModule("SkipCinematics", {
	title = L.TITLE,
	description = L.DESC,
	note = L.NOTE,
	category = "INTERFACE",
	order = 10,
	defaults = {
		cinematics = true,
		movies = true,
		onlySeen = false,
		seenMovies = {},
	},
	options = {
		{ type = "header", label = L.SECTION_SKIP },
		{ key = "cinematics", type = "checkbox", label = L.CINEMATICS, tooltip = L.CINEMATICS_DESC },
		{ key = "movies", type = "checkbox", label = L.MOVIES, tooltip = L.MOVIES_DESC },
		{ key = "onlySeen", type = "checkbox", label = L.ONLY_SEEN, tooltip = L.ONLY_SEEN_DESC },
	},
})

function module:OnEnable()
	self:RegisterEvent("CINEMATIC_START")
	self:RegisterEvent("PLAY_MOVIE")
end

-- Cancel on the next frame, after Blizzard's frames handled the start.
function module:CINEMATIC_START(canBeCancelled)
	if not self.db.cinematics or IsShiftKeyDown() then
		return
	end
	C_Timer.After(0, function()
		if not self.enabled then
			return
		end
		if canBeCancelled then
			StopCinematic()
		elseif IsInCinematicScene() and CanCancelScene() then
			CancelScene()
		end
	end)
end

function module:PLAY_MOVIE(movieID)
	if not self.db.movies or not movieID then
		return
	end
	local seen = self.db.seenMovies[movieID]
	self.db.seenMovies[movieID] = true
	if IsShiftKeyDown() or (self.db.onlySeen and not seen) then
		return
	end
	C_Timer.After(0, function()
		if self.enabled and MovieFrame:IsShown() and MovieFrame.movieID == movieID then
			MovieFrame:FinishMovie()
		end
	end)
end
