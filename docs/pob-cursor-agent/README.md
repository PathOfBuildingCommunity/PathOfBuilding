# PoB Cursor Agent — handoff pack

Index for the **personal Path of Exile 1–only** AI **build-advisor** agent for Path of Building, powered by the owner's **Cursor subscription only** (non-LLM sidecar allowed).

**Map:** [PoB Cursor Agent — handoff spec map](https://github.com/waltersmike/PathOfBuilding/issues/1)

**Scope of this pack:** product + technical specification dense enough that an implementer can build without redoing discovery. **Implementing the agent is out of scope for the map**; these docs *are* the destination.

**Fork only:** `waltersmike/PathOfBuilding`. Never for PathOfBuildingCommunity merge.

## How to read

| Order | Doc | Owns |
| --- | --- | --- |
| 1 | [PRD.md](./PRD.md) | Jobs, UX, propose→apply loop, failure modes, out of scope |
| 2 | [ARCHITECTURE.md](./ARCHITECTURE.md) | System diagram, component responsibilities, ADR index |
| 3 | [adr/](./adr/) | Irreversible forks (sidecar UI, apply/undo, Cursor local SDK, PoE2 gates, Knowledge Pack layout) |
| 4 | [KNOWLEDGE-PACK.md](./KNOWLEDGE-PACK.md) | Pack schema, Sync policy, staleness, PoE2 Exclusion data vs runtime |
| 5 | [CURSOR-INTEGRATION.md](./CURSOR-INTEGRATION.md) | Auth, SDK runtime, threads/history, usage caps, message surface |

## Research (linked, not copied)

| Topic | Doc | Branch (authored on) |
| --- | --- | --- |
| Cursor SDK / billing / history | [docs/research/cursor-sdk-pob-agent.md](../research/cursor-sdk-pob-agent.md) | `research/cursor-sdk-pob-agent` |
| PoB Lua seams (snapshot, apply, float, IPC) | [docs/research/pob-agent-integration-surfaces.md](../research/pob-agent-integration-surfaces.md) | `research/pob-agent-integration-surfaces` |
| PoE1 sources + patch-notes feeds | [docs/research/poe1-knowledge-sources-patch-notes.md](../research/poe1-knowledge-sources-patch-notes.md) | `research/poe1-knowledge-sources` |

## Prototype

| Artifact | Path | Branch |
| --- | --- | --- |
| Floating agent window UX (variant **D** default) | [prototype/agent-window/index.html](./prototype/agent-window/index.html) | `prototype/agent-window-ux` |

## Destination complete checklist

An implementer should be able to start from this pack alone when:

- [x] All files listed above exist under `docs/pob-cursor-agent/`
- [x] Required sections filled (no TBD in those sections)
- [x] Expected ADRs written
- [x] Research remains under `docs/research/` and is linked, not pasted into product docs
- [x] Map [Decisions so far](https://github.com/waltersmike/PathOfBuilding/issues/1) lists every closed ticket; no open map tickets remain after Assemble

## Materialized (issue #13)

- Repo-root `knowledge-pack/` with `policy/`, `notes/`, `meta.yaml` — see [knowledge-pack/README.md](../../knowledge-pack/README.md)
- Pure PoE2 policy evaluators + tests in `sidecar/src/policy/`

## Deferred (not blocking this pack)

Left on the map as **Not yet specified** — pin during implementation, not here:
- Concrete numeric default for usage cap
- Window/pill placement persistence across monitors/sessions
- Friend handoff runbook
- Sync job cadence / who runs the scraper
- Exact ops vocabulary and HTTP route/schema names
