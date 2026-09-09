# Changelog

All notable changes to the Toolkit bundle are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The bundle's version tracks its own manifest and skill, not the components it
depends on. A component release does not require a bundle release unless the
pinned range no longer resolves.

## [Unreleased]

### Added

- **`/forge:update`** — prints installed against published for all four plugins
  and updates what is behind. `--check` reports and changes nothing.
- **`update.sh` and `update.ps1`** at the repository root, plus
  `scripts/update.sh` inside the bundle so the command and the shell script are
  the same code. Versions are read from the plugin database and the marketplace
  cache, so the comparison needs no network beyond one marketplace refresh.
- **An optional weekly check**, `--weekly` / `--no-weekly`. It writes
  `~/.claude/forge/weekly-update.sh` and one `async` `SessionStart` hook, exits
  in milliseconds on six days out of seven, and updates in the background on
  the seventh. It is **not** the recommended way to stay current: Claude Code's
  own `autoUpdate` runs at every session start and needs no hook, so `--weekly`
  says so and asks before installing over a live `autoUpdate`.
- `/forge:uninstall` and both uninstall scripts now remove the weekly hook,
  `~/.claude/forge/`, and the `SessionStart` entry, leaving any other hook in
  that array untouched.
- 15 more assertions in `tests/run.sh` covering the seven-day gate, the lock,
  and that a foreign `SessionStart` hook survives both install and removal.

- **`/forge:uninstall`** — the one command that removes all of it: the four
  plugins, the marketplace, the settings the installer wrote, the TARS style
  file, and everything Charter and Craft wrote into the repository it is run
  from. It prints the full list first and removes nothing until the user says
  yes. `--plan` prints and stops.
- **`uninstall.sh` and `uninstall.ps1`** at the repository root, for uninstalling
  without the plugin installed, plus `scripts/uninstall.sh` inside the bundle so
  the command and the shell script are the same code.
- **The receipt, `.forge/manifest.tsv`** — Charter and Craft now append a line
  for every artifact they create and every file they edit, so removal is exact
  rather than inferred. The working agreement is cut out of `CLAUDE.md` and the
  prose around it survives byte for byte; rules Charter added come out of
  `permissions`, rules you added stay. Format is documented in
  [docs/UNINSTALL.md](../../docs/UNINSTALL.md).
- **A fallback for projects with no receipt.** Markers and known paths find the
  fence, `.craft/`, `.claude/charter.json` and a TARS `outputStyle`. Permission
  rules cannot be attributed without a receipt, so they are reported and left
  alone rather than guessed at.
- Backups for everything removed: settings files as `*.backup-<timestamp>`
  beside the original, project files copied into `.forge-backup-<timestamp>/`.
- 18 assertions in `tests/run.sh` covering both removal paths, including that
  user-authored prose, permission rules and `.gitignore` lines survive.

### Added

- **`setup.ps1` and `install.ps1`** — line-for-line PowerShell equivalents of
  `setup.sh` and `install.sh`, so Windows no longer needs a POSIX shell to
  install anything. Same options under PowerShell naming (`-NoAutoUpdate`,
  `-AutoUpdateOnly`, `-Dir`), same settings backup, and no dependency on
  Python, Node or `jq` — `ConvertFrom-Json` does the work the shell script
  farmed out.

- **`.gitattributes`, pinning `*.sh` to LF.** Git for Windows defaults to
  `core.autocrlf=true`, which rewrote every script on checkout and left the
  shebang reading `#!/usr/bin/env bash\r`. Claude Code's own marketplace clone
  is a Windows checkout like any other, so the plugins installed cleanly and
  then failed on first use with `bad interpreter: no such file or directory`.

  Existing Windows installs need one refresh to pick up the fix:

  ```
  claude plugin marketplace update claude-forge
  ```

### Changed

- `/forge:setup` now names the PowerShell installer alongside the shell one.
- [docs/SETUP.md](../../docs/SETUP.md) gained a Windows section covering both
  installers, the execution-policy workaround, the `bash` the plugins still
  need at runtime, and three new troubleshooting rows.

## [0.2.0] — 2026-09-08

### Changed

- **The bundle is now `forge`, and the marketplace is `claude-forge`.** It was
  `toolkit` inside a marketplace called `claude-toolkit`: one word doing two
  jobs at two scopes, which is why nobody could tell which was which. The
  command prefix is `/forge:`, and the install is `forge@claude-forge`.

  **Breaking.** Re-add the marketplace and reinstall:

  ```
  claude plugin marketplace remove claude-toolkit
  claude plugin marketplace add mohxmmd/claude-toolkit
  claude plugin install forge@claude-forge
  ```

  The GitHub repository is unchanged, so clone URLs still work.

### Added

- **`/forge:doctor`** — the check no component could make alone. Every tool here
  is good at writing things down and none of them reads what the others wrote,
  so a repository ends up with `CLAUDE.md`, auto-memory, `.claude/rules/`,
  `.ai/rules/`, `.project-context/` and `.craft/` all loaded, none reconciled,
  and nothing saying which wins when two disagree.

  It reports: combined always-loaded token estimate across every surface;
  references and commands named in a doc that no longer exist; the same
  assertion written into two surfaces; policies stated in more than one place;
  and **prose claiming an enforcement it does not have**, checked against the
  permission rules that actually exist.

  That last check found the bug that prompted it: `.craft/config.md` said CRAFT
  would "refuse to touch" a path, and nothing stopped an edit to it.

  It reports and never repairs. Adding a seventh surface to reconcile the other
  six would be the same mistake with better intentions.
- `scripts/doctor.sh` — read-only, under 120 lines of output, writes nothing.
- `bundles/forge/tests/run.sh` — 25 assertions, run in CI.

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
