# Configuration

CRAFT has one configuration file: `.craft/config.md` in your project.

You do not have to create it. CRAFT writes a starting version from what it reads
in your code, and it works without one.

## Contents

- Shape of the file
- Settings
- Sections
- Advanced settings
- Personal preferences
- Resetting

## Shape of the file

YAML frontmatter for settings, markdown for the knowledge only a person has.

Both halves matter. `posture: conservative` is a setting. *"The sidebar is legacy
and sales demos it, so ask before touching it"* is not a setting, and compressing
it into one would lose the reason, which is the part that lets CRAFT tell an
exception from a violation.

CRAFT reads the whole file only when it changes. Day to day it uses a compiled
projection, so the file can grow to whatever your team needs without every task
paying for it.

## Settings

| Key | Values | Default | Effect |
|---|---|---|---|
| `craft` | integer | `1` | Schema version. Do not edit by hand |
| `posture` | `conservative` `evolutionary` `transformative` | `evolutionary` | How much change is allowed before CRAFT asks |
| `design.density` | `compact` `comfortable` `inherit` | `inherit` | `inherit` means keep what the product does |
| `design.motion` | `none` `subtle` `expressive` `inherit` | `inherit` | |
| `design.ornament` | `flat` `restrained` `rich` `inherit` | `inherit` | |
| `design.hierarchy` | `subtle` `strong` `inherit` | `inherit` | |
| `preserve` | list | three sensible entries | Advisory. Things to keep |
| `avoid` | list | three sensible entries | Advisory. Things not to do |
| `verification` | `auto` `checks` `visual` `browser` `none` | `auto` | `auto` picks a level from each change's risk |
| `research` | `on-demand` `never` | `on-demand` | Research never overrides your conventions |

`inherit` is the important default. It means CRAFT reads the value off your code
rather than imposing one, which is what makes the zero-config path work.

## Sections

### `## About this product`

Two or three sentences: who uses it, for what, under what conditions. The single
highest-value paragraph in the file. It is what turns "improve this table" into
"this is scanned by support agents dozens of times an hour, so density stays".

### `## Do not change`

The strongest thing CRAFT reads. It stops here and says so rather than working
around it.

It is still a **convention**, not an enforced boundary. CRAFT reads this file;
nothing prevents an edit to a path listed here. For a path that must be
mechanically un-editable, ask CRAFT for the matching `Edit()` deny rule and
install it with Charter, which writes rules the client evaluates before the
model is consulted.

```markdown
## Do not change

- The sidebar architecture. Sales demos it. Ask before touching it.
- Ticket status vocabulary. It maps to the API and to agent training.
```

Give the reason. `preserve` in the frontmatter is advisory and can lose to an
explicit request; this section does not. Both are things CRAFT reads, so both
are conventions, and neither is a gate. The tier vocabulary is Charter's; see
[charter/references/policy.md](../../skills/charter/references/policy.md).

### `## Known problems`

Things you already know are wrong. CRAFT uses them to prioritise and will not
present them back to you as discoveries.

## Advanced settings

Generated commented-out at the bottom of the file, with every default shown.
Uncomment what you need.

| Key | Purpose |
|---|---|
| `budget` | Per-axis override of the posture. `brand: 0` is the default and should stay there unless you mean it |
| `paths` | Where your UI, styles and ignorable files live. Useful in a monorepo or where vendor CSS pollutes measurement |
| `detect` | Individual detector rules. `taste` ships `off` on purpose |
| `protected_surfaces` | Globs that raise risk one level and require confirmation |
| `surfaces` | Map globs to `.craft/surfaces/<name>.md` memory files |
| `viewports` | Defaults to `[1440, 768, 375]` |
| `browsers` | A browserslist query. Decides whether modern CSS is available to you |
| `dev_command` | How to start the app. Without it, visual verification is unavailable and CRAFT will say so |
| `questions_max` | Blocking questions per task. Default 3 |
| `taste` | Optional. A sentence, a vocabulary word, or a reference URL. Null means preserve the product's own language |

Unknown keys are preserved rather than dropped, and reported once, so an option
you are trying out is never silently lost.

## Personal preferences

Preferences that belong to you rather than to a product live in `~/.craft/`:

```
~/.craft/
├── preferences.md    prose. "always show me a before/after"
├── profile.json      dials and defaults, set at install
└── evidence/         cached research
```

They travel with you across projects, and because they sit outside every
repository they cannot be committed to a team repo by accident.

**Personal preferences never override project conventions.** If you prefer
expressive motion and the project's config prohibits motion in navigation, the
project wins, and CRAFT says so once rather than silently splitting the
difference.

## Resetting

| To reset | Do this |
|---|---|
| the measured knowledge | delete `.craft/atlas/`, run `/craft:atlas` |
| everything project-side | delete `.craft/`, ask CRAFT for anything |
| your personal preferences | delete `~/.craft/` |
| after an update | `/craft:atlas doctor` reports any gap and names the fix |

CRAFT never migrates or repairs your files as a side effect of a design task.
Only `doctor` writes, and only when you run it.
