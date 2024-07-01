#!/bin/sh
umask 0

# If external cache dir has not been defined keep it inside the container
if [[ -z "$CACHEDIR" ]]
then
    mkdir /tmp/cachedir
    export CACHEDIR="/tmp/cachedir"
fi

# Copy mounted workdir to allow for changes during test run
rm -rf /tmp/workdir && mkdir /tmp/workdir && cp -rf "$WORKDIR"/. /tmp/workdir/ && cd /tmp/workdir

git config --global --add safe.directory /tmp/workdir
git config --global --add advice.detachedHead false

if [[ ! -z "$HEADREF" ]]
then
    git diff --no-color "$HEADREF" -- /tmp/workdir/.busted /tmp/workdir/src/HeadlessWrapper.lua /tmp/workdir/spec/ > /tmp/HeadPatch &&
    git reset --hard "$HEADREF" && git clean -fd && git apply --allow-empty /tmp/HeadPatch
fi

headsha=$(git rev-parse HEAD)
devsha=$(git rev-parse "$DEVREF")

rm -rf /tmp/headsha && mkdir /tmp/headsha
rm /tmp/workdir/src/Settings.xml
cat /tmp/workdir/spec/builds.txt | dos2unix | parallel --will-cite --ungroup --pipe -N50 'LINKSBATCH="$(mktemp){#}"; cat > $LINKSBATCH; BUILDLINKS="$LINKSBATCH" BUILDCACHEPREFIX="/tmp/headsha" busted --lua=luajit -r generate' && \
BUILDCACHEPREFIX='/tmp/headsha' busted --lua=luajit -r generate && date > "/tmp/headsha/$headsha" && echo "[+] Build cache computed for $headsha (headsha)" || exit $?

if [[ ! -f "$CACHEDIR/$devsha" ]] # Output of builds outdated or nonexistent
then
	rm -rf "$CACHEDIR"/*.build

    # Keep new changes to tests related files
    git diff --no-color "$DEVREF" -- /tmp/workdir/.busted /tmp/workdir/src/HeadlessWrapper.lua /tmp/workdir/spec/ > /tmp/DevPatch && \
    git reset --hard "$DEVREF" && git clean -fd && git apply --allow-empty /tmp/DevPatch && \
    cat /tmp/workdir/spec/builds.txt | dos2unix | parallel --will-cite --ungroup --pipe -N50 'LINKSBATCH="$(mktemp){#}"; cat > $LINKSBATCH; BUILDLINKS="$LINKSBATCH" BUILDCACHEPREFIX="$CACHEDIR" busted --lua=luajit -r generate' && \
    BUILDCACHEPREFIX="$CACHEDIR" busted --lua=luajit -r generate && date > "$CACHEDIR/$devsha" && echo "[+] Build cache computed for $devsha (devsha)" || exit $?
fi

for build in "$CACHEDIR"/*.build
do
    BASENAME=$(basename "$build")

    # Only print the header if there is a diff to display
    DIFFOUTPUT=$(diff <(xmllint --exc-c14n "$build") <(xmllint --exc-c14n "/tmp/headsha/$BASENAME")) || {
        echo "## Savefile Diff for $BASENAME"
        echo '```diff'
        echo "$DIFFOUTPUT"
        echo '```'
    }

    # Dedicated output diff
    DIFFOUTPUT=$(luajit spec/diffOutput.lua "/tmp/headsha/$BASENAME" "$build") || {
        echo "## Output Diff for $BASENAME"
        echo '```'
        echo "$DIFFOUTPUT"
        echo '```'
    }
done
