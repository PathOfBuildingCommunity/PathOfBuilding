# Cross-platform architecture

Path of Building is a pure-Lua application (`src/`) that runs on a native host.
The host API contract is specified, in executable form, by
[`src/HeadlessWrapper.lua`](../src/HeadlessWrapper.lua): any host that provides
those globals (rendering, input, filesystem search, clipboard, subscripts,
`Inflate`/`Deflate`, path helpers) can run the app. The shipping host is
SimpleGraphic (built from
[PathOfBuilding-SimpleGraphic](https://github.com/PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic)),
which renders through GLFW + ANGLE (OpenGL ES) and is delivered into `runtime/`
by the `update-simple-graphic` workflow.

## Platform identity

A client learns its platform from the `platform` attribute of the `<Version>`
element in its local `manifest.xml` (e.g. `win32`). The updater
(`src/UpdateCheck.lua`) then:

- includes a remote `<File>` iff it has no `platform` attribute or its
  `platform` matches the local platform;
- downloads each part from `<Source part="..." platform="...">` matching the
  local platform, falling back to the platform-less source.

`update_manifest.py` generates these attributes from `manifest.cfg`: a section
with a `platform` option tags its source and every file it contains with that
platform. A section may set `part` to publish under a shared part name, so a
future `[runtime-linux64]` section (with `part = runtime`,
`platform = linux64`) ships an alternative runtime bundle without any client
code changes.

## Update ops

`UpdateCheck.lua` stages downloads and writes an ops file that
`UpdateApply.lua` executes (`move`, `delete`, `chmod`, `start`). On non-win32
platforms, updated runtime files without a file extension (the POSIX
executables) get a `chmod` op so they stay executable after being rewritten.
Runtime files are applied by a second, minimal host (`runtime/Update` /
`Update.exe`) because the main host's own binaries cannot replace themselves
while running.

## Host expectations

Hosts are not required to provide every global: `GetCloudProvider` is optional,
and `jit.opt` tuning is skipped when unavailable. Asset paths are
case-sensitive on Linux/macOS; `spec/System/TestAssetCase_spec.lua` enforces
that all `Assets/` references match on-disk casing exactly.

## Status

Native Linux/macOS support additionally requires (tracked as follow-on plans):

1. A POSIX/macOS system layer in PathOfBuilding-SimpleGraphic publishing
   `SimpleGraphicDLLs-<arch>-<os>.tar` release assets (the Windows asset
   already follows this naming).
2. Per-platform runtime bundles in this repo (`[runtime-<platform>]` manifest
   sections), ingestion workflow updates, and packaging. Until then, Linux
   users run the Windows build under Wine or use community hosts such as
   pobfrontend.

On macOS, a native app can be built locally today: `make macos-app` builds
the SimpleGraphic host from a sibling clone (branch `feat/macos-build`, currently local-only, pending upstream submission) and
assembles `build/macos/Path of Building.app`, a dev-mode app running
`src/Launch.lua` from this checkout (auto-updates disabled by design — see
the spec in `docs/superpowers/specs/2026-08-05-macos-app-design.md`).
