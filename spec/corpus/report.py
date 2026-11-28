"""Write the report published by the release workflow from the offline comparison."""
import base64
import csv
import hashlib
import html
import json
import os
import re
import sys
import time
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from decimal import Decimal, InvalidOperation
from http.client import HTTPException
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import urlopen


def safe(value):
    """Keep data from build exports inside a Markdown table cell."""
    text = html.escape(str(value))
    return re.sub(r"([\\|*_\[\]~\x60])", r"\\\1", " ".join(text.split()))


def number(count, singular, plural=None):
    return f"{count:,} {singular if count == 1 else plural or singular + 's'}"


def stat_name(key):
    words = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", key)
    words = re.sub(r"([A-Z])([A-Z][a-z])", r"\1 \2", words)
    return safe(words.replace("Dot", "DoT"))


def display_value(raw):
    if raw == "":
        return "Absent"
    try:
        value = Decimal(raw)
        if value.is_finite() and abs(value.adjusted()) < 30:
            return f"{value:,.2f}".rstrip("0").rstrip(".")
    except InvalidOperation:
        pass
    return safe(raw)


def values(before, after):
    left, right = display_value(before), display_value(after)
    # Small changes must remain visible even when the rounded values match.
    return (safe(before), safe(after)) if left == right else (left, right)


def public_url(code, deadline):
    token = base64.urlsafe_b64encode(hashlib.sha1(code).digest()).decode()
    for size in (11, 20):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        build_id = token[:size]
        try:
            with urlopen(f"https://api.pob.codes/{build_id}/raw", timeout=min(4, remaining)) as response:
                if response.read(len(code) + 2).rstrip(b"\r\n") == code:
                    return "https://pob.codes/b/" + build_id + ("0" if build_id.endswith("_") else "")
        except HTTPError as error:
            if error.code != 404:
                break
        except (OSError, HTTPException):
            break
    return ""


class Builds:
    def __init__(self, results, corpus, harness, repo, revision, ids, findings):
        self.names = {}
        self.urls = {}
        self.tags = {}
        fixtures = {"fixture-" + p.stem.replace(" ", "-"): p for p in (harness / "spec/TestBuilds").rglob("*.xml")}
        entries = {b["sha256"]: b for b in corpus["builds"]}
        for key in ids:
            if key in fixtures:
                path = fixtures[key]
                self.names[key] = path.stem
                self.urls[key] = f"https://github.com/{repo}/blob/{revision}/{quote(path.relative_to(harness).as_posix())}"
                continue
            self.tags[key] = entries[key].get("criteria", [])
            label = "Corpus build"
            try:
                with (results / "inputs" / (key + ".xml")).open("rb") as source:
                    for _, node in ET.iterparse(source, events=("start",)):
                        if node.tag == "Build":
                            cls = node.get("ascendClassName")
                            if cls in (None, "", "None"):
                                cls = node.get("className", "character")
                            label = f"Level {node.get('level', '?')} {cls}"
                            break
            except (OSError, ET.ParseError):
                pass
            self.names[key] = f"{label} ({key[:12]})"
        # Link checks are best effort. A provider outage must not hold up a release.
        lookup = [key for key in dict.fromkeys(findings) if key in entries]
        deadline = time.monotonic() + 45
        with ThreadPoolExecutor(max_workers=4) as pool:
            urls = pool.map(lambda key: public_url(entries[key]["code"].encode("ascii"), deadline), lookup)
            self.urls.update(zip(lookup, urls))

    def link(self, key):
        label = safe(self.names[key])
        url = self.urls.get(key)
        return f"[{label}]({url})" if url else label


def rows(path):
    return [line.split("\t") for line in path.read_text(encoding="utf-8").splitlines()]


def table(headers, records):
    return ["| " + " | ".join(row) + " |" for row in [headers, ["---"] * len(headers), *records]]


def revision_link(repo, sha):
    if re.fullmatch(r"[0-9a-f]{40}", sha):
        return f"[{sha[:12]}](https://github.com/{repo}/commit/{sha})"
    return safe(sha)


