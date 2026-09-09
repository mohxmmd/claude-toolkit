---
name: uninstall
description: Remove Claude Forge from this machine and this repository - the plugins, the marketplace, the settings they wrote, the TARS style file, and everything Charter and Craft wrote here. Use when the user runs /forge:uninstall or asks to uninstall, remove, revert or get rid of Forge, Charter, Craft or TARS.
disable-model-invocation: true
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/uninstall.sh *)
---

# Forge: uninstall

Plan:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/uninstall.sh" --plan`

---

## What this command is

The plan above is read-only. Nothing has been removed.

This is the one Forge command that changes things, and it only does so after
the user says yes to the list it just printed. That order is the whole design:
show first, remove second.

## Render this

Print the plan's own two blocks, `Machine` and `This repository`, as they are.
Do not re-format them into a table and do not summarise them into a sentence.
The user is about to approve a deletion; they get to read the actual list.

Then one line about the receipt, whichever applies:

- **Receipt found.** "Removal is exact: `.forge/manifest.tsv` records what was
  written." Nothing more.
- **No receipt.** "No receipt in this repo, so the permission rules cannot be
  told apart from yours. They are listed and left alone." Say it once. It is
  the honest limit of the fallback, not a failure.

Then ask, in one line: **Remove all of this?**

## On yes

Run:

```
"${CLAUDE_PLUGIN_ROOT}/scripts/uninstall.sh" --yes
```

Print its output. Then stop.

Two things to know about what happens:

- It removes the plugins last, on purpose. That deletes this command along with
  everything else, so the output you print is the last thing this skill ever
  says. Do not offer follow-up work that depends on Forge still existing.
- The plugins stay loaded until Claude Code restarts. Say that once, at the end.
  A user who sees `/craft` still listed and assumes the uninstall failed will
  run it again.

## On no, or anything ambiguous

Stop. Nothing is removed. If the user wants only part of it, the flags are:

| They want | Flag |
| --- | --- |
| Keep this repo's files, remove the plugins | `--keep-project` |
| Remove this repo's files, keep the plugins | `--keep-plugins` |
| Keep the TARS output style | `--keep-style` |
| Keep user settings untouched | `--keep-settings` |

Run the script with the flag they chose. Never combine flags they did not ask
for, and never fall back to a full removal because a flag combination looked
odd.

## Rules

- **Never remove anything the plan did not print.** Not the backups it leaves,
  not a stray `.craft/` in a sibling directory, not a rule that looks like
  Charter's but is not in the receipt.
- **Never edit these files by hand instead.** The script backs up every file it
  touches; an Edit call does not, and a hand-written JSON edit on a settings
  file is how a session loses its permissions.
- Only this repository is in scope. Other repos need the same command run from
  each of them; say so once, and do not go looking for them.
- Report what the script reported. If a plugin removal printed `failed`, say so
  and print the command it named. Do not retry it silently.
