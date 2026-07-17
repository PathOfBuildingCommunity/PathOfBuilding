# Cursor local SDK with owner user API key

LLM access is **Cursor only**, via `@cursor/sdk` / `cursor-sdk` **local** runtime in the sidecar, authenticated with the owner's **user API key** (bills their subscription pools). Cloud Agents are the wrong shape for a live desktop PoB session. There is no second LLM vendor and no fine-tune.

## Why

- Local agent loop can sit beside Lua PoB; cloud VMs cannot attach to the live process.
- User API keys map spend to the owner; Team Admin keys are unsupported by the SDK.
- Cursor does not expose embeddable IDE chat or IDE history APIs — custom Agent Window + SDK `agentId` resume is mandatory anyway.

## Guardrails

- Default model: **Composer 2.5** (not Fast); per-thread opt-up allowed.
- Soft warn ~80% / hard stop at 100% of an **app-level** configurable cap (Cursor has no personal hard-budget API).

## Consequences

- Sidecar requires Node 22.13+ (or Python SDK equivalent) and network to Cursor.
- Friend handoff implies sharing a key out-of-band (runbook deferred).
