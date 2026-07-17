# Sidecar owns the Agent Window

PoB's Lua/SimpleGraphic host has a single OS window and only modal `PopupDialog` overlays — unsuitable for a chat advisor that must stay open while the user edits the build. We put the floating Agent Window in a **local sidecar process** that PoB spawns; PoB remains build authority (snapshot / apply / undo) over localhost HTTP/JSON.

## Considered options

- **In-app non-modal floating panel** — would require inventing hit-testing and input routing outside `main.popups`; possible later, rejected for v1.
- **Modal PopupDialog** — blocks PoB use while open; rejected.
- **Sidecar-owned window** — chosen; matches Cursor SDK hosting and custom chat UX.

## Consequences

- PoB must spawn/monitor the sidecar and expose bridge APIs; UI polish lives outside Lua.
- Closed state is a compact pill in the sidecar (see PRD / prototype), not a PoB toast.
