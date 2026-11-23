"""MCP server exposing Path of Building's build engine.

Run with ``pob-mcp`` (stdio transport). Every tool talks to a single headless PoB instance
that is started lazily on the first call and kept alive for the life of the server.
"""

from __future__ import annotations

import argparse
import logging
import os
import sys
from pathlib import Path
from typing import Any

from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ToolError

from .bridge import PoBBridge, PoBError, decode_share_code, encode_share_code, resolve_build_xml

log = logging.getLogger("pob_mcp")

INSTRUCTIONS = """\
Path of Building (Path of Exile 1 build planner) running headless.

Typical workflow:
1. `load_build` with a .xml file path, raw build XML, a share code, or a pobb.in / pob.codes /
   poe.ninja / pastebin / maxroll link. (Or `new_build` to start from scratch.)
2. `get_build_summary` / `get_sidebar_stats` to see what PoB shows in its left-hand panel.
3. Make changes - `add_item`, `set_config_option`, `allocate_node`, `set_gem`, `set_custom_modifiers`
   and friends. Every mutating tool returns `changes`: the sidebar stats that moved, with before/after
   values, so you can evaluate a change without a second call.
4. `export_build` to get a share code or XML for the modified build, or `save_build` to write a file.

Stat names (`get_stats`, `get_breakdown`) are PoB's internal output keys, e.g. TotalDPS, CombinedDPS,
FullDPS, Life, EnergyShield, Mana, Armour, Evasion, TotalEHP, FireResist, ColdResist, LightningResist,
ChaosResist, Speed, CritChance, AverageHit. `get_stats` with no names lists everything.

Item text uses the in-game copy format (what you get from Ctrl+C on an item or from PoB's item editor):
rarity line, name, base, then one modifier per line. Gem lists use one gem per line as
"<name> <level>/<quality>", e.g. "Fireball 21/20".
"""

server = MCPServer(
    name="pob",
    title="Path of Building",
    instructions=INSTRUCTIONS,
    version="0.1.0",
)

_bridge: PoBBridge | None = None
_bridge_options: dict[str, Any] = {}


def bridge() -> PoBBridge:
    global _bridge
    if _bridge is None:
        _bridge = PoBBridge(**_bridge_options)
    return _bridge


def _call(cmd: str, **args: Any) -> dict[str, Any]:
    try:
        return bridge().call(cmd, **args)
    except PoBError as exc:
        # ToolError is the one exception type whose message the client gets to see
        raise ToolError(str(exc)) from exc


# -- Build lifecycle ------------------------------------------------------------


@server.tool()
def load_build(source: str, name: str | None = None) -> dict[str, Any]:
    """Load a Path of Building build and return its summary.

    `source` may be: a path to a .xml build file, the raw build XML, a PoB share code, or a link
    to pobb.in, pob.codes, poe.ninja, maxroll.gg, pastebin.com, rentry.co or poedb.tw.
    Loading replaces whatever build was loaded before.
    """
    try:
        xml, origin = resolve_build_xml(source)
    except PoBError as exc:
        raise ToolError(str(exc)) from exc
    if name is None:
        name = Path(origin).stem if origin not in ("xml", "share code") and not origin.startswith("http") else "Imported build"
    result = _call("load_xml", xml=xml, name=name)
    result["source"] = origin
    return result


@server.tool()
def new_build(class_name: str | None = None, ascendancy: str | None = None, name: str | None = None) -> dict[str, Any]:
    """Start a new, empty build (level 1, no items, no skills). Optionally pick class and ascendancy."""
    return _call("new_build", name=name, **{"class": class_name, "ascendancy": ascendancy})


@server.tool()
def set_class(class_name: str | None = None, ascendancy: str | None = None) -> dict[str, Any]:
    """Change the character class and/or ascendancy of the loaded build.

    Changing class keeps the tree if the new class start is connected; otherwise PoB connects the
    tree to the new class start along the shortest path.
    """
    return _call("set_class", **{"class": class_name, "ascendancy": ascendancy})


