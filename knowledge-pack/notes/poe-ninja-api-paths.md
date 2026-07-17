---
status: active
verified_against_patch: "3.29.0"
---

# poe.ninja API paths migrated to /poe1/

Legacy URLs such as `https://poe.ninja/api/data/currencyoverview` return 404.
Use the **`/poe1/api/...`** prefix for economy and index endpoints.

Example:

```text
https://poe.ninja/poe1/api/economy/stash/current/currency/overview?league=Standard&type=Currency
```

Do not use `/poe2/` paths — those are PoE2 namespace.
