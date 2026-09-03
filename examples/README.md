# Examples

Worked command sequences. Every command below is documented in the component
READMEs — nothing here does anything the tools do not already do.

## Setting up a repository you have just cloned

Charter runs once per repository and then gets out of the way.

```
/charter:init
```

It surveys the repo, runs the commands it is about to write down, asks two to
four questions, and shows you a diff before writing anything. Say no and nothing
changes.

Afterwards, at any time:

```
/charter:status     what is set up, what it costs per session, the one next action
/charter:check      drift, context audit, and promotion of local learnings
```

`/charter:check` also takes `--drift`, `--audit` or `--promote` to run a single
pass instead of all three.

### Seeing what it would do, without writing

```
/charter:init --dry-run
```

## Improving a screen

Craft needs no setup. Ask in plain English, or name the skill:

```
/craft make the settings page easier to scan
Make this modal cleaner
```

Both route identically.

### Auditing without editing

`diagnose` reports and never writes:

```
/craft diagnose resources/views/tickets
```

### Letting Craft record what it learned about the product

```
/craft:atlas           read the product, write .craft/config.md
/craft:atlas doctor    report drift and configuration health, repair nothing
```

`config.md` is the only file you ever need to open. Anything you list under
`## Do not change` in it is a hard gate, not a preference.

## Turning the tone down

TARS is an output style, so it applies to every response rather than waiting to
be invoked.

```bash
git clone https://github.com/mohxmmd/claude-toolkit.git
cd claude-toolkit
./install.sh
```

Then in Claude Code: `/config` → **Output style** → **TARS** → `/clear`. The
`/clear` matters, because output styles load at session start.

To switch it off, pick **Default** in `/config` and `/clear` again.

### Scoping it to one project

```bash
./install.sh --dir /path/to/project/.claude/output-styles
```

## All three on one project

They do not know about each other. This is just the order you meet a project.

```
# once, when you first open the repository
/charter:init

# once, so Craft records the product's conventions
/craft:atlas

# then, whenever a screen needs work
/craft the invoice table is unreadable on a laptop
```

TARS, if you installed it, is already on for all of the above.

Craft respects the boundaries Charter wrote — not because Craft reads them, but
because Charter wrote them into Claude Code's own `permissions`, which are
evaluated before the model is consulted.

## Trying a change before you commit it

Run a plugin straight from a checkout, with no marketplace and no install:

```bash
claude --plugin-dir /path/to/claude-toolkit/skills/craft
claude --plugin-dir /path/to/claude-toolkit/skills/charter
```
