# Router index

Read this only when the routing matrix in `SKILL.md` does not cover the request.
Resolve, load what it names, and note the resolution so the same miss is not
paid twice.

## Contents

- Intents
- Surfaces
- Reference catalogue
- Verification levels
- Research triggers
- Risk

## Intents

| Intent | Recognised by | Default budget axis in play |
|---|---|---|
| preserve | "check", "review", "is this fine" | none |
| correct | "fix", "broken", "not working", "inaccessible" | interaction, content |
| refine | "cleaner", "tidy", "polish", "tighten", "better" | visual, interaction |
| modernize | "dated", "modernize", "refresh", "looks old" | visual, motion |
| redesign | "rethink", "redesign", "restructure", "start over" | structure |
| explore | "options", "alternatives", "what would you do" | none until chosen |
| diagnose | "audit", "what is wrong", "review only" | none, never edits |

An ambiguous verb resolves to the **lower** intent. "Better" is refine, not
redesign. Escalation needs a structural defect named in writing.

## Surfaces

| Surface | Recognised by | Reference |
|---|---|---|
| modal, dialog, drawer, sheet, popover | filename or role | `surfaces/modal.md` |
| table, grid, data list, report | filename or a `<table>`/grid | `surfaces/table.md` |
| form, settings, profile, preferences, wizard | inputs present | `surfaces/form.md` |
| empty, loading, error, skeleton, 404 | state names | `surfaces/states.md` |
| nav, sidebar, header, menu, breadcrumb | navigation landmarks | `surfaces/modal.md` for overlay nav, else `foundations/hierarchy.md` |
| dashboard, overview, home, analytics | many widgets | `foundations/hierarchy.md` + `foundations/spacing.md` |
| list, index, feed, inbox | repeating rows | `surfaces/table.md` |
| detail, show, view page | one record | `foundations/hierarchy.md` |
| card, tile, panel, widget | component scope | `foundations/spacing.md` |
| button, badge, chip, input | single primitive | `quality/craft.md` only |
| other | anything else | `foundations/hierarchy.md` |

Surface comes from the target, not from the product. A settings page inside a
marketing site is still a form.

## Reference catalogue

One level deep from `SKILL.md`. Load only what the plan names.

| Reference | Load when | Cost |
|---|---|---|
| `foundations/hierarchy.md` | anything about attention, emphasis, scanning, competing actions | ~700 |
| `foundations/spacing.md` | rhythm, density, grouping, alignment, whitespace | ~650 |
| `surfaces/modal.md` | overlays, focus trapping, dismissal, layered UI | ~700 |
| `surfaces/table.md` | tabular data, dense lists, responsive tables | ~700 |
| `surfaces/form.md` | inputs, labels, validation, multi-step | ~750 |
| `surfaces/states.md` | empty, loading, error, disabled, partial | ~650 |
| `decisions/decide.md` | mode is unclear, or a redesign is on the table | ~800 |
| `quality/craft.md` | **immediately before editing UI, every time** | ~800 |

`quality/craft.md` is the only reference loaded on timing rather than topic.
Never load it on a planning-only turn.

## Verification levels

| Level | Runs | Use for |
|---|---|---|
| checks | deterministic checks only | token or spacing tweak |
| visual | checks + screenshots at each viewport | component, layout, visual work |
| interaction | visual + keyboard walk + state exercise | modal, form, nav |
| full | interaction + console + regression against before | redesign, high risk |

Drop one level when no dev server is reachable, and say which level actually
ran. Never claim a level you did not run.

## Research triggers

Research is off unless one of these fires. It is evidence, never doctrine, and
it ranks below product convention.

- the user asks for current, latest, or best practice
- a browser or platform capability decides the approach
- an accessibility standard may have moved
- an external reference must be analysed
- competitive research is explicitly requested

## Risk

| Risk | When | Effect |
|---|---|---|
| low | one component, no shared code, reversible | act, verify at `checks` |
| medium | a surface, or a shared component with few consumers | act, verify at `visual` or above |
| high | shared primitive, navigation, billing, auth, or anything in `Do not change` | confirm before editing, verify at `full` |

Risk rises one level automatically when the target is matched by
`protected_surfaces` in config.
