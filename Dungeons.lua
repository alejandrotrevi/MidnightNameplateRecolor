local addonName, addon = ...

-- Midnight Season 1 dungeons, mobs ported verbatim from MythicPlusCount's
-- data.lua. mapID is the ChallengeMapID (also usable as the `currentMapID`
-- 8th return of GetInstanceInfo in dungeons — MPC uses it the same way).
--
-- Structure:
--   addon.Dungeons = {
--       [mapID] = { name = "...", mobs = { [npcID] = "Name", ... } }
--   }
--
-- Source of truth: MythicPlusCount/data.lua. When MPC updates for new seasons
-- regenerate this file from that source.

addon.Dungeons = {
	[402] = {
		name = "Algeth'ar Academy",
		mobs = {
			[196045] = "Corrupted Manafiend",
			[196577] = "Spellbound Battleaxe",
			[196671] = "Arcane Ravager",
			[196694] = "Arcane Forager",
			[196044] = "Unruly Textbook",
			[192680] = "Guardian Sentry",
			[192329] = "Territorial Eagle",
			[192333] = "Alpha Eagle",
			[197406] = "Aggravated Skitterfly",
			[197219] = "Vile Lasher",
			[197398] = "Hungry Lasher",
			[196200] = "Algeth'ar Echoknight",
			[196202] = "Spectral Invoker",
			[194181] = "Vexamus (boss)",
			[191736] = "Crawth (boss)",
			[196482] = "Overgrown Ancient (boss)",
			[190609] = "Echo of Doragosa (boss)",
		},
	},

	[560] = {
		name = "Maisara Caverns",
		mobs = {
			[248684] = "Frenzied Berserker",
			[242964] = "Keen Headhunter",
			[248686] = "Dread Souleater",
			[248685] = "Ritual Hexxer",
			[249020] = "Hexbound Eagle",
			[253302] = "Hex Guardian",
			[249002] = "Warding Mask",
			[249022] = "Bramblemaw Bear",
			[248693] = "Mire Laborer",
			[248678] = "Hulking Juggernaut",
			[254740] = "Umbral Shadowbinder",
			[249030] = "Restless Gnarldin",
			[248692] = "Reanimated Warrior",
			[248690] = "Grim Skirmisher",
			[249036] = "Tormented Shade",
			[253683] = "Rokh'zal",
			[249025] = "Bound Defender",
			[249024] = "Hollow Soulrender",
			[253458] = "Zil'jan",
			[253473] = "Gloomwing Bat",
			[250443] = "Unstable Phantom",
			[251047] = "Soulbind Totem",
			[253701] = "Death's Grasp",
			[254233] = "Rokh'zal (spawn)",
			[247570] = "Muro'jin (boss)",
			[247572] = "Nekraxx (boss)",
			[248595] = "Vordaza (boss)",
			[248605] = "Rak'tul (boss)",
		},
	},

	[239] = {
		name = "The Seat of the Triumvirate",
		mobs = {
			[124171] = "Merciless Subjugator",
			[122571] = "Rift Warden",
			[122413] = "Ruthless Riftstalker",
			[255320] = "Ravenous Umbralfin",
			[122421] = "Umbral War-Adept",
			[122404] = "Dire Voidbender",
			[252756] = "Void-Infused Destroyer",
			[122423] = "Grand Shadow-Weaver",
			[122322] = "Famished Broken",
			[122403] = "Shadowguard Champion",
			[122405] = "Dark Conjurer",
			[122412] = "Bound Voidcaller",
			[122716] = "Coalesced Void",
			[122827] = "Umbral Tentacle",
			[125340] = "Shadewing",
			[255551] = "Depravation Wave Stalker",
			[256424] = "Void Tentacle",
			[122313] = "Zuraal the Ascended (boss)",
			[122316] = "Saprish (boss)",
			[122319] = "Darkfang (boss)",
			[122056] = "Viceroy Nezhar (boss)",
			[124729] = "L'ura (boss)",
		},
	},

	[557] = {
		name = "Windrunner Spire",
		mobs = {
			[232070] = "Restless Steward",
			[232071] = "Dutiful Groundskeeper",
			[232113] = "Spellguard Magus",
			[232116] = "Windrunner Soldier",
			[232173] = "Fervent Apothecary",
			[232171] = "Ardent Cutthroat",
			[232232] = "Zealous Reaver",
			[232175] = "Devoted Woebringer",
			[232176] = "Flesh Behemoth",
			[232056] = "Territorial Dragonhawk",
			[234673] = "Spindleweb Hatchling",
			[232067] = "Creeping Spindleweb",
			[232063] = "Apex Lynx",
			[238099] = "Pesty Lashling",
			[236894] = "Bloated Lasher",
			[238049] = "Scouting Trapper",
			[232119] = "Swiftshot Archer",
			[232122] = "Phalanx Breaker",
			[232283] = "Loyal Worg",
			[232147] = "Lingering Marauder",
			[232148] = "Spectral Axethrower",
			[232146] = "Phantasmal Mystic",
			[258868] = "Haunting Grunt",
			[250883] = "Scouting Trapper (spawn)",
			[232118] = "Flaming Updraft",
			[232121] = "Phalanx Breaker (2)",
			[231606] = "Emberdawn (boss)",
			[231626] = "Kalis (boss)",
			[231629] = "Latch (boss)",
			[231631] = "Commander Kroluk (boss)",
			[231636] = "Restless Heart (boss)",
		},
	},

	[559] = {
		name = "Nexus-Point Xenas",
		mobs = {
			[241643] = "Shadowguard Defender",
			[248501] = "Reformed Voidling",
			[241644] = "Corewright Arcanist",
			[241645] = "Hollowsoul Scrounger",
			[241647] = "Flux Engineer",
			[248708] = "Nexus Adept",
			[248373] = "Circuit Seer",
			[248706] = "Cursed Voidcaller",
			[248506] = "Dreadflail",
			[241660] = "Duskfright Herald",
			[251853] = "Grand Nullifier",
			[248502] = "Null Sentinel",
			[241642] = "Lingering Image",
			[254932] = "Radiant Swarm",
			[254926] = "Lightwrought",
			[254928] = "Flarebat",
			[248769] = "Smudge",
			[250299] = "Conduit Stalker",
			[251024] = "Null Guardian",
			[251031] = "Wretched Supplicant",
			[251568] = "Fractured Image",
			[251852] = "Nullifier",
			[251878] = "Voidcaller",
			[252825] = "Mana Battery",
			[252852] = "Corespark Conduit",
			[254227] = "Corewarden Nysarra (spawn)",
			[254459] = "Broken Pipe",
			[254485] = "Corespark Pylon",
			[255179] = "Fractured Image (2)",
			[259569] = "Mana Battery (2)",
			[249711] = "Core Technician",
			[241539] = "Kasreth (boss)",
			[241542] = "Corewarden Nysarra (boss)",
			[241546] = "Lothraxion (boss)",
		},
	},

	[161] = {
		name = "Skyreach",
		mobs = {
			[76132]  = "Soaring Chakram Master",
			[78932]  = "Driving Gale-Caller",
			[250992] = "Raging Squall",
			[75976]  = "Lowborn Servant",
			[79462]  = "Blinding Sun Priestess",
			[79466]  = "Initiate of the Rising Sun",
			[79467]  = "Adept of the Dawn",
			[78933]  = "Solar Elemental",
			[76087]  = "Solar Construct",
			[79093]  = "Suntalon",
			[76154]  = "Suntalon Tamer",
			[76149]  = "Dread Raven",
			[76205]  = "Outcast Warrior",
			[76227]  = "Sunwing",
			[76285]  = "Arakkoa Magnifying Glass",
			[79303]  = "Adorned Bladetalon",
			[251880] = "Solar Orb",
			[253963] = "Outcast Warrior (custom)",
			[75964]  = "Ranjit (boss)",
			[76141]  = "Araknath (boss)",
			[76142]  = "Skyreach Sun Construct Prototype (boss)",
			[76143]  = "Rukhran (boss)",
			[76266]  = "High Sage Viryx (boss)",
		},
	},

	[556] = {
		name = "Pit of Saron",
		mobs = {
			[252551] = "Deathwhisper Necrolyte",
			[252602] = "Risen Soldier",
			[252603] = "Arcanist Cadaver",
			[252567] = "Gloombound Shadebringer",
			[252561] = "Quarry Tormentor",
			[252563] = "Dreadpulse Lich",
			[252558] = "Rotting Ghoul",
			[252610] = "Ymirjar Graveblade",
			[252559] = "Leaping Geist",
			[252606] = "Plungetalon Gargoyle",
			[252555] = "Lumbering Plaguehorror",
			[257190] = "Iceborn Proto-Drake",
			[252565] = "Wrathbone Enforcer",
			[252566] = "Rimebone Coldwraith",
			[252564] = "Glacieth",
			[254684] = "Rotling",
			[254691] = "Scourge Plaguespreader",
			[252621] = "Krick (boss)",
			[252625] = "Ick (boss)",
			[252635] = "Forgemaster Garfrost (boss)",
			[252648] = "Scourgelord Tyrannus (boss)",
			[252653] = "Rimefang (boss)",
			[255037] = "Shade of Krick (boss)",
		},
	},

	[558] = {
		name = "Magisters' Terrace",
		mobs = {
			[232369] = "Arcane Magister",
			[234089] = "Animated Codex",
			[251861] = "Blazing Pyromancer",
			[240973] = "Runed Spellbreaker",
			[234069] = "Voidling",
			[234065] = "Hollowsoul Shredder",
			[234064] = "Dreaded Voidwalker",
			[234068] = "Shadowrift Voidcaller",
			[234066] = "Devouring Tyrant",
			[249086] = "Void Infuser",
			[232106] = "Brightscale Wyrm",
			[234062] = "Arcane Sentry",
			[234067] = "Vigilant Librarian",
			[234124] = "Sunblade Enforcer",
			[234486] = "Lightward Healer",
			[241354] = "Void-Infused Brightscale",
			[255376] = "Unstable Voidling",
			[257447] = "Hollowsoul Shredder (variant)",
			[259387] = "Spellwoven Familiar",
			[231861] = "Arcanotron Custos (boss)",
			[231863] = "Seranel Sunlash (boss)",
			[231864] = "Gemellus (boss)",
			[231865] = "Degentrius (boss)",
			[239636] = "Gemellus (spawn)",
			[241397] = "Celestial Drifter (boss)",
		},
	},
}

-- Sorted list of dungeon mapIDs (for stable UI order — dungeons sorted by name).
addon.DungeonOrder = {}
do
	for mapID in pairs(addon.Dungeons) do
		addon.DungeonOrder[#addon.DungeonOrder + 1] = mapID
	end
	table.sort(addon.DungeonOrder, function(a, b)
		return addon.Dungeons[a].name < addon.Dungeons[b].name
	end)
end

-- For a given dungeon mapID, return a list of npcIDs sorted alphabetically by name.
function addon.GetDungeonMobOrder(mapID)
	local d = addon.Dungeons[mapID]
	if not d then return {} end
	local ids = {}
	for id in pairs(d.mobs) do ids[#ids + 1] = id end
	table.sort(ids, function(a, b) return d.mobs[a] < d.mobs[b] end)
	return ids
end
