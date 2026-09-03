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

[Unreleased]: https://github.com/mohxmmd/skills/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mohxmmd/skills/releases/tag/v0.1.0
