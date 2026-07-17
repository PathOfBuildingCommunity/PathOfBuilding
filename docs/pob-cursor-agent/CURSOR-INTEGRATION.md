# Cursor integration guide

How the sidecar talks to Cursor and what surface it exposes to PoB. Product UX: [PRD.md](./PRD.md). ADR: [adr/0003-cursor-local-sdk-user-key.md](./adr/0003-cursor-local-sdk-user-key.md).

**Research basis:** [docs/research/cursor-sdk-pob-agent.md](../research/cursor-sdk-pob-agent.md).

## 1. Auth and billing

| Item | Decision |
| --- | --- |
| Mechanism | Owner **user API key** (`CURSOR_API_KEY` or SDK `apiKey`) |
| Billing | Owner's Cursor subscription pools (same pricing class as IDE) |
| Avoid | Team Admin keys (unsupported); treating Cloud Agents as the live-PoB path |
| Friend handoff | Share key out-of-band; dedicated runbook deferred |

## 2. Runtime shape

| Item | Decision |
| --- | --- |
| SDK | `@cursor/sdk` (TypeScript, Node **22.13+**) or `cursor-sdk` (Python) |
| Mode | **Local** agent loop in the sidecar process |
| Inference | Always Cursor-hosted (“local” ≠ local model) |
| Cloud Agents | Not for live build advice beside PoB |

## 3. Threads and history

| Item | Decision |
| --- | --- |
| Thread types | `build` and `research` |
| Mapping | Each thread ↔ durable Cursor `agentId` |
| Resume | `Agent.resume` / send follow-ups; list via `Agent.messages.list` / conversation APIs |
| IDE history | **Not available** — do not promise Cursor IDE chat reuse |
| UI | Custom Agent Window streams SDK events |

Build-scoped threads carry `buildId` (sidecar multiplexes).

## 4. Tools / MCP

Sidecar exposes PoB operations to the agent via **local `customTools` and/or MCP** (local-only; cloud custom tools throw). Typical tools wrap:

- Request/refresh build snapshot
- Submit proposal ops for UI
- Trigger Apply / Reject / Undo (user-confirmed in UI — tools must not bypass confirm)
- Knowledge Pack / allowlisted fetch helpers
- Usage status

Exact tool names deferred; behavior is normative.

## 5. Usage guardrails (app-level)

Cursor exposes per-run `TokenUsage` and plan/`RateLimitError` signals but **no personal hard-budget API**. Sidecar enforces:

| Threshold | Behavior |
| --- | --- |
| ~80% of configurable cap | Soft warn in UI |
| 100% | **Hard stop** new turns until cap raised/reset |

| Model | Decision |
| --- | --- |
| Default | **Composer 2.5** (standard — **not** Fast) |
| Opt-up | Per-thread allow more capable Cursor models |
| Numeric default cap | Deferred — ship configurable |

## 6. PoB ↔ sidecar message surface

Transport: **localhost HTTP/JSON** (not stdio as the PoB↔sidecar bus). PoB **spawns** the sidecar.

Minimum message kinds:

| Kind | Direction (typical) | Role |
| --- | --- | --- |
| Build snapshot/export | PoB → sidecar | Full `SaveDB` XML (and metadata) each turn / on demand |
| Chat turn | UI → sidecar → Cursor | User text + thread ids |
| Proposal | sidecar → UI | Ops JSON + human summary |
| Apply / Reject / Undo | UI → sidecar → PoB | Confirm path; Undo uses pre-Apply snapshot |
| Usage status | sidecar → UI | Meter + warn/stop |
| PoE2-guard signals | sidecar → UI / PoB | Refuse reasons; Apply hard-fail |

Exact route paths and JSON field names are deferred (map fog). Implementers must preserve kinds and semantics above.

## 7. Lifecycle

1. User opens Agent (or PoB auto-starts sidecar with BUILD mode).
2. Sidecar loads API key, resumes or creates `agentId`s for threads.
3. Turns stream until user collapses to pill or exits PoB.
4. On PoB exit: sidecar shutdown policy is implementer choice (die with parent vs linger) — prefer **die with parent** unless a documented reason not to.

## 8. Hard blockers (do not design around)

From research — treat as constraints, not TODOs:

- No Cursor chat UI embed
- No API to read Cursor IDE chat history
- Cloud VM cannot attach to live Lua PoB

## 9. Related ADRs

- [0001](./adr/0001-sidecar-owned-agent-window.md) — UI placement
- [0002](./adr/0002-apply-all-or-nothing-savedb-undo.md) — Apply/Undo
- [0003](./adr/0003-cursor-local-sdk-user-key.md) — SDK/auth
- [0004](./adr/0004-poe2-exclusion-fail-closed.md) — Exclusion on this surface
