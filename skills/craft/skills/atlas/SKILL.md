---
name: atlas
description: Reads an existing product and records what CRAFT needs to know about it. Use to set up CRAFT in a project, refresh its understanding after the design system changes, or check whether its recorded context still matches the code. Writes .craft/config.md and .craft/atlas/. Also runs as doctor to report drift, staleness and configuration problems.
argument-hint: "[init|refresh|doctor]"
license: Apache-2.0
allowed-tools:
  - Bash(node ${CLAUDE_PLUGIN_ROOT}/scripts/*)
metadata:
  craft_schema: "1"
---

Atlas answers one question: **what is this product?**

It records observed facts. It never invents preferences, and it never proposes a visual direction.

## Actions

`init` (default when no `.craft/` exists) · `refresh` · `doctor`

## init

### 1. Detect and measure

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/measure.mjs --json
```

Reads in this order, because token sources outrank scattered component styles: manifest → token and theme config → source tree → stylesheets and component styles.

Returns colours, type, spacing, radius, shadow, motion, breakpoints, a component inventory and five dials.

**Read [references/measure.md](../../references/measure.md) before believing any number.** Three rules from it that change what you write:

- **Rank on `files`, never on `evidence`.** A value in one file is a one-off however often it repeats; a value in forty files is a system.
- **`css` is usage-weighted.** When `stack.css_split` is non-null there are two systems and you must not name one canonical.
- **Every `signals` entry names its mechanism.** An empty `matched` means nothing matched, which is a fact. Never report a signal without it.

Name `excluded` in the report: what was dropped as vendored, generated, gitignored or derived, with the paths.

### 2. Reuse what already exists

Before asking anything, read whatever the project already wrote down: `DESIGN.md`, a design-system README, `docs/design*`, Storybook config and stories, a token file, a Tailwind theme, a UI component directory. Confirm those rather than re-deriving them. **Never make someone retype what they already documented.**

### 3. Confidence gates behaviour

| Confidence | Action |
|---|---|
| high, one source, consistent | write it, do not ask |
| medium, dominant value with outliers | write it, note the drift, do not ask |
| low, no dominant value | one question, only if it changes future work |
| absent | write `undecided`. **Never invent a default** |

`undecided` is a real value. A product with no motion vocabulary gets "none observed".

### 4. Ask, at most six, only what matters

Use the structured question tool when one is available. Attach the evidence, because people answer instantly when they can see the split.

> Two radius systems: `6px` on 31 components in `components/ui/*`, `12px` on 9 in `components/marketing/*`. Which is canonical?
> `6px` · `12px` · `both, split by area` · `neither, mid-migration`

Offer "mid-migration" wherever it is plausible. It records a legacy zone instead of forcing a false canonical value, and it is the most common real state of a mature codebase.

Ask about, in priority order: a genuine ambiguity in the token system; what must never change; the dev command, if it is not discoverable. **Do not ask for an aesthetic direction, a palette, a font or a style.** The product already has those.

### 5. Write

Write `.craft/config.md` from [templates/config.md](../../templates/config.md), filling only confirmed values, plus `.craft/atlas/{dna,product,components}.md` and `.craft/state.json`. Add `.craft/cache/` to the project's `.gitignore`.

**When `dials.write_to_config` is false, write the dials commented out**, saying the corpus was too thin to measure them. A wrong `density: 7` reads as authoritative and shapes every later decision. `undecided` and `inherit` are real values; a guess dressed as a measurement is not.

Never silently overwrite an existing `config.md`. Update in place, leaving human edits untouched, and report what changed.

Then append one line per artifact to `.forge/manifest.tsv`, creating it with the
header if it does not exist. It is the receipt an uninstall reads, and without
it removal falls back to guessing:

```
# component	kind	path	a	b
craft	path	.craft
craft	gitignore	.gitignore	.craft/cache/
```

Record only what this run created, one line per thing, paths relative to the
repository root. On a refresh, skip lines that are already there. Never record
`.gitignore` itself as a `path`: the `gitignore` kind removes the single line
and leaves the user's file alone.

### 5b. Offer the enforced form of "do not change"

Everything in `config.md` is a **convention**: CRAFT reads it and follows it, and
nothing stops another tool, another session, or a person from editing those
paths. Say so once, plainly, and never describe a config entry as a gate.

When `## Do not change` or `protected_surfaces` names a concrete path, print the
`Edit()` deny rule that would make it enforced, and offer to hand it to Charter:

```
## Do not change  ->  enforced form

  "permissions": { "deny": ["Edit(public/theme/css/bundle-*.css)"] }

  Install with /charter:check, or paste into .claude/settings.json.
  Until then this path is a convention CRAFT honours, not a boundary.
```

Use `Edit(<path>)`, never `Write(<path>)` — Claude Code accepts a `Write` path
rule and never consults it. One rule per path. Do not write the settings file
from atlas; Charter owns that file and needs to diff it.

### 6. Report, in about ten lines

Stack · dials with their confidence · the five most-used components from `components.top` · what was excluded and why · the three weakest surfaces you noticed · what was recorded as never-change. Then offer to improve one of the weak surfaces now. Do not lecture about the configuration format.

Always: name the exclusions with paths, and when `css_split` is set report both systems with their file shares rather than resolving to one.

## refresh

Re-measure and update `.craft/atlas/*` and `state.json`. **Never overwrite human edits in `config.md`.** Where a measured value now contradicts config, report the conflict and let the human decide.

## doctor

Read-only. Report, never repair:

| Check | Severity |
|---|---|
| `craft_schema` older than this version | route |
| config frontmatter key not recognised | mention, preserve the key |
| declared token absent from the code | mention |
| dominant code value differs from config | mention |
| `.craft/atlas/*` older than the code hash | auto |
| surface file with no matching path | mention |
| `cache/` not gitignored | auto |
| a dial in config was written from a low-confidence measurement | mention |
| `stack.css_split` set but config names one canonical system | mention |
| a `signals` entry recorded in atlas now has an empty `matched` | mention |

`auto` is applied on the next write to that file that was already happening. `mention` is stated once. `route` names the action and stops using that artifact.

**Never repair drift as a side effect of a design task.** Only this command repairs, and only when the user runs it.

## Rules

- Observed facts only. Mark every inference as an inference.
- Confirm before recording anything a human said in passing.
- `config.md` is the human's file. Atlas seeds it once and then defers to it.
- Everything in `.craft/atlas/` is disposable and regenerable. Nothing in it is authoritative over `config.md`.
