# Compiling answers into boundaries

Read this before generating a single permission rule.

Claude Code's own documentation is explicit: CLAUDE.md is *context, not enforced configuration*. A git, database, or deployment policy written as prose is a suggestion the model may or may not follow. A `permissions` rule is evaluated by the client **before the model is consulted** and cannot be argued around.

That distinction governs the vocabulary used everywhere in Charter:

| Tier | Mechanism | Binding? | Called |
| --- | --- | --- | --- |
| 1 | `permissions` deny / ask | Yes, client-side | a **boundary** |
| 2 | `PreToolUse` hook | Yes, client-side | a **guard** |
| 3 | A line in the working agreement | No | a **convention** |

Never describe a tier-3 item as a boundary, in generated output or in conversation.

---

## The eleven gotchas

A generator that ignores these emits rules that look correct and match nothing. Each one is a real behaviour of the permission matcher.

**1. Order is deny → ask → allow. First match wins. Specificity is irrelevant.**
A broad deny cannot carry allowlist exceptions. `deny: Bash(aws *)` blocks `aws s3 ls` even with an explicit allow for it. Design deny rules to be exactly as wide as intended, never wider with exceptions bolted on.

**2. A trailing ` *` also matches the bare command.**
`Bash(git push *)` catches plain `git push` as well as `git push origin main`. Correct, and easy to assume otherwise and add a redundant second rule.

**3. The space before the trailing `*` is part of the rule.**
`Bash(ls *)` requires a space, so it does not match `lsof`. `Bash(ls*)` has no space and **does** match `lsof`. Always emit the space. Never emit the no-space form.

**4. A wildcard before the subcommand is dangerous.**
`Bash(git * main)` matches `git -c core.fsmonitor=<script> diff main` — arbitrary execution through a config override. Claude Code warns about this at startup. Put the `*` after the subcommand, always.

**5. Compound commands split and each part must match independently.**
Separators: `&& || ; | & |&` and newlines. `Bash(safe-cmd *)` does not license `safe-cmd && rm -rf /`. Never try to match a compound string; match each command you mean.

**6. Some wrappers are stripped, and the dangerous ones are not.**
Stripped before matching: `timeout time nice nohup stdbuf command builtin noglob`, bare `xargs`, and a leading assignment of a known-safe environment variable. **Not stripped:** `docker exec`, `npx`, `devbox run`, `mise exec`, `direnv exec`, `watch`, `setsid`, `flock`, and `find -exec`.
Consequence: `allow: Bash(docker exec *)` permits anything inside the container. **Never emit a bare environment-runner allow.** Emit runner-plus-inner pairs: `Bash(docker exec app npm test)`.

**7. A `Read()` deny also blocks Edit and Write on that path.**
It does not cover `NotebookEdit`. Where notebooks exist, add an `Edit()` deny too.

**8. Path rules for `Write`, `NotebookEdit`, `Glob`, `MultiEdit` are accepted and never consulted.**
Claude Code warns at startup and ignores them. Use `Edit(path)` in place of all the write-side ones, and `Read(path)` in place of `Glob(path)`.

**9. Project `allow` rules wait for workspace trust. `deny` and `ask` apply immediately.**
So safety must live in deny and ask. Never rely on an allow rule to constrain anything — allow rules only remove prompts, they never add protection.

**10. `permissions.defaultMode` values `auto` and `bypassPermissions` do not take effect from project or local settings.**
Never emit them there.

**11. Output redirection targets are checked as file writes.**
`>`, `>>`, `2>` are checked against Edit rules and protected paths. An allow on a command does not license its redirect target. `/dev/null` is exempt.

---

## Git presets

Chosen by question 2. Substitute the real default branch from `git.default_branch`.

### Propose only
*Default for open source and for any repo where the answer is unclear.*

```
deny:  Bash(git push *)
       Bash(git reset --hard *)
       Bash(git config *)
ask:   Bash(git commit *)
       Bash(git checkout -b *)
allow: Bash(git status *)  Bash(git diff *)  Bash(git log *)  Bash(git show *)
```

### Local commits
*Default for team repos.*

```
deny:  Bash(git push --force *)
       Bash(git push * --force*)
       Bash(git push * <default-branch>)
       Bash(git config *)
ask:   Bash(git push *)
allow: Bash(git commit *)  Bash(git add *)  Bash(git checkout -b *)
       Bash(git status *)  Bash(git diff *)  Bash(git log *)  Bash(git show *)
```

### Full
*Solo repos, and only when explicitly chosen.*

```
deny:  Bash(git push --force *)
       Bash(git push * --force*)
ask:   Bash(git push * <default-branch>)
allow: commit, add, checkout -b, push to non-default branches, plus the read-only set
```

**Force-push is denied in all three, including Full.** It is the one git operation that destroys other people's work, and a developer who genuinely needs it can run it in their own terminal. `git config` is denied outside Full because it can rewrite hooks and aliases into arbitrary execution.

