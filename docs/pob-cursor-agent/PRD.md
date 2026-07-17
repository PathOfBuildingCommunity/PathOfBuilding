# Product requirements — PoB Cursor Agent

Personal **Path of Exile 1–only** AI **build advisor** embedded beside Path of Building, billed only against the owner's **Cursor** subscription. Non-LLM sidecar is allowed.

**Audience:** implementer on fork `waltersmike/PathOfBuilding`.  
**Not for:** upstream PathOfBuildingCommunity merge.

## 1. Jobs to be done

### Primary — Build advisor

With the user's **current build** loaded in PoB:

- Explain tradeoffs (tree, gear, skills, config) grounded in PoB's live state
- Suggest changes as a **Proposal** the user can inspect, apply, reject, or undo
- Use web/research against **allowlisted PoE1 sources** when the build alone is not enough

### Secondary — Research threads

Separate **research** threads (not bound to a single build) for league/mechanic/meta questions, still PoE1-only and citation-gated.

### Explicit non-jobs (out of scope)

- PoB **power-user** agent (teach the UI, debug imports as the main product)
- PoE2 support or dual-game advice
- Fine-tuning a model
- Second LLM vendor
- Upstream contribution of this feature

## 2. Users and deployment

| Attribute | Decision |
| --- | --- |
| User | Owner of the Cursor subscription (and anyone they hand a key to — runbook deferred) |
| Host app | Personal fork of Path of Building (Lua + SimpleGraphic) |
| LLM | Cursor only (local SDK agent loop; inference Cursor-hosted) |
| Sidecar | Local non-LLM process; owns Agent Window UI and Cursor SDK |

## 3. UX — Agent Window

Locked from [Prototype floating agent window UX](https://github.com/waltersmike/PathOfBuilding/issues/10) (variant **D**).

### Open state

- Narrow **chat stack** (second-monitor friendly)
- Thread chips: **build** vs **research**
- Streaming replies + citations
- **Proposal drawer** at bottom: Apply / Reject / Undo
- Usage meter + model pill (**Composer 2.5**, not Fast)

### Closed state

- Collapses to a **compact connected pill** (re-open from pill) — not dismiss-only

### Rejected chrome for v1

- Always-on split proposal pane (too wide)
- Tabbed Chat/Proposal/History as primary open layout (history via SDK `agentId`, not main chrome)

### Prototype artifact

[`prototype/agent-window/index.html`](./prototype/agent-window/index.html)

### Placement persistence

Pill/window position across monitors/sessions is **deferred** (map fog). Implementer chooses a reasonable default; not a product reopen.

## 4. Core loop — Propose → Diff → Confirm → Apply

1. User chats; sidecar includes a **full build export** every turn (see Architecture / research).
2. Agent may emit a **Proposal**: canonical **ops JSON** (typed ops with PoB ids) plus a human summary for the in-window diff.
3. User **Apply** / **Reject** / **Undo**:
   - **Apply** is **all-or-nothing** across all touched surfaces (tree, items/gems, Configuration, …).
   - **Reject** discards; build unchanged.
   - Before Apply: capture full-build `SaveDB` snapshot; **Undo** restores that snapshot (one-step reverse of the whole proposal).
4. **Compare** tab handoff remains **optional/manual** — nice for full before/after, not required to apply.

PoE2 / unknown-id guards run on ops **before** Apply; failure **hard-refuses** (no override, no partial apply). See [KNOWLEDGE-PACK.md](./KNOWLEDGE-PACK.md) and [adr/0004-poe2-exclusion-fail-closed.md](./adr/0004-poe2-exclusion-fail-closed.md).

## 5. Context every turn

- **Full build snapshot** via PoB `SaveDB` (XML; optional share-code encoding) — strongest existing seam.
- Thread metadata: `threadType: build | research`, `buildId` when build-scoped.
- Knowledge Pack policy + notes available to tools/guards (not pasted wholesale into every prompt unless needed).

## 6. Knowledge and PoE2

| Concern | Rule |
| --- | --- |
| Game | **PoE1 only** |
| Mixing PoE2 as PoE1 truth | **Catastrophic failure** |
| Sources | Allowlist/denylist in `knowledge-pack/policy/` |
| Apply | Proposals may only reference entities present in loaded PoB / PoE1 id sets |
| Research contamination | Refuse + **automatic re-ask** constrained to allowlisted PoE1 / PoB grounding |
| Silent stripping | Forbidden |

## 7. Models and usage

| Setting | Decision |
| --- | --- |
| Default model | **Composer 2.5** (standard — **not** Composer 2.5 Fast) |
| Per-thread opt-up | Allowed to a more capable Cursor model |
| Soft warn | ~80% of configurable cap |
| Hard stop | 100% — block new turns until cap raised/reset |
| Numeric default | Deferred (map fog); implementer ships a configurable default |

Billing is the owner's Cursor plan via **user API key**. No personal hard-budget API from Cursor — caps are **app-level** in the sidecar.

## 8. Failure modes (product-visible)

| Failure | User-visible behavior |
| --- | --- |
| PoE2-risk on Apply | Hard refuse; explain PoE2-risk; no partial apply |
| PoE2-risk in research/chat | Refuse contaminated answer; auto re-ask on allowlisted sources |
| Usage at hard cap | Block new turns; show meter; allow raise/reset |
| Sidecar down / spawn fail | Clear error in PoB or last-known pill state; no silent LLM calls from Lua |
| Cursor rate limit / auth | Surface error; do not retry unbounded |

## 9. Acceptance for “spec complete”

This PRD plus Architecture, ADRs, Knowledge Pack, and Cursor Integration docs are sufficient when an implementer does not need to reopen:

- Primary job and non-jobs
- Window open/closed chrome
- Propose / Apply / Reject / Undo semantics
- PoE2 Exclusion behavior
- Sidecar ownership of UI + Cursor billing model
- Knowledge Pack layout and Sync-via-PR policy

Remaining fog (exact list entries, numeric cap default, placement persistence, friend runbook, Sync cadence, wire schemas) is **implementation detail**, not product discovery.
