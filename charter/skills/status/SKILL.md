---
name: status
description: Show what Charter has set up in this repository, what it costs per session, and the one next action. Use when the user runs /charter:status or asks what Charter has done, what the session context costs, or whether this repo is set up.
disable-model-invocation: true
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/fingerprint.sh *)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/audit.sh *)
---

# Charter: status

Fingerprint:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/fingerprint.sh" .`

Context audit:

!`"${CLAUDE_PLUGIN_ROOT}/scripts/audit.sh" .`

---

Render exactly the block below from the two outputs above. Every line must trace to a value in them — infer nothing, score nothing, and do not read any other file.

```
CHARTER   <repo name> · <branch> · <initialised DATE | not initialised>

✓/✗ Context      <fence line count> lines · <n> path-scoped rules
✓/✗ Commands     <verified list> · <missing list>
✓/✗ Boundaries   <n> rules in <scope> · git: <preset> · db: <preset>
✓/✗ Session cost ~<total.always_loaded_est_tokens> tokens always loaded

⚠ <finding>                        (omit this block when there are none)

Next: <single concrete action>
```

## Marking rules

- `✓` when the thing exists and looks current. `✗` when absent. `⚠` when present but flagged.
- **Boundaries is `✗` when `permissions.has_deny` is `no`**, regardless of how many allow rules exist. Allow rules constrain nothing.
- Findings, worth surfacing, in this order:
  - `manifest_changed: yes` — dependencies or scripts moved since setup.
  - Any `dead.ref` — an always-loaded file names a path that no longer exists.
  - `warn.oversize` — a CLAUDE.md past ~200 lines, where adherence starts dropping.
  - `warn.memory_index` — MEMORY.md past 200 lines, so the tail never loads.
  - `hint.scopeable` — a rules file with no `paths:` key, paying tokens every session for something that matters in one directory.
  - `hint.derivable` — a directory tree or dependency list the model can derive.
- Report the token figure as an estimate. It is bytes divided by four, and saying so costs one word.

## Next action

Exactly one line, and it must be the highest-value thing available:

| Situation | Next |
| --- | --- |
| No `charter.json` | `/charter:init` — two questions, about a minute |
| `permissions.has_deny: no` | `/charter:init` — this repo has no enforced boundaries |
| Any finding present | `/charter:check` — *n* findings |
| Session cost above ~2,000 tokens | `/charter:check` — *n* tokens of always-loaded context look trimmable |
| Nothing outstanding | `nothing — you're set` |

Print the block and stop. No commentary, no summary paragraph, no offer of further work.
