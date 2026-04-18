local addonName, addon = ...

-- Build the settings tree:
--   Root
--     [top] Enable checkbox + help text (always visible)
--     [expandable] "Algeth'ar Academy" → dropdown per mob
--     [expandable] "Magisters' Terrace" → ...
--     ... one section per dungeon in alphabetical order
-- The dropdown for each mob is a palette picker (Default / Red / Orange / ...).

-- suppressPaint guards the bulk reset path: each dropdown's set callback fires
-- refreshPaint(), so without this a reset of ~95 mobs would trigger ~95 full
-- RepaintAll passes. We short-circuit during the reset and do one paint at the end.
local suppressPaint = false
local function refreshPaint()
	if suppressPaint then return end
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

-- Push the current DB value into every color dropdown's Setting object so the
-- visible widgets resync after a programmatic DB change (the Reset button).
-- Calling Setting:SetValue fires the dropdown's `set` callback, which writes
-- the same value back to DB and calls refreshPaint — harmless and idempotent.
local function syncAllColorDropdowns()
	for mapID, dungeon in pairs(addon.Dungeons) do
		for npcID in pairs(dungeon.mobs) do
			local element = addon.SettingsLayout.elements[colorKeyVar(mapID, npcID)]
			local setting = element and element.setting
			if setting and setting.SetValue then
				setting:SetValue(addon.Recolor:GetColorKey(mapID, npcID) or "default")
			end
		end
	end
end

-- Blizzard StaticPopup used by the "Reset to defaults" button. Registered
-- lazily from buildSettings() — adding at file scope would run before
-- SavedVariables are bound on some load orders.
local RESET_POPUP = "MNR_RESET_DEFAULTS_CONFIRM"
local function registerResetPopup()
	if StaticPopupDialogs[RESET_POPUP] then return end
	StaticPopupDialogs[RESET_POPUP] = {
		text = "Reset all Midnight Nameplate Recolor mob colors to the built-in defaults?\n\nThis overwrites every color you've customized.",
		button1 = YES,
		button2 = NO,
		OnAccept = function()
			if not addon.ResetToDefaultColors then return end
			suppressPaint = true
			addon.ResetToDefaultColors()
			syncAllColorDropdowns()
			suppressPaint = false
			refreshPaint()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
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

	registerResetPopup()
	addon.functions.SettingsCreateButton(rootCat, {
		var = "reset_defaults",
		text = "Reset mob colors",
		label = "Reset to defaults",
		desc = "Overwrite all per-mob colors with the built-in interrupt-priority defaults (|cffff8000orange|r = extremely important, |cff4f8fffblue|r = important). Asks for confirmation before applying.",
		func = function()
			StaticPopup_Show(RESET_POPUP)
		end,
	})

	for _, mapID in ipairs(addon.DungeonOrder) do
		buildDungeonSection(rootCat, mapID)
	end
end

function addon.functions.InitSettings()
	if addon.SettingsLayout.ready then return end
	addon.functions.EnsureRootCategory()
	buildSettings()
	addon.SettingsLayout.ready = true
end
