#!/bin/sh
# Container mounts: /harness, /base and /candidate are read-only; /results and /baseline are writable.
set -eu
export LC_ALL=C
tools=/harness/spec/corpus
results=/results
inputs=$results/inputs
mkdir "$inputs" "$results/candidate" "$results/batches"
export LUA_PATH="/harness/runtime/lua/?.lua;/harness/runtime/lua/?/init.lua;;"
luajit "$tools/FetchTestBuilds.lua" /corpus.json "$inputs" > "$results/snapshot.txt"
cat "$results/snapshot.txt"

find /harness/spec/TestBuilds -name '*.xml' | sort | while IFS= read -r fixture; do
    name=$(basename "$fixture" .xml | tr ' ' '-')
    dest="$inputs/fixture-$name"
    test ! -e "$dest.xml"
    cp "$fixture" "$dest.xml"
    echo 'checked-in fixture' > "$dest.tags"
done
(cd "$inputs"; for file in *.xml; do echo "${file%.xml}"; done) > "$results/builds.txt"
split -l 50 "$results/builds.txt" "$results/batches/batch-"
expected=$(wc -l < "$results/builds.txt")

calculate() (
    cd "$1/src"
    export LUA_PATH="../runtime/lua/?.lua;../runtime/lua/?/init.lua;;"
    find "$results/batches" -name 'batch-??' -print0 | sort -z | xargs -0 -P "${BUILD_JOBS:-2}" -I '{}' sh "$tools/batch.sh" '{}' "$2"
    actual=$(find "$2" -name '*.build' | wc -l)
    echo "Calculated $actual of $expected inputs for $1"
)

if [ ! -f /baseline/complete ]; then
    calculate /base /baseline
    if [ "$(find /baseline -name '*.build' | wc -l)" -eq "$expected" ] && [ -z "$(find /baseline -name '*.error' -print -quit)" ]; then
        cp "$results/builds.txt" /baseline/complete
    fi
else
    cmp /baseline/complete "$results/builds.txt"
    echo "Reused $expected baseline calculations"
fi
calculate /candidate "$results/candidate"

: > "$results/stat-diffs.txt"
: > "$results/import-errors.txt"
: > "$results/other-diffs.txt"
compared=0
while IFS= read -r name; do
    base="/baseline/$name"
    head="$results/candidate/$name"
    if [ -f "$base.error" ] || [ -f "$head.error" ]; then
        if [ -f "$base.error" ]; then printf 'Base: ' >> "$results/import-errors.txt"; cat "$base.error" >> "$results/import-errors.txt"; fi
        if [ -f "$head.error" ]; then printf 'Candidate: ' >> "$results/import-errors.txt"; cat "$head.error" >> "$results/import-errors.txt"; fi
        continue
    fi
    if output=$(luajit "$tools/DiffOutput.lua" "$head.build" "$base.build"); then :
    else
        status=$?
        [ "$status" -eq 1 ] || exit "$status"
        printf '## Output Diff for %s.build\n%s\n' "$name" "$output" >> "$results/stat-diffs.txt"
    fi
    xmllint --nonet --exc-c14n "$head.build" > /tmp/head.xml
    xmllint --nonet --exc-c14n "$base.build" > /tmp/base.xml
    if ! cmp -s /tmp/head.xml /tmp/base.xml; then echo "Saved XML changed: $name" >> "$results/other-diffs.txt"; fi
    if output=$(luajit "$tools/DiffRuntime.lua" "$head.time" "$base.time" "$name"); then :
    else
        status=$?
        [ "$status" -eq 1 ] || exit "$status"
        printf '%s\n' "$output" >> "$results/other-diffs.txt"
    fi
    compared=$((compared + 1))
done < "$results/builds.txt"
luajit "$tools/BuildSummary.lua" "$results/stat-diffs.txt" "$compared" "$BASE_SHA" "$CANDIDATE_SHA" > "$results/summary.md"
cat "$results/snapshot.txt" >> "$results/summary.md"
if [ -s "$results/import-errors.txt" ]; then
    printf '\n**Import or calculation failures**\n\n' >> "$results/summary.md"
    head -n 15 "$results/import-errors.txt" >> "$results/summary.md"
    exit 1
fi
test "$compared" -eq "$expected"
if [ "${STRICT:-false}" = true ] && [ -s "$results/stat-diffs.txt" ]; then exit 1; fi
