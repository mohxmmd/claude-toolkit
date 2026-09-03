# Inspirations and acknowledgements

CRAFT was built by studying what already exists. Nothing here is presented as
original when it is not.

Each entry says what was taken and, where relevant, what was deliberately not
taken. The second column is not criticism. These projects are aimed at different
problems, and a choice that is right for generating a new interface is often
wrong for evolving one that already has users.

---

### [Impeccable](https://github.com/pbakaus/impeccable)

**Taken.** A routing-only `SKILL.md` that spends its budget on deciding rather
than on knowing. Loading the quality floor late, immediately before editing,
rather than on a planning turn. Drift severity expressed as an action (`auto`,
`mention`, `route`) instead of as a level of badness. The rule that drift is
never repaired as a side effect of a design task. Bounded verification rounds
instead of an open-ended polish loop. A boot script that emits directives the
skill branches on.

**Not taken.** Twenty-three commands organised by mood. For a preserve-first tool
those collapse into one diagnosis: the audit decides whether a surface is
over-expressed or under-expressed, so the user does not have to.

### [ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)

**Taken.** Keeping bulk knowledge behind a search script so it costs nothing
until it is queried. Persisting a project-level design record, and refusing to
regenerate it over human edits without an explicit flag.

**Not taken.** A large curated catalogue of palettes and font pairings. That
serves generation. In a redesign the palette already exists, and a catalogue of
alternatives is an invitation to replace it.

### [taste-skill](https://github.com/Leonxlnx/taste-skill)

**Taken.** Design dials as a compact shared vocabulary, and reading the brief
before reaching for any rule.

**Not taken.** A single 1,206-line `SKILL.md`, roughly 22,000 tokens loaded on
every invocation. CRAFT's entire core is 1,497 tokens and the budget is enforced
in CI.

### [Tastemaker](https://github.com/codeswithroh/tastemaker)

**Taken.** Separating craft from taste as different kinds of judgement. A
persistent per-developer taste profile. A decisions log, so a product can evolve
across sessions instead of restarting. Deterministic scripts for the things that
are actually measurable, such as contrast.

**Not taken.** Storing the developer's taste profile inside the repository, where
it gets committed and becomes a team artefact. CRAFT keeps personal preferences
in `~/.craft/`, outside every project.

### [Senlin taste-skill](https://github.com/senlindesign/taste-skill)

**Taken.** Reverse-engineering a reference into concrete tokens *plus the
reasoning behind them*. Extracting the why is what makes a reference usable
without cloning it.

### [Google Stitch skills](https://github.com/google-labs-code/stitch-skills)

**Taken.** The codebase extraction order: manifest, then token and theme config,
then the source tree, then stylesheets. Consolidating near-identical colours
under a functional name rather than a hex value. The rule that token files
outrank scattered component styles. The [DESIGN.md](https://github.com/google-labs-code/design.md)
format as an interoperability target.

**Not taken.** Global aesthetic bans, such as banning Inter, banning serif in
dashboards, or banning centred heroes. Those are defensible when generating
something new. They are wrong for a tool whose first duty is to a product that
already made those choices and shipped them to users. In CRAFT such rules exist
only as configurable detector rules, and they ship off.

### [Anthropic frontend-design](https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design)

**Taken.** Naming the visual defaults AI converges on explicitly, rather than
exhorting against genericism in the abstract. Planning and critiquing the plan
before writing code. The principle that the brief's own words always win. Spend
boldness in one place and keep everything around it disciplined.

**Not taken.** Nothing, except scope. It is a generation skill and does not claim
otherwise; CRAFT starts where it stops.

### [OneRedOak design-review](https://github.com/OneRedOak/claude-code-workflows/tree/main/design-review)

**Taken.** Review phases routed by what is being reviewed. Fixed viewports at
1440, 768 and 375. A severity triage rather than an undifferentiated list.
Reporting the problem and its user impact rather than prescribing the fix.

**Not taken.** A single design-principles document that mixes universal
heuristics with one product's module-specific rules. Anyone adopting it inherits
someone else's product. Separating core doctrine from project context is the
direct response to this.

### [Anthropic skill-authoring guidance](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

**Taken.** The 500-line ceiling on a skill body. References exactly one level
deep, because a reference reached through another reference may be read only
partially. A table of contents on any reference over 100 lines. Building
evaluations before writing documentation.

---

## The honest summary

CRAFT combines progressive disclosure, design dials, design-DNA extraction,
deterministic checks and persistent preferences, all of which originated
elsewhere, and adds three things for its own objective:

1. A **preservation ledger** that makes what may not change explicit and
   enforceable before any code is written.
2. A **six-axis change budget** that turns "do not over-redesign" from a hope
   into a check that can fail.
3. An **Improvement Summary** that makes the value of the work visible without
   reading the diff.

If you maintain one of the projects above and something here misrepresents your
work, please open an issue. It will be corrected.
