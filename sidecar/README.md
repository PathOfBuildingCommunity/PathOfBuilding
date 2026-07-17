# PoB Cursor Agent sidecar

Non-LLM sidecar process (Node 22.13+). Policy evaluators load `knowledge-pack/policy/` at runtime.

## Policy tests

```bash
npm install
npm test
npm run typecheck
```

Fail-closed acceptance suite: URL/domain deny, mixed citation refuse, same-name Apply refuse.
