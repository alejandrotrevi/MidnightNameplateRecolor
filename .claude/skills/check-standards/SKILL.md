---
name: check-standards
description: "Audit MidnightNameplateRecolor Lua/XML/TOC files against the addon's coding standards (MidnightNameplateRecolor/CLAUDE.md + workspace CLAUDE.md + EllesmereUI patterns). Trigger when: user asks to check standards, review code quality, audit the addon against our guidelines, verify code follows conventions, or asks 'does this follow our rules'."
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
argument-hint: "[-u|--uncommitted] [-a|--all] [file paths or glob pattern (optional — defaults to uncommitted changes, falls back to all MidnightNameplateRecolor files when the working tree is clean)]"
---

# /check-standards — Audit MidnightNameplateRecolor against project standards

You review MidnightNameplateRecolor addon files against the standards defined in `MidnightNameplateRecolor/CLAUDE.md`, the workspace `CLAUDE.md` (for Midnight API and cross-cutting rules), and the patterns established by `EllesmereUI/`. You report violations with specific file paths, line numbers, and concrete suggested fixes but you do **NOT** modify any files.

**IMPORTANT: Every numbered step is mandatory. Do not skip steps.**

**IMPORTANT workspace layout:** `MidnightNameplateRecolor/` lives at the workspace root alongside `PersonalQOL/`, `EllesmereUI/`, `MythicPlusCount/`, etc. Each addon has its own inner git repo. Run every git command with `git -C MidnightNameplateRecolor ...` (or `cd` into the folder first). Reference addons (`EllesmereUI/`, `MythicPlusCount/`, `PersonalQOL/`) are **never** in scope for this skill.

---

## Step 1 — Load guidelines (mandatory)

Read these files in full and extract every rule. After reading, display the extracted ruleset grouped by category so the user sees what you are about to check:

1. `MidnightNameplateRecolor/CLAUDE.md` — the authoritative addon-specific doc. Covers architecture, identification (fingerprint formula + ChallengeMapID resolution), painting (EUI pool plate discovery + per-plate hook), Secret Values discipline, and the seven hard-won gotchas. **Every rule this skill enforces should trace back to a section in this doc.**
2. Workspace `CLAUDE.md` at `../CLAUDE.md` (one level up from the addon) — workspace-wide rules for Midnight API (12.0.1), Secret Values cheatsheet, interface version, commit style.
3. `MidnightNameplateRecolor/MidnightNameplateRecolor.lua` — canonical lifecycle example. Confirms the `ADDON_LOADED` → `PLAYER_LOGIN` sequence and the `/mnr` slash command surface.
4. On demand only (read these when a specific violation needs context, not up front):
   - `../EllesmereUI/EllesmereUINameplates/EllesmereUINameplates.lua` — reference for the EUI plate structure we hook into (specifically lines 3021, 3025, 3644, 4744).
   - `../MythicPlusCount/util.lua` — reference for the fingerprint formula we port verbatim (line 37 for the schema, 48-109 for the builder, 286-324 for the ChallengeMapID resolver).
   - `../PersonalQOL/Modules/TrashCastAlert/RESEARCH.md` — the POC postmortem — every silent-failure bug this addon avoids is documented there.

List every rule you extracted, grouped by category (Lifecycle, Event handling, OnUpdate, Performance, UI text, Midnight API, Addon-specific, Code style). Display this list to the user before proceeding.

---

## Step 2 — Identify target files

Parse `$ARGUMENTS` (strip known flags, keep the rest as paths/globs):

- `--uncommitted` / `-u` present → uncommitted-only mode.
- `--all` / `-a` present → full MidnightNameplateRecolor scan.
- Remaining arguments (after flag removal) → treated as explicit paths or globs (relative to workspace root, e.g. `MidnightNameplateRecolor/Recolor.lua`).
- No arguments → try uncommitted first, and if the working tree is clean, fall back to scanning all `.lua`/`.xml`/`.toc` files under `MidnightNameplateRecolor/`.

### Uncommitted mode

Run these from the workspace root with `-C` so they resolve against the addon's inner git repo:

