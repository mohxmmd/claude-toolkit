---
name: check
description: Audit what this repository loads into every session, detect stale project knowledge, and promote durable local learnings into shared committed rules. Use when the user runs /charter:check, asks why a command in CLAUDE.md is wrong, asks what their session context costs, or asks to clean up or share project knowledge.
disable-model-invocation: true
argument-hint: "[--drift | --audit | --promote]"
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/fingerprint.sh *)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/audit.sh *)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/survey.sh *)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/companions.sh *)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/record-hash.sh *)
---

# Charter: check

Three passes. Run all three unless an argument narrows it to one.

Start with:

```
${CLAUDE_PLUGIN_ROOT}/scripts/fingerprint.sh .
${CLAUDE_PLUGIN_ROOT}/scripts/audit.sh .
```

Change nothing without showing a diff and getting a yes. This command is safe to run at any time.

---

## Pass 1 — Drift

Structural only. Three checks, all cheap, no rescan and no model reasoning about architecture.

**1. Do the recorded commands still work?** For each entry in `charter.json` → `commands`, run its cheapest proving form. A non-zero exit is the highest-signal drift indicator there is, and the most common cause of an agent quietly working around a broken instruction.

**2. Do the referenced paths still exist?** Every `dead.ref` line from the audit is a path an always-loaded file names that is no longer there.

**3. Did the manifests move?** When `manifest_changed: yes`, scope the investigation with `git diff --name-status <state.head>..HEAD` and re-read only the scripts block. Do not re-survey the whole repo.

**4. Do the recorded companions still resolve?** Skip when `charter.json` has no `companions` key. Otherwise run `${CLAUDE_PLUGIN_ROOT}/scripts/companions.sh .` and compare:

| Recorded | Now | Repair |
| --- | --- | --- |
| `companions.style` set | `style.name: none` | The style no longer exists. Propose removing `outputStyle` |
| `companions.style` set | `style.name` differs | Usually a switch between the plugin and file installs, which expose different names. Propose the corrected value |
| `companions.craft: true` | `companion.craft: absent` | The agreement points at a command nobody has. Propose removing the line |

The first two are the reason this check exists: an `outputStyle` naming a style Claude Code cannot find fails **silently**, leaving a session with no output style and nothing saying why.

For each finding, propose the smallest repair: a corrected command, a corrected path, a removed line.

---

## Pass 2 — Context audit

The audit output says what this repo costs on every single session, forever. Report it plainly and propose cuts.

| Signal | What it means | Proposal |
| --- | --- | --- |
| `total.always_loaded_est_tokens` above ~2,000 | Every session pays this before the user types anything | Show the breakdown and where it can go |
| `hint.derivable` | A directory tree or dependency list the model can re-derive for free | Cut it. `/doctor`'s trim pass deletes this content anyway |
| `hint.scopeable` | A rules file with no `paths:` key | Add a `paths:` front-matter key so it loads only in the directory it describes — this is free conditional context and the most under-used mechanism in Claude Code |
| `warn.oversize` | CLAUDE.md past ~200 lines | Adherence drops. Move the area-specific half into path-scoped rules |
| `warn.memory_index` | MEMORY.md past 200 lines | Everything past line 200 never loads. Merge or drop entries |

Also check for **contradictions**: two always-loaded files giving different guidance on the same subject. Conflicting instructions make the model pick one arbitrarily, which produces silent, intermittent, unattributable quality loss. Read the always-loaded files and name any pair that disagrees. This is the one part of the check that needs judgment rather than a script.

---

## Pass 3 — Promotion

Auto memory is **machine-local and invisible**. Six developers on one repository accumulate six private, divergent, never-reviewed sets of learnings about the same code. Nothing surfaces them and nothing shares them. This pass is the fix.

Read the memory files listed by the audit under `memory.file`. For each, classify:

| Classification | Signal | Action |
| --- | --- | --- |
| **Promote** | A durable convention about one area of the code, stable for weeks, that a teammate would need too | Offer to write it as `.claude/rules/<area>.md` with a `paths:` key, committed |
| **Promote to fence** | A behavioural rule that applies to the whole project | Offer to add it to the charter fence, if the 35-line cap allows |
| **Duplicate** | Already stated in CLAUDE.md or a rules file | Offer to delete the memory file; the shared copy wins |
| **Stale** | Names a file, command, or flag that no longer exists | Offer to delete it, and say what no longer exists |
| **Keep private** | A personal working preference, or a correction specific to this user | Leave it alone. Not everything belongs to the team |

Two rules that must not be broken:

- **Never promote silently.** Promotion moves a private note into a committed file that the user's colleagues will read. Show the exact proposed text and ask.
- **Never promote anything derivable from the code.** It will drift, and the model can re-derive it more cheaply than anyone can maintain it.

Verify before recommending: if a memory names a file, function, or flag, check it still exists. A memory records what was true when it was written.

---

## Report

```
CHARTER CHECK   <repo> · <n> findings

DRIFT
  ✗ test command `npm test` exits 1 — package.json now uses pnpm
  ✗ .claude/rules/api.md → src/handlers/ no longer exists

CONTEXT   ~<n> tokens always loaded
  ⚠ CLAUDE.md lines 40-58 are a directory tree the model can derive  (~180 tok)
  ⚠ .claude/rules/testing.md has no paths: key                       (~140 tok)

PROMOTE
  ↑ dark-mode-modal-inversion — durable, area-specific, your team needs it
    → .claude/rules/dark-mode.md  paths: public/css/**, resources/views/**
  ✗ old-build-flow — names a Makefile target that no longer exists

Apply?  [a]ll  [d]rift only  [p]romotions only  [e]dit  [n]one
```

After writing, re-sync the state file by running:

```
${CLAUDE_PLUGIN_ROOT}/scripts/record-hash.sh .
```

That is the only supported way to update `head` and `manifest_hash`. Never patch
`charter.json` with an inline `python3 -c`, `node -e`, `jq` or `sed` call: an improvised
interpreter command cannot be covered by `allowed-tools`, so it prompts the user on every
run. Then stop.

If there are no findings, say so in one line and stop. Do not manufacture work.
