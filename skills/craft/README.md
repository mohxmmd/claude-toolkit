# CRAFT

**Improve existing SaaS interfaces without losing the product's identity.**

Same product. Better product.

Part of the [skills](../../README.md) marketplace.

CRAFT is a [Claude Code](https://claude.com/claude-code) skill for products that
already exist and already have users. It reads your product's own conventions,
diagnoses what is actually wrong, makes the smallest change that fixes it, proves
the change worked, and tells you plainly what it did and what it deliberately
left alone.

It is not a UI generator. It will not give your product a new look because a
different look is fashionable.

---

## The thirty-second version

```
> Make this ticket modal cleaner.

CRAFT  no .craft found. Reading your UI...
       Blade + Tailwind, 6px radius, 4px spacing scale, one blue accent, dense.
       Wrote .craft/config.md. Edit it any time.

       The modal header competed with the ticket title, and three footer buttons
       had equal weight, so the intended action was not obvious.

       Before → After → Benefit
       Three equal-weight footer buttons → one primary, two text actions
       → the intended action is obvious at a glance instead of needing a read.

       Changed    header hierarchy, footer button weights, metadata row gap 24→16px
       Preserved  palette, font, density, modal behaviour, field order
       Verified   1440 / 768 / 375, keyboard focus, loading and error states
       Watch      the status dropdown truncates at 375px. Out of scope; want it fixed?
```

No setup. No questionnaire. No new design system.

---

## What it is for

| | |
|---|---|
| **Who** | Anyone maintaining a UI that already exists: solo developers, product teams, design-system owners |
| **The problem** | Ask any AI to "improve this screen" and it regenerates it. You get something that photographs well, does not look like your product, and quietly changed six things you did not ask about |
| **The difference** | CRAFT treats your existing UI as evidence rather than as a first draft. Preservation is enforced by a ledger and a change budget, not by hoping the model behaves |
| **Not for** | Greenfield design. If nothing exists yet, use [frontend-design](https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design) |

---

## Install

```bash
claude plugin marketplace add mohxmmd/claude-toolkit
claude plugin install craft@claude-toolkit
```

Then open a project with a UI in it and ask for something.

## Use

```
/craft make the settings page easier to scan     improve something
/craft diagnose resources/views/tickets          audit only, never edits
/craft:atlas                                     (re)read the product
/craft:atlas doctor                              drift and configuration health
```

Plain English works everywhere. `Make this modal cleaner` routes exactly like
`/craft`.

---

## Common questions

**Does it work with an existing project?** That is the only thing it is for.

**Do I need configuration?** No. CRAFT reads your code and writes a starting
`.craft/config.md` itself. Editing it is optional.

**Will it redesign everything?** No. Every task runs against a change budget:

| posture | structure | visual | interaction | brand | content | motion |
|---|---|---|---|---|---|---|
| conservative | 0 | 1 | 1 | **0** | 1 | 0 |
| evolutionary *(default)* | 1 | 2 | 2 | **0** | 1 | 1 |
| transformative | free | free | free | explicit only | free | free |

`brand: 0` on both default postures. Fonts, brand colours, logo treatment,
navigation identity and product terminology do not move unless you ask. If a fix
genuinely needs more budget than it has, CRAFT stops and says which axis and why,
rather than quietly exceeding it or quietly giving up.

**Can I preserve specific things?** Yes, and it is a hard gate rather than a
preference. Anything under `## Do not change` in `config.md` will not be touched,
and CRAFT will say so rather than working around it.

**Can I define my own taste?** Optionally. The default is to preserve the visual
language your product already has. If you want direction, describe it in a
sentence, name a vocabulary word (`minimal`, `dense`, `editorial`, `technical`),
or point at a reference. References are mined for principles, never cloned, and
if a reference conflicts with your product, your product wins.

**How does it verify changes?** Verification is routed to risk: deterministic
checks for a spacing tweak, screenshots and a keyboard walk for a modal, full
verification for a redesign. When no dev server is reachable it says
**"implemented, not visually verified"**. It never says "done" for work it did
not check.

**Can it decide to change nothing?** Yes, and that is a designed outcome. If your
screen is already good, CRAFT says so and shows what it checked.

**Is it slow or expensive?** A normal task loads about 4,000 tokens of skill
context. The core is 1,497 tokens and the router loads two or three references
rather than a library. CI fails the build if any budget is exceeded.

---

## How it works

```
your request
   ↓
Router      intent · surface · scope · risk · budget · what to load · how to verify
   ↓
Atlas       what this product is: measured tokens, conventions, your config
   ↓
Refit       diagnose → preservation ledger → decide → smallest sufficient change
   ↓
Verify      routed to risk, bounded to two inspection rounds
   ↓
Improvement Summary
```

Four ideas carry it:

1. **The router loads only what the task needs.** Intelligence is deciding what
   to read, not having everything available.
2. **Preservation is mechanical.** A ledger of `preserve` / `improve` /
   `uncertain` / `forbidden`, plus a six-axis budget that can be exceeded only
   deliberately and out loud.
3. **One human file.** `.craft/config.md` is the only file you ever need to open.
4. **Value is visible.** Every task ends with what changed, why, what was
   preserved, and what was verified.

More detail: [docs/how-it-works.md](../../docs/craft/how-it-works.md) ·
[docs/configuration.md](../../docs/craft/configuration.md)

---

## What CRAFT writes into your project

```
.craft/
├── config.md        the only file you edit. yours.
├── atlas/           measured knowledge. generated, disposable, regenerable.
├── state.json       machine state: hashes, dials, routing cache.
└── cache/           ephemeral. gitignored.
```

Your personal preferences live in `~/.craft/`, outside every repository, so they
travel with you across projects and can never be committed to a team repo by
accident.

Updating CRAFT replaces the skill and touches neither directory.

---

## Layout

| Path | What it is |
|---|---|
| `skills/craft/SKILL.md` | The core. Doctrine, decision model, budget, routing. Capped at 1,500 body tokens |
| `skills/atlas/SKILL.md` | Reads the product and writes `.craft/config.md`. Also runs as `doctor` |
| `router/INDEX.md` | Full routing catalogue, read only when the inline matrix misses |
| `references/` | Diagnostic detail, loaded one file at a time |
| `scripts/` | Deterministic work: boot, measurement, inspection, budget gate, releases |
| `templates/` | The `config.md` a project starts from |
| `evals/` | Benchmark cases and rubric |

## Scripts

```bash
node scripts/context.mjs --target <path>   # boot: compiled context and directives
node scripts/measure.mjs [--json]          # design tokens, dials, confidence
node scripts/inspect.mjs <file>            # one surface and its local conventions
node scripts/budget.mjs                    # token and spec gate (CI)
node scripts/version.mjs --check           # release consistency (CI)
```

All are zero-dependency Node 20 ESM and safe to run against any repository.

---

## Status

**0.1.0.** The core loop works and is measured. Browser-driven verification, the
deterministic detector, surface memory and reference grounding are specified and
scheduled; see the [changelog](../../CHANGELOG.md) for what is and is not in this
release, including its known limitations.

---

## Inspirations

CRAFT was built by studying the existing ecosystem, and it did not invent
progressive disclosure, design dials, design-DNA extraction, deterministic design
checks or persistent taste profiles. It combines them for a different objective:
preserve-first evolution of products that already exist.

Full credit, and what was learned from each project including where their
approach was deliberately not followed, is in
**[docs/inspirations.md](../../docs/craft/inspirations.md)**.

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md). The short version: every addition is paid
for on every task that loads it, so a pull request should say what it costs and
which observed failure it fixes.

## Author

Created and maintained by **Mohammed**.

Licensed under [Apache 2.0](../../LICENSE).
