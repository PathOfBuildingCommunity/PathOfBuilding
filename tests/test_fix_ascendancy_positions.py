import filecmp
import pathlib
import shutil
import tempfile

import fix_ascendancy_positions


def test_fix_one() -> None:
    raw = pathlib.Path("data.json")
    fixed = pathlib.Path("data_fixed.json")
    with tempfile.TemporaryDirectory() as td:
        new = pathlib.Path(td, raw)
        shutil.copy(raw, td)
        fix_ascendancy_positions.fix_ascendancy_positions(new)
        assert filecmp.cmp(new, fixed, shallow=False)


def test_fix_all() -> None:
    raw = pathlib.Path("data.json")
    fixed = pathlib.Path("data_fixed.json")
    with tempfile.TemporaryDirectory() as outer, tempfile.TemporaryDirectory(
        dir=outer
    ) as inner:
        root = pathlib.Path(outer)
        new = pathlib.Path(inner, raw)
        shutil.copy(raw, inner)
        fix_ascendancy_positions.main(root)
        assert filecmp.cmp(new, fixed, shallow=False)
