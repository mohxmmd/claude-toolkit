# Contributing to CRAFT

Thank you for considering it. This document is short because the rules are few
and most of them come from one idea.

## The one idea

**Every addition is paid for on every task that loads it.**

CRAFT's advantage is not that it knows more than the model. The model already
knows a great deal about design. CRAFT's advantage is that it decides what to
read, preserves what exists, and proves what it did. A pull request that adds
knowledge the model already has makes CRAFT worse, because it costs context and
buys nothing.

So a change should answer three questions:

1. **Which observed failure does this fix?** Not an imagined one. Something you
   watched Claude get wrong on a real surface.
2. **Where does it belong?** Core doctrine, a reference, a script, config, or
   documentation. Most things belong further down that list than they first seem.
3. **What does it cost?** In tokens, and on which tasks.

## What belongs where

| Layer | Contains | Test for belonging here |
|---|---|---|
| `skills/craft/skills/craft/SKILL.md` | doctrine, taxonomy, budget, precedence, routing | needed on **every** task |
| `references/` | diagnostic detail for one topic | needed on *some* tasks, and the model gets it wrong without it |
| `router/INDEX.md` | routing that the inline matrix misses | a real request that failed to route |
| `scripts/` | anything deterministic | counting, parsing, measuring, checking |
| `templates/`, `docs/` | user-facing | a person reads it |

The core skill is capped at 1,500 body tokens and it is nearly full. Adding to it
usually means removing from it.

## Rules for references

- One level deep from `SKILL.md`. Never a reference that points at another
  reference; Claude may read a chained file only partially and answer from half
  of it.
- Over 100 lines, add a `## Contents` table of contents, for the same reason.
- Under 2,000 tokens and 260 lines. The gate enforces both.
- Diagnostic over encyclopaedic. "Squint at it and answer these five questions"
  beats a taxonomy of type scales.
- Every reference needs a **Preserve** section. If you cannot say what the
  reference should stop CRAFT from changing, it is not written for this tool.

## Rules for design opinions

CRAFT does not ship universal aesthetic bans. No rule that says never use a
particular typeface, never centre content, never use gradients, cards or shadows.
The product being improved is the source of truth, and it may already do any of
those deliberately.

An opinion can enter as:

- an **objective defect** with a measurable test (contrast, target size, overflow)
- a **project inconsistency**, which is only definable against that project
- a **configurable detector rule**, shipping `off`

Not as doctrine.

## Running the checks

```bash
node skills/craft/scripts/budget.mjs        # token budgets, frontmatter spec, links
node skills/craft/scripts/version.mjs --check
node skills/craft/scripts/measure.mjs       # smoke test against any real project
node skills/craft/scripts/inspect.mjs <file>
```

CI runs all of them. A pull request that fails the gate will not be merged, and
raising a budget to fit a change is not the fix; it is the thing the budget
exists to prevent.

## Evaluations

Behaviour changes need an evaluation case. See
[skills/craft/evals/README.md](skills/craft/evals/README.md).

Baselines come first: run the case **without** the change, record what went
wrong, then make the change and show the difference. A reference file that cannot
point at a baseline failure is documentation of an imagined problem.

Preservation cases carry half the total weight. A change that improves output on
a broken screen while making CRAFT more willing to alter a good one is a
regression, however good the diffs look.

## Releasing

Versions are managed by script so the three places that carry one cannot drift.

```bash
node skills/craft/scripts/version.mjs --bump patch     # or minor, major
# edit the new CHANGELOG.md section
git commit -am "release: v$(node skills/craft/scripts/version.mjs --current)"
git tag "v$(node skills/craft/scripts/version.mjs --current)"
```

- `patch` fixes behaviour. `minor` adds a capability or a reference. `major`
  changes how CRAFT decides things.
- `--schema` additionally bumps `craft_schema`, the format of a user's `.craft/`
  directory. That is a breaking change, belongs only in a `major`, and must ship
  with a migration documented in the changelog. `/craft:atlas doctor` is what
  users run; it reports the gap and names the fix, and never migrates their files
  behind their back.

## Reporting

Bug reports should include the `plan:` line CRAFT printed. It shows what was
routed and loaded, and that is where most wrong results begin.

## Conduct

Be straightforward and be kind. Critique the work, not the person. Maintainers
will remove comments that do not meet that bar.
