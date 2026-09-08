---
name: doctor
description: Check every AI context surface in this repository against the others. Reports what loads into every session, references that no longer exist, the same rule written in two places, policies stated twice, and prose claiming an enforcement it does not have. Use when the user runs /forge:doctor or asks why Claude ignores an instruction, which file wins, whether CLAUDE.md is too long, or what is stale across their AI docs.
disable-model-invocation: true
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh *)
---

# Forge: doctor

Findings:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh" .`

---

## What this command is

Every tool in Forge is good at writing things down. None of them reads what the
others wrote. A repository ends up with `CLAUDE.md`, auto-memory, `.claude/rules/`,
`.ai/rules/`, `.project-context/`, `.craft/` and a house skill, all loaded, none
reconciled, and nothing saying which one wins when two disagree.

This command reads all of them and reports. **It writes nothing and repairs
nothing.** Adding a seventh surface that reconciles the other six would be the
same mistake with better intentions.

Do not run `/charter:init`, `/craft:atlas`, or any other component from here.
They write files and ask questions; they run when a person types them.

## Render this

```
FORGE DOCTOR   <repo>

Always loaded   <N> surfaces · ~<N> tokens every session
  <path>  <lines>L  ~<N>tok
  ...

Dead references <N>            or: none
  <file> -> <path that no longer exists>

Said twice      <N>            or: none
  <file A> == <file B> :: <the assertion>

Enforcement claims <N>         or: none
  <file>:<line> :: <the claim>   -> covered / NOT covered

Precedence      stated in <file>     or: nowhere — nothing says which surface wins
```

Omit any section with nothing in it. A doctor that prints five green rows is a
doctor nobody reads twice.

## Reading the output

**`warn.budget` / `warn.surfaces`.** Report the total and the count together.
The number that matters is not any one file's length, it is what loads every
session across all of them. Say it plainly and do not prescribe: a repo with a
good reason for four surfaces is not broken.

**`dead.ref` and `dead.cmd`.** The highest-yield finding here and the cheapest
to fix. A doc naming a deleted file is worse than one naming nothing, because it
is followed. List every one. Offer to fix them; do not fix them unasked.

**`dup.assertion`.** Not automatically wrong. Two surfaces stating the same rule
is how contradictions start, and it is paid for twice every session. Report it,
name both files, and let the user decide which copy to delete.

**`contradiction.check`.** This only says a topic is covered in more than one
place, not that the statements disagree. **Read both surfaces before reporting a
contradiction**, and quote the two lines if they genuinely conflict. Reporting a
conflict that is not one is worse than missing one.

**`tier.claim` — the check that matters most.** Prose claiming an enforcement it
does not have. `refuse`, `hard gate`, `is blocked`, `cannot be changed`. For each
claim, read the line, find the path or command it names, and check whether
`permissions.rule_count` covers it:

| Situation | Report as |
|---|---|
| `permissions.rule_count: 0` | Every claim is a convention. Say so once, for all of them. |
| Rules exist and one covers the named path | Covered. Say nothing. |
| Rules exist and none covers the named path | **A tier violation.** Name it. |

The vocabulary is Charter's, and it is worth restating in the report because the
whole point is that these words mean different things:

- **sandbox** — the OS enforces it
- **boundary** — a `permissions` rule; the client enforces it before the model
- **guard** — a `PreToolUse` hook
- **convention** — a line in a file; nothing enforces it

For an uncovered claim, print the rule that would make it true, and stop:

```
.craft/config.md:2 claims CRAFT will "refuse to touch" public/theme/css/bundle-core.css.
Nothing enforces that. The enforced form is:

  "permissions": { "deny": ["Edit(public/theme/css/bundle-core.css)"] }

Install it with /charter:init, or paste it into .claude/settings.json.
```

Use `Edit(...)`, never `Write(...)` — Claude Code accepts a `Write` path rule and
never consults it.

**`precedence.stated_in: nowhere`.** With two or more always-loaded surfaces,
this is a real gap: when two disagree, nothing decides. Suggest one line in the
highest-level surface naming the order. Suggest it once.

## Rules

- **Report, never repair.** Not even the trivial fixes, not even when asked to
  "just tidy it up" mid-report. Offer, then wait.
- **Never invent a finding the script did not produce.** If a section is empty,
  it is empty. A doctor that pads is a doctor that gets ignored.
- **Verify before escalating.** `contradiction.check` and `tier.claim` are both
  heuristics that point at a line. Read the line before calling it a problem.
- Cap file reads at **8**. Beyond that, report what is unresolved rather than
  reading further.
- Findings first, at most three lines of interpretation after. No summary
  paragraph, no offer to redesign the documentation.
