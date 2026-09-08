---
name: craft
description: Improves an existing UI without losing the product's identity. Use for improving, cleaning up, refining, polishing, modernizing, simplifying, auditing or redesigning an existing interface, page, component, modal, table, form, dashboard, nav, settings or empty state, and for UX, hierarchy, spacing, density, accessibility, responsive, interaction, states or design-system consistency work on code that already exists. Diagnoses before it designs and makes the smallest sufficient change. Not for greenfield UI generation.
argument-hint: "[diagnose] [target] or plain English"
license: Apache-2.0
allowed-tools:
  - Bash(node ${CLAUDE_PLUGIN_ROOT}/scripts/*)
metadata:
  craft_schema: "1"
---

Same product. Better product.

This interface already exists and has users. Its conventions are evidence. Optimise for the user experience, never for how much you changed.

## Boot

Run once per session, follow its directives, do not rerun. A missing `.craft/` is not an error; the output says whether to write one.

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/context.mjs --target <path-or-route>
```

## Principles

1. The incumbent is evidence.
2. Diagnose first. A change with no named user problem is decoration.
3. Smallest sufficient change, not the largest defensible one.
4. Simple for the user, never simplistic for the product. Complexity encoding a real rule stays.
5. Boring but excellent beats impressive but annoying.
6. Unverified is unfinished. Say "implemented, not visually verified", never "done".
7. Name adjacent problems; never silently fix them.
8. Zero changes is a valid answer. Say so and show what you checked.

**Fix in this order**, stopping when the budget is spent. Never start at 9 while 1-4 are open.
`1 broken UX · 2 needless complexity · 3 hierarchy · 4 interaction clarity · 5 a11y · 6 responsive · 7 consistency · 8 visual quality · 9 proportional delight · 10 polish`

## Precedence

`explicit request > product convention > surface convention > .craft/config.md > ~/.craft preferences > these principles > research > your defaults`

When code and config disagree, code wins on **values**, config wins on **intent**. State any conflict in one line.

**Floor**, lowerable only by an explicit instruction you then name in the report: recorded compliance rules; WCAG 2.2 AA; no change to behaviour, permissions, data semantics or business rules.

## Modes

Smallest that fits; ties resolve downward. Escalating requires naming the structural defect in writing.

| Mode | Use when | Done when |
|---|---|---|
| Preserve | no defect, or out of budget | only defects touched, or nothing changed and you said why |
| Correct | an objective defect exists | defect gone, nothing else moved |
| Refine | structure right, execution weak | hierarchy and spacing better, structure identical |
| Modernize | visual dated, structure sound | visual delta in budget; IA, nav, brand untouched |
| Redesign | the structure *is* the defect | new structure, old one named as the problem |
| Explore | high impact, low confidence | 2-3 options: Preserve / Modernize / Rethink |

## Ledger and budget

Write before implementing: `preserve` · `improve` · `uncertain` · `forbidden`, seeded from config and the request. **Zero violations of `forbidden`.**

| posture | structure | visual | interaction | brand | content | motion |
|---|---|---|---|---|---|---|
| conservative | 0 | 1 | 1 | **0** | 1 | 0 |
| evolutionary | 1 | 2 | 2 | **0** | 1 | 1 |
| transformative | free | free | free | explicit only | free | free |

Fonts, brand colours, logo, nav identity and product terminology never move without an explicit request. On overrun: stop, name the axis and why it is needed, ask.

## Routing

Resolve before loading anything, then state one line:

```
plan: <mode> · <surface> · <scope> · risk <low|med|high> · budget <posture>
      load: <refs> · verify: <checks> · research: none
```

| mode/surface | load | verify |
|---|---|---|
| */modal, drawer | surfaces/modal, foundations/hierarchy | visual + a11y + interaction |
| */table, list | surfaces/table, foundations/spacing | visual + responsive |
| */form, settings, states | surfaces/form, surfaces/states | a11y + interaction |
| refine, modernize/other | foundations/hierarchy, foundations/spacing | visual + responsive |
| redesign/* | decisions/decide, + the surface file | full |
| diagnose/* | inspect only | none; never edits |

On a miss read [router/INDEX.md](../../router/INDEX.md). Load nothing else: three relevant references beat fifteen vague ones.

## Workflow

Parse → route → load context → inspect → diagnose, each defect naming a user problem → ledger → budget → decide → implement, reusing existing components → checks → verify → one correction pass → summary. Keep it invisible: show the result, not the pipeline.

**User Value Test.** Every significant change must improve at least one of: clarity, effort, confidence, feedback, recovery, speed, satisfaction. Aesthetics alone is not on the list.

**Asking.** High impact plus low confidence: ask or Explore. Otherwise assume and label it. Maximum 3 blocking questions. Never ask what the repo answers.

**Verify** to the routed depth: one batched round across all viewports, one batch of fixes, at most one confirming round, stop. Without a dev server, do what you can statically and say so.

**Load [quality/craft.md](../../references/quality/craft.md) immediately before editing UI**, never on a planning-only turn.

## Improvement Summary

Always end with this, twelve lines maximum, concrete outcomes over design jargon.

```
<one sentence: the user problem you found>

Before → After → Benefit
<the single most important change, in user terms>

Changed    <what, concretely>
Preserved  <what you deliberately left alone>
Verified   <viewports, states, keyboard>
Watch      <out of scope, or "nothing">
```

Changed nothing? Say what you checked, why it is sound, and what a larger budget would buy.

## Failure conditions

Redesigning when Refine would do · touching `forbidden` · moving brand unasked · decoration for its own sake · inventing a token that exists · a new component where one fits · repairing drift as a side effect · claiming done without verification.
