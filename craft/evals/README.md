# Evaluations

CRAFT's quality claim is testable, and the tests that matter most are the ones
where the right answer is to change almost nothing.

## Contents

- Method
- The preservation set
- The capability set
- The north star
- Scoring
- Fixtures

## Method

1. **Baseline first.** Run the case with the skill disabled and record what
   Claude does. Keep the actual failure sentences; they are the requirements
   document for anything you add.
2. Run the case with CRAFT.
3. Assert on the `plan:` line before asserting on the diff. A right answer from a
   wrong plan is luck and will not repeat.
4. Record tokens consumed.

Run every case on both a mid-tier and a top-tier model. Doctrine that only the
largest model can follow is doctrine that fails for most installations.

## The preservation set

**Half the total weight sits here.** Every tool in this category passes the
capability set by trying hard. Only a tool with a working preservation model
passes these.

| # | Case | Prompt | Passes when |
|---|---|---|---|
| P1 | A genuinely good screen | "make this better" | fewer than 15 changed lines, or zero changes with a clear explanation of what was checked |
| P2 | Explicit constraint | "improve this, keep the sidebar" | zero `forbidden` violations, even when a supplied reference suggests otherwise |
| P3 | Conservative posture | "small improvement" | total movement inside the budget, and the ledger's `preserve` list is non-empty and specific |
| P4 | Design-system drift present | any refine request | drift is reported and **not** repaired as a side effect |
| P5 | Config contradicted by research | "modernize this" | the project convention wins; the research is mentioned as a note, not applied |
| P6 | Brand pressure | "make it look more premium" | fonts and brand colours unchanged; the improvement comes from hierarchy, spacing and states |

## The capability set

| # | Case | Passes when |
|---|---|---|
| C1 | Dated but branded UI, "modernize" | visibly improved, brand axis at zero, information architecture identical |
| C2 | Broken information architecture, "improve this flow" | a structural change happens, and the structural defect is named in writing |
| C3 | Reference image or URL supplied | principles extracted and adapted, nothing cloned |
| C4 | Conflicting taste and project convention | convention dominant unless explicitly overridden |
| C5 | No dev server available | reports "implemented, not visually verified" and never claims done |
| C6 | Modal | focus trap, Escape, focus restoration, one primary action |
| C7 | Table | identity column strongest, numbers right-aligned and tabular, a responsive strategy consistent with the rest of the product |
| C8 | Form | labels above inputs, inline errors, pending state, full keyboard path |
| C9 | Missing states | empty, filtered-empty, loading and error all distinguished |
| C10 | Accessibility-only request | zero visual change beyond what accessibility required |
| C11 | Ambiguous request | at most three blocking questions, or Explore with labelled alternatives |
| C12 | Token stress, large surface | full task under 8,000 tokens, plan line correct, no unrequested references loaded |

## The north star

The highest-weight case, and the only one that measures the actual goal.

Show someone who knows the product the before and the after, unlabelled, and ask
two questions:

```
Is this the same product?   must be YES
Which one is better?        must be AFTER
```

Run it on P1, C1 and a dashboard case every release. Everything else in this
suite is a proxy for it. A build that passes twenty proxies and fails this one
has failed.

## Scoring

| Signal | Target |
|---|---|
| `forbidden` violations | zero, always |
| changed lines on P1 | under 15 |
| unrequested new components | zero |
| token literals introduced where a token exists | zero |
| files touched outside the stated scope | zero |
| blocking questions | at most 3 |
| tokens, normal task | about 4,000 |
| tokens, complex redesign | under 8,000 |
| ledger `preserve` non-empty and specific | always |

Do not average these into a single number. A zero on `forbidden` violations is
not tradeable against a good score elsewhere.

## Fixtures

`fixtures/` holds small self-contained projects, each with an established design
language of its own. A fixture needs a real design system, however modest: a
token file or a consistent set of utilities, several surfaces that agree with
each other, and at least one deliberate inconsistency for the drift cases.

Fixtures are the only place in this repository where a `.craft/` directory may be
committed. They are examples, not configuration, and nothing outside `fixtures/`
should ever contain one.
