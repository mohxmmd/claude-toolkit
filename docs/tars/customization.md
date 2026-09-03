# Customization

TARS is one Markdown file of one-line rules. There is no config format. To
change a behavior, edit the line that causes it.

```bash
${EDITOR:-nano} ~/.claude/output-styles/TARS.md
```

Then `/clear` in Claude Code. Output styles load at session start, so an edit
does nothing until you clear or restart.

If you want to keep the upstream file and layer your own changes, copy it to a
new name instead and edit that:

```bash
cp ~/.claude/output-styles/TARS.md ~/.claude/output-styles/TARS-mine.md
# change the `name:` line inside the copy, then pick it in /config
```

The `name:` in the frontmatter is what appears in the `/config` picker, not the
filename. Two files with the same `name:` will collide.

---

## Map of the file

| Section | Controls | Edit it when |
| --- | --- | --- |
| Header dials | Flavor only. No mechanical effect. | You want a different self-description |
| **Shape of every reply** | Response structure and length budget | Answers are too long, too short, or bury the point |
| **Judgment** | Whether and how Claude disagrees with you | Pushback is too frequent or too rare |
| **Engineering** | Solution shape, complexity tolerance, architecture fit | Your codebase has different norms |
| **Verification** | Claims about what was run, tested, or checked | Almost never. This is the load-bearing section |
| **Scope** | What Claude touches beyond what you asked | It does too much, or too little |
| **Voice** | Length, formatting, tone, humor | Output is too terse or too chatty |

Frontmatter:

- `name`: the label in `/config`
- `description`: the subtitle in `/config`
- `keep-coding-instructions: true` keeps Claude Code's built-in software
  engineering instructions. **Leave this on** unless you are turning TARS into a
  non-coding assistant. Removing it drops scoping, verification, and file-editing
  guidance that TARS assumes is present.

---

## Recipes

### Make it stricter

Add to **Verification**:

```markdown
- Do not report a task complete until you have run the project's tests. If you cannot run them, say the task is unverified and stop.
- Before any claim about behavior, name the file and line you read to support it.
```

Add to **Judgment**:

```markdown
- State your confidence when it is below high, and what would raise it.
```

### Make it shorter still

Brevity is already the default. To push further, edit the ceiling in **Shape of
every reply**:

```markdown
- Default ceiling: 5 lines. Go past it only for a real list (findings, steps) or when asked for depth.
```

And remove from **Scope**:

```markdown
- Extra ideas: one line at the end, or nothing.
```

Do not remove this line, whatever ceiling you set:

```markdown
- Brevity never costs a correction. A false premise in the question is the first line of the answer.
```

It exists because an early build without it went quiet: asked to confirm a false
claim and then do a task, it silently did the task. The correction is the part
you are paying for.

### Make it longer

If answers feel clipped, raise the ceiling and restore the counterweight:

```markdown
- Default ceiling: 20 lines.
- Terse is not cryptic. Include what the reader needs to decide.
```

Expect noticeably longer output. That second line was in v1.0 and was the main
reason it sprawled.

### Change the humor level

The header dial is decorative. The behavior lives in **Voice**:

```markdown
- Dry humor, sparingly. Never in an error, a risk, or a security finding.
```

- **No humor:** delete the line.
- **More humor:** replace `sparingly` with `where it lands`. Keep the second
  sentence. Jokes in a security finding are how a finding gets ignored.

### Restore chat-first behavior

The original private version of TARS answered in chat and edited files only
when the request named a path. That is a real preference, but it half-disables
Claude Code for beginners, so it is not the public default. To bring it back,
add to **Scope**:

```markdown
- Answer in chat by default. Edit files only when the request names a file, a path, or an explicit action verb.
```

Expect to say "go ahead and edit it" more often. That is the trade.

### Make it ask more (or less)

The relevant line in **Scope** is:

```markdown
- Ask only when the answer changes what you build. Otherwise assume, state the assumption, continue.
```

- **Ask more:** replace with
  `- When a choice affects the design, ask before building. State the options in one line each.`
- **Ask less:** replace with
  `- Never ask. Pick the most defensible option, state it in one line, continue.`

Pairs well with Claude Code's permission modes. If you set "ask less", run in a
mode where you still approve writes.

### Add your team's engineering rules

Add a section at the end. Keep the one-line imperative format so it reads like
the rest of the file:

```markdown
## House rules

- Every new endpoint needs a request validation class. No inline validation.
- Migrations are forward-only. Never edit a migration that has shipped.
- No new dependency without naming what it replaces.
- Money is always integer minor units. Never a float.
```

Team-wide? Put the file at `.claude/output-styles/TARS.md` inside the repo and
commit it. Project-level styles beat user-level ones for that project, and
everyone gets the same rules.

For rules that are about *your codebase* rather than *how Claude should think*,
`CLAUDE.md` is the better home. Output styles change judgment and tone;
`CLAUDE.md` carries project facts.

---

## Things not worth changing

- **The header dials.** They are flavor. Editing `Humor 60` to `Humor 20` does
  nothing on its own. Edit the Voice line.
- **`keep-coding-instructions`.** See above.
- **Length, for token reasons.** The whole file is roughly 700 to 800 tokens and
  is cached after the first request in a session. Cutting rules to save tokens
  trades a real behavior for a rounding error.

---

## Sanity-check your edit

Prompts that reliably expose whether a change took effect:

| You want to test | Prompt |
| --- | --- |
| Pushback | State something false about your own code and ask it to confirm |
| Scope | Ask for a small change in a file that obviously needs a refactor |
| Verification | Ask it to fix something, then ask "is it working now?" |
| Voice | Ask any simple question and count the lines |

Run each before and after. If you cannot tell the difference, the rule is not
doing anything and should come back out.
