# Safety model

## Three tiers, and the words matter

| Tier | Mechanism | Binding | Charter calls it |
| --- | --- | --- | --- |
| 1 | `permissions` deny / ask rules | Evaluated by the client before the model is consulted | a **boundary** |
| 2 | `PreToolUse` hook | Runs before the tool call, can deny it | a **guard** |
| 3 | A line in `CLAUDE.md` | Advisory only | a **convention** |

Anthropic's documentation is explicit that tier 3 is not enforcement: *"Claude treats them as context, not enforced configuration. To block an action regardless of what Claude decides, use a PreToolUse hook."*

Charter never describes a tier-3 item as a boundary, in generated output or in conversation. If you see it do so, that is a bug worth reporting.

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

Not a question and not configurable. `.env`, `.env.*`, `*.pem`, `id_rsa*`, `*.key`, `*credentials*.json`, and `*.tfvars` are denied to `Read`, which also blocks `Edit` and `Write` on the same paths.

The survey records secret file **names only** and never opens them. The deny rule is generated from the filename.

---

## What the boundaries do not protect against

Read this section. A safety tool that overstates its coverage is worse than none, because it converts caution into false confidence.

**Permission rules govern Claude Code's own tools**, and the file commands it recognises inside Bash such as `cat`, `head`, `tail` and `sed`. They do **not** govern:

- **Arbitrary subprocesses.** A Python or Node script that opens a file itself is not intercepted. A `Read` deny on `.env` does not stop `python -c "print(open('.env').read())"`. For OS-level enforcement across all processes, enable [sandboxing](https://code.claude.com/docs/en/sandboxing).
- **Environment runners.** `docker exec`, `npx`, `devbox run`, `mise exec` and `direnv exec` are not stripped before matching. Charter never emits a bare allow for these, but if you add one yourself it permits everything behind it.
- **Exec wrappers.** `watch`, `setsid`, `flock`, and `find -exec` cannot be auto-approved by a prefix rule. In manual mode they always prompt, which is the safe direction, but do not assume a rule covers them.
- **Anything you approve at the prompt.** An `ask` rule is a question, not a wall. If you press yes, it runs.
- **A model that is wrong inside its boundaries.** Charter constrains the blast radius. It does not make the code correct.
- **Prompt injection from repository content.** Nothing here defends against a file whose contents try to instruct the agent.

**Deny rules are the only part that constrains anything.** Allow rules remove prompts; they never add protection. If `/charter:status` shows `Boundaries ✗`, it means there are no deny rules, regardless of how many allow rules exist.

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
