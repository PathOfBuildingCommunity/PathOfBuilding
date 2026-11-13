# Atlas tab

The Atlas tab lets you plan atlas passive trees inside Path of Building. Like the in-game atlas, they belong to you rather than to a single build: every build shows the same atlas trees, changes are saved automatically, and they can be shared as a link. The tab is fully separate from build calculations: allocating atlas nodes never changes a calculated value and never triggers a recalculation.

This page explains how the feature works end to end: where the data comes from, how it is loaded and drawn, and how atlas trees are saved and shared.

## Overview

```
https://github.com/grindinggear/atlastree-export   (one tag per league)
        │  python3 src/Export/Atlas/import_atlas_tree.py
        ▼
src/TreeData/Atlas/<key>/tree.lua + images.lua
src/TreeData/Atlas/Images/          (sprite sheets, stored once)
src/Data/AtlasTreeVersions.lua
        │  main:LoadAtlasTree(key)            (Modules/Main.lua, cached)
        ▼
AtlasTree       one atlas tree version: nodes, positions, links, sprites
        │
AtlasSpec       one named atlas plan: allocated nodes, variants, undo, save/load, links, stat summary
        │
AtlasLibrary    all atlas trees, stored in AtlasTrees.xml in the user folder
        │
AtlasTab        the tab: atlas tree list, version picker, buttons, popups
  ├─ AtlasTreeView    draws the tree, handles hover/click/zoom/pan
  └─ AtlasStatPanel   right-hand panel with summed stats
```

## Where the atlas trees come from

Grinding Gear Games publishes the official atlas tree data at <https://github.com/grindinggear/atlastree-export>. That's the same data their own website and community planners use. Every league gets a git tag (`3.30.0`, `3.29.1`, `3.25.0-ruthless`, …), and each tag contains:

- `data.json`: every node (name, stats, icon, group, orbit, connections), every group (position), the orbit constants, the point total, and the sprite sheet layout
- `assets/`: the sprite sheets (node icons, frames, connector lines, group backgrounds, the atlas background) at several zoom levels

PoB doesn't download this at runtime. A script converts it once and the result is committed, the same as PoB does for the passive tree:

```bash
python3 src/Export/Atlas/import_atlas_tree.py              # every version
python3 src/Export/Atlas/import_atlas_tree.py --tag 3.31.0 # just one new version
```

The script:

1. Lists the tags through the GitHub API and drops release candidates (`-rc`). A trailing `-atlas` is ignored, and when two tags describe the same version, the `-atlas` one wins.
2. Turns each tag into a **version key**: `3.30.0` becomes `3_30`, `3.29.1` becomes `3_29_1`, and `3.25.0-ruthless` becomes `3_25_ruthless`. Keys are stored in users' build files, so they must never change.
3. Downloads `data.json` and writes it as a Lua table to `src/TreeData/Atlas/<key>/tree.lua`.
4. Downloads only the sprite sheets PoB draws: zoom `0.3835`, or the largest one available. If a file is missing from the tag it falls back to GGG's CDN.
   Many leagues share identical images, so each image is stored once in `src/TreeData/Atlas/Images/` under its name plus a short content hash. A per-version `images.lua` maps the names used in `tree.lua` to those files. A full import removes images no version uses anymore.
5. Rewrites `src/Data/AtlasTreeVersions.lua`, the ordered version list shown in the version dropdown. The newest non-Ruthless version is the default.

Files are written only when they change, so re-running the script is safe. Step-by-step instructions and troubleshooting are in [importing-atlas-versions.md](importing-atlas-versions.md).

### Export formats

GGG's export comes in two shapes, and both are supported:

