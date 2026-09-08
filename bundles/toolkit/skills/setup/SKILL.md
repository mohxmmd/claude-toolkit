---
name: setup
description: Show what the Claude Toolkit has set up in this repository and the exact next command to type. Use when the user runs /toolkit:setup or asks how to get started with the toolkit, what is configured here, or what to do next.
disable-model-invocation: true
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/state.sh *)
---

# Toolkit: set up

State:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" .`

---

## What this command is

An orientation. It reads the state above and tells the user the one command to
type next.

**It writes nothing, and it cannot run the other components' commands.**
`/charter:init`, `/craft:atlas` and `/craft` are all marked
`disable-model-invocation`, which means they run only when a person types them.
That is deliberate on their part: each one writes files and asks questions, and
a command that writes files should not fire because a model inferred it might be
wanted.

So do not attempt to invoke them, do not use the Skill tool to reach them, and
above all **do not reimplement what they do.** Writing a working agreement or a
permission rule here would produce artifacts Charter did not author and cannot
later diff, check, or update.

## Render this, from the values above

```
TOOLKIT   <repo>

✓/✗ Charter    <fence> · boundaries: <yes/no>      or: not run
✓/✗ Craft      .craft/config.md                    or: not run
✓/✗ TARS       <tars.style> in <tars.set_in>       or: not set

⚠ Updates      off — you will stay on this version   (omit when on)

Next: <one command>
```

Marking rules:

- Charter is `✓` only when `charter.state: yes` **and** `charter.boundaries: yes`.
  A fence with no deny rules is context without enforcement, which is the exact
  gap Charter exists to close — mark it `⚠` and say "no enforced boundaries".
- TARS is `✓` when `tars.style` is anything but `none`. Both `TARS` and
  `tars:TARS` are valid; they are the file and plugin installs respectively.
- The Updates line appears **only when auto-update is off** — that is,
  `autoupdate.marketplace: no`, or `autoupdate.forced: no` on a machine where
  Claude Code's own auto-updater is disabled (native and VS Code installs). When
  it is on, say nothing; a permanent row confirming a thing works is a row
  nobody reads twice.

## The next command

Exactly one line, the first row that applies:

| State | Next |
| --- | --- |
| `charter.state: no` | `/charter:init` — two to five questions, about a minute |
| `charter.boundaries: no` | `/charter:init` — this repo has no enforced boundaries |
| `craft.config: no` | `/craft:atlas` — reads the product, writes `.craft/config.md` |
| `tars.style: none` | `/config` → Output style → `tars:TARS` → then `/clear` |
| `autoupdate.marketplace: no` | `./setup.sh --auto-update-only` from a checkout — these tools change often |
| Everything set | `nothing — you're set. /charter:status any time` |

Charter comes before Craft. Charter's own setup offers to wire TARS and add the
`/craft` routing line, so running it first means the other two need less.

Auto-update comes last, because it is about future sessions rather than this
one. Mention it once and do not argue for it: it means running new versions
without reviewing them, which is a real trade the user gets to make. Never
offer to enable it yourself — it lives in the user's own settings file, and a
plugin quietly granting itself update rights is the exact thing that boundary
exists to prevent.

Print the block, print the next line, and stop. No commentary, no summary
paragraph, no offer to do the work yourself.
