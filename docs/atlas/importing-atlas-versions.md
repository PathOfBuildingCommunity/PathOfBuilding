# Importing atlas tree versions

The Atlas tab reads atlas passive tree data from `src/TreeData/Atlas/<key>/`, plus the version list `src/Data/AtlasTreeVersions.lua`. Both are generated from Grinding Gear Games' official export at <https://github.com/grindinggear/atlastree-export>, where every league gets a git tag (for example `3.30.0` or `3.25.0-ruthless`).

When GGG publishes a new tag, run the import script and commit the result. No manual editing is needed.

## Prerequisites

- Python 3.8 or newer. Only the standard library is used.
- Network access to `api.github.com` and `raw.githubusercontent.com`.

## Import everything (recommended)

From the repository root:

```bash
python3 src/Export/Atlas/import_atlas_tree.py
```

The script:

1. Lists every tag in the export repository.
2. Picks the usable ones:
   - Release candidates (`-rc`) are skipped.
   - A trailing `-atlas` is ignored.
   - If two tags describe the same version, the one ending in `-atlas` wins.
3. For each version, writes:
   - `src/TreeData/Atlas/<key>/tree.lua`, which is `data.json` converted to a Lua table.
   - `src/TreeData/Atlas/<key>/images.lua`, which maps the sprite sheets the tree uses (at the zoom level PoB draws: `0.3835`, or the largest available) to files in `src/TreeData/Atlas/Images/`. Each image is stored once, even when several leagues use it. A full import also removes images no version uses anymore.
4. Rewrites `src/Data/AtlasTreeVersions.lua`, ordered oldest to newest, with each Ruthless version right after its normal version.

Re-running is safe: files are rewritten only when their content changed. Each run still downloads every `data.json` to compare, so it takes a couple of minutes.

### How tags become keys

| Tag | Key | Shown in PoB as |
|---|---|---|
| `3.30.0` | `3_30` | 3.30.0 |
| `3.29.1` | `3_29_1` | 3.29.1 |
| `3.25.0-ruthless` | `3_25_ruthless` | 3.25.0 (Ruthless) |
| `3.21.0-atlas` | `3_21` | 3.21.0 |

**Never rename or delete an existing key.** Keys are stored in users' build files.

## Import a single new tag

```bash
python3 src/Export/Atlas/import_atlas_tree.py --tag 3.31.0
```

This imports only that tag and adds it to the existing version list. Use `--tag` several times to import several tags.

## After importing

1. Start PoB, open a build, go to **Atlas** and pick the new version in the version dropdown. Check that the tree draws and nodes can be allocated.
2. When preparing a release, run `python3 update_manifest.py` so the new files are listed in `manifest.xml`.
3. Commit `src/TreeData/Atlas/` (including any new files in `Images/`) and `src/Data/AtlasTreeVersions.lua`.

## Troubleshooting

- **HTTP 403 from api.github.com:** you hit GitHub's anonymous rate limit. Create a token with no scopes and run `GITHUB_TOKEN=<token> python3 src/Export/Atlas/import_atlas_tree.py`.
- **`missing asset: …` lines:** the image is in neither the tag's `assets/` folder nor GGG's CDN. This happens for `3.18.0`, whose frame, line and background art is gone from the CDN. PoB draws those parts using the newest imported version's art, which has the same sprite names, so the warning is expected for that version.
- **`Unsupported tag(s)`:** the tag doesn't look like `X.Y.Z`, `X.Y.Z-ruthless` or `X.Y.Z-atlas`. If GGG changes its naming, update `TAG_RE` in the script.
