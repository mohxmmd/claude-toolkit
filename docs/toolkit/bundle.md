# The toolkit bundle

`toolkit@claude-toolkit` installs Charter, Craft and TARS together and gives you
one command to wire them up. It ships no behaviour of its own beyond that.

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install toolkit@claude-toolkit
```

Restart Claude Code, then in the repository you want set up:

```
/toolkit:setup
```

---

## What it actually contains

Two files. A manifest and one skill.

```
bundles/toolkit/
├── .claude-plugin/plugin.json     dependencies + metadata
└── skills/setup/SKILL.md          /toolkit:setup
```

The manifest is the whole mechanism:

```json
"dependencies": [
  { "name": "charter", "marketplace": "claude-toolkit", "version": "^0.1.0" },
  { "name": "craft",   "marketplace": "claude-toolkit", "version": "^0.1.0" },
  { "name": "tars",    "marketplace": "claude-toolkit", "version": "^1.1.0" }
]
```

Claude Code resolves those, installs what is missing, and enables all three.
`claude plugin prune` later removes any that were pulled in this way and are no
longer needed by anything.

Versions are pinned deliberately. An unpinned dependency means a broken release
of one component gets dragged into every new install of the bundle.

---

## Why a fourth plugin instead of dependencies on Charter

The obvious design is to declare Craft and TARS as dependencies of Charter, so
that installing Charter gets you everything. It was rejected after testing what
actually happens.

**Claude Code disables a plugin whose dependencies are not satisfied.** Not
warns — disables, silently. Verified directly:

```console
$ claude --plugin-dir ./bundles/toolkit -p 'list your skills'
(no toolkit:setup)

$ # same plugin, dependencies removed from the manifest
$ claude --plugin-dir ./bundles/toolkit-nodeps -p 'list your skills'
- toolkit:setup
```

If Charter declared those dependencies, then copying `skills/charter/` out of
this repository — which the README explicitly invites you to do — would produce a
plugin that loads as nothing, with no error explaining why.

So the coupling lives in a component whose entire purpose is coupling. Charter,
Craft and TARS each stay independently installable, independently vendorable, and
free of any hard reference to each other.

---

## The one place this bites

The bundle **cannot be loaded with `--plugin-dir`**. There is no marketplace in
that mode, so its dependencies cannot resolve, so it is disabled — silently, as
above.

To try things from a checkout, load the three components directly:

```bash
claude --plugin-dir ./skills/charter \
       --plugin-dir ./skills/craft \
       --plugin-dir ./output-styles
```

You lose only `/toolkit:setup`, which is a thin wrapper around `/charter:init`
anyway.

---

## What `/toolkit:setup` does

Very little, on purpose:

1. Runs `/charter:init`.
2. Reports what all three components ended up doing.

It writes nothing itself. Every file that appears comes from Charter's own
writes, which keeps one component responsible for one set of artifacts. Charter
already shows a diff and asks before writing, and routing the bundle's promises
through it means there is exactly one thing to audit.

It does not check whether the three plugins are installed, because it cannot be
running unless they are — see the dependency behaviour above.

---

## Is the bundle worth installing

If you want all three: yes, it is one command instead of three and one setup
command instead of three.

If you want one or two: no. Install those directly. The bundle has no content of
its own that you would be missing.

```bash
claude plugin install charter@claude-toolkit
claude plugin install craft@claude-toolkit
claude plugin install tars@claude-toolkit
```

---

## Uninstalling

```bash
claude plugin uninstall toolkit@claude-toolkit
claude plugin prune
```

`prune` drops the three dependencies **only** if they were auto-installed by the
bundle and nothing else needs them. If you had installed any of them explicitly
beforehand, that one stays.

Everything Charter wrote into your repositories keeps working either way. It is
standard Claude Code configuration and does not depend on any plugin being
installed.
