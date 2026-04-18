local addonName, addon = ...
local SettingsLib = LibStub("LibEQOLSettingsMode-1.0")

-- Minimal wrappers around LibEQOLSettingsMode, modelled on
-- PersonalQOL/Settings/SettingsUI.lua. Only the helpers we use in Settings.lua
-- are here — no scroll dropdowns, sound pickers, etc.

local PREFIX = "MNR_"

addon.SettingsLayout = addon.SettingsLayout or { elements = {} }

-- Root category is registered lazily from InitSettings (the shared lifecycle
-- entry point in Settings.lua), not at file load. Keeps file scope free of
-- SettingsLib:Create* calls per the lifecycle rules.
function addon.functions.EnsureRootCategory()
	if addon.SettingsLayout.rootCategory then return addon.SettingsLayout.rootCategory end
	addon.SettingsLayout.rootCategory = SettingsLib:CreateRootCategory(addonName, false)
	return addon.SettingsLayout.rootCategory
end

function addon.functions.SettingsCreateCheckbox(cat, data)
	local element, setting = SettingsLib:CreateCheckbox(cat, {
		key = data.var,
		name = data.text,
		default = data.default or false,
		get = data.get or function() return addon.db[data.var] end,
		set = data.set or function(v) addon.db[data.var] = v end,
		desc = data.desc,
		parent = data.element,
		parentCheck = data.parentCheck,
		parentSection = data.parentSection,
		prefix = PREFIX,
	})
	addon.SettingsLayout.elements[data.var] = { setting = setting, element = element }
	return addon.SettingsLayout.elements[data.var]
end

function addon.functions.SettingsCreateDropdown(cat, data)
	local element, setting = SettingsLib:CreateDropdown(cat, {
		key = data.var,
		name = data.text,
		default = data.default,
		values = data.values,
		optionfunc = data.listFunc,
		order = data.order,
		get = data.get or function() return addon.db[data.var] end,
		set = data.set or function(v) addon.db[data.var] = v end,
		desc = data.desc,
		parent = data.element or data.parent,
		parentCheck = data.parentCheck,
		parentSection = data.parentSection,
		prefix = PREFIX,
	})
	addon.SettingsLayout.elements[data.var] = { setting = setting, element = element }
	return addon.SettingsLayout.elements[data.var]
end

function addon.functions.SettingsCreateText(cat, text, extra)
	return SettingsLib:CreateText(cat, text, extra)
end

function addon.functions.SettingsCreateHeader(cat, text, extra)
	return SettingsLib:CreateHeader(cat, text, extra)
end

function addon.functions.SettingsCreateExpandableSection(cat, data)
	return SettingsLib:CreateExpandableSection(cat, {
		name = data.name,
		expanded = data.expanded,
		extent = data.extent,
		newTagID = data.newTagID,
		prefix = PREFIX,
	})
end
