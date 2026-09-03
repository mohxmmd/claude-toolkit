# Changelog

Format follows [Keep a Changelog](https://keepachangelog.com/). Versioning is SemVer
on `.claude-plugin/plugin.json`, which is what decides whether users receive an update.

A version bump never silently changes an existing repository's boundaries. Charter
always proposes and always shows a diff.

## [0.1.0] — unreleased

Initial release.

### Added
- `/charter:init` — survey, verify commands, ask 2-4 questions, propose, write.
- `/charter:status` — what is set up, what it costs per session, one next action.
- `/charter:check` — three passes: drift, context audit, promotion.
- `scripts/survey.sh` — deterministic repo facts outside the context window.
- `scripts/audit.sh` — always-loaded token accounting, dead references, memory listing.
- `scripts/fingerprint.sh` — HEAD SHA plus manifest hash staleness signal.
- Git, database, deployment and secrets presets with the eleven permission-syntax
  gotchas encoded (`references/policy.md`).
- Four path-scoped rule templates.
- Fence schema `v1`.
