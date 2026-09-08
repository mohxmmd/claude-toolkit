# Reading the measurement

`measure.mjs --json` returns numbers. Some of them used to be wrong in ways that
looked authoritative, which is worse than being absent. This file says what each
field means and which ones may be believed.

## The rule

**Rank and report on `files`, never on `evidence`.**

`#77a507` at 750 occurrences could be one file or sixty, and the two mean
opposite things. A value used once in a file is a one-off however many times
that file repeats it. A value in forty files is a system. Occurrence counts also
inherit whatever weighting the corpus happens to have, so one large file
dominates every total in it. File share does not.

Every entry in `tokens.*` carries both:

```json
{ "value": "#1a2b4c", "evidence": 41, "files": 12, "file_share": 0.63, "share": 0.12 }
```

`confidence` is computed from `file_share`, and is `absent` below three files
whatever the occurrence count says.

## `excluded`

What was dropped before anything was counted, and why:

| Key | Means |
|---|---|
| `vendored` | Somebody else's design system. Bootstrap, FontAwesome, jQuery plugins. |
| `generated` | Content-hashed (`bundle-core.88f4182ca0.css`), `.min.`, source maps. Nobody types those names. |
| `gitignored` | The repo's own `.gitignore` said so, which beats any guess this script could make. |
| `derived` | A stylesheet holding more than 70% of another's declarations. Catches the committed vendored copy that no filename rule can see. |

**Name these in the report.** A user whose main stylesheet was excluded needs to
see that immediately, and a wrong exclusion is far easier to spot than a wrong
number. `excluded.derived_files` and `excluded.examples` carry the paths.

## `stack.css_systems` and `stack.css_split`

Usage-weighted, not manifest-derived. A manifest says what is installed; it does
not say what the product is written in. Reading `package.json` once reported
`css: "tailwind"` for a Bootstrap site where Tailwind was nine lines across two
of ninety-eight views.

```json
"css": "bootstrap",
"css_systems": [
  { "name": "bootstrap", "files": 87, "file_share": 0.89, "source": "usage" },
  { "name": "tailwind",  "files": 2,  "file_share": 0.02, "source": "usage" }
]
```

A `source` of `"manifest only, no usage observed"` means the dependency is
installed and unused. Say that rather than dropping it or leading with it.

**When `css_split` is non-null, do not pick one canonical system.** Offer
"both, split by area" and record the split. A codebase mid-migration genuinely
has two, and forcing a single answer records a fiction.

## `signals`

Every signal is `{ value, files, matched[] }`, never a bare integer.

```json
"dark_mode": { "value": 0, "files": 0, "matched": [] }
```

This one reported `1773` once. It was substring-matching `dark`, and
`--hlp-navy-dark: #1a2b4c` contains the literal `dark:`. There were zero
`prefers-color-scheme` rules in that codebase. A confident number over a false
positive is worse than no number.

So each signal now names its mechanisms: `prefers-color-scheme`,
`[data-theme=dark]`, `.dark` class selector, the Tailwind `dark:` variant,
`@custom-variant dark`. An empty `matched` with a zero `value` is a fact worth
reporting: no mechanism was found. A non-zero value is auditable.

**Never report a signal without its mechanism.**

## `components`

The partial ranking, ranked by file count. For a design tool this is the
highest-value output of the scan: it is the vocabulary the product is built
from. Matched across SCSS mixins and placeholders, Blade components and
partials, Livewire, and JSX/Vue elements. Capitalised HTML and SVG tags are
excluded, or every icon file reports `Path` and `Circle` as leading components.

## `dials`

`confidence` and `write_to_config`. A dial computed from a thin corpus reads
exactly as authoritative as one computed from a thick corpus, and a wrong
`density: 7` silently shapes every later decision.

**When `write_to_config` is false, write the dials into `config.md` commented
out**, under a line saying the corpus was too thin to measure them. `inherit` is
the template's default and the correct value when unsure.

The dials are computed after all exclusions. Before those existed they were
derived from bundle output, which made them describe a bundler rather than a
design system.

## The standing rule

Observed facts only, and mark every inference as an inference. A script that
emits inferences with confidence scores attached is doing the opposite. If a
number cannot be traced to named files and a named mechanism, it does not go
into `config.md` as a fact.
