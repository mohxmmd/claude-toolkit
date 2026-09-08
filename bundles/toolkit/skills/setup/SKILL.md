---
name: setup
description: Set up the whole toolkit in this repository in one pass — run Charter's interview, wire TARS as the output style, and point UI work at Craft. Use when the user runs /toolkit:setup or asks to set up, initialise, or configure the Claude Toolkit.
disable-model-invocation: true
argument-hint: "[--dry-run]"
---

# Toolkit: set up

One pass, one repository. This command does not replace `/charter:init` — it
runs it and reports what the other two components ended up doing.

`--dry-run` proposes everything and writes nothing.

## What is already true when this runs

Charter, Craft and TARS are declared as **dependencies** of this bundle, and
Claude Code disables a plugin whose dependencies are not enabled. So if you are
reading this, all three are installed and enabled. Do not check, and do not
offer to install anything.

The one exception is a `--plugin-dir` load straight from a checkout, where
dependencies cannot resolve. In that situation this command does not load at
all, so it cannot be the thing reporting the problem.

## Step 1 — Run Charter

Invoke `/charter:init`, passing `--dry-run` through if it was given.

Charter owns the interview, the diff, and **every write**. Its companion step
will detect that Craft and TARS are enabled and offer to wire them.

Do not answer on the user's behalf. Do not pre-empt the question by writing
settings here. Do not write any file yourself. Everything this bundle promises
is delivered by Charter's own writes, which is what keeps one component
responsible for one set of artifacts.

## Step 2 — Report

Six lines maximum, and only what is true after Charter finished. Read the values
back from what Charter reported; do not re-derive them.

```
TOOLKIT   <repo name>

✓/✗ Charter    <n> boundaries in <scope> · <fence line count>-line agreement
✓/✗ TARS       outputStyle: <value> in <file>   (or: declined)
✓/✗ Craft      routing line in the agreement    (or: declined)

Next: <single action, or "nothing — you're set">
```

If this run set `outputStyle`, the Next line must be `/clear — output styles
load at session start`. The session the user is sitting in will otherwise look
like nothing happened, and that reads as a broken install.

Then stop. Do not continue into unrelated work.
