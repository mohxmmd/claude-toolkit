# Compiling answers into boundaries

Read this before generating a single permission rule.

Claude Code's own documentation is explicit: CLAUDE.md is *context, not enforced configuration*. A git, database, or deployment policy written as prose is a suggestion the model may or may not follow. A `permissions` rule is evaluated by the client **before the model is consulted**, so the model cannot talk its way past it.

That distinction governs the vocabulary used everywhere in Charter:

| Tier | Mechanism | Enforced by | Called |
| --- | --- | --- | --- |
| 0 | `sandbox` filesystem / network | The operating system | a **sandbox** |
| 1 | `permissions` deny / ask | The client, before the model | a **boundary** |
| 2 | `PreToolUse` hook | The client, before the tool | a **guard** |
| 3 | A line in the working agreement | Nothing | a **convention** |

Never describe a tier-3 item as a boundary, in generated output or in conversation. Never describe a tier-1 boundary as a sandbox.

**What a tier-1 boundary is not.** It matches command *text*. It stops the model from choosing a denied command and stops an accident from becoming a `git push --force`. It is not containment. A shell that re-enters through `sh -c '<command>'` is one command with a quoted argument, and `sh`/`bash`/`zsh` are not in the wrapper list Claude Code strips before matching, so the inner command is never matched against your rules. Gotcha 12 covers the mitigation. Real containment is tier 0.

---

## The seventeen gotchas

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
`>`, `>>`, `2>` are checked against Edit rules and protected paths. An allow on a command does not license its redirect target. `/dev/null` is exempt. Input redirects (`< file`) are checked against `Read` rules from v2.1.257.

**12. `sh -c` and friends re-enter the shell and are never split.**
`sh -c 'git push origin main'` is one command whose argument happens to be a command. No rule written for `git push` sees it. Neither do `bash -c`, `zsh -c`, `eval`, or `env`. The docs' own table shows `Bash(* --version)` matching `bash -c 'echo hi' --version`, which is the same hole from the other side.
**Always emit the shell re-entry ask block below.** It is the difference between "stops accidents" and "stops accidents and the obvious way around them".

**13. A field-scoped rule is accepted, ignored, and warned about.**
`Bash(command:rm *)` names the tool's primary content field. Claude Code ignores it and warns at startup, because a compound command would bypass it. Same for `Read(file_path:...)`, `Grep(path:...)`, `NotebookEdit(notebook_path:...)`. Write `Bash(rm *)`, `Read(./path)`, `WebFetch(domain:host)`.

**14. An unparseable compound is not split, so no allow rule matches it.**
`npm test &&` with nothing after it is unparseable. `Bash(npm *)` does not approve it and the user is prompted. Never emit a rule that depends on a compound parsing cleanly.

**15. Deny and ask see past any leading assignment. Allow does not.**
`Bash(rm *)` in deny still matches `FOO=bar rm -rf tmp/`. An allow rule only matches past an assignment of a *known-safe* variable. Safety in deny, convenience in allow — the asymmetry is deliberate and in your favour.

**16. `xargs` is stripped only when it has no flags.**
`Bash(grep *)` covers `xargs grep pattern`. It does not cover `xargs -n1 grep pattern`, which matches as an `xargs` command. If `xargs` matters, write the `xargs` rule too.

**17. `*` matches at any position, including before the program.**
`Bash(* --version)` matches `node --version` and also `bash -c 'echo hi' --version`. Never emit a rule whose first character is `*`.

---

## Shell re-entry — always emitted, not a question

The one gap a text matcher cannot close by itself. Emitted in every repo, at `ask` rather than `deny`, because each of these is occasionally the right tool and a prompt is enough to stop it being silent:

```
ask:   Bash(sh -c *)      Bash(bash -c *)    Bash(zsh -c *)
       Bash(eval *)       Bash(env *)
       Bash(watch *)      Bash(setsid *)     Bash(flock *)
```

Do not deny these — a denied `env` breaks ordinary work and teaches the user to disable Charter. Do **not** add a rule for `find -exec`: it already prompts in Manual mode whatever you write, and a rule with `*` before `-exec` trips the startup warning in gotcha 4.

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

### This repo's own destructive commands

The presets above cover the framework's verbs. They do not cover the command this team wrote. `danger.destructive_cmds` carries those: an npm script called `db:reset`, a make target called `db-wipe`, an artisan command called `cms:restore` that truncates rows.

Emit one rule per entry, at the same tier as the preset's own destructive row (`deny` under read-only, `ask` under local-migrations). Show the user each command beside the rule, in their vocabulary:

