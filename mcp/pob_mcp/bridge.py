"""Subprocess bridge to a headless Path of Building instance.

Spawns ``luajit`` on ``lua/bridge.lua`` inside the PoB ``src`` directory and talks to it
over a JSON-lines protocol (see the header of ``bridge.lua``). Also handles the parts of
the import/export pipeline that need zlib, which the headless Lua runtime does not have.
"""

from __future__ import annotations

import base64
import json
import os
import queue
import re
import shutil
import subprocess
import threading
import urllib.request
import zlib
from collections import deque
from pathlib import Path
from typing import Any

RS = "\x1e"
DEFAULT_TIMEOUT = 120.0
STARTUP_TIMEOUT = 300.0

LUA_DIR = Path(__file__).resolve().parent / "lua"
BRIDGE_SCRIPT = LUA_DIR / "bridge.lua"


class PoBError(Exception):
    """An error reported by Path of Building (or by the bridge itself)."""


class PoBBridgeDied(PoBError):
    """The LuaJIT process exited or stopped responding."""


def find_pob_root(start: Path | None = None) -> Path:
    """Locate the Path of Building checkout (the directory containing ``src/Launch.lua``)."""
    env = os.environ.get("POB_ROOT")
    candidates: list[Path] = []
    if env:
        candidates.append(Path(env).expanduser())
    here = (start or Path(__file__)).resolve()
    candidates.extend(here.parents)
    for candidate in candidates:
        if (candidate / "src" / "Launch.lua").is_file() and (candidate / "runtime" / "lua").is_dir():
            return candidate
    raise PoBError(
        "Could not find the Path of Building source tree. Set POB_ROOT to the directory "
        "that contains src/Launch.lua (a clone of the PathOfBuilding repository)."
    )


def find_luajit() -> str:
    env = os.environ.get("POB_LUAJIT")
    if env:
        return env
    for name in ("luajit", "luajit-2.1"):
        found = shutil.which(name)
        if found:
            return found
    raise PoBError(
        "luajit was not found on PATH. Install LuaJIT (e.g. `brew install luajit`) or set POB_LUAJIT."
    )


def lua_cpath_entries() -> list[str]:
    """Where the native ``lua-utf8`` module might live."""
    home = Path.home()
    entries = [
        str(home / ".luarocks" / "lib" / "lua" / "5.1" / "?.so"),
        "/opt/homebrew/lib/lua/5.1/?.so",
        "/usr/local/lib/lua/5.1/?.so",
        "/usr/lib/lua/5.1/?.so",
        "/usr/lib/x86_64-linux-gnu/lua/5.1/?.so",
    ]
    extra = os.environ.get("POB_LUA_CPATH")
    if extra:
        entries.insert(0, extra)
    return entries


class PoBBridge:
    """Owns one headless PoB process. Thread-safe; calls are serialised."""

    def __init__(
        self,
        root: Path | str | None = None,
        luajit: str | None = None,
        timeout: float = DEFAULT_TIMEOUT,
    ) -> None:
        self.root = Path(root) if root else find_pob_root()
        self.src = self.root / "src"
        self.luajit = luajit or find_luajit()
        self.timeout = timeout
        self._proc: subprocess.Popen[str] | None = None
        self._lines: queue.Queue[str | None] = queue.Queue()
        self._stderr: deque[str] = deque(maxlen=400)
        self._lock = threading.RLock()
        self._next_id = 0

    # -- process management -------------------------------------------------

    @property
    def running(self) -> bool:
        return self._proc is not None and self._proc.poll() is None

    def start(self) -> dict[str, Any]:
        with self._lock:
            if self.running:
                return self.call("ping")
            env = dict(os.environ)
            lua_path = "./?.lua;../runtime/lua/?.lua;../runtime/lua/?/init.lua;;"
            env["LUA_PATH"] = lua_path
            env["LUA_CPATH"] = ";".join(lua_cpath_entries()) + ";;"
            # The CI flag makes PoB rebuild its mod cache from scratch (slow); never want that here.
            env.pop("CI", None)
            self._lines = queue.Queue()
            self._stderr.clear()
            try:
                self._proc = subprocess.Popen(
                    [self.luajit, str(BRIDGE_SCRIPT)],
                    cwd=str(self.src),
                    env=env,
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    bufsize=1,
                )
            except OSError as exc:
                raise PoBError(f"Could not start {self.luajit}: {exc}") from exc
            threading.Thread(target=self._pump_stdout, daemon=True).start()
            threading.Thread(target=self._pump_stderr, daemon=True).start()
            # The first round-trip waits for PoB to finish loading its data.
            return self._roundtrip("ping", {}, timeout=STARTUP_TIMEOUT)

    def close(self) -> None:
        with self._lock:
            proc = self._proc
            self._proc = None
            if proc is None:
                return
            try:
                if proc.stdin:
                    proc.stdin.close()
                proc.wait(timeout=5)
            except Exception:
                proc.kill()

    def restart(self) -> dict[str, Any]:
        self.close()
        return self.start()

    def recent_stderr(self, lines: int = 40) -> str:
        return "\n".join(list(self._stderr)[-lines:])

    def _pump_stdout(self) -> None:
        proc = self._proc
        assert proc is not None and proc.stdout is not None
        for line in proc.stdout:
            self._lines.put(line)
        self._lines.put(None)

    def _pump_stderr(self) -> None:
        proc = self._proc
        assert proc is not None and proc.stderr is not None
        for line in proc.stderr:
            self._stderr.append(line.rstrip("\n"))

    # -- RPC ------------------------------------------------------------------

    def call(self, cmd: str, **args: Any) -> dict[str, Any]:
        """Send one command to PoB and return its ``result`` (raises PoBError on failure)."""
        with self._lock:
            if not self.running:
                self.start()
            return self._roundtrip(cmd, args, timeout=self.timeout)

    def _roundtrip(self, cmd: str, args: dict[str, Any], timeout: float) -> dict[str, Any]:
        proc = self._proc
        if proc is None or proc.stdin is None:
            raise PoBBridgeDied("PoB process is not running")
        self._next_id += 1
        req_id = self._next_id
        payload = json.dumps({"id": req_id, "cmd": cmd, "args": {k: v for k, v in args.items() if v is not None}})
        try:
            proc.stdin.write(payload + "\n")
            proc.stdin.flush()
        except (BrokenPipeError, OSError) as exc:
            self._die(f"PoB process closed its input: {exc}")
        while True:
            try:
                line = self._lines.get(timeout=timeout)
            except queue.Empty:
                self._die(f"PoB did not answer '{cmd}' within {timeout:.0f}s")
            if line is None:
                self._die(f"PoB process exited while handling '{cmd}'")
            if not line.startswith(RS):
                # Stray output from PoB; keep it for diagnostics
                self._stderr.append(line.rstrip("\n"))
                continue
            try:
                resp = json.loads(line[1:])
            except json.JSONDecodeError:
                self._stderr.append(line.rstrip("\n"))
                continue
            if resp.get("fatal"):
                self._die(str(resp.get("error")))
            if resp.get("id") != req_id:
                continue
            if not resp.get("ok"):
                raise PoBError(str(resp.get("error", "unknown error")))
            result = resp.get("result")
            return result if isinstance(result, dict) else {"result": result}

    def _die(self, message: str) -> None:
        tail = self.recent_stderr(15)
        self.close()
        detail = f"\nLast output from PoB:\n{tail}" if tail else ""
        raise PoBBridgeDied(message + detail)


