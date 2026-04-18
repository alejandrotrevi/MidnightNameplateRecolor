local addonName, addon = ...

-- Default per-mob colors for mobs with interruptible casts in Midnight S1 M+
-- dungeons. Source: MythicDungeonTools/Midnight/*.lua, every spell where
-- ["interruptible"] = true, graded by damage / impact.
--
--   EXTREME   = extremely important — heavy nuke, AoE damage, hard CC, heal,
--               add spawn, damage-reduction buff, or any boss-level cast.
--   IMPORTANT = important — filler single-target damage, single-target
--               debuff, self-empowerment buff, standard DoT.
--
-- Red is avoided for EXTREME because Blizzard's default hostile nameplate is
-- already red — orange is the next "high-danger" signal that stays visually
-- distinct from untagged mobs.
--
-- If a mob has casts in both tiers, the higher tier wins.
--
-- Applied once in Recolor:InitDB (gated by db.defaultsApplied). User picks in
-- the settings panel are preserved on subsequent logins; picking "Default" in
-- the dropdown still clears the color and won't bounce back to the preset.
-- ResetToDefaultColors() wipes all user picks and re-applies presets — used by
-- the "Reset to defaults" settings button.

local EXTREME   = "orange"
local IMPORTANT = "blue"

addon.DefaultColors = {
	-- Algeth'ar Academy
	[402] = {
		[196045] = IMPORTANT, -- Corrupted Manafiend — Surge
		[196044] = EXTREME, -- Unruly Textbook — Monotonous Lecture (AoE 8s stun)
		[196202] = IMPORTANT, -- Spectral Invoker — Arcane Bolt
	},

	-- Magisters' Terrace
	[558] = {
		[232369] = EXTREME, -- Arcane Magister — Polymorph (hard CC) + Arcane Bolt
		[251861] = EXTREME, -- Blazing Pyromancer — Pyroblast (4s heavy)
		[234064] = IMPORTANT, -- Dreaded Voidwalker — Shadow Bolt
		[249086] = EXTREME, -- Void Infuser — Terror Wave (AoE fear + root)
	},

	-- Maisara Caverns
	[560] = {
		[242964] = IMPORTANT, -- Keen Headhunter — Hooked Snare (root)
		[248685] = EXTREME, -- Ritual Hexxer — Hex (hard CC) + Shadow Bolt
		[254740] = IMPORTANT, -- Umbral Shadowbinder — Shrink (DoT debuff)
		[248692] = EXTREME, -- Reanimated Warrior — Reanimation (99% DR self-buff)
		[249036] = IMPORTANT, -- Tormented Shade — Spirit Rend
		[249024] = IMPORTANT, -- Hollow Soulrender — Shadowfrost Blast
		[253473] = IMPORTANT, -- Gloomwing Bat — Piercing Screech
		[248595] = EXTREME, -- Vordaza (boss) — Necrotic Convergence
	},

	-- Nexus-Point Xenas
	[559] = {
		[241644] = EXTREME, -- Corewright Arcanist — Arcane Explosion (channeled AoE)
		[248708] = IMPORTANT, -- Nexus Adept — Umbra Bolt
		[251853] = EXTREME, -- Grand Nullifier — Nullify (5s heavy)
		[254926] = IMPORTANT, -- Lightwrought — Holy Bolt
		[251031] = EXTREME, -- Wretched Supplicant — Nullify (5s heavy)
		[251568] = IMPORTANT, -- Fractured Image — Divine Guile
	},

	-- Pit of Saron
	[556] = {
		[252603] = EXTREME, -- Arcanist Cadaver — Netherburst (AoE 5s)
		[252567] = IMPORTANT, -- Gloombound Shadebringer — Shadow Bolt
		[252563] = EXTREME, -- Dreadpulse Lich — Icy Blast (4s heavy)
		[252606] = EXTREME, -- Plungetalon Gargoyle — Plungegrip (12s root DoT)
		[252566] = IMPORTANT, -- Rimebone Coldwraith — Ice Bolt
		[254691] = IMPORTANT, -- Scourge Plaguespreader — Plague Bolt
		[252621] = EXTREME, -- Krick (boss) — Death Bolt (10s massive nuke)
		[255037] = IMPORTANT, -- Shade of Krick (boss) — Shadowbind (DoT + slow)
	},

	-- The Seat of the Triumvirate
	[239] = {
		[122413] = EXTREME, -- Ruthless Riftstalker — Shadowmend (heal)
		[122404] = IMPORTANT, -- Dire Voidbender — Abyssal Enhancement (self-buff)
		[122405] = EXTREME, -- Dark Conjurer — Summon Voidcaller (add) + Umbral Bolt
		[122056] = EXTREME, -- Viceroy Nezhar (boss) — Mind Blast
		[125340] = EXTREME, -- Shadewing (boss) — Dread Screech (AoE + disorient)
	},

	-- Skyreach
	[161] = {
		[78932]  = IMPORTANT, -- Driving Gale-Caller — Repel (knockback)
		[79462]  = EXTREME, -- Blinding Sun Priestess — Blinding Light (AoE 5s stun)
		[79466]  = IMPORTANT, -- Initiate of the Rising Sun — Solar Bolt
		[76266]  = EXTREME, -- High Sage Viryx (boss) — Solar Blast
	},

	-- Windrunner Spire
	[557] = {
		[232070] = IMPORTANT, -- Restless Steward — Spirit Bolt
		[232171] = IMPORTANT, -- Ardent Cutthroat — Poison Blades (self-buff)
		[232175] = IMPORTANT, -- Devoted Woebringer — Shadow Bolt + Pulsing Shriek
		[236894] = IMPORTANT, -- Bloated Lasher — Fungal Bolt
		[232146] = EXTREME, -- Phantasmal Mystic — Chain Lightning (chain AoE)
		[231626] = EXTREME, -- Kalis (boss) — Shadow Bolt
	},
}

-- Seed user DB with default colors. Only fills npcIDs that don't already have
-- a saved color, so user picks are never overwritten. Called once per install
-- from Recolor:InitDB.
function addon.ApplyDefaultColors()
	local db = addon.db
	if not db then return end
	db.colors = db.colors or {}
	for mapID, mobs in pairs(addon.DefaultColors) do
		for npcID, paletteKey in pairs(mobs) do
			local key = tostring(mapID) .. ":" .. tostring(npcID)
			if db.colors[key] == nil then
				db.colors[key] = paletteKey
			end
		end
	end
end

-- Wipe all saved colors and re-apply the default color map. Used by the
-- "Reset to defaults" settings button — destructive, overwrites user picks.
function addon.ResetToDefaultColors()
	local db = addon.db
	if not db then return end
	db.colors = {}
	addon.ApplyDefaultColors()
end
