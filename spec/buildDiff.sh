#!/bin/sh
umask 0

# If external cache dir has not been defined keep it inside the container
if [[ -z "$CACHEDIR" ]]
then
    mkdir /tmp/cachedir
    export CACHEDIR="/tmp/cachedir"
fi

# Copy mounted workdir to allow for changes during test run
rm -rf /tmp/workdir && mkdir /tmp/workdir && cp -rf $WORKDIR/. /tmp/workdir/ && cd /tmp/workdir

git config --global --add safe.directory /tmp/workdir
git config --global --add advice.detachedHead false
headref=$(git rev-parse HEAD)
devref=$(git rev-parse origin/dev)

rm -rf /tmp/headref && mkdir /tmp/headref
rm /tmp/workdir/src/Settings.xml
cat /tmp/workdir/spec/builds.txt | dos2unix | parallel --will-cite --ungroup --pipe -N50 'LINKSBATCH="$(mktemp){#}"; cat > $LINKSBATCH; BUILDLINKS="$LINKSBATCH" BUILDCACHEPREFIX="/tmp/headref" busted --lua=luajit -r generate' && \
BUILDCACHEPREFIX='/tmp/headref' busted --lua=luajit -r generate && date > "/tmp/headref/$headref" && echo "[+] Build cache computed for $headref (headref)" || exit $?

if [[ ! -f "$CACHEDIR/$devref" ]] # Output of builds outdated or nonexistent
then
	rm -rf $CACHEDIR/*.build

    # Keep new changes to tests related files
    git diff --no-color origin/dev -- /tmp/workdir/.busted /tmp/workdir/src/HeadlessWrapper.lua /tmp/workdir/spec/ > /tmp/patch && \
    git reset --hard origin/dev && git clean -fd && git apply --allow-empty /tmp/patch && \
    cat /tmp/workdir/spec/builds.txt | dos2unix | parallel --will-cite --ungroup --pipe -N50 'LINKSBATCH="$(mktemp){#}"; cat > $LINKSBATCH; BUILDLINKS="$LINKSBATCH" BUILDCACHEPREFIX="$CACHEDIR" busted --lua=luajit -r generate' && \
    BUILDCACHEPREFIX="$CACHEDIR" busted --lua=luajit -r generate && date > "$CACHEDIR/$devref" && echo "[+] Build cache computed for $devref (devref)" || exit $?
fi

for build in $CACHEDIR/*.build
do
    BASENAME=$(basename "$build")

    # Only print the header if there is a diff to display
    DIFFOUTPUT=$(diff <(xmllint --exc-c14n "$build") <(xmllint --exc-c14n "/tmp/headref/$BASENAME")) || {
        echo "## Savefile Diff for $BASENAME"
        echo '```diff'
        echo "$DIFFOUTPUT"
        echo '```'
    }

    # Dedicated output diff
    DIFFOUTPUT=$(luajit spec/diffOutput.lua "$build" "/tmp/headref/$BASENAME") || {
        echo "## Output Diff for $BASENAME"
        echo '```'
        echo "$DIFFOUTPUT"
        echo '```'
    }
done
