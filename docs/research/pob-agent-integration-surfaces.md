# Research: PoB integration surfaces for an agent bridge

**Ticket:** [#4](https://github.com/waltersmike/PathOfBuilding/issues/4) (part of [#1](https://github.com/waltersmike/PathOfBuilding/issues/1))  
**Question:** In this Path of Building codebase, what are the realistic integration surfaces for (1) a floating window open/close at will, (2) a full build export/snapshot every agent turn, (3) applying a confirmed proposal that mutates tree, items/gems, and Configuration, (4) optional handoff into the Compare tab, and (5) a non-LLM sidecar process talking to the Lua app?  
**Scope:** Identify seams, gaps, and what would have to be invented. Do **not** implement the agent.  
**Primary sources:** this repo's Lua app (`src/`), docs, and runtime host artifacts under `runtime/`.  
**Date:** 2026-07-17

---

## Executive summary

| Need | Realistic surface today | Verdict |
|------|-------------------------|---------|
| (1) Floating window | In-app `PopupDialog` / controls only; **one** OS window (`SimpleGraphic`) | **Invent** non-modal in-app panel *or* put the UI in an external sidecar window |
| (2) Full build snapshot | `buildMode:SaveDB` → XML; optional Deflate+base64 share code | **Reuse** — strongest existing seam |
| (3) Apply confirmed proposal | Full wipe via `Init`+XML, **or** per-tab Load/undo/copy helpers | **Partial reuse** — no cross-tab “proposal transaction” |
| (4) Compare handoff | `CompareTab:ImportBuild` / Import-tab “Import as comparison” | **Reuse** — optional path already exists |
| (5) Sidecar ↔ Lua | `LaunchSubScript`, `SpawnProcess`, files, clipboard, HTTP (`lcurl`); unused `socket.dll` | **Invent** the bridge protocol; host has primitives but no agent IPC |

---

## Host / UI architecture (context for all five)

PoB is a LuaJIT app hosted by **SimpleGraphic** (see `docs/rundown.md`, `src/Launch.lua` `#@ SimpleGraphic`). There is a single OS window (`SetWindowTitle`, `vid_resizable`). The Lua UI is a custom control tree (`Control` / `ControlHost`), not a native widget toolkit.

Two top-level modes live under `main.modes`: `LIST` (`Modules/BuildList`) and `BUILD` (`Modules/Build`). Inside BUILD, `build.viewMode` switches tabs (`TREE`, `SKILLS`, `ITEMS`, `CONFIG`, `IMPORT`, `COMPARE`, …) and each tab draws into a shared viewport (`buildMode:OnFrame`).

Modal UI is a stack of in-window overlays: `main.popups` processed/drawn before normal controls (`main:OnFrame`, `main:OpenPopup` / `ClosePopup`). When a popup is open, input is consumed by the popup only.

```text
OS window (SimpleGraphic)
└── main viewPort (full screen)
    ├── mode UI (LIST or BUILD tabs)
    ├── ToastNotification (non-blocking messages)
    └── main.popups[1] (modal PopupDialog — blocks input underneath)
```

There is **no** Lua API in this tree for creating a second OS window or docking an external HWND.

---

## (1) Floating window open/close at will

### Existing seams

- **`PopupDialog`** (`src/Classes/PopupDialog.lua`) + **`main:OpenPopup` / `ClosePopup` / `OpenConfirmPopup` / `OpenMessagePopup`** (`src/Modules/Main.lua`): centered modal dialogs with controls, Escape/Enter handling. Used heavily (Options, Import Comparison, Save As, etc.).
- **`ToastNotification`** (`src/Modules/ToastNotification.lua`): non-modal, auto-dismissing messages at the bottom of the main window — not a chat/workspace surface.
- **Tab panels**: each BUILD tab is a `ControlHost` drawing into `tabViewPort` (`buildMode:OnFrame`). A new “Agent” tab would fit this pattern but is a full tab, not a floating window.
- Window chrome is limited to title text (`main:SetWindowTitleSubtext`, `PassiveSpec:SetWindowTitleWithBuildClass`).

### Gaps

- Popups are **modal**: `main:OnFrame` routes all input to `self.popups[1]` and wipes events, so the user cannot edit the tree/items while a popup is open. That conflicts with “open/close at will” while continuing to use PoB.
- No multi-window / always-on-top floating panel primitive in the Lua host surface documented in this repo.
- No persisted window-placement system for arbitrary panels (placement persistence is listed as unspecified on the map issue).

### What would have to be invented

1. **In-app non-modal floating panel** (recommended if UI must live inside PoB): a new control host drawn on a high draw layer, with its own show/hide flag, that does **not** go through `main.popups` (so it does not steal all input). Would need hit-testing rules so clicks on the panel vs. the tab underneath behave correctly — pattern does not exist today (toasts are display-only).
2. **External window owned by a sidecar** (fits “non-LLM sidecar OK”): agent UI is outside PoB; PoB only exposes snapshot/apply APIs. Avoids inventing non-modal overlay UX inside SimpleGraphic.
3. **Misuse of `PopupDialog`**: technically open/close works, but modality makes it a poor fit for an advisor that must stay open while the user inspects the build.

---

## (2) Full build export / snapshot every agent turn

### Existing seams (strong)

Canonical serialization is XML with root element `PathOfBuilding`:

- **`buildMode:SaveDB(fileName)`** (`src/Modules/Build.lua`): builds `{ elem = "PathOfBuilding" }`, writes the `Build` section via `buildMode:Save`, then each registered saver’s `Save`, then `common.xml.ComposeXML`. Returns the XML **string** (or shows an error).
- **Savers registered in `buildMode:Init`**:

  | XML elem | Object |
  |----------|--------|
  | `Config` | `configTab` |
  | `Notes` | `notesTab` |
  | `Party` | `partyTab` |
  | `Tree` | `treeTab` |
  | `TreeView` | `treeTab.viewer` |
  | `Items` | `itemsTab` |
  | `Skills` | `skillsTab` |
  | `Calcs` | `calcsTab` |
  | `Import` | `importTab` |

- **Share-code encoding** (Import/Export tab):  
  `common.base64.encode(Deflate(self.build:SaveDB("code"))):gsub("+","-"):gsub("/","_")`  
  (`ImportTab` generate-code button; same pattern in `CompareTab:ImportFromCode` decode path).
- **File persistence**: `SaveDBFile` / `LoadDBFile` read/write `*.xml` under the user’s build path.
- **Headless helpers**: `HeadlessWrapper.loadBuildFromXML` / `newBuild` for offline loading (testing), not for talking to a live GUI session.

Calling `SaveDB` does not require UI interaction; it reads live tab state. After edits, calcs refresh when `buildFlag` is set (`buildMode:OnFrame` → `calcsTab:BuildOutput`).

### Gaps / caveats

- **Compare entries are not savers**: comparison builds live only in `compareTab.compareEntries` memory; they are not part of `SaveDB` XML.
- Snapshot size can be large (full items + tree + config). Product notes already say monitor usage — no compression-for-agent path beyond the existing Deflate share code.
- `SaveDB` argument is only used for error messages; it does not change content.
- Party “Export Support” buffs are optional via `partyTab.enableExportBuffs` (ImportTab checkbox); usually irrelevant for a solo build advisor.

### What would have to be invented

- A thin **agent-facing export API** (e.g. always return XML and/or share code + metadata like `dbFileName`, `buildName`, `outputRevision`) — wrapping existing `SaveDB`.
- Optional **delta/hash** if full XML every turn becomes too large for the LLM context (optimization later; not required for a first bridge).
- A place to dump the snapshot for a sidecar (clipboard, temp file, HTTP body) — see (5).

---

## (3) Applying a confirmed proposal (tree, items/gems, Configuration)

### Existing seams

**A. Full-build replace (nuclear, already used for Import)**

`ImportTab` “Import to this build”:

1. Confirm popup warning that import erases **ALL** existing data.
2. `build:Shutdown()` then `build:Init(dbFileName, buildName, importCodeXML, …)`.

That reloads the entire BUILD mode from XML. Correct for “replace whole build with proposed XML,” heavy-handed for partial proposals, and destroys unsaved in-memory-only state that isn’t in the XML path you supply.

**B. Per-domain mutation / undo (granular)**

Each major surface already has Load/Save and (usually) undo:

| Domain | Load/Save | Undo | Notable mutators |
|--------|-----------|------|------------------|
| Passive tree | `TreeTab:Load` / `Save`; `PassiveSpec` | `PassiveSpec:CreateUndoState` / `RestoreUndoState`; `AllocNode` / `DeallocNode` | Compare: `CopyCompareSpecToPrimary` |
| Items | `ItemsTab:Load` / `Save` | `CreateUndoState` / `RestoreUndoState`; `AddItem`, slot `SetSelItemId` | Compare: `CopyCompareItemToPrimary` |
| Skills/gems | `SkillsTab:Load` / `Save` | `CreateUndoState` / `RestoreUndoState` | Socket-group structures in skills tab |
| Configuration | `ConfigTab:Load` / `Save` | undo of `configSets[…].input`; `UpdateControls` + `BuildModList` | `ConfigOptions` var list drives keys |

After mutations, callers typically set `build.buildFlag = true` so the next frame rebuilds calcs.

**C. Compare → primary copy helpers (partial apply patterns)**

`CompareTab:CopyCompareSpecToPrimary` and `CopyCompareItemToPrimary` show how to push pieces from a secondary XML-derived `CompareEntry` into the live build (with explicit limitations — e.g. jewels not copied with the tree because item IDs differ).

**D. Undo model**

`UndoHandler` (`src/Classes/UndoHandler.lua`) is **per object** (items tab, skills tab, config tab, passive spec, …), depth-capped (~100), not a single transactional undo spanning tree+items+skills+config.

### Gaps

- **No proposal/diff/apply API**: nothing accepts an agent “proposal” object and applies tree + items + gems + config atomically.
- **No cross-tab undo**: map issue still lists undo/rollback semantics as unspecified; the code supports per-tab Ctrl+Z style undo only.
- Full `Init` from XML is all-or-nothing and remounts UI.
- Applying by writing a temp `.xml` and calling `LoadDB` mid-session is not a supported hot-reload path without going through `Init`/`Shutdown` (section load happens during `Init`).
- Skills and items are coupled (socket groups, jewel sockets on the tree); order of application matters (tree deferred after items on load for jewel reasons — see comments in `buildMode:Init`).

### What would have to be invented

1. **Proposal representation** (likely proposed XML sections, or structured patches) owned by the agent UI — not present in PoB.
2. **Apply orchestrator** that either:
   - builds a full XML and runs the Import-to-this-build path, **or**
   - applies section-wise via tab Load/RestoreUndoState / copy helpers, then sets `buildFlag`, with a documented order (Items → Skills → Tree → Config mirrors load constraints).
3. **Rollback policy**: snapshot `SaveDB` before apply and re-`Init`, or push coordinated undo states on each tab (fragile), or rely on PoB Save + user revert.
4. Agent-owned **diff display** (product decision: agent window owns the proposal diff; Compare is optional).

---

## (4) Optional handoff into the Compare tab

### Existing seams (strong)

- **`CompareTab:ImportBuild(xmlText, label)`** (`src/Classes/CompareTab.lua`): constructs `CompareEntry` from XML, appends to `compareEntries`, selects it. Returns success if calcs produced `mainOutput`.
- **`CompareTab:ImportFromCode(code)`**: Deflate+base64 decode → `ImportBuild`.
- **Import tab mode** `"Import as comparison"`: calls `compareTab:ImportBuild` and sets `build.viewMode = "COMPARE"`.
- **UI import paths**: `OpenImportPopup` (paste code/URL), `OpenImportFolderPopup` (local `.xml` files via `BuildListHelpers.ScanFolder`).
- **`CompareEntry`** (`src/Classes/CompareEntry.lua`): lightweight build wrapper — loads XML, creates tabs, runs calcs **without** primary BUILD chrome. Good model for “secondary build in memory.”
- Compare sub-views: Summary / Tree / Skills / Items / Calcs / Config; tree overlay; power report; copy-to-primary helpers (see §3).

### Gaps

- Compare state is **not persisted** in the primary build’s `SaveDB`.
- Handoff is manual today (user imports). Programmatic handoff only needs a caller to `ImportBuild` + optionally `viewMode = "COMPARE"` — small glue, not a new subsystem.
- Compare is for **side-by-side analysis**, not for owning the proposal diff (aligned with product notes).

### What would have to be invented

- Optional one-liner bridge from the agent “Apply preview” / “Send to Compare” action → `ImportBuild(proposedXml, label)` (+ maybe switch tab). No deep Compare changes required for MVP.

---

## (5) Non-LLM sidecar talking to the Lua app

### Existing host primitives

| Primitive | Location | Role |
|-----------|----------|------|
| `LaunchSubScript` | SimpleGraphic host; used in `Launch:DownloadPage`, `CheckForUpdate`, `TreeTab`, `PoBArchivesProvider` | In-process Lua worker; callbacks via `launch:OnSubFinished` / `RegisterSubScript`. **Not** a long-lived external process server. |
| `SpawnProcess` | `Launch:ApplyUpdate`, `UpdateApply.lua`; stubbed in `HeadlessWrapper` | Fire-and-forget OS process (updater). |
| `launch:DownloadPage` | `lcurl` inside a subscript | Outbound HTTPS. |
| `Copy` / `Paste` | Host clipboard | Manual or scripted exchange. |
| `io.open` | Widespread | Read/write build XML and settings on disk. |
| `HeadlessWrapper.lua` | CLI/test entry | Separate process loads PoB headless; **does not attach to a running GUI**. |
| `socket.dll` | `runtime/socket.dll` | Present in the Windows runtime bundle; **no `require("socket")` (or similar) usage anywhere under `src/`**. Latent capability, not an existing API. |

There is **no** first-party agent bridge, named-pipe protocol, localhost RPC, or message bus in the Lua codebase.

### Gaps

- GUI session and sidecar are separate processes with no shared memory API exposed to Lua.
- Subscripts cannot replace a durable sidecar (they run short scripts and return).
- Headless PoB cannot drive the user’s open build; it can only load another copy of XML offline.

### What would have to be invented

A bridge design choosing one (or combining) of:

1. **File mailbox**: sidecar writes commands / reads snapshots under a known directory; Lua polls each `OnFrame` (or on a timer). Uses only `io.*` — lowest invention cost, highest latency/races.
2. **Clipboard protocol**: fragile UX; already available via `Copy`/`Paste`.
3. **Local HTTP**: sidecar listens; Lua uses `lcurl` or a new `LaunchSubScript` loop to POST/GET. Outbound from PoB is proven; inbound server **inside** the GUI process would need sockets (possibly via unused `socket.dll`) or the sidecar is the server and PoB only polls/pushes.
4. **Lua `socket` module**: verify loadability from the shipped runtime, then invent a small JSON line protocol. Currently unused — treat as R&D, not a seam.
5. **Injected Lua module in this fork**: e.g. `Modules/AgentBridge.lua` started from `Main:Init`, owning poll/connect logic — all fork-local (map forbids upstream merge).

Cursor-side integration (SDK, chat history) is **outside** this PoB codebase and out of scope for this ticket’s primary sources.

---

## Recommended integration shape (research conclusion only)

Without implementing anything, the lowest-friction architecture consistent with the code is:

```text
┌─────────────────────────────┐     snapshot XML / share code      ┌──────────────────┐
│ PoB GUI (SimpleGraphic)     │ ─────────────────────────────────► │ Non-LLM sidecar  │
│  SaveDB every turn          │                                    │  ↔ Cursor agent  │
│  Apply via Init or tab APIs │ ◄───────────────────────────────── │  proposal XML    │
│  optional CompareTab import │                                    │  (own UI window) │
└─────────────────────────────┘         invented IPC               └──────────────────┘
```

- **Reuse:** `SaveDB`, Import encode/decode, `CompareTab:ImportBuild`, per-tab Load/undo mutators, `buildFlag` recalc.
- **Invent:** agent UI window (prefer sidecar-owned OS window **or** new non-modal in-app panel), IPC protocol, proposal apply orchestrator + rollback policy, optional AgentBridge Lua module in this fork.

---

## Source index (primary)

| Topic | Paths / symbols |
|-------|-----------------|
| Host entry | `src/Launch.lua` (`SetWindowTitle`, `LaunchSubScript`, `SpawnProcess`, `DownloadPage`) |
| Main loop / popups | `src/Modules/Main.lua` (`OnFrame`, `OpenPopup`, `ClosePopup`, `popups`) |
| Popup UI | `src/Classes/PopupDialog.lua` |
| Build lifecycle | `src/Modules/Build.lua` (`Init`, `Shutdown`, `SaveDB`, `LoadDB`, `savers`, `viewMode`, `OnFrame`, `buildFlag`) |
| Import/Export | `src/Classes/ImportTab.lua` (generate code, import modes, confirm wipe) |
| Share sites | `src/Modules/BuildSiteTools.lua` |
| Compare | `src/Classes/CompareTab.lua` (`ImportBuild`, `ImportFromCode`, copy helpers); `src/Classes/CompareEntry.lua` |
| Config | `src/Classes/ConfigTab.lua` (`Load`/`Save`, `RestoreUndoState`, `BuildModList`) |
| Tree | `src/Classes/TreeTab.lua`, `src/Classes/PassiveSpec.lua` |
| Items / skills | `src/Classes/ItemsTab.lua`, `src/Classes/SkillsTab.lua` |
| Undo | `src/Classes/UndoHandler.lua` |
| Headless | `src/HeadlessWrapper.lua` |
| Runtime host | `docs/rundown.md` (SimpleGraphic, lcurl, lzip); `runtime/socket.dll` (unused by `src/`) |
| Layout docs | `docs/rundown.md` |

---

## Explicit non-findings

- No existing “agent”, “Cursor”, or “sidecar bridge” module in `src/`.
- No second-window API in the Lua bindings used by this app.
- No `require("socket")` call sites despite `runtime/socket.dll`.
- Implementation of the agent remains out of scope (per ticket and map issue #1).
