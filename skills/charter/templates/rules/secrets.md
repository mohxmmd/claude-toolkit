---
paths:
  - "config/**"
  - "**/*.env.example"
---
# Configuration and secrets

Real secret files are blocked by a Read deny rule and cannot be opened. That is
deliberate — do not work around it.

When a change needs a new environment variable:
- Add it to the example file with a placeholder value.
- Reference it through the project's config layer, never `process.env` /
  `getenv()` / `env()` directly at a call site, if this project has a config layer.
- Tell the user which variable to set. Do not attempt to read or set it.