@server.tool()
def get_build_summary() -> dict[str, Any]:
    """Class, ascendancy, level, main skill, passive points, warnings and the key offensive/defensive stats."""
    return _call("summary")


@server.tool()
def export_build(format: str = "code") -> dict[str, Any]:
    """Export the current build as a share code (`format="code"`, paste into PoB's Import tab or pobb.in) or as XML (`format="xml"`)."""
    xml = _call("export_xml")["xml"]
    if format == "xml":
        return {"xml": xml}
    return {"code": encode_share_code(xml)}


@server.tool()
def save_build(path: str) -> dict[str, Any]:
    """Write the current build to a .xml file that PoB can open (e.g. in its Builds folder)."""
    xml = _call("export_xml")["xml"]
    target = Path(path).expanduser()
    if target.suffix.lower() != ".xml":
        target = target.with_suffix(".xml")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(xml, encoding="utf-8")
    return {"path": str(target), "bytes": len(xml)}


@server.tool()
def decode_build_code(code: str) -> dict[str, Any]:
    """Decode a PoB share code into its XML without loading it."""
    try:
        return {"xml": decode_share_code(code)}
    except PoBError as exc:
        raise ToolError(str(exc)) from exc


# -- Stats --------------------------------------------------------------------


@server.tool()
def get_stats(names: list[str] | None = None, actor: str = "player") -> dict[str, Any]:
    """Raw calculated stats from PoB's output table.

    Pass `names` (e.g. ["TotalDPS", "Life", "FireResist"]) for specific values, or omit to get every
    scalar stat (several hundred). `actor` may be "player" or "minion".
    """
    return _call("stats", names=names, actor=actor)


@server.tool()
def get_sidebar_stats() -> dict[str, Any]:
    """The stats exactly as PoB shows them in the left-hand sidebar (formatted strings, in display order)."""
    return _call("sidebar")


@server.tool()
def get_breakdown(stat: str, actor: str = "player") -> dict[str, Any]:
    """PoB's calculation breakdown for one stat (what the Calcs tab shows on hover), e.g. "Life", "TotalDPS", "Speed", "Armour".

    Breakdowns come from PoB's Calcs-tab pass, whose `value` can differ from the sidebar (`sidebarValue`)
    when the Calcs tab uses a different skill part or option. PoB only builds a breakdown for stats that
    modifiers actually affect; the error message lists similar keys when one is missing.
    """
    return _call("breakdown", stat=stat, actor=actor)


# -- Skills -------------------------------------------------------------------


@server.tool()
def list_skills() -> dict[str, Any]:
    """All socket groups (skill setups) with their gems, levels, qualities and which one is the main skill."""
    return _call("skills")


@server.tool()
def set_main_skill(index: int, active_skill: int | None = None) -> dict[str, Any]:
    """Select which socket group (1-based index from list_skills) is the main skill used for DPS.

    `active_skill` picks the active gem within the group when it contains several.
    """
    return _call("set_main_skill", index=index, active_skill=active_skill)


@server.tool()
def add_skill_group(
    gems: str,
    slot: str | None = None,
    label: str | None = None,
    make_main: bool = False,
) -> dict[str, Any]:
    """Add a socket group. `gems` is one gem per line: "<name> <level>/<quality>", e.g.

        Fireball 21/20
        Spell Echo Support 20/20
        Elemental Focus Support 20/20

    `slot` (e.g. "Body Armour", "Weapon 1", "Helmet") links the group to an item slot.
    """
    return _call("add_skill_group", gems=gems, slot=slot, label=label, make_main=make_main)


@server.tool()
def remove_skill_group(index: int) -> dict[str, Any]:
    """Remove a socket group by its 1-based index."""
    return _call("remove_skill_group", index=index)


