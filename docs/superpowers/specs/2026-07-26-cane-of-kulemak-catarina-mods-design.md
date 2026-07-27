# Cane of Kulemak: restore missing Catarina signature mods

**Date:** 2026-07-26
**Status:** Approved

## Problem

Cane of Kulemak is a programmatically generated unique (`src/Data/Uniques/Special/Generated.lua`).
Its variant dropdowns are built by filtering `data.veiledMods` (`src/Data/ModVeiled.lua`) through
`veiledModIsActive`, which only accepts a mod if `weapon`, `staff`, or `two_hand_weapon` appears in
the mod's `weightKey` with a positive weight.

Catarina's signature veiled mods do not use those keys. They carry their spawn weight on
`catarina_veiled_prefix` (weight 2000) and list only the slots they are *excluded* from (weight 0).
A staff is not in their exclusion lists, so in game they can roll on Cane of Kulemak, but PoB's
filter drops them. Five weapon-legal variants are missing from the item:

1. `JunMasterVeiledLocalIncreaseSocketedSupportGemLevel` — `+2 to Level of Socketed Support Gems`
   / `+(5-8)% to Quality of Socketed Support Gems` (single mod, two lines — the motivating case)
2. `JunMasterVeiledChaosExplosionOnKill` — enemies killed have (15-25)% chance to explode
3. `JunMasterVeiledSupportedByCastOnCritAndSpellDamage`
4. `JunMasterVeiledSupportedByCastWhileChannelingAndSpellDamage`
5. `JunMasterVeiledSupportedByArcaneSurgeAndSpellDamage`

The other ~23 Catarina mods must remain excluded: they explicitly zero the `weapon` key.

## Scope

Cane of Kulemak only. Paradoxica and Replica Paradoxica generation must be byte-for-byte
unchanged (Replica Paradoxica's analogous gap with master signature mods is a possible follow-up,
out of scope here).

## Design

### Filter change (`src/Data/Uniques/Special/Generated.lua`)

- Add an optional `poolKey` parameter to `veiledModIsActive(mod, baseType, specificType1,
  specificType2, poolKey)`.
- New rule, appended to the existing checks: if **none** of `baseType`/`specificType1`/
  `specificType2` appear in the mod's `weightKey`, but `poolKey` does with weight > 0, the mod is
  active.
- Explicit slot keys keep priority: a mod listing `weapon` with weight 0 stays inactive regardless
  of pool key (this is what keeps the minion/spectre/flask Catarina mods off the staff, and it
  mirrors the game's first-matching-weightKey-wins semantics).
- `getVeiledMods` passes `"catarina_veiled_prefix"` as `poolKey` only when
  `veiledPool == "catarina"`. A nil `poolKey` preserves old behavior exactly.

### Knock-on effects

- The five new variants are inserted into the alphabetically sorted variant list, shifting the
  indices of later variants. The hardcoded `Selected Variant` / `Selected Alt Variant` defaults
  (`Generated.lua` lines 114–117) must be re-pointed so the same default mods stay selected.
  Verify by generating the item text before and after.
- No new mod data is needed. Both target lines are already flagged scalable in
  `src/Data/ModScalability.lua`, so the staff's `(50-70)% increased Unveiled Modifier magnitudes`
  implicit scales them automatically via existing machinery.

### Testing

- New busted spec (in `spec/System/`, following existing `Test*_spec.lua` conventions) asserting:
  - the generated Cane of Kulemak item text contains `+2 to Level of Socketed Support Gems` and
    `+(5-8)% to Quality of Socketed Support Gems`;
  - a weapon-illegal Catarina mod (e.g. `+1 to maximum number of Spectres`) is still absent;
  - Paradoxica and Replica Paradoxica generated text is unchanged (no Catarina signature mods
    leak in).
- Run the full spec suite to confirm no regressions.

### Error handling

None needed — pure data generation at program load; no user input or runtime failure paths.

## Success criteria

Selecting Cane of Kulemak from the unique list in PoB offers
"(Prefix) Increase Socketed Support Gem Level" (support gem level + quality) as a selectable
variant in the variant dropdowns, with values that scale with the unveiled-magnitude implicit.
