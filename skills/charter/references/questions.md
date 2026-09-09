# Asking the setup questions

Read before the `AskUserQuestion` call in Step 4 of `/charter:init`. This file is the wording; [SKILL.md](../skills/init/SKILL.md) decides which questions survive suppression.

A person running `/charter:init` is often two days into Claude Code. They know what their project is. They do not know what a permission rule, an output style, or a path-scoped rule is, and a question that assumes otherwise gets a confident wrong answer rather than a request for clarification. Wrong answers here are written into enforced settings, so the wording is not cosmetic.

## The questions

Say them this way unless the repo forces a change. The header is the short chip, the bold text is the option label, and the sentences after the dash are the option description. Where a question has a context line, put it under the question so it is read before the options.

**Q1** — header `Who codes`

> **Who works on this code?**
>
> - **Just me** — Your choices get saved in a private file on this computer. Nobody else ever sees them, and nothing is added to the project itself.
> - **Me and a team** — Your choices get saved inside the project, so everyone who downloads it starts with the same limits without setting anything up.
> - **Public / open source** — People you do not know can send in changes, so Claude sticks to the most careful settings.

**Q2** — header `Git`

> **How much should Claude do with Git on its own?**
>
> *Git keeps a record of every version of your project, and can upload that record to GitHub so other people get it.*
>
> - **Just edit files** — Claude edits files and shows you what it changed. It never adds anything to the record and never uploads. Saving and uploading stays your job.
> - **Save here only** — Claude can add its work to the record on this computer. Uploading anywhere always stops and asks you first, so nothing leaves your machine by surprise.
> - **Save and upload** — Claude can add its work to the record and upload it without asking each time. Uploading to your main branch, the copy everyone else uses, still asks first.
>
> Always add one closing line: *Whichever you pick, Claude can never force-push. That is the one Git command that can wipe out work other people already have.*

Say "the record of your project", not "history" or "commits"; "upload", not "push" — and name whichever host `git.remote_host` reports rather than saying GitHub by reflex. When `git.remote_host: none`, drop the uploading half of every option instead of describing something that cannot happen here.

**Q3** — header `Database`

> **Can Claude change the database on this computer?**
>
> *This is only about the copy on your own machine. Nothing here lets Claude near a live database that real users depend on.*
>
> - **Look, do not change** — Claude can read what is stored. Anything that would change the structure or delete data stops and asks you first.
> - **Change this copy freely** — Claude can update your local database without asking each time. Faster while building, and your live data is still out of reach.
> - **Stay out completely** — Claude runs no database commands at all, not even to look at what is there.

When `danger.destructive_cmds` is non-empty, name those commands inside this question rather than adding a fifth. Same decision, and the user recognises `cms:restore` faster than they recognise "database autonomy". Say what each one does to them, in one clause:

> This also covers `php artisan cms:restore`, which empties your database and fills it again from scratch.

**Q4** — header `Off limits`, multi-select

> **Is there anything here Claude should never change?**
>
> *Tick whatever you want completely off limits. Leaving everything unticked is a normal answer.*
>
> One checkbox per entry in `danger.paths`, labelled with the path and described by what it does for the person, not by what kind of file it is:
>
> - **`deploy/`** — the scripts that push your site live for real users.
> - **`terraform/`** — the setup for your servers and cloud accounts.
> - **`.github/workflows/`** — the checks that run automatically every time the code changes.
>
> Close with one line: *Passwords and keys (your `.env` files) are blocked already, so they are not in this list.*

## Wording rules

- Labels stay under five words and carry no jargon. The description does the explaining, in one or two short sentences — enough that nobody has to guess, short enough to read in a terminal.
- Every option says what happens to the user, not which setting it writes: "uploading always asks you first", never "adds an `ask` rule for `Bash(git push *)`".
- No Charter vocabulary in a question: not *boundary*, *permission rule*, *scope*, *preset*, *autonomy*, *path-scoped*, *tier*. Those appear in the Step 6 diff, annotated, where there is room to explain them.
- Explain a technical word the first time it appears, in the same breath, or do not use it. Assume the person does not know what a branch, a migration, or a commit is.
- Name the reassurance out loud when there is one. "Your live database is never touched" and "force-push is blocked either way" are the sentences that let someone answer without fear of breaking something.
- One idea per option. If an option needs three clauses to explain, it is two options, or the split is wrong.
- Never make the safe answer sound like the timid one. `Look, do not change` is the default because it is right, not because the user is new.

Wording is the only thing this file governs. The answer keys recorded in `charter.json` and the preset each answer selects in [policy.md](policy.md) are unchanged: `collab` is `solo` / `team` / `open-source`, `git` is `propose-only` / `local-commits` / `full`, `db` is `read-only` / `local-migrations` / `no-access`.