```bash
git -C MidnightNameplateRecolor diff --name-only --cached
git -C MidnightNameplateRecolor diff --name-only
git -C MidnightNameplateRecolor ls-files --others --exclude-standard
```

Deduplicate. These commands return paths relative to `MidnightNameplateRecolor/`. Prefix each result with `MidnightNameplateRecolor/` before passing them to `Read` / `Grep`.

### All mode (explicit `--all` or default fallback when working tree is clean)

Use Glob:

```
MidnightNameplateRecolor/**/*.lua
MidnightNameplateRecolor/**/*.xml
MidnightNameplateRecolor/**/*.toc
```

### Filters (always apply)

Include extensions: `.lua`, `.xml`, `.toc`.

Exclude paths:
- `MidnightNameplateRecolor/libs/**` (bundled LibStub / CallbackHandler / LibEQOL — vendored, not our code).
- `MidnightNameplateRecolor/.claude/**` (this skill itself and any other workspace config).
- Anything outside `MidnightNameplateRecolor/` (reference addons are never in scope).
- `.git/**` (none currently, but future-proof).

If the final list is empty, print `No files to check.` and stop.

Display the final file list to the user before running checks.

---

## Step 3 — Run checks

For each file:

1. Read it (in sections if it exceeds 2000 lines).
2. Determine which rule categories apply based on the file's role:
   - `Init.lua` → A (lifecycle) only; skip D1 (upvalue caching) — intentionally tiny.
   - `Palette.lua` / `Dungeons.lua` / `Fingerprints.lua` → data files. A4, H apply; others are N/A.
   - `Identify.lua` → all categories, with special attention to **I** (addon-specific fingerprint discipline) and **G4** (Secret Values).
   - `Recolor.lua` → all categories, with special attention to **I** (EUI integration + nameplate enumeration).
   - `MidnightNameplateRecolor.lua` → lifecycle file; A, B, D, H apply.
   - `Settings/SettingsUI.lua` → A4, H.
   - `Settings/Settings.lua` → A3 (settings must not build at load), H.
   - `.toc` → G1 only.
   - `.xml` → frame template sanity (no runtime logic expected).
3. Check every applicable rule. Do not sample.
4. Record violations as: file path, line number, category, rule ID, severity, concrete suggestion showing the exact code change.
5. If a file passes all applicable rules, say so explicitly in the report.

### A. Lifecycle (errors unless noted)

- **A1 (error)** — `MidnightNameplateRecolor.lua` must register exactly one `ADDON_LOADED` handler that (a) guards on the addon name, (b) calls `UnregisterEvent("ADDON_LOADED")`, (c) binds `MidnightNameplateRecolorDB`, and (d) calls `Recolor:InitDB()`. Deviation → error.
- **A2 (error)** — `PLAYER_LOGIN` handler must (a) call `UnregisterEvent("PLAYER_LOGIN")`, (b) call `addon.functions.InitSettings()`, (c) call `Recolor:OnEnabledChanged(Recolor:IsEnabled())`. Missing any step → error.
- **A3 (error)** — Settings must NOT be built at file load. Any `SettingsLib:Create*`, `SettingsCreate*`, or `Settings.RegisterAddOnSetting` call that runs at file scope (not wrapped in `addon.functions.InitSettings` or a function it calls) → error.
- **A4 (warning)** — No global side effects on file load. Writes to `_G["..."]` or bare global assignments outside the `addon.*` namespace → warning. Exception: the intentional `_G[addonName] = addon` line in `Init.lua`.

### B. Event handling (errors unless noted)

- **B1 (error)** — `frame:RegisterEvent(` at file scope is disallowed. The only permitted file-scope sentinel is the top-level `ADDON_LOADED` + `PLAYER_LOGIN` pair in `MidnightNameplateRecolor.lua`. Anything else registered outside a function body → error. Suggest moving the call into `Recolor:RegisterEvents` or a similar method invoked from the enable path.
- **B2 (warning)** — Feature-specific events must be unregistered when the feature is disabled. `Recolor:UnregisterEvents` must mirror `Recolor:RegisterEvents` exactly — every `RegisterEvent` pair has a matching `UnregisterEvent`.
- **B3 (warning)** — `SetScript("OnEvent", function(self, event, ...) ... end)` bodies longer than ~40 lines inline should be extracted. Suggest moving the body to a named local function (the EllesmereUI style).
- **B4 (warning)** — One-shot events (`PLAYER_LOGIN`, `ADDON_LOADED`) must `self:UnregisterEvent(event)` inside the handler. Missing → warning. `PLAYER_ENTERING_WORLD` is legitimately multi-shot for our cache-flush path; don't flag it.
- **B5 (error)** — Event names passed to `RegisterEvent` must be `SCREAMING_SNAKE_CASE`. Typos like `Player_Login` → error.

