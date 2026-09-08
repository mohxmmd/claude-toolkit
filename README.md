# Claude Toolkit

**Three tools for Claude Code, maintained by Mohammed.**

Each one fixes a different failure. None depends on the others. Install one, or
all three at once.

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install toolkit@claude-toolkit
```

| | What it fixes | Install just this |
|---|---|---|
| **[Craft](skills/craft/README.md)** | Ask any AI to improve a screen and it regenerates it. Craft changes the smallest thing that fixes the problem and tells you what it left alone. | `claude plugin install craft@claude-toolkit` |
| **[Charter](skills/charter/README.md)** | A rule written in prose is a suggestion. Charter turns a two-minute interview into a working agreement *and* enforced permission boundaries. | `claude plugin install charter@claude-toolkit` |
| **[TARS](output-styles/README.md)** | Claude agreeing with you is pleasant and occasionally expensive. TARS answers first, in a line or two, and tells you when you are wrong. | `claude plugin install tars@claude-toolkit` |

Craft and Charter are **skills** — you invoke them by name. TARS is an **output
style** — it changes every response until you switch it off. That difference is
the only thing you need to know to pick what you want.

**[Toolkit](bundles/toolkit/README.md)** is a fourth plugin that installs all
three and gives you `/toolkit:setup` to wire them up. It contains nothing else.

New here? **[docs/SETUP.md](docs/SETUP.md)** is the install-and-configure guide.
Forking it? **[docs/PUBLISHING.md](docs/PUBLISHING.md)** is how to get your copy
onto GitHub.

---

## Craft

**Improve existing SaaS interfaces without losing the product's identity.**

For products that already exist and already have users. Craft reads your
product's own conventions, diagnoses what is actually wrong, makes the smallest
change that fixes it, proves the change worked, and says plainly what it
deliberately left alone.

Preservation is mechanical rather than hopeful: a ledger of
`preserve` / `improve` / `uncertain` / `forbidden`, and a six-axis change budget
that can be exceeded only deliberately and out loud. On both default postures the
brand axis is zero, so fonts, brand colours and navigation identity do not move
unless you ask.

```
/craft make the settings page easier to scan     improve something
/craft diagnose resources/views/tickets          audit only, never edits
/craft:atlas                                     read the product, write .craft/config.md
```

Not for greenfield design. **[Read more](skills/craft/README.md)**

---

## Charter

**A charter grants powers and limits them in the same document. So does this.**

Runs once per repository. Surveys the repo, asks two to four questions the repo
cannot answer itself, then writes a working agreement into `CLAUDE.md` and
*enforced* boundaries into settings. Afterwards it gets out of the way: about 600
resident tokens per session, no hooks on an ordinary prompt, nothing rescans.

The distinction it exists for: `CLAUDE.md` is context, not enforced
configuration. "Never push to main" in a markdown file is a suggestion. A `deny`
rule is evaluated before the model is consulted.

```
/charter:init       the whole thing, about a minute
/charter:status     what is set up, what it costs, what to do next
/charter:check      drift, context audit, and promotion
```

**[Read more](skills/charter/README.md)**

---

## TARS

**A no-BS engineering partner.**

An output style rather than a skill, so it changes every response rather than
waiting to be invoked. Answer first in a line or two, details second, and only
the details that change what you do next. It corrects a false premise before
carrying out the task, and it separates what it *verified* from what it merely
*wrote*.

```bash
claude plugin install tars@claude-toolkit
# then /config -> Output style -> tars:TARS -> /clear
```

**Mind the name.** A plugin install is selected as **`tars:TARS`**; the file
install below is plain **`TARS`**. Claude Code namespaces plugin-provided output
styles, both installs can coexist, and a setting naming one will not find the
other. Verified on 2.1.197 with a negative control, written up in
**[output-styles/README.md](output-styles/README.md#compatibility)**.

*(An earlier version of this README said not to install TARS as a plugin,
because on 2.1.112 it installed and then never appeared. That was true when
written and no longer is.)*

**[Read more](output-styles/README.md)**

---

## Install

Full guide: **[docs/SETUP.md](docs/SETUP.md)**. The short version:

### Everything

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install toolkit@claude-toolkit
```

Restart Claude Code, then `/toolkit:setup` in the repository you want set up.

