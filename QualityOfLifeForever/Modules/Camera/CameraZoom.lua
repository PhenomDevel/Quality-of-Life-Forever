local _, ns = ...

local L = ns.NewLocale({
	enUS = {
		TITLE = "Max camera distance",
		DESC = "Sets the maximum camera zoom distance.",
		NOTICE = "Changes the game setting cameraDistanceMaxZoomFactor. Disabling restores your previous value.",
		FACTOR = "Zoom factor",
		FACTOR_DESC = "Multiplier for the maximum zoom distance. The client may cap the value.",
	},
	deDE = {
		TITLE = "Maximale Kameradistanz",
		DESC = "Setzt die maximale Zoomdistanz der Kamera.",
		NOTICE = "Ändert die Spieleinstellung cameraDistanceMaxZoomFactor. Beim Deaktivieren wird dein vorheriger Wert wiederhergestellt.",
		FACTOR = "Zoomfaktor",
		FACTOR_DESC = "Multiplikator für die maximale Zoomdistanz. Der Client kann den Wert begrenzen.",
	},
})

local module = ns:NewModule("CameraZoom", {
	title = L.TITLE,
	description = L.DESC,
	notice = L.NOTICE,
	category = "CAMERA",
	defaults = {
		factor = 4.0,
	},
	options = {
		{ key = "factor", type = "slider", label = L.FACTOR, tooltip = L.FACTOR_DESC, min = 1, max = 4, step = 0.1 },
	},
})

function module:Apply()
	self:SetCVar("cameraDistanceMaxZoomFactor", self.db.factor)
end

function module:OnEnable()
	self:Apply()
end

function module:OnOptionChanged()
	self:Apply()
end