### C. OnUpdate / hot paths (errors unless noted)

- **C1 (error)** — Every `SetScript("OnUpdate", ...)` must use an elapsed accumulator throttle:
  ```lua
  local accum = 0
  local THROTTLE = 0.033
  frame:SetScript("OnUpdate", function(self, elapsed)
      accum = accum + elapsed
      if accum < THROTTLE then return end
      accum = 0
      -- work
  end)
  ```
  Unthrottled OnUpdate → error. `C_Timer.NewTicker` is an acceptable substitute.
- **C2 (error)** — OnUpdate bodies must have a disable gate (early return when the feature is off). Missing → error.
- **C3 (error)** — OnUpdate must have a stop path: either `self:SetScript("OnUpdate", nil)` when work completes, or a toggle. Persistent, never-stopped OnUpdate → error.
- **C4 (warning)** — No `string.format`, `format(`, `CreateColor`, `CreateFrame`, or table constructors (`{}`) inside an OnUpdate body. Cache/precompute outside and reuse.
- **C5 (info)** — **MidnightNameplateRecolor currently has ZERO OnUpdate handlers and should stay that way.** Every paint path is event-driven (`NAME_PLATE_UNIT_ADDED` + per-plate `UpdateHealthColor` hook). If any new OnUpdate is introduced, flag informationally so the reviewer double-checks it's really necessary.

### D. Performance (warning unless noted)

- **D1 (warning)** — `.lua` files that reference WoW/Lua globals more than ~3 times should cache them at file top as upvalues. Grep the top ~20 lines: if `CreateFrame`, `C_NamePlate`, `UnitExists`, `UnitCanAttack`, `UnitLevel`, `pairs`, `ipairs`, `format`, etc. are used repeatedly inside the file but not declared as `local X = X` at the top, warn. Skip `Init.lua`.
- **D2 (warning)** — Modules that rebuild a UI string or rewrite a status bar color in a hot path should cache the last value and skip the write when unchanged. `paintHealthBar` in `Recolor.lua` writes a constant RGB per `(fileID, level, buffCount)` bucket — if a future refactor introduces per-frame recomputation, flag it.
- **D3 (info)** — `frame:CreateTexture(...)` used for a crisp separator/border/line should call `SetSnapToPixelGrid(false)` + `SetTexelSnappingBias(0)`. Heuristic: only flag textures with `SetSize` width or height of 1.
- **D4 (warning)** — Bursty events must be debounced. This addon only subscribes to `NAME_PLATE_UNIT_ADDED` / `NAME_PLATE_UNIT_REMOVED` / `PLAYER_ENTERING_WORLD`, which are already bounded (per-unit, not per-tick). But if any new subscription is added to a bursty event (`UNIT_AURA`, `COMBAT_LOG_EVENT_UNFILTERED`, `UNIT_SPELLCAST_*`, `GROUP_ROSTER_UPDATE`), warn and suggest a `pending` flag + `C_Timer.After(0.05, ...)` debounce.

### E. UI text (warnings unless noted)

- **E1 (warning)** — Any `SetFont(path, size, "OUTLINE")` or `SetFont(path, size, "THICKOUTLINE")` on a custom label → warning. Prefer `SetFont(path, size, "")` + `SetShadowOffset(1, -1)` + `SetShadowColor(0, 0, 0, 1)`. The addon currently has no custom text but this rule applies if any is added.
- **E2 (info)** — Single-line labels should call `SetWordWrap(false)`.
- **E3 (warning)** — Custom `FontString` with no `SetTextColor` / `SetVertexColor` call at all → warning.

