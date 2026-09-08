# Auto-update

How to receive new versions of these plugins without running a command, what it
costs you, and how to turn it off.

```bash
./setup.sh                    # install everything, auto-update on
./setup.sh --auto-update-only # already installed, just turn it on
./setup.sh --no-auto-update   # install, leave it off
```

---

## Why this is opt-in per machine, and cannot be shipped

**A plugin cannot enable its own auto-update.** Three routes were tested and all
three are closed:

| Route | Result |
|---|---|
| `settings` key in `plugin.json` | Accepted by the schema, marked `@internal`, **silently ignored**. A probe plugin declaring `env.PLUGIN_SHIPPED_MARKER` produced `settingsEnv keys: FORCE_AUTOUPDATE_PLUGINS` — the plugin's value never reached the runtime |
| `autoUpdate` in `marketplace.json` | No such field. After `marketplace add`, the settings entry contains `source` and nothing else |
| Default-on for a marketplace | A hardcoded Anthropic allowlist (`claude-plugins-official`, `anthropic-marketplace`, …), with a regex that blocks names impersonating official ones |

That is the correct design. A plugin that could grant itself update rights could
ship arbitrary new code to every user forever, with no review after the first
install. The install is the consent boundary; auto-update is a user handing that
boundary over, so it has to live in the user's own settings file.

`setup.sh` exists because the install command is the one honest moment to ask.

---

## What it writes

Into `~/.claude/settings.json` (or `$CLAUDE_CONFIG_DIR/settings.json`), backed up
first:

```json
{
  "env": { "FORCE_AUTOUPDATE_PLUGINS": "1" },
  "extraKnownMarketplaces": {
    "claude-forge": {
      "source": { "source": "github", "repo": "mohxmmd/claude-toolkit" },
      "autoUpdate": true
    }
  }
}
```

**`autoUpdate`** is the actual feature. Its schema describes it as: *whether to
automatically update this marketplace **and its installed plugins** on startup*.
One flag covers all four — the bundle and the three components.

**`FORCE_AUTOUPDATE_PLUGINS`** is needed only on some machines. Plugin
auto-update is gated behind Claude Code's global auto-updater:

```js
function Y1e(){ return autoUpdaterDisabled() && !process.env.FORCE_AUTOUPDATE_PLUGINS }
```

Native and VS Code installs ship with `"autoUpdates": false` and
`autoUpdatesProtectedForNative: true`, because the host manages its own updates.
Without the variable, those users get:

```
[DEBUG] Plugin autoupdate: skipped (auto-updater disabled)
```

The variable affects **plugins only**. It never causes Claude Code itself to
update, which is why setting it does not fight a VS Code or native install.

Existing keys are preserved. If you added the marketplace from a fork, your
`source` is kept and only `autoUpdate` is added.

---

## What it actually costs you

**You will run new versions of these plugins without reviewing them.** That is
the entire point, and it is a real trade-off worth naming rather than burying.

For these tools specifically the trade leans toward updating: they are early,
they change often, and the failure they prevent is concrete. `/forge:setup`
shipped broken in 0.1.0 and was fixed in 0.1.1. A user without auto-update runs
the broken one until they think to check.

Weigh it differently for a marketplace you do not control.

---

## How often it checks

At session start, throttled to one refresh per 30 seconds — so in practice,
every session.

Two caveats:

- The refresh runs after a small random delay. A very short-lived headless
  session may exit before it completes.
- Plugins load at session start, so a version fetched during startup most likely
  applies to the **next** session. An update is rarely visible in the session
  that fetched it.

---

## Turning it off

Delete `autoUpdate` from the marketplace entry in `~/.claude/settings.json`, or
set it to `false`. Removing `FORCE_AUTOUPDATE_PLUGINS` from `env` also stops it
on machines where the global auto-updater is off.

Then update by hand whenever you like:

```bash
claude plugin marketplace update claude-forge
claude plugin update forge@claude-forge
```

---

## Checking it is working

```bash
claude plugin list          # versions
```

Or read the debug log after a session:

```bash
grep -i autoupdate ~/.claude/debug/$(ls -t ~/.claude/debug | head -1)
```

| Line | Meaning |
|---|---|
| `Plugin autoupdate: skipped (auto-updater disabled)` | `FORCE_AUTOUPDATE_PLUGINS` is not set |
| `Plugin autoupdate: updated X from A to B` | Working |
| *(no autoupdate line)* | Gate passed, nothing to update |

---

## For maintainers

Auto-update on the user's side does nothing unless you release properly.

**The plugin cache is keyed by version.** Pushing to `main` without bumping a
version ships nothing: `claude plugin update` replies *"already at the latest
version"* and every user keeps the old code. See
[PUBLISHING.md](PUBLISHING.md#releasing-a-version).

Bump the version in both `plugin.json` and `.claude-plugin/marketplace.json` for
**every** change users should receive, including documentation fixes inside a
plugin directory. CI checks that the two agree.