| Versions | Sprite data | Images |
|---|---|---|
| 3.18.0 | `skillSprites` and `assets` (one image per asset, hosted on GGG's CDN) | The CDN images are gone. Frames, lines and backgrounds are borrowed from the newest version, which uses the same sprite names. |
| 3.18.1 and later | `sprites` (sprite sheets shipped in the tag) | Complete |

## Loading a version: `AtlasTree`

`main:LoadAtlasTree(key)` creates an `AtlasTree` the first time a version is needed and caches it. An unknown key falls back to the newest version.

The loader:

- **Node positions:** computes each node's position with the same orbit maths as the passive tree. `PassiveTree:CalcOrbitAngles` is reused read-only, and position = group centre plus orbit radius at the node's angle.
- **Node types:** gives every node one of `Root`, `Normal`, `Notable`, `Keystone`, `Mastery` or `Wormhole`. The root and the nameless start node are always allocated and never counted.
- **Links:** builds an undirected `linked` list per node from `out` and `in`. Masteries are decorative and are never linked.
- **Connectors:** builds the lines between nodes. Nodes in the same group and orbit get an arc, the rest get a straight line. Gateway pairs are linked for pathing, but no line is drawn between them because it would cross the whole map.
- **Stat text:** resolves GGG markup such as `[Thread|Threads]` to `Threads`.
- **Variant notables:** reads `variantEffects`, the effects a variant notable can have.
- **Sprites:** loads the sprite sheets into a sprite map for node icons and an asset table for frames, lines and backgrounds.

Atlas stats are plain text. They are never run through PoB's modifier parser.

## An atlas plan: `AtlasSpec`

An `AtlasSpec` is one named atlas tree, such as "Breach farming". It holds:

- the version key
- the allocated nodes
- the chosen effect of each variant notable
- an undo history

It handles the following:

- **Shortest path:** a breadth-first search starting from every allocated node at once. The first time it reaches the target, the path is final. Masteries are skipped.
- **Removing nodes:** removes the clicked node and every allocated node that can no longer reach the start.
- **Changing version:** keeps the node ids that exist in the new version and drops the rest (the tab shows how many were dropped).
- **Stat summary:**
  - Identical stats are summed. Their numbers are replaced by placeholders, matched, added up and put back.
  - Each stat is placed in a category: the first mechanic (mastery) name found in its text, such as Breach, Incursion or Ritual. Stats that name no mechanic, such as "increased Maps found", go under "Misc", which is listed last.
  - Variant notables count only their chosen effect.

## The tab

- **`AtlasTab`** creates the controls:
  - the atlas tree dropdown and the "Manage atlas trees" list
  - the version dropdown
  - Clear, Import, Export and search
  - Collapse All and Expand All

  Ctrl+Z / Ctrl+Y undo and redo, Ctrl+F jumps to search, and Ctrl+M opens the atlas tree manager.
- **`AtlasTreeView`** draws the background, group backgrounds, connectors, nodes and tooltips:
  - Hover shows the path to allocate, or the nodes that would be removed in red.
  - Hovering a node rings every other node with the same name. For example, hovering a Gateway shows its partner, and hovering a mechanic's cluster icon (such as Breach) shows every Breach cluster on the tree.
  - Clicking a node calls back into the tab. Clicking a variant notable opens the effect dropdown.
- **`AtlasStatPanel`** draws the point counter and the collapsible stat categories. Hovering a stat rings the nodes that give it.

## Hooks into Path of Building

Only two existing files are changed, and only with additions:

- **`Modules/Main.lua`:** loads the version list and adds `main:LoadAtlasTree`.
- **`Modules/Build.lua`:**
  - adds the **Atlas** button and the `ATLAS` view mode
  - creates `atlasTab`
  - registers `<Atlas>` as a load-only legacy section, so older build files can be imported
  - saves `viewMode` as `TREE` when the Atlas tab is open, so the build opens normally in other PoB versions

## Saving

Atlas trees are stored in `AtlasTrees.xml` in PoB's user folder (`main.userPath`, normally `Documents\Path of Building`, next to `Settings.xml` and the Builds folder). That folder survives program updates and reinstalls. `AtlasLibrary` loads the file the first time a build is opened, and the Atlas tab writes it after every change. There's no save button and build files are never touched.

```xml
<AtlasTrees activeSpec="1">
  <Spec title="Breach farming" treeVersion="3_30" nodes="57123,63753">
    <Variant nodeId="45404" effect="55878"/>
  </Spec>
</AtlasTrees>
```

An unrecognised `treeVersion` falls back to the newest version, and node ids that don't exist are skipped.

Earlier versions of the tab saved atlas trees in an `<Atlas>` section of the build file. When such a build is opened, its atlas trees are imported into the library once. Duplicates and empty atlas trees are skipped, and the build itself is not modified.

## Sharing

**Export** produces an official-style link: `https://www.pathofexile.com/fullscreen-atlas-skill-tree/<payload>`. The payload uses the same binary layout as passive tree links:

- version 6
- class 0 and ascendancy 0
- the node ids
- zero cluster nodes
- variant choices as effect/node pairs

All of it is base64url-encoded. **Import** accepts the full link or just the payload and loads it into the current atlas tree at its current version.

## Testing

```bash
docker compose run busted-tests                                   # whole suite, as in CONTRIBUTING.md
docker compose run busted-tests busted --lua=luajit ../spec/System/TestAtlasTab_spec.lua   # one spec
```

The atlas specs (`spec/System/TestAtlas*_spec.lua`) cover:

- loading every version
- pathing, removal and Gateways
- variants
- the library file, importing from older build files, and link round trips
- the stat summary
- drawing, tooltips and same-name highlighting

`TestAtlasNonInterference_spec.lua` loads the bundled test builds with and without atlas data. It allocates atlas nodes and checks that every calculated value is unchanged and no recalculation was triggered.