```
Bash(php artisan cms:restore*)   deny   your own command, from app/Console/Commands
Bash(npm run db:reset*)          deny   your own script, from package.json
```

**Never emit a rule for one of these silently.** The verb match is a heuristic; only the user knows whether `prune` clears a cache or drops a table. A wrong deny here is the fastest way to make someone turn Charter off.

---

## Invocation variants

The matcher is literal-prefix. `Bash(vendor/bin/pint --dirty*)` does not match `./vendor/bin/pint --dirty`, and the user gets prompted for the command Charter just told them was allowed. Half-working allow rules are worse than none.

Expand every generated command rule into all forms that actually resolve:

| Verified as | Also emit |
| --- | --- |
| `vendor/bin/<x>` | `./vendor/bin/<x>` |
| `node_modules/.bin/<x>` | `./node_modules/.bin/<x>`, `npx <x>` |
| `bin/<x>` | `./bin/<x>` |
| `npm run <s>` | `<pm> run <s>` for the detected `stack.node_pm` when it is not npm |

Do not expand into a form the survey did not find. `npx <x>` is emitted only when the binary exists in `node_modules/.bin`, because `npx` on a missing binary downloads and executes from the network.

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

## Sandbox — offered once, never assumed

Tier 0 is the only thing here the operating system enforces. Seatbelt on macOS, seccomp plus bubblewrap on Linux and WSL2. It applies to a Bash command **and every child process it spawns**, so it holds where a text matcher cannot: `sh -c`, a postinstall script, a compromised dependency.

Offer it in Step 6 as a separate accept, never bundled with the boundaries, because it changes how commands run and a surprised user will disable it wholesale.

```json
{
  "sandbox": {
    "enabled": true,
    "network": { "allowedDomains": ["<the package registry for stack.node_pm>", "*.github.com"] },
    "credentials": { "files": [{ "path": "~/.ssh", "mode": "deny" },
                               { "path": "~/.aws/credentials", "mode": "deny" }] }
  },
  "permissions": { "blockReadsOutsideWorkingDirectories": true }
}
```

Rules for generating it:

- **Never emit `filesystem.denyRead` from Charter.** Once managed settings configure `sandbox.filesystem` at all, only managed settings can set it. Use `credentials.files` for secrets and `blockReadsOutsideWorkingDirectories` for the general case. Both survive.
- **Never emit `allowUnsandboxedCommands: false`** without asking. It removes the escape hatch, so a command the sandbox breaks cannot be retried, and the user has no way forward inside Claude Code.
- **Never emit `network.strictAllowlist`.** It has no effect from project or local settings. Say so rather than writing a key that silently does nothing.
- Derive `allowedDomains` from the detected stack: `registry.npmjs.org`, `pypi.org`, `packagist.org`, `proxy.golang.org`, `rubygems.org`, `crates.io`. Add `*.github.com` only when `git.remote_host` is github.
- **Not available on native Windows.** When the platform is Windows and not WSL2, skip the offer entirely rather than writing a key that does nothing.

State the honest version in the report: *"Sandboxed: filesystem and network, enforced by the OS. This is the only layer a shell escape does not get past."*

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

Do not run this by eye. Charter ships it as a script:

```
${CLAUDE_PLUGIN_ROOT}/scripts/lint-rules.sh <the settings file you are about to write>
```

It asserts, and exits non-zero on any failure:

- Every deny and ask rule has a space before any trailing `*`. (gotcha 3)
- No rule starts with `*`, and no rule has a `*` before its subcommand. (4, 17)
- No `Read(./.env.*)` glob — secret files are enumerated, `.env.example` stays readable.
- No bare environment-runner allow: `docker exec`, `npx`, `devbox run`, `mise exec`, `direnv exec`. (6)
- No `Write(...)`, `Glob(...)`, `NotebookEdit(...)`, `MultiEdit(...)` path rule. (8)
- No field-scoped rule: `Bash(command:...)`, `Read(file_path:...)`, `Grep(path:...)`. (13)
- No `defaultMode` key in a project or local file. (10)
- No allow rule is doing safety work: nothing in `allow` also appears in `deny` or `ask`.
- The secrets block is present.
- The shell re-entry ask block is present. (12)
- No `sandbox.filesystem` key, no `network.strictAllowlist`, no unrequested `allowUnsandboxedCommands`.

**Write the file only after the linter passes**, and report its result in Step 7. Two further checks it cannot make, which stay human:

- Every allowed command was actually executed during Step 3.
- `claude doctor` reports no invalid-settings or permission-rule warnings. The linter checks the rules Charter wrote; `doctor` checks what the installed client actually accepted.
