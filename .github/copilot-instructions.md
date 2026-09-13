# GitHub Copilot Instructions

This file provides guidance to GitHub Copilot when working with code in this repository: a
fuzzy-logic FX trading strategy implemented twice, independently, in Python and MQL5.

This file is intentionally short — a map, not the content. Details live in `docs/`:

- **`docs/architecture.md`** — subsystem boundaries, core data structures. Read when you need
  to understand where something lives before making a change.
- **`docs/mql5-development.md`** — compiling MQL5 scripts, running the MetaTrader terminal.
  Read before compiling or running anything under `MetaTrader5_TMPL/`.
- **`docs/known-issues.md`** — open bugs and planned/deferred work. Read before starting new
  work on `TestVariables.mq5`/`variables.mqh`, to check if it's already known or planned.
- **`docs/design-decisions.md`** — settled technical decisions and why. Read before
  questioning or reversing something that looks like a past decision.
- **`docs/changelog.md`** — dated, one-line implementation milestones, newest first.
- **`docs/repository-notes.md`** — full historical detail (root-cause investigations, design
  sketches, rejected alternatives) behind everything condensed in the docs above. Read this
  for anything not fully covered by the focused docs.

## Recap instruction

A fresh session has no memory of what was discussed last time. For any "recap" / "what's the
state of X" / "summarize the project" request: check `docs/changelog.md` for recent
milestones and `git log` for anything not yet documented there — don't rely on the doc map
alone being current.

**Any of these files can grow long.** If a doc looks partial or you're unsure you're seeing
all of it, read the file directly rather than answering from a truncated or cached view.

## Maintaining this documentation

When you produce new information worth keeping, write it to the matching file immediately —
don't leave it only in conversation history:

- **New bug/regression found, not yet fixed** → append to `docs/known-issues.md` under
  "Open issues."
- **New future idea/plan sketched, not yet implemented** → append to `docs/known-issues.md`
  under "Planned / deferred work."
- **A bug gets fixed, or a design question gets settled** →
  1. append the full root-cause reasoning / rationale to `docs/repository-notes.md`,
  2. add the condensed decision + a pointer into `docs/design-decisions.md`,
  3. add a one-line dated entry (newest first) to `docs/changelog.md`, and
  4. remove/update the corresponding entry in `docs/known-issues.md` if it was tracked there.
- **Subsystem boundaries, core data structures, or major files added/changed/removed** →
  update `docs/architecture.md` directly.
- **Compile/run/tooling procedure changes** → update `docs/mql5-development.md` directly.
- **Any real milestone** (not a pure doc correction) → always gets a `docs/changelog.md`
  line, even if its full detail lives elsewhere.
