# The toolkit bundle

`toolkit@claude-toolkit` installs Charter, Craft and TARS together and gives you
one command to wire them up. It ships no behaviour of its own beyond that.

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install toolkit@claude-toolkit
```

Restart Claude Code, then in the repository you want set up:

```
/charter:init
```

---

## What it actually contains

Two files. A manifest and one skill.

```
bundles/toolkit/
├── .claude-plugin/plugin.json     dependencies + metadata
├── scripts/state.sh               read-only repository state
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

You lose only `/toolkit:setup`, which is an orientation command — the three
components' own commands are unaffected.

---

## What `/toolkit:setup` does

Reads what is configured in the current repository and prints the one command to
type next. That is all. It writes nothing.

```
TOOLKIT   my-app

✗ Charter    not run
✗ Craft      not run
✓ TARS       tars:TARS in .claude/settings.local.json

Next: /charter:init — two to five questions, about a minute
```

### Why it does not just run Charter for you

It was written that way first. It could not work.

`/charter:init`, `/craft:atlas` and `/craft` are all marked
`disable-model-invocation: true`. That removes them from the model's view
entirely — verifiable by loading Charter and asking Claude to list its skills,
where `charter:init` appears only if the flag is stripped. No model can invoke
them, through the Skill tool or otherwise.

That flag is correct and should stay. Each of those commands writes files and
asks questions. A command that rewrites your permission rules should fire
because a person typed it, not because a model inferred it might be wanted.

The alternative — having the bundle reimplement Charter's writes — is worse than
the problem. It would produce a working agreement and permission rules that
Charter did not author and therefore cannot diff, check, or update, and two
components writing the same artifacts is how configuration silently diverges.

So the bundle does the part that genuinely needs no judgment: install the three
plugins, and point at the right next command.

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
