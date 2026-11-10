local _, ns = ...

local L = ns.L

--[[
	About page of the options window: who made the addon, version and links.
	The same page (content and layout) exists in all addons by Phenom.
]]

local DISCORD = "https://discord.gg/4fSVKCVJWy"

local function GetLinks()
	return {
		{ label = "Discord", url = DISCORD },
		{ label = "CurseForge", url = "https://www.curseforge.com/projects/1748279" },
		{ label = "Wago", url = "https://addons.wago.io/addons/L6JbyQ6v" },
		{ label = "GitHub", url = "https://github.com/PhenomDevel/Quality-of-Life-Forever" },
		{ label = L.ABOUT_REPORT_BUG, url = "https://github.com/PhenomDevel/Quality-of-Life-Forever/issues" },
		{ label = L.ABOUT_SUPPORT, url = "https://streamlabs.com/phenombutbetter/tip" },
	}
end

local function GetOtherAddons()
	return {
		{ name = "AskAzeroth", note = L.ABOUT_ADDON_ASKAZEROTH },
		{ name = "BlizzHUDTweaks", note = L.ABOUT_ADDON_BLIZZHUDTWEAKS },
		{ name = "Guild Finder Forever", note = L.ABOUT_ADDON_GUILDFINDER },
		{ name = "PhenomRaidTools", note = L.ABOUT_ADDON_PHENOMRAIDTOOLS },
	}
end

-- Returns title, subtitle, no list entries, cards (like the General page).
function ns:GetAboutPage()
	local linkRows = {}
	for _, link in ipairs(GetLinks()) do
		linkRows[#linkRows + 1] = {
			type = "text",
			label = link.label,
			tooltip = L.ABOUT_COPY_TOOLTIP,
			readOnly = true,
			width = 260,
			get = function()
				return link.url
			end,
		}
	end

	local addonLines = {}
	for _, other in ipairs(GetOtherAddons()) do
		addonLines[#addonLines + 1] = ("{%s}: %s"):format(other.name, other.note)
	end

	return L.ABOUT, L.ABOUT_SUBTITLE:format("Quality of Life Forever"), nil, {
		{
			title = "Quality of Life Forever",
			note = L.ABOUT_MADE_BY,
			rows = {
				{ type = "description", label = L.ABOUT_TAGLINE },
				{ type = "description", label = L.ABOUT_DETAILS:format(ns.version) },
				{ type = "notice", label = L.ABOUT_DISCORD .. " " .. DISCORD },
			},
		},
		{
			title = L.ABOUT_LINKS,
			note = L.ABOUT_LINKS_NOTE,
			rows = linkRows,
		},
		{
			title = L.ABOUT_MORE_ADDONS,
			rows = {
				{ type = "description", label = table.concat(addonLines, "\n") },
			},
		},
	}
end
