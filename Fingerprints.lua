local addonName, addon = ...

-- Compound fingerprints for Midnight Season 1 dungeons, ported verbatim from
-- MythicPlusCount/fingerprints.lua (MPC.DefaultFingerprints). Keys are in
-- MPC's format:
--   base: "modelFileID:level%10:classification:sex:classToken:powerType"
--   ext:  "<base>:buffCount"   (tiebreaker when two mobs share a base)
-- Values are npcIDs. Negative npcIDs are MPC's "custom" markers for mobs
-- whose real npcID is unknown — treat them as unique labels in the data.
--
-- At runtime Identify.lua builds the same strings from probed unit data and
-- looks them up here. Extended key wins over base when both match.

addon.Fingerprints = {
	[402] = { -- Algeth'ar Academy
		["1102558:0:elite:1:WARRIOR:1"] = 196694,
		["3952432:0:elite:1:WARRIOR:1"] = 196045,
		["3951256:0:elite:1:WARRIOR:1"] = 197406,
		["4077816:1:elite:1:WARRIOR:1"] = 192333,
		["4033880:1:elite:1:WARRIOR:1"] = 192680,
		["1100483:0:minus:1:WARRIOR:1"] = 192329,
		["4216711:0:elite:3:PALADIN:0"] = 196202,
		["617127:0:elite:1:WARRIOR:1"]  = 196044,
		["4217881:1:elite:3:WARRIOR:1"] = 196200,
		["1382579:0:elite:2:WARRIOR:1"] = 196577,
		["1722688:0:normal:1:WARRIOR:1"] = 197398,
		["1722688:1:elite:1:WARRIOR:1"]  = 197219,
		["4323766:1:elite:1:WARRIOR:1"]  = -63875, -- Vicious Ravager (MPC custom)
	},

	[560] = { -- Maisara Caverns
		["6875167:0:elite:3:WARRIOR:1"]    = 249036,
		["6875167:0:elite:3:WARRIOR:1:0"]  = 249036,
		["6875167:0:elite:3:PALADIN:0"]    = 254740,
		["6875167:0:elite:3:PALADIN:0:0"]  = 254740,
		["6366139:0:elite:3:WARRIOR:1"]    = 242964,
		["6366139:0:elite:3:WARRIOR:1:0"]  = 248693, -- Mire Laborer (0 buffs)
		["6366139:0:elite:3:WARRIOR:1:1"]  = 242964, -- Keen Headhunter (1 buff)
		["6366139:1:elite:3:PALADIN:0"]    = 248686,
		["6366141:0:elite:2:WARRIOR:1"]    = 248684,
		["6366141:1:elite:2:PALADIN:0"]    = 253458,
		["6366141:1:elite:2:PALADIN:0:0"]  = 253458,
		["1716306:0:elite:1:WARRIOR:1"]    = 248690,
		["1716306:0:elite:1:WARRIOR:1:0"]  = 248692, -- Reanimated Warrior (0 buffs)
		["1716306:0:elite:1:WARRIOR:1:1"]  = 248690, -- Grim Skirmisher
		["6875165:0:elite:2:PALADIN:0"]    = 248685,
		["6875165:1:elite:2:PALADIN:0"]    = 253683,
		["6875165:1:elite:2:PALADIN:0:0"]  = 253683,
		["6875165:0:elite:2:WARRIOR:1"]    = 249036,
		["6875165:0:elite:2:WARRIOR:1:0"]  = 249036,
		["7127711:1:elite:2:WARRIOR:1"]    = 249030,
		["7127711:1:elite:2:WARRIOR:1:1"]  = 249030,
		["4034801:1:elite:1:WARRIOR:1"]    = 248678,
		["1695668:1:elite:1:PALADIN:0"]    = 249024,
		["1695668:1:elite:1:PALADIN:0:0"]  = 249024,
		["804504:0:elite:1:WARRIOR:1"]     = 253473,
		["804504:0:elite:1:WARRIOR:1:0"]   = 253473,
		["6163242:0:elite:1:WARRIOR:1"]    = 249020,
		["1266661:0:elite:1:WARRIOR:1"]    = 249022,
		["1719446:1:elite:1:WARRIOR:1"]    = 249025,
		["1719446:1:elite:1:WARRIOR:1:1"]  = 249025,
		["124640:0:normal:1:WARRIOR:1"]    = 249002,
		["124640:0:normal:1:WARRIOR:1:1"]  = 249002,
		["124640:1:elite:1:PALADIN:0"]     = 253302,
	},

	[239] = { -- The Seat of the Triumvirate
		["6152557:0:elite:3:PALADIN:0"]    = 122404,
		["6152557:0:elite:3:PALADIN:0:0"]  = 122404,
		["6152557:0:elite:3:PALADIN:0:1"]  = 122405, -- Dark Conjurer (1 buff)
		["6152557:1:elite:3:PALADIN:0"]    = 122423,
		["6152557:1:elite:3:PALADIN:0:0"]  = 122423,
		["6152557:0:elite:3:WARRIOR:1"]    = 122403,
		["1572365:0:elite:2:WARRIOR:1"]    = 122413,
		["1572365:0:elite:2:WARRIOR:1:0"]  = 122413,
		["5926159:1:elite:2:WARRIOR:1"]    = 122421,
		["5926159:1:elite:2:WARRIOR:1:0"]  = 122421,
		["6705352:1:elite:1:WARRIOR:1"]    = 122571,
		["6705352:1:elite:1:WARRIOR:1:1"]  = 122571,
		["6254042:1:elite:1:WARRIOR:1"]    = 252756,
		["6254042:1:elite:1:WARRIOR:1:0"]  = 252756,
		["1574725:0:normal:0:?:-1:0"]      = 255320,
		["1570694:0:elite:1:WARRIOR:1"]    = 255320,
		["1574725:0:normal:1:WARRIOR:1"]   = 122322,
		["1572377:1:elite:3:PALADIN:0"]    = 124171,
	},

	[557] = { -- Windrunner Spire
		["1100258:0:elite:3:WARRIOR:1"]    = 232070,
		["1100087:0:elite:2:WARRIOR:1"]    = 232071,
		["1100087:1:elite:2:PALADIN:0"]    = 232113,
		["6251997:1:elite:1:PALADIN:0"]    = 232122,
		["997378:0:elite:3:WARRIOR:1"]     = 232173,
		["959310:0:elite:2:WARRIOR:1"]     = 232171,
		["1252028:1:elite:3:WARRIOR:1"]    = 232175,
		["1598184:1:elite:1:WARRIOR:1"]    = 232176,
		["6119019:0:elite:1:WARRIOR:1"]    = 232056,
		["1513629:0:normal:1:WARRIOR:1"]   = 234673,
		["1513629:0:elite:1:WARRIOR:1"]    = 232067,
		["6338575:1:elite:1:WARRIOR:1"]    = 232063,
		["5095674:0:normal:1:WARRIOR:1"]   = 238099,
		["5095674:1:elite:1:ROGUE:3"]      = 236894,
		["1373320:0:elite:1:WARRIOR:1"]    = 232283,
		["6366139:0:elite:3:WARRIOR:1"]    = 232148,
		["930099:1:elite:2:PALADIN:0"]     = 232146,
		["917116:0:elite:2:WARRIOR:1"]     = 258868,
	},

	[559] = { -- Nexus-Point Xenas
		["6152557:0:elite:3:WARRIOR:1"]    = 241643,
		["6152557:0:elite:3:WARRIOR:1:1"]  = 241643,
		["6152557:0:elite:3:PALADIN:0"]    = 241644,
		["6152557:0:elite:3:PALADIN:0:1"]  = 241644,
		["6377937:0:elite:1:WARRIOR:1"]    = 241645,
		["6377937:0:elite:1:WARRIOR:1:1"]  = 241645,
		["5926159:0:elite:2:WARRIOR:1"]    = 241647,
		["5926159:0:elite:2:WARRIOR:1:1"]  = 241647,
		["5926159:0:normal:2:PALADIN:0"]   = 248708,
		["5926159:0:normal:2:PALADIN:0:0"] = 248708,
		["5926159:1:elite:1:MAGE:0"]       = 248373,
		["5926159:1:elite:1:MAGE:0:1"]     = 248373,
		["6705352:0:normal:1:PALADIN:0"]   = 248706,
		["6705352:0:normal:1:PALADIN:0:1"] = 248706,
		["6705352:0:elite:1:PALADIN:0"]    = 251853,
		["6705352:0:elite:1:PALADIN:0:1"]  = 251853,
		["6181818:1:elite:1:WARRIOR:1"]    = 248506,
		["6181818:1:elite:1:WARRIOR:1:0"]  = 248506,
		["6181816:1:elite:1:MAGE:0"]       = 241660,
		["6181816:1:elite:1:MAGE:0:0"]     = 241660,
		["6181814:1:elite:1:WARRIOR:1"]    = 248502,
		["6181814:1:elite:1:WARRIOR:1:0"]  = 248502,
		["6730408:1:elite:2:PALADIN:0"]    = 241642,
		["6730408:1:elite:2:PALADIN:0:0"]  = 241642,
		["124640:0:minus:1:WARRIOR:1"]     = 254932,
		["124640:0:minus:1:WARRIOR:1:1"]   = 254932,
		["3952432:0:elite:1:WARRIOR:1"]    = 254926,
		["3952432:0:elite:1:WARRIOR:1:0"]  = 254926,
		["2966279:0:normal:1:WARRIOR:1"]   = 254928,
		["2966279:0:normal:1:WARRIOR:1:1"] = 254928,
		["7344962:0:normal:1:WARRIOR:1"]   = 248501,
		["7344962:0:normal:1:WARRIOR:1:1"] = 248501,
	},

	[161] = { -- Skyreach
		["986699:0:elite:1:WARRIOR:1"]     = 76132,
		["986699:0:elite:1:PALADIN:0"]     = 78932,
		["986699:1:elite:1:WARRIOR:1"]     = 79303,
		["1033563:0:elite:1:WARRIOR:1"]    = 75976,
		["1000727:1:elite:1:PALADIN:0"]    = 76087,
		["3952432:1:elite:1:PALADIN:0"]    = 78933,
		["1031301:1:normal:1:WARRIOR:1"]   = 79093,
		["948417:1:elite:1:WARRIOR:1"]     = 76149,
		["3946582:0:elite:1:ROGUE:3"]      = 250992,
		["353152:0:elite:1:ROGUE:3"]       = 253963, -- Outcast Warrior (MPC custom)
	},

	[556] = { -- Pit of Saron
		["3087468:0:elite:2:WARRIOR:1"]    = 252551,
		["3487358:0:elite:2:PALADIN:0"]    = 252566,
		["3487358:0:elite:2:WARRIOR:1"]    = 252561,
		["1574421:0:elite:1:WARRIOR:1"]    = 252558,
		["125234:0:normal:1:WARRIOR:1"]    = 252559,
		["122815:1:elite:2:WARRIOR:1"]     = 252610,
		["124131:0:elite:3:WARRIOR:1"]     = 252606,
		["3197237:0:elite:1:WARRIOR:1"]    = 252555,
		["4672491:1:elite:1:WARRIOR:1"]    = 257190,
		["3482565:1:elite:2:WARRIOR:1"]    = 252563,
		["1709401:1:elite:1:WARRIOR:1"]    = 252564,
	},

	[558] = { -- Magisters' Terrace
		["1100258:0:elite:3:PALADIN:0"]    = 232369,
		["1100258:1:elite:3:PALADIN:0"]    = 251861, -- also covers Runed Spellbreaker (shared)
		["1100087:0:elite:2:WARRIOR:1"]    = 234124,
		["1100087:0:elite:2:PALADIN:0"]    = 234486,
		["6705352:1:elite:1:ROGUE:3"]      = 234068,
		["1410362:1:elite:1:WARRIOR:1"]    = 234066,
		["3087474:0:elite:1:PALADIN:0"]    = 234064,
		["7344962:0:normal:1:WARRIOR:1"]   = 234069,
		["6316091:1:elite:1:ROGUE:3"]      = 234062,
		["6253063:0:normal:1:PALADIN:0"]   = 232106,
		["1102558:0:normal:1:PALADIN:0"]   = 241354,
		["6377937:0:elite:1:WARRIOR:1"]    = 257447,
		["3034257:0:elite:1:PALADIN:0"]    = -21937, -- Void Terror (MPC custom)
		["7464966:0:normal:1:ROGUE:3"]     = 245325, -- Spellwoven Familiar (MPC custom)
	},
}