---

## Database presets

Ask question 3 only when `danger.db_tooling` or `danger.paths` shows a database surface. Emit only the commands for the stack actually detected.

### Read only — the default

```
ask:   <the stack's migrate command>       e.g. Bash(php artisan migrate*)
       <the stack's seed command>
deny:  <destructive resets>
```

Per stack:

| `danger.db_tooling` | ask | deny |
| --- | --- | --- |
| `laravel-artisan` | `Bash(php artisan migrate*)` `Bash(php artisan db:*)` | `Bash(php artisan migrate:fresh*)` `Bash(php artisan migrate:reset*)` `Bash(php artisan db:wipe*)` |
| `prisma` | `Bash(npx prisma migrate*)` `Bash(npx prisma db push*)` | `Bash(npx prisma migrate reset*)` `Bash(npx prisma db push * --accept-data-loss*)` |
| `django` | `Bash(python manage.py migrate*)` | `Bash(python manage.py flush*)` |
| `rails` | `Bash(rails db:migrate*)` `Bash(bin/rails db:migrate*)` | `Bash(rails db:drop*)` `Bash(rails db:reset*)` |
| `alembic` | `Bash(alembic upgrade*)` | `Bash(alembic downgrade base*)` |
| `node-orm` | `Bash(npx knex migrate:*)` `Bash(npx drizzle-kit push*)` | `Bash(npx knex migrate:rollback --all*)` |

### Local migrations allowed
Same denies. Migration commands move from `ask` to `allow`. Destructive resets stay denied. Keep `ask` on seeders that touch existing rows.

### No database access
Add `deny: Bash(mysql *) Bash(psql *) Bash(mongosh *) Bash(redis-cli *)`.

**Production is never a question.** Every preset denies commands carrying a production marker.

---

## Deployment

Ask question 4 only when `danger.paths` shows deploy tooling. The default in every case, without asking: **preparing a deploy is allowed, executing one is not.**

```
deny:  Bash(terraform apply*)  Bash(terraform destroy*)  Bash(pulumi up*)
       Bash(kubectl delete*)   Bash(helm upgrade*)       Bash(helm delete*)
       Bash(flyctl deploy*)    Bash(vercel * --prod*)    Bash(eb deploy*)
       Bash(serverless deploy*)
       plus any npm script / composer script / make target matching deploy|release|publish|ship
allow: Bash(terraform plan*)  Bash(terraform validate*)
       Bash(kubectl get*)     Bash(kubectl describe*)    Bash(docker build*)
```

Staging targets move from deny to `ask` only on an explicit opt-in.

---

## Secrets — not a question, not configurable

Always emitted, in every repo:

```
deny:  Read(./**/*.pem)  Read(./**/id_rsa*)  Read(./**/*.key)
       Read(./**/*credentials*.json)  Read(./**/*.tfvars)
```

Then **one deny per filename listed in `danger.secret_files`**:

```
deny:  Read(./.env)  Read(./.env.local)  Read(./.env.production)
```

**Do not emit `Read(./.env.*)`.** That glob also matches `.env.example`, and adding a new variable to the example file is normal work that Charter's own secrets rule template instructs. Deny rules cannot carry exceptions (gotcha 1), so a blanket glob cannot be narrowed afterwards — enumerate instead.

`danger.secret_templates` lists the files that must stay readable: `.env.example`, `.env.sample`, `.env.template`, `.env.dist`. Never deny these.

The survey records **names only** and never opens any of these files; every rule is generated from the filename.

---

## Always allow

Emit these so the common loop stops prompting. Take the actual commands from the verified set — never write one that was not executed during init.

```
allow: <verified test command>
       <verified lint command>
       <verified typecheck command>
       <verified build command>
       Bash(git status *)  Bash(git diff *)  Bash(git log *)
```

---

## Scope

| Q1 answer | File | Why |
| --- | --- | --- |
| team, open source | `.claude/settings.json` | Committed, so every teammate inherits the same boundaries |
| solo | `.claude/settings.local.json` | Personal and untracked; local allow rules also skip the workspace-trust step |

If the file already exists, **merge** — never overwrite. Claude Code combines list keys across scopes, so an added entry never removes an existing one. Show the merged result in the diff.

---

## Self-check before writing

- Every deny and ask rule has a space before any trailing `*`.
- No `Read(./.env.*)` glob — secret files are enumerated, and `.env.example` stays readable.
- No rule has a `*` before its subcommand.
- No bare environment-runner allow (`docker exec`, `npx`, `devbox run`, `mise exec`).
- No `Write(...)`, `Glob(...)`, `NotebookEdit(...)`, or `MultiEdit(...)` path rules.
- No `defaultMode` key.
- No allow rule is doing safety work.
- Every allowed command was actually executed during init.
- The secrets block is present.

After writing, the user can confirm the file parses with `claude doctor` — no invalid-settings or permission-rule warnings should appear.
