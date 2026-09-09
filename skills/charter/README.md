# Charter

**A charter grants powers and limits them in the same document. So does this.**

Charter is a Claude Code plugin that runs once per repository. It surveys the repo, asks two to four questions the repo cannot answer, and writes two things: a **working agreement** (what Claude knows about this project) and **enforced boundaries** (what Claude may do in it). Then it gets out of the way.

Standing cost afterwards: about **600 tokens per session**. No hooks fire on an ordinary prompt. Nothing rescans.

---

## Why this exists

Claude Code already has the mechanisms — `CLAUDE.md`, `permissions`, path-scoped rules, auto memory. Almost nobody configures them, and two of them are effectively unreachable in practice:

- The good `/init` flow is behind an opt-in environment variable (`CLAUDE_CODE_NEW_INIT=1`). The default is the older single-shot version.
- `/doctor` has to be run by hand, and people run it after something breaks.
- Auto memory works, but it is **machine-local and invisible**. Six developers on one repository accumulate six private, divergent, never-reviewed sets of learnings about the same code.

And the most important gap: **prose is not a safety boundary.** Anthropic's documentation says it plainly — CLAUDE.md is context, not enforced configuration. A "never push to main" line in a markdown file is a suggestion. A `deny` rule is evaluated by the client before the model is consulted.

Charter's job is to apply the correct configuration in one command, make what it costs visible, and move private knowledge into the repository.

---

## Install

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install charter@claude-forge
```

Or load a local checkout directly, which is how the tests run:

```bash
claude --plugin-dir /path/to/claude-toolkit/skills/charter
```

## Quick start

```
/charter:init
```

That is the whole thing. It takes about a minute.

```
/charter:status     what is set up, what it costs, what to do next
/charter:check      drift, context audit, and promotion
```

---

## What the first run does

**1. Surveys.** One shell script, run outside the context window, returning about thirty lines of facts: stack, package manager, commands, CI, existing instruction files, migration and infrastructure directories, secret file *names*. It never opens `.env`, a lockfile, or `node_modules/`.

**2. Reads, within a budget.** Twelve files maximum, existing instruction files first. If the repo is still unclear at twelve, it records what is unknown rather than inventing it.

**3. Verifies.** Every command it is about to write gets executed first. A command that has not run is written as `none`, not guessed at. This is the difference between an instruction file and a wish.

**4. Asks two to four questions.** Each is suppressed when the repo already answers it, and pre-selected from what the survey found.

| Question | Skipped when |
| --- | --- |
| Who works on this code? | Never, but pre-selected from author count |
| How much should Claude do with Git on its own? | Never — no repo can answer this |
| Can Claude change the database on this machine? | No migrations or database tooling found |
| Anything here Claude should never change? | No deploy tooling or infrastructure found |

Every question is asked in plain words, and every option describes what happens to you rather than the setting it writes — *"uploading always asks you first"*, not *"adds an `ask` rule for `Bash(git push *)`"*. Answering requires no knowledge of permission rules, and the wording is fixed in [`references/questions.md`](references/questions.md) rather than improvised per run.

Not asked, because a safe default is obvious: production confirmation (always required), secrets (always denied), branch naming, commit message style, whether to run tests.

**5. Shows a diff.** Nothing is written until you say yes. The diff is also the tutorial — for most people it is the first time they see permission syntax, annotated, applied to their own repository.

---

## What it writes

| Artifact | Native mechanism | Cost per session | Enforced? |
| --- | --- | --- | --- |
| Working agreement, ≤35 lines | `CLAUDE.md`, inside a fence | ~400 tokens | No — guidance |
| Boundaries | `.claude/settings.json` permissions | 0 | **Yes** — client-side |
| Area rules | `.claude/rules/*.md` with `paths:` | 0 until a matching file is opened | No — guidance |
| State | `.claude/charter.json` | 0 — never auto-loaded | n/a |

Everything Charter writes is a **native, hand-editable file**. There is no Charter configuration format. Delete the fence and the boundaries remain; delete the boundaries and the agreement remains. Uninstalling the plugin leaves your setup working.

---

## `/charter:check` — the part you keep it for

Init is the one-time hook. Check is the recurring value. Three passes:

**Drift.** Re-runs the recorded commands. Stats every path the always-loaded files name. Compares the manifest hash. A test command that stopped working is the highest-signal drift indicator there is, and the most common cause of an agent quietly working around a broken instruction.

**Context audit.** Reports what this repo costs on every session, forever, and what of it can go: a directory tree the model can derive, a rules file with no `paths:` key paying tokens for something that matters in one directory, a CLAUDE.md past the length where adherence drops, two always-loaded files that contradict each other.

**Promotion.** Reads what auto memory has quietly accumulated and offers to move the durable, area-specific parts into committed path-scoped rules — so your teammates get them too. Deletes what has gone stale. Leaves personal preferences alone. Nothing is promoted without showing the exact text first.

---

## What it deliberately does not do

- **No memory store.** Auto memory is native and works. Charter curates it rather than competing with it.
- **No per-prompt hook.** The best-known prompt-coaching implementation costs about 189 tokens on *every* prompt — roughly 2.8% of a 200k window across a session — to catch a minority case. Charter replaces it with one line in the working agreement.
- **No tips engine.** A tip is useful once and irritating the fourth time, and there is no reliable signal for which is which.
- **No scaffolding.** Every ecosystem has a better project generator.
- **No workflow.** Charter does not own your development loop. If you use Superpowers or Compound Engineering, they should win — Charter is a different layer.

---

## Requirements

POSIX shell and git. `jq` is used when present and not required. Works on macOS, Linux, WSL, and Windows with Git Bash. No network, no MCP servers, no other plugins.

## Documentation

- [Beginners](docs/BEGINNERS.md) — what each generated file is, in plain terms
- [Safety model](docs/SAFETY.md) — the three tiers, and **what the boundaries do not protect against**
- [Configuration](docs/CONFIG.md) — hand-editing, silencing, and uninstalling cleanly

## Contributing

Charter's claims are numbers, so a change has to move a number or fix a failure
somebody actually watched happen. See [CONTRIBUTING.md](CONTRIBUTING.md) for the
gates and for how to add a case to the permission corpus.

Charter lives in [mohxmmd/claude-toolkit](https://github.com/mohxmmd/claude-toolkit) alongside
[CRAFT](../craft/README.md) and [TARS](../../output-styles/README.md). The three are
independent and usable separately. Issues and pull requests go to that
repository.

## License

Apache-2.0. See [LICENSE](../../LICENSE).

A charter is a founding document that grants powers and limits them in the same
breath. That is the product in one word.
