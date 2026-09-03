# skills

**Claude Code plugins, maintained by Mohammed.**

Three of them. Each fixes a different failure, none depends on the others, and
each is documented in its own directory.

```bash
claude plugin marketplace add mohxmmd/skills
```

| | What it fixes | Install |
|---|---|---|
| **[CRAFT](craft/README.md)** | Ask any AI to improve a screen and it regenerates it. CRAFT changes the smallest thing that fixes the problem and tells you what it left alone. | `claude plugin install craft@skills` |
| **[CHARTER](charter/README.md)** | A rule written in prose is a suggestion. CHARTER turns a two-minute interview into a working agreement *and* enforced permission boundaries. | `claude plugin install charter@skills` |
| **[TARS](tars/README.md)** | Claude agreeing with you is pleasant and occasionally expensive. TARS answers first, in a line or two, and tells you when you are wrong. | `cd tars && ./install.sh` |

---

## CRAFT

**Improve existing SaaS interfaces without losing the product's identity.**

For products that already exist and already have users. CRAFT reads your
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
```

Not for greenfield design. **[Read more](craft/README.md)**

---

## CHARTER

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

**[Read more](charter/README.md)**

---

## TARS

**A no-BS engineering partner.**

An output style rather than a skill, so it changes every response rather than
waiting to be invoked. Answer first in a line or two, details second, and only
the details that change what you do next. It corrects a false premise before
carrying out the task, and it separates what it *verified* from what it merely
*wrote*.

```bash
cd tars && ./install.sh     # then /config -> Output style -> TARS
```

**Install it as a file, not a plugin.** Claude Code's docs describe plugins
shipping output styles, and TARS ships a valid manifest for the day that works,
but on 2.1.112 a plugin-bundled output style installs cleanly and then never
appears in `/config`. The installer puts the file where every version reads it.
The test is written up in **[tars/README.md](tars/README.md#compatibility)**.

**[Read more](tars/README.md)**

---

## What is in this repository

| Path | What it is |
|---|---|
| `craft/` | The CRAFT plugin: skills, router, references, scripts, evals |
| `charter/` | The CHARTER plugin: skills, references, scripts, docs |
| `tars/` | The TARS output style, its installer, and its docs |
| `docs/` | CRAFT's long-form documentation |
| `.claude-plugin/marketplace.json` | The marketplace manifest listing all three |

CRAFT's changelog is [CHANGELOG.md](CHANGELOG.md) at the root, because its
release tooling reads it there. CHARTER and TARS keep their own, in their own
directories.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The short version: every addition is paid
for on every task that loads it, so a pull request should say what it costs and
which observed failure it fixes.

TARS is a behavioural prompt rather than code, so a change to it needs a
transcript instead of an argument. See
[tars/CONTRIBUTING.md](tars/CONTRIBUTING.md).

## Author

Created and maintained by **Mohammed**.

Licensed under [Apache 2.0](LICENSE).
