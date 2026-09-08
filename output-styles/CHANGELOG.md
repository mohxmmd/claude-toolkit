# Changelog

All notable changes to TARS are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Because TARS is a behavioral prompt rather than code, versions follow the shape
of the change: **major** for a change to what TARS fundamentally does, **minor**
for added or removed behavior, **patch** for wording that does not change
behavior.

## [Unreleased]

### Changed

- Documentation only; the style itself is unchanged.
- **The plugin install works.** Verified on 2.1.197 end to end, headless, with a
  negative control. Selected as `tars:TARS` — plugin-provided output styles are
  namespaced `<plugin>:<style>`, so the plugin and file installs coexist and
  neither name resolves the other.
- The README previously said not to install TARS as a plugin, because on 2.1.112
  it installed cleanly and never appeared in `/config`. That was true when
  written and is no longer true.
- `install.sh` is now documented as the path for people without a marketplace,
  rather than the only working path.

## [1.1.0] - 2026-09-03

Compaction release. v1.0 was as verbose as the default style, sometimes more so.

### Added

- `Shape of every reply` section: answer in one or two lines, then only details
  that change what the reader does next, with a 10-line default ceiling.
- `Brevity never costs a correction. A false premise in the question is the first
  line of the answer.` Added after an intermediate build regressed: asked to
  confirm a false claim and then perform a task, it silently performed the task
  in 11 words. See `docs/examples.md` scenario 2 for the behavior this protects.
- `Asked to confirm something? Check it before confirming.` Same regression.

### Removed

- `Terse is not cryptic. Include what the reader needs to decide.` This was the
  main driver of sprawl. Available as a recipe in `docs/customization.md` for
  anyone who wants longer answers.
- `Flag the risks, dependencies, and failure modes the user has not accounted
  for` and `Name what you would need to know but do not`, folded into a single
  conditional rule: risks and unknowns only when they change the decision.
- Redundant `Answer first`, `Short lines`, `Steps in order`, `No preamble` lines,
  now covered by the Shape section.

### Distribution

- TARS now ships from the [mohxmmd/claude-toolkit](https://github.com/mohxmmd/claude-toolkit)
  marketplace alongside CRAFT, and is licensed Apache-2.0 to match that
  repository. It was Apache-2.0 from its first public release; no previously
  published version was under a different license.

### Measured

Single headless runs on Claude Code 2.1.112, same prompts, v1.0 versus v1.1:

| Scenario | v1.0 | v1.1 |
| --- | --- | --- |
| Over-engineered architecture | 272 words | 100 words |
| Fix and report status | 66 words | 49 words |
| False premise plus task | 118 words | 93 words |
| Code review | 110 words | 101 words |

Model output varies between runs, so these are direction rather than
measurement. The gain is largest on open-ended prompts, where v1.0 sprawled into
markdown headings. A list of real bug findings barely compresses, as expected.

## [1.0.0] - 2026-09-03

First public release.

### Added

- `Engineering` section: architecture fit, no speculative abstraction, edge
  cases, maintainability, and a requirement to say what added complexity buys.
- `Verification` section replaces the previous `Honesty` section, with explicit
  rules: "implemented" and "verified" are different words, never claim a command
  ran or a test passed unless it did, no invented output or benchmarks.
- Scope exception so an out-of-scope problem that blocks the task can be fixed
  rather than only reported.
- Concrete threshold for when to plan first: several files, a public interface
  change, a data migration, or anything hard to undo.
- Counterweight to terseness: "Terse is not cryptic. Include what the reader
  needs to decide."
- Guards against the style's own failure modes: "Blunt, never hostile",
  "Personality never delays the answer", and humor fenced out of errors, risks,
  and security findings.
- Reasoning rules: separate fact from assumption, name what you would need to
  know but do not.
- `install.sh`, which backs up any existing `TARS.md` before writing.
- `.claude-plugin/` manifests for forward compatibility. See the compatibility
  note in the README before using them.
- Documentation: README, examples with real transcripts, customization guide,
  contributing guide.

### Changed

- `Execution` section split into `Engineering` and `Scope`, which is what it was
  actually doing.
- "Answer in chat. Create or edit files only when the ask names a file, path, or
  action" became "Do not produce extra files, reports, or summaries unless
  asked". The original wording suppressed ordinary code editing, because most
  real requests name neither a file nor a path. The original behavior is
  available as a recipe in `docs/customization.md`.

### Removed

- `author` frontmatter field, which is not a supported output-style frontmatter
  key. Authorship now lives in `.claude-plugin/plugin.json` and the README.

### Notes

- The `Honesty 95` dial in the header is retained as flavor. A line in the
  `Verification` section makes explicit that it is not a license to shade facts.
