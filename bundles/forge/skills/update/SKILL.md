---
name: update
description: Check for new versions of Forge, Charter, Craft and TARS, show what changed, and install them. Also turns the weekly background check on or off. Use when the user runs /forge:update or asks whether these plugins are current, how to update them, or to keep them updated automatically.
disable-model-invocation: true
argument-hint: "[--check | --weekly | --no-weekly]"
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/update.sh *)
---

# Forge: update

Versions:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/update.sh" --check`

---

## What this command is

The block above already refreshed the marketplace and compared what is
installed against what is available. It changed nothing else.

## Render this

Print the version table as it is, one line per plugin. Do not summarise it into
a sentence: which component is behind is the whole point.

Then one line, whichever applies:

- **Everything current.** "All current." Stop there. Do not offer to update
  something that is already the latest version.
- **Something is behind.** Name what would change, then ask: **Update now?**

## On yes

```
"${CLAUDE_PLUGIN_ROOT}/scripts/update.sh" --yes
```

Print its output, then say once: the new versions load at the next session
start, not in this one. A user who sees the old behaviour and assumes the
update failed will run it again.

## Arguments

| Typed | Do this |
| --- | --- |
| `--check` | Nothing more. The block above is the answer. |
| `--weekly` | Run the script with `--weekly` (see below first) |
| `--no-weekly` | Run the script with `--no-weekly` |
| nothing | The flow above |

## About --weekly, and when to talk the user out of it

Claude Code's own plugin auto-update runs at **every session start**, which is
more often than weekly and needs no hook. If the user wants to stay current,
that is the better mechanism:

```
./setup.sh --auto-update-only
```

So when someone asks for automatic updates, say that first, in one line. The
weekly check is for the narrower case: auto-update deliberately off, but not
wanting to fall six versions behind unnoticed.

If auto-update is already on, the script says so and asks before installing a
second mechanism over the top of it. Do not talk it past that prompt.

What `--weekly` installs, so you can answer accurately:

- `~/.claude/forge/weekly-update.sh`, a small script nothing else calls
- a `SessionStart` hook in `settings.json`, marked `async` so it never delays a
  session

Six days out of seven the script exits in milliseconds. On the seventh it
updates in the background and appends the result to `~/.claude/forge/update.log`.
Because it runs in the background, the update usually lands for the session
after next. `--no-weekly` removes both, and so does `/forge:uninstall`.

## Rules

- **Never edit settings by hand to do any of this.** The script backs up the
  settings file before every change; an Edit call does not.
- Report what the script reported. A `failed` line names the command to retry;
  print it and do not retry silently.
- Do not run `/charter:init`, `/craft:atlas` or any other component from here.
  Updating a plugin and configuring a repository are different jobs.
