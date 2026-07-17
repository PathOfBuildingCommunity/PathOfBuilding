# Research: Cursor SDK for a personal PoB desktop agent

**Ticket:** [waltersmike/PathOfBuilding#3](https://github.com/waltersmike/PathOfBuilding/issues/3)  
**Date:** 2026-07-17  
**Scope:** Primary sources only (Cursor docs / help / dashboard pages). No implementation.

## Question

What does the Cursor SDK / agent APIs allow for a **personal desktop** integration that must:

1. Bill only against the **owner’s Cursor subscription**
2. Support a **floating chat UX with history** (prefer reusing Cursor history if feasible)
3. Run via a **non-LLM local sidecar** talking to Lua Path of Building
4. Support **usage guardrails**

## Verdict (short)

**Feasible architecture:** a local Node/Python **sidecar** owns the floating chat UI and PoB IPC; it drives Cursor via **`@cursor/sdk` / `cursor-sdk` local runtime** with the owner’s **user API key**. Inference is always Cursor-hosted; the sidecar is non-LLM plumbing.

**Not feasible from Cursor APIs alone:** embedding Cursor’s IDE chat UI, reading **Cursor IDE** chat history, or hard spend caps on individual plans without **app-level** metering (SDK token usage + plan limits / `RateLimitError`).

---

## 1. Auth model (API keys)

| Claim | Source |
| --- | --- |
| SDK auth is `CURSOR_API_KEY` env or explicit `apiKey` / `api_key` | [TypeScript SDK — Authentication](https://cursor.com/docs/sdk/typescript) |
| Accepted key types: **user API keys** and **team service-account keys**; **Team Admin API keys are not yet supported** | [TypeScript SDK — Authentication](https://cursor.com/docs/sdk/typescript), [Python SDK](https://cursor.com/docs/sdk/python) |
| User keys: Cursor Dashboard → API Keys (`https://cursor.com/dashboard/api`) | [TypeScript SDK — Authentication](https://cursor.com/docs/sdk/typescript), [API Overview](https://cursor.com/docs/api) |
| Service-account keys: team settings (team/enterprise path) | [TypeScript SDK — Authentication](https://cursor.com/docs/sdk/typescript), [Cloud Agents API overview](https://cursor.com/docs/cloud-agent/api/overview) |
| REST APIs use Basic auth (`API_KEY` as username, empty password); Cloud Agents API also accepts Bearer | [API Overview](https://cursor.com/docs/api) |
| Cloud Agents API keys: user key or service-account key | [Cloud Agents API](https://cursor.com/docs/cloud-agent/api/endpoints) |
| `Cursor.me()` / `GET /v1/me` (and legacy `GET /v0/me`) return API key / caller identity metadata | [TypeScript SDK — Cursor.me()](https://cursor.com/docs/sdk/typescript), [Cloud Agents API — API Key Info](https://cursor.com/docs/cloud-agent/api/endpoints), [v0 API Key Info](https://cursor.com/docs/cloud-agent/api/v0) |

**Implication for PoB:** use a **user API key** belonging to the subscription owner so spend lands on that user’s plan (see §5). Do not use Team Admin keys. Friend handoff = share that key out-of-band (product decision; docs do not provide a delegated-user OAuth flow for SDK).

---

## 2. Local vs cloud runtimes

| Claim | Source |
| --- | --- |
| One SDK interface for **local** and **cloud** | [TypeScript SDK — Overview](https://cursor.com/docs/sdk/typescript) |
| **Local:** agent loop runs in the caller process; files from disk/`cwd` | [TypeScript SDK — Overview](https://cursor.com/docs/sdk/typescript) |
| **Cloud:** Cursor-hosted VM; repo cloned; survives caller disconnect | [TypeScript SDK — Overview](https://cursor.com/docs/sdk/typescript), [Cloud Agents API](https://cursor.com/docs/cloud-agent/api/endpoints) |
| **“Local” ≠ local model** — all inference goes through Cursor-hosted models in both modes | [TypeScript SDK — Local means local agent loop, not local model](https://cursor.com/docs/sdk/typescript) |
| Same `CURSOR_API_KEY` for either runtime | [TypeScript SDK — Overview](https://cursor.com/docs/sdk/typescript) |
| Local agent IDs: `agent-…`; cloud: `bc-…` | [TypeScript SDK — Creating agents / resume](https://cursor.com/docs/sdk/typescript) |
| TS SDK requires **Node.js 22.13+**; ships platform binaries (sandbox/ripgrep) | [TypeScript SDK — Installation](https://cursor.com/docs/sdk/typescript) |
| Cloud Agents API is **public beta**; oriented at repository workflows (repos, PRs, artifacts) | [Cloud Agents API overview](https://cursor.com/docs/cloud-agent/api/overview) |
| Cloud create can omit repos for a **no-repo** agent, but still runs in Cursor’s cloud environment | [Cloud Agents API — Create An Agent](https://cursor.com/docs/cloud-agent/api/endpoints) |

**Implication for PoB:** prefer **local runtime**. The live Lua PoB process and build state live on the desktop; cloud VMs cannot attach to that process. Cloud remains useful only for repo-bound chores (e.g. editing the fork), not for the advisor sitting beside PoB.

---

## 3. History / conversation APIs

### What exists (SDK / Cloud Agents)

| Capability | Notes | Source |
| --- | --- | --- |
| **Agent** = durable conversation container across prompts | Follow-ups via `agent.send` keep context | [TypeScript SDK — Core concepts / Sending messages](https://cursor.com/docs/sdk/typescript) |
| **`Agent.resume(agentId)`** | Continue after process restart; runtime from ID prefix | [TypeScript SDK — Resuming agents](https://cursor.com/docs/sdk/typescript) |
| **`run.conversation()`** | Structured turns for the current run | [TypeScript SDK — conversation()](https://cursor.com/docs/sdk/typescript) |
| **`Agent.messages.list(agentId)`** (local) | Stored user/assistant messages for a local agent | [TypeScript SDK — Agent.messages.list()](https://cursor.com/docs/sdk/typescript) |
| Python: **`agent.list_messages()`** | Same idea on the agent handle | [Python SDK](https://cursor.com/docs/sdk/python) |
| Local persistence | Default on-disk SQLite under home; optional JSONL / custom `local.store` | [TypeScript SDK — Conversation context / Local store](https://cursor.com/docs/sdk/typescript) |
| Cloud persistence | Server-side; list/get/archive/delete agents | [TypeScript SDK — Cloud agent lifecycle](https://cursor.com/docs/sdk/typescript), [Cloud Agents API](https://cursor.com/docs/cloud-agent/api/endpoints) |
| Legacy **`GET /v0/agents/{id}/conversation`** | Full cloud agent transcript (user + assistant texts) | [Cloud Agents API v0 — Agent Conversation](https://cursor.com/docs/cloud-agent/api/v0) |
| v1 Cloud API | Agents + runs + stream + usage; conversation continuity via follow-up runs on the same agent | [Cloud Agents API endpoints](https://cursor.com/docs/cloud-agent/api/endpoints) |

### What is **not** documented

| Gap | Impact |
| --- | --- |
| **No API to read Cursor IDE / Composer chat history** | “Reuse Cursor history” cannot mean IDE threads; only **SDK/Cloud agent** transcripts |
| **No embeddable Cursor chat widget** | Floating UX must be **custom UI** in the sidecar (or other host), streaming `run.stream()` / Python `run.messages()` |
| Cookbook mentions “embedded in-product agents” as a use case for the SDK (caller builds the product surface) | [TypeScript SDK — Cookbook](https://cursor.com/docs/sdk/typescript) |

**Implication for PoB:** map **per-build threads** → durable SDK `agentId`s (one agent per build thread + one for research). Persist/resume those IDs in the sidecar. Render history from `Agent.messages.list` / stream events — not from the Cursor IDE.

---

## 4. Sidecar ↔ PoB (non-LLM local bridge)

| Claim | Source |
| --- | --- |
| Local agents can register **`local.customTools`** (in-process functions exposed as MCP `custom-user-tools`) | [TypeScript SDK — Custom tools](https://cursor.com/docs/sdk/typescript) |
| Custom tools are **local-only**; on cloud they throw `ConfigurationError` | [TypeScript SDK — Custom tools](https://cursor.com/docs/sdk/typescript) |
| MCP servers (stdio/HTTP) can be passed inline on create/send | [TypeScript SDK — MCP servers](https://cursor.com/docs/sdk/typescript), [Cursor MCP](https://cursor.com/docs/mcp) |
| Hooks are **file-based only** (`.cursor/hooks.json`); no programmatic hook callbacks | [TypeScript SDK — Hooks](https://cursor.com/docs/sdk/typescript) |
| Default local sandbox is **off**; headless runs have no human approval UI | [TypeScript SDK — Sandbox options](https://cursor.com/docs/sdk/typescript) |
| Optional `local.sandboxOptions.enabled` + `local.autoReview` for safer tool execution | [TypeScript SDK — Sandbox / Auto-review](https://cursor.com/docs/sdk/typescript) |

**Implication for PoB:** the **sidecar** (Node 22+ or Python) should:

1. Own IPC to Lua PoB (export build, apply confirmed diffs, etc.)
2. Expose PoB operations to the agent via **custom tools** and/or a **stdio MCP** server
3. Keep LLM calls exclusively through Cursor SDK (satisfies “no second LLM vendor”)

Cursor does not need to know about Lua; the sidecar is the adapter.

---

## 5. Pricing / subscription pooling

| Claim | Source |
| --- | --- |
| SDK runs use the **same pricing, request pools, and Privacy Mode rules** as IDE and Cloud Agents | [TypeScript SDK — Usage and billing](https://cursor.com/docs/sdk/typescript) |
| Spend appears on the usage dashboard under an **SDK** tag | [TypeScript SDK — Usage and billing](https://cursor.com/docs/sdk/typescript) → [usage dashboard](https://cursor.com/dashboard/usage) |
| **User API keys bill to that user’s plan**; service-account keys bill to the **team** | [TypeScript SDK — Usage and billing](https://cursor.com/docs/sdk/typescript) |
| Individual plans: two pools — **First-party models** (Auto, Composer 2.5, Grok 4.5) and **API** (model API rates); included amounts by tier (e.g. Pro $20 API / month) | [Models & Pricing](https://cursor.com/docs/models-and-pricing), [Usage and limits](https://cursor.com/help/models-and-usage/usage-limits) |
| Over included usage → on-demand pay-as-you-go or upgrade | [Models & Pricing](https://cursor.com/docs/models-and-pricing), [Usage and limits](https://cursor.com/help/models-and-usage/usage-limits) |
| Usage resets with billing cycle; unused does not roll over | [Usage and limits](https://cursor.com/help/models-and-usage/usage-limits), [Billing](https://cursor.com/help/account-and-billing/billing) |
| Team spend limits / Admin spend APIs are **Teams/Enterprise** features | [Team dashboard](https://cursor.com/docs/account/teams/dashboard), [Admin API](https://cursor.com/docs/account/teams/admin-api), [API Overview](https://cursor.com/docs/api) |
| Cloud Agents API + TS/Python SDKs listed as available to **All users** (Cloud Agents beta) | [API Overview](https://cursor.com/docs/api) |

**Implication for PoB:** owner’s **user key** → owner’s subscription pools. No separate Cursor “product billing” for a personal sidecar. Friend using the owner’s key also draws from the **owner’s** pools (same key → same plan). There is **no documented subscription pooling** across separate individual accounts without a Team/Enterprise arrangement.

---

## 6. Usage guardrails (what Cursor gives vs what you build)

### Provided by Cursor

| Mechanism | Source |
| --- | --- |
| Per-run **`TokenUsage`** (`inputTokens`, `outputTokens`, cache, `totalTokens`) on `run.usage` / `result.usage` and `"usage"` stream events | [TypeScript SDK — Token usage](https://cursor.com/docs/sdk/typescript) |
| Cloud **`GET /v1/agents/{id}/usage`** (totals + per-run) | [Cloud Agents API — Get Agent Usage](https://cursor.com/docs/cloud-agent/api/endpoints) |
| Plan monthly included usage + dashboard visibility | [Usage and limits](https://cursor.com/help/models-and-usage/usage-limits), [Models & Pricing](https://cursor.com/docs/models-and-pricing) |
| SDK **`RateLimitError`** for burst limits or **usage limit exceeded** | [TypeScript SDK — Errors](https://cursor.com/docs/sdk/typescript) (via docs error table) |
| HTTP **429** on REST APIs when rate-limited | [API Overview — Rate Limits](https://cursor.com/docs/api) |
| Cloud Agents: “Standard rate limiting” (not a fixed published RPM in the overview table) | [API Overview](https://cursor.com/docs/api) |
| Hooks / sandbox / auto-review for **tool-call** policy (not dollar caps) | [TypeScript SDK — Hooks / Sandbox / Auto-review](https://cursor.com/docs/sdk/typescript) |
| Team Admin **user spend limits** (Enterprise Admin API) — not the personal Hobby/Pro path | [Admin API](https://cursor.com/docs/account/teams/admin-api) |

### Not provided (hard gap for “usage guardrails”)

- No documented **SDK method to set a personal hard dollar/token budget** before a run.
- No documented API for an individual Pro user to programmatically read **remaining monthly allowance** (Admin/Analytics spend endpoints are team/enterprise-oriented).
- Guardrails for the PoB product must be **implemented in the sidecar**: sum `TokenUsage`, stop/warn before `send`, choose cheaper models (`Cursor.models.list` / prefer First-party pool models), and handle `RateLimitError`.

---

## 7. Constraints & hard blockers for embedding beside PoB

### Hard blockers / non-starters

1. **No Cursor-hosted floating chat UI or IDE embed API** — you build the window; SDK is headless. ([TypeScript SDK](https://cursor.com/docs/sdk/typescript) describes programmatic agent control, not UI embedding.)
2. **No access to Cursor IDE chat history** — only SDK/Cloud agent transcripts (§3).
3. **Cloud runtime cannot drive live PoB** — isolated VM / repo workflow; no path to the local Lua process. ([Cloud Agents API](https://cursor.com/docs/cloud-agent/api/endpoints), [SDK local vs cloud](https://cursor.com/docs/sdk/typescript))
4. **Inference is never fully local** — “local” agent still bills Cursor-hosted models. ([SDK — Local means local agent loop](https://cursor.com/docs/sdk/typescript))
5. **Team Admin keys unsupported** by SDK. ([SDK Authentication](https://cursor.com/docs/sdk/typescript))

### Soft constraints (design around them)

| Constraint | Mitigation |
| --- | --- |
| Node **22.13+** for `@cursor/sdk` | Bundle/require that runtime in the sidecar, or use Python SDK |
| Local tools unrestricted by default | Enable sandbox/auto-review; prefer confirm-before-apply in **your** UX (product already wants propose → confirm → apply) |
| Inline MCP secrets not persisted across `resume` | Re-pass MCP/custom tools on resume ([SDK resume notes](https://cursor.com/docs/sdk/typescript)) |
| Large context (full PoB export every turn) burns included usage quickly | Prefer First-party pool models where possible; meter tokens; optimize later |
| Public beta surfaces (SDK + Cloud Agents API) | Expect breaking changes before GA ([Cloud Agents overview](https://cursor.com/docs/cloud-agent/api/overview); SDKs marked public beta in skill/docs) |

### Fit vs requirements checklist

| Requirement | Fit |
| --- | --- |
| (1) Bill only owner subscription | **Yes** with owner **user API key** |
| (2) Floating chat + history | **Yes** with custom UI + SDK agent history; **No** reusing IDE history |
| (3) Non-LLM sidecar ↔ Lua PoB | **Yes** (local SDK + custom tools / MCP) |
| (4) Usage guardrails | **Partial** — telemetry + plan limits + app-enforced caps; no first-class personal budget API |

---

## 8. Recommended integration shape (research-only)

```
┌─────────────────────┐     IPC      ┌──────────────────────────────┐
│ Path of Building    │◄────────────►│ Local sidecar (Node/Python)  │
│ (Lua, desktop)      │  export/apply│  • floating chat UI          │
└─────────────────────┘              │  • thread → agentId map      │
                                     │  • usage metering/guardrails │
                                     │  • customTools / MCP → PoB   │
                                     └──────────────┬───────────────┘
                                                    │ @cursor/sdk local
                                                    │ CURSOR_API_KEY (user)
                                                    ▼
                                     ┌──────────────────────────────┐
                                     │ Cursor hosted models / pools │
                                     └──────────────────────────────┘
```

Do **not** route the advisor through Cloud Agents for day-to-day build advice.

---

## Primary sources consulted

- [Cursor TypeScript SDK](https://cursor.com/docs/sdk/typescript)
- [Cursor Python SDK](https://cursor.com/docs/sdk/python)
- [Cursor APIs Overview](https://cursor.com/docs/api)
- [Cloud Agents API (v1)](https://cursor.com/docs/cloud-agent/api/endpoints)
- [Cloud Agents API v0 (legacy conversation endpoint)](https://cursor.com/docs/cloud-agent/api/v0)
- [Models & Pricing](https://cursor.com/docs/models-and-pricing)
- [Usage and limits (help)](https://cursor.com/help/models-and-usage/usage-limits)
- [Pricing / plans (help)](https://cursor.com/help/account-and-billing/pricing)
- [Billing (help)](https://cursor.com/help/account-and-billing/billing)
- [Team dashboard (spend limits context)](https://cursor.com/docs/account/teams/dashboard)
- [Admin API (team spend limits)](https://cursor.com/docs/account/teams/admin-api)
- Cursor Dashboard links referenced by docs: [API Keys](https://cursor.com/dashboard/api), [Usage](https://cursor.com/dashboard/usage)

Also cross-checked against the in-Cursor `/sdk` skill (`~/.cursor/skills-cursor/sdk/SKILL.md`), which points at the same official SDK docs as canonical.
