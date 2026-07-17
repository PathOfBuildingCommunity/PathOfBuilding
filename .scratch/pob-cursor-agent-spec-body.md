## Problem Statement

As a Path of Exile 1 player using Path of Building, I want an AI build advisor that understands my live build and PoE1 sources, so I can get grounded suggestions and apply them safely without leaving PoB or paying a second LLM vendor. Today I either leave PoB for chat tools that do not see my build, or risk PoE2/wrong-game contamination and irreversible edits with no clear undo.

## Solution

A personal (fork-only) **PoB Cursor Agent**: PoB remains build authority; a local **sidecar** owns a floating Agent Window and talks to **Cursor** via the local SDK using the owner's user API key. The agent advises on the current build (and separate research threads), proposes multi-surface changes as ops the user can inspect, then **Apply / Reject / Undo** over a localhost HTTP/JSON bridge. PoE2 Exclusion is fail-closed. A git **Knowledge Pack** supplies allow/deny policy and notes; Patch-Notes Sync always opens a PR.

Canonical discovery docs: `docs/pob-cursor-agent/` (map: https://github.com/waltersmike/PathOfBuilding/issues/1).

## User Stories

1. As a PoB user, I want a floating Agent Window beside PoB, so that I can chat about my build without blocking the main PoB UI.
2. As a PoB user, I want the open window to be a narrow chat stack, so that it fits a second monitor and does not dominate the desk.
3. As a PoB user, I want build and research thread chips, so that I can separate build-scoped advice from general PoE1 research.
4. As a PoB user, I want streaming replies with citations, so that I can see answers arrive and judge their sources.
5. As a PoB user, I want a proposal drawer with Apply, Reject, and Undo, so that suggestions never mutate my build without confirmation.
6. As a PoB user, I want a usage meter and model pill showing Composer 2.5 by default, so that I know spend and which model I am on.
7. As a PoB user, I want closing the window to leave a compact connected pill, so that I can reopen quickly without hunting menus.
8. As a PoB user, I want PoB to spawn the sidecar for me, so that I do not run a separate manual process every session.
9. As a PoB user, I want the sidecar to shut down with PoB by default, so that orphan agent processes do not linger.
10. As a PoB user, I want every build-thread turn to include a full build export (`SaveDB`), so that advice is grounded in my live tree, items, skills, and config.
11. As a PoB user, I want research threads that do not require a build, so that I can ask league/mechanic questions independently.
12. As a PoB user, I want proposals that may touch tree, items/gems, and Configuration together, so that coherent multi-surface changes arrive as one unit.
13. As a PoB user, I want Apply to be all-or-nothing, so that I never end up with a half-applied proposal.
14. As a PoB user, I want Reject to discard the proposal with no build change, so that I can ignore bad advice safely.
15. As a PoB user, I want Undo to restore the pre-Apply full-build snapshot, so that one confirmed Apply is reversible in one step.
16. As a PoB user, I want the in-window diff to show a human summary derived from ops JSON, so that I can review intent without reading raw XML.
17. As a PoB user, I want optional manual handoff into Compare, so that I can use PoB's before/after when I choose—not as a required Apply step.
18. As a PoB user, I want PoE2-risk Apply attempts to hard-refuse with a clear explanation, so that wrong-game data never lands on my build.
19. As a PoB user, I want contaminated research/chat answers to be refused and automatically re-asked on allowlisted PoE1 sources, so that I am not shown PoE2 "for comparison."
20. As a PoB user, I want denylisted hosts and paths blocked before the model consumes them, so that PoE2 lookalikes never enter context.
21. As a PoB user, I want same-named skills/items absent from PoB/PoE1 id sets to fail Apply, so that name collisions cannot smuggle PoE2 entities in.
22. As a PoB user, I want no silent stripping of bad citations or ops, so that failures are visible and honest.
23. As a PoB user, I want a soft warning near ~80% of my usage cap, so that I can slow down before hard stop.
24. As a PoB user, I want a hard stop at 100% of the configurable cap, so that spend cannot runaway without my raising the cap.
25. As a PoB user, I want to raise or reset the cap after a hard stop, so that I can continue when I choose.
26. As a PoB user, I want per-thread opt-up to a more capable Cursor model, so that hard problems can use a stronger model without changing the default.
27. As a PoB user, I want billing only against my Cursor subscription via my user API key, so that I do not pay a second LLM vendor.
28. As a PoB user, I want thread history to resume via Cursor agent ids, so that conversations survive sidecar restarts.
29. As a PoB user, I want a clear error if the sidecar fails to spawn or dies, so that I am not left thinking the agent is working.
30. As a PoB user, I want Cursor auth and rate-limit failures surfaced without unbounded retries, so that failures are diagnosable.
31. As a PoB user, I want Knowledge Pack notes with active / possibly_stale / retired status, so that the agent distrusts stale guidance and ignores retired notes.
32. As a PoB user, I want a pack-level staleness warning when Sync detects a newer patch, so that I know advice may lag the league.
33. As a maintainer of the personal fork, I want Knowledge Pack policy and notes in git under `knowledge-pack/`, so that policy is reviewable and versioned.
34. As a maintainer, I want Patch-Notes Sync to always open a PR with human merge, so that pack updates never auto-merge quietly.
35. As a maintainer, I want Sync to prefer PoE1 Patch Notes forum HTML (`3.x`), so that PoE2 Early Access forum content is excluded.
36. As a maintainer, I want allowlist/denylist seeds covering official PoE1, poewiki, poe.ninja/poe1, and known PoE2 traps, so that Exclusion has concrete data.
37. As an implementer, I want tools that request snapshots and submit proposals without bypassing user confirm, so that Apply remains human-gated.
38. As an implementer, I want the Agent Window UX to match the locked prototype (open stack+drawer; closed pill), so that chrome is not rediscovered.
39. As an implementer, I want this feature only on the personal fork, so that upstream PathOfBuildingCommunity is never targeted.
40. As a PoB user, I do not want a PoB power-user tutor as the primary product, so that scope stays on build advising.
41. As a PoB user, I do not want PoE2 support or dual-game advice, so that Exclusion stays absolute.
42. As a PoB user, I do not want fine-tuning or a second LLM vendor, so that the stack stays Cursor-only plus non-LLM sidecar.

## Implementation Decisions

### Architecture

- Dual process: **PoB (Lua)** is build authority; **sidecar** owns Agent Window UI, Cursor local SDK, usage metering, PoE2 gates, and tool/MCP surface.
- Transport between PoB and sidecar: **localhost HTTP/JSON** (not stdio as the bus). PoB spawns the sidecar.
- Cursor: local agent loop (`@cursor/sdk` / `cursor-sdk`); owner **user API key**; Cloud Agents are not the live-PoB path.
- Default model: **Composer 2.5** (not Fast); per-thread opt-up allowed.
- Knowledge Pack at repo-root `knowledge-pack/` with `policy/`, `notes/`, and pack `meta`; Sync updates via PR only.

### PoB-facing modules (conceptual)

- Agent bridge module: spawn/monitor sidecar; serve/consume bridge message kinds (snapshot export, apply/reject/undo, guard/usage signals as needed).
- Snapshot: reuse full-build `SaveDB` (XML; optional share-code encoding).
- Apply orchestrator: all-or-nothing multi-surface apply; capture pre-Apply `SaveDB` for Undo; Reject leaves build unchanged.
- Compare handoff: reuse existing import-as-comparison path optionally; not on the Apply critical path.
- Do not use modal `PopupDialog` as the chat surface.

### Sidecar-facing modules (conceptual)

- Agent Window UI matching prototype variant D (narrow chat + proposal drawer; compact pill when closed).
- Thread multiplex: `threadType: build | research` + `buildId` when build-scoped; map each thread to a durable Cursor `agentId`.
- Cursor adapter: create/resume agents, stream turns, expose local custom tools and/or MCP for PoB operations (tools must not bypass Apply confirm).
- Usage guardrails: soft warn ~80%; hard stop at 100% of configurable cap (numeric default implementer-chosen).
- PoE2 Exclusion runtime: source/tool gates + output guard + Apply id checks; research contamination → refuse + automatic re-ask.

### Bridge message kinds (normative; exact route/field names implementer-chosen)

- Build snapshot/export
- Chat turn
- Proposal (canonical **ops JSON** with PoB ids + human summary)
- Apply / Reject / Undo
- Usage status
- PoE2-guard signals

### Proposal / Apply semantics

- Ops JSON is canonical for validation and Apply; UI summary is derived.
- Apply validates PoE2 / PoB-id guards **before** mutation; failure hard-refuses entire Apply (no partial, no override).
- Undo snapshot held until next Apply or explicit discard.

### Prototype-encoded UX (from `docs/pob-cursor-agent/prototype/agent-window`)

Open chrome = chat stack + bottom proposal drawer (Apply / Reject / Undo) + usage meter + model pill; closed = compact connected pill (not dismiss-only). Rejected for v1: always-on split proposal pane; tabbed Chat/Proposal/History as primary open layout.

### Deferred implementer details (not product rediscovery)

- Exact allowlist/denylist file contents (seed sets documented in Knowledge Pack design)
- Concrete numeric usage-cap default
- Window/pill placement persistence
- Friend handoff runbook
- Sync job cadence / operator
- Exact HTTP routes, JSON field names, and ops vocabulary

### Fork policy

- Build only on `waltersmike/PathOfBuilding`. Never for upstream merge.

## Testing Decisions

### What makes a good test

- Assert **external behavior** at agreed seams (protocol outcomes, build state before/after, policy allow/deny/refuse), not private implementation details or UI pixels.
- Prefer highest seams; mock Cursor network; do not require live Cursor or live PoE websites for the core suite.
- Fail-closed PoE2 cases must be explicit tests (URL/domain deny, same-name Apply refuse, mixed citation refuse+re-ask).

### Seams (agreed)

1. **Primary — Agent Bridge contract (localhost HTTP/JSON)**
   - PoB/Lua side: Busted + `HeadlessWrapper` — `SaveDB` export, all-or-nothing Apply, Undo restores pre-Apply snapshot.
   - Sidecar side: in-process HTTP with Cursor SDK mocked — turn packaging, proposal handoff, guard/usage signals.
2. **Secondary — PoE2 / Knowledge Pack policy (pure)**
   - Pure functions over policy data + ops/citations for allow/deny, same-name Apply refusal, mixed-citation re-ask.
   - Mandatory fail-closed acceptance suite lives here and/or is exercised through Bridge Apply refuse.

### Explicitly not v1 automated seams

- Agent Window layout/pixel tests (prototype is the visual reference).
- Live Cursor API calls.
- Full Patch-Notes Sync scraper E2E (PR-only policy is the product rule; scraper can be thinner/manual later).

### Modules under test

- PoB agent bridge / apply-undo orchestration (via HeadlessWrapper).
- Sidecar bridge handlers and usage/guard signaling (mocked Cursor).
- Knowledge Pack policy evaluators.

### Prior art in this codebase

- Busted under `spec/System` (Docker/`busted --lua=luajit`); build lifecycle via `HeadlessWrapper` (`newBuild`, load XML).
- Import/reimport and tree/item specs show how to assert build state after mutations without the GUI.
- Sidecar tests will be new (Node 22.13+ or Python) alongside the Lua suite; keep them behavior-focused at the HTTP contract.

## Out of Scope

- Upstream PathOfBuildingCommunity contribution or merge of this feature
- PoE2 support or dual-game advice
- Fine-tuning a model; second LLM vendor
- PoB power-user agent as primary job (teach UI / debug imports as the product)
- Embedding Cursor IDE chat UI or reading Cursor IDE chat history
- Auto-merge of Knowledge Pack Sync PRs
- Friend handoff runbook and numeric cap default as blockers to starting implementation (ship sensible defaults)

## Further Notes

- Wayfinder map (closed): https://github.com/waltersmike/PathOfBuilding/issues/1
- Handoff pack index: `docs/pob-cursor-agent/README.md`
- Research: `docs/research/cursor-sdk-pob-agent.md`, `docs/research/pob-agent-integration-surfaces.md`, `docs/research/poe1-knowledge-sources-patch-notes.md`
- ADRs under `docs/pob-cursor-agent/adr/` (sidecar UI, Apply/Undo, Cursor local SDK, PoE2 fail-closed, Knowledge Pack PR Sync)
- Next skill after this spec: `/to-tickets` to split into tracer-bullet implementation tickets with blocking edges
