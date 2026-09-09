# Changelog

All notable changes to CRAFT are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Two version numbers matter:

- **Plugin version** (`plugin.json`). What you install and update. Semantic
  versioning. `major` means a change to how CRAFT decides things; `minor` adds a
  capability or a reference; `patch` fixes behaviour.
- **`craft_schema`**. The format of a project's `.craft/` directory. It changes
  rarely and only in a `major` release, and every change ships with a migration
  documented here. `/craft:atlas doctor` reports the gap and names the fix. CRAFT
  never migrates your files as a side effect of a design task.

## [Unreleased]

### Added

- `/craft:atlas` records what it wrote in `.forge/manifest.tsv`, so an uninstall
  removes `.craft/` and the `.gitignore` line it added, and nothing else.

## [0.2.0] - 2026-09-08

`craft_schema` is unchanged at 1. No migration is needed; `.craft/config.md` is
read the same way. What changed is what the measurement pass reports, and three
of those numbers were previously wrong in ways that looked authoritative.

### Fixed

- **`css` was read from the manifest, not from the code.** A `tailwindcss`
  dependency reported `css: "tailwind"` for a Bootstrap product where Tailwind
  was nine lines across two of ninety-eight views. Detection is now
  usage-weighted, and the schema gained `stack.css_systems` and
  `stack.css_split` so "two systems, split by area" is expressible. A dependency
  that is installed and unused is reported as
  `source: "manifest only, no usage observed"`.
- **`dark_mode` substring-matched the word `dark`.** `--hlp-navy-dark: #1a2b4c`
  contains the literal `dark:`, so a codebase with zero `prefers-color-scheme`
  rules reported 1773. Every entry in `signals` is now
  `{value, files, matched[]}` and matches named mechanisms only. An empty
  `matched` makes a zero legible rather than merely absent.
- **Every token count was inflated several-fold by build output.** A
  content-hashed `bundle-core.88f4182ca0.css` was weighted the same as a
  hand-written stylesheet. Generated files are now excluded by content-hashed
  filename, `.min.`, and the repo's own `.gitignore` via `git check-ignore`.
- **Committed vendored copies had no filename signal.** A stylesheet holding
  more than 70% of another's declarations is now detected as derived and
  dropped, which catches the `theme/api/css/stylesheet.css` case.
- **Counts were occurrences, so one large file dominated.** Every value now
  carries `files` and `file_share` alongside `evidence`, and ranking and
  confidence are computed on files. `#77a507` at 750 hits in one file no longer
  outranks a value used once in forty.
- **The dials were computed from the polluted corpus and written as facts.**
  They are now computed after every exclusion and carry `confidence` and
  `write_to_config`. Atlas writes them commented out when confidence is low.

### Added

- **`components`**, the inventory that was previously `null`. Ranked by file
  count across SCSS mixins and placeholders, Blade components and partials,
  Livewire, and JSX/Vue elements. Capitalised HTML and SVG tags are excluded.
- `excluded` in the measurement output: what was dropped as vendored, generated,
  gitignored or derived, with example paths. Atlas reports these.
- [`references/measure.md`](skills/craft/references/measure.md) — what each
  measured field means and which may be believed.
- `skills/craft/tests/run.sh` — 18 assertions, one per failure above, run in CI.

### Changed

- **`## Do not change` is no longer described as a hard gate.** It was called
  one in five places while nothing enforced it, which is the tier-3-as-tier-1
  violation Charter's own policy forbids. It is a convention CRAFT honours.
  Atlas step 5b now prints the `Edit()` deny rule that makes it enforced and
  offers to hand it to Charter.
- The repository is now **claude-toolkit** and the marketplace is
  **claude-forge**. CRAFT installs as `craft@claude-forge`. Nothing inside the
  plugin moved, so `.craft/` and `craft_schema` are unaffected.

### Fixed

- `craft/.claude-plugin/plugin.json` carried `$schema` and `displayName`, which
  `claude plugin validate` rejects as unrecognised keys. Both removed; the
  manifest now validates. CI validates every plugin rather than only CHARTER's.

## [0.1.0] - 2026-09-03

First release. `craft_schema` 1.

### Added

- **`/craft`**, the core skill. Router, six-mode decision taxonomy, preservation
  ledger, six-axis change budget, precedence model, verification policy and the
  Improvement Summary format. 1,497 body tokens against a 1,500 budget.
- **`/craft:atlas`**, project understanding. Detects the stack, measures the
  design system with evidence counts and confidence, reuses existing design
  documentation instead of re-asking, and writes `.craft/config.md`. Also runs as
  `doctor` to report drift without repairing it.
- **`.craft/config.md`**, one human configuration file. YAML frontmatter for
  settings, markdown for the product knowledge only a human has. Compiled into a
  compact projection at boot so the file can grow without the per-task context
  cost growing with it.
- **Zero-config first run.** No initialisation step is required. CRAFT works on
  codebase evidence and writes a config as a side effect.
- **Scripts**: `context.mjs` (boot and directives), `measure.mjs` (token and dial
  extraction), `inspect.mjs` (surface and convention summary), `budget.mjs`
  (token and Agent Skills spec gate), `version.mjs` (release consistency).
- **Eight references** across foundations, surfaces, decisions and quality,
  loaded one at a time by the router.
- **CI gate** enforcing token budgets, frontmatter spec conformance,
  one-level-deep reference links, table-of-contents rules and version agreement.

### Known limitations

- Verification is static and screenshot-level. Browser-driven interaction
  verification arrives in 0.2.0.
- No deterministic detector yet; the craft floor is enforced by the agent rather
  than by a script.
- Surface memory and the decision ledger are specified but not yet written by
  any command.
- Dials are measured with file-share proxies for motion and ornament, which
  under-report a design system concentrated in a few stylesheets.

[Unreleased]: https://github.com/mohxmmd/claude-toolkit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mohxmmd/claude-toolkit/releases/tag/v0.1.0
