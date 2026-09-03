# Claude Toolkit

**Three tools for Claude Code, maintained by Mohammed.**

Each one fixes a different failure. None depends on the others. Install one, or
all three.

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
```

| | What it fixes | Install |
|---|---|---|
| **[Craft](skills/craft/README.md)** | Ask any AI to improve a screen and it regenerates it. Craft changes the smallest thing that fixes the problem and tells you what it left alone. | `claude plugin install craft@claude-toolkit` |
| **[Charter](skills/charter/README.md)** | A rule written in prose is a suggestion. Charter turns a two-minute interview into a working agreement *and* enforced permission boundaries. | `claude plugin install charter@claude-toolkit` |
| **[TARS](output-styles/README.md)** | Claude agreeing with you is pleasant and occasionally expensive. TARS answers first, in a line or two, and tells you when you are wrong. | `./install.sh` |

Craft and Charter are **skills** — you invoke them by name. TARS is an **output
style** — it changes every response until you switch it off. That difference is
why TARS installs differently, and it is the only thing you need to know to pick
what you want.

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
./install.sh     # then /config -> Output style -> TARS -> /clear
```

**Install it as a file, not a plugin.** Claude Code's docs describe plugins
shipping output styles, and TARS ships a valid manifest for the day that works,
but on 2.1.112 a plugin-bundled output style installs cleanly and then never
appears in `/config`. The installer puts the file where every version reads it.
The test is written up in
**[output-styles/README.md](output-styles/README.md#compatibility)**.

**[Read more](output-styles/README.md)**

---

## Install

### Simple

Add the marketplace once, then install what you want.

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install craft@claude-toolkit
claude plugin install charter@claude-toolkit
```

For TARS, clone and run the installer. It copies one file into
`~/.claude/output-styles/` and backs up anything already there.

```bash
git clone https://github.com/mohxmmd/claude-toolkit.git
cd claude-toolkit
./install.sh
```

Then `/config` → **Output style** → **TARS** → `/clear`. Output styles load at
session start, so the `/clear` matters.

### Advanced

**Run a plugin from a local checkout** — no marketplace, no install step. This is
how the tests run and how you try a change before committing it.

```bash
claude --plugin-dir /path/to/claude-toolkit/skills/craft
claude --plugin-dir /path/to/claude-toolkit/skills/charter
```

**Install TARS somewhere else**, for one project rather than every project:

```bash
./install.sh --dir /path/to/project/.claude/output-styles
```

**Install TARS without cloning**, one file over the network:

```bash
mkdir -p ~/.claude/output-styles
curl -fsSL https://raw.githubusercontent.com/mohxmmd/claude-toolkit/main/output-styles/TARS.md \
  -o ~/.claude/output-styles/TARS.md
```

**Configure a plugin.** Craft and Charter both declare `userConfig` in their
manifests, so `/plugin` exposes their settings in the UI. Craft additionally
reads a per-project `.craft/config.md`, which is the file you edit by hand.
See [docs/craft/configuration.md](docs/craft/configuration.md) and
[Charter's config guide](skills/charter/docs/CONFIG.md).

**Fork a component.** Each of the three is a self-contained directory with its
own manifest, changelog and tests. Copy the one you want out of this repo and it
keeps working.

## Using them together

They do not know about each other, and nothing breaks if you run one alone. In
practice they stack in the order you meet a project:

1. **Charter** once, when you open a repository for the first time. It writes the
   working agreement and the permission boundaries.
2. **Craft** whenever a screen needs work. It respects the boundaries Charter
   wrote, because those are enforced by Claude Code, not by Craft.
3. **TARS** always on, if you want shorter answers and to be told when you are
   wrong.

Worked sequences are in [examples/](examples/README.md).

## What is in this repository

| Path | What it is |
|---|---|
| `skills/craft/` | The Craft plugin: skills, router, references, scripts, evals |
| `skills/charter/` | The Charter plugin: skills, references, scripts, templates, tests |
| `output-styles/` | The TARS output style, its manifest, changelog and contributing guide |
| `install.sh` | The TARS installer. Copies `output-styles/TARS.md` into `~/.claude/` |
| `docs/` | Long-form documentation for Craft and TARS |
| `examples/` | Worked command sequences |
| `.claude-plugin/marketplace.json` | The marketplace manifest listing all three |

Craft's changelog is [CHANGELOG.md](CHANGELOG.md) at the root, because its
release tooling reads it there. Charter and TARS keep their own, beside their
code.

## Requirements

Claude Code 2.x. Craft's scripts need Node 20 or newer; Charter's need a POSIX
shell and git, and use `jq` when it is present without requiring it. Both work on
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
