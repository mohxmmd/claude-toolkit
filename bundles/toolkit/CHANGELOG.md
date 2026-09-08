# Changelog

All notable changes to the Toolkit bundle are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The bundle's version tracks its own manifest and skill, not the components it
depends on. A component release does not require a bundle release unless the
pinned range no longer resolves.

## [0.1.2] — 2026-09-08

### Added

- `/toolkit:setup` reports when auto-update is off and names the one command
  that turns it on. The line appears only when it is off.
- `scripts/state.sh` detects both halves of the auto-update gate: the
  marketplace's `autoUpdate` flag and `FORCE_AUTOUPDATE_PLUGINS`, which is
  additionally required on native and VS Code installs where Claude Code's own
  auto-updater is disabled.

### Notes

- The skill never offers to enable auto-update itself. It lives in the user's
  own settings file, and a plugin that could grant itself update rights could
  ship arbitrary code to every user with no review after the first install.
  Three routes for a plugin to set it were tested and all are closed — see
  [docs/AUTO-UPDATE.md](../../docs/AUTO-UPDATE.md).

## [0.1.1] — 2026-09-08

### Fixed

- **`/toolkit:setup` could not work.** It instructed the model to invoke
  `/charter:init`, which is marked `disable-model-invocation: true` — that
  removes a skill from the model's view entirely, so no model can call it,
  through the Skill tool or otherwise. The command failed on its first real use.

  It is now an orientation: it reads what is configured in the current
  repository and prints the one command to type next. It writes nothing and
  calls nothing.

  The flag on `/charter:init` is correct and stays. That command rewrites
  permission rules, and it should fire because a person typed it. The other
  possible fix — having the bundle reimplement Charter's writes — would be worse
  than the bug: artifacts Charter did not author and cannot later diff, check,
  or update.

### Added

- `scripts/state.sh` — read-only repository state, so the report is derived
  rather than guessed.

## [0.1.0] — 2026-09-08

### Added

- The bundle. Declares Charter `^0.1.0`, Craft `^0.1.0` and TARS `^1.1.0` as
  dependencies, so one install command produces all three.
- `/toolkit:setup`. Broken on release; see 0.1.1.

### Notes

- Ranges are pinned deliberately. An unpinned dependency drags a broken
  component release into every new install of the bundle.
- The bundle cannot be loaded with `--plugin-dir`: dependencies cannot resolve
  outside a marketplace, and Claude Code disables a plugin whose dependencies
  are unsatisfied. This is why the coupling lives here rather than in Charter,
  where it would have broken vendoring the directory on its own.
