local addonName, addon = ...

local CreateFrame     = CreateFrame
local print           = print
local tostring        = tostring
local format          = string.format
local pairs           = pairs
local ipairs          = ipairs
local UnitExists      = UnitExists
local UnitCanAttack   = UnitCanAttack
local UnitIsPlayer    = UnitIsPlayer
local C_NamePlate     = C_NamePlate
local GetInstanceInfo = GetInstanceInfo

-- -----------------------------------------------------------------------------
-- Lifecycle events
-- -----------------------------------------------------------------------------
-- Shared lifecycle (same shape as PersonalQOL's PersonalQOL.lua):
--   ADDON_LOADED: bind SavedVariables, init DB defaults
--   PLAYER_LOGIN: build settings panel, enable runtime

local eventFrame = CreateFrame("Frame")

local handlers = {
	["ADDON_LOADED"] = function(self, loadedAddon)
		if loadedAddon ~= addonName then return end
		self:UnregisterEvent("ADDON_LOADED")

		MidnightNameplateRecolorDB = MidnightNameplateRecolorDB or {}
		addon.db = MidnightNameplateRecolorDB

		addon.Recolor:InitDB()
	end,
	["PLAYER_LOGIN"] = function(self)
		self:UnregisterEvent("PLAYER_LOGIN")

		if addon.functions.InitSettings then
			addon.functions.InitSettings()
		end
		addon.Recolor:OnEnabledChanged(addon.Recolor:IsEnabled())
	end,
}

for event in pairs(handlers) do eventFrame:RegisterEvent(event) end
eventFrame:SetScript("OnEvent", function(self, event, ...)
	local h = handlers[event]
	if h then h(self, ...) end
end)

-- -----------------------------------------------------------------------------
-- /mnr slash command
-- -----------------------------------------------------------------------------
-- Slash command for quick toggling / repaint / diagnostics. Mirrors the
-- PersonalQOL POC's `/pqnpr` surface so muscle memory transfers.
SLASH_MNR1 = "/mnr"
SlashCmdList["MNR"] = function(msg)
	msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
	local R = addon.Recolor

	if msg == "on" then
		R:SetEnabled(true)
		print("|cff7fffd4[MNR]|r enabled")
		return
	elseif msg == "off" then
		R:SetEnabled(false)
		print("|cff7fffd4[MNR]|r disabled")
		return
	elseif msg == "paint" then
		R:RepaintAll()
		print("|cff7fffd4[MNR]|r repainted")
		return
	elseif msg == "debug on" then
		R.debug = true
		print("|cff7fffd4[MNR]|r live debug logging ON")
		return
	elseif msg == "debug off" then
		R.debug = false
		print("|cff7fffd4[MNR]|r live debug logging OFF")
		return
	elseif msg == "help" then
		print("|cff7fffd4[MNR]|r /mnr | on | off | paint | debug on | debug off")
		return
	end

	-- No args (or unknown) → status dump.
	print("|cff7fffd4[MNR]|r --- status ---")
	print("  enabled:        " .. tostring(R:IsEnabled()))
	print("  R.enabled flag: " .. tostring(R.enabled))
	print("  db present:     " .. tostring(addon.db ~= nil))

	local colorCount = 0
	if addon.db and addon.db.colors then
		for _ in pairs(addon.db.colors) do colorCount = colorCount + 1 end
	end
	print("  saved colors:   " .. colorCount)

	local instanceName, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
	local challengeMapID = addon.GetCurrentMapID and addon.GetCurrentMapID()
	print("  instanceName:   " .. tostring(instanceName))
	print("  instanceMapID:  " .. tostring(instanceMapID))
	print("  challengeMapID: " .. tostring(challengeMapID))
	print("  fingerprints:   " .. tostring(challengeMapID and addon.Fingerprints[challengeMapID] ~= nil))
	print("  dungeon name:   " .. tostring(challengeMapID and addon.Dungeons[challengeMapID] and addon.Dungeons[challengeMapID].name or "(unknown)"))

	local platerLoaded = type(_G.Plater) == "table" and type(_G.Plater.ChangeHealthBarColor_Internal) == "function"
	print("  plater:         " .. (platerLoaded and "yes" or "no")
		.. (platerLoaded and (R.platerHookInstalled and " (hook installed)" or " (hook pending)") or ""))

	local hostile = 0
	for i = 1, 40 do
		local u = "nameplate" .. i
		if UnitExists(u) and UnitCanAttack("player", u) and not UnitIsPlayer(u) then
			hostile = hostile + 1
			local d = addon.DebugIdentify(u) or {}
			local mob = d.mapID and addon.Dungeons[d.mapID] and addon.Dungeons[d.mapID].mobs[d.npcID]
			local colorKey = d.mapID and d.npcID and R:GetColorKey(d.mapID, d.npcID)
			local bp = C_NamePlate and C_NamePlate.GetNamePlateForUnit(u)
			local eui
			if bp then
				for _, child in ipairs({ bp:GetChildren() }) do
					if child._mixedIn and child.health then eui = child; break end
				end
			end
			local backend = "blizzard"
			if platerLoaded and bp and bp.unitFrame and bp.unitFrame.healthBar then
				backend = "plater"
			elseif eui then
				backend = "eui"
			end
			print(format("    %s fp=%s", u, tostring(d.base)))
			print(format("      ext=%s npcID=%s name=%s",
				tostring(d.ext),
				tostring(d.npcID or "(no match)"),
				tostring(mob or "?")))
			print(format("      color=%s backend=%s eui=%s hooked=%s buffs=%s",
				tostring(colorKey or "(unset)"),
				backend,
				eui and "yes" or "no",
				eui and eui._mnrHooked and "yes" or "no",
				tostring(d.buffs)))
		end
	end
	if hostile == 0 then print("  (no hostile nameplates visible)") end
end