### G. Midnight API — Patch 12.0.1 (errors unless noted)

- **G1 (error)** — `MidnightNameplateRecolor.toc`'s `## Interface:` line must equal `120001`. Other values → error.
- **G2 (error)** — Usage of deprecated `LE_EXPANSION_*` constants or `NUM_LE_EXPANSION_LEVELS` → error. Suggest `Enum.ExpansionLevel.Midnight`.
- **G3 (error)** — Any reference to files removed in 12.0.0 (`Deprecated_BattleNet.lua`, `Deprecated_ChatInfo.lua`, `Deprecated_ChatFrame.lua`, `Deprecated_CombatLog.lua`, `Deprecated_SpellBook.lua`, `Deprecated_InstanceEncounter.lua`, `Deprecated_SpellScript.lua`) or the removed duration getters in `C_UnitAuras` / `C_Spell` / `C_ActionBar` → error.
- **G4 (warning)** — Secret Values heuristic. Flag any use of a unit API result that looks like it treats a potentially-Secret value as plain. Specifically:
  - Arithmetic (`+`, `-`, `*`, `/`) or non-nil comparison (`> 0`, `< X`) applied to a result from `UnitBuff` / `UnitDebuff` / `UnitAura` / `C_UnitAuras.GetAuraDataByIndex` / `C_UnitAuras.GetUnitAuraBySpellID` without a prior `issecretvalue` check.
  - Using `UnitName`, `UnitGUID`, `UnitCreatureType`, or `UnitCastingInfo.*` (except the NeverSecret fields `castBarID`, `delayTimeMs`, `isTradeskill`) in a way that expects a real value.
  - **Correct pattern:** use `Identify.lua:safeRead(fn, default)` — pcall the read, check `issecretvalue`, fall back to default. Suggest replacing raw reads with this helper.

### I. Addon-specific (errors unless noted)

These are the hard-won rules from the CLAUDE.md "Hard-won gotchas" section. Each is a *silent failure* — no error, just "nothing happens".

- **I1 (error)** — **Never call `probe:Hide()`** on the `PlayerModel` probe frame in `Identify.lua`. Hidden PlayerModel frames don't load their model data; `CanSetUnit` returns nil and `GetModelFileID` returns nil. The correct pattern is `SetAlpha(0)` + offscreen position without Hide.
- **I2 (error)** — **Never hook `_G.NameplateFrame`**. EllesmereUI's `NameplateFrame` table is file-local at `../EllesmereUI/EllesmereUINameplates/EllesmereUINameplates.lua:3021`. `hooksecurefunc(_G.NameplateFrame, ...)` silently does nothing. The only correct hook is per-plate: `hooksecurefunc(euiPlate, "UpdateHealthColor", fn)` inside `ensurePlateHook` on `NAME_PLATE_UNIT_ADDED`.
- **I3 (error)** — **Paint `euiPlate.health`, not `blizzardPlate.UnitFrame.healthBar`**, when EllesmereUI is loaded. The Blizzard bar is hidden beneath EUI's pool plate. Any code path that paints `UnitFrame.healthBar` without first trying `findEUIPlate` and painting `euiPlate.health` → error. The fallback to `UnitFrame.healthBar` is legitimate *only* when `findEUIPlate` returns nil.
- **I4 (error)** — **Enumerate nameplates via `UnitExists("nameplate" .. i)` for `i = 1..40`**, not `C_NamePlate.GetNamePlates()`. The latter's returned frames don't reliably carry `namePlateUnitToken`, so a direct iteration silently drops every plate. Any loop that depends on `plate.namePlateUnitToken` from `GetNamePlates` → error.
- **I5 (error)** — **`CanSetUnit` returns nil, not false, when the model isn't loaded yet.** `not probe:CanSetUnit(unit)` evaluates `not nil = true` and short-circuits. The correct gate is `probe:CanSetUnit(unit) == false` (only bail on explicit false). Any `not probe:CanSetUnit(...)` pattern → error.
- **I6 (error)** — **`GetInstanceInfo()`'s 8th return is the instance mapID, not the ChallengeMapID.** The two are unrelated numbers (e.g. Maisara is 2874 instance / 560 challenge). Our `Fingerprints.lua` is keyed by ChallengeMapID. Any `Fingerprints[<result_of_GetInstanceInfo 8th return>]` lookup → error. The correct resolver is `Identify.lua:currentMapID()` which tries `C_ChallengeMode.GetActiveChallengeMapID` first, then name-matches against `addon.Dungeons[*].name`.
- **I7 (warning)** — **Fingerprint format must stay MPC-compatible.** `buildFingerprints` builds `"modelFileID:level%10:classification:sex:classToken:powerType"` plus `:buffCount` extended. Changing the schema, field order, separator, or level-modulo without also updating `Fingerprints.lua` → warning. Also warn if `%d` is used where a string dimension is expected (e.g. classification) or vice versa.
- **I8 (warning)** — **Per-plate `hooksecurefunc` must mark the plate to avoid double-hooking.** `ensurePlateHook` sets `euiPlate._mnrHooked = true`. If that marker is removed, the hook would install N times per plate lifetime, each call re-firing the full paint chain. Any new hook-install path missing the marker → warning.

