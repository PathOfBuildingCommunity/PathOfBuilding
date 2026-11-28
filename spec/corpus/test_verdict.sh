#!/bin/sh
set -eu
tools=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
: > "$work/errors.tsv"
: > "$work/stats.tsv"

expect_status() {
    expected=$1
    strict=$2
    override=$3
    actual=0
    sh "$tools/verdict.sh" "$work" "$strict" "$override" || actual=$?
    if [ "$actual" -ne "$expected" ]; then
        echo "Expected status $expected, got $actual" >&2
        exit 1
    fi
}

expect_status 0 false false
printf 'baseline\tbuild\t1\tloading\tknown failure\n' > "$work/errors.tsv"
expect_status 0 false false
printf 'candidate\tbuild\t1\tloading\tnew failure\n' > "$work/errors.tsv"
expect_status 1 false false
expect_status 0 false true
printf 'baseline\tbuild\t1\tloading\tknown failure\n' > "$work/errors.tsv"
printf 'candidate\tbuild\t1\tloading\tstill failing\n' >> "$work/errors.tsv"
expect_status 1 false false
expect_status 0 false true
: > "$work/errors.tsv"
printf 'build\tPlayer\tLife\t100\t101\n' > "$work/stats.tsv"
expect_status 0 false false
expect_status 1 true false
expect_status 0 true true
