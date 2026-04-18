# Midnight Nameplate Recolor

Small WoW addon that lets you recolor hostile nameplates in Mythic+ dungeons, mob by mob. You open the settings, pick a color for whichever mob you want, and the addon paints that mob's healthbar whenever it shows up on your screen.

Same color sticks across Normal, Heroic, Mythic 0, and Mythic+ keys. One setup, and you're done for the season.

## Why this exists

Patch 12.0 brought the Secret Values system, which was Blizzard's big addon disarmament pass. A lot of the unit data addons used to read (names, GUIDs, creature type, spell IDs, you name it) went opaque inside instances. The old "if the mob is named X, color the nameplate red" pattern just stopped working for hostile units in M+.

So this addon is trying to solve one thing: give you back per-mob nameplate colors in M+, without stepping on any of the new rules.

## How it works

Even with Secret Values turned on, a handful of fields on hostile units are still plain-readable. The addon stitches six of them together into a "fingerprint" that ends up being unique (or close to it) per mob type:

- Model file ID, read off an offscreen `PlayerModel` probe after `SetUnit`
- Level mod 10, so the same mob on Normal/Heroic/M+ collapses to one key
- Classification (elite, normal, rare, and so on)
- Sex
- Class token (WARRIOR, PALADIN, etc.), assigned per mob by the server
- Power type (mana, rage, energy, or none)

Stitched with colons it looks like `6366139:0:elite:3:WARRIOR:1`. That string goes into a table keyed by Challenge Map ID, and what comes back is the mob's npcID. From there we look up whichever color you picked for that npcID and paint the nameplate.

Every now and then two different mobs hash to the same six-piece key (same model, same class assignment, everything). When that happens, the addon falls back to an extended key that tacks on the number of buffs the unit has. Buffs get counted with `C_UnitAuras.GetAuraDataByIndex` in a loop. The fields on the returned aura table are Secret, but a nil vs non-nil existence check is still allowed, so the count works without us ever actually reading anything off the aura.

## Painting the nameplate

If EllesmereUI is loaded, it owns the visible nameplate. Its pool plate gets parented to Blizzard's, and its own `.health` bar is what you actually see on screen. If you write to `plate.UnitFrame.healthBar` in that setup, nothing happens visually because Blizzard's default bar is hidden behind EUI's. So when EUI is around, the addon walks the children of Blizzard's plate, finds the EUI pool plate, and paints `euiPlate.health` directly. It also drops a post-hook on that plate's `UpdateHealthColor` so our color survives every time EUI repaints (threat changes, focus changes, that kind of thing).

No EUI? Then it just paints Blizzard's default health bar and calls it a day.

## Credits

Most of the credit here goes to the folks behind [**MythicPlusCount**](https://www.curseforge.com/wow/addons/mythic-plus-count). MPC is a Mythic+ trash counter, and to do its job it had to solve the exact same "how do I identify mobs under Secret Values" problem we did, just for a completely different reason (counting enemy forces toward the key total).

What we actually did was the research side: poking at which APIs were still plain-readable in Midnight, building a little probe addon to capture per-nameplate data in real dungeons, and figuring out what a reliable set of fingerprints might look like for Season 1. Somewhere in that process it became obvious that MPC had already shipped exactly the approach we were converging on, and their fingerprint tables were way more complete than anything we were going to assemble ourselves in a sane amount of time. So we dropped our own collection and ported theirs.

Stuff that came directly from MPC:

- The compound fingerprint formula
- The Challenge Map ID resolver (M+ active key path, plus the instance-name fallback for non-keystone runs)
- The extended-key buff-count tiebreaker
- The full per-dungeon fingerprint tables for Season 1
- The dungeon list and the npcID to mob-name mapping that drives the settings UI

Basically, none of this works without the legwork MPC's author did across a ton of live runs.

A couple of other addons also shaped how this was built:

- [**Mythic Dungeon Tools**](https://www.curseforge.com/wow/addons/mythic-dungeon-tools) for the per-dungeon NPC metadata (npcID, displayId, creatureType). Really handy while double-checking fingerprints and wrapping my head around display variants.
- [**EnhanceQoL**](https://www.curseforge.com/wow/addons/enhanceqol) (and [**EnhanceQoLSharedMedia**](https://www.curseforge.com/wow/addons/enhanceqolsharedmedia)) for the addon shape overall: how to wire up events, how to structure the settings panel, how SavedVariables and profiles get handled. Our settings panel is mostly a thin wrapper on their LibEQOL approach.

## Usage

1. Drop it in `Interface/AddOns`.
2. Log in, open the Blizzard settings panel, find "Midnight Nameplate Recolor".
3. Expand a dungeon, pick a color for whichever mob you care about.
4. Zone in, pull a pack. That mob should show up in your color.

There are 11 named colors in the palette. Picking "Default" (or just leaving a mob alone) means the nameplate stays whatever color EllesmereUI or Blizzard would normally give it.

## Slash commands

```
/mnr              status dump for the current instance and visible nameplates
/mnr on           enable recoloring
/mnr off          disable recoloring
/mnr paint        force a repaint on every visible plate
/mnr debug on     chat logging on every paint
/mnr debug off    stop the logging
/mnr help         show this command list
```

If something's acting weird, `/mnr` with no args is the first thing to run. It tells you which dungeon it thinks you're in, whether the Challenge Map ID resolved, and for each visible plate: what fingerprint it generated, which npcID that matched, and the color it would apply.

## Limitations

- Season 1 only for now. The fingerprint data is a snapshot of whatever MPC has at the moment. When Season 2 drops, the dungeon list will need updating, and honestly it's easiest to just wait for MPC to do their pass first.
- Fingerprints can drift between patches. If Blizzard swaps a model, rebalances a mob, or adds a new display variant, that mob's entry may go stale. Re-syncing with MPC each patch is the cheap way to stay current.
- If a mob's distinguishing buff is applied mid-combat (rather than pre-pull), the first paint might miss and show the wrong color for a frame or two. The per-plate hook re-fires fast though, so it corrects itself almost immediately.

## Compatibility

Built against Interface 120001 (Patch 12.0.1). Works on its own, and plays nicely with EllesmereUI when that's loaded.
