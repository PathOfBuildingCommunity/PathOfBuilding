# Research: PoE1 knowledge sources and patch-notes feeds

**Ticket:** https://github.com/waltersmike/PathOfBuilding/issues/5  
**Branch:** `research/poe1-knowledge-sources`  
**Date:** 2026-07-17  
**Scope:** Facts for Knowledge Pack allowlist/denylist and Patch-Notes Sync design. No scraper or agent implementation.

**Critical constraint:** Path of Exile 1 only. Treating PoE2 data (including same-named items/skills) as PoE1 truth is a catastrophic failure mode for the planned agent.

---

## Question

What high-trust PoE1 sources should seed the Knowledge Pack allowlist/denylist, and what machine-readable or scrapable PoE1 patch-notes feeds exist for Patch-Notes Sync?

---

## Short answers

1. **Allowlist seeds (PoE1):** official `pathofexile.com` (especially the Patch Notes forum + news RSS as a secondary signal), `poewiki.net`, `poe.ninja/poe1/*`, Reddit `r/pathofexile` + `r/PathOfExileBuilds`, and PoB-adjacent community tools that already namespace PoE1 (`poedb.tw`, `maxroll.gg/poe`, `pobb.in`).
2. **Denylist / PoE2 lookalike traps:** `pathofexile2.com`, GGG forum id `2212` (“Early Access Patch Notes”, `0.x` versions), `poe2wiki.net`, `poe2db.tw`, `poe.ninja/poe2/*`, `maxroll.gg/poe2`, `r/PathOfExile2`, and `grindinggear/poe2-skilltree-export`. Same skill/item **names** exist on both wikis with different mechanics.
3. **Patch-Notes Sync:** there is **no** official dedicated patch-notes API or RSS. The durable primary surface is HTML forum listing + thread pages under `https://www.pathofexile.com/forum/view-forum/patch-notes`. Official news RSS exists but is incomplete for hotfixes and can mention PoE2. Discriminate games by **forum section** and **version scheme** (`3.x` PoE1 vs `0.x` PoE2 EA).

---

## 1. Official GGG / Path of Exile 1

### 1.1 Site and forums (primary for patch notes)

| Surface | URL | Role |
| --- | --- | --- |
| PoE1 site | https://www.pathofexile.com/ | Official home; news, forums, trade, shop |
| **PoE1 Patch Notes forum** | https://www.pathofexile.com/forum/view-forum/patch-notes | Canonical chronological list of PoE1 patch/hotfix threads |
| Example PoE1 thread | https://www.pathofexile.com/forum/view-thread/3985151 | `3.28.0k Patch Notes` (verified 2026-07-17) |
| Example league patch | https://www.pathofexile.com/forum/view-thread/3985332 | `Content Update 3.29.0 - Path of Exile: Curse of the Allflame` |
| Developer docs | https://www.pathofexile.com/developer/docs | OAuth API policies; **no patch-notes resource** |
| Data exports | https://www.pathofexile.com/developer/docs/data | Official passive/atlas tree exports only |
| PoE1 passive tree export | https://github.com/grindinggear/skilltree-export | First-party tree JSON |
| PoE1 atlas tree export | https://github.com/grindinggear/atlastree-export | First-party atlas tree (linked from data docs) |
| Trade leagues JSON | https://www.pathofexile.com/api/trade/data/leagues | Official league list (PoE1 trade stack) |

**Observed (2026-07-17):** the Patch Notes forum listing currently shows PoE1 `3.28.x` / `3.29.0` threads (e.g. `3.28.0k`, Curse of the Allflame `3.29.0`). Thread bodies are ordinary HTML forum posts authored by GGG staff accounts — scrapable, not machine-schema’d.

### 1.2 Official news RSS (partial, not patch-notes-complete)

| Feed | URL | Notes |
| --- | --- | --- |
| PoE1 site news RSS | https://www.pathofexile.com/news/rss | Valid RSS 2.0; channel title `Path of Exile News`; category typically `news` |
| PoE2 site news RSS | https://pathofexile2.com/news/rss | Separate host; **denylist for PoE1 sync** |

**Facts:**

