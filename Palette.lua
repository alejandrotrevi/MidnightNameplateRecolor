local addonName, addon = ...

-- Named colors the settings dropdown lists. `key` is the stable identifier
-- stored in SavedVariables; `label` is displayed in the dropdown; `r/g/b` are
-- the paint values (nil = "don't override" = fall through to EUI/Blizzard).
-- Keep the list short so the dropdown is scannable.
addon.Palette = {
	{ key = "default", label = "Default (no override)", r = nil, g = nil, b = nil },
	{ key = "red",     label = "Red",     r = 1.00, g = 0.20, b = 0.20 },
	{ key = "orange",  label = "Orange",  r = 1.00, g = 0.55, b = 0.10 },
	{ key = "yellow",  label = "Yellow",  r = 1.00, g = 0.85, b = 0.10 },
	{ key = "lime",    label = "Lime",    r = 0.55, g = 0.95, b = 0.20 },
	{ key = "green",   label = "Green",   r = 0.20, g = 0.80, b = 0.30 },
	{ key = "cyan",    label = "Cyan",    r = 0.20, g = 0.85, b = 0.90 },
	{ key = "blue",    label = "Blue",    r = 0.30, g = 0.55, b = 1.00 },
	{ key = "purple",  label = "Purple",  r = 0.65, g = 0.30, b = 0.90 },
	{ key = "pink",    label = "Pink",    r = 1.00, g = 0.50, b = 0.80 },
	{ key = "white",   label = "White",   r = 1.00, g = 1.00, b = 1.00 },
	{ key = "black",   label = "Black",   r = 0.15, g = 0.15, b = 0.15 },
}

-- Build a lookup for O(1) color resolution at paint time.
addon.PaletteByKey = {}
for _, entry in ipairs(addon.Palette) do
	addon.PaletteByKey[entry.key] = entry
end

-- Return r, g, b for a palette key (or nil if key is "default" / missing).
function addon.GetPaletteColor(key)
	local entry = key and addon.PaletteByKey[key] or nil
	if not entry or not entry.r then return nil end
	return entry.r, entry.g, entry.b
end

-- Options table suitable for LibEQOL dropdowns: { [key] = label, ... } plus
-- a stable order array.
function addon.GetPaletteDropdown()
	local values = {}
	local order = {}
	for _, entry in ipairs(addon.Palette) do
		values[entry.key] = entry.label
		order[#order + 1] = entry.key
	end
	return values, order
end
