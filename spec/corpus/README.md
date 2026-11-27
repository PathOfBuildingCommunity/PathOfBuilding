# Manual build corpus comparison

Select **Actions → Compare build corpus → Run workflow**. Choose a baseline commit and a candidate commit from this repository. The candidate defaults to the selected workflow revision. Running a control with the same commit on both sides measures repeatability. The workflow runs only on manual dispatch.

Each run fetches one [PoB Codes corpus](https://api.pob.codes/test-builds/corpus), records its snapshot ID and response SHA-256, verifies the SHA-256 of each encoded build, and decodes the inputs once. Supply the optional response digest to require the same snapshot across runs. A snapshot change then stops the run before calculations. Both PoB revisions load every corpus entry and the same checked-in XML fixtures.

The check fails for import errors, missing outputs, aborted calculations and incomplete comparisons. A crash report identifies the revision side, build hash and saved corpus criteria. Remaining inputs in that batch resume in a fresh PoB process. The summary compares saved player and minion stats and additional scalar numeric and boolean outputs. Enable **strict** to fail on any stat difference. Timing and saved-XML changes are informational. Download **build-diff-output** for the per-build reports.

The baseline cache is keyed by the exact baseline commit, corpus response, comparison tools, image definition and fixtures. Only complete baselines are cached. Each run calculates the candidate. GitHub cache eviction makes the next run recalculate the baseline.

## Run locally

From the checkout containing this harness, point `BASE` and `CANDIDATE` at clean checkouts of the revisions to compare. The test container reads both without modifying either. This example uses a new baseline directory.

```sh
BASE=/absolute/path/to/base
CANDIDATE=/absolute/path/to/candidate
run=$(mktemp -d)
mkdir "$run/results" "$run/baseline"
curl -fsS --max-filesize 16777216 https://api.pob.codes/test-builds/corpus -o "$run/corpus.json"
docker build -t pob-corpus spec/corpus
docker run --rm --network none --user "$(id -u):$(id -g)" \
  -v "$PWD:/harness:ro" -v "$BASE:/base:ro" -v "$CANDIDATE:/candidate:ro" \
  -v "$run/corpus.json:/corpus.json:ro" -v "$run/results:/results" -v "$run/baseline:/baseline" \
  -e BASE_SHA="$(git -C "$BASE" rev-parse HEAD)" -e CANDIDATE_SHA="$(git -C "$CANDIDATE" rev-parse HEAD)" \
  pob-corpus sh /harness/spec/corpus/run.sh
cat "$run/results/summary.md"
```
