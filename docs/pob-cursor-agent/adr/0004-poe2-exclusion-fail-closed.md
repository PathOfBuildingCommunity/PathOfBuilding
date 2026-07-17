# PoE2 Exclusion is fail-closed

Treating Path of Exile 2 data (including same-named skills/items) as Path of Exile 1 truth is a **catastrophic failure**. Runtime enforcement combines:

1. **Baseline gates** — tool/source gates refuse denylisted hosts/paths before the model consumes them; output guard checks citations/proposals.
2. **Apply path** — proposals may only reference entities present in loaded PoB / PoE1 id sets; unknown same-named entities **hard-fail**.

## On guard trip

| Path | Behavior |
| --- | --- |
| **Apply** | Hard refuse — no override, no partial apply of the contaminated slice; user told it was PoE2-risk refusal |
| **Research/chat** | Refuse contaminated answer and **automatically re-ask** constrained to allowlisted PoE1 sources / PoB grounding |

No silent stripping. No Apply override in v1.

## Policy vs enforcement

Allowlist/denylist and exclusion **data** live in `knowledge-pack/policy/`. This ADR owns **runtime** behavior only.

## Mandatory fail-closed acceptance suite

1. **URL/domain** — denylisted hosts/paths blocked (`pathofexile2.com`, `poe2wiki.net`, `poe.ninja/poe2/*`, forum 2212, etc.)
2. **Same-name Apply** — proposing Apply of a same-named skill/item absent from PoB/PoE1 ids hard-refuses
3. **Mixed citation** — PoE1+PoE2 links in one answer refuses and re-asks; PoE2 link must not be shown even “for comparison”
