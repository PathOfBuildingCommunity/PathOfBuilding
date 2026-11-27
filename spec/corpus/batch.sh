#!/bin/sh
set -eu
batch=$1
out=$2
cursor="$batch.cursor"
next=1
count=$(wc -l < "$batch")
while [ "$next" -le "$count" ]; do
    rm -f "$cursor"
    if luajit /harness/spec/corpus/Calculate.lua "$batch" "$cursor" "$out" "$next"; then
        break
    else
        status=$?
    fi
    # A native crash can terminate Lua before it can report an error. Its last
    # flushed cursor identifies the build. Resume the remaining inputs in a fresh PoB.
    if [ ! -s "$cursor" ]; then
        echo "PoB failed to start (exit $status)" >&2
        exit "$status"
    fi
    index=$(cat "$cursor")
    name=$(sed -n "${index}p" "$batch")
    tags=$(cat "/results/inputs/$name.tags")
    printf '%s (exit %s) %s\n' "$name" "$status" "$tags" | tee "$out/$name.error" >&2
    next=$((index + 1))
done
