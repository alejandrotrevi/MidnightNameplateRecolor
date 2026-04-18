# Midnight Nameplate Recolor

A small World of Warcraft addon that recolors hostile nameplates in Mythic+ dungeons by mob identity. You pick a color per mob in the settings panel, and the addon paints their healthbar that color whenever you see them.

Works on Normal, Heroic, Mythic 0, and Mythic+ keystones. Same dungeon, same mob, same color across all difficulties.

## Why this exists

Patch 12.0 introduced the Secret Values system, which was Blizzard's big addon disarmament pass. A bunch of unit data that used to be readable (names, GUIDs, creature type, spell IDs, and so on) became opaque inside instances. The classic "if the mob is named X, color the nameplate red" code path stopped working for hostile units in M+.

The goal of this addon is narrow: give back the ability to color trash mobs by identity in M+ dungeons, within the rules of what addons are still allowed to do.

## How it works

Even with Secret Values in place, a handful of fields stay plain-readable for hostile units in instances. This addon combines six of them into a compound "fingerprint" that is unique, or close enough to unique, for each mob type:

- Model file ID (read from an offscreen `PlayerModel` probe after calling `SetUnit`)
- Level modulo 10, so the same mob on Normal, Heroic and M+ maps to the same key
- Classification (elite, normal, rare, etc.)
- Sex
- Class token (WARRIOR, PALADIN, etc.), assigned per-mob by the server
- Power type (mana, rage, energy, or none)

Joined with colons that looks like `6366139:0:elite:3:WARRIOR:1`. The addon looks this up in a table keyed by Challenge Map ID and gets the mob's npcID back. Then it looks up whatever color you picked for that npcID in your settings and paints the nameplate.

When two mobs happen to collide on the six-dimension key (same model, same class assignment, everything), the addon falls back to an extended key that appends the number of buffs currently on the unit. Buffs are counted with `C_UnitAuras.GetAuraDataByIndex` in a loop. Every field on the returned aura table is Secret, but the nil-vs-non-nil existence check is allowed, so we count auras without reading anything off them.

## Painting the nameplate

If EllesmereUI is loaded it owns the visible nameplate. Its pool plate gets parented to the Blizzard nameplate, and its own `.health` bar is what you actually see. Writing to `plate.UnitFrame.healthBar` in that case does nothing visible, because Blizzard's default bar is hidden underneath. So when EUI is present the addon walks the Blizzard plate's children, finds the pool plate, and paints `euiPlate.health` directly. It also installs a post-hook on that plate's `UpdateHealthColor` so our color survives EUI's periodic repaints (threat, faction, focus change, and so on).

Without EllesmereUI the fallback is just Blizzard's default health bar.

## Credits

Most of the credit for this addon goes to the authors of [**MythicPlusCount**](https://www.curseforge.com/wow/addons/mythic-plus-count). MPC is a Mythic+ trash counter that had to solve the exact same mob identification problem we did, for its own reasons (counting forces toward the keystone total).

Our own work was the research: digging into what APIs were still plain-readable under Secret Values, building a probe addon to capture per-nameplate data, and trying to assemble a reliable set of fingerprints for the Season 1 dungeons. Once we got deep enough to understand the problem, we realized MPC had already shipped exactly the approach we were converging on, and their fingerprint tables were broader and better validated than anything we were going to collect in a reasonable amount of time. So we stopped collecting and ported theirs.

Specifically, the following came from MPC:

- The compound fingerprint formula
- The Challenge Map ID resolver (Mythic+ active key path plus the instance-name fallback for non-keystone runs)
- The extended-key buff-count tiebreaker
- The full per-dungeon fingerprint tables for Season 1
- The dungeon list and the npcID to mob-name mapping that populates the settings UI

None of this works without their empirical collection effort across many live runs.

We also leaned on two other addons for shape and context:

- [**Mythic Dungeon Tools**](https://www.curseforge.com/wow/addons/mythic-dungeon-tools) for per-dungeon NPC metadata (npcID, displayId, creatureType). Useful while sanity-checking fingerprints and understanding display variants.
- [**EnhanceQoL**](https://www.curseforge.com/wow/addons/enhanceqol) and its companion [**EnhanceQoLSharedMedia**](https://www.curseforge.com/wow/addons/enhanceqolsharedmedia) for the overall addon shape: event-driven lifecycle, settings panel patterns, SavedVariables and profile handling. Our settings panel is a thin layer on top of the LibEQOL approach.

## Usage

1. Install into `Interface/AddOns`.
2. Log in, open the Blizzard settings panel, and find "Midnight Nameplate Recolor".
3. Expand a dungeon, pick a color for any mob from the dropdown.
4. Enter the dungeon. Pull a pack. That mob's healthbar is the color you picked.

The palette has 11 named colors. Picking "Default" (or leaving it alone) means the nameplate uses whatever color EllesmereUI or Blizzard would normally show.

## Slash commands

```
/mnr              status dump for the current instance and visible nameplates
/mnr on           enable recoloring
/mnr off          disable recoloring
/mnr paint        force a repaint pass on every visible plate
/mnr debug on     per-paint logging in chat
/mnr debug off    stop logging
/mnr help         command list
```

`/mnr` with no arguments is the first thing to run when something isn't behaving. It reports which dungeon you're in, whether the Challenge Map ID resolved, and for each visible plate the fingerprint it produced, the npcID it matched (if any), and the color that would apply.

## Limitations

- Season 1 only for now. The fingerprint data is a snapshot of what MPC has at the moment. When Season 2 ships the dungeon list will need to be updated, ideally after MPC does their own pass.
- Fingerprints can drift across patches. Model swaps, rebalancing, or new display variants can invalidate individual entries. Re-syncing with MPC each patch is the cheap fix.
- A mob whose distinguishing buff is applied mid-combat (rather than pre-pull) may flash the wrong color for a frame or two before the per-plate hook corrects it.

## Compatibility

Built against Interface 120001 (Patch 12.0.1). Works standalone, and integrates with EllesmereUI when that addon is loaded.
