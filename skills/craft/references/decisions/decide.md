# Deciding what to change

Load this when the mode is unclear, when a redesign is on the table, or when the
change budget is about to be exceeded.

## Contents

- The order of questions
- Choosing a mode
- The reuse ladder
- When redesign is justified
- When to produce alternatives
- Writing the ledger

## The order of questions

Answer these in order. Stop as soon as the answer decides the mode.

1. Is anything objectively broken? Accessibility failure, overflow, a dead
   control, a missing state. If yes, that is Correct, and it comes first.
2. Is there unnecessary complexity that the user pays for on every visit? If yes,
   removing it usually beats improving it.
3. Does the structure support the task? If it does, you are in Refine or
   Modernize. If it does not, you may be in Redesign.
4. Is the weakness in execution or in the visual language? Execution is Refine.
   Language is Modernize.
5. Does the change fit the budget? If not, say so and ask rather than trimming
   the fix into something that no longer solves the problem.

## Choosing a mode

| Evidence | Mode |
|---|---|
| Nothing found, or everything found is out of budget | Preserve |
| A defect with an objective test | Correct |
| Structure fine, hierarchy and spacing weak | Refine |
| Structure fine, visual language dated or inconsistent | Modernize |
| The layout or flow is itself the reason the task is hard | Redesign |
| High impact, and you genuinely cannot tell which of two directions is right | Explore |

Ties resolve downward. Modernize is not a better Refine; it is a different claim
about where the problem lives, and it spends a different budget axis.

## The reuse ladder

Walk down. Stop at the first rung that works.

| Rung | Condition | Cost |
|---|---|---|
| Reuse | an existing component does this | none |
| Configure | it does this with a prop or class already supported | none |
| Extend | it nearly does this; add a variant, keep every consumer working | low |
| Refactor | it is structurally wrong and has few consumers | medium |
| Replace | it is wrong and every consumer benefits from the change | high |
| New | nothing exists and the pattern will recur | high |

A new component is the last resort, not the first instinct. Before writing one,
name the existing component you rejected and say why. If you cannot name one, you
have not looked.

## When redesign is justified

All three must hold:

1. You can name the structural property that causes the user problem. Not "it
   looks dated", but "the primary task requires three screens because the
   information is split by data model rather than by task".
2. Refine and Modernize would leave that property in place.
3. The structure axis has budget, or the user asked for it explicitly.

If you cannot satisfy all three, the honest answer is a Refine plus a note
recommending a redesign, with the reason. That note is more valuable than an
unrequested redesign.

## When to produce alternatives

Only at high impact and low confidence. Then produce at most three, each labelled
by how much it changes:

- **A, Preserve.** The smallest thing that addresses the defect.
- **B, Modernize.** The change you would recommend.
- **C, Rethink.** The structural option, with its cost stated.

Recommend one. An unranked menu moves the decision onto the user without giving
them anything you know and they do not.

## Writing the ledger

Before implementing, write four lists:

```
preserve   what is working and stays, named specifically
improve    what you are changing, each with the user problem it solves
uncertain  what you considered and are leaving alone, with the reason
forbidden  what you may not touch, from config and from the request
```

`preserve` must not be empty. If nothing is worth preserving, you are writing a
new product, and that needs saying out loud rather than doing quietly.
`forbidden` is absolute: a violation is a failed task, not a trade-off. It binds
CRAFT, not the client. A path that must be un-editable by anything needs an
`Edit()` deny rule in settings, which atlas step 5b emits.
