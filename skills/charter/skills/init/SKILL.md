---
name: init
description: Set up Charter in this repository. Surveys the repo, verifies its commands, asks two to four questions, then writes a working agreement into CLAUDE.md and enforced permission boundaries into settings. Use when the user runs /charter:init or asks to set up, initialise, or configure Charter.
disable-model-invocation: true
argument-hint: "[--quiet | --dry-run]"
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/survey.sh *)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/fingerprint.sh *)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/audit.sh *)
---

# Charter: initialise

Produce four artifacts for this repository, in one pass, and then stop:

1. A **working agreement** — a fenced block of at most 35 lines in `CLAUDE.md`.
2. **Boundaries** — `deny` / `ask` / `allow` rules in the project's settings file.
3. **Area rules** — path-scoped `.claude/rules/*.md` for the dangerous or convention-heavy directories.
4. **State** — `.claude/charter.json`, never loaded into a session.

Arguments: `--quiet` skips explanatory commentary. `--dry-run` shows the proposal and writes nothing.

## Standing rules for this whole task

- **Never write without showing a diff first** and getting an explicit yes.
- **Never read** `.env*`, lockfiles, `node_modules/`, `vendor/`, or any file over 800 lines without a line range.
- **Never write a command as fact until it has been executed.** An unverified command is written as `TBD` or omitted.
- **Never touch content outside the `<!-- charter:start v1 -->` / `<!-- charter:end -->` fence.**
- Cap file reads at **12**. If the repo is still unclear at that point, record what is unknown rather than inventing it.

## Step 1 — Survey

Run once:

```
${CLAUDE_PLUGIN_ROOT}/scripts/survey.sh .
```

Then run `${CLAUDE_PLUGIN_ROOT}/scripts/audit.sh .` to learn what this repo already loads into every session.

Read [references/survey.md](../../references/survey.md) for how to interpret the output and what each key drives.

**If `shape.size_class: new`** (fewer than 15 tracked files, or no commits), switch to new-project mode: skip to Step 6 and follow the New-project section of [references/survey.md](../../references/survey.md).

## Step 2 — Read, within the budget

In this order, stopping at 12 reads:

1. Every file named in `instructions.found`, in full. These are the highest-value tokens in the repo.
2. `README`, first 120 lines.
3. The primary manifest named in `stack.manifests`, in full.
4. Up to four entry points, ranged to 200 lines each.

Existing instructions are **preserved, not replaced**. Deduplicate against them: never restate in the fence something the file already says outside it.

## Step 3 — Verify the commands

For each candidate in `cmd.*` and `cmd.local_bins`, run its cheapest proving form — `--version`, `--help`, `--dry-run`, or `--list`. Record only what exits zero.

Typical mapping:

| Candidate source | Prove with |
| --- | --- |
| `cmd.local_bins: vendor/bin/phpunit` | `./vendor/bin/phpunit --version` |
| `cmd.npm_scripts: test` | `npm run test -- --help` or the underlying binary's `--version` |
| `cmd.make_targets: test` | `make -n test` |
| `quality.configs: tsconfig.json` | `npx tsc --version` |

Anything that fails or is absent is recorded as "none" — not guessed at.

## Step 4 — Ask, but only what the repo cannot answer

Use **one** `AskUserQuestion` call carrying only the questions that survive the suppression rules below. Two is typical. Four is the maximum.

| Q | Ask | Suppress when | Pre-select |
| --- | --- | --- | --- |
| 1 | Who else works in this repo? *solo / team / open source* | Never suppressed, but pre-select from `git.authors_90d` | ≥3 authors → team; 1 author → solo |
| 2 | How much git autonomy should Claude have? *propose only / local commits / full* | Never — no repo can answer this | team → local commits; solo → local commits; open source → propose only |
| 3 | Can Claude change the database on this machine? *read only / local migrations / no access* | `danger.db_tooling` and `danger.paths` both show no database surface | read only |
| 4 | Anything here Claude must never touch? *checkboxes built from `danger.paths`* | No deploy tooling, infra directories, or unusual sensitive paths found | nothing checked |

Do **not** ask about: production confirmation (always required), secrets (always denied), branch naming, commit message style (infer from `git.style_conventional`), whether to run tests, or the CI provider.

Phrase every option in plain language. The user should not need to know what a permission rule is to answer.

## Step 5 — Compile the answers into rules

Read [references/policy.md](../../references/policy.md) **before generating any rule**. It carries the preset tables and the eleven syntax gotchas that decide whether a generated rule binds or silently matches nothing. Generating rules without it produces output that looks correct and does nothing.

Settings scope follows Q1:

- **team** or **open source** → `.claude/settings.json` (committed, so teammates inherit it)
- **solo** → `.claude/settings.local.json` (personal, untracked)

## Step 6 — Propose, then write

Show the complete proposal as a diff. Group it by file. For each permission rule, show the rule and one clause saying what it stops.

```
PROPOSED CHANGES                              nothing is written until you accept

CLAUDE.md                        +N lines inside a charter fence
.claude/settings.json            +N permission rules
.claude/rules/<area>.md          new, loads only when those files are opened
.claude/charter.json             new, never loaded into a session

Accept?  [a]ll  [e]dit  [s]kip boundaries  [n]one
```

On accept, write in this order: rules files, settings, CLAUDE.md fence, then `charter.json` last so a partial run is detectable.

Build the fence from [templates/working-agreement.md](../../templates/working-agreement.md). **Hard cap: 35 lines.** Anything that does not fit moves into a path-scoped rule instead — see [templates/rules/](../../templates/rules/) for the four starters. Do not write a directory tree, a dependency list, or an architecture overview into the fence; that content is derivable, and `/doctor`'s trim pass deletes it.

Write `.claude/charter.json`:

```json
{
  "schema": 1,
  "initialized_at": "YYYY-MM-DD",
  "head": "<git.head>",
  "manifest_hash": "<from fingerprint.sh>",
  "commands": { "test": "...", "lint": "...", "typecheck": null, "build": null },
  "answers": { "collab": "team", "git": "local-commits", "db": "read-only" },
  "scope": ".claude/settings.json",
  "paths_referenced": ["..."]
}
```

Offer, do not impose, a `.gitignore` entry for `.claude/settings.local.json` and `.claude/charter.json` when the scope is local.

## Step 7 — Report

Six lines maximum. What was written, what was verified, what was left unknown, and the one next action. Then stop — do not continue into unrelated work.

## Re-running

`/charter:init` is idempotent. A second run on an unchanged repo must produce an empty diff. Content outside the fence survives byte-for-byte. If the user deleted the fence, do not re-create it without asking.
