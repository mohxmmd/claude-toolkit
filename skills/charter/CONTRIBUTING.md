# Contributing to CHARTER

Charter is a configurator. It does not know more than the model — it decides
what gets written down, where, and what binds. So its claims are all numbers,
and a change has to move a number or fix a failure somebody actually watched.

## The one rule

**A generated permission rule either binds or it does not.** Everything else in
Charter is a preference; that part is correctness. A rule that looks right and
matches nothing is worse than no rule, because it converts caution into false
confidence.

So any change to `references/policy.md` or to how rules are generated needs a
case in the corpus, not an argument.

## Three questions a change should answer

1. **Which observed failure does this fix?** Not an imagined one. Something you
   watched Charter get wrong on a real repository. Paste the survey output and
   the generated artifact.
2. **What does it cost?** In resident tokens if it touches the working-agreement
   template, in one-time tokens if it touches init, in nothing if it lives in a
   reference or a script.
3. **Could Claude Code already do this?** `/init`, `/doctor`, auto memory,
   `.claude/rules/`, plan mode and `permissions` cover a lot. Charter's job is to
   configure them correctly, not to replace them. A PR that reimplements a native
   mechanism will be declined even if it works.

## The gates

`./tests/make-fixtures.sh && ./tests/run.sh` must pass. CI runs it. It enforces:

| Gate | Limit | Why |
| --- | --- | --- |
| Resident context | ~600 tokens | Paid on every session, forever. This is the product's main claim |
| Repository size | 2,500 lines | Small enough for one maintainer to keep true |
| `SKILL.md` body | 2,000 words each | Past this, move detail into `references/` |
| Survey output | 80 lines | It enters the context window; the script's own work does not |
| Audit output | 60 lines | Same |
| Working agreement | 35 lines | Adherence drops on long instruction files |
| No leaked contents | asserted | The survey must never emit a file's contents |

A change that raises a limit needs to say why the limit was wrong, not why the
feature is good.

## What belongs where

| Layer | Contains | Test for belonging here |
| --- | --- | --- |
| `templates/working-agreement.md` | the always-loaded fence | needed on **every** session, in **every** repo |
| `skills/*/SKILL.md` | the procedure for one command | the model runs it start to finish |
| `references/` | detail one command needs | needed on *some* runs, and the output is wrong without it |
| `scripts/` | anything deterministic | counting, parsing, hashing, listing — it runs outside the context window, so its work is free |
| `templates/rules/` | starter path-scoped rules | a convention that is true of one directory |
| `docs/` | user-facing | a person reads it |

Content moves **down** that table far more often than up. If something can be a
script, it should be.

## Adding a permission-rule case

The seventeen gotchas in [`references/policy.md`](references/policy.md) each
exist because a plausible-looking rule silently fails. To add an eighteenth:

1. Name the behaviour, with the documentation or the observed transcript that
   shows it.
2. Add the gotcha to `references/policy.md` with the wrong form and the right one.
3. Add a check to [`scripts/lint-rules.sh`](scripts/lint-rules.sh). The self-check
   is a script, not a list read by eye, and a non-zero exit stops the write.
4. Add two assertions to `tests/run.sh`: one that the bad form is caught, and
   **one that a legitimate similar form is not**. Every check here has a
   near-miss that must pass — `Bash(php artisan migrate*)` is correct and
   `Bash(ls*)` is not, and the first version of the gotcha-3 check failed that.
5. If it needs a model to check, add a fixture that exercises it and record the
   dry-run output in the PR.

## Changing the presets

Git, database and deployment presets change what a user's agent may do. Two
standing constraints, and a PR that relaxes either needs a strong argument:

- **Force-push stays denied in every preset**, including the permissive one.
- **Destructive database resets stay denied in every preset.**

The rest is negotiable with evidence.

## Scripts

POSIX shell. `jq` may be used when present but never required — every path needs
a `grep`/`sed` fallback. No network. No writes. macOS, Linux, WSL and Git Bash all
have to work, so no GNU-only flags without a guard.

`bash -n` every script before pushing; CI does it too.

## Documentation

`docs/SAFETY.md` carries a limitations section. It is not optional and it must
not shrink. A safety tool that overstates its coverage is worse than no tool,
because someone will rely on it. If a change narrows what Charter protects,
that section grows in the same commit.

## Versioning

SemVer on `.claude-plugin/plugin.json`. `major` for a change to the fence schema
or to what a generated rule means; `minor` for a new command, preset or template;
`patch` for behaviour fixes.

A version bump never silently changes an existing repository's boundaries.
Charter always proposes and always shows a diff — on every version, without
exception.
