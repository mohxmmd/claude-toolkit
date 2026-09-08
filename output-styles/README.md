# TARS

**A no-BS engineering partner for Claude Code.**

TARS is a Claude Code output style: one Markdown file that changes how Claude
reasons with you and how it reports back.

**The result comes first. The shape and length of what follows are chosen from
the task, not from a template.** A port number gets one word. A migration gets a
summary you could act on without reading further. Inside that, it commits to a
verdict, names the concrete alternative, separates what it *verified* from what
it merely *wrote*, and stays in the scope you asked for.

No dependencies. Install in under a minute. Remove by deleting one file.

---

## See it first

Same prompt, same model, same repo. Only the output style differs.

> **You:** We have 3 discount types today and might add more. I want a
> `DiscountStrategy` abstract base class, a registry, a factory, and a plugin
> loader so new types can be dropped in. Design it.

**Claude, default style:**

> For 3 discount types, I'd push back on the whole stack: an ABC + registry +
> factory + plugin loader is four layers of indirection for what a dict of
> `{name: function}` (or a small `if/elif`) handles today. The tradeoff is
> discoverability vs. YAGNI [...] Want me to sketch the minimal version instead?

**Claude, TARS:**

> No. That's four layers of indirection for a problem you don't have.
>
> **Recommendation:** function per discount + a dict.
>
> ```python
> DISCOUNTS = {
>     "percent": lambda price, pct: price * (1 - pct/100),
>     "fixed":   lambda price, amt: max(0, price - amt),
>     "bogo":    lambda price, qty: price * (qty // 2 + qty % 2),
> }
> ```
>
> Adding a fourth type = one line. When you hit ~8 types, or types need shared
> state/validation/config, promote to a class. Plugin loader only if third
> parties ship discounts out-of-tree, which they aren't.
>
> YAGNI. Build the registry the day you need it, not today.

Both disagree with you, in about the same number of words. Only one hands you
the code, the threshold at which your original idea becomes correct, and a
verdict instead of a request for permission.

TARS is not mainly shorter than the default. It is denser.

### What 2.0 added

The default style treats every turn as a fresh request. TARS reads the
conversation. After picking the simplest option three times in a row:

> **You:** Simplest again.
>
> **TARS:** **In-process token bucket, per-IP.** Locking in "single server, no
> extra infra" as the default from here, so I won't re-open the fork next time.

Two turns later, on a new subsystem, it applied that silently and then said
where the preference stops working:

> **TARS:** **"Simplest" can't carry this one alone.** A notification system's
> shape is set by two things I don't know yet: which channels, and whether
> delivery needs to be real-time. [...] Here's a concrete default consistent
> with your single-server, no-infra choices, plus the two forks that would move
> it.

That is the behavior you notice most when you switch back.

These are real transcripts, not mockups. More in [docs/tars/examples.md](../docs/tars/examples.md),
including a case where the default style already does fine.

---

## Quick start

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install tars@claude-forge
```

Then, in Claude Code:

1. Run `/config`
2. Pick **tars:TARS** under **Output style**
3. Run `/clear`

That's it. Output styles load at session start, so the `/clear` matters.

The `tars:` prefix is not decoration — plugin styles are namespaced, and a
setting that says `TARS` will not find `tars:TARS`. See
[Compatibility](#compatibility) for why both names exist.

<details>
<summary>Install as a file instead (no marketplace)</summary>

```bash
git clone https://github.com/mohxmmd/claude-toolkit.git
cd claude-toolkit
./install.sh
```

Or copy the one file directly:

```bash
mkdir -p ~/.claude/output-styles
curl -fsSL https://raw.githubusercontent.com/mohxmmd/claude-toolkit/main/output-styles/TARS.md \
  -o ~/.claude/output-styles/TARS.md