@server.tool()
def set_gem(
    group_index: int,
    gem_index: int,
    level: int | None = None,
    quality: int | None = None,
    enabled: bool | None = None,
    count: int | None = None,
    name: str | None = None,
) -> dict[str, Any]:
    """Change a gem inside a socket group (both indices 1-based, from list_skills). `name` swaps the gem for another."""
    return _call(
        "set_gem", group=group_index, gem=gem_index, level=level, quality=quality, enabled=enabled, count=count, name=name
    )


@server.tool()
def set_skill_group_enabled(index: int, enabled: bool | None = None, include_in_full_dps: bool | None = None) -> dict[str, Any]:
    """Enable/disable a socket group, or toggle whether it counts towards Full DPS."""
    return _call("set_group_enabled", index=index, enabled=enabled, include_in_full_dps=include_in_full_dps)


# -- Items --------------------------------------------------------------------


@server.tool()
def list_items() -> dict[str, Any]:
    """Equipment slots with what is equipped, plus every item in the build's item list (equipped or not)."""
    return _call("items")


@server.tool()
def get_item_text(item_id: int) -> dict[str, Any]:
    """Full item text (PoB/in-game format) for an item from list_items."""
    return _call("item_text", id=item_id)


@server.tool()
def add_item(item_text: str, slot: str | None = None, equip: bool = True) -> dict[str, Any]:
    """Add an item from its text (in-game Ctrl+C format or PoB item format) and, by default, equip it.

    Without `slot` PoB picks the first valid empty slot; pass `slot` (e.g. "Ring 2", "Weapon 1",
    "Body Armour", "Flask 3", "Belt Abyssal Socket 1") to replace what is equipped there.
    Returns the sidebar stats that changed.
    """
    return _call("add_item", text=item_text, slot=slot, equip=equip)


@server.tool()
def equip_item(item_id: int, slot: str) -> dict[str, Any]:
    """Equip an existing item (from list_items) into a slot."""
    return _call("equip_item", id=item_id, slot=slot)


@server.tool()
def unequip_slot(slot: str) -> dict[str, Any]:
    """Empty an equipment slot (the item stays in the item list)."""
    return _call("unequip_slot", slot=slot)


@server.tool()
def delete_item(item_id: int) -> dict[str, Any]:
    """Delete an item from the build entirely."""
    return _call("delete_item", id=item_id)


# -- Passive tree -------------------------------------------------------------


@server.tool()
def get_passive_tree(notables_only: bool = True, with_stats: bool = False) -> dict[str, Any]:
    """Allocated passive nodes, mastery choices, point counts and a pathofexile.com tree link.

    By default only notables, keystones and masteries are listed; set `notables_only=false` for every node.
    """
    return _call("tree", notables_only=notables_only, with_stats=with_stats)


@server.tool()
def search_passive_nodes(query: str, allocated_only: bool = False, limit: int = 40) -> dict[str, Any]:
    """Find passive nodes whose name or stat text contains `query`; reports whether each is allocated and how many points it costs to reach."""
    return _call("search_nodes", query=query, allocated_only=allocated_only, limit=limit)


@server.tool()
def allocate_node(node: str) -> dict[str, Any]:
    """Allocate a passive node (by numeric id or name, e.g. "Elemental Overload") plus the shortest path to it."""
    return _call("alloc_node", node=node)


@server.tool()
def deallocate_node(node: str) -> dict[str, Any]:
    """Deallocate a passive node (by id or name) and any nodes that were only connected through it."""
    return _call("dealloc_node", node=node)


@server.tool()
def reset_passive_tree() -> dict[str, Any]:
    """Remove every allocated passive (keeps class and ascendancy)."""
    return _call("reset_tree")


@server.tool()
def import_passive_tree(url: str) -> dict[str, Any]:
    """Replace the passive tree from a pathofexile.com or poeplanner passive tree URL."""
    return _call("import_tree_url", url=url)


# -- Configuration ------------------------------------------------------------


