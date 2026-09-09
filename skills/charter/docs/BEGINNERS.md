# Charter for beginners

You do not need to read this to use Charter. Run `/charter:init`, answer two questions, accept the diff. This page explains what happened.

## The four mechanisms Charter configures

Claude Code has these built in. Charter's whole job is to set them up correctly, because almost nobody does.

### 1. `CLAUDE.md` — what Claude reads every time

A markdown file in your repository. Claude reads it at the start of every conversation, before you type anything.

Because it loads *every* session, everything in it costs tokens forever. A 200-line CLAUDE.md is not free thoroughness — it is a permanent tax, and past roughly 200 lines Claude follows it *less* reliably, not more.

Charter writes at most 35 lines into it, inside a fence:

```
<!-- charter:start v1 -->
   ...Charter's lines live here and only here...
<!-- charter:end -->
```

Anything you write outside those markers is never touched. Re-running `/charter:init` rewrites only the inside.

### 2. `permissions` — what Claude may do

Rules in `.claude/settings.json`. Unlike CLAUDE.md, these are **enforced**: Claude Code checks them before the model is even consulted, so they hold regardless of what Claude decides.

```json
{
  "permissions": {
    "deny":  ["Bash(git push --force *)", "Read(./.env)"],
    "ask":   ["Bash(git push *)"],
    "allow": ["Bash(npm test *)"]
  }
}
```

Three kinds:
- **deny** — never, no prompt, no argument.
- **ask** — Claude must get your confirmation first.
- **allow** — runs without stopping to ask you.

The order matters: **deny wins over ask, ask wins over allow.** A deny rule cannot have exceptions carved out of it.

The important thing to understand: **only deny and ask protect you.** Allow rules just remove prompts. A settings file with fifty allow rules and no deny rules protects nothing.

### 3. `.claude/rules/` — context that loads only when relevant

A markdown file with a `paths:` header at the top:

```markdown
---
paths:
  - "database/migrations/**"
---
This team applies migrations by hand, not with the framework's command.
```

That text costs **zero tokens** until Claude opens a file under `database/migrations/`. At that moment — exactly when it matters — it arrives.

This is the most under-used feature in Claude Code and the reason your CLAUDE.md can stay at 35 lines instead of growing to 200.

### 4. Auto memory — what Claude notices about you

Claude saves notes to `~/.claude/projects/<your-repo>/memory/` on its own: your corrections, your preferences, project facts it cannot derive from the code.

Two things to know. It is **private to your machine** — your teammates never see it. And nobody ever prunes it, so it accumulates stale notes indefinitely.

`/charter:check` reads it, tells you what is in there, and offers to promote the genuinely useful parts into shared rules files your team gets too.

---

## The questions Charter asks

They are asked in plain words. You do not need to know any of the four mechanisms above to answer them.

**"Who works on this code?"** Decides whether the limits go in a file your teammates share, or a personal file only you have. It also sets the default for the next question.

**"How much should Claude do with Git on its own?"** Git keeps a record of every version of your project, and can upload that record to GitHub so other people get it.

- *Just edit files* — Claude edits and shows you what changed. Nothing goes into the record, nothing is uploaded. Saving and uploading stays your job.
- *Save here only* — Claude can add its work to the record on this computer. Uploading always stops and asks you first, so nothing leaves your machine by surprise.
- *Save and upload* — Claude can add its work and upload it without asking each time. Uploading to your main branch, the copy everyone else uses, still asks first.

Force-push is blocked in all three. That is not negotiable, and it is the one setting worth explaining: force-push is the git command that destroys work other people have already pulled.

**"Can Claude change the database on this computer?"** Only asked if you have migrations. *Look, do not change* is the default: Claude reads what is stored, and anything that would change the structure or delete data stops and asks first. This question is only ever about the copy on your machine — a live database real users depend on is out of reach whatever you pick.

**"Is there anything here Claude should never change?"** Only asked if Charter found deploy scripts or infrastructure directories. Tick whatever you want completely off limits; leaving it all unticked is a normal answer. Passwords and keys are blocked already, so they are not in the list.

---

## Reading `/charter:status`

```
CHARTER   my-app · main · initialised 2026-09-03

✓ Context      31 lines · 2 path-scoped rules
✓ Commands     test, lint verified · no typecheck
✗ Boundaries   0 rules — this repo has no enforced boundaries
✓ Session cost ~520 tokens always loaded (estimate)

Next: /charter:init — set up boundaries
```

`✓` set up. `✗` missing. `⚠` present but flagged.

**Session cost** is what you pay before typing a single word, on every conversation, forever. Under 1,000 is healthy. Past 2,000, run `/charter:check` — it will tell you which lines to cut and why.

---

## Undoing everything

Charter writes native files. Removing it is deleting them:

```bash
# remove the working agreement: delete the charter:start/charter:end block
# remove the boundaries: delete the deny/ask entries in .claude/settings.json
rm .claude/charter.json
rm -r .claude/rules        # only if you want the area rules gone too
/plugin uninstall charter
```

Nothing breaks and nothing is left behind. Equally, you can uninstall the plugin and **keep** everything it wrote — the files are standard Claude Code configuration and work on their own.

---

## Common questions

**Will it change my code?** No. Charter writes configuration files only.

**Will it read my secrets?** No. It records that `.env` exists, by name, and generates a rule blocking it. It never opens the file.

**I already have a CLAUDE.md.** It is preserved in full. Charter adds a fenced block and deduplicates against what is already there.

**Something it wrote is wrong.** Edit the file. They are plain markdown and JSON, they belong to you, and Charter never overwrites content outside its own fence.

**A rule is blocking something I need.** Delete the rule from `.claude/settings.json`. No ceremony required.
