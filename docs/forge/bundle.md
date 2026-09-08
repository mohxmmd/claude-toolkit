# The forge bundle

`forge@claude-forge` installs Charter, Craft and TARS together and gives you
one command to wire them up. It ships no behaviour of its own beyond that.

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install forge@claude-forge
```

Restart Claude Code, then in the repository you want set up:

```
/charter:init
```

---

## What it actually contains

A manifest and two skills, both read-only.

```
bundles/forge/
├── .claude-plugin/plugin.json     dependencies + metadata
├── scripts/state.sh               read-only repository state
├── scripts/doctor.sh              read-only context-surface audit
├── skills/setup/SKILL.md          /forge:setup
└── skills/doctor/SKILL.md         /forge:doctor
```

The manifest is the whole mechanism:

```json
"dependencies": [
  { "name": "charter", "marketplace": "claude-forge", "version": "^0.1.0" },
  { "name": "craft",   "marketplace": "claude-forge", "version": "^0.1.0" },
  { "name": "tars",    "marketplace": "claude-forge", "version": "^1.1.0" }
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
$ claude --plugin-dir ./bundles/forge -p 'list your skills'
(no forge:setup)

$ # same plugin, dependencies removed from the manifest
$ claude --plugin-dir ./bundles/forge-nodeps -p 'list your skills'
- forge:setup
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

You lose only `/forge:setup` and `/forge:doctor`, which report and write
nothing — the three components' own commands are unaffected.

---

## What `/forge:setup` does

Reads what is configured in the current repository and prints the one command to
type next. That is all. It writes nothing.

```
FORGE     my-app

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

## What `/forge:doctor` does

The one job no component can do alone: read every AI context surface in the repo
and check them against each other.

Each tool here is good at writing things down. None of them reads what the others
wrote. A repository accumulates `CLAUDE.md`, auto-memory, `.claude/rules/`,
`.ai/rules/`, `.project-context/`, `.craft/` and a house skill — all loaded, none
reconciled, and nothing saying which wins when two disagree.

```
$ /forge:doctor

count.always_loaded_surfaces: 5
warn.surfaces: 5 always-loaded surfaces; nothing states which wins when two disagree
dead.ref: CLAUDE.md -> docs/architecture.md
dead.cmd: CLAUDE.md -> npm run bundle
dup.assertion: CLAUDE.md == .ai/rules/console.md :: Never commit unless explicitly asked.
tier.claim: .craft/config.md:2 :: CRAFT will refuse to touch public/theme/bundle.css
tier.verdict: no permission rules exist, so every enforcement claim above is a convention
precedence.stated_in: nowhere
```

The last two lines are the check that mattered enough to build the command. Prose
claiming an enforcement it does not have is the failure mode this whole toolkit
warns other tools about, and Forge shipped one: `.craft/config.md` said CRAFT
would "refuse to touch" a path while nothing stopped an edit to it. `/forge:doctor`
finds that class of bug by comparing the words in a document against the
permission rules that actually exist.

**It reports and never repairs**, including the trivial fixes. Adding a seventh
surface whose job is reconciling the other six would be the same mistake with
better intentions.

---

## Is the bundle worth installing

If you want all three: yes, it is one command instead of three and one setup
command instead of three.

If you want one or two: no. Install those directly. The bundle has no content of
its own that you would be missing.

```bash
claude plugin install charter@claude-forge
claude plugin install craft@claude-forge
claude plugin install tars@claude-forge
```

---

## Uninstalling

```bash
claude plugin uninstall forge@claude-forge
claude plugin prune
```

`prune` drops the three dependencies **only** if they were auto-installed by the
bundle and nothing else needs them. If you had installed any of them explicitly
beforehand, that one stays.

Everything Charter wrote into your repositories keeps working either way. It is
standard Claude Code configuration and does not depend on any plugin being
installed.
