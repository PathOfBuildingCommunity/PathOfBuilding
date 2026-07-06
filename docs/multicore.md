# Multi-core calculation support — dev handoff notes

## Changelog (PR summary)

**Adds multi-core support for the four "iterate candidates, rank outcomes" features, with a user toggle (default: multi-core) and automatic single-core fallback.**

Parallelized features:
- Passive tree node power / heat map / "Show Power Report" (`CalcsTab:PowerBuilder`)
- Compare tab power report (`CompareTab`)
- Anoint notable stat-sorting (`NotableDBControl`)
- Item DB stat-sorting (`ItemDBControl`)

### Architecture

Workers are one-shot isolated Lua VMs started via the engine's existing `LaunchSubScript` primitive (no engine changes). Each worker bootstraps a headless PoB (HeadlessWrapper pattern), reconstructs the build from an in-memory `SaveDB` XML snapshot, computes its batch using **the same per-candidate functions the single-core path runs**, and returns one JSON payload (dkjson). The main thread partitions candidates, aggregates progress via subList calls, validates results, and merges by stable IDs.

### New files
- `src/Modules/ParallelRunner.lua` — worker pool / job manager: launch, cancel, progress aggregation, baseline validation, per-session sticky fallback, dev-mode job log (`src/parallel_log.txt`)
- `src/CalcWorker.lua` — worker script (read via `io.open`, passed as scriptText like `UpdateCheck.lua`): hardened headless stubs, script-path-relative `io.open` resolution (worker threads don't inherit a guaranteed cwd), env probe mode
- `src/Modules/PowerCalcTasks.lua` — shared per-candidate compute logic + JSON number sentinels + baseline extraction, loaded by both main thread and workers
- `spec/System/TestParallelTasks_spec.lua` — equivalence tests: single-core vs worker entry points in-process, through a JSON round trip, for all four features; merge staleness tests

### Modified files
- `src/Launch.lua` — `OnSubError` now notifies CUSTOM subscript callbacks (`(nil, errMsg)` — audited compatible with all existing users); nil-guards in `OnSubError`/`OnSubFinished` for aborted subscripts; dev-mode F7 = worker environment probe (report written to `src/probe_report.txt`)
- `src/Classes/CalcsTab.lua` — `PowerBuilder(filter)` optional candidate filter (nil = byte-identical legacy behavior); `EnumeratePowerCandidates`/`BuildPowerBatches` (modKey-grouped, weight-balanced batches carrying authoritative `node.path`/`node.depends` id lists); dual-path `BuildPower` with duplicate-launch guard; `LaunchParallelPowerBuild`/`MergeParallelPower` (staleness via `outputRevision`)
- `src/Classes/CompareTab.lua` — `ComparePowerBuilder` split into enumerate / `ComputeComparePowerCandidate` / format-row so both paths share candidate computation; dual-path report runner
- `src/Classes/NotableDBControl.lua`, `src/Classes/ItemDBControl.lua` — `ListBuilder` split into filter / measure / finish; dual-path `Draw`; candidates keyed by node id / item name
- `src/Modules/Main.lua` — `computationMode` ("MULTI"/"SINGLE", default MULTI) and `workerCount` (0 = auto) settings, persisted in `Settings.xml`; Options popup UI; loads `ParallelRunner`/`PowerCalcTasks` as globals
- `src/Modules/Build.lua` — cancels outstanding worker jobs on shutdown
- `src/Modules/DataLegionLookUpTableHelper.lua` — **standalone bugfix**: `loadJewelFile` could cache empty jewel data to `<jewel>.bin` when `Inflate` is stubbed (headless/busted), silently corrupting timeless jewel stats for the full app afterwards. Now rejects empty data, reads an existing `.bin` directly when `NewFileSearch` is unavailable, and never writes the shared cache from headless contexts

### Correctness guarantees
- Workers and single-core run identical code; results cross the thread boundary as JSON with `inf`/NaN sentinels
- Every worker returns a baseline stat vector recomputed from its reconstructed build; any relative deviation > 1e-3 from the main thread's baseline fails the whole job → automatic single-core fallback (sticky for the session, cleared by toggling the option or a successful F7 probe)
- Main thread sends each candidate's live `path`/`depends` node ids: a spec rebuilt from XML resolves equal-length shortest-path ties in different `pairs()` order, which would otherwise change `pathPower` vs what the UI displays
- Results merge only if `build.outputRevision` is unchanged since the snapshot; any build change mid-job cancels/discards and re-runs
- Worker errors surface once via `OnSubError` → fallback; workers never write shared caches
- Headless/CI: `HeadlessWrapper.lua` stubs `LaunchSubScript` → everything transparently uses the single-core path; no platform checks anywhere (pure feature detection)

### Verified
- `spec/System/TestParallelTasks_spec.lua`: 6/6 (all four features numerically identical through the worker entry points + JSON round trip)
- Full existing spec suite: zero regressions vs pristine master baseline (same harness, failure sets identical)
- Cross-process fresh-VM E2E: 781/781 nodes bit-identical on a 3.13 test build; pass on a live 3.28 build with a Brutal Restraint timeless jewel
- Real engine: worker baseline probe exact match on all stats; heat map on a level-95 build computes 4,348 candidates in ~15 s (8 workers) vs ~48 s single-core
- Engine facts established via probe: subscript VMs receive funcList injections (incl. `GetUserPath`) but not `NewFileSearch`/`Inflate`/`Deflate`; worker-thread cwd is launch-dependent (both handled in `CalcWorker.lua`)

### Performance (measured, 5950X SMT-off, level-95 build, full-depth heat map)
- Single-core: ~48 s (one core busy)
- Multi-core, 8 workers (auto default): ~15–27 s depending on system load
- Fixed overhead per job: ~5–7 s worker bootstrap (one-shot VMs must load all game data + build) + ~1–2 s snapshot/merge — this is the Amdahl floor; raise `worker threads` to physical cores − 1 to approach it

---

## Future speed projects (ordered by expected impact)

1. **Persistent warm workers (engine change — removes the ~7 s floor).** `LaunchSubScript` VMs are one-shot; every job pays a full bootstrap. A persistent worker/channel primitive in SimpleGraphic (send job → receive result → VM stays alive) would drop heat-map latency to pure compute (~3–6 s at 15 workers). Largest win, requires C++ runtime work upstream.
2. **Result caching across tree toggles.** Allocating then un-allocating a node currently recomputes everything twice. Caching the last few power-result sets keyed by a spec/state hash makes "undo a change" instant. Cheap, and directly targets the most common interaction.
3. **Trim worker bootstrap.** Profile `timing.initMs` vs `bootstrapMs` (already reported by workers): skip unique/rare item DB loading outside itemdb mode, skip tree versions the build doesn't use, lazy-load legion/tattoo data unless present, and cache Data modules as precompiled bytecode (`string.dump`). Realistic target: 7 s → 3–4 s.
4. **Wave scheduling for stragglers.** The job ends when the slowest worker finishes; per-candidate cost varies (masteries, long paths). Splitting into ~2× more batches than workers and launching a second wave as results return evens out the tail without engine changes.
5. **Stat-scoped calculation (benefits single-core too).** Each candidate runs a full offence+defence pipeline even when the heat map only needs one stat (e.g. Life). A calculation mode that skips unneeded sections could cut per-candidate cost several-fold — invasive, touches `calcs.perform`.
6. **Parallelize the Timeless Jewel search.** "Find Timeless Jewel" brute-forces thousands of seeds through the same kind of loop and is a notorious multi-minute wait — it fits the existing ParallelRunner/batch pattern well and may be the single most user-visible follow-up.
7. **Progressive merge.** Color the tree per-worker as payloads arrive instead of waiting for the last one — no wall-time change, large perceived-latency change.
8. **Auto worker count tuning.** Auto currently clamps at 8 for memory safety; scale the cap with detected physical cores and available RAM instead (e.g. `min(cores − 1, RAM_GB / 1.5, 16)`).
