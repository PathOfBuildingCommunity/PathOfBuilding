"""End-to-end tests for the headless PoB bridge.

They start a real LuaJIT + Path of Building process, so they need `luajit` and the `lua-utf8`
module installed (see README.md). They are skipped otherwise.
"""

from __future__ import annotations

import re
import shutil
from pathlib import Path

import pytest

from pob_mcp.bridge import (
    PoBBridge,
    PoBError,
    decode_share_code,
    encode_share_code,
    find_pob_root,
    raw_build_url,
    resolve_build_xml,
)

pytestmark = pytest.mark.skipif(shutil.which("luajit") is None, reason="luajit not installed")

ROOT = find_pob_root()
TEST_BUILD = ROOT / "spec" / "TestBuilds" / "3.13" / "Dual Savior.lua"


def _build_xml() -> str:
    text = TEST_BUILD.read_text(encoding="utf-8")
    return re.search(r"xml = \[\[(.*?)\]\]", text, re.S).group(1)


@pytest.fixture(scope="module")
def pob():
    bridge = PoBBridge(root=ROOT)
    info = bridge.start()
    assert info["buildLoaded"] is True
    yield bridge
    bridge.close()


@pytest.fixture()
def dual_savior(pob: PoBBridge) -> dict:
    return pob.call("load_xml", xml=_build_xml(), name="Dual Savior")


def test_load_matches_test_suite_output(dual_savior: dict) -> None:
    # Values recorded in spec/TestBuilds/3.13/Dual Savior.lua
    assert dual_savior["class"] == "Marauder"
    assert dual_savior["ascendancy"] == "Berserker"
    assert dual_savior["mainSkill"] == "Double Strike"
    assert dual_savior["keyStats"]["Life"] == 92
    assert dual_savior["keyStats"]["TotalDPS"] == pytest.approx(47.5315533, rel=1e-6)


def test_sidebar_and_stats(pob: PoBBridge, dual_savior: dict) -> None:
    sidebar = pob.call("sidebar")["lines"]
    labels = {line["label"] for line in sidebar}
    assert "Total Life" in labels
    stats = pob.call("stats", names=["Life", "TotalDPS", "DoesNotExist"])
    assert stats["stats"]["Life"] == 92
    assert stats["missing"] == ["DoesNotExist"]
    everything = pob.call("stats")["stats"]
    assert len(everything) > 300


def test_custom_mods_report_unparsed_and_changes(pob: PoBBridge, dual_savior: dict) -> None:
    result = pob.call("set_custom_mods", text="+500 to maximum Life\nthis is not a mod")
    assert result["unparsed"] == ["this is not a mod"]
    life = next(c for c in result["changes"] if c["stat"] == "Life")
    assert life["before"] == 92 and life["after"] == 592
    cleared = pob.call("set_custom_mods", text="")
    assert next(c for c in cleared["changes"] if c["stat"] == "Life")["after"] == 92


def test_add_item_equips_and_diffs(pob: PoBBridge, dual_savior: dict) -> None:
    result = pob.call(
        "add_item",
        text="Rarity: RARE\nTest Ring\nAmethyst Ring\n+70 to maximum Life\n+40% to Fire Resistance",
        slot="Ring 1",
    )
    assert result["item"]["equippedIn"] == ["Ring 1"]
    changes = {c["stat"]: c for c in result["changes"]}
    assert changes["Life"]["delta"] == 70
    assert changes["FireResist"]["delta"] == 40
    text = pob.call("item_text", id=result["item"]["id"])["text"]
    assert "+70 to maximum Life" in text
    with pytest.raises(PoBError):
        pob.call("add_item", text="Rarity: RARE\nNope\nNot A Real Base\n+1 to nothing")


def test_passive_tree_allocation(pob: PoBBridge, dual_savior: dict) -> None:
    found = pob.call("search_nodes", query="Resolute Technique")["nodes"]
    assert found and found[0]["type"] == "Keystone" and found[0]["allocated"] is False
    before = pob.call("tree")["passivePointsUsed"]
    result = pob.call("alloc_node", node="Resolute Technique")
    assert result["node"]["allocated"] is True
    assert pob.call("tree")["passivePointsUsed"] == before + len(result["allocatedPath"])
    # Deallocating only removes the node itself (and anything hanging off it); the path stays
    removed = pob.call("dealloc_node", node=str(result["node"]["id"]))
    assert [n["id"] for n in removed["deallocated"]] == [result["node"]["id"]]
    assert pob.call("tree")["passivePointsUsed"] == before + len(result["allocatedPath"]) - 1
    with pytest.raises(PoBError):
        pob.call("alloc_node", node="No Such Node")


def test_skill_groups_and_support_suffix(pob: PoBBridge, dual_savior: dict) -> None:
    result = pob.call("add_skill_group", gems="Fireball 20/20\nSpell Echo Support 20/20", make_main=True)
    gems = result["group"]["gems"]
    assert [g["name"] for g in gems] == ["Fireball", "Spell Echo"]
    assert gems[1]["isSupport"] is True
    assert pob.call("skills")["mainSocketGroup"] == result["index"]
    pob.call("remove_skill_group", index=result["index"])


def test_config_options(pob: PoBBridge, dual_savior: dict) -> None:
    listing = pob.call("config_list", query="power charges")
    assert any(o["var"] == "usePowerCharges" for o in listing["options"])
    result = pob.call("config_set", var="usePowerCharges", value=True)
    assert result["option"]["value"] is True
    assert any(c["stat"] == "CritChance" for c in result["changes"])
    with pytest.raises(PoBError):
        pob.call("config_set", var="enemyIsBoss", value="Bogus")
    pob.call("config_set", var="usePowerCharges", value=None)


def test_export_roundtrip(pob: PoBBridge, dual_savior: dict) -> None:
    xml = pob.call("export_xml")["xml"]
    assert xml.startswith("<?xml")
    code = encode_share_code(xml)
    assert decode_share_code(code) == xml
    reloaded = pob.call("load_xml", xml=decode_share_code(code), name="Reloaded")
    assert reloaded["keyStats"]["TotalDPS"] == pytest.approx(dual_savior["keyStats"]["TotalDPS"])


def test_new_build_and_class(pob: PoBBridge) -> None:
    result = pob.call("new_build", **{"class": "Witch", "ascendancy": "Necromancer"})
    assert result["class"] == "Witch" and result["ascendancy"] == "Necromancer"
    assert result["passivePointsUsed"] == 0


def test_build_site_urls() -> None:
    assert raw_build_url("https://pobb.in/abc123") == "https://pobb.in/pob/abc123"
    assert raw_build_url("https://pastebin.com/XyZ") == "https://pastebin.com/raw/XyZ"
    assert raw_build_url("https://poe.ninja/poe1/pob/abc") == "https://poe.ninja/poe1/pob/raw/abc"
    assert raw_build_url("https://example.com/whatever") is None


def test_resolve_build_xml_sources(tmp_path: Path) -> None:
    xml = _build_xml()
    assert resolve_build_xml(xml)[0] == xml
    assert resolve_build_xml(encode_share_code(xml))[0] == xml
    file = tmp_path / "build.xml"
    file.write_text(xml, encoding="utf-8")
    assert resolve_build_xml(str(file))[0] == xml
    with pytest.raises(PoBError):
        resolve_build_xml("definitely not a code")
