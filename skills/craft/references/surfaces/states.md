# States

Most interfaces are designed for the state where everything worked and there is
data. Users spend a surprising amount of their time in the other states, and
those states are where trust is won or lost.

## The states every surface owes

| State | Question it answers | Failure if missing |
|---|---|---|
| Empty, first run | what is this, and how do I start? | the user thinks it is broken |
| Empty, filtered | why is this blank now? | the user thinks their data is gone |
| Loading | is something happening? | the user clicks again |
| Partial | some of it arrived | flicker, layout jumps |
| Error | what went wrong, and what now? | the user is stuck |
| Disabled | why can I not do this? | the user retries or leaves |
| Success | did it work? | the user re-submits |

Empty-first-run and empty-after-filtering are different states with different
copy. Showing "No tickets yet" to someone whose filter matched nothing is a bug,
not a nuance.

## Rules

- **Empty states are invitations.** Say what would put content here, and give the
  action that does it. Do not decorate an empty state with an illustration
  instead of a next step.
- **Loading matches the shape of what is coming.** A skeleton in the layout's own
  proportions beats a centred spinner, because it prevents the layout jump.
- **Errors name the problem and the recovery**, in the interface's voice. Not
  "Something went wrong". Which thing, and what to do.
- **Disabled controls explain themselves.** A tooltip or helper text saying why.
  A disabled button with no reason is a dead end.
- **Success is quiet and specific.** The verb from the action: "Published", not
  "Success!".
- **Never lose the user's input on an error.** Repopulate the form.

## Copy

Write from the user's side of the screen. Name things by what people control,
not by how the system is built. A person manages notifications, not webhook
configuration.

Errors do not apologise and are never vague about what happened. An empty screen
is an invitation to act. Keep the register plain: active voice, sentence case, no
filler.

## Accessibility

- Loading regions use `aria-busy`, and content that arrives asynchronously is
  announced with a polite live region.
- Errors that appear after an action use `role="alert"` so they are announced.
- Disabled controls that must stay reachable use `aria-disabled` rather than the
  `disabled` attribute, which removes them from the tab order.
- Do not communicate any state through colour alone.

## Common defects

| Defect | Fix |
|---|---|
| No empty state at all | add one with a next action |
| Same message for empty and filtered-empty | separate copy, plus a clear-filter action |
| Centred spinner replacing the whole layout | skeleton in the layout's shape |
| Error toast that disappears in 3 seconds | persistent inline error; toasts are for success |
| "Something went wrong" | name the operation and the recovery |
| Disabled with no explanation | say why, beside or on hover and focus |
| Layout jumps when data arrives | reserve the space in the loading state |

## Preserve

Use the product's existing state components. If there is a shared empty-state
component, extend it rather than authoring a second one. A second pattern for the
same state is worse than an imperfect single pattern.

## Verify

Force each state and look at it: no data, filtered to nothing, slow network,
server error, one item, and the maximum realistic number of items.
