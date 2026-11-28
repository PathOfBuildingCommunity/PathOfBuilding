# Build corpus comparison

**Release candidates.** Preparing a release with **Release next version** starts a comparison on the prepared release branch. Later maintainer pushes to that branch start a new comparison on the updated commit. Open **Compare build corpus** in the release PR's **Checks** tab to read the result before publishing. Each run compares its candidate commit against the latest published stable community release at the start of the run. The report records both commit hashes. Stat changes are advisory. Crashes and incomplete runs fail the check. The workflow does not enforce a merge or publication policy.

**Manual runs.** Select **Actions → Compare build corpus → Run workflow**. Leave the baseline blank to use the latest stable release or enter a baseline from this repository. The candidate defaults to the selected workflow revision. To measure repeatability, enter the same commit for both revisions.

Each run fetches one [PoB Codes corpus](https://api.pob.codes/test-builds/corpus), records its snapshot ID and response SHA-256, verifies the SHA-256 of each encoded build, and decodes the inputs once. Supply the optional response digest to require the same snapshot across runs. A snapshot change then stops the run before calculations. Both PoB revisions load every corpus entry and the same checked-in XML fixtures.

## Reading the result

Open the job summary in GitHub Actions. The first line gives the result. A failed build appears first, with the revision that failed, the build link, and the error PoB returned when available. If a build failed on the baseline alone, the candidate finished that build but a comparison was impossible.

**Stat changes.** Each affected build has a table showing the player or minion stat, its baseline value, and its candidate value. For widespread changes, the report also shows which stats changed on the most builds. Changes are advisory by default. Selecting **strict** makes any stat change fail the check. Failure to load, calculate, save, or complete the comparison always fails it.

**Time and saved files.** CPU time measures the work spent parsing, loading and calculating a build. It excludes saving. The report lists measurements that differ by at least 10% in either direction. A single sample can vary between runs. A saved XML difference means PoB wrote different output for the same input. This includes its calculated stats. Both observations are informational.

**Downloads.** Open **build-diff-output** under **Artifacts** or use the download link in the job summary.

| File | When to open it |
| --- | --- |
| `summary.md` | Read the full report, including every affected build and its changes. GitHub shows a shorter overview for large reports. |
| `builds.csv` | Look up a full build ID, a verified link, or the outcome for any input. |
| `stat-changes.csv` | Filter changed stats across builds or copy exact values. Created only when stats change. |

Fixtures link to their XML at the tested harness revision. For public corpus builds the report checks that the hosted code matches the input before linking. If the link cannot be verified within the lookup window, search the build list for its identifier. The inventory includes unchanged builds as well. If the run stops before completing its comparison, the report names the failed run and directs you to the Actions log.

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
export BASE_SHA="$(git -C "$BASE" rev-parse HEAD)" CANDIDATE_SHA="$(git -C "$CANDIDATE" rev-parse HEAD)"
export STRICT=false
status=0
docker run --rm --network none --user "$(id -u):$(id -g)" \
  -v "$PWD:/harness:ro" -v "$BASE:/base:ro" -v "$CANDIDATE:/candidate:ro" \
  -v "$run/corpus.json:/corpus.json:ro" -v "$run/results:/results" -v "$run/baseline:/baseline" \
  -e STRICT pob-corpus sh /harness/spec/corpus/run.sh || status=$?
# Use your fork name here if that is where the harness commit lives.
python3 spec/corpus/report.py "$run/results" "$run/corpus.json" . \
  PathOfBuildingCommunity/PathOfBuilding "$(git rev-parse HEAD)" || exit $?
cat "$run/results/report/summary.md"
exit "$status"
```
