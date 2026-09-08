# Companions

Read before Step 4b of `/charter:init`. Governs everything Charter writes about
Craft and TARS.

Charter does not require either of them, does not install them, and does not
break when they are absent. It offers to connect what is already there, records
what the user accepted, and reports drift later. That is the whole contract.

---

## The one rule that causes bugs

**TARS has two install paths and they expose different names.**

| Install | Style name | Detected as |
| --- | --- | --- |
| Plugin (`tars@claude-forge`) | `tars:TARS` | `companion.tars: enabled` |
| File (`install.sh`) | `TARS` | `style.file_user: yes` or `style.file_project: yes` |

Write the name `companions.sh` reports in `style.name`. Never construct it
yourself. A setting naming a style that does not resolve fails **silently** —
the session simply has no output style, and nothing says why.

When `style.name` is `none`, there is nothing to offer. Do not write
`outputStyle`, and do not suggest one in the diff.

---

## Where each thing is written

| Artifact | File | Why |
| --- | --- | --- |
| `outputStyle` | `.claude/settings.local.json`, **always** | |
| Craft routing line | Inside the `CLAUDE.md` fence | |
| Both choices | `.claude/charter.json` → `companions` | |

`outputStyle` goes to the local file **even when Step 5 sends boundaries to the
committed `.claude/settings.json`**, and this is not negotiable by the
collaboration answer.

Permission boundaries are a team decision: everyone cloning the repo should
inherit the same limits. Response style is a personal one. Committing
`outputStyle` changes how Claude talks to every teammate who clones, without
asking any of them, and the first thing most of them will do is wonder what
broke. A working agreement that quietly reconfigures other people's tools is the
opposite of what Charter is for.

If the user explicitly asks for the committed file, do it and say in one line
that it applies to everyone who clones.

Writing `outputStyle` to `.claude/settings.local.json` when the scope is
**team** creates a file Step 6 would not otherwise have created. Offer the
`.gitignore` entry for it in that case too.

---

## Step 4b — the question

Ask **only** when at least one companion is connectable:

- `companion.craft: enabled`, or
- `style.name` is not `none`.

When neither holds, skip the question entirely and say nothing until Step 7.
An offer to configure software the user does not have is noise charged against
a two-minute interview.

One `AskUserQuestion`, multi-select, at most two options. This is a fifth
question and it is the only thing permitted to exceed the four-question cap,
because it is skipped in every repository where it has nothing to offer.

> **Two other tools are set up on this machine. Connect them?**
>
> - **Direct answers (TARS)** — Claude answers first in a line or two and tells
>   you when you are wrong. Personal to you, not committed.
> - **UI work routing (Craft)** — one line in the working agreement pointing
>   screen work at `/craft`, which changes the smallest thing that fixes a
>   problem instead of regenerating the screen.

Phrase both options by what they do. The user should not need to know what an
output style is to answer, and must not need to know either product's name.

Suppress an option that is already true: `style.set_local` already equal to
`style.name`, or `craft.referenced: yes`. Re-offering a setting the user already
has reads as a tool that cannot see its own output.

### When `guidance: explain`

Add one line naming what was detected and what will be written. Under `quiet`,
the diff is the explanation.

---

## What gets written on accept

**TARS.** One key, merged into `.claude/settings.local.json`, preserving
everything already there:

```json
{ "outputStyle": "<style.name verbatim>" }
```

Never rewrite the file wholesale. It commonly holds `enabledPlugins` and
personal `permissions` that are not Charter's to touch.

**Craft.** One line inside the fence, placed directly after the Project facts
block:

```
UI/screen work: `/craft` — smallest sufficient change, never a regeneration.
```

One line, roughly ten tokens, and it counts against the 35-line cap like
everything else. If the fence is at 35 lines, this line does not go in; say so
rather than silently dropping something else to make room.

Do **not** write `.craft/config.md`. That file is Craft's, `/craft:atlas`
generates it from reading the product, and a Charter-authored guess at posture
would be a second source of truth that nothing reconciles. Point at `/craft:atlas`
on the Next line instead.

---

## State

Extend `charter.json`. Absent means the question was never asked; `false` means
it was asked and declined, and a declined offer is not re-offered on re-run.

```json
"companions": {
  "style": "tars:TARS",
  "style_scope": ".claude/settings.local.json",
  "craft": true
}
```

Set `"style": null` on decline. Record `style_scope` even though it is almost
always the local file, so a hand-moved setting stays traceable.

---

## Drift, for `/charter:check`

Two checks, both cheap and both structural:

1. **`companions.style` is set but no longer resolves.** `style.name` came back
   `none`, or it disagrees with what is recorded — the usual cause is a
   plugin uninstall, or a switch between the plugin and file installs. Propose
   the corrected name, or removing the key. This is the failure that is
   otherwise invisible, and it is the reason the check exists.

2. **`craft.referenced: yes` but `companion.craft: absent`.** The agreement
   points at a command nobody has. Propose removing the line.

Neither is an error. Both are one-line repairs, proposed with a diff like
everything else.

---

## Re-running

`/charter:init` stays idempotent. A second run on an unchanged machine produces
an empty diff: recorded acceptances are already written, and recorded declines
are not re-offered.

The one thing that legitimately changes the answer is a companion that was
absent at setup and is installed now. Offer it then, once.
