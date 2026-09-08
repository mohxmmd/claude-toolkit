# Toolkit

**Installs Charter, Craft and TARS together, and wires them up in one pass.**

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install toolkit@claude-toolkit
```

Restart Claude Code, then in the repository you want set up:

```
/toolkit:setup
```

Two to five questions, about a minute, and a diff before anything is written.

---

## What you get

| | |
|---|---|
| **[Charter](../../skills/charter/README.md)** | A working agreement in `CLAUDE.md` and *enforced* permission boundaries in settings |
| **[Craft](../../skills/craft/README.md)** | UI/UX changes that fix the smallest thing rather than regenerating the screen |
| **[TARS](../../output-styles/README.md)** | Answers first, in a line or two, and tells you when you are wrong |

The bundle itself contains no behaviour beyond `/toolkit:setup`. It is a
manifest that declares the other three as dependencies, and one skill that runs
Charter and reports the result.

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
