local addonName, addon = ...

-- Build MPC-style fingerprints from a live unit and look the result up in
-- addon.Fingerprints to produce an npcID. Approach is lifted from
-- MythicPlusCount/util.lua:37-170. Key insight: every dimension we read is
-- plain (non-Secret) in Midnight M+, and their combination is unique enough
-- for ~all trash. Buff count is the extended-key tiebreaker.

local CreateFrame     = CreateFrame
local GetInstanceInfo = GetInstanceInfo
local UnitLevel       = UnitLevel
local UnitClassification = UnitClassification
local UnitSex         = UnitSex
local UnitClass       = UnitClass
local UnitPowerType   = UnitPowerType
local C_UnitAuras     = C_UnitAuras
local issecretvalue   = issecretvalue or function() return false end
local tostring        = tostring
local pcall           = pcall
local format          = string.format

-- Shared PlayerModel probe. Alpha 0 + offscreen position hides it; do NOT call
-- Hide() (hidden PlayerModel frames don't load models, so GetModelFileID then
-- returns nil). Replicated from the Personal QOL probe POC.
local probe
local function ensureProbe()
	if probe then return probe end
	probe = CreateFrame("PlayerModel", nil, UIParent)
	probe:SetAlpha(0)
	probe:SetSize(1, 1)
	probe:SetPoint("CENTER", UIParent, "CENTER", 0, 20000)
	return probe
end

local function safeVal(fn, ...)
	local ok, a, b = pcall(fn, ...)
	if not ok then return nil end
	if a ~= nil and issecretvalue(a) then return nil end
	return a, b
end

-- (mapID, fileID, level) → per-plate cache. Cleared on zone change.
local cache = {}
-- Cached ChallengeMapID for the current dungeon (resolved on demand, cleared
-- on PLAYER_ENTERING_WORLD). Matches MythicPlusCount/util.lua:286-324.
local resolvedMapID = nil

function addon.ClearIdentifyCache()
	cache = {}
	resolvedMapID = nil
end

function addon.OnUnitRemoved(unit)
	if unit then cache[unit] = nil end
end

-- Resolve to a ChallengeMapID (our Fingerprints keys). Two paths:
--   1. Inside an M+ keystone, C_ChallengeMode.GetActiveChallengeMapID() works.
--   2. Otherwise (Mythic 0, Heroic, Normal), match GetInstanceInfo()'s first
--      return (instance name) against our Dungeons table. `GetInstanceInfo`'s
--      8th return is the *instance* mapID (e.g. 2874 for Maisara) — different
--      from the ChallengeMapID (560) MPC keys by, so we can't use it directly.
local function currentMapID()
	if resolvedMapID then return resolvedMapID end

	if C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID then
		local cm = C_ChallengeMode.GetActiveChallengeMapID()
		if cm and type(cm) == "number" then
			resolvedMapID = cm
			return resolvedMapID
		end
	end

	local instanceName = GetInstanceInfo()
	if type(instanceName) ~= "string" then return nil end

	-- Exact match first.
	for mapID, d in pairs(addon.Dungeons) do
		if d.name == instanceName then
			resolvedMapID = mapID
			return resolvedMapID
		end
	end
	-- Case-insensitive substring fallback (e.g. "Seat of the Triumvirate" vs
	-- "The Seat of the Triumvirate").
	local lower = instanceName:lower()
	for mapID, d in pairs(addon.Dungeons) do
		local dlower = d.name:lower()
		if lower:find(dlower, 1, true) or dlower:find(lower, 1, true) then
			resolvedMapID = mapID
			return resolvedMapID
		end
	end
	return nil
end

addon.GetCurrentMapID = currentMapID

-- Count helpful auras. Per CLAUDE.md, `if data then` on the returned aura
-- table is a legal nil-vs-non-nil existence check even if the table's fields
-- are Secret — we never index or compare them.
local function countBuffs(unit)
	if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return 0 end
	local count = 0
	for i = 1, 20 do
		local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
		if not ok or not aura then break end
		count = count + 1
	end
	return count
end

-- Build MPC's 6-dimensional base fingerprint and the extended variant with
-- buff count appended. Uses MythicPlusCount's exact `safeRead` pattern —
-- read each dimension via its own pcall so a secret return on one field
-- doesn't poison the others, and each value is individually filtered for
-- secrecy.
local function safeRead(fn, default)
	local ok, val = pcall(fn)
	if ok and val ~= nil and not issecretvalue(val) then return val end
	return default
end

local function buildFingerprints(unit)
	local p = ensureProbe()
	p:ClearModel()
	if p.CanSetUnit and p:CanSetUnit(unit) == false then return nil end
	p:SetUnit(unit)
	local fileID = p.GetModelFileID and p:GetModelFileID() or nil
	if not fileID or fileID == 0 then return nil end

	local level   = safeRead(function() return UnitLevel(unit) end, 0)
	local classif = safeRead(function() return UnitClassification(unit) end, "?")
	local sex     = safeRead(function() return UnitSex(unit) end, 0)
	local ctok    = safeRead(function() return select(2, UnitClass(unit)) end, "?")
	local ptype   = safeRead(function() return UnitPowerType(unit) end, -1)

	local base = format("%d:%d:%s:%d:%s:%d",
		fileID, level % 10, classif, sex, ctok, ptype)

	local buffs = countBuffs(unit)
	local ext = base .. ":" .. tostring(buffs)

	return base, ext, fileID, level
end

-- Diagnostic: build the fingerprint and return every dimension + the resolved
-- strings, without touching the cache. Used by the /mnr status dump so we can
-- see exactly what we're generating when a match fails.
function addon.DebugIdentify(unit)
	if not unit then return nil end
	local base, ext, fileID, level = buildFingerprints(unit)
	local mapID = currentMapID()
	local byMap = mapID and addon.Fingerprints[mapID] or nil
	local npcID = base and byMap and ((ext and byMap[ext]) or byMap[base]) or nil
	return {
		fileID  = fileID,
		level   = level,
		classif = safeRead(function() return UnitClassification(unit) end, "?"),
		sex     = safeRead(function() return UnitSex(unit) end, 0),
		ctok    = safeRead(function() return select(2, UnitClass(unit)) end, "?"),
		ptype   = safeRead(function() return UnitPowerType(unit) end, -1),
		buffs   = countBuffs(unit),
		base    = base,
		ext     = ext,
		mapID   = mapID,
		npcID   = npcID,
	}
end

-- Identify a unit: returns (mapID, npcID) or nil. Memoized per unit token
-- until NAME_PLATE_UNIT_REMOVED or zone change.
function addon.Identify(unit)
	if not unit then return nil end
	local cached = cache[unit]
	if cached == false then return nil end
	if cached then return cached.mapID, cached.npcID end

	local mapID = currentMapID()
	local table_ = mapID and addon.Fingerprints[mapID] or nil
	if not table_ then
		cache[unit] = false
		return nil
	end

	local base, ext = buildFingerprints(unit)
	if not base then return nil end -- transient, don't poison cache

	-- Extended (with buff count) wins when present.
	local npcID = (ext and table_[ext]) or table_[base]
	if not npcID then
		cache[unit] = false
		return nil
	end

	cache[unit] = { mapID = mapID, npcID = npcID }
	return mapID, npcID
end
