# Setup

How to install and configure the Claude Forge from GitHub, from nothing.

Everything here is one of two things: a `claude` command you paste, or a file you
edit. There is no build step and nothing to compile.

---

## Requirements

| | Needed for |
|---|---|
| **Claude Code 2.1.197 or newer** | The plugin install path. Older versions work via the file installs below |
| **git** | Charter's survey, and cloning if you go that route |
| **Node 20+** | Craft's scripts only. Charter and TARS do not need it |
| **jq** *(optional)* | Charter's scripts use it when present and fall back when absent |

Check what you have:

```bash
claude --version
git --version
node --version
```

macOS, Linux, WSL and native Windows are all supported. See
[Windows](#windows) for the one thing that differs.

---

## Windows

Everything works, with one split: **the installers come in two flavours, the
plugins do not.**

| | Use |
|---|---|
| macOS, Linux, WSL, Git Bash | `./setup.sh`, `./install.sh` |
| Windows PowerShell | `.\setup.ps1`, `.\install.ps1` |

The `.ps1` scripts are line-for-line equivalents. They take the same options
under PowerShell naming (`-NoAutoUpdate`, `-AutoUpdateOnly`, `-Dir`), back your
settings file up the same way, and need no Python, Node or `jq`.

If PowerShell refuses to run the script at all, it is the execution policy, not
the script:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

**The plugins still need `bash`.** Charter and the Forge bundle shell out to
`scripts/*.sh` at runtime. That is the same `bash` Claude Code on Windows
already requires, so if Claude Code runs, they run. If you installed Claude Code
without [Git for Windows](https://git-scm.com/download/win), install it.

You never need `bash` to *install* — only to use Charter's and Forge's commands.
Craft and TARS have no shell scripts on the runtime path.

**Line endings.** The repository pins `*.sh` to LF in
[`.gitattributes`](../.gitattributes). Without it, Git for Windows'
`core.autocrlf=true` rewrites every script on checkout and the shebang becomes
`#!/usr/bin/env bash\r`, which fails as `bad interpreter: no such file or
directory`. If you cloned or installed before this was pinned, refresh the copy
Claude Code holds:

```powershell
claude plugin marketplace update claude-forge
```

---

## The one-command install

```bash
git clone https://github.com/mohxmmd/claude-toolkit.git
cd claude-toolkit && ./setup.sh
```

Windows PowerShell:

```powershell
git clone https://github.com/mohxmmd/claude-toolkit.git
cd claude-toolkit; .\setup.ps1
```

That installs **four** things — the `forge` bundle plus Charter, Craft and
TARS, which the bundle declares as dependencies — and turns on **auto-update**
so you receive fixes without repeating this.

These tools are early and change often, so being stuck on the version you first
installed means hitting bugs that are already fixed. The script backs up your
settings first, says exactly what it wrote, and `--no-auto-update`
(`-NoAutoUpdate` in PowerShell) opts out.
Details and the trade-off: [AUTO-UPDATE.md](AUTO-UPDATE.md).

Without the script, and without auto-update:

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install forge@claude-forge
```

Restart Claude Code. Plugins are loaded at session start, so nothing you just
installed exists in the session you typed it into.

Then, in the repository you want to set up:

```
/charter:init
```

Two to five questions, about a minute, and a diff before anything is written.
Because the bundle guarantees Craft and TARS are installed, Charter also offers
to set your output style and add a `/craft` routing line.

Lost at any point:

```
/forge:setup      what is configured here, and the one command to type next
```

It reads state and prints a next step. It writes nothing, and it cannot run the
commands for you — `/charter:init` and `/craft:atlas` are user-invocation only,
by design, because they write files.

---

## Installing one component instead

Nothing depends on anything else. Install only what you want.

```bash
claude plugin marketplace add mohxmmd/claude-toolkit

claude plugin install charter@claude-forge    # working agreement + boundaries
claude plugin install craft@claude-forge      # UI/UX changes that preserve identity
claude plugin install tars@claude-forge       # direct, no-flattery responses
```

Each has its own entry point:

| Component | Start with |
|---|---|
| Charter | `/charter:init` |
| Craft | `/craft:atlas`, then `/craft <what you want>` |
| TARS | `/config` → Output style → **tars:TARS** → `/clear` |

**TARS needs the `/clear`.** Output styles load at session start. Without it the
session looks exactly the same and the install reads as broken.

---

## Installing without the marketplace

Useful behind a proxy, on an air-gapped machine, or when you want to read
everything before running it.

### From a checkout

```bash
git clone https://github.com/mohxmmd/claude-toolkit.git
cd claude-toolkit
```

Load a plugin straight from disk, no install:

```bash
claude --plugin-dir ./skills/charter
claude --plugin-dir ./skills/craft
claude --plugin-dir ./output-styles
```

`--plugin-dir` is repeatable, so you can load several at once.

> **The `forge` bundle is the one exception.** It declares dependencies, and
> Claude Code disables a plugin whose dependencies are not enabled. Under
> `--plugin-dir` there is no marketplace to resolve them against, so the bundle
> loads as nothing at all — silently. Load the three components directly
> instead. This is expected behaviour, not a bug.

### TARS as a plain file

TARS is one markdown file and needs no plugin machinery:

```bash
./install.sh
```

```powershell
.\install.ps1
```

Or without cloning anything:

```bash
mkdir -p ~/.claude/output-styles
curl -fsSL https://raw.githubusercontent.com/mohxmmd/claude-toolkit/main/output-styles/TARS.md \
  -o ~/.claude/output-styles/TARS.md
```

```powershell
New-Item -ItemType Directory -Force ~\.claude\output-styles | Out-Null
Invoke-WebRequest -UseBasicParsing `
  https://raw.githubusercontent.com/mohxmmd/claude-toolkit/main/output-styles/TARS.md `
  -OutFile ~\.claude\output-styles\TARS.md
```

Then `/config` → Output style → **TARS** → `/clear`.

Note the name: **`TARS`** for a file install, **`tars:TARS`** for a plugin
install. Plugin styles are namespaced, and a setting naming one will not find
the other. Both can be installed at once without colliding.

### Pinning TARS to one project

```bash
./install.sh --dir /path/to/project/.claude/output-styles
```

```powershell
.\install.ps1 -Dir C:\path\to\project\.claude\output-styles
```

Project-level `.claude/output-styles/` is read exactly like the user-level
directory. Commit that file and everyone who clones gets the same style.

---

## Configuring

### Through the UI

```
/plugin
```

Charter and Craft both declare `userConfig`, so their settings appear there with
descriptions. Nothing needs to be edited by hand.

### Charter

Charter has **no configuration file of its own** — by design. What it writes is
native Claude Code configuration, and you edit that directly, forever.

| To change | Edit |
|---|---|
| What Claude knows about the project | The fence in `CLAUDE.md` |
| What Claude may do | `.claude/settings.json` |
| Area-specific conventions | `.claude/rules/*.md` |
| Defaults for your next repository | `~/.claude/charter.json` |

Full detail: [Charter configuration](../skills/charter/docs/CONFIG.md).

One Charter setting is about the other two components:

```
companions: ask | both | tars | craft | off      (default: ask)
```

`ask` offers to connect Craft and TARS during `/charter:init`, but **only when
they are already installed**. Charter never installs anything. Set it to `off`
to never be asked. See [Companions](charter/companions.md).

### Craft

Per-project, generated by reading the product:

```
/craft:atlas
```

That writes `.craft/config.md`, which is the file you hand-edit afterwards.
Full detail: [Craft configuration](craft/configuration.md).

### TARS

Edit the style file directly. It is a behavioural prompt, not code:

```bash
$EDITOR ~/.claude/output-styles/TARS.md          # file install
```

Full detail: [TARS customization](tars/customization.md).

---

## Verifying the install worked

```bash
claude plugin list
```

Then in a session:

```
/charter:status
```

If Charter has run in the current repository, that prints what is set up, what
it costs per session, and the one next thing worth doing.

### When something is not there

| Symptom | Cause | Fix |
|---|---|---|
| A command is not recognised | Plugins load at session start | Restart Claude Code |
| TARS is selected, nothing changed | Output styles load at session start | `/clear` |
| Style not in `/config` | Wrong name — `TARS` vs `tars:TARS` | Pick the one matching your install path |
| Bundle installed, `/forge:setup` missing | A dependency is disabled, so the bundle is too | `claude plugin list`, enable the missing one |
| `/forge:setup` will not run Charter for you | By design — `/charter:init` is user-invocation only | Type `/charter:init` yourself |
| Charter says a command is missing that exists | It only records commands that exit zero when probed | Run the probe yourself; if it fails, Charter is right |
| `bad interpreter: no such file or directory` on Windows | A pre-`.gitattributes` checkout rewrote the scripts to CRLF | `claude plugin marketplace update claude-forge`, then restart |
| `forge not found in marketplace claude-forge` | A cached marketplace clone from before the `claude-toolkit` → `claude-forge` rename | `claude plugin marketplace remove claude-toolkit`, then add and install again |
| PowerShell will not run `setup.ps1` | Execution policy, not the script | `powershell -ExecutionPolicy Bypass -File .\setup.ps1` |

---

## Updating

If you installed with `./setup.sh` or `.\setup.ps1`, this happens on its own at
session start. Turn it on for an existing install with
`./setup.sh --auto-update-only`, or `.\setup.ps1 -AutoUpdateOnly`.

By hand:

```bash
claude plugin marketplace update claude-forge
claude plugin update forge@claude-forge
```

Or one at a time:

```bash
claude plugin update charter@claude-forge
claude plugin update craft@claude-forge
claude plugin update tars@claude-forge
```

Updates need a restart to take effect. Charter never rewrites permission rules
on an upgrade — a changed boundary always requires explicit confirmation.

---

## Uninstalling

```bash
claude plugin uninstall forge@claude-forge
claude plugin prune          # drops the three dependencies nothing needs now
```

`prune` removes only plugins that were auto-installed as dependencies and are
now orphaned. Anything you installed explicitly is left alone.

**Everything Charter wrote keeps working.** The working agreement, the
boundaries and the rules files are standard Claude Code configuration and do not
depend on the plugin being installed. Removing them is a separate, optional
step — see [Charter configuration](../skills/charter/docs/CONFIG.md#uninstalling).
