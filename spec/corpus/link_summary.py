"""Link examples and failed inputs after the offline calculation has finished."""

import base64
import hashlib
import json
import re
import sys
from functools import lru_cache
from http.client import HTTPException
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import urlopen


def link_summary(report, corpus, harness, repository, revision):
    entries = {}
    for build in json.loads(corpus.read_bytes())["builds"]:
        digest = build["sha256"]
        entries[digest] = build
        prefix = digest[:12]
        entries[prefix] = build if prefix not in entries else None
    fixtures = {
        "fixture-" + path.stem.replace(" ", "-"): path.relative_to(harness).as_posix()
        for path in (harness / "spec/TestBuilds").rglob("*.xml")
    }

    @lru_cache(None)
    def link(name):
        if name in fixtures:
            return f"[{name}](https://github.com/{repository}/blob/{revision}/{quote(fixtures[name])})"
        build = entries.get(name)
        if build:
            code = build["code"].encode("ascii")
            token = base64.urlsafe_b64encode(hashlib.sha1(code).digest()).decode()
            for length in (11, 20):
                build_id = token[:length]
                try:
                    with urlopen(f"https://api.pob.codes/{build_id}/raw", timeout=5) as response:
                        if response.read(len(code) + 2).rstrip(b"\r\n") == code:
                            suffix = "0" if build_id.endswith("_") else ""
                            return f"[{name}](https://pob.codes/b/{build_id}{suffix})"
                except HTTPError as error:
                    if error.code != 404:
                        break
                except (OSError, HTTPException):
                    break
        return name

    lines = report.read_text(encoding="utf-8").splitlines(keepends=True)
    for i, line in enumerate(lines):
        if line.startswith("| "):
            cells = line.split(" | ")
            if len(cells) == 5:
                cells[2] = link(cells[2])
                lines[i] = " | ".join(cells)
        elif match := re.match(r"^(Base|Candidate): (\S+) \(exit ", line):
            lines[i] = line[:match.start(2)] + link(match[2]) + line[match.end(2):]
    report.write_text("".join(lines), encoding="utf-8")


if __name__ == "__main__":
    link_summary(*(Path(arg) for arg in sys.argv[1:4]), *sys.argv[4:])
