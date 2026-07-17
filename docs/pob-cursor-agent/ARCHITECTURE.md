# Architecture — PoB Cursor Agent

System shape for the personal PoB build-advisor agent. Product behavior lives in [PRD.md](./PRD.md); irreversible forks live in [adr/](./adr/).

## 1. Context diagram

```text
┌─────────────────────────────────────────────────────────────┐
│  Desktop (owner machine)                                    │
│                                                             │
│  ┌──────────────────────┐     localhost HTTP/JSON           │
│  │ Path of Building     │◄──────────────────────────────────┤
│  │ (Lua / SimpleGraphic)│                                   │
│  │                      │     spawn process                 │
│  │  • build authority   │──────────────────────┐            │
│  │  • SaveDB snapshot   │                      │            │
│  │  • Apply / Undo      │                      ▼            │
│  │  • optional Compare  │           ┌─────────────────────┐ │
│  └──────────────────────┘           │ Sidecar (Node 22+   │ │
│                                       │  or Python)         │ │
│                                       │  • Agent Window UI  │ │
│                                       │  • threads ↔ agentId│ │
│                                       │  • usage caps       │ │
│                                       │  • PoE2 guards      │ │
│                                       │  • @cursor/sdk      │ │
│                                       └─────────┬───────────┘ │
└─────────────────────────────────────────────────┼───────────┘
                                                  │ local agent loop
                                                  ▼
                                        ┌─────────────────────┐
                                        │ Cursor (hosted LLM) │
                                        │  user API key bill  │
                                        └─────────────────────┘

External (tools / Sync, not in hot path of every chat):
  knowledge-pack/   ← git; Sync opens PRs
  allowlisted PoE1 web sources (research tools)
```

## 2. Component responsibilities

| Component | Owns | Does not own |
| --- | --- | --- |
| **PoB (Lua)** | Live build state; `SaveDB` export; Apply/Undo orchestration against tabs; spawning the sidecar | Chat UI; Cursor auth; model choice; Knowledge Pack editing |
| **Sidecar** | Floating Agent Window; Cursor SDK local runtime; thread↔`agentId` map; usage metering; tool/MCP surface; PoE2 gates on chat/research and pre-Apply ops | Authoritative build mutation without PoB confirm path |
| **Cursor** | Inference + durable agent transcripts (`agentId`) | IDE chat history reuse; personal hard-budget API; embeddable chat widget |
| **Knowledge Pack (git)** | Allow/deny policy data; mechanic notes; pack `meta` patch/generation | Runtime enforcement (sidecar); auto-merge Sync |

## 3. Key flows

### 3.1 Chat turn (build thread)

1. PoB (or sidecar on demand) obtains full build XML via `buildMode:SaveDB`.
2. Sidecar sends turn to Cursor local agent with snapshot + tools.
3. Stream renders in Agent Window; citations checked against allowlist.
4. Optional Proposal (ops JSON) lands in proposal drawer.

### 3.2 Apply / Reject / Undo

1. User **Apply** → sidecar validates ops (PoE2 / PoB-id guards) → PoB captures pre-Apply `SaveDB` → PoB applies all-or-nothing → success or hard refuse.
2. **Reject** → discard proposal; no mutation.
3. **Undo** → PoB restores pre-Apply snapshot (held until next Apply or discard).

### 3.3 Research turn

Same Cursor path without requiring a build snapshot (or with optional context). Contaminated answers refuse + auto re-ask on allowlisted sources.

### 3.4 Patch-Notes Sync (offline / maintainer)

Scraper or job reads PoE1 Patch Notes forum HTML → proposes updates under `knowledge-pack/notes/` (+ `meta`) → **always opens a PR**; human merge required.

## 4. Integration seams (from research)

| Need | Verdict | Detail |
| --- | --- | --- |
| Floating UI | **Sidecar window** (chosen) | Lua has no second OS window; `PopupDialog` is modal |
| Snapshot | **Reuse** `SaveDB` | Strongest seam |
| Apply | **Invent** cross-tab orchestrator + rollback | Per-tab helpers exist; no proposal transaction today |
| Compare | **Reuse** optional import-as-comparison | Not on Apply critical path |
| IPC | **Invent** localhost HTTP/JSON | Host has spawn/`lcurl`/files; no agent protocol |

Full write-up: [docs/research/pob-agent-integration-surfaces.md](../research/pob-agent-integration-surfaces.md).

## 5. ADR index

| ADR | Decision |
| --- | --- |
| [0001-sidecar-owned-agent-window.md](./adr/0001-sidecar-owned-agent-window.md) | Agent Window lives in the sidecar, not an in-PoB panel |
| [0002-apply-all-or-nothing-savedb-undo.md](./adr/0002-apply-all-or-nothing-savedb-undo.md) | Multi-surface proposals; all-or-nothing Apply; SaveDB Undo |
| [0003-cursor-local-sdk-user-key.md](./adr/0003-cursor-local-sdk-user-key.md) | Cursor local SDK + owner user API key; no second LLM |
| [0004-poe2-exclusion-fail-closed.md](./adr/0004-poe2-exclusion-fail-closed.md) | Gates + output guard; Apply hard refuse; research re-ask |
| [0005-knowledge-pack-git-pr-sync.md](./adr/0005-knowledge-pack-git-pr-sync.md) | Repo-root `knowledge-pack/`; Sync via PR only |

## 6. Wire schemas (deferred naming)

Minimum **message kinds** between PoB and sidecar (names exactable at implement time):

- Build snapshot / export
- Chat turn
- Proposal (ops JSON)
- Apply / Reject / Undo
- Usage status
- PoE2-guard signals

Exact HTTP routes and ops vocabulary are map fog — behavior above is normative; identifiers are not.