# -- share codes and build sites ------------------------------------------------


def decode_share_code(code: str) -> str:
    """Turn a PoB share code (base64url + zlib) into build XML."""
    code = code.strip()
    code = code.replace("-", "+").replace("_", "/")
    code += "=" * (-len(code) % 4)
    try:
        raw = base64.b64decode(code, validate=False)
        return zlib.decompress(raw).decode("utf-8")
    except Exception as exc:
        raise PoBError(f"Not a valid Path of Building share code: {exc}") from exc


def encode_share_code(xml: str) -> str:
    """Turn build XML into a PoB share code."""
    raw = zlib.compress(xml.encode("utf-8"), 9)
    return base64.b64encode(raw).decode("ascii").replace("+", "-").replace("/", "_")


# Mirrors src/Modules/BuildSiteTools.lua
_BUILD_SITES: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"maxroll\.gg/poe/pob/([^\s?#]+)"), "https://maxroll.gg/poe/api/pob/{0}"),
    (re.compile(r"pob\.codes/b/([^\s?#]+)"), "https://api.pob.codes/{0}/raw"),
    (re.compile(r"pobb\.in/([^\s?#]+)"), "https://pobb.in/pob/{0}"),
    (re.compile(r"poe\.ninja/(?:poe1/)?pob/(\w+)"), "https://poe.ninja/poe1/pob/raw/{0}"),
    (re.compile(r"pastebin\.com/(?:raw/)?(\w+)"), "https://pastebin.com/raw/{0}"),
    (re.compile(r"pastebinp\.com/(?:raw/)?(\w+)"), "https://pastebinp.com/raw/{0}"),
    (re.compile(r"rentry\.co/(\w+)"), "https://rentry.co/paste/{0}/raw"),
    (re.compile(r"poedb\.tw/pob/([^\s?#/]+)"), "https://poedb.tw/pob/{0}/raw"),
]


def raw_build_url(url: str) -> str | None:
    for pattern, template in _BUILD_SITES:
        match = pattern.search(url)
        if match:
            return template.format(match.group(1))
    return None


def fetch_url(url: str, timeout: float = 20.0) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": "pob-mcp/0.1"})
    with urllib.request.urlopen(request, timeout=timeout) as response:  # noqa: S310 - user supplied build link
        return response.read().decode("utf-8", errors="replace")


def resolve_build_xml(source: str) -> tuple[str, str]:
    """Accept XML text, a file path, a share code or a build-site URL; return (xml, description)."""
    text = source.strip()
    if not text:
        raise PoBError("source is empty")
    if text.startswith("<"):
        return text, "xml"
    if text.startswith(("http://", "https://")):
        raw_url = raw_build_url(text) or text
        body = fetch_url(raw_url).strip()
        if body.startswith("<"):
            return body, raw_url
        return decode_share_code(body), raw_url
    path = Path(text).expanduser()
    if path.is_file():
        body = path.read_text(encoding="utf-8").strip()
        if body.startswith("<"):
            return body, str(path)
        return decode_share_code(body), str(path)
    if "/" in text or " " in text:
        raise PoBError(f"'{source}' is neither an existing file, a URL, nor a share code")
    return decode_share_code(text), "share code"
