# Uninstalling

One command removes everything. The rest of this page is for when you want to
remove only part of it, or want to know exactly what is being deleted before it
happens.

```
/forge:uninstall
```

It prints what it found, asks once, and removes it. Without the plugin, or from
a shell:

```sh
./uninstall.sh                     # from a checkout
curl -fsSL https://raw.githubusercontent.com/mohxmmd/claude-toolkit/main/uninstall.sh | sh -s -- --plan
```

```powershell
.\uninstall.ps1                    # Windows PowerShell
```

Restart Claude Code afterwards. Plugins stay loaded until the session ends, so
`/craft` still appearing in the list is not a failed uninstall.

## See it before you do it

```sh
./uninstall.sh --plan
```

`--plan` reads and prints, and changes nothing. Everything below is what that
plan can contain.

## What is removed

**On this machine**

| Thing | Where |
|---|---|
| The four plugins | `forge`, `charter`, `craft`, `tars` |
| The marketplace | `claude-forge` |
| Auto-update settings | `extraKnownMarketplaces.claude-forge`, `env.FORCE_AUTOUPDATE_PLUGINS` |
| Plugin enablement | `enabledPlugins` entries ending in `@claude-forge` |
| The output style | `outputStyle`, only when it is set to TARS |
| The style file | `~/.claude/output-styles/TARS.md`, if `install.sh` put it there |

**In the repository you run it from**

| Thing | Where |
|---|---|
| Craft's state | `.craft/` |
| Charter's state | `.claude/charter.json` |
| Charter's rules files | `.claude/rules/*.md`, only the ones it wrote |
| The working agreement | the block between the `charter:start` and `charter:end` markers in `CLAUDE.md` |
| Permission rules | only the ones Charter added, from `permissions.deny` and `permissions.ask` |
| `.gitignore` lines | only the ones Charter and Craft added |
| The receipt | `.forge/` |

Other repositories are never touched. Run it from each one, or find them:

```sh
grep -rl 'charter:start' ~/your/projects --include=CLAUDE.md
```

## What is never removed

- `CLAUDE.md` itself. The fence is cut out of it; your prose stays byte for byte.
- Any settings file. Keys and rules are removed from it; the file survives.
- Any rule you wrote. The receipt says which rules were Charter's.
- Anything outside the repository you ran it from.

## Backups

Nothing is deleted without a copy.

| What changed | Where the copy goes |
|---|---|
| A settings file | `<file>.backup-<timestamp>`, beside the original |
| Anything in the project | `.forge-backup-<timestamp>/`, mirroring the paths |

To undo an uninstall, copy the backup tree back over the project and re-run
`./setup.sh`. Delete `.forge-backup-*` once you are happy.

## Removing only part of it

| You want | Command |
|---|---|
| Keep this repo's files, remove the plugins | `./uninstall.sh --keep-project` |
| Remove this repo's files, keep the plugins | `./uninstall.sh --keep-plugins` |
| Keep the TARS output style | `./uninstall.sh --keep-style` |
| Leave user settings alone | `./uninstall.sh --keep-settings` |
| No confirmation prompt, for scripts | `./uninstall.sh --yes` |

Turning off auto-update without uninstalling anything is a different job: delete
`autoUpdate` from `extraKnownMarketplaces` in your settings, or see
[AUTO-UPDATE.md](AUTO-UPDATE.md).

## The receipt

Charter and Craft append a line to `.forge/manifest.tsv` for every artifact they
create and every file they edit. That file is the reason an uninstall can be
exact instead of a guess, and it is why the fence comes out of `CLAUDE.md`
without taking your notes with it.

Tab separated, five columns:

```
# component	kind	path	a	b
charter	path	.claude/charter.json
charter	path	.claude/rules/secrets.md
charter	fence	CLAUDE.md	<!-- charter:start v1 -->	<!-- charter:end -->
charter	settings	.claude/settings.json	deny	Bash(git push --force*)
charter	settings	.claude/settings.local.json	key	outputStyle
charter	gitignore	.gitignore	.claude/charter.json
craft	path	.craft
craft	gitignore	.gitignore	.craft/cache/
```

| `kind` | `path` | `a` | `b` | Removal |
|---|---|---|---|---|
| `path` | file or directory | | | Deleted, with its parent if that leaves it empty |
| `fence` | file to edit | start marker | end marker | The lines from start to end, inclusive, are cut |
| `settings` | settings file | `deny`, `ask`, `allow` | the rule | That one entry is pulled from `permissions.<bucket>` |
| `settings` | settings file | `key` | key name | That top-level key is dropped |
| `gitignore` | the ignore file | the exact line | | That one line is removed |

Paths are relative to the repository root. A line is a promise that removing the
thing it names is safe, so nothing goes in that was only proposed, and no file
that already existed is ever recorded as a `path`.

Commit it or ignore it, as you prefer. A committed receipt lets a teammate
uninstall cleanly from their own checkout; an ignored one keeps the repo clean.

## Without a receipt

Projects set up before the receipt existed still uninstall. The fallback finds
the fence by its markers, and `.craft/`, `.claude/charter.json` and a TARS
`outputStyle` by their known paths.

What it cannot do is attribute permission rules. Charter's rules and yours sit
in the same array and look identical, so it lists them and leaves them alone.
Delete the ones you recognise, or run `/charter:init` once first to regenerate
the receipt and then uninstall.

## If something goes wrong

**`claude` is not on your PATH.** The settings and project passes still run. The
plugins need removing by hand:

```sh
claude plugin uninstall forge@claude-forge --yes
claude plugin marketplace remove claude-forge
```

**Neither `python3` nor `node` is available.** JSON files are left untouched and
named in a warning. Everything else still runs.

**A plugin removal printed `failed`.** The script prints the exact command to
retry. It does not retry silently.

**The uninstall was interrupted.** Re-run it. It finds what is left and removes
only that.
