# Knowledge Pack lives in git; Sync always opens a PR

The Knowledge Pack is versioned at repo-root `knowledge-pack/` (not a local-only overlay). **Patch-Notes Sync** updates the pack by committing and **always opening a PR**; human merge is required — no auto-merge to the default branch.

## Layout

| Path | Role |
| --- | --- |
| `knowledge-pack/policy/` | Allowlist, denylist, PoE2 Exclusion **data**; rare manual PRs |
| `knowledge-pack/notes/` | Markdown pitfalls/mechanic notes — primary Sync touch surface |
| Pack `meta` | Current patch / generation for behind-pack detection |

## Staleness → agent

- **Pack-level:** warn when Sync has detected a newer patch and/or pack generation is behind
- **Per-note:** frontmatter `status: active | possibly_stale | retired` + `verified_against_patch`; agent must distrust `possibly_stale` and ignore `retired`

## Sync input

Primary: PoE1 Patch Notes forum HTML (see research). Exact job cadence and operator are deferred.

## Consequences

- First materialize of allowlist/denylist seeds comes from research ticket findings; exact file contents deferred to Assemble/implement.
- Runtime Exclusion behavior is separate ([0004](./0004-poe2-exclusion-fail-closed.md)).
