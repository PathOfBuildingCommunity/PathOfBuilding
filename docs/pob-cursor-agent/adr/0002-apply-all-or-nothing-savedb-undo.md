# All-or-nothing Apply with SaveDB Undo

A Proposal may touch multiple surfaces (tree, items/gems, Configuration, …). **Apply is all-or-nothing** — no partial or per-section Apply. Before Apply, PoB captures a full-build `SaveDB` snapshot; **Undo** restores that snapshot (one-step reverse of the whole proposal). Reject discards the Proposal with no mutation.

## Why

Per-tab undo/load helpers exist, but there is no cross-tab proposal transaction. Full-build replace via Import-style `Shutdown`+`Init(xml)` is the reliable seam; wrapping it with a pre-Apply snapshot gives a clear rollback story without inventing multi-tab undo stacks.

## Format

- **Ops JSON** (typed ops with PoB ids) is canonical for validation and Apply.
- In-window diff shows a **human summary** derived from ops; deeper/XML detail may be optional.
- Compare-tab handoff stays optional/manual — not required for Apply.

## Consequences

- Contaminated or invalid ops fail the entire Apply (ties to PoE2 Exclusion ADR).
- Snapshot retention: held until next Apply or explicit discard.