### One thing

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install charter@claude-toolkit    # or craft, or tars
```

Restart. Plugins load at session start, so nothing you just installed exists in
the session you typed it into.

### Advanced

**Run a plugin from a local checkout** — no marketplace, no install step. This is
how the tests run and how you try a change before committing it.

```bash
claude --plugin-dir /path/to/claude-toolkit/skills/craft
claude --plugin-dir /path/to/claude-toolkit/skills/charter
```

The `toolkit` bundle is the one exception: it declares dependencies, and Claude
Code silently disables a plugin whose dependencies cannot resolve. Load the three
components directly instead.

**Install TARS as a plain file**, with no marketplace at all:

```bash
./install.sh                                             # ~/.claude/output-styles/
./install.sh --dir /path/to/project/.claude/output-styles  # one project only
```

Selected as **`TARS`** rather than `tars:TARS`. A committed project-level copy
gives a whole team the same style.

**Configure a plugin.** Charter and Craft both declare `userConfig`, so `/plugin`
exposes their settings in the UI. Craft additionally reads a per-project
`.craft/config.md`, which is the file you edit by hand. See
[docs/craft/configuration.md](docs/craft/configuration.md) and
[Charter's config guide](skills/charter/docs/CONFIG.md).

**Fork a component.** Each of the three is a self-contained directory with its
own manifest, changelog and tests. Copy the one you want out of this repo and it
keeps working — which is exactly why none of them declares the others as a
dependency. Publishing your own copy: [docs/PUBLISHING.md](docs/PUBLISHING.md).

## Using them together

Nothing breaks if you run one alone. In practice they stack in the order you
meet a project:

1. **Charter** once, when you open a repository for the first time. It writes the
   working agreement and the permission boundaries.
2. **Craft** whenever a screen needs work. It respects the boundaries Charter
   wrote, because those are enforced by Claude Code, not by Craft.
3. **TARS** always on, if you want shorter answers and to be told when you are
   wrong.

`/charter:init` knows how to connect the other two, and this is the one place
they touch. If Craft or TARS is **already installed**, it offers — once, in a
repository where they exist — to set TARS as your output style and add a
one-line pointer at `/craft` in the working agreement. Both are shown in the
diff, both can be declined, and a decline is remembered.

Three things it will not do:

- **Install anything.** It offers what is present and nothing else.
- **Commit your output style.** `outputStyle` always goes to
  `.claude/settings.local.json`, even when your boundaries go to the committed
  file. Permission limits are a team decision; how Claude talks to you is not.
- **Require either of them.** Charter declares no dependency on Craft or TARS, so
  a vendored copy of `skills/charter/` keeps working on its own. That
  independence is why the "install all three" coupling lives in a separate
  [bundle plugin](bundles/toolkit/README.md).

Turn it off entirely with Charter's `companions: off`. Details and the reasoning:
[docs/charter/companions.md](docs/charter/companions.md).

Worked sequences are in [examples/](examples/README.md).

## What is in this repository

| Path | What it is |
|---|---|
| `skills/craft/` | The Craft plugin: skills, router, references, scripts, evals |
| `skills/charter/` | The Charter plugin: skills, references, scripts, templates, tests |
| `output-styles/` | The TARS output style, its manifest, changelog and contributing guide |
| `bundles/toolkit/` | The bundle plugin: a manifest of dependencies and `/toolkit:setup` |
| `install.sh` | The TARS file installer. Copies `output-styles/TARS.md` into `~/.claude/` |
| `docs/` | Long-form documentation, plus the setup and publishing guides |
| `examples/` | Worked command sequences |
| `.claude-plugin/marketplace.json` | The marketplace manifest listing all four |

Craft's changelog is [CHANGELOG.md](CHANGELOG.md) at the root, because its
release tooling reads it there. The other three keep their own, beside their
code.

## Requirements

Claude Code 2.x for the file installs; **2.1.197 or newer** for the plugin
install of TARS, which is where plugin-provided output styles were verified
working. Craft's scripts need Node 20 or newer; Charter's need a POSIX shell and
git, and use `jq` when it is present without requiring it. Everything works on
macOS, Linux and WSL.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The short version: every addition is paid
for on every task that loads it, so a pull request should say what it costs and
which observed failure it fixes.

Each component has its own bar on top of that:
[Craft](CONTRIBUTING.md) · [Charter](skills/charter/CONTRIBUTING.md) ·
[TARS](output-styles/CONTRIBUTING.md). TARS is a behavioural prompt rather than
code, so a change to it needs a transcript instead of an argument.

## Author

Created and maintained by **Mohammed** ([@mohxmmd](https://github.com/mohxmmd)).

Licensed under [Apache 2.0](LICENSE).
