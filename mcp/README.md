# Path of Building MCP server

An [MCP](https://modelcontextprotocol.io) server that lets AI assistants (Claude Code, Claude
Desktop, Cursor, ...) drive Path of Building's calculation engine: load builds, read every stat PoB
computes, swap items, change gems, allocate passives, flip configuration options, and export the
result as a share code.

It runs PoB **headless** in a `luajit` subprocess (the same way the test suite does) and talks to it
over stdin/stdout. No PoB window is involved and nothing in `src/` is modified.

## Requirements

* Python 3.11+ and [`uv`](https://docs.astral.sh/uv/) (or `pip`)
* LuaJIT 2.1 on your `PATH` (or point `POB_LUAJIT` at it)
* The native `lua-utf8` module (LuaRocks package `luautf8`) built for Lua 5.1 / LuaJIT
* A checkout of this repository (the server needs `src/` and `runtime/lua/`)

### macOS (Homebrew)

```bash
brew install luajit luarocks
luarocks --lua-version=5.1 --lua-dir="$(brew --prefix luajit)" --local install luautf8
```

### Debian / Ubuntu

```bash
sudo apt install luajit libluajit-5.1-dev luarocks
luarocks --lua-version=5.1 --local install luautf8
```

The server looks for `lua-utf8.so` in `~/.luarocks/lib/lua/5.1`, `/opt/homebrew/lib/lua/5.1`,
`/usr/local/lib/lua/5.1` and `/usr/lib/lua/5.1`. Anywhere else: set `POB_LUA_CPATH` to a Lua
cpath template such as `/some/dir/?.so`.

### Windows

Untested. The simplest route is WSL with the Linux steps above. A native setup needs a LuaJIT 2.1
build plus a `lua-utf8.dll` compiled against it; point `POB_LUAJIT` at the executable and
`POB_LUA_CPATH` at the directory holding the DLL (`C:\lua\?.dll`).

> Note: recent LuaJIT builds no longer skip the `#@` marker line at the top of PoB's entry files,
> which is why `luajit src/HeadlessWrapper.lua` can fail with "unexpected symbol near '#'".
> The bridge loads those files through a shim, so any LuaJIT 2.1 works here.

## Install

```bash
cd mcp
uv sync
uv run pob-mcp --help
```

Quick smoke test (starts PoB, loads a test build, prints its summary):

```bash
uv run pytest
```

## Connect a client

### Claude Code

```bash
claude mcp add pob -- uv --directory /path/to/PathOfBuilding/mcp run pob-mcp
```

### Claude Desktop / other stdio clients

```json
{
  "mcpServers": {
    "pob": {
      "command": "uv",
      "args": ["--directory", "/path/to/PathOfBuilding/mcp", "run", "pob-mcp"]
    }
  }
}
```

Environment variables (all optional):

| Variable         | Purpose                                                                 |
|------------------|-------------------------------------------------------------------------|
| `POB_ROOT`       | PoB checkout to use (default: the repository this folder lives in)       |
| `POB_LUAJIT`     | LuaJIT executable (default: `luajit` on `PATH`)                          |
| `POB_LUA_CPATH`  | Extra Lua C-module search template, e.g. `/opt/lua/?.so`                 |
| `POB_MCP_EAGER`  | Set to start PoB at server launch instead of on the first tool call      |

## Tools

| Tool | What it does |
|------|--------------|
| `load_build` | Load from a `.xml` path, raw XML, share code, or pobb.in / pob.codes / poe.ninja / maxroll / pastebin / rentry / poedb link |
| `new_build`, `set_class` | Start from scratch, change class or ascendancy |
| `get_build_summary` | Class, level, main skill, points, warnings, key stats |
| `get_sidebar_stats` | The left-hand stat panel exactly as PoB formats it |
| `get_stats` | Any of PoB's internal output values (player or minion) |
| `get_breakdown` | The Calcs-tab breakdown for one stat |
| `list_skills`, `set_main_skill`, `add_skill_group`, `remove_skill_group`, `set_gem`, `set_skill_group_enabled` | Socket groups and gems |
| `list_items`, `get_item_text`, `add_item`, `equip_item`, `unequip_slot`, `delete_item` | Items and equipment |
| `get_passive_tree`, `search_passive_nodes`, `allocate_node`, `deallocate_node`, `reset_passive_tree`, `import_passive_tree` | Passive tree |
| `list_config_options`, `set_config_option` | Configuration tab |
| `set_custom_modifiers`, `get_custom_modifiers` | Free-form "what if I had +100 life" modifiers |
| `set_character` | Level, bandit, pantheon |
| `export_build`, `save_build`, `decode_build_code` | Share codes and XML |
| `restart_engine` | Restart the headless PoB process |

Every tool that changes the build returns `changes`: the sidebar stats that moved, with before and
after values, so one call is enough to judge an upgrade.

Notes on inputs:

* Gem lines are `<name> <level>/<quality>`; the `Support` suffix is optional (PoB names support
  gems "Spell Echo", not "Spell Echo Support"), and abbreviations PoB understands in its gem
  search box ("CtF" for Cold to Fire) work too.
* Item text is the in-game Ctrl+C format: `Rarity: RARE`, name, base type, then one modifier per
  line. PoB's own export format (with `Implicits:` / `LevelReq:` lines) is accepted as well.
* Passive nodes can be given by numeric id or by name ("Resolute Technique"); names that match
  several nodes error out and list the candidates.

## How it works

```
MCP client  <-- stdio (JSON-RPC) -->  pob_mcp/server.py
                                          |
                                          |  JSON lines over a pipe
                                          v
                              luajit pob_mcp/lua/bridge.lua   (cwd = src/)
                                          |
                                          v
                              Path of Building modules (Launch.lua, Modules/, Classes/)
```

`bridge.lua` bootstraps PoB the same way `src/HeadlessWrapper.lua` does, then loops over
commands. Each mutating command sets `build.buildFlag`, runs one frame so PoB recomputes, and
diffs the sidebar stats. Share codes are inflated/deflated in Python because the headless Lua
runtime has no zlib.

Startup takes a few seconds (tree data, mod cache and item databases are loaded once); the process
is then kept alive for the life of the MCP server.

## Limitations

* One build at a time per server instance.
* Anything that needs the network from inside PoB (account import, uploading to pobb.in) is not
  exposed; downloading from build sites is done in Python instead.
* Trade and item-crafting UI helpers are not wrapped. Items are added via their text form.
