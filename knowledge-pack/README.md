# Knowledge Pack

Versioned PoE1 knowledge layer for the PoB Cursor Agent. Design: [docs/pob-cursor-agent/KNOWLEDGE-PACK.md](../docs/pob-cursor-agent/KNOWLEDGE-PACK.md).

## Layout

| Path | Kind | Purpose |
| --- | --- | --- |
| `policy/allowlist.yaml` | Allowlist | Hosts and path prefixes the agent may fetch or cite for PoE1 |
| `policy/denylist.yaml` | Denylist | PoE2 and lookalike traps (hosts, path prefixes) |
| `policy/exclusion.yaml` | Exclusion extras | Forum ids, version patterns for non-URL gates |
| `notes/*.md` | Notes | Mechanic/pitfall notes with YAML frontmatter |
| `meta.yaml` | Meta | `current_patch`, `generation`, pack version |

## Note frontmatter

Every note under `notes/` must include:

```yaml
status: active | possibly_stale | retired
verified_against_patch: "<PoE1 patch id>"
```

## Runtime enforcement

Policy **data** lives here. PoE2 Exclusion **evaluators** live in `sidecar/src/policy/` and load these files.
