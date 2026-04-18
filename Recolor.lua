local addonName, addon = ...

-- Runtime paint. Takes the lessons from the PersonalQOL POC:
--   1. EllesmereUI mounts its own pool plate as a child of Blizzard's plate;
--      painting blizzardPlate.UnitFrame.healthBar does NOT recolor the visible
--      bar. Paint `euiPlate.health` when EUI is loaded.
--   2. `NameplateFrame` is file-local in EUI — not a global we can hook. Hook
--      `UpdateHealthColor` per-plate after EUI mixes it in.
--   3. C_NamePlate.GetNamePlates() doesn't reliably expose `namePlateUnitToken`;
--      enumerate via `UnitExists("nameplate"..i)` for i=1..40 for robustness.

local CreateFrame     = CreateFrame
local C_NamePlate     = C_NamePlate
local UnitExists      = UnitExists
local UnitCanAttack   = UnitCanAttack
local UnitIsPlayer    = UnitIsPlayer
local hooksecurefunc  = hooksecurefunc
local ipairs          = ipairs
local pairs           = pairs

local MAX_NAMEPLATES = 40
local DB_ENABLED = "enabled"
local DB_COLORS  = "colors" -- { ["<mapID>:<npcID>"] = "<paletteKey>" }

addon.Recolor = addon.Recolor or {}
local R = addon.Recolor

R.debug = false
local function dprint(fmt, ...)
	if not R.debug then return end
	print("|cff7fffd4[MNR]|r " .. string.format(fmt, ...))
end

local function db()
	return addon.db
end

-- Flat storage key — keeps one map for every mob across every dungeon, easy
-- to dump and migrate.
local function colorKey(mapID, npcID)
	return tostring(mapID) .. ":" .. tostring(npcID)
end

function R:GetColorKey(mapID, npcID)
	local d = db()
	if not d or not d[DB_COLORS] then return nil end
	return d[DB_COLORS][colorKey(mapID, npcID)]
end

function R:SetColorKey(mapID, npcID, paletteKey)
	local d = db()
	if not d then return end
	d[DB_COLORS] = d[DB_COLORS] or {}
	if not paletteKey or paletteKey == "default" then
		d[DB_COLORS][colorKey(mapID, npcID)] = nil
	else
		d[DB_COLORS][colorKey(mapID, npcID)] = paletteKey
	end
end

-- Find EllesmereUI's pool plate among the Blizzard plate's children (the one
-- with `_mixedIn + .health + .UpdateHealthColor`; see EllesmereUINameplates.lua
-- lines 3022-4744 in the reference addon).
local function findEUIPlate(blizzardPlate)
	if not blizzardPlate then return nil end
	for _, child in ipairs({ blizzardPlate:GetChildren() }) do
		if child._mixedIn and child.health and child.UpdateHealthColor then
			return child
		end
	end
	return nil
end

local function paintHealthBar(blizzardPlate, r, g, b)
	local eui = findEUIPlate(blizzardPlate)
	if eui and eui.health and eui.health.SetStatusBarColor then
		eui.health:SetStatusBarColor(r, g, b)
		return true
	end
	local hb = blizzardPlate.UnitFrame and blizzardPlate.UnitFrame.healthBar
	if hb and hb.SetStatusBarColor then
		hb:SetStatusBarColor(r, g, b)
		return true
	end
	return false
end

function R:PaintUnit(unit)
	if not unit then return end
	local mapID, npcID = addon.Identify(unit)
	if not mapID then
		dprint("%s: no identify (not a recognized dungeon mob)", unit)
		return
	end
	local key = self:GetColorKey(mapID, npcID)
	if not key or key == "default" then
		dprint("%s: npcID=%s has no color set", unit, tostring(npcID))
		return
	end
	local r, g, b = addon.GetPaletteColor(key)
	if not r then
		dprint("%s: color key '%s' didn't resolve to rgb", unit, tostring(key))
		return
	end
	local bp = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
	if not bp then
		dprint("%s: C_NamePlate.GetNamePlateForUnit returned nil", unit)
		return
	end
	if paintHealthBar(bp, r, g, b) then
		dprint("%s: painted npcID=%s '%s' rgb(%.2f,%.2f,%.2f)", unit, tostring(npcID), key, r, g, b)
	else
		dprint("%s: matched npcID=%s but no paintable healthbar found", unit, tostring(npcID))
	end
end

function R:RepaintAll()
	for i = 1, MAX_NAMEPLATES do
		local unit = "nameplate" .. i
		if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsPlayer(unit) then
			self:PaintUnit(unit)
		end
	end
end

-- Install a `hooksecurefunc` on an EUI plate the first time we see it.
-- Re-runs our paint after EUI's own color write so we survive its ladder.
local function ensurePlateHook(euiPlate)
	if not euiPlate or euiPlate._mnrHooked then return end
	if type(euiPlate.UpdateHealthColor) ~= "function" then return end
	hooksecurefunc(euiPlate, "UpdateHealthColor", function(self)
		if not R.enabled then return end
		if not self or not self.unit then return end
		R:PaintUnit(self.unit)
	end)
	euiPlate._mnrHooked = true
end

local eventFrame

local function onAdded(unit)
	if not unit then return end
	local bp = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
	if bp then ensurePlateHook(findEUIPlate(bp)) end
	R:PaintUnit(unit)
end

function R:RegisterEvents()
	if self.eventsRegistered then return end
	eventFrame = eventFrame or CreateFrame("Frame")
	eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventFrame:SetScript("OnEvent", function(_, event, unit)
		if event == "NAME_PLATE_UNIT_ADDED" then
			onAdded(unit)
		elseif event == "NAME_PLATE_UNIT_REMOVED" then
			addon.OnUnitRemoved(unit)
		elseif event == "PLAYER_ENTERING_WORLD" then
			addon.ClearIdentifyCache()
		end
	end)
	self.eventsRegistered = true
end

function R:UnregisterEvents()
	if not self.eventsRegistered or not eventFrame then return end
	eventFrame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
	eventFrame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
	eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	eventFrame:SetScript("OnEvent", nil)
	self.eventsRegistered = false
	addon.ClearIdentifyCache()
end

function R:OnEnabledChanged(enabled)
	self.enabled = enabled == true
	if self.enabled then
		self:RegisterEvents()
		-- Hook plates that are already on-screen at enable time.
		for i = 1, MAX_NAMEPLATES do
			local unit = "nameplate" .. i
			if UnitExists(unit) then
				local bp = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
				if bp then ensurePlateHook(findEUIPlate(bp)) end
			end
		end
		self:RepaintAll()
	else
		self:UnregisterEvents()
	end
end

function R:InitDB()
	local d = db()
	if not d then return end
	if d[DB_ENABLED] == nil then d[DB_ENABLED] = true end
	if type(d[DB_COLORS]) ~= "table" then d[DB_COLORS] = {} end
end

function R:IsEnabled()
	return db() and db()[DB_ENABLED] == true
end

function R:SetEnabled(v)
	local d = db()
	if not d then return end
	d[DB_ENABLED] = v and true or false
	self:OnEnabledChanged(d[DB_ENABLED])
end
