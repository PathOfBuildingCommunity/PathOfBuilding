# Knowledge Pack design

Design for the versioned PoE1 knowledge layer that grounds research tools and PoE2 Exclusion **data**. Runtime enforcement behavior is in [adr/0004-poe2-exclusion-fail-closed.md](./adr/0004-poe2-exclusion-fail-closed.md); layout/Sync policy ADR: [adr/0005-knowledge-pack-git-pr-sync.md](./adr/0005-knowledge-pack-git-pr-sync.md).

**Research basis:** [docs/research/poe1-knowledge-sources-patch-notes.md](../research/poe1-knowledge-sources-patch-notes.md).

## 1. Location and ownership

| Item | Decision |
| --- | --- |
| Root | Repo-root `knowledge-pack/` |
| Versioning | Git on the personal fork |
| Local overlays | None — Sync updates land via commits/PRs |
| Runtime enforcement | Sidecar (not the pack files themselves) |

## 2. Directory schema

```text
knowledge-pack/
  policy/          # allowlist, denylist, exclusion rule data (rare manual PRs)
  notes/           # markdown mechanic/pitfall notes (primary Sync surface)
  meta             # or meta.json / meta.yaml — current patch + pack generation
```

Exact filenames inside `policy/` are fixed at first materialize (deferred). Required **kinds** of data:

| Kind | Purpose |
| --- | --- |
| Allowlist | Hosts/paths/namespaces the agent may fetch or cite for PoE1 |
| Denylist | PoE2 and lookalike traps (hosts, forum sections, path prefixes) |
| Exclusion extras | Any non-URL rules needed by gates (e.g. forum id `2212`) |
| Notes | Human-maintained pitfalls; Sync may add/retire |
| Meta | `current_patch` / generation counters for behind-pack warnings |

## 3. Note frontmatter (normative fields)

Every note under `notes/` carries:

```yaml
status: active | possibly_stale | retired
verified_against_patch: "<PoE1 patch id, e.g. 3.29.0>"
```

Agent rules:

- Trust `active` notes aligned with current pack meta
- **Distrust** `possibly_stale` (may cite with caution / prefer re-fetch)
- **Ignore** `retired`

## 4. Allowlist / denylist seeds (from research)

Exact file contents are deferred; **seed sets** an implementer must encode:

### Allowlist (PoE1)

- Official: `pathofexile.com` — especially [Patch Notes forum](https://www.pathofexile.com/forum/view-forum/patch-notes), developer docs/data exports, trade API; `grindinggear/skilltree-export` / atlastree-export
- Wiki: `poewiki.net` (+ MediaWiki/Cargo API; plan for Anubis bot protection)
- Economy/builds: `poe.ninja/poe1/*` (legacy `/api/data/...` paths are dead)
- Reddit: `r/pathofexile`, `r/PathOfExileBuilds`
- Secondary: `poedb.tw`, `maxroll.gg/poe/`, `pobb.in`

### Denylist / PoE2 traps

- `pathofexile2.com`, forum **2212** (Early Access `0.x` notes), `poe2wiki.net`, `poe2db.tw`, `poe.ninja/poe2/`, `maxroll.gg/poe2/`, `r/PathOfExile2`, `poe2-skilltree-export`
- Rule: **host/namespace beats name equality** — same-named skills/items on PoE2 wikis are not PoE1 truth

## 5. Patch-Notes Sync policy

| Rule | Decision |
| --- | --- |
| Primary feed | HTML list + threads under `/forum/view-forum/patch-notes` (PoE1 `3.x`) |
| Secondary | `https://www.pathofexile.com/news/rss` only as noisy hint (incomplete; can mention PoE2) |
| Discrimination | Forum section + version scheme (`3.x` vs `0.x` / forum 2212) |
| Landing | Updates under `knowledge-pack/notes/` and pack `meta` |
| Merge | **Always open a PR**; human merge required — no auto-merge |
| Cadence / operator | Deferred (map fog) |

No official dedicated patch-notes RSS/API exists (research verified).

## 6. Staleness signals to the agent

| Level | Signal | Agent behavior |
| --- | --- | --- |
| Pack | Sync detected newer patch and/or generation behind | Warn in UI / system prompt |
| Note | `possibly_stale` | Distrust |
| Note | `retired` | Ignore |

## 7. Boundary with PoE2 Exclusion

| Concern | Lives in |
| --- | --- |
| Allow/deny data | `knowledge-pack/policy/` |
| Tool/source gates, output guard, Apply id checks, re-ask | Sidecar runtime ([ADR 0004](./adr/0004-poe2-exclusion-fail-closed.md)) |

## 8. Out of scope for the pack

- Fine-tuned weights
- Mirroring full wiki dumps as the primary strategy
- Auto-merging Sync to default branch
- PoE2 content “for comparison”
