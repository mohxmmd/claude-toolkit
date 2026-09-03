# Forms and settings

A form is a request for work. The design job is to reduce the work, not to
decorate the request.

## Diagnose

1. How many fields are visible? How many are required to complete the primary
   task? The gap between those two numbers is the opportunity.
2. Is every field's purpose clear without reading help text?
3. Where does validation happen, and what does the user see when it fails?
4. Are labels persistent, or are they placeholders that vanish on focus?
5. Can the form be completed with a keyboard alone, in a sensible tab order?
6. What happens on submit: is there a pending state, and is double submission
   prevented?

## Rules

- **Labels above inputs, always visible.** A placeholder is not a label. It
  disappears exactly when the user needs it, and it fails for screen readers and
  for anyone returning to a half-filled form.
- **Group by the user's mental model, not the database schema.** Fields that are
  decided together belong together.
- **Optional is marked, required is not**, when most fields are required. Invert
  when most are optional. Marking everything marks nothing.
- **Validate on blur, not on every keystroke.** Keystroke validation tells people
  they are wrong while they are still typing. Re-validate on submit.
- **Errors name the problem and the recovery.** "Enter a date after today", not
  "Invalid input". Put the message beside the field, not only at the top.
- **One primary action.** Cancel is a text link. Destructive actions live away
  from the primary, not beside it.
- **Progressive disclosure beats a long page**, but only when the hidden fields
  are genuinely rare. Hiding a commonly used field to look tidier costs the user
  a click every time.

## Simplification, carefully

Reducing visible fields is the highest-value change available on most forms, and
the easiest to get wrong. Before collapsing or hiding a field:

- Confirm it is not required by a business rule, a compliance requirement, or a
  downstream system. If you cannot confirm it from the code, do not touch it.
- Prefer sensible defaults over removal. A field with a good default is cheaper
  than a field that is gone and later missed.
- Moving a field into an "Advanced" group is reversible. Deleting it is not.

Complexity that encodes a real rule stays. The goal is simple for the user, never
simplistic for the product.

## Accessibility, non-negotiable

- Every input has a `<label for>` or an `aria-label`. Placeholder is not enough.
- Errors use `aria-invalid` and are associated with `aria-describedby`.
- The error summary, if present, links to the fields and moves focus there.
- Required fields use `required` or `aria-required`, not only a red asterisk.
- Fieldsets with legends for radio and checkbox groups.
- Focus is visible on every control, including custom selects and date pickers.

## Common defects

| Defect | Fix |
|---|---|
| Placeholder as label | persistent label above the input |
| Errors only at the top | inline beside the field, and keep the summary |
| Submit with no pending state | disable-on-submit plus a spinner, restore on failure |
| Cancel styled like submit | cancel is a link |
| Uniform spacing across unrelated fields | group with space |
| Help text that repeats the label | delete it, or make it say something new |

## Preserve

Field order, field names and validation rules are product truth. Change layout
and presentation freely; change what is asked, or what is required, only when
the user asked you to.

## Verify

Keyboard through every control in order. Submit empty. Submit with one field
wrong. Submit valid. Check the pending state, the error state, and 375px, where
label-above-input matters most.
