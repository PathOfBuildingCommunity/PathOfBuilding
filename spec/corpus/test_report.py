import csv
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from report import write_report


class ReportVerdictTest(unittest.TestCase):
    def render(self, errors="", stats="", strict=False, override=False, cache_hit=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            results = root / "results"
            harness = root / "harness"
            fixture_dir = harness / "spec" / "TestBuilds"
            results.mkdir()
            fixture_dir.mkdir(parents=True)
            fixture = "fixture-sample"
            (fixture_dir / "sample.xml").write_text("<PathOfBuilding/>", encoding="utf-8")
            (results / "builds.txt").write_text(fixture + "\n", encoding="utf-8")
            (results / "compared.txt").write_text("0\n" if errors else "1\n", encoding="utf-8")
            (results / "errors.tsv").write_text(errors, encoding="utf-8")
            (results / "stats.tsv").write_text(stats, encoding="utf-8")
            (results / "timing.tsv").write_text("", encoding="utf-8")
            (results / "xml-changes.txt").write_text("", encoding="utf-8")
            corpus = root / "corpus.json"
            corpus.write_text('{"snapshotId":"test-snapshot","builds":[]}', encoding="utf-8")
            environment = {
                "BASE_SHA": "a" * 40,
                "CANDIDATE_SHA": "b" * 40,
                "STRICT": str(strict).lower(),
                "OVERRIDE_VERDICT": str(override).lower(),
                "BASELINE_CACHE_HIT": str(cache_hit).lower(),
            }
            with patch.dict(os.environ, environment, clear=True):
                write_report(results, corpus, harness, "example/repo", "c" * 40)
            summary = (results / "report" / "summary.md").read_text(encoding="utf-8")
            with (results / "report" / "builds.csv").open(encoding="utf-8", newline="") as stream:
                build = next(csv.DictReader(stream))
            return summary, build

    def test_all_completed_builds_pass(self):
        summary, build = self.render()
        self.assertTrue(summary.startswith("# Passed - All builds had matching stats"))
        self.assertEqual(build["Result"], "Stats matched")

    def test_baseline_only_failure_passes_as_fixed(self):
        error = "baseline\tfixture-sample\t1\tloading\tknown failure\n"
        summary, build = self.render(errors=error, cache_hit=True)
        self.assertTrue(summary.startswith("# Passed - Candidate fixed 1 baseline failure"))
        self.assertIn("fixed baseline failures are visible but do not block", summary)
        self.assertIn("restored from an earlier complete run", summary)
        self.assertEqual(build["Result"], "Fixed in candidate")

    def test_candidate_only_failure_blocks(self):
        error = "candidate\tfixture-sample\t1\tsaving\tnew failure\n"
        summary, build = self.render(errors=error)
        self.assertTrue(summary.startswith("# Failed - Candidate stopped on 1 build"))
        self.assertIn("Candidate failures normally block the check", summary)
        self.assertIn("select **override verdict**", summary)
        self.assertEqual(build["Result"], "Candidate failed")

    def test_candidate_failure_can_be_overridden(self):
        error = "candidate\tfixture-sample\t1\tsaving\tknown failure\n"
        summary, build = self.render(errors=error, override=True)
        self.assertTrue(summary.startswith("# Passed by maintainer override - Candidate stopped on 1 build"))
        self.assertIn("All findings remain visible below", summary)
        self.assertEqual(build["Result"], "Candidate failed")

    def test_shared_failure_blocks(self):
        errors = ("baseline\tfixture-sample\t1\tloading\tknown failure\n"
                  "candidate\tfixture-sample\t1\tloading\tstill failing\n")
        summary, build = self.render(errors=errors)
        self.assertTrue(summary.startswith("# Failed - Candidate stopped on 1 build"))
        self.assertIn("Both revisions stopped.", summary)
        self.assertEqual(build["Result"], "Candidate failed")

    def test_strict_stat_change_blocks(self):
        stat = "fixture-sample\tPlayer\tLife\t100\t101\n"
        summary, _ = self.render(stats=stat, strict=True)
        self.assertTrue(summary.startswith("# Failed - Existing stat values changed on 1 build"))

    def test_strict_stat_change_can_be_overridden(self):
        stat = "fixture-sample\tPlayer\tLife\t100\t101\n"
        summary, _ = self.render(stats=stat, strict=True, override=True)
        self.assertTrue(summary.startswith("# Passed by maintainer override - Existing stat values changed on 1 build"))


if __name__ == "__main__":
    unittest.main()
