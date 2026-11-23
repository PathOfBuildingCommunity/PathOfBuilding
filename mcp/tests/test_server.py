"""End-to-end test: talk to the MCP server over stdio like a real client would."""

from __future__ import annotations

import re
import shutil
import sys

import anyio
import pytest
from mcp import ClientSession
from mcp.client.stdio import StdioServerParameters, stdio_client

from pob_mcp.bridge import find_pob_root

pytestmark = pytest.mark.skipif(shutil.which("luajit") is None, reason="luajit not installed")

ROOT = find_pob_root()


def _build_xml() -> str:
    text = (ROOT / "spec" / "TestBuilds" / "3.13" / "Dual Savior.lua").read_text(encoding="utf-8")
    return re.search(r"xml = \[\[(.*?)\]\]", text, re.S).group(1)


def test_server_roundtrip() -> None:
    async def run() -> None:
        params = StdioServerParameters(command=sys.executable, args=["-m", "pob_mcp"])
        async with stdio_client(params) as (read, write):
            async with ClientSession(read, write) as session:
                await session.initialize()
                tools = {tool.name for tool in (await session.list_tools()).tools}
                assert {"load_build", "get_build_summary", "add_item", "export_build"} <= tools

                result = await session.call_tool("load_build", {"source": _build_xml()}, read_timeout_seconds=300)
                assert not result.is_error, result.content
                summary = result.structured_content
                assert summary["class"] == "Marauder"
                assert summary["keyStats"]["Life"] == 92

                result = await session.call_tool("set_custom_modifiers", {"text": "+100 to maximum Life"})
                assert not result.is_error, result.content
                life = next(c for c in result.structured_content["changes"] if c["stat"] == "Life")
                assert life["after"] == 192

                result = await session.call_tool("export_build", {"format": "code"})
                assert not result.is_error
                assert len(result.structured_content["code"]) > 100

                result = await session.call_tool("allocate_node", {"node": "No Such Node"})
                assert result.is_error
                assert "No passive node" in result.content[0].text

    anyio.run(run)
