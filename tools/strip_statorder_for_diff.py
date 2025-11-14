#!/usr/bin/env python3
"""Text conversion helper that hides statOrder churn in diffs."""

from __future__ import annotations

import io
import re
import sys
from pathlib import Path
from typing import Final

_RE_TABLE: Final = re.compile(r"(statOrder\s*=\s*\{)([^}]*)(\})", re.MULTILINE)
_RE_SCALAR: Final = re.compile(r"(statOrder\s*=\s*)(?!\{)([^,\s}]+)", re.MULTILINE)
_RE_BRACKET_KEY: Final = re.compile(r'(\["statOrder"\]\s*=\s*)([^,\s}]+)', re.MULTILINE)
_RE_NOTABLE_ENTRY: Final = re.compile(r'(\["[^"]+"\]\s*=\s*)(\d+)', re.MULTILINE)
_RE_STATDESC_BLOCK: Final = re.compile(r"(?m)(^\t)\[(\d+)\](\s*=\s*\{)")
_RE_STATDESC_TAIL: Final = re.compile(r'(\["[^"]+"\]\s*=\s*)(\d+)(,?)$', re.MULTILINE)
_STATDESC_SUFFIX = "_stat_descriptions.lua"
_PLACEHOLDER: Final = "0"


def _replace_scalar(match: re.Match[str]) -> str:
    return f"{match.group(1)}{_PLACEHOLDER}"


def _replace_table(match: re.Match[str]) -> str:
    return f"{match.group(1)} {_PLACEHOLDER} {match.group(3)}"


def _normalize(contents: str, file_hint: str | None) -> str:
    contents = _RE_TABLE.sub(_replace_table, contents)
    contents = _RE_SCALAR.sub(_replace_scalar, contents)
    contents = _RE_BRACKET_KEY.sub(_replace_scalar, contents)

    file_name = Path(file_hint).name if file_hint else ""

    if file_name == "ClusterJewels.lua" or "NotableSortOrder" in contents:
        contents = _RE_NOTABLE_ENTRY.sub(_replace_scalar, contents)
    if file_hint and "LegionPassives.lua" in file_hint:
        contents = re.sub(r'(\["oidx"\]\s*=\s*)(\d+)', _replace_scalar, contents)
    if file_name == "stat_descriptions.lua" or file_name.endswith(_STATDESC_SUFFIX):
        contents = _RE_STATDESC_BLOCK.sub(lambda m: f"{m.group(1)}[0]{m.group(3)}", contents)
        contents = _RE_STATDESC_TAIL.sub(lambda m: f'{m.group(1)}{_PLACEHOLDER}{m.group(3)}', contents)

    return contents


def _read_source(path: str | None) -> str:
    if path:
        with io.open(path, "r", encoding="utf-8", errors="ignore") as handle:
            return handle.read()
    return sys.stdin.read()


def main() -> None:
    path = sys.argv[1] if len(sys.argv) > 1 else None
    sys.stdout.write(_normalize(_read_source(path), path))


if __name__ == "__main__":
    main()
