#!/bin/sh
set -eu
results=$1
strict=${2:-false}

if awk -F '\t' '$1 == "candidate" { found = 1 } END { exit found ? 0 : 1 }' "$results/errors.tsv"; then
    exit 1
fi
if [ "$strict" = true ] && [ -s "$results/stats.tsv" ]; then
    exit 1
fi
