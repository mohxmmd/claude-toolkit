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

These are real transcripts, not mockups. More in [docs/examples.md](docs/examples.md),
including a case where the default style already does fine.

---

## Quick start

```bash
git clone https://github.com/mohxmmd/skills.git
cd skills/tars
./install.sh
```

Then, in Claude Code:

1. Run `/config`
2. Pick **TARS** under **Output style**
3. Run `/clear`

That's it. Output styles load at session start, so the `/clear` matters.

<details>
<summary>Manual install (no script)</summary>

Copy one file:

```bash
mkdir -p ~/.claude/output-styles
curl -fsSL https://raw.githubusercontent.com/mohxmmd/skills/main/tars/output-styles/TARS.md \
  -o ~/.claude/output-styles/TARS.md
```

Then `/config` → Output style → TARS → `/clear`.

For a single project instead of everywhere, put the file in
`.claude/output-styles/TARS.md` inside the repo.
</details>

<details>
<summary>Uninstall</summary>

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

[docs/customization.md](docs/customization.md) covers which section controls
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

Verified on Claude Code **2.1.112** (Linux): user-level install at
`~/.claude/output-styles/TARS.md` loads correctly and takes effect.

**Do not install TARS as a plugin yet, even though this repo is a Claude Code
marketplace.** TARS ships a valid plugin manifest, so this works:

```bash
claude plugin marketplace add mohxmmd/skills
claude plugin install tars@skills
```

Tested on 2.1.112, it installs cleanly and then does nothing. The file lands in
the plugin cache and the style never appears in `/config`. Retested with an
explicit `outputStyles` manifest field: same result. Claude Code's docs describe
plugins shipping an `output-styles/` directory, but the minimum version that
supports it is not documented anywhere I could find.

The manifest is here for the day that lands. Until then, **use `install.sh` or
the manual copy above.** Both put the file where every version reads it.

If plugin-bundled output styles work on your version, please open an issue
saying which version. That is the single most useful thing anyone can report.

---

## Contributing

Behavioral changes need evidence, not opinion. See
[CONTRIBUTING.md](CONTRIBUTING.md) for how to test a proposed rule change
before opening a PR.

TARS lives in [mohxmmd/skills](https://github.com/mohxmmd/skills) alongside
[CRAFT](../craft/README.md). Issues and pull requests go to that repository.

## License

Apache-2.0. See [LICENSE](../LICENSE).

The name is a nod to the robot in *Interstellar*, which had an adjustable
honesty setting. This one does not.
