# MCP server (AI assistants driving Path of Building)

Path of Building can run a [Model Context Protocol](https://modelcontextprotocol.io) server inside
the application. An AI assistant that supports MCP (Claude Code, Claude Desktop, Cursor, ...) then
works on the build that is **open in the window**: when it equips an item, allocates a passive or
flips a configuration option, the change appears in the window immediately, marks the build unsaved
and can be undone like any other edit. Nothing runs headless and no second copy of PoB is started.

## Turning it on

1. Click **MCP** in the bottom-left bar (next to *Options* and *About*).
2. Tick **MCP server**. The panel shows the URL the server listens on, by default
   `http://127.0.0.1:7390/mcp`. The switch and the port are saved with your settings, so the server
   comes back the next time PoB starts.
3. Connect a client:
   * **Claude Code** – copy the command from the panel, or run
     `claude mcp add --transport http pob http://127.0.0.1:7390/mcp`
   * **Other clients** – add a remote / Streamable HTTP MCP server with the URL from the panel.

The bar button shows the number of clients that were active in the last ten minutes. The panel lists
every client session (name and version from the MCP handshake, address, number of tool calls, last tool
and when it was last active); hover a row for details such as the last error.

The server only listens on 127.0.0.1 and rejects requests from web pages (non-local `Origin`), so
other machines and browser tabs cannot reach it.

## Tools

| Tool | What it does |
|------|--------------|
| `get_build_summary` | Class, level, main skill, points, warnings, key stats of the open build |
| `list_builds`, `open_build`, `close_build` | Browse the Builds folder and open or close a saved build in the window |
| `load_build` | Load a share code, raw XML, a `.xml` path, or a pobb.in / pob.codes / poe.ninja / maxroll / pastebin / rentry / poedb link |
| `new_build`, `set_class`, `set_character` | Start from scratch; change class, ascendancy, level, bandit, pantheon |
| `save_build`, `export_build`, `decode_build_code` | Save to the Builds folder, get a share code or XML |
| `get_sidebar_stats`, `get_stats`, `get_breakdown` | What the sidebar shows, any output stat, the Calcs-tab breakdown of a stat |
| `list_skills`, `set_main_skill`, `add_skill_group`, `remove_skill_group`, `set_gem`, `set_skill_group_enabled` | Socket groups and gems |
| `list_items`, `get_item_text`, `add_item`, `equip_item`, `unequip_slot`, `delete_item` | Items and equipment |
| `get_passive_tree`, `search_passive_nodes`, `allocate_node`, `deallocate_node`, `reset_passive_tree`, `import_passive_tree` | Passive tree |
| `list_config_options`, `set_config_option` | Configuration tab |
| `set_custom_modifiers`, `get_custom_modifiers` | Free-form "what if I had +100 life" modifiers (a Custom Modifiers block named *MCP*) |

Every tool that changes the build returns `changes`: the sidebar stats that moved, with before and after
values. Tools that would replace the open build (`load_build`, `open_build`, `new_build`, `close_build`)
refuse while it has unsaved changes unless the assistant passes `force=true`.

## How it works

```
MCP client ── HTTP POST /mcp (JSON-RPC) ──► src/MCPServer.lua      (sub script thread, LuaSocket)
                                                   │ MCPHandle(remote, session, method, body)  blocking sub-script call
                                                   ▼
                                           src/Modules/MCPStatus.lua   (main thread: sessions, JSON-RPC)
                                                   │
                                                   ▼
                                           src/Modules/MCPTools.lua    (tools acting on main.modes.BUILD)
```

* The server implements the MCP *Streamable HTTP* transport with plain JSON responses: `POST /mcp`
  carries one JSON-RPC message (or a batch), `DELETE /mcp` ends a session, `GET` is answered with
  405 because the server never pushes messages on its own. Sessions are identified by the
  `Mcp-Session-Id` header handed out by `initialize`.
* SimpleGraphic runs one blocking sub-script call per frame, so each request costs about one frame of
  latency. While the server runs, PoB keeps rendering frames even when the window is not focused.
* Downloads for `load_build` links happen in the sub script (the main thread must not block on the
  network); everything else runs on the main thread between frames, exactly where a mouse click would.
* After a mutating tool the build is recomputed immediately (the same work `Build:OnFrame` does when
  `buildFlag` is set) so the reported `changes` are current.

Headless runs (`HeadlessWrapper.lua`, the test suite) have no sub scripts, so the server cannot start
there; the JSON-RPC layer can still be exercised by calling `main.mcp:Handle(...)` directly.
