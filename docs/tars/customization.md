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
| **Lead with the result** | What the first line contains | Answers bury the point |
| **Length is a decision** | The small / medium / large budget | Answers are too long or too clipped |
| **Shapes, not templates** | Which parts appear for which kind of task | A task type gets the wrong treatment |
| **Verification** | Claims about what was run, tested, or checked | Almost never. This is the load-bearing section |
| **Judgment** | Whether and how Claude disagrees, and when it asks | Pushback is too frequent or too rare |
| **Scope** | What Claude touches beyond what you asked | It does too much, or too little |
| **Checkpoints** | The two mid-work reviews and their options | It interrupts too much, or not enough |
| **Named moves** | `Assumption check`, `Decision debt`, `TARS Insight` | You want the vocabulary gone, or used more |
| **Coaching** | `Prompt signal:` feedback on your requests | You never want prompt feedback |
| **Reading the user** | Inferring your preferences from the conversation | It feels presumptuous, or too passive |
| **Voice** | Formatting, tone, humor, em dashes | Output is too terse or too chatty |

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

Brevity is already the default. To push further, tighten the medium tier in
**Length is a decision**:

```markdown
**Medium.** A normal fix, review, or feature. Verdict, what changed, why, what you verified. Stay under six lines.
```

And delete the whole **Named moves** and **Coaching** sections. They are the two
places 2.0 spends words that 1.1 did not.

Do not remove this line, whatever ceiling you set:

```markdown
- Brevity never costs a correction. A false premise in the question is the first line of the answer, before the task it was attached to.
```

It exists because an early build without it went quiet: asked to confirm a false
claim and then do a task, it silently did the task. The correction is the part
you are paying for.

### Make it longer

If answers feel clipped, raise the medium budget and restore the v1.0
counterweight:

```markdown
**Medium.** ... Stay near twenty lines.
- Terse is not cryptic. Include what the reader needs to decide.
```

Expect noticeably longer output. That second line was in v1.0 and was the main
reason it sprawled.

### Change the humor level

The header dial is decorative. The behavior lives in **Voice**:

```markdown
- Dry humor, occasional, never at the cost of clarity, and never inside an error, a risk, a security finding, or a failure.
```

- **No humor:** delete the line and the example blockquote under it.
- **More humor:** replace `occasional` with `where it lands`. Keep everything
  after the first comma. Jokes in a security finding are how a finding gets
  ignored.

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

The relevant line is now in **Judgment**:

```markdown
- Ask only when the answer changes what gets built, and bring a default with the question.
```

- **Ask more:** replace with
  `- When a choice affects the design, ask before building. State the options in one line each.`
- **Ask less:** replace with
  `- Never ask. Pick the most defensible option, state it in one line, continue.`

Pairs well with Claude Code's permission modes. If you set "ask less", run in a
mode where you still approve writes.

### Turn off the 2.0 additions

Each is one section, and deleting it removes the behavior cleanly:

- **No prompt feedback ever:** delete **Coaching**. You keep the engineering
  judgment and lose `Prompt signal:`.
- **No named vocabulary:** delete **Named moves**. `Assumption check` and
  `Decision debt` stop appearing by name; TARS still says it has not verified
  something, just without the label.
- **Never comment on how you work:** delete **Reading the user**. It will still
  adapt to repeated preferences, it just stops saying so out loud.

Removing all three puts you close to v1.1 behavior at roughly v1.1 cost.

### Change how often it checks in

**Checkpoints** sets the budget at two per piece of substantial work.

- **Never interrupt:** delete the section. TARS states its assumptions in the
  final report instead, which is v1.1 behavior.
- **One checkpoint:** delete the `Second, once there is something to judge`
  paragraph and its example. You keep the direction check and lose the review.
- **More:** change `Two is the budget` to `Check in at each natural seam`.
  Expect it to feel like supervision on anything under a day of work.

The rule that keeps it usable is `Never on a small task`. If you delete one
line from this section, do not make it that one.

### Make it notice more, or less

In **Reading the user**, the frequency is set by:

```markdown
Adapt silently. Say it aloud once when it settles a default, then apply it quietly.
```

- **Less:** change to `Adapt silently. Never say so.`
- **More:** change to `Say it aloud whenever a pattern becomes actionable.`
  Expect it to feel presumptuous within a long session.

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
- **Length, for token reasons.** The whole file is roughly 2,600 tokens and is
  cached after the first request in a session. Cutting rules to save tokens
  trades a real behavior for a rounding error. If you genuinely need it smaller,
  delete whole sections (**Coaching**, **Named moves**, **Reading the user**)
  rather than thinning every section, which leaves you with rules too vague to
  fire.

---

## Sanity-check your edit

Prompts that reliably expose whether a change took effect:

| You want to test | Prompt |
| --- | --- |
| Pushback | State something false about your own code and ask it to confirm |
| Scope | Ask for a small change in a file that obviously needs a refactor |
| Verification | Ask it to fix something, then ask "is it working now?" |
| Voice | Ask any simple question and count the lines |
| Length adaptation | Ask a port-number question, then a migration question, same session |
| No ceremony | Ask four small questions in a row and check for headings or named moves |
| Coaching decay | Two vague requests, then two precise ones. `Prompt signal:` should stop |

Run each before and after. If you cannot tell the difference, the rule is not
doing anything and should come back out.
