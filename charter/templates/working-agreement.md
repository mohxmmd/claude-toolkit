<!--
  Charter working-agreement template.

  HARD CAP: 35 lines between the fences. Anything that does not fit belongs in a
  path-scoped rule under .claude/rules/, not here.

  Placeholders in <angle brackets>. Drop any section with nothing true to say —
  an empty heading costs tokens every session forever.

  Do NOT include: directory trees, dependency lists, architecture overviews, or
  anything restating the framework's documentation. /doctor's trim pass deletes
  exactly that content, so writing it is doubly wasteful.
-->

<!-- charter:start v1 -->
## Working agreement
<!-- guidance: quiet -->

Commands (verified <DATE>)
- test: `<verified>`     lint: `<verified>`
- typecheck: `<verified or none>`     build: `<verified or none>`
If one of these fails, run `/charter:check` instead of working around it.

Project facts
- <fact 1>
- <fact 2>
- <fact 3>

Ask before acting when
- two readings of the request produce materially different code, or
- the change touches <money / auth / tenancy / data loss — name what is real here>, or
- it contradicts an existing pattern here.
Otherwise state the assumption in one line and continue. Do not ask about
anything this file or the repo already answers. When a request is genuinely
underspecified and guessing wrong is expensive, ask one question offering two
or three concrete options.

Plan before acting when three or more hold: >5 files, crosses a module
boundary, adds a dependency, changes a schema or public contract, no existing
pattern to copy, hard to reverse.

Before reporting done
Run the narrowest command that would fail if the change is wrong. If you ran
nothing, say "not verified" and say why.

Change only what the task requires. Do not reformat, re-indent, or tidy code
that is not part of the ask.

Boundaries are enforced in `<settings file>`, not here.
<!-- charter:end -->
