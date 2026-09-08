# How CRAFT works

## Contents

- The layers
- The router
- Precedence
- The six modes
- The preservation ledger
- The change budget
- Verification
- What gets remembered
- Token economy

## The layers

```
CORE      shipped with the plugin, versioned, never edited by you
PROJECT   .craft/          one human file plus generated knowledge
PROFILE   ~/.craft/        your preferences, outside every repository
EVIDENCE  ~/.craft/evidence/   cached external research, on demand only
```

Updating CRAFT replaces the core and touches nothing else. A project teaches
CRAFT by editing its own `config.md`. You express personal taste by editing
`~/.craft/`. Neither ever requires editing the skill.

## The router

Before loading anything, CRAFT resolves the request into a plan and states it in
one line:

```
plan: refine · modal · hierarchy+visual · risk med · budget evolutionary
      load: surfaces/modal, foundations/hierarchy
      verify: visual + a11y + interaction · research: none
```

That line is the most useful thing to look at when CRAFT does something
unexpected. It shows what it thought you asked for and what it read. Almost every
wrong result is a wrong plan, and a wrong plan is easy to correct: say so, and it
reroutes.

The common cases are covered by a matrix inside the skill itself, so routing
usually costs nothing. Anything it does not cover falls through to
`router/INDEX.md`, which is read only on a miss.

## Precedence

When two sources of truth disagree, this order settles it:

```
1  your explicit request
2  what the product does elsewhere
3  what this surface's neighbours do
4  .craft/config.md
5  ~/.craft preferences
6  CRAFT's own principles
7  external research
8  the model's defaults
```

When live code and `config.md` disagree, code wins on **values** and config wins
on **intent**. If config says the radius is 8px and the components use 6px, CRAFT
uses 6px and reports the drift, but it still treats radius as a single system
token rather than concluding that per-component radii are the convention. Without
that split, a tool learns a codebase's accidents as if they were decisions.

Above all of it sits a floor that only an explicit instruction can lower, and
CRAFT names it in the report when you do: recorded compliance rules, WCAG 2.2 AA,
and no change to behaviour, permissions, data semantics or business rules.

## The six modes

| Mode | Chosen when | Finished when |
|---|---|---|
| Preserve | nothing is wrong, or the fix is out of budget | only defects touched, or nothing changed and you were told why |
| Correct | something is objectively broken | the defect is gone and nothing else moved |
| Refine | the structure is right, the execution is weak | hierarchy and spacing improved, structure identical |
| Modernize | the structure is sound, the visual language is dated | visual change within budget, navigation and brand untouched |
| Redesign | the structure is itself the problem | a new structure, with the old one named as the defect |
| Explore | high impact and genuinely unclear | two or three labelled options, one recommended |

Ties resolve downward. "Make this better" is Refine, not Redesign. Escalating
requires naming the structural property that causes the user problem, in writing.

## The preservation ledger

Written before any code changes:

```
preserve   what is working and stays
improve    what is changing, each with the user problem it solves
uncertain  what was considered and left alone, with the reason
forbidden  what may not be touched, from config and from your request
```

`preserve` is never empty. If nothing on a surface is worth keeping, that is a
new product, and it gets said out loud rather than done quietly. `forbidden` is
absolute: violating it is a failed task, not a trade-off. It binds CRAFT, not the
client; the enforced form is an `Edit()` deny rule, which atlas prints for you.

## The change budget

Six axes, tracked independently, measured before and after.

Brand sits at zero on both default postures. Fonts, brand colours, logo
treatment, navigation identity and product terminology are the things users
recognise a product by, so they never move without being asked for.

If a fix truly needs more budget than it has, CRAFT stops and tells you which
axis and why. It does not quietly exceed the budget, and it does not quietly trim
the fix into something that no longer solves the problem.

## Verification

Scaled to risk, not applied uniformly:

| Change | What runs |
|---|---|
| a spacing or token tweak | deterministic checks |
| a component | checks and screenshots |
| a modal, form or navigation | plus keyboard walk and state exercise |
| a redesign | plus console and a regression check against the before state |

Bounded to two inspection rounds: build, one batched look across every viewport,
one batch of fixes, at most one confirming look, stop. Open-ended self-review
converges on fiddling.

If no dev server is reachable, CRAFT does what it can statically and reports
**"implemented, not visually verified"**, naming what it could not check.

## What gets remembered

| Kind | Where | Lives |
|---|---|---|
| your configuration and product knowledge | `.craft/config.md` | until you edit it |
| measured design system | `.craft/atlas/` | until the code changes |
| durable decisions and their reasons | `.craft/decisions.md` | pruned at 200 entries |
| hashes, dials, routing cache | `.craft/state.json` | invalidated automatically |
| screenshots and scratch output | `.craft/cache/` | the session |

Only decisions that are durable and non-obvious are recorded, so the next session
does not re-litigate a question you already settled. It is not a log of edits.

## Token economy

| | budget |
|---|---|
| the core skill | 1,500 tokens |
| boot context | 500 |
| one reference | 1,200 typical, 2,000 hard |
| a normal task | about 4,000 |
| a complex redesign | under 8,000 |

Bought by routing, by compiling `config.md` into a small projection rather than
reading the file every time, by loading the craft floor only on turns that edit,
and by scripts that return summaries instead of dumps. `node skills/craft/scripts/budget.mjs`
enforces it, and CI fails the build on a breach.
