# Companions

How Charter connects to Craft and TARS, and the rules it follows while doing it.

Charter does not require either of them. It does not install them, does not
break when they are absent, and never mentions them in a repository where they
are not already present. What it does is offer to connect what is already there,
record what you accepted, and tell you later when that connection breaks.

---

## Why this exists at all

The three tools solve different problems and were built to be installed
separately. But installing them separately leaves you doing the wiring by hand,
and the wiring is exactly the part that is easy to get subtly wrong.

Charter is already the component that runs once per repository, already asks you
questions, and already writes settings. Adding "and by the way, do you want the
other two connected" costs one question in the repositories where it applies and
nothing anywhere else.

---

## What you get asked

Only when at least one companion is installed and not already wired:

> **Two other tools are set up on this machine. Connect them?**
>
> - **Direct answers (TARS)** — Claude answers first in a line or two and tells
>   you when you are wrong. Personal to you, not committed.
> - **UI work routing (Craft)** — one line in the working agreement pointing
>   screen work at `/craft`, which changes the smallest thing that fixes a
>   problem instead of regenerating the screen.

Multi-select. Both options can be declined, and a decline is remembered — you
are not asked again on a re-run.

This is Charter's fifth question, and the only one allowed past its four-question
cap. It earns that by being completely absent from every repository where it has
nothing to offer.

---

## What gets written

### TARS

One key, merged into `.claude/settings.local.json`:

```json
{ "outputStyle": "tars:TARS" }
```

Existing content in that file is preserved. It commonly holds `enabledPlugins`
and personal permissions that are not Charter's to touch.

### Craft

One line inside the `CLAUDE.md` fence:

```
UI/screen work: `/craft` — smallest sufficient change, never a regeneration.
```

Roughly ten tokens, and it counts against the fence's 35-line cap like
everything else. If the fence is already full, Charter says so rather than
silently dropping something to make room.

Charter does **not** write `.craft/config.md`. That file is Craft's, and
`/craft:atlas` generates it by actually reading your product. A Charter-authored
guess at posture would be a second source of truth that nothing reconciles.

### State

```json
"companions": {
  "style": "tars:TARS",
  "style_scope": ".claude/settings.local.json",
  "craft": true
}
```

In `.claude/charter.json`, which is never loaded into a session. Absent means
never asked. `null` or `false` means asked and declined.

---

## The output style always goes in the local file

`outputStyle` is written to `.claude/settings.local.json` — **always**, including
when your boundaries go to the committed `.claude/settings.json`.

This is not configurable by the collaboration answer, and the reason is worth
stating plainly.

Permission boundaries are a team decision. Everyone who clones the repository
should inherit the same limits; that is most of the point of writing them down.
Response style is a personal one. Committing `outputStyle` changes how Claude
talks to every teammate who clones the repo, without asking any of them, and the
first thing most of them will do is wonder what broke.

A working agreement that quietly reconfigures other people's tools is the exact
opposite of what Charter is for.

If you want it committed anyway, move the key by hand. Charter will not fight
you, and `/charter:check` reads it wherever it ends up.

---

## The name trap

TARS has two install paths and they expose **different names**:

| Install | Style name |
|---|---|
| Plugin — `claude plugin install tars@claude-toolkit` | `tars:TARS` |
| File — `install.sh` or a manual copy | `TARS` |

Claude Code namespaces plugin-provided output styles as `<plugin>:<style>`. Both
installs can coexist; they do not collide, and neither name resolves the other.

**A setting naming a style that does not exist fails silently.** The session
simply has no output style and nothing says why. This is the single most likely
thing to go wrong here, which is why Charter reads the name from detection rather
than constructing it, and why `/charter:check` verifies it afterwards.

---

## Drift

`/charter:check` checks two things, both structural and both cheap:

| Detected | Meaning | Proposed repair |
|---|---|---|
| Recorded style no longer resolves | The plugin was uninstalled, or you switched between the plugin and file installs | Correct the name, or drop the key |
| Fence says `/craft`, Craft is gone | The agreement points at a command nobody has | Remove the line |

Neither is an error, and neither is fixed without showing you a diff first.

---

## Turning it off

In `/plugin`, or in the plugin's `userConfig`:

```
companions: ask | both | tars | craft | off
```

| Value | Behaviour |
|---|---|
| `ask` *(default)* | Offer whatever is installed and not already wired |
| `both` | Wire both without asking, still shown in the diff |
| `tars` / `craft` | Only ever offer that one |
| `off` | Never ask, never write, never mention it |

`off` is a complete opt-out. Charter behaves exactly as it did before this
feature existed.

Note that none of these values can cause an install. Charter offers what is
present and nothing else, in every mode.

---

## Doing it by hand

Nothing here needs Charter. The two writes are:

```bash
# TARS
echo '{"outputStyle": "tars:TARS"}' > .claude/settings.local.json

# Craft — one line inside the charter fence in CLAUDE.md
UI/screen work: `/craft` — smallest sufficient change, never a regeneration.
```

If you do it by hand, `.claude/charter.json` will not know, and `/charter:check`
will not watch it for you. That is a fair trade and a supported way to work.
