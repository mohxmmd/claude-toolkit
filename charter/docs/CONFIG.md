# Configuration

**There is no Charter configuration file.** The configuration is the generated artifacts, and every one of them is a native Claude Code file you can hand-edit forever.

This is deliberate. A Charter-specific config format would be a fifth configuration language layered over four that already exist, and the moment you edited `settings.json` directly the two would disagree.

| To change | Edit |
| --- | --- |
| What Claude knows and how it behaves | The fence in `CLAUDE.md` — plain markdown |
| What Claude may do | `.claude/settings.json` — native permissions |
| Area-specific conventions | `.claude/rules/*.md` — native path-scoped rules |
| How much Charter explains itself | One comment line inside the fence |
| Defaults for the next repo you set up | `~/.claude/charter.json` |

---

## Guidance level

One line inside the fence:

```markdown
<!-- guidance: quiet -->
```

`quiet` is the default. `explain` makes Claude give the reasoning behind an assumption, name which planning signals fired, say why a verification command was the narrowest sufficient one, and identify which rule matched when a boundary blocks something.

There are two levels, not four. Inferring a user's experience level guesses wrong in both directions, and multiplying every behaviour by four is four times the maintenance for no gain.

---

## Editing the working agreement

Everything between the fence markers is Charter's; everything outside is yours and is never touched.

```markdown
<!-- charter:start v1 -->
...edit freely — a re-run diffs against this, it does not clobber it...
<!-- charter:end -->
```

Delete the fence entirely and Charter will not re-create it without asking.

**Keep it under 35 lines.** That cap is the reason the file still works. Past roughly 200 lines Claude follows a CLAUDE.md *less* reliably, and everything in it costs tokens on every session forever. When you have more to say, say it in a path-scoped rule instead.

---

## Moving content into path-scoped rules

The highest-leverage edit available. Content in `CLAUDE.md` loads always; content in a rule with a `paths:` key loads only when Claude opens a matching file.

```markdown
---
paths:
  - "resources/views/**"
  - "public/css/**"
---
Buttons that fire an async request need a loading state: swap the label for a
spinner, block repeat clicks, restore on completion.
```

That is free until someone opens a view. Run `/charter:check` to find candidates — it flags any rules file missing a `paths:` key and any always-loaded content that is area-specific.

Glob patterns: `**/*.ts`, `src/**/*`, `src/**/*.{ts,tsx}`, `app/api/*.py`.

---

## Editing the boundaries

```bash
/permissions              # view and manage interactively
$EDITOR .claude/settings.json
```

Three things worth knowing before you edit:

1. **Order is deny → ask → allow, and specificity does not matter.** A deny rule cannot have exceptions carved out of it. If `Bash(aws *)` is denied, an allow for `Bash(aws s3 ls)` will not bring it back.
2. **The space before a trailing `*` is part of the rule.** `Bash(ls *)` does not match `lsof`; `Bash(ls*)` does.
3. **Only deny and ask protect anything.** Allow rules remove prompts.

Full syntax: [Configure permissions](https://code.claude.com/docs/en/permissions). The complete list of traps Charter's generator encodes is in [`references/policy.md`](../references/policy.md).

### Committed or personal

| Scope | File | Applies to |
| --- | --- | --- |
| Team | `.claude/settings.json` | Everyone who clones the repo |
| Personal | `.claude/settings.local.json` | Just you, untracked |

Charter picks based on your answer to "who else works in this repo". To switch later, move the `permissions` block between the two files. Rules merge across scopes rather than overriding, so a personal file can add to a committed one.

---

## Making Charter silent

Charter has no runtime. It ships **no enabled hooks**, so nothing fires on an ordinary prompt and nothing runs unless you type a command.

To reduce it further:

- Trim the fence to the commands and one or two facts. Roughly 150 tokens.
- Set `guidance: quiet` if it is not already.
- Never run `/charter:check` — nothing schedules it.

To make it invisible while keeping the enforcement: delete the fence, keep `.claude/settings.json`. The boundaries hold with zero context cost.

---

## Defaults for future repositories

`~/.claude/charter.json`, read only by `/charter:init` to pre-fill answers. Never loaded into a session.

```json
{
  "git": "local-commits",
  "scope": "auto",
  "guidance": "quiet"
}
```

`scope: "auto"` picks committed or personal from the collaboration answer. Force it with `"project"` or `"local"`.

---

## Uninstalling

```bash
# 1. remove the working agreement
#    delete the charter:start / charter:end block from CLAUDE.md

# 2. remove the boundaries (optional — they work without the plugin)
#    delete the deny/ask entries from .claude/settings.json

# 3. remove state and rules
rm .claude/charter.json
rm -r .claude/rules          # only if you want the area rules gone

# 4. remove the plugin
/plugin uninstall charter
```

Uninstalling the plugin and **keeping** everything it wrote is a supported outcome. The files are standard Claude Code configuration and do not depend on Charter being installed.

---

## Upgrades

The fence carries a schema version (`<!-- charter:start v1 -->`) and `charter.json` carries `"schema": 1`. On a version bump, `/charter:status` notices the mismatch and offers a migration that rewrites only inside the fence, with a diff.

Permission rules are never rewritten on upgrade. A changed boundary always requires explicit confirmation.

---

## Troubleshooting

**`/charter:init` says a command is missing that exists.** It only records commands that exit zero when probed. Run the probe yourself (`npm test -- --help`, `./vendor/bin/phpunit --version`) — if it fails, the recorded absence is correct.

**A boundary blocks something legitimate.** Delete the rule. Then consider `ask` instead of `deny` if you want the prompt but not the wall.

**`claude doctor` warns about a rule Charter wrote.** A bug — please report it with the rule text. The generator is meant to produce warning-free output.

**Claude ignores the working agreement.** Check `/context` to confirm CLAUDE.md actually loaded. Then look for a contradiction: two always-loaded files disagreeing makes the model pick one arbitrarily. `/charter:check` looks for exactly this.

**The session cost looks high.** Run `/charter:check`. It reports the breakdown and names what can move to a path-scoped rule or be cut entirely.
