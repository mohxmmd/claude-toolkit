# Changelog

Format follows [Keep a Changelog](https://keepachangelog.com/). Versioning is SemVer
on `.claude-plugin/plugin.json`, which is what decides whether users receive an update.

A version bump never silently changes an existing repository's boundaries. Charter
always proposes and always shows a diff.

## [Unreleased]

### Added
- Companion detection. `/charter:init` offers to connect Craft and TARS **when
  they are already installed**, and says nothing in a repository where neither
  is. Charter never installs anything and declares no dependency on either, so a
  vendored copy still works alone.
- `scripts/companions.sh` — read-only detection of what is installed, enabled,
  and already wired.
- `references/companions.md` — the write rules, including the one that actually
  breaks: TARS is `tars:TARS` as a plugin and `TARS` as a file, and a setting
  naming a style that does not resolve fails silently.
- `companions` user config: `ask` (default) | `both` | `tars` | `craft` | `off`.
- `charter.json` gains a `companions` key. A decline is recorded and not
  re-offered.
- `/charter:check` gains two drift checks: a recorded output style that no
  longer resolves, and a `/craft` reference in the fence with Craft uninstalled.

### Notes
- `outputStyle` is always written to `.claude/settings.local.json`, including
  when boundaries go to the committed file. Permission limits are a team
  decision; response style is a personal one, and committing it reconfigures
  every teammate who clones without asking any of them.
- The companion question is the only one permitted past the four-question cap,
  and it earns that by being absent wherever it has nothing to offer.

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