def write_report(results, corpus_file, harness, repo, revision):
    output = results / "report"
    output.mkdir(parents=True, exist_ok=True)
    summary = output / "summary.md"
    preview = results / "actions-summary.md"
    if not (results / "compared.txt").is_file():
        message = ("# Failed · Comparison did not finish\n\n"
                   "PoB could not finish comparing the builds. Open the first failed step in the Actions log "
                   "for the error. A complete list of changes is unavailable.\n")
        summary.write_text(message, encoding="utf-8")
        preview.write_text(message, encoding="utf-8")
        return

    raw_corpus = corpus_file.read_bytes()
    corpus = json.loads(raw_corpus)
    ids = (results / "builds.txt").read_text().splitlines()
    compared = int((results / "compared.txt").read_text())
    stats = defaultdict(list)
    for key, actor, stat, before, after in rows(results / "stats.tsv"):
        stats[key].append((actor, stat, before, after))
    failures = [line.split("\t", 4) for line in (results / "errors.tsv").read_text(encoding="utf-8", errors="replace").splitlines()]
    failed = {key for _, key, _, _, _ in failures}
    if len(ids) != len(set(ids)) or compared + len(failed) != len(ids):
        raise ValueError("Build counts do not match the comparison results")
    xml = (results / "xml-changes.txt").read_text().splitlines()
    timings = []
    for key, before, after in rows(results / "timing.tsv"):
        a, b = float(before), float(after)
        if a > 0 and abs(b - a) >= a * 0.1:
            timings.append((key, a, b))
    timings.sort(key=lambda row: -abs(row[2] - row[1]))
    builds = Builds(results, corpus, harness, repo, revision, ids,
                    [*(r[1] for r in failures), *stats, *(r[0] for r in timings), *xml])
    strict = os.environ.get("STRICT", "false").lower() == "true"
    changed = sum(map(len, stats.values()))
    verdict = "Failed" if failures or (strict and changed) else "Passed"
    if failures:
        sides = {row[0] for row in failures}
        if len(sides) == 1:
            title = f"{next(iter(sides)).capitalize()} stopped on {number(len(failed), 'build')}"
        else:
            title = f"PoB failed on {number(len(failed), 'build')}"
    elif changed:
        title = f"Stats changed for {number(len(stats), 'build')}"
    else:
        title = "All builds had matching stats"
    lines = [f"# {verdict} · {title}", "",
             f"Compared {compared:,} of {number(len(ids), 'build')}. "
             f"{number(len(corpus['builds']), 'build')} came from PoB.codes and "
             f"{len(ids) - len(corpus['builds'])} from PoB’s test files.", ""]

    if failures:
        lines += ["## Builds that failed", ""]
        by_build = defaultdict(set)
        for side, key, *_ in failures:
            by_build[key].add(side)
        for side, key, status, stage, reason in failures:
            other_side = "baseline" if side == "candidate" else "candidate"
            comparison = f"The {other_side} finished." if other_side not in by_build[key] else "Both revisions stopped."
            lines += [f"- {builds.link(key)} · The **{side}** stopped while {safe(stage)} this build (exit {safe(status)}). {comparison}",
                      "  - " + (safe(reason[:400]) if reason else "PoB did not return an error message. See the calculation log.")]
        lines.append("")
    if changed:
        lines += [f"{number(changed, 'stat value')} changed across {number(len(stats), 'build')}. "
                  + ("Strict mode makes a stat change fail this run." if strict else
                     "Stat changes are reported for review and do not fail this run."), ""]
    elif failures:
        lines += [f"Stats matched for all {compared:,} builds that finished.", ""] if compared else ["No build produced results on both revisions.", ""]
    if len(stats) > 5:
        examples = {}
        for key, changes in stats.items():
            for actor, stat, before, after in changes:
                examples.setdefault((actor, stat), (key, before, after))
        frequency = Counter((a, s) for entries in stats.values() for a, s, _, _ in entries)
        common = sorted(frequency, key=lambda k: (-frequency[k], k))
        top_rows = []
        for actor, stat in common[:10]:
            key, before, after = examples[actor, stat]
            top_rows.append((actor, stat_name(stat), str(frequency[actor, stat]),
                             builds.link(key), *values(before, after)))
        lines += ["## Stats that changed on the most builds", "",
                  "Before and after are shown for one affected build per row.", ""] + table(
            ["Whose stat", "Stat", "Builds", "Example build", "Before", "After"], top_rows) + [""]
    overview = lines.copy()
    if changed:
        lines += ["## Stat changes by build", "", "Before is the baseline. After is the candidate. "
                  "Values are rounded for reading. See **stat-changes.csv** for exact values.", ""]
        with (output / "stat-changes.csv").open("w", newline="", encoding="utf-8") as stream:
            writer = csv.writer(stream)
            writer.writerow(["Build", "Build ID", "Build URL", "Whose stat", "PoB stat", "Before", "After"])
            for key in sorted(stats, key=lambda k: (-len(stats[k]), builds.names[k])):
                lines += [f"### {builds.link(key)}", ""]
                changes = []
                for actor, stat, before, after in sorted(stats[key]):
                    writer.writerow([builds.names[key], key, builds.urls.get(key, ""), actor, stat, before, after])
                    changes.append((actor, stat_name(stat), *values(before, after)))
                lines += table(["Whose stat", "Stat", "Before", "After"], changes) + [""]

    if timings or xml:
        lines += ["## Other observations", "", "These observations do not affect the result.", ""]
    if timings:
        lines += ["### Time spent loading and calculating", "",
                  "CPU time measures processor work for one build, from reading its XML into PoB through calculating its stats. "
                  "The measurement ends before saving.",
                  "Each row is a single measurement that changed by at least 10%. Repeat the run to check a suspected slowdown.", ""]
        lines += table(["Build", "Baseline", "Candidate", "Change"],
                       [(builds.link(k), f"{a:,.1f} ms", f"{b:,.1f} ms", f"{100*(b/a-1):+.1f}%") for k, a, b in timings]) + [""]
    if xml:
        lines += ["### Builds that saved differently", "",
                  "Both revisions received the same input. PoB wrote different XML for the builds below. "
                  "The saved output includes calculated stats, so a stat change can also appear here.", ""]
        lines += ["- " + builds.link(k) for k in xml] + [""]
    metadata = ["## Run details", ""]
    for label, var in (("Baseline", "BASE_SHA"), ("Candidate", "CANDIDATE_SHA")):
        slug = os.environ.get("BASE_REPO", repo) if label == "Baseline" else repo
        tag = safe(os.environ.get("STABLE_TAG", "")) if label == "Baseline" else ""
        ref = revision_link(slug, os.environ[var])
        metadata.append(f"- {label}: {tag} {ref}" if tag else f"- {label}: {ref}")
    metadata += [f"- Corpus snapshot: {safe(corpus['snapshotId'])}",
                 f"- Snapshot SHA-256: \x60{hashlib.sha256(raw_corpus).hexdigest()}\x60"]
    lines += metadata
    summary.write_text("\n".join(lines) + "\n", encoding="utf-8")
    with (output / "builds.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(["Build", "Build ID", "Build URL", "Result", "Corpus criteria"])
        for key in ids:
            outcome = "Failed to compare" if key in failed else "Stats changed" if key in stats else "Stats matched"
            writer.writerow([builds.names[key], key, builds.urls.get(key, ""), outcome, ", ".join(builds.tags.get(key, []))])
    if summary.stat().st_size <= 60_000 and len(lines) <= 350:
        preview.write_bytes(summary.read_bytes())
    else:
        # GitHub caps job summaries at 1 MiB. The download always retains every finding.
        shortened = overview
        if len(failures) > 5:
            start = shortened.index("## Builds that failed") + 2
            end = start + 2 * len(failures)
            shortened = shortened[:start + 10] + [f"Showing 5 of {number(len(failures), 'failures')}."] + shortened[end:]
        shortened += ["", f"Timing changed by at least 10% for {number(len(timings), 'build')}. "
                      f"Saved XML differed for {number(len(xml), 'build')}."]
        shortened += ["", "Download **build-diff-output** and open **summary.md** for every affected build, "
                      "its values before and after, and all timing and saved XML observations.", ""]
        preview.write_text("\n".join(shortened + metadata) + "\n", encoding="utf-8")


if __name__ == "__main__":
    write_report(*(Path(arg) for arg in sys.argv[1:4]), *sys.argv[4:])
