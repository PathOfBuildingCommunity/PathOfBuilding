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

# The report writer reads only these records. Write the completion marker last.
: > "$results/stats.tsv"
: > "$results/timing.tsv"
: > "$results/xml-changes.txt"
: > "$results/errors.tsv"
compared=0
while IFS= read -r name; do
    base="/baseline/$name"
    head="$results/candidate/$name"
    if [ -f "$base.error" ] || [ -f "$head.error" ]; then
        for side in baseline candidate; do
            if [ "$side" = baseline ]; then file="$base"; else file="$head"; fi
            if [ -f "$file.error" ]; then
                printf '%s\t%s\t%s\n' "$side" "$name" "$(cat "$file.error")" >> "$results/errors.tsv"
            fi
        done
        continue
    fi
    luajit "$tools/DiffOutput.lua" "$head.build" "$base.build" "$name" >> "$results/stats.tsv"
    xmllint --nonet --exc-c14n "$head.build" > /tmp/head.xml
    xmllint --nonet --exc-c14n "$base.build" > /tmp/base.xml
    if ! cmp -s /tmp/head.xml /tmp/base.xml; then echo "$name" >> "$results/xml-changes.txt"; fi
    printf '%s\t%s\t%s\n' "$name" "$(cat "$base.time")" "$(cat "$head.time")" >> "$results/timing.tsv"
    compared=$((compared + 1))
done < "$results/builds.txt"
printf '%s\n' "$compared" > "$results/compared.txt"
test "$compared" -eq "$expected"
if [ "${STRICT:-false}" = true ] && [ -s "$results/stats.tsv" ]; then exit 1; fi