```

Then `/config` → Output style → **TARS** (no prefix) → `/clear`.

For a single project instead of everywhere, put the file in
`.claude/output-styles/TARS.md` inside the repo. Commit it and the whole team
gets the same style.
</details>

<details>
<summary>Uninstall</summary>

Plugin install:

```bash
claude plugin uninstall tars@claude-forge
```

File install:

```bash
rm ~/.claude/output-styles/TARS.md
```

Then `/config` → Output style → Default. The installer never deletes anything,
so any file it replaced is still there as `TARS.md.backup-<timestamp>`.
</details>

---

## What actually changes

TARS replaces Claude's default reporting instincts with ten rule groups.

| Group | What it governs |
| --- | --- |
| **Lead with the result** | The first line is the verdict, the root cause, the number, or an honest "I cannot confirm that". Evidence comes after. |
| **Length is a decision** | Small, medium and large tiers instead of one shape. A port number gets one word; a migration gets a summary that stands on its own. |
| **Shapes, not templates** | Eight task modes (debug, implement, decide, review, refactor, UI, plan, blocked), described as the parts that matter rather than a form to fill in. |
| **Verification** | "Implemented" and "verified" are different words. Never claim a command ran, a test passed, or a file changed unless it did. |
| **Judgment** | Disagree with a concrete reason. Recommend instead of listing options. Ask only when the answer changes what gets built, and bring a default with the question. |
| **Scope** | Solve the asked problem. Out-of-scope findings get reported, not fixed. Scope growth gets named out loud. |
| **Checkpoints** | On substantial work it stops twice: once on the fork before the bulk of the build, once when there is something to judge. Numbered options with a default, so "go" is a valid answer. Never on small tasks. |
| **Named moves** | `Assumption check`, `Decision debt`, `TARS Insight`. A shared vocabulary, rated for frequency: most responses use none of it. |
| **Coaching** | `Prompt signal:` when missing information actually changed the work. It decays as your requests get more precise. |
| **Reading the user** | Infer working preferences from the conversation, state one once when it settles a default, then apply it silently. |

It keeps Claude Code's built-in software engineering instructions
(`keep-coding-instructions: true`), so this is a change of judgment and tone,
not a replacement for how Claude codes.

---

## Philosophy

Claude is very good at agreeing with you. That is usually pleasant and
occasionally expensive. The failure modes that cost real time are not "the
model can't code":

- It validates a plan you have not thought through.
- It says "done" about code it never ran.
- It refactors four files when you asked about one.
- It gives you three balanced options when you needed a recommendation.

TARS is a set of defaults aimed at those four. The principles behind it:

- **Correctness over agreement.** Being wrong is worse than being disagreed with.
- **Evidence over confidence.** A claim you can check beats a claim you can't.
- **Verification over completion.** Writing the code is not finishing the job.
- **Simplicity over structure.** Complexity is fine when it buys something. Say what.
- **Scope discipline over helpfulness.** Unrequested work is work you now have to review.
- **Useful criticism over praise.** "Looks good" is not a review.

The personality serves the engineering. Not the other way around. TARS is
blunt about the work and never about you.

---

## Who it's for

**Good fit:** you review Claude's output rather than accepting it, you have
been burned by a confident "all tests pass", or you find the default tone
padded.

**Bad fit:** you want every step narrated as it happens. Use the built-in
**Explanatory** or **Learning** styles for that. TARS does teach, but only when
the work just produced a lesson, and it stops once your requests get precise.
It optimizes for people who already know what they are looking at.

---

## Customization

TARS is one Markdown file of one-line rules. Delete a line to remove a
behavior, add a line to add one. There is no config format to learn.

[docs/tars/customization.md](../docs/tars/customization.md) covers which section controls
what, plus recipes for: making it stricter, making it quieter, changing the
humor level, restoring chat-first behavior, and adding your team's engineering
rules.

---

## Honest limitations

- **It applies to the main conversation only.** Subagents run their own system
  prompt and ignore output styles.
- **It costs tokens.** About 10.6 KB of system prompt, roughly 2,600 tokens
  (approximate, not measured with a tokenizer). That is three times v1.1, which
  bought the response modes, the named vocabulary and the coaching. Prompt
  caching absorbs most of it after the first request in a session.
- **The "no em dashes" rule is the weakest one in the file.** v1.1 prohibited
  them and they appeared 18 times in a 17-turn evaluation. 2.0 names a
  replacement instead, which held for four turns. Small sample. Do not rely on
  it. It is also scoped: it governs prose TARS writes, not text a tool, skill or
  template dictates verbatim. A skill that tells Claude to write a specific line
  containing an em dash wins, because a corrupted command is worse than a
  punctuation mark.
- **On large open-ended questions it is closer to the default than you would
  hope.** On a migration question TARS wrote 657 words to the default's 635.
  The difference is that TARS opens with the recommendation and names the hard
  part first. Real, but structural. The gap is widest on pushback and on small
  tasks, not on essays.
- **It is a prompt, not a guarantee.** It shifts defaults. It does not make
  fabrication impossible.
- **Some of what it asks for, Claude already does.** Recent Claude Code
  versions are already careful about claiming verification. TARS makes that
  behavior explicit and consistent rather than inventing it.

---

## Compatibility

Two install paths, both verified on Claude Code **2.1.197** (Linux). They differ
in one way that matters: **the name you select.**

| Install | Style name | Where it lives |
|---|---|---|
| Plugin | `tars:TARS` | The plugin cache, managed by `claude plugin` |
| File (`install.sh`) | `TARS` | `~/.claude/output-styles/TARS.md` |

Plugin-bundled output styles are namespaced `<plugin>:<style>`. The two installs
therefore coexist without colliding, and a setting that names one will not
resolve the other.

### The plugin path works

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install tars@claude-forge
```

Then `/config` → **Output style** → **tars:TARS** → `/clear`.

Verified end to end, headless, with a negative control:

```console
$ claude --plugin-dir ./output-styles \
         --settings '{"outputStyle":"tars:TARS"}' \
         -p 'State your active output style and its three numeric values.'
TARS. Honesty 95, Humor 60, Flattery 0.

$ claude --settings '{"outputStyle":"tars:TARS"}' \
         -p 'State your active output style and its three numeric values.'
I don't have an active output style — none is set in this session.
```

The style applies only when the plugin is loaded, which is what proves the
plugin supplied it rather than a file left over from an earlier install.

### Earlier versions

On **2.1.112** the plugin install completed and the style never appeared. That
was true when written and is no longer true. If you are on a version between the
two and the plugin path does not work, use `install.sh` — the file path has
worked on every version tested.

### Which to pick

**Plugin**, if you already use the marketplace. It updates with
`claude plugin update tars@claude-forge` and uninstalls cleanly.

**File**, if you want TARS without a marketplace, want to pin a hand-edited
copy, or want it in one project only:

```bash
./install.sh --dir /path/to/project/.claude/output-styles
```

Project-level `.claude/output-styles/` is read the same as the user-level
directory, so a committed copy gives a whole team the same style.

---

## Contributing

Behavioral changes need evidence, not opinion. See
[CONTRIBUTING.md](CONTRIBUTING.md) for how to test a proposed rule change
before opening a PR.

TARS lives in [mohxmmd/claude-toolkit](https://github.com/mohxmmd/claude-toolkit) alongside
[CRAFT](../skills/craft/README.md). Issues and pull requests go to that repository.

## License

Apache-2.0. See [LICENSE](../LICENSE).

The name is a nod to the robot in *Interstellar*, which had an adjustable
honesty setting. This one does not.
