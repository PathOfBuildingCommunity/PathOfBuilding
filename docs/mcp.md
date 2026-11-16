# Local MCP server

Path of Building can run a small [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server, so MCP clients on
the same computer can read and change the build open in the window: look at its stats, simulate an item or passive before
buying or allocating it, compare it with a guide build, use the timeless jewel finder, and so on. Every number comes from
Path of Building's own calculations, and every change shows in the window as if it had been made by hand.

The server is **off by default**.

## Turning it on

1. Open **Options** (bottom left) and, under *Application options*, click **Configure...** next to *Local MCP server*.
2. Tick **Enable MCP server**, keep the port (49290) or choose another, and click **Save**. The status line shows
   `Listening on http://127.0.0.1:49290/mcp`.
3. Click **Copy client configuration** and add it to your MCP client. It looks like this:

```json
{
  "mcpServers": {
    "path-of-building": {
      "type": "http",
      "url": "http://127.0.0.1:49290/mcp",
      "headers": { "Authorization": "Bearer <token>" }
    }
  }
}
```

Any client that supports the *Streamable HTTP* transport and custom headers works. Path of Building must be running
for the client to reach it; the server stops when Path of Building closes. The same dialog lists the most recent requests,
so you can see what a client did.

## Safety

- The server listens on `127.0.0.1` only, so other computers cannot reach it.
- Every request must carry the token shown in the dialog (stored in `Settings.xml`, like the Path of Exile login).
  **New token** invalidates the old one. Requests with another `Host` or a foreign `Origin` header are refused, so web pages
  cannot use the server.
- Nothing replaces the open build while it has unsaved changes, unless the client explicitly asks to discard them; clients
  are told to do that only when you agree.
- Tools that change the build are refused while you have a dialog open in Path of Building, and changes mark the build as
  unsaved, so Path of Building asks before closing it. Only `build_save` writes build files, and it never replaces another
  existing file unless told to.
- Tools that use one of Path of Building's dialogs to do their work (timeless jewel finder, tattoos, crafting) close it and
  put back what they changed in it.
- `import_character` uses the Path of Exile login you set up in *Import/Export*; the token never leaves Path of Building.
  Build links are downloaded by Path of Building itself. Nothing is uploaded.

## Tools

Tools are grouped by the part of the window they work on. Read-only tools are marked as such to clients.

| Area | Tool | What it does |
|---|---|---|
| App | `app_status` | Version, what is open, unsaved changes, dialogs, Path of Exile login |
| Builds | `builds_list` | Saved builds and folders, with PoB's search and sort |
| | `build_open` | Open a saved build, a code, a build link or a new build |
| | `build_save` | Save, or save as a new name |
| | `build_export` | Build share code or XML |
| Side bar | `build_stats` | The side bar as shown, warnings, raw output values |
| | `build_edit` | Character level and notes |
| Calcs | `simulate` | What an item, passives or a flask would change, without changing the build |
| | `calcs_breakdown` | Calcs tab cells and the breakdown of a stat |
| Tree | `tree_get` | Class, ascendancy, points, keystones, notables, masteries, jewels, specs |
| | `tree_search` | PoB's tree search, with the points needed to reach each node |
| | `tree_edit` | Allocate or remove passives, masteries, class and ascendancy |
| | `tree_specs` | Passive tree sets: list, select, new, copy, rename, delete |
| | `tree_node_power` | The node power report for a stat |
| | `tree_timeless_jewel` | The timeless jewel finder |
| | `tree_tattoos` | Tattoos for a node: list, apply, remove |
| Items | `items_get` | Equipped items, item sets, other items in the build |
| | `items_equip` | Add an item from its text, equip, unequip, flasks |
| | `items_sets` | Item sets: list, select, new, copy, rename, delete |
| | `items_db_search` | PoB's unique and rare databases, sortable by a stat |
| | `items_craft` | Build an item with PoB's crafting and return its text |
| | `trade_query` | The weighted trade search PoB generates for a slot |
| Skills | `skills_get` | Socket groups, gems, main skill, skill sets |
| | `skills_edit` | Add or change gems and groups, main skill, skill sets |
| | `skills_rank_supports` | Support gems ranked by damage for a group |
| Config | `config_get` | Configuration options that differ from defaults, or a search |
| | `config_set` | Change options, configuration sets and custom modifiers |
| Compare | `compare_builds` | Builds in the Compare tab and their differences |
| | `compare_copy` | Copy tree, items, skills or config from a compared build |
| Party | `party` | Party members and their effects |
| Import | `import_character` | Import a character through the Path of Exile login |

The server also offers four prompts (`analyze_build`, `compare_with_guide`, `best_upgrade`, `timeless_jewel`) and the
open build's XML as the resource `pob://build/current.xml`.

## Troubleshooting

- **The status shows an error about the port:** another program uses it. Choose another port and update the client.
- **The client gets 401:** the token in the client does not match; copy the configuration again.
- **Requests are slow while the window is idle:** Path of Building redraws an idle window less often to save power; a
  request still wakes it at once. Long tools (node power, timeless jewel search) run while the window waits.
- **Responses arrive broken or truncated:** security software that inspects local web traffic can interfere. The server
  answers in the HTTP framing such software was seen to pass through intact; if a client still fails, allow local
  connections to Path of Building in that software.

## For developers

| File | Purpose |
|---|---|
| `src/Modules/McpHttp.lua` | Parses HTTP/1.1 requests and composes responses. No sockets. |
| `src/Modules/McpProtocol.lua` | MCP over Streamable HTTP: JSON-RPC, protocol versions, Host/Origin/token checks, argument validation. No sockets. |
| `src/Modules/McpServer.lua` | LuaSocket listener polled from `main:OnFrame`, settings and the settings dialog. |
| `src/Modules/McpTools.lua` | The tool framework, prompts and resources. |
| `src/Modules/McpTools/*.lua` | The tools, one file per area of the window. |

**Protocol.** One endpoint, `POST /mcp`, answered with `application/json` (no SSE stream). It serves protocol version
2026-07-28 (stateless: version and client capabilities in every request's `_meta` and headers, `server/discover`) and the
earlier `initialize`-based versions 2025-11-25, 2025-06-18 and 2025-03-26 on the same endpoint, as the specification allows
for dual-era servers. No session ids are issued. `GET` and `DELETE` get 405.

**Threading.** Everything runs on the main thread between frames, on the same objects the UI uses. SimpleGraphic skips
`OnFrame` for an unfocused window unless a coroutine is suspended (`ui_main_c::Frame`), so while the server runs it keeps
one suspended; `McpServer:Poll` then waits in `socket.select` while nobody uses the window, so idle frames are rare.

**Adding a tool.** Register it in the matching `McpTools/*.lua` with `T.Tool { name, title, description, input, required,
readOnly/destructive/idempotent/openWorld, modifies/usesDialog/replacesBuild, run }`. Prefer calling the same functions the
UI's controls call, so behaviour stays identical. Fail with `T.Fail(message)` and say what to do instead. Call
`ctx:Changed()` after changing the build: the framework then marks it unsaved, recalculates it, and reports the changed
side-bar stats. Return names people understand, with ids only where a follow-up call needs them, and page long lists.

**Tests.** `spec/System/TestMcp*_spec.lua` drive the protocol and the tools headless (`docker-compose up`, or
`busted --lua=luajit -p TestMcp`). The socket layer and anything using `Deflate`/`Inflate` (build codes) need the real
application.
