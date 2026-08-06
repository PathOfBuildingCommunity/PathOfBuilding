#!/usr/bin/env bash
# Assembles Path of Building.app from the SimpleGraphic install tree.
# Contents/MacOS mirrors the Windows runtime/ layout: the host resolves fonts,
# lua modules, and native modules relative to the executable's directory.
set -euo pipefail

: "${SG_DIST:?SG_DIST not set}"
: "${BUILD_DIR:?BUILD_DIR not set}"
: "${POB_ROOT:?POB_ROOT not set}"

for f in pob libSimpleGraphic.dylib lcurl.so lua-utf8.so socket.so lzip.so libEGL.dylib; do
	if [[ ! -e "$SG_DIST/$f" ]]; then
		echo "error: missing $SG_DIST/$f — run 'make macos-runtime' (see docs/crossPlatform.md)" >&2
		exit 1
	fi
done

APP="$BUILD_DIR/Path of Building.app"
MACOS_DIR="$APP/Contents/MacOS"
rm -rf "$APP"
mkdir -p "$MACOS_DIR"

# Native runtime: launcher (renamed to match CFBundleExecutable), dylibs, Lua modules
cp "$SG_DIST/pob" "$MACOS_DIR/Path of Building"
find "$SG_DIST" -maxdepth 1 \( -name '*.dylib' -o -name '*.so' \) -exec cp -R {} "$MACOS_DIR/" \;
# Pure-Lua modules and fonts from the repo's platform-neutral runtime dir
cp -R "$POB_ROOT/runtime/lua" "$MACOS_DIR/lua"
mkdir -p "$MACOS_DIR/SimpleGraphic"
cp -R "$POB_ROOT/runtime/SimpleGraphic/Fonts" "$MACOS_DIR/SimpleGraphic/Fonts"

cp "$POB_ROOT/scripts/macos/Info.plist" "$APP/Contents/Info.plist"

# The app runs the Lua program from this checkout (dev mode: updater disabled,
# user data lives in the checkout). POB_SCRIPT_PATH overrides at launch.
cat > "$MACOS_DIR/launch-env.sh" <<EOF
#!/bin/bash
export POB_SCRIPT_PATH="\${POB_SCRIPT_PATH:-$POB_ROOT/src/Launch.lua}"
exec "\$(dirname "\$0")/Path of Building.bin" "\$@"
EOF

# Wrapper trick: CFBundleExecutable -> shell wrapper baking the script path.
mv "$MACOS_DIR/Path of Building" "$MACOS_DIR/Path of Building.bin"
mv "$MACOS_DIR/launch-env.sh" "$MACOS_DIR/Path of Building"
chmod +x "$MACOS_DIR/Path of Building" "$MACOS_DIR/Path of Building.bin"

codesign --force --deep -s - "$APP"
echo "built: $APP"
