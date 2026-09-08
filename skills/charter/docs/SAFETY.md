# Safety model

## Four tiers, and the words matter

| Tier | Mechanism | Enforced by | Charter calls it |
| --- | --- | --- | --- |
| 0 | `sandbox` filesystem / network | The operating system, for a command and all its children | a **sandbox** |
| 1 | `permissions` deny / ask rules | The client, before the model is consulted | a **boundary** |
| 2 | `PreToolUse` hook | The client, before the tool call | a **guard** |
| 3 | A line in `CLAUDE.md` | Nothing | a **convention** |

Anthropic's documentation is explicit that tier 3 is not enforcement: *"Claude treats them as context, not enforced configuration. To block an action regardless of what Claude decides, use a PreToolUse hook."*

Charter never describes a tier-3 item as a boundary, and never describes a tier-1 boundary as a sandbox. If you see it do either, that is a bug worth reporting.

**Tier 1 matches command text. Tier 0 does not.** That difference is the whole of the next-to-last section, and it is the reason `/charter:init` offers the sandbox separately rather than assuming it.

---

## What each preset writes

### Git

| Preset | Denied | Prompts | Allowed |
| --- | --- | --- | --- |
| **Propose only** | push, `reset --hard`, `git config` | commit, branch creation | read-only git |
| **Local commits** | force-push (both spellings), push to the default branch, `git config` | push | commit, add, branch, read-only git |
| **Full** | force-push (both spellings) | push to the default branch | everything else |

Force-push is denied in **all three presets, including Full.** It is the one git operation that destroys other people's work. A developer who genuinely needs it can run it in their own terminal — that is a deliberate friction, not an oversight.

`git config` is denied outside Full because it can rewrite hooks and aliases into arbitrary code execution.

### Database

Read-only is the default. Migration and seed commands prompt. Destructive resets — `migrate:fresh`, `migrate:reset`, `db:wipe`, `prisma migrate reset`, `db push --accept-data-loss`, `rails db:drop`, `manage.py flush` — are denied outright in every preset, including the permissive one.

### Deployment

Preparing a deploy is allowed. Executing one is not. `terraform plan` and `validate` run freely; `apply` and `destroy` are denied. Same split for `kubectl get`/`describe` versus `delete`, and for `docker build` versus any deploy command.

### Secrets

Not a question and not configurable. `*.pem`, `id_rsa*`, `*.key`, `*credentials*.json` and `*.tfvars` are denied to `Read`, which also blocks `Edit` and `Write` on the same paths.

Real `.env` files are denied **by name, one rule each** — `Read(./.env)`, `Read(./.env.production)`. Charter never writes `Read(./.env.*)`. That glob also matches `.env.example`, and adding a variable to the example file is ordinary work that Charter's own secrets rule template instructs. A deny rule cannot carry exceptions, so a blanket glob could not be narrowed afterwards.

The survey records secret file **names only** and never opens them. The deny rule is generated from the filename.

---

## What the boundaries do not protect against

Read this section. A safety tool that overstates its coverage is worse than none, because it converts caution into false confidence.

**Permission rules govern Claude Code's own tools**, and the file commands it recognises inside Bash such as `cat`, `head`, `tail` and `sed`. They do **not** govern:

- **A shell re-entered as an argument.** `sh -c 'git push origin main'` is one command whose argument happens to be a command. `sh`, `bash` and `zsh` are not stripped before matching, so no rule written for `git push` sees it. Charter puts `sh -c`, `bash -c`, `zsh -c`, `eval` and `env` on `ask` in every repository, which makes it visible rather than silent. A prompt is not a wall.
- **Arbitrary subprocesses.** A Python or Node script that opens a file itself is not intercepted. A `Read` deny on `.env` does not stop `python -c "print(open('.env').read())"`.
- **Environment runners.** `docker exec`, `npx`, `devbox run`, `mise exec` and `direnv exec` are not stripped before matching. Charter never emits a bare allow for these, but if you add one yourself it permits everything behind it.
- **Exec wrappers.** `watch`, `setsid`, `flock`, and `find -exec` cannot be auto-approved by a prefix rule. In manual mode they always prompt, which is the safe direction, but do not assume a rule covers them.
- **Anything you approve at the prompt.** An `ask` rule is a question, not a wall. If you press yes, it runs.
- **A model that is wrong inside its boundaries.** Charter constrains the blast radius. It does not make the code correct.
- **Prompt injection from repository content.** Nothing here defends against a file whose contents try to instruct the agent.

**Deny rules are the only part that constrains anything.** Allow rules remove prompts; they never add protection. If `/charter:status` shows `Boundaries ✗`, it means there are no deny rules, regardless of how many allow rules exist.

### What does cover them

The first three items above are all the same gap: a text matcher cannot see past a command into what that command runs. Tier 0 can, because the operating system enforces it for a process **and every child it spawns**.

`/charter:init` offers a [sandbox](https://code.claude.com/docs/en/sandboxing) as a separate accept. With it on, a subprocess reading `.env`, a `sh -c` re-entry and a compromised postinstall script are all constrained by the same filesystem and network rules, whatever the model decided. Without it, the boundaries stop accidents and drift, which is worth having and is not the same claim.

The sandbox is not available on native Windows; run Claude Code inside WSL2 there.

One more asymmetry worth knowing: project `allow` rules wait for you to trust the folder, but `deny` and `ask` rules apply immediately. That is why Charter puts all safety in deny and ask.

---

## Changing or removing the boundaries

Everything lives in a native file you own:

```bash
# see what is set
/permissions

# edit directly
$EDITOR .claude/settings.json

# remove Charter's boundaries entirely
# (delete the deny/ask entries; the working agreement is unaffected)
```

Charter never rewrites existing permission rules on upgrade. A changed boundary always requires an explicit confirmation, on every version.

If a rule blocks something legitimate, delete it. That is the correct response and it needs no ceremony — these are your rules, in your repository, in a documented format that works whether or not this plugin stays installed.