### H. Code style (warnings and info)

- **H1 (info)** — Section headers should use `--` + 77 dashes (80 chars total). Other styles (`====`, `****`, shorter/longer) → info.
- **H2 (info)** — The main file of each concern should define a short alias local at file top, e.g. `local R = addon.Recolor` in `Recolor.lua`. Missing → info.
- **H3 (warning)** — DB keys should be `camelCase`. Keys stored in `addon.db` using `snake_case` or `PascalCase` → warning.
- **H4 (info)** — Comments above non-trivial functions describing purpose / params / return. Missing on a 30+ line function → info only.

---

## Step 4 — Output report

Render the report in this exact format. Skip categories that are clean for a given file.

```
# MidnightNameplateRecolor Standards Check

**Files checked:** {count}
**Errors:** {n}   **Warnings:** {n}   **Info:** {n}
**Mode:** {uncommitted | all | explicit}

---

## {relative path under workspace root, e.g. MidnightNameplateRecolor/Recolor.lua}

### Addon-specific (I)
| Line | Severity | Rule | Issue | Suggestion |
|------|----------|------|-------|------------|
| 42   | error    | I3   | ...   | ...        |

### Event handling (B)
| Line | Severity | Rule | Issue | Suggestion |
|------|----------|------|-------|------------|
| ...  | ...      | ...  | ...   | ...        |

(...repeat for every violated category — skip clean ones)

(or `All checks passed.` if the file is fully compliant)

---

## Summary

### Errors (must fix)
- `{path}:{line}` — `{rule}` — one-line description

### Warnings (should fix)
- `{path}:{line}` — `{rule}` — one-line description

### Informational
- `{path}:{line}` — `{rule}` — one-line description

### Files that look fully compliant
- `{relative path}`
- ...

**Verdict:** PASS   (or: **Verdict:** FAIL — {n} errors)
```

End the report with a single `PASS` line if there are zero errors, or `FAIL — {n} errors` otherwise.

---

## Step 5 — Important rules for this skill

- This skill is **READ-ONLY**. Never modify files. Never run `--fix`-style commands. Never offer to apply fixes automatically within the same invocation — tell the user to invoke a separate edit session if they want fixes applied.
- Always give line numbers. Every violation row needs one.
- Every suggestion must show the exact replacement code, not vague advice like "use a better pattern".
- Read large files in sections. Do not truncate or skip sections to save time.
- Never scan files outside `MidnightNameplateRecolor/`. If the user asks you to audit `PersonalQOL`, `EllesmereUI`, or `MythicPlusCount`, politely redirect: those addons are references or live under their own skills (e.g. `PersonalQOL/.claude/skills/check-standards/`).
- `MidnightNameplateRecolor/libs/**` is always excluded.
- The addon-specific gotchas (category **I**) are the most important rules in this skill — they're the silent failures that cost us an evening during the POC. Prioritize them in the report when they fire.
- Treat `MidnightNameplateRecolor/CLAUDE.md` as authoritative. If a rule in this file seems to contradict it, the CLAUDE.md wins — re-read it before reporting to the user.
