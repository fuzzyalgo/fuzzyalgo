# Copilot instructions

Follow the repository guidance in `CLAUDE.md` and the focused documents under `docs/`.

This repository contains two independent systems: Python under `Lib/algotrader/` and MQL5 under `MetaTrader5_TMPL/MQL5/`. Do not assume they share code or validation tooling.

Read the relevant document before working:

- `docs/architecture.md` for subsystem boundaries and core structures.
- `docs/mql5-development.md` for MQL5 compilation and terminal execution.
- `docs/known-issues.md` for current unresolved behavior.
- `docs/design-decisions.md` before revisiting settled choices.
- `docs/changelog.md` for dated, one-line implementation milestones, newest first.
- `docs/repository-notes.md` for full historical detail behind everything condensed in the other docs (root-cause investigations, design sketches, rejected alternatives — not just tick-cache).

Never expose or commit credentials, `config/common.ini`, per-user account JSON files, terminal binaries, or compiler logs. Write compiler logs to `C:\fuzzyalgo\logs\`. MQL5 source edits affect all provisioned MT5 accounts because their MQL5 directories are symlinked to this repository.

Keep changes focused, preserve existing behavior unless the task requires otherwise, and validate Python changes with the relevant script or MQL5 changes by compiling the relevant script and inspecting its output.

Keep the documentation current as you work, rather than leaving new information only in conversation/PR history:

- New bug found, or a new idea sketched but not yet implemented → append to `docs/known-issues.md`.
- A bug fixed, or a design question settled → append the full reasoning to `docs/repository-notes.md`, add the condensed decision to `docs/design-decisions.md`, add a dated one-line entry (newest first) to `docs/changelog.md`, and remove/update the corresponding `docs/known-issues.md` entry.
- Subsystem boundaries, core data structures, or major files added/changed/removed → update `docs/architecture.md`.
- Compile/run/tooling procedure changes → update `docs/mql5-development.md`.
- Any real milestone, even with detail living elsewhere → always add a line to `docs/changelog.md`.