@server.tool()
def list_config_options(query: str | None = None, section: str | None = None, only_set: bool = False, limit: int = 150) -> dict[str, Any]:
    """Configuration tab options (buffs, charges, enemy settings, conditions...) with their current values.

    Filter with `query` (matches variable name or label, e.g. "frenzy", "boss", "shock") or `section`
    ("General", "Skill Options", "Map Modifiers and Player Debuffs", "When In Combat", "For Effective DPS").
    `only_set=true` shows just the options the build has changed from default.
    """
    return _call("config_list", query=query, section=section, only_set=only_set, limit=limit)


@server.tool()
def set_config_option(var: str, value: str | int | float | bool | None) -> dict[str, Any]:
    """Set a Configuration tab option by variable name (from list_config_options).

    Checkboxes take true/false, counters take numbers, lists take an option value or label.
    Pass null/empty to reset to default. Examples: ("usePowerCharges", true), ("enemyIsBoss", "Pinnacle"),
    ("buffOnslaught", true), ("multiplierRage", 50).
    """
    return _call("config_set", var=var, value=value)


@server.tool()
def set_custom_modifiers(text: str) -> dict[str, Any]:
    """Apply free-form modifiers to the character, one per line, in item/passive wording - e.g.
    "+100 to maximum Life", "20% increased Attack Speed", "Chaos Inoculation", "+1 to Level of all Spell Skill Gems".

    Useful for what-if questions. Replaces any modifiers previously set by this tool; pass "" to clear.
    Lines PoB cannot parse are returned in `unparsed`.
    """
    return _call("set_custom_mods", text=text)


@server.tool()
def get_custom_modifiers() -> dict[str, Any]:
    """Custom modifier blocks currently applied to the build (Configuration tab > Custom Modifiers)."""
    return _call("get_custom_mods")


@server.tool()
def set_character(
    level: int | None = None,
    level_auto: bool | None = None,
    bandit: str | None = None,
    pantheon_major_god: str | None = None,
    pantheon_minor_god: str | None = None,
) -> dict[str, Any]:
    """Set character level (1-100, disables auto level unless `level_auto=true`), bandit choice
    ("None", "Oak", "Kraityn", "Alira") and pantheon gods (e.g. "TheBrineKing", "Lunaris", "Solaris", "Arakaali",
    "Gruthkul", "Yugul", "Abberath", "Tukohama", "Garukhan", "Ralakesh", "Ryslatha", "Shakari")."""
    return _call(
        "set_character",
        level=level,
        level_auto=level_auto,
        bandit=bandit,
        pantheonMajorGod=pantheon_major_god,
        pantheonMinorGod=pantheon_minor_god,
    )


# -- Engine -------------------------------------------------------------------


@server.tool()
def restart_engine() -> dict[str, Any]:
    """Restart the headless Path of Building process (discards the loaded build). Use if a tool reports the engine died."""
    try:
        return bridge().restart()
    except PoBError as exc:
        raise ToolError(str(exc)) from exc


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(prog="pob-mcp", description="MCP server for Path of Building")
    parser.add_argument("--root", help="Path of Building checkout (default: auto-detect / $POB_ROOT)")
    parser.add_argument("--luajit", help="LuaJIT executable (default: luajit on PATH / $POB_LUAJIT)")
    parser.add_argument("--transport", default="stdio", choices=["stdio", "streamable-http", "sse"])
    parser.add_argument("--timeout", type=float, default=120.0, help="Seconds to wait for a single PoB command")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args(argv)

    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO, stream=sys.stderr)
    if args.root:
        _bridge_options["root"] = args.root
    if args.luajit:
        _bridge_options["luajit"] = args.luajit
    _bridge_options["timeout"] = args.timeout
    if os.environ.get("POB_MCP_EAGER"):
        bridge().start()
    try:
        server.run(transport=args.transport)
    finally:
        if _bridge is not None:
            _bridge.close()


if __name__ == "__main__":
    main()