- Feed is live and returns XML (HTTP 200 probed 2026-07-17).
- Items link to forum news threads (e.g. expansion announcements), not every Patch Notes hotfix.
- Community asked for a dedicated patch-notes RSS category; thread archived without an official feed: https://www.pathofexile.com/forum/view-thread/3554274
- Cloudflare has historically blocked some RSS clients (`403` challenges reported): https://www.pathofexile.com/forum/view-thread/3648166
- Sample titles on 2026-07-17 were mostly PoE1 league/marketing, but the same feed can carry PoE2-adjacent headlines (e.g. “Path of Exile 2: Return of the Ancients FAQ”). **Do not treat news RSS as a pure PoE1 patch-notes stream.**

### 1.3 What GGG does *not* provide for patch notes

From https://www.pathofexile.com/developer/docs :

- Supported resources are only those in the API reference and data exports.
- Reverse-engineering undocumented internal endpoints is against Terms of Use §7i.
- Data exports explicitly cover **passive/atlas trees**, not patch notes, skill gems, or item text: https://www.pathofexile.com/developer/docs/data

**Implication for Patch-Notes Sync:** design around **forum HTML polling** (list → thread), optionally using news RSS as a noisy secondary hint — not as the sole source of truth.

---

## 2. poewiki (PoE1) — high-trust community encyclopedia

| Surface | URL | Role |
| --- | --- | --- |
| PoE1 wiki | https://www.poewiki.net/ | Canonical community wiki for Path of Exile 1 |
| MediaWiki API | https://www.poewiki.net/w/api.php | Standard MW API (query, parse, etc.) |
| Cargo / data query docs | https://www.poewiki.net/wiki/Path_of_Exile_Wiki:Data_query_API | Structured item/skill/mod queries (Cargo) |
| PoB deep-link precedent | `src/Modules/ItemTools.lua` opens `https://www.poewiki.net/wiki/...` on F1 | First-party PoB integration signal |

