#!/bin/sh
set -eu
batch=$1
out=$2
cursor="$batch.cursor"
next=1
log=$(mktemp)
trap 'rm -f "$log"' EXIT
count=$(wc -l < "$batch")
while [ "$next" -le "$count" ]; do
    rm -f "$cursor" "$cursor.stage"
    if luajit /harness/spec/corpus/Calculate.lua "$batch" "$cursor" "$out" "$next" > "$log" 2>&1; then
        cat "$log"
        break
    else
        status=$?
        cat "$log" >&2
    fi
    # A native crash can terminate Lua before it can report an error. Its last
    # flushed cursor identifies the build. Resume the remaining inputs in a fresh PoB.
    if [ ! -s "$cursor" ]; then
        echo "PoB failed to start (exit $status)" >&2
        exit "$status"
    fi
    index=$(cat "$cursor")
    name=$(sed -n "${index}p" "$batch")
    reason=$(sed -n "/In 'OnFrame':/{s/.*In 'OnFrame': //;p;q;}" "$log")
    if [ -z "$reason" ]; then reason=$(sed -n 's/^luajit: //p' "$log" | head -n 1); fi
    printf '%s\t%s\t%s\n' "$status" "$(cat "$cursor.stage")" "$reason" > "$out/$name.error"
    next=$((index + 1))
done
