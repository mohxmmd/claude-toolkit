# Craft floor

Load immediately before editing UI. Never on a planning-only turn.

These are checks on the built result, not intentions. Run them together in the
batched inspection round; they share one render. Config and the product's own
committed language override anything here. Your habit does not.

## Contents

- Verify
- Reach for first
- Default to avoiding
- Never

## Verify

- **Contrast.** Body and placeholder text at 4.5:1, large text and UI borders at
  3:1. On a coloured surface, tint secondary text from that hue rather than
  greying it.
- **Focus.** Every interactive element has a visible focus state that is not the
  browser default removed. Check it with the keyboard, not by reading the CSS.
- **Targets.** Interactive elements are at least 24 by 24 CSS pixels, and 44 on
  surfaces used on phones.
- **Spacing.** Read the computed values. Tight within groups, generous between
  them, more space above a heading than below it.
- **Type.** Body measure between 45 and 80 characters. Real content at every
  breakpoint, not lorem ipsum. Fix what overflows.
- **States.** Hover, focus, active, disabled, loading, empty, error. All present
  and all reachable.
- **Motion.** `prefers-reduced-motion` honoured wherever motion was added.
  Animate transform and opacity; not width, height, top or left.
- **Overflow.** Nothing clipped or horizontally scrolling at 375px.
- **Copy.** The product's own vocabulary. Controls name their action, errors name
  the problem and the recovery, an action keeps its name through the whole flow.
- **Tokens.** Every value you wrote exists in the product's system. A hex literal
  beside a token that already holds that value is drift you introduced.

## Reach for first

The cheap levers, in order, because they produce visible improvement without
spending structure budget:

1. Weight and colour, before size.
2. Space, before borders. Borders, before boxes.
3. Alignment, before decoration.
4. Removing an element, before restyling it.
5. An existing component, before a new one.

## Default to avoiding

These are the category's defaults rather than choices. The brief, the config, or
the product's own committed language can earn any of them. Reaching for one when
the axis is free means you were not deciding.

- Cards as the page's structure, and nested cards in any circumstance.
- A modal for a task that needs neither interruption nor protected focus.
- Gradient text. Emphasis comes from weight and colour.
- Glass and blur as decoration rather than as a specific, needed effect.
- Zero-blur or zero-offset "glow" shadows. Depth has an offset and a soft blur.
- Emoji standing in for an icon system.
- Monospace as a costume for "technical" rather than for code, data or
  measurement.
- Animating everything identically on entrance.
- A new accent colour where the product already has one.

None of these is banned. If the product already does one of them consistently,
it is the product's language and it stays.

## Never

These are not preferences.

- Change behaviour, permissions, data semantics or business rules.
- Touch anything in the ledger's `forbidden` list.
- Move fonts, brand colours, logo treatment, navigation identity or product
  terminology without an explicit request.
- Introduce a second visual language into a product that has one.
- Remove a state, a label or a field to make a surface look tidier.
- Report the work as done without saying which verification level actually ran.
