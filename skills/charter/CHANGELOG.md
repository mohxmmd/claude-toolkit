# Changelog

Format follows [Keep a Changelog](https://keepachangelog.com/). Versioning is SemVer
on `.claude-plugin/plugin.json`, which is what decides whether users receive an update.

A version bump never silently changes an existing repository's boundaries. Charter
always proposes and always shows a diff.

## [Unreleased]

### Added

- `/charter:init` records what it wrote in `.forge/manifest.tsv`: the state file,
  the rules files it created, the `CLAUDE.md` fence markers, each permission rule
  it added, and any `.gitignore` line. This is what lets an uninstall remove
  Charter's rules without touching yours. A rule that was proposed and declined
  is never recorded.

### Fixed

- **Charter no longer reintroduces prompts that `auto` mode turned off.** `deny`
  and `ask` are evaluated before the model, so they fire regardless of the
  permission mode the user chose. Rules aimed at mechanics rather than
  destruction therefore land as prompts on ordinary work — `cd`, a `python`
  script, a wrapped pipeline — which is Charter obstructing the user rather than
  enhancing them.
  - The **shell re-entry block is now an offer**, not a mandatory emission.
    `sh -c`, `bash -c`, `zsh -c` and `eval` are proposed in Step 6 on their own
    accept line, with their cost stated. `env`, `watch`, `setsid` and `flock`
    are never emitted at any tier: they prefix ordinary commands and the prompt
    buys nothing.
  - `scripts/lint-rules.sh` no longer **requires** the block, and now **fails the
    write** on any deny/ask rule whose first token is navigation or inspection
    (`cd ls cat grep find env …`) and on any bare interpreter or runner rule
    (`Bash(python *)`, `Bash(npm *)`). Named destructive commands
    (`Bash(python manage.py flush*)`) are unaffected.
  - Question 4's off-limits paths compile to `Read()` / `Edit()` denies, never to
    a `cd` or `ls` command rule.
- **`git config` moved from `deny` to `ask`** in the Propose-only and
  Local-commits presets. A deny cannot carry exceptions, so it also blocked the
  read-only `git config --get`.

## [0.2.0] — 2026-09-08

### Added

- **Tier 0: the sandbox.** Permission rules match command text; the OS-enforced
  sandbox covers what a text matcher cannot, including a child process and a
  shell that re-enters through `sh -c`. `/charter:init` offers it as a separate
  accept, never bundled with the boundaries. `references/policy.md` carries the
  keys Charter may write and the three it must never: `sandbox.filesystem`
  (once set, only managed settings can change it), `network.strictAllowlist`
  (no effect from project settings), and an unrequested
  `allowUnsandboxedCommands: false` (removes the user's escape hatch).
- **The shell re-entry ask block**, emitted in every repository.
  `sh -c 'git push origin main'` is one command with a quoted argument and
  matched no rule Charter wrote. `sh -c`, `bash -c`, `zsh -c`, `eval`, `env`,
  `watch`, `setsid` and `flock` now ask.
- **`scripts/lint-rules.sh`** — the self-check is a script, not a checklist read
  by eye. A non-zero exit stops the write, and Step 7 reports the count.
- **Six more matcher gotchas**, eleven to seventeen: `sh -c` re-entry;
  field-scoped rules (`Bash(command:rm *)`) accepted, ignored and warned about;
  unparseable compounds not splitting for allow rules; deny and ask matching
  past any leading assignment where allow does not; `xargs` stripped only
  without flags; `*` matching at any position, including before the program.
- **`danger.destructive_cmds`** in the survey. The DB preset covers the
  framework's verbs; it never covered the command this team wrote. npm scripts,
  composer scripts, make targets, just recipes, `bin/*`, artisan signatures and
  rake tasks are matched for a destructive verb, so a bespoke `cms:restore` that
  truncates rows is found by reading `app/Console/Commands`, not by luck.
- **Invocation variants.** The matcher is literal-prefix, so
  `Bash(vendor/bin/pint --dirty*)` did not match `./vendor/bin/pint --dirty` and
  the user was prompted for a command Charter had just called allowed. Generated
  rules now expand into the forms that actually resolve.
- **Step 6a, the oversize gate.** `audit.sh` warned that `CLAUDE.md` was past
  the adherence cliff and `/charter:init` then appended 35 lines to it. It now
  proposes cuts first, from `audit.sh`'s own findings. "Add anyway" is accepted
  without argument; adding silently is not.

### Changed

- **"cannot be argued around" is gone from `references/policy.md`.** A
  permission rule is evaluated before the model is consulted, which is true and
  worth saying. It is not containment, and describing it as containment is the
  same overclaim Charter tells other tools not to make. The tier table now has
  four rows and names what enforces each.
- Step 7 reports verification in two parts: what `lint-rules.sh` asserted about
  the rules Charter wrote, and `claude doctor` as the user's own next check.
  Charter no longer implies it ran a check it did not run.
- Charter installs as `charter@claude-forge`.

### Fixed

- The repo size gate counted reference files, which load on demand, against a
  budget meant for per-session cost. It now also caps the frontmatter
  descriptions, which are what actually load every session.

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
