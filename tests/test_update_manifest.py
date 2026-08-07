import pathlib
import sys
import xml.etree.ElementTree as Et

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))

from update_manifest import create_manifest


BASE_MANIFEST = (
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    "<PoBVersion>\n"
    '\t<Version number="1.0.0" />\n'
    "</PoBVersion>\n"
)


def make_repo(tmp_path: pathlib.Path, cfg: str) -> None:
    (tmp_path / "manifest.xml").write_text(BASE_MANIFEST)
    (tmp_path / "manifest.cfg").write_text(cfg)
    runtime = tmp_path / "runtime"
    runtime.mkdir()
    (runtime / "SimpleGraphic.dll").write_bytes(b"\x00binary")
    (runtime / "Update").write_bytes(b"\x00posix-executable")  # extensionless
    lua = runtime / "lua"
    lua.mkdir()
    (lua / "xml.lua").write_text("-- lua module\n")
    src = tmp_path / "src"
    src.mkdir()
    (src / "Launch.lua").write_text("-- launch\n")


def generate(tmp_path, monkeypatch, cfg):
    make_repo(tmp_path, cfg)
    monkeypatch.chdir(tmp_path)
    create_manifest(version="1.2.3", replace=True)
    return Et.parse(tmp_path / "manifest.xml").getroot()


def test_platform_section_tags_sources_and_files(tmp_path, monkeypatch):
    root = generate(
        tmp_path,
        monkeypatch,
        "[runtime]\npath = runtime\nplatform = win32\n\n[program]\npath = src\n",
    )
    sources = {
        (s.get("part"), s.get("platform")): s.get("url") for s in root.findall("Source")
    }
    assert ("runtime", "win32") in sources
    assert ("program", None) in sources
    runtime_files = {
        f.get("name"): f for f in root.findall("File") if f.get("part") == "runtime"
    }
    # every file in a platformed section is tagged, not just .dll/.exe
    assert runtime_files["SimpleGraphic.dll"].get("platform") == "win32"
    assert runtime_files["lua/xml.lua"].get("platform") == "win32"
    # legacy attribute dropped
    assert runtime_files["SimpleGraphic.dll"].get("runtime") is None
    # extensionless files are included
    assert "Update" in runtime_files
    program_files = {
        f.get("name"): f for f in root.findall("File") if f.get("part") == "program"
    }
    assert program_files["Launch.lua"].get("platform") is None


def test_part_override_allows_multiple_runtime_sections(tmp_path, monkeypatch):
    cfg = (
        "[runtime]\npath = runtime\nplatform = win32\n\n"
        "[runtime-linux64]\npath = runtime\npart = runtime\nplatform = linux64\n"
    )
    root = generate(tmp_path, monkeypatch, cfg)
    sources = {(s.get("part"), s.get("platform")) for s in root.findall("Source")}
    assert ("runtime", "win32") in sources
    assert ("runtime", "linux64") in sources
    parts = {f.get("part") for f in root.findall("File")}
    assert parts == {"runtime"}
    platforms = {f.get("platform") for f in root.findall("File")}
    assert platforms == {"win32", "linux64"}
