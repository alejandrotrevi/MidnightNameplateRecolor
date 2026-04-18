local addonName, addon = ...

-- Build the settings tree:
--   Root
--     [top] Enable checkbox + help text (always visible)
--     [expandable] "Algeth'ar Academy" → dropdown per mob
--     [expandable] "Magisters' Terrace" → ...
--     ... one section per dungeon in alphabetical order
-- The dropdown for each mob is a palette picker (Default / Red / Orange / ...).

local function refreshPaint()
	if addon.Recolor and addon.Recolor.RepaintAll then
		addon.Recolor:RepaintAll()
	end
end

local function paletteListFunc()
	-- LibEQOL wants (values, order) where values is { key = label, ... }.
	return addon.GetPaletteDropdown()
end

local function colorKeyVar(mapID, npcID)
	-- Dropdown var name — LibEQOL uses this as its setting ID. Must be stable
	-- and unique across the whole addon.
	return "color_" .. tostring(mapID) .. "_" .. tostring(npcID)
end

local function buildDungeonSection(rootCat, mapID)
	local dungeon = addon.Dungeons[mapID]
	if not dungeon then return end

	local section = addon.functions.SettingsCreateExpandableSection(rootCat, {
		name = dungeon.name,
		expanded = false,
		newTagID = "MNR_" .. tostring(mapID),
	})

	for _, npcID in ipairs(addon.GetDungeonMobOrder(mapID)) do
		local mobName = dungeon.mobs[npcID]
		addon.functions.SettingsCreateDropdown(rootCat, {
			var = colorKeyVar(mapID, npcID),
			text = mobName,
			listFunc = paletteListFunc,
			default = "default",
			get = function()
				return addon.Recolor:GetColorKey(mapID, npcID) or "default"
			end,
			set = function(value)
				addon.Recolor:SetColorKey(mapID, npcID, value)
				refreshPaint()
			end,
			parentCheck = function()
				return addon.Recolor:IsEnabled()
			end,
			parentSection = section,
		})
	end
end

local function buildSettings()
	local rootCat = addon.SettingsLayout.rootCategory
	if not rootCat then return end

	-- Top (outside any collapsible section): global toggle + help text.
	addon.functions.SettingsCreateCheckbox(rootCat, {
		var = "enabled",
		text = "Enable nameplate recoloring",
		desc = "Repaints hostile trash nameplates in Midnight Season 1 dungeons using colors picked below.",
		default = true,
		get = function() return addon.Recolor:IsEnabled() end,
		set = function(v) addon.Recolor:SetEnabled(v) end,
	})

	addon.functions.SettingsCreateText(rootCat,
		"Pick a color per mob in each dungeon. |cffffd100Default|r keeps the nameplate's normal color. " ..
		"Fingerprints sourced from MythicPlusCount; works in Normal/Heroic/M0/M+ runs of the same dungeon.")

	for _, mapID in ipairs(addon.DungeonOrder) do
		buildDungeonSection(rootCat, mapID)
	end
end

function addon.functions.InitSettings()
	if addon.SettingsLayout.ready then return end
	buildSettings()
	addon.SettingsLayout.ready = true
end
