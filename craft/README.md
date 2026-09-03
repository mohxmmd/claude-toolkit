# CRAFT

Preserve-first UI/UX evolution for Claude Code.

This directory is the plugin. Documentation lives at the repository root:

- [Overview and install](../README.md)
- [Configuration](../docs/configuration.md)
- [How it works](../docs/how-it-works.md)
- [Inspirations and acknowledgements](../docs/inspirations.md)
- [Contributing](../CONTRIBUTING.md)

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
