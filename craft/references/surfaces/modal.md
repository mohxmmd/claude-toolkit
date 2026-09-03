# Modals, dialogs and drawers

A modal interrupts. It has to earn that, and then it has to be easy to leave.

## Diagnose

1. Does this need to be a modal? Interruption is justified by a decision that
   must be made now, or by focus that must be protected. Not by convenience.
2. Can the user tell what will happen when they confirm, without scrolling?
3. Is there exactly one primary action?
4. Does Escape close it, does the backdrop close it, and do those two agree?
5. Where does focus go on open, and where does it return on close?
6. What happens at 375px tall content: does it scroll inside, or does the page
   scroll behind it?

## Anatomy

| Part | Rule |
|---|---|
| Title | Names the decision, not the object. "Delete 3 tickets?" beats "Confirm" |
| Body | The consequence, in one or two lines. What is irreversible, say so |
| Primary action | One. Its label repeats the title's verb: title "Delete", button "Delete" |
| Secondary | Text or outline weight, never a second filled button |
| Dismiss | Escape, backdrop click, and a close control all available and consistent |

An action keeps its name through the whole flow. A button that says "Publish"
produces a message that says "Published", not "Saved successfully".

## Common defects

| Defect | Why it hurts | Fix |
|---|---|---|
| Three equal-weight footer buttons | the user must read all three to choose | one primary, others de-emphasised |
| Title competing with the record title inside | two things claim to be the heading | mute one, usually the record title into a subtitle |
| Destructive action styled as primary by default | encourages the irreversible path | destructive is available, not preselected |
| No focus trap | keyboard users tab into the page behind | trap focus, restore it on close |
| Body scrolls the page behind it | disorienting on touch | scroll inside the modal, lock the body |
| Modal for a non-decision | interruption with no payoff | inline it, or use a drawer or a page |

## Accessibility, non-negotiable

- `role="dialog"` with `aria-modal="true"`, and a label via `aria-labelledby`
  pointing at the title.
- Focus moves into the dialog on open, is trapped inside it, and returns to the
  trigger on close.
- Escape closes it, unless data would be lost silently; then confirm.
- The backdrop is inert to screen readers.
- Touch targets in the footer are at least 24 by 24 CSS pixels, and 44 is better
  where the surface is used on phones.

## Preserve

Keep the product's existing modal mechanics: its transition, its backdrop
opacity, its close affordance, its width. Those are product identity, and users
have learned them. Improve what is inside the modal before you touch the modal
itself.

If the product opens modals from a shared component, change the shared component
only when every consumer benefits. Otherwise fix the instance.

## Verify

Open, tab through every control, Escape, reopen, confirm focus returned to the
trigger. Then check 375px with content twice as long as the example, plus the
loading and error states of whatever the primary action does.
