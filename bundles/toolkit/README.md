# Toolkit

**Installs Charter, Craft and TARS together, and wires them up in one pass.**

```bash
git clone https://github.com/mohxmmd/claude-toolkit.git
cd claude-toolkit && ./setup.sh
```

That also enables auto-update, so you receive fixes without repeating it —
see [docs/AUTO-UPDATE.md](../../docs/AUTO-UPDATE.md). Without the script:

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install toolkit@claude-toolkit
```

Restart Claude Code, then in the repository you want set up:

```
/charter:init       the actual setup — two to five questions, about a minute
/toolkit:setup      where am I, and what should I type next
```

`/charter:init` does the work: it surveys the repo, asks its questions, shows a
diff, and writes the working agreement and boundaries. It also offers to wire
TARS and Craft, since the bundle guarantees both are installed.

`/toolkit:setup` is an orientation. It reads what is configured in this
repository and prints the one command to type next. **It writes nothing.**

---

## What you get

| | |
|---|---|
| **[Charter](../../skills/charter/README.md)** | A working agreement in `CLAUDE.md` and *enforced* permission boundaries in settings |
| **[Craft](../../skills/craft/README.md)** | UI/UX changes that fix the smallest thing rather than regenerating the screen |
| **[TARS](../../output-styles/README.md)** | Answers first, in a line or two, and tells you when you are wrong |

The bundle itself contains almost nothing: a manifest declaring the other three
as dependencies, and one read-only orientation command.

**It cannot run the other components' commands, and does not try.**
`/charter:init` and `/craft:atlas` are marked `disable-model-invocation` — they
run only when a person types them, because each writes files and asks questions.
A model deciding on its own to rewrite your permissions is exactly the failure
that flag exists to prevent. The bundle's value is the dependency install, not
automation of commands that should stay deliberate.

---

## Do you want this

**Yes**, if you want all three. One install command instead of three, one setup
command instead of three.

**No**, if you want one or two. Install those directly — the bundle has no
content you would be missing.

```bash
claude plugin install charter@claude-toolkit
claude plugin install craft@claude-toolkit
claude plugin install tars@claude-toolkit
```

---

## One thing to know

**The bundle cannot be loaded with `--plugin-dir`.** It declares dependencies,
Claude Code disables a plugin whose dependencies are unsatisfied, and a checkout
has no marketplace to resolve them against. It will load as nothing, silently.

To work from a checkout, load the three components directly:

```bash
claude --plugin-dir ./skills/charter \
       --plugin-dir ./skills/craft \
       --plugin-dir ./output-styles
```

That is also the reason the coupling lives here rather than in Charter. Charter
declaring these dependencies would mean copying `skills/charter/` out of this
repository produced a plugin that silently did nothing.

Full reasoning: [docs/toolkit/bundle.md](../../docs/toolkit/bundle.md).

---

## Uninstalling

```bash
claude plugin uninstall toolkit@claude-toolkit
claude plugin prune
```

`prune` drops the three dependencies only if the bundle pulled them in and
nothing else needs them. Anything you had installed explicitly stays.

Everything Charter wrote into your repositories keeps working. It is standard
Claude Code configuration and does not depend on any plugin being installed.

## License

Apache-2.0. See [LICENSE](../../LICENSE).