**Bot protection:** HTML and API fetches from this environment received Anubis proof-of-work interstitial pages (“Making sure you're not a bot!”). Design implication: allowlist the domain, but plan for polite human-browser or authenticated access patterns, caching, and rate limits — not naive bulk scrape.

**Legacy Fandom host:** `pathofexile.fandom.com` is a historical Gamepedia/Fandom surface; not the current community home. Prefer `poewiki.net` only for PoE1 wiki facts.

---

## 3. poe.ninja — economy / builds (PoE1 namespace)

poe.ninja hosts **both** games with explicit path prefixes:

| PoE1 (allow) | PoE2 (deny) |
| --- | --- |
| https://poe.ninja/poe1/ | https://poe.ninja/poe2/ |
| https://poe.ninja/poe1/builds | https://poe.ninja/poe2/builds |
| https://poe.ninja/poe1/data | (PoE2 equivalents under `/poe2/`) |

### Machine-readable PoE1 economy endpoints (verified 2026-07-17)

Example (HTTP 200, JSON):

```text
https://poe.ninja/poe1/api/economy/stash/current/currency/overview?league=Standard&type=Currency
```

League index-ish JSON:

```text
https://poe.ninja/poe1/api/data/index-state
```

**Breaking change vs older community docs:** legacy URLs such as

```text
https://poe.ninja/api/data/currencyoverview?league=Standard&type=Currency
```

returned **HTTP 404** on 2026-07-17. Community trackers report the migration to `/poe1/api/...` paths (e.g. https://github.com/exilence-ce/exilence-ce/issues/49). Knowledge Pack tooling must prefer the **`/poe1/`** prefix.

**PoB already namespaces PoE1 PoB share URLs** under `poe.ninja/poe1/pob/...` (`src/Modules/BuildSiteTools.lua`).

---

## 4. Reddit community surfaces

| Subreddit | PoE game | Seed |
| --- | --- | --- |
| https://www.reddit.com/r/pathofexile/ | PoE1 primary discussion | **Allow** |
| https://www.reddit.com/r/PathOfExileBuilds/ | PoE1 builds | **Allow** |
| https://www.reddit.com/r/pathofexiledev/ | Tooling / API discussion | **Allow** (lower weight for build truth) |
| https://www.reddit.com/r/pathofexile/wiki/tools | Community tool index | **Allow** as discovery, not ground truth |
| https://www.reddit.com/r/PathOfExile2/ | PoE2 | **Deny** |

**Notes:**

- Reddit JSON endpoints often return `403` to non-browser clients; design sync/research around official Reddit API or browser-grade access, not anonymous scraping assumptions.
- Community Discord (`discord.gg/pathofexile`) is mixed PoE1+PoE2; treat as low-trust / optional, not allowlist-default for factual claims.

---

## 5. Other PoE1-friendly community tools (secondary allow)

These are not “official,” but are high-signal and already used by PoB or the PoE1 ecosystem. Prefer paths that **encode PoE1 in the URL**:

| Tool | PoE1 URL pattern | PoE2 lookalike |
| --- | --- | --- |
| PoEDB | https://poedb.tw/ | https://poe2db.tw/ |
| Maxroll | https://maxroll.gg/poe/ | https://maxroll.gg/poe2/ |
| pobb.in | https://pobb.in/ | (PoB share; confirm content is PoE1 before trusting) |
| FilterBlade / Awakened PoE Trade / etc. | listed on r/pathofexile wiki/tools | N/A — verify game |

PoB’s own import/export allowlist (`src/Modules/BuildSiteTools.lua`) already distinguishes `maxroll.gg/poe/...` and `poe.ninja/poe1/...`.

---

## 6. PoE2 lookalike traps (denylist seeds)

### 6.1 Domain / path traps

| Trap | Why catastrophic |
| --- | --- |
| https://pathofexile2.com/ (+ `/news/rss`) | Separate official PoE2 site and news feed |
| https://www.pathofexile.com/forum/view-forum/2212 | Title: **“Early Access Patch Notes”**; threads are `0.5.x` PoE2 patches (e.g. `0.5.4c`) — same GGG forum chrome as PoE1 |
| https://www.poe2wiki.net/ | Parallel wiki; pages like `/wiki/Spark` exist with **PoE2** gem data |
| https://poe2db.tw/ | Parallel DB site (e.g. `/us/Lightning_Strike`) |
| https://poe.ninja/poe2/ | Explicit PoE2 builds/economy UI |
| https://maxroll.gg/poe2/ | Explicit PoE2 Maxroll namespace |
| https://github.com/grindinggear/poe2-skilltree-export | Official PoE2 tree export (pair of PoE1 `skilltree-export`) |
| `r/PathOfExile2` | PoE2 subreddit |
| Fandom / mirror pages that do not resolve to `poewiki.net` | Easy to confuse with PoE1 wiki |

### 6.2 Same-name, wrong-game content (examples)

These names exist as distinct entities in both games; wiki/DB pages are **not interchangeable**:

| Name | PoE1 | PoE2 |
| --- | --- | --- |
| Spark | https://www.poewiki.net/wiki/Spark | https://www.poe2wiki.net/wiki/Spark |
| Lightning Strike | (poewiki) | https://poe2db.tw/us/Lightning_Strike |
| Ball Lightning / Flame Dash / many legacy skill names | PoE1 gems | Reworked / weapon-gated PoE2 skills |

**Exclusion rule for implementers:** host + game namespace beats item/skill string equality. Never resolve a bare skill name to the first search hit across games.

### 6.3 Version-scheme discriminator (patch notes)

| Game | Typical version strings on GGG forums | Forum |
| --- | --- | --- |
| PoE1 | `3.28.0k`, `3.29.0`, `Content Update 3.x` | `/forum/view-forum/patch-notes` |
| PoE2 EA | `0.5.4c`, `0.5.3 Hotfix N` | `/forum/view-forum/2212` |

Sync should **hard-fail** (or quarantine) any candidate patch thread whose version matches `^0\.` or whose forum id is `2212`.

---

## 7. Patch-Notes Sync — feed / scrape options ranked

| Rank | Source | Machine-readable? | PoE1 purity | Completeness for balance changes | Recommendation |
| --- | --- | --- | --- | --- | --- |
| 1 | Forum list + threads: `/forum/view-forum/patch-notes` | HTML only (scrape) | High if scoped to this forum | High (includes hotfixes) | **Primary sync input** |
| 2 | News RSS: `/news/rss` | RSS/XML | Medium (PoE2 mentions possible) | Low–medium (misses many hotfixes) | Secondary “new post” hint only |
| 3 | GGG OAuth / developer API | JSON (other resources) | N/A | **None for patch notes** | Do not use for notes |
| 4 | Unofficial third-party “patch notes APIs” | Varies | Untrusted / often PoE2-focused | Unknown | Not for Knowledge Pack truth |
| 5 | PoE2 forum `2212` or `pathofexile2.com/news/rss` | HTML/RSS | **Wrong game** | N/A | **Deny** |

### Practical sync shape (design only)

1. Poll `https://www.pathofexile.com/forum/view-forum/patch-notes` (and paginate if needed).
2. Extract thread ids/titles/dates; filter by title/version heuristics (`3.` / `Content Update`).
3. Fetch each new thread HTML; extract the first staff post body as the note text.
4. Optionally cross-check news RSS for large league announcements — never as the only source.
5. Reject anything from forum `2212`, `pathofexile2.com`, or `0.x` version strings.

Cloudflare/WAF and forum markup changes are operational risks; there is no first-party schema guarantee.

---

## 8. Suggested Knowledge Pack seed lists

### Allowlist (domains / path prefixes)

```text
pathofexile.com                 # prefer PoE1 paths; still filter patch forum vs 2212
pathofexile.com/forum/view-forum/patch-notes
pathofexile.com/news/rss        # secondary; content-filter required
pathofexile.com/developer/docs
pathofexile.com/api/trade       # PoE1 trade API family
github.com/grindinggear/skilltree-export
github.com/grindinggear/atlastree-export
poewiki.net
poe.ninja/poe1/
reddit.com/r/pathofexile
reddit.com/r/PathOfExileBuilds
reddit.com/r/pathofexiledev
poedb.tw                        # not poe2db.tw
maxroll.gg/poe/                 # not /poe2/
pobb.in
```

### Denylist (domains / path prefixes)

```text
pathofexile2.com
pathofexile.com/forum/view-forum/2212
poe2wiki.net
poe2db.tw
poe.ninja/poe2/
maxroll.gg/poe2/
github.com/grindinggear/poe2-skilltree-export
reddit.com/r/PathOfExile2
# Plus any URL whose path or title clearly encodes PoE2 / Early Access 0.x patch notes
```

### Content-level exclusion (beyond hosts)

- Same-named skills/items: require `poewiki.net` / `poe.ninja/poe1` / PoE1 forum evidence before accepting claims.
- Mixed Discord / YouTube / random guides: deny-by-default unless host is allowlisted.

---

## 9. Open risks for later tickets

- **Anubis on poewiki.net** may block Cargo/API automation; need an access strategy before relying on live wiki sync.
- **News RSS ≠ patch notes**; players already requested a dedicated feed and did not get one.
- **poe.ninja API paths changed**; older community documentation is stale — pin `/poe1/api/...`.
- **Shared GGG forum chrome** makes PoE1 vs PoE2 threads easy to confuse if filtering by “site:pathofexile.com” alone.
- Whether Patch-Notes Sync auto-applies Knowledge Pack edits vs flags for human review remains a product decision (map issue #1).

---

## Sources consulted (primary)

1. https://www.pathofexile.com/forum/view-forum/patch-notes  
2. https://www.pathofexile.com/forum/view-forum/2212  
3. https://www.pathofexile.com/news/rss  
4. https://pathofexile2.com/news/rss  
5. https://www.pathofexile.com/developer/docs  
6. https://www.pathofexile.com/developer/docs/data  
7. https://www.pathofexile.com/developer/docs/reference  
8. https://www.pathofexile.com/api/trade/data/leagues  
9. https://www.pathofexile.com/forum/view-thread/3554274  
10. https://www.pathofexile.com/forum/view-thread/3648166  
11. https://www.poewiki.net/ (incl. Anubis interstitial; Data query API page)  
12. https://www.poe2wiki.net/wiki/Spark  
13. https://poe.ninja/poe1/ , `/poe1/builds`, `/poe1/api/economy/...`, `/poe1/api/data/index-state`  
14. https://poe.ninja/poe2/builds  
15. https://github.com/grindinggear/skilltree-export  
16. https://github.com/grindinggear/poe2-skilltree-export  
17. https://poedb.tw/ , https://poe2db.tw/  
18. https://maxroll.gg/poe , https://maxroll.gg/poe2  
19. https://www.reddit.com/r/pathofexile/wiki/tools  
20. In-repo PoB references: `src/Modules/BuildSiteTools.lua`, `src/Modules/ItemTools.lua`
