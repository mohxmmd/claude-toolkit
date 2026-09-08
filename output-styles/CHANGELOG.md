# Changelog

All notable changes to TARS are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Because TARS is a behavioral prompt rather than code, versions follow the shape
of the change: **major** for a change to what TARS fundamentally does, **minor**
for added or removed behavior, **patch** for wording that does not change
behavior.

## [2.0.0] - 2026-09-08

Redesign. v1.1 was a list of prohibitions with one fixed reply shape. 2.0 is an
operating model: it picks a response shape from the kind of work, and it can
teach, notice a working pattern, and name an unverified assumption.

### Added

- **`Length is a decision, made per task`** replaces the flat 10-line ceiling
  with small / medium / large tiers. Small tasks get one line and no lesson.
  Large tasks open with a summary that stands on its own. The medium tier keeps
  the old ten-line budget, so the v1.1 anti-sprawl guard survives where it
  applied.
- **`Shapes, not templates`**: eight task modes (debug, implement, decide,
  review, refactor, UI, plan, blocked) described as the parts that tend to
  matter, with an explicit instruction against emitting them mechanically.
- **`Named moves`**: a small shared vocabulary. `Assumption check` for an
  unverified belief that changes the result, `Decision debt` for choosing
  without the evidence that would settle it, `TARS Insight` for a lesson that
  transfers to the next problem. Rated for frequency: most responses use none.
- **`Coaching`**: `Prompt signal:` marks missing information that actually
  changed the work, or a request that was unusually good. It decays. Once the
  user writes precise requests, TARS stops teaching prompting.
- **`Reading the user`**: infer working preferences from the conversation,
  state one once when it settles a default, then apply it silently. Explicit
  limits against inventing personal facts, claiming absent memory, or
  psychoanalyzing.
- **`Checkpoints`**: on work big enough to go wrong quietly, TARS stops twice
  rather than surfacing at the end with something built on a wrong guess. First
  on the fork before the bulk of the work, as numbered options with one marked
  default so the cheapest reply is "go". Second once there is an artifact to
  judge, naming the calls it made rather than derived. Then it acts on the
  answer and says what moved. Capped at two, barred from small tasks, and
  dropped for the session if the user says to stop asking.
- **`Never`**: two guards against the style's own failure modes.
- A rule against writing a page of options when the honest answer is that you
  need direction, added after evaluation showed exactly that.

### Changed

- **`Lead with the result`** replaces `Shape of every reply`, with four worked
  openers: found it, implemented, a verdict, and an honest "I cannot confirm
  that". The rule is now about what the first line contains rather than how
  many lines follow.
- `Engineering` folded into `Judgment`. It was three lines that belonged there.
- The em dash rule now names a replacement (colon, period, parentheses) instead
  of only prohibiting. Prohibition alone was measurably losing. See Measured.
- Description rewritten for the `/config` picker.

### Preserved

Four v1.1 behaviors were dropped during the rewrite and restored on review.
Two of them were added in v1.1.0 in response to measured regressions:

- The false-premise guard.
- The medium-response line budget.
- No extra files, reports or summaries unless asked.
- The plan-first threshold: several files, a public interface, a data
  migration, or anything hard to undo.

### Measured

Multi-turn headless evaluation on Claude Code 2.1.197, run through
`--resume` so that conversation-dependent behavior could be observed. Single
runs, so these are direction rather than measurement.

| Behavior | Result |
| --- | --- |
| Simple vs complex length | 1 word (`5432.`) vs 657 words with a standalone summary, same session |
| Ceremony on small tasks | Four consecutive git questions: no headings, no named moves, no coaching |
| Mechanical emission | 2 named moves across 17 turns. Never opened a response |
| User-pattern recognition | After three "simplest" choices, stated the default once, applied it silently, then flagged where it stopped being sufficient |
| Coaching decay | Vague, vague, precise, precise. `Prompt signal:` fired on turn 1, stayed silent on 2, marked turn 3 strong with a specific reason, and was absent on turn 4 |
| Decision debt | Fired on a goal-free "make the caching layer better", naming the two numbers that would settle the choice |
| Checkpoint, fires | Ambiguous offline-sync request produced "the design fork you're actually standing on": three numbered options, one marked default |
| Checkpoint, suppressed | A fully specified job-queue build got no checkpoint. It delivered, then closed with "What I chose, and where the edges are": five reversible calls plus a "Not verified" |
| Checkpoint, small tasks | Four small tasks in a row: none |
| Checkpoint, acts on the answer | Replying "2" produced "Option 2 it is", plus the consequence that choice made worse |
| Checkpoint, dropped on request | "Just do it, stop asking me" produced "Checkpoints off for the rest of this session; I'll state assumptions inline instead of asking" |
| Checkpoint, stays dropped | The next substantial request (usage metering: schema, migration, tiered pricing) got zero questions and zero option-forks. It made the structural call unilaterally and stated it, and still closed with "Not verified" |
| Reaffirmed decision | Pushed back once on a solution-first request, then dropped it entirely when the user reaffirmed |
| False premise plus task | Premise corrected in the first line, task still completed |
| No em dashes | **Improved, not fixed.** 18 occurrences under the v1.1 prohibition; 2 across seven turns once the rule named a replacement |

Against default Claude on the same migration prompt, TARS produced 657 words to
the default's 635. The difference is shape, not length: TARS opens with the
recommendation and names the hard part in the first paragraph, and ends with a
decision request carrying a default. This is the weakest point of
differentiation, and it is worth knowing before installing.

### Not verified

Suppression was confirmed to survive one following request, not a long session.
`TARS Insight` fired only in single-turn runs, never in the multi-turn set.
Coaching decay was observed across one four-turn session, not a long one. The
em dash rule still leaks. Nothing here was run more than once, and model output
varies between runs.

### Known weakness

On open-ended conceptual prompts TARS runs long: 561, 601 and 558 words on
three design questions, and 657 on a migration question where default Claude
wrote 635. This is sharpest when TARS's own verdict is "you have not told me
the goal" and it then writes a page anyway, which undercuts the point it is
making. 2.0 adds one rule against exactly that case. The differentiation from
default Claude is strongest on pushback and on small tasks, weakest on essays.

### Cost

10.6 KB, roughly 2,600 tokens, up from 2.9 KB and roughly 750. `Checkpoints` is
the single most expensive section at roughly 1.4 KB. It is also the one that
changes the working relationship most, and it is deletable in one piece. Prompt caching
absorbs most of it after the first request in a session.

### Distribution

- **The plugin install works.** Verified on 2.1.197 end to end, headless, with a
  negative control. Selected as `tars:TARS` because plugin-provided output
  styles are namespaced `<plugin>:<style>`, so the plugin and file installs
  coexist and neither name resolves the other.
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
