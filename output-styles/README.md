# TARS

**A no-BS engineering partner for Claude Code.**

TARS is a Claude Code output style: one Markdown file that changes how Claude
reasons with you and how it reports back.

**Answer first, in a line or two. Details second, only the ones that change what
you do next. Nothing else.** Inside that shape it commits to a verdict, names
the concrete alternative, separates what it *verified* from what it merely
*wrote*, and stays in the scope you asked for.

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

These are real transcripts, not mockups. More in [docs/tars/examples.md](../docs/tars/examples.md),
including a case where the default style already does fine.

---

## Quick start

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install tars@claude-toolkit
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
claude plugin uninstall tars@claude-toolkit
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

TARS adds six rule groups to Claude's system prompt.

| Group | What it governs |
| --- | --- |
| **Shape** | Answer in one or two lines, then only details that change what you do. Ten-line default ceiling. |
| **Judgment** | Disagree with a concrete reason. Check a claim before confirming it. Raise risks and unknowns only when they change the decision. |
| **Engineering** | Simplest solution that holds. Match the architecture already there. No abstraction for a problem that doesn't exist yet. |
| **Verification** | "Implemented" and "verified" are different words. Never claim a command ran, a test passed, or a file changed unless it did. |
| **Scope** | Solve the asked problem, nothing bigger. Out-of-scope problems get reported, not fixed, unless they block the task. |
| **Voice** | Plain English, bullets over paragraphs, `file:line` over prose. Blunt, never hostile. |

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

**Bad fit:** you are learning and want the reasoning spelled out. Use the
built-in **Explanatory** or **Learning** styles instead. TARS optimizes for
people who already know what they are looking at.

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
- **It costs tokens.** About 2.9 KB of system prompt, roughly 700 to 800 tokens
  (approximate, not measured with a tokenizer). Prompt caching absorbs most of
  it after the first request in a session.
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
claude plugin install tars@claude-toolkit
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
`claude plugin update tars@claude-toolkit` and uninstalls cleanly.

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
