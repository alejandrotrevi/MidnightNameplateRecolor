# Midnight Nameplate Recolor — Agent Handoff

> Addon that recolors hostile nameplates in WoW Midnight (Patch 12.0.1) Season 1 dungeons by mob identity, working around the "Secret Values" addon-disarmament rules. Users pick a color per mob from a dropdown in the settings panel; the addon identifies mobs at runtime via a compound fingerprint and paints their healthbar accordingly.

This doc is the onboarding for the **next agent** — or future-you — to pick up this addon without re-walking every dead end we already buried. Sections:

1. [What the addon does](#what-the-addon-does)
2. [File layout](#file-layout)
3. [Runtime flow](#runtime-flow)
4. [How identification works](#how-identification-works)
5. [How painting works](#how-painting-works)
6. [Inspiration & credits](#inspiration--credits)
7. [Data sources + collection pipeline](#data-sources--collection-pipeline)
8. [Hard-won gotchas](#hard-won-gotchas)
9. [Secret Values cheatsheet](#secret-values-cheatsheet)
10. [MCP servers for research](#mcp-servers-for-research)
11. [Adding a new dungeon / season](#adding-a-new-dungeon--season)
12. [Debugging / slash commands](#debugging--slash-commands)
13. [Known limitations](#known-limitations)

---

## What the addon does

WoW Midnight introduced the "Secret Values" system (see [workspace CLAUDE.md § WoW Midnight API Reference](../CLAUDE.md)) which makes `UnitName`, `UnitGUID`, `UnitCreatureType`, spell/cast IDs, and most per-unit identity data *Secret* for hostile units inside instances. Addons can't read those values to drive logic, so the traditional "if this mob is named X, color the nameplate red" code path is dead.

This addon sidesteps that by identifying mobs via a **compound fingerprint** of fields that *are* still plain in instances:

```
modelFileID : (level % 10) : classification : sex : classToken : powerType [: buffCount]
```

Every dimension is readable. Combined, they uniquely identify ~95% of Midnight Season 1 M+ trash; the `buffCount` suffix breaks ties between NPCs that share the first six dimensions.

User experience:

- Open settings → expand *Maisara Caverns* → pick "Red" for Hulking Juggernaut.
- Enter the dungeon, pull a pack. Juggernaut's healthbar is red.
- Works across Normal / Heroic / Mythic 0 / M+ keystones — same dungeon, same color.

---

## File layout

```
MidnightNameplateRecolor/
├── MidnightNameplateRecolor.toc     # Interface 120001, SavedVariables, load order
├── Init.lua                          # addon namespace (addon.functions, etc.)
├── Palette.lua                       # 11 named colors + dropdown helpers
├── Dungeons.lua                      # 8 Season 1 dungeons, npcID → mob name
├── Fingerprints.lua                  # verbatim port of MPC DefaultFingerprints
├── Identify.lua                      # probe + fingerprint builder + mapID resolver
├── Recolor.lua                       # event wiring, per-plate EUI hook, paint
├── MidnightNameplateRecolor.lua      # ADDON_LOADED/PLAYER_LOGIN lifecycle + /mnr
├── Settings/
│   ├── SettingsUI.lua                # thin LibEQOL wrappers (our PREFIX = MNR_)
│   └── Settings.lua                  # build the UI tree (globals + per-dungeon)
└── libs/
    ├── LibStub/                      # copied from PersonalQOL/libs/
    ├── CallbackHandler-1.0/
    └── LibEQOL/                      # renamed PQOL_ → MNR_ to avoid collision
```

Load order is in `MidnightNameplateRecolor.toc`. Libs first, then data → identify → paint → lifecycle → settings.

---

## Runtime flow

```
ADDON_LOADED (once)
  └── bind MidnightNameplateRecolorDB
  └── Recolor:InitDB()            # defaults: enabled=true, colors={}

PLAYER_LOGIN (once)
  ├── addon.functions.InitSettings()   # build the Blizzard settings panel
  └── Recolor:OnEnabledChanged(true)   # registers nameplate events, hooks visible plates

NAME_PLATE_UNIT_ADDED (hundreds of times/session)
  ├── findEUIPlate(blizzardPlate)      # walk children for the EUI pool plate
  ├── hooksecurefunc(euiPlate, "UpdateHealthColor", ...)   # ONCE per plate
  └── PaintUnit(unit)                  # identify + color lookup + paint

PaintUnit(unit)
  ├── Identify(unit) → (mapID, npcID) | nil
  ├── GetColorKey(mapID, npcID) → palette key | nil
  ├── GetPaletteColor(key) → r, g, b | nil
  └── paintHealthBar(bp, r, g, b)      # euiPlate.health, falls back to Blizzard

EUI's UpdateHealthColor fires repeatedly (threat, faction, focus change)
  └── our post-hook re-paints so our color wins over EUI's color ladder
```

`PLAYER_ENTERING_WORLD` flushes the per-unit identity cache and the resolved ChallengeMapID so zoning works cleanly. `NAME_PLATE_UNIT_REMOVED` drops the unit from the cache.

---

## How identification works

### The 6-dimension base fingerprint

`Identify.lua:buildFingerprints` reads every dimension with a `safeRead` pcall guard:

| Dimension | API | Plain? | Notes |
|---|---|---|---|
| `modelFileID` | `PlayerModel:GetModelFileID()` after `SetUnit(unit)` | yes | Research confirmed |
| `level % 10` | `UnitLevel(unit)` | yes | Relative level matches across difficulties (90 / 91 / 92 → 0 / 1 / 2) |
| `classification` | `UnitClassification(unit)` | yes | `"elite"` / `"normal"` / `"minus"` / `"rare"` / `"worldboss"` |
| `sex` | `UnitSex(unit)` | yes | 0 / 1 / 2 / 3 |
| `classToken` | `select(2, UnitClass(unit))` | yes | `"WARRIOR"` / `"PALADIN"` / `"MAGE"` / `"ROGUE"` — per-mob class assignment (not "all warriors" as older research assumed) |
| `powerType` | `UnitPowerType(unit)` | yes | 0 (mana) / 1 (rage) / 3 (energy) / -1 (no power) |

Joined with colons: `"6366139:0:elite:3:WARRIOR:1"`. Lookup in `addon.Fingerprints[mapID][key] → npcID`.

### The extended fingerprint (buff-count tiebreaker)

Two NPCs can share the same 6-tuple. Example from Maisara:

```
Keen Headhunter  → 6366139:0:elite:3:WARRIOR:1  + 1 buff (Regeneratin')
Mire Laborer     → 6366139:0:elite:3:WARRIOR:1  + 0 buffs
```

Same model, same level, same class assignment. Differentiated by aura count. We build an extended key `<base>:<buffCount>` and look it up *before* the base — ext wins when both exist.

Counting buffs uses `C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")` in a loop with `pcall`. The returned `AuraData` table's fields are Secret in instances, but `if aura then` is a legal nil-vs-non-nil existence check per the Secret Values rules. We don't touch any field on the table — only count that one exists.

### ChallengeMapID vs instance mapID

The hardest bug we hit: `GetInstanceInfo()`'s 8th return is the **instance** mapID (e.g. `2874` for Maisara), but MPC's fingerprints are keyed by **ChallengeMapID** (e.g. `560`). Two completely unrelated WoW concepts with confusingly similar names.

`Identify.lua:currentMapID()` resolves the ChallengeMapID via two paths, matching [MythicPlusCount/util.lua:286-324](../MythicPlusCount/util.lua#L286):

1. `C_ChallengeMode.GetActiveChallengeMapID()` — works inside M+ keystones.
2. Otherwise: match `GetInstanceInfo()`'s first return (instance name string) against `addon.Dungeons[*].name`. Exact match first, then case-insensitive substring fallback (for "The Seat of the Triumvirate" vs "Seat of the Triumvirate" variants).

Cached in `resolvedMapID`; cleared on `PLAYER_ENTERING_WORLD`.

---

## How painting works

### EllesmereUI is the real target

EllesmereUI doesn't skin Blizzard's nameplate — it creates its own pool plate, parents it to the Blizzard one (`self:SetParent(nameplate)` at [EllesmereUINameplates.lua:3025](../EllesmereUI/EllesmereUINameplates/EllesmereUINameplates.lua#L3025)), mounts its own `.health` status bar, and hides Blizzard's default bar underneath. Writing `blizzardPlate.UnitFrame.healthBar:SetStatusBarColor(r, g, b)` when EUI is loaded does nothing visible — you'd be painting the hidden bar.

`Recolor.lua:findEUIPlate(blizzardPlate)` walks the Blizzard plate's children for one with `_mixedIn + .health + .UpdateHealthColor` (the fields EUI's Mixin stamps onto each pool plate at [EllesmereUINameplates.lua:4744](../EllesmereUI/EllesmereUINameplates/EllesmereUINameplates.lua#L4744)). When found, we paint `euiPlate.health:SetStatusBarColor(r, g, b)`.

Without EUI we fall back to `blizzardPlate.UnitFrame.healthBar`. The addon works standalone, it just doesn't need the per-plate hook in that case because nothing overwrites our color.

### Per-plate `hooksecurefunc`

The gotcha that cost us an evening: `NameplateFrame` is declared `local NameplateFrame = {}` at [EllesmereUINameplates.lua:3021](../EllesmereUI/EllesmereUINameplates/EllesmereUINameplates.lua#L3021) — **file-local**, not a global. `hooksecurefunc(_G.NameplateFrame, "UpdateHealthColor", fn)` silently does nothing because `_G.NameplateFrame` is nil.

`Mixin()` at line 4744 copies the function reference onto each pool plate individually. The only workable hook is on each plate:

```lua
hooksecurefunc(euiPlate, "UpdateHealthColor", function(self)
    NPR:PaintUnit(self.unit)
end)
```

Installed in `ensurePlateHook` at `Recolor.lua:111`. Marked with `_mnrHooked = true` to avoid double-hooking.

---

## Inspiration & credits

This addon stands on three shoulders:

### 1. MythicPlusCount (primary source of fingerprints + algorithm)

**Location in workspace:** `../MythicPlusCount/`.

MPC solved the "identify mobs in Midnight instances" problem for a completely different reason — they count forces for keystone progress. We ported:

- `MythicPlusCount/util.lua:37` — the 6-dimension compound-fingerprint formula, verbatim.
- `MythicPlusCount/util.lua:286-324` — the ChallengeMapID resolver (C_ChallengeMode + instance-name fallback).
- `MythicPlusCount/fingerprints.lua` — every fingerprint key → npcID mapping for all 8 Season 1 dungeons. We copied this verbatim into our `Fingerprints.lua`.
- `MythicPlusCount/data.lua` — the dungeon + mob list (npcID → name) that populates our settings UI. Copied into our `Dungeons.lua`.

**Credit:** MPC's author did the hard empirical work of collecting fingerprints across every Season 1 dungeon, including the `:buffCount` tiebreakers. Our addon is essentially MPC's identity system wired to a recolor UI instead of a force counter.

**To resync with a new MPC version:** diff `MythicPlusCount/fingerprints.lua` and `MythicPlusCount/data.lua` against our copies.

### 2. PersonalQOL POC (all the hard-won bugs are documented)

**Location in workspace:** `../PersonalQOL/Modules/TrashCastAlert/RESEARCH.md`.

Before MPC surfaced as a reference, we built our own nameplate-recolor POC inside PersonalQOL. Every dead end and every bug is documented in `RESEARCH.md`. The six bugs in the "Hard-won gotchas" section below all come from that postmortem. The POC code was removed after validation; the research doc is the authoritative spec for the fingerprint-only (pre-MPC) approach.

Priority reading order in RESEARCH.md:

1. TL;DR
2. Status checklist
3. "What works ✅" — non-secret APIs
4. "Runtime architecture (validated)" code block — the corrected paint path
5. "Five bugs the POC hit" — each with a file:line pointer to the reference addon that got it right

### 3. EllesmereUI (the nameplate addon we integrate with)

**Location in workspace:** `../EllesmereUI/EllesmereUINameplates/EllesmereUINameplates.lua`.

EUI is the target paint surface — when loaded it owns the visible nameplate. We hook its `UpdateHealthColor` method per-plate and paint `euiPlate.health`. When EUI isn't loaded we fall back gracefully to Blizzard's default `plate.UnitFrame.healthBar`.

Key references inside EUI:
- [Line 3021](../EllesmereUI/EllesmereUINameplates/EllesmereUINameplates.lua#L3021) — `local NameplateFrame = {}` — the table that can't be hooked globally.
- [Line 3025](../EllesmereUI/EllesmereUINameplates/EllesmereUINameplates.lua#L3025) — `self:SetParent(nameplate)` — EUI's pool plate becomes a child of Blizzard's.
- [Line 3644](../EllesmereUI/EllesmereUINameplates/EllesmereUINameplates.lua#L3644) — `self.health:SetStatusBarColor(GetReactionColor(unit))` — what we override.
- [Line 4744](../EllesmereUI/EllesmereUINameplates/EllesmereUINameplates.lua#L4744) — `Mixin(plate, NameplateFrame)` — the moment methods land on each pool plate.

---

## Data sources + collection pipeline

If you need to add a new dungeon, update Season 2 data, or debug a mob that isn't identifying, here are the upstream sources MPC (and we) use.

### Local in the workspace

| Source | Purpose |
|---|---|
| `../MythicDungeonTools/Midnight/<dungeon>.lua` | Per-dungeon NPC metadata (npcID, name, displayId, creatureType, level, spell IDs). Harvested by MDT's in-game DataCollection tool. |
| `../Data/Creature.12.0.5.66741.csv` | **Empty for Midnight dungeon NPCs** — do not use for them. Legacy dungeon NPCs (Seat of the Triumvirate, Pit of Saron) do populate here. |
| `../Data/CreatureDisplayInfo.12.0.5.66741.csv` | Maps `displayID → ModelID`. 2nd column is ModelID. Column 5 is DisplayInfo scale multiplier. |
| `../Data/CreatureModelData.12.0.5.66741.csv` | Maps `ModelID → FileDataID`. 8th column is the `fileID` our probe returns at runtime. |
| `../Data/SpellMisc.*.csv` + `SpellCastTimes.*.csv` + `SpellName.*.csv` | Spell cast timings and names. Not needed for this addon but useful for related research. |
| `../PersonalQOL_Probe/` | Research/dev addon — captures per-nameplate fingerprints + `*Secret` flags + cast events. See its README comments. Useful for empirically validating fingerprints and discovering display variants. |

### DBC join chain (displayId → fileID)

For a given NPC's `displayId` from MDT:

```
displayId
 ⨯ CreatureDisplayInfo.csv   (col 1 = displayId, col 2 = ModelID)
 ⨯ CreatureModelData.csv     (col 1 = ModelID, col 8 = FileDataID = fileID)
= modelFileID
```

Example (confirms Keen Headhunter / Mire Laborer collision):

```
displayId 131701 (Keen Headhunter)    → ModelID 15970 → FileDataID 6366139
displayId 130872 (Mire Laborer var 1) → ModelID 15970 → FileDataID 6366139
displayId 130873 (Mire Laborer var 2) → ModelID 15972 → FileDataID 6366141
```

Both Keen and one Mire variant hash to the same fileID — this is the "cross-NPC collision" we broke via the buff-count extended key.

### External

| Source | URL / Access | Purpose |
|---|---|---|
| **wago.tools** | https://wago.tools/db2/<Table> (export CSV) | DBC tables. Manual browser export — the API doesn't serve parsed DBCs. |
| **nether.wowhead.com** | `https://nether.wowhead.com/tooltip/npc/<id>` | JSON endpoint, bypasses the CloudFront 403 on `www.wowhead.com`. Returns classification, creatureType, isBoss. |
| **warcraft.wiki.gg** | https://warcraft.wiki.gg | API reference, Secret Values spec, patch notes. |
| **keystone.guru** | https://keystone.guru | Dungeon route data, mob counts/positions, cross-check MDT numbers. |

### Collecting data for a new season

1. **Update MDT** to the new season inside WoW and run its DataCollection tool in each dungeon. Export the per-dungeon Lua tables.
2. **Export DBC tables** at the new build from wago.tools (`CreatureDisplayInfo`, `CreatureModelData`). Build numbers bump per patch.
3. **Run PersonalQOL_Probe** on a sample pull in each dungeon to empirically confirm the MDT data matches reality — `/pqprobe` captures per-plate fingerprints, `/pqbuckets` aggregates by `(fileID, level)` with scale/class/aura histograms. Useful for discovering display variants MDT missed.
4. **Watch MythicPlusCount** — they collect fingerprints in the wild across many runs. Diffing their `fingerprints.lua` against ours after each MPC release is the cheapest way to stay current.

---

## Hard-won gotchas

Every one of these bit us during the POC. Each is a *silent failure* — no error, no log, just "nothing happens". Documented here so the next agent doesn't re-discover them.

### 1. `probe:Hide()` kills model loading

Hidden `PlayerModel` frames don't load their model data. `CanSetUnit` returns nil/false, `GetModelFileID` returns nil. Keep the probe at `SetAlpha(0)` + offscreen position, **never call Hide()**. Reference: `PersonalQOL_Probe/PersonalQOL_Probe.lua:44-47`.

### 2. `_G.NameplateFrame` does not exist

EllesmereUI declares `local NameplateFrame = {}` — the identifier is file-local, not a global. `hooksecurefunc(_G.NameplateFrame, ...)` silently does nothing. Hook each plate individually via `hooksecurefunc(euiPlate, "UpdateHealthColor", fn)` on `NAME_PLATE_UNIT_ADDED`.

### 3. Painting `plate.UnitFrame.healthBar` when EUI is loaded does nothing visible

That's the Blizzard default bar, hidden beneath EUI's pool plate. Paint `euiPlate.health:SetStatusBarColor(...)` instead. Find the EUI plate by walking the Blizzard plate's children for `_mixedIn + .health + .UpdateHealthColor`.

### 4. `C_NamePlate.GetNamePlates()` frames may not carry `namePlateUnitToken`

Iterating the return value and reading `plate.namePlateUnitToken` silently produced nil on every frame in our probes. Use `UnitExists("nameplate" .. i)` for `i = 1..40` to enumerate — bulletproof.

### 5. `CanSetUnit` returns nil, not false

`not probe:CanSetUnit(unit)` evaluates `not nil = true` — we short-circuited and skipped `SetUnit`, so `GetModelFileID` stayed nil forever. The correct gate is `probe:CanSetUnit(unit) == false`; nil means "try anyway, model may still be loading". Also: don't cache transient failures — only cache a stable miss (got a fileID + level but no fingerprint match).

### 6. `GetInstanceInfo()`'s 8th return is instance mapID, not ChallengeMapID

`2874` (Maisara instance mapID) ≠ `560` (Maisara ChallengeMapID). MPC's fingerprints are keyed by ChallengeMapID. Use `C_ChallengeMode.GetActiveChallengeMapID()` in keystones, or name-match against `addon.Dungeons[*].name` otherwise.

### 7. (Data side) Display variants + cross-NPC collisions

A single NPC can have many `displayId` values. The server picks one at spawn. Mire Laborer has six displayIds, three of which share a modelFileID with Keen Headhunter. Without the `:buffCount` extension, we'd paint both with one color. MPC's extended fingerprint is the answer.

---

## Secret Values cheatsheet

Summary from [workspace CLAUDE.md § Secret Values](../CLAUDE.md). Rules for tainted code:

**Not allowed (errors):**

- Arithmetic on a secret
- Comparisons (equality, ordering) against any other value, including another secret
- Boolean tests that try to read the hidden value (`if secret then` is *only* a nil-vs-non-nil existence check)
- Length operator `#` on a secret
- Using a secret as a table key
- Indexed access/assignment on a secret table
- Calling a secret as a function

**Allowed:**

- Store in variables, upvalues, table values
- Pass to Lua functions
- String concatenation (result may be Secret)
- `string.format` / `string.concat` / `string.join`
- Pass to whitelisted C APIs (`FontString:SetText`, `StatusBar:SetValue`, `StatusBar:SetTimerDuration`)
- `type()` returns the real type
- `issecretvalue(v)` → boolean — the detection primitive we use everywhere

**Our addon's discipline:**

- Every value that *might* be Secret is read through `Identify.lua:safeRead(fn, default)` — pcall the read, check `issecretvalue`, fall back to the default.
- Aura existence checks use `if aura then` without touching `.name` / `.spellId` / etc.
- No secret ever becomes a table key or a comparison operand.

**What *is* plain for hostile units in M+ dungeons** (confirmed by PQProbe):

- `UnitLevel`, `UnitClassification`, `UnitSex`, `UnitClass` (both returns), `UnitPowerType`
- `PlayerModel:GetModelFileID()` after `SetUnit(unit)`
- `C_UnitAuras.GetAuraDataByIndex` return — the *table* is non-nil (existence-readable), fields are Secret
- **Aura `spellId`** — empirically plain in Midnight, unlike cast spellIDs. We don't currently use this but it's a known escape hatch for edge cases.
- `C_NamePlate.GetNamePlateForUnit` return
- `GetInstanceInfo` return
- `C_ChallengeMode.GetActiveChallengeMapID` return

---

## MCP servers for research

Both defined in the workspace root `.mcp.json` and auto-allowed for this repo.

### `wow-api` — structured WoW API reference

**Source:** https://github.com/spartanui-wow/wow-api-mcp

Indexes the full WoW Lua API from the `ketho.wow-api` VS Code extension. 8000+ functions, 260 namespaces, 843 enums, 1716 events, 90+ deprecated functions with replacement info.

Tools:

| Tool | Purpose |
|---|---|
| `lookup_api(name)` | Find functions by exact or partial name |
| `search_api(query)` | Full-text search across all APIs |
| `list_deprecated(filter?)` | Show deprecated functions + replacements |
| `get_namespace(name)` | All functions in a `C_` namespace |
| `get_widget_methods(widget_type)` | Methods on a widget class (e.g. `PlayerModel`, `StatusBar`) |
| `get_enum(name)` | Enum values by name |
| `get_event(name)` | Event payload parameters |

**Use before touching any unfamiliar API** — confirm signature, return types, and whether it's Secret / deprecated in 12.0.x.

### `warcraft-wiki` — read-only MediaWiki access

**Source:** https://github.com/professional-wiki/mediawiki-mcp-server

Pre-configured to query warcraft.wiki.gg. Use this for prose context, examples, patch history, and anything not covered by the structured `wow-api` lookup — usage notes, deprecation rationale, Midnight Secret Values discussion.

Tools (read-only):

| Tool | Purpose |
|---|---|
| `search-page(query)` | Full-text search across page titles + content |
| `search-page-by-prefix(prefix)` | Title prefix search |
| `get-page(title)` | Fetch wikitext or HTML of a page |
| `get-page-history(title)` | Recent revisions |
| `get-revision(revisionId)` | A specific revision |
| `get-category-members(category)` | Pages in a category (e.g. patch API change indexes) |

The wiki is configured read-only; write tools (`create-page`, etc.) will fail.

**Workflow tip:** `wow-api` for signature/enum/event lookup, `warcraft-wiki` for narrative context. Prefer `wow-api` first, escalate to the wiki when you need more than a signature.

### Schemas are deferred

Both MCP servers appear in the session-start "deferred tools" reminder. Their full schemas only load on demand via `ToolSearch("select:<tool_name>")`. Don't assume they're missing just because they aren't in the active tool list — check the deferred list.

---

## Adding a new dungeon / season

When Midnight Season 2 (or similar) ships:

1. **Wait for MythicPlusCount to update.** Their author collects fingerprints across many live runs; our data is a verbatim port of theirs. Sync by diffing `../MythicPlusCount/fingerprints.lua` and `../MythicPlusCount/data.lua` against our `Fingerprints.lua` and `Dungeons.lua`.
2. **Port the new dungeons.** Add entries to `addon.Dungeons` (name + npcID → mob name) and `addon.Fingerprints` (fingerprint key → npcID).
3. **Verify the instance name resolver.** Enter each new dungeon, run `/mnr`, confirm `challengeMapID:` resolves. If `challengeMapID: nil`, the instance name in `addon.Dungeons[*].name` doesn't match what `GetInstanceInfo()` returns — fix the name.
4. **Validate in-game.** Pull a pack, `/mnr`, confirm each plate resolves to a correct `npcID` + `name`. Pay special attention to mobs sharing a modelFileID — ext fingerprint should split them via buff count.
5. **Update this doc's "Data sources" section** if build numbers / source URLs changed.

If MPC lags, you can collect fingerprints yourself with `PersonalQOL_Probe` — `/pqprobe` captures per-plate data, `/pqbuckets` aggregates by `(fileID, level)`. Cross-reference against MDT's NPC data to map fingerprints to npcIDs.

---

## Debugging / slash commands

```
/mnr                         status dump — one-shot, no args
/mnr on                      enable recoloring
/mnr off                     disable recoloring
/mnr paint                   force a repaint pass across all visible plates
/mnr debug on                turn on per-paint chat logging
/mnr debug off               turn off debug logging
/mnr help                    print command list
```

`/mnr` (no args) output:

```
[MNR] --- status ---
  enabled:        true                 # db flag
  R.enabled flag: true                 # runtime flag — should match db
  db present:     true
  saved colors:   3                    # how many mobs have non-default colors
  instanceName:   Maisara Caverns      # from GetInstanceInfo
  instanceMapID:  2874                 # the "other" mapID — NOT what we key by
  challengeMapID: 560                  # what we key by — must be non-nil for recolor to work
  fingerprints:   true                 # addon.Fingerprints[challengeMapID] exists
  dungeon name:   Maisara Caverns      # resolved from addon.Dungeons
  nameplate1 fp=6366139:0:elite:3:WARRIOR:1
    ext=6366139:0:elite:3:WARRIOR:1:1 npcID=242964 name=Keen Headhunter
    color=red eui=yes hooked=yes buffs=1
  ...
```

**Diagnostic flowchart for "my color isn't applying":**

1. `enabled: false` → tick the global checkbox in settings.
2. `saved colors: 0` → you haven't picked a color yet, or the settings `set` callback never fired.
3. `challengeMapID: nil` → instance name doesn't match any entry in `addon.Dungeons`; dump the `instanceName:` value and fix the name.
4. Per-plate `npcID=(no match)` with a valid `fp=...` → fingerprint isn't in `addon.Fingerprints[mapID]`; we'd need to teach it (or wait for an MPC sync).
5. Per-plate has `npcID` but `color=(unset)` → you picked a color for a different npcID; check which NPC the mob actually is via the `name=` field.
6. `eui=no` in a session where EUI is loaded → the EUI plate detection failed (`findEUIPlate` didn't match). Shouldn't happen but flag if it does.
7. `hooked=no` with `eui=yes` → the per-plate hook didn't install; check `ensurePlateHook` for an error.

`/mnr debug on` prints a line for every `PaintUnit` call, tagged with the failure stage if any. Useful when the plate comes and goes faster than `/mnr` can snapshot.

---

## Known limitations

- **Season 1 only.** Data is a verbatim port of MPC's `DefaultFingerprints` at their time of capture. Non-Season-1 dungeons silently no-op.
- **Custom npcIDs.** Some MPC entries use negative npcIDs (e.g. `-63875` Vicious Ravager) for mobs whose real npcID is unknown. Those show up in our `Dungeons.lua` only if we listed them explicitly; right now we don't, so they'll resolve to an npcID with no display name in settings (the dropdown row is missing). Low priority.
- **Aura-based disambiguation timing.** Buff count is read when the nameplate becomes visible. If a mob's distinguishing aura is applied mid-combat (not pre-pull), the first paint may misidentify. Our per-plate `UpdateHealthColor` hook re-fires on every EUI repaint though, so the identification corrects itself within a frame or two.
- **Fingerprints drift across patches.** Blizzard rebalancing, model swaps, or new display variants can invalidate individual fingerprints. The defense is re-running PQProbe + resyncing with MPC each major patch.
- **Interface: 120001 only.** New patch? bump the TOC and re-check that no assumption baked into Identify.lua broke. Secret Values policy has tightened across 12.0.0 → 12.0.1 and will continue to evolve.

---

## Maintenance checklist (per patch)

- [ ] Bump `Interface:` in `MidnightNameplateRecolor.toc` to the new build number.
- [ ] Re-run `PersonalQOL_Probe` in each dungeon with a clean pull. Check `/pqbuckets` output against our fingerprints — any new mismatches indicate model/aura/class changes.
- [ ] Resync `Fingerprints.lua` and `Dungeons.lua` from MythicPlusCount's latest release.
- [ ] Test `/mnr` in each of the 8 dungeons on Normal + Heroic + M0 + a low-key keystone. Confirm `challengeMapID:` resolves in every mode.
- [ ] Verify EllesmereUI integration — the `_mixedIn` + `.health` + `.UpdateHealthColor` fingerprint may change across EUI releases; if `eui=no` starts appearing, update `findEUIPlate` in `Recolor.lua`.
- [ ] Re-read the workspace CLAUDE.md's "WoW Midnight API Reference" section for any newly-whitelisted or newly-restricted APIs.
