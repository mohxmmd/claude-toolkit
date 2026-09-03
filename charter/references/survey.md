# Reading the survey

`scripts/survey.sh` returns `key: value` lines and nothing else. It never opens a file's contents beyond named manifests, never touches the network, and never writes. Secret files are reported by **name only**.

## What each key drives

| Key | Drives |
| --- | --- |
| `git.authors_90d` | Pre-selection for question 1. ≥3 → team, 1 → solo. Ignore when `git.shallow: yes` — a shallow clone cannot answer this, so ask instead. |
| `git.default_branch` | Substituted into the git preset's branch-protection rules. |
| `git.style_conventional` | `N/30`. Above 20 means the repo uses conventional commits — record it as a fact so commit messages match. Below 10, say nothing. |
| `stack.*` | Which command candidates and which database preset table apply. |
| `monorepo.*` | When present, area conventions go into per-package rules rather than the fence. A monorepo's conventions never fit in 35 lines. |
| `cmd.*`, `cmd.local_bins` | Candidates for step 3. **Candidates, not facts** — nothing here is written until it has been executed. |
| `quality.configs` | Which verification tools exist. Feeds the verification matrix. |
| `ci.*` | What "verified" means to this team. A repo whose CI runs typecheck expects typecheck. |
| `instructions.found` | Read all of these in full. Deduplicate the fence against them. |
| `instructions.charter_fence` | Not `none` → this is a re-run. Diff against the existing fence. |
| `danger.paths` | Which questions to ask, which deny rules to emit, which path-scoped rules to offer. |
| `danger.secret_files` | Names feeding the secrets deny block. Never open these. |
| `danger.db_tooling` | Selects the row of the database preset table. |
| `shape.size_class` | `new` → new-project mode. `large` → cap reads harder and prefer per-area rules. |

## The read budget

At most **12 file reads**, in this order:

1. Everything in `instructions.found`, in full.
2. `README`, first 120 lines.
3. The primary manifest, in full.
4. Up to four entry points, ranged to 200 lines.

Entry points by stack: `src/index.*`, `src/main.*`, `app/main.py`, `manage.py`, `cmd/*/main.go`, `src/main.rs`, `routes/web.php`, `app/Http/Kernel.php`, `config/routes.rb`.

**Never read:** `.env*`, lockfiles, `node_modules/`, `vendor/`, `dist/`, `build/`, `.git/`, or any file over 800 lines without a range.

If the repo is still unclear at 12 reads, stop and record what is unknown. `architecture: not determined` is a correct answer. An invented architecture is worse than a blank.

## Facts worth writing

Five to eight, maximum. A fact earns its place in the fence only if **all four** hold:

1. It is true of the whole project, not one directory. *(Otherwise it is a path-scoped rule.)*
2. It is not derivable from the code in under a minute.
3. Getting it wrong causes a real mistake, not a stylistic one.
4. It is not already stated outside the fence.

Good facts look like: an unusual workflow the team follows, a constraint that is invisible in the code, a trap that has bitten before, a convention that contradicts the framework's default.

Bad facts, all of which `/doctor` deletes on sight: directory trees, dependency lists, architecture overviews, anything restating the framework's own documentation.

## New-project mode

Triggered by `shape.size_class: new`, which the survey sets when there are **no commits at all**, or when the tree has fewer than 15 tracked files **and** no manifest of any kind. A six-file repository with a full `package.json` is a small project, not a greenfield one — do not put it into this mode.

The survey has nothing to survey, so the flow inverts from inference to declaration. Ask three questions:

1. What are you building?
2. Which stack? *(offer "not decided yet")*
3. Solo, team, or open source?

Then write a twelve-line fence with commands marked `TBD` and a note to re-run `/charter:init` after the first dependency install. Write the conservative boundary set: secrets denied, force-push denied, push asked.

Then **stop**. Do not scaffold — no directory structure, no starter files, no framework choice. Every ecosystem has a better generator than this, and a skill that creates files in an empty repo on first run is the opposite of what Charter promises.
