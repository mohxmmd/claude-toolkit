# Spacing and density

Space is how an interface communicates what belongs together. Change it before
you change anything structural, because it is the cheapest lever that produces a
visible improvement.

## Diagnose

1. Find the spacing unit the product already uses. Do not invent one.
2. Measure the gaps between related items and between unrelated groups. If they
   are the same, grouping is doing no work.
3. Check the space above and below a heading. Below should be smaller.
4. Look for values off the scale: `13px`, `7px`, `22px` in a 4px system.
5. Check density against the use scene, not against taste. An operator tool used
   all day earns more density than a page seen once a month.

## The one rule that fixes most surfaces

**Tight within a group, generous between groups.** Most cramped-and-confusing
surfaces have uniform spacing. Most airy-and-vague surfaces have uniform spacing
too. The fix in both cases is differentiation, not a global increase.

A heading belongs to the content beneath it, so the space above it must be larger
than the space below it. Getting this one relationship right often resolves a
complaint about hierarchy without touching type at all.

## Common defects

| Defect | Signal | Fix |
|---|---|---|
| Uniform rhythm | every gap identical | differentiate group gaps from item gaps |
| Orphan heading | equal space above and below | more above, less below |
| Off-scale values | `13px` in a 4px system | snap to the nearest scale step |
| Edge crowding | content touching the viewport at 375px | one scale step of inline padding minimum |
| Double gap | margin plus padding plus gap stacking | pick one owner of the space |
| Uneven optical alignment | icons and text baselines out by 1-2px | align optically, not numerically |

## Density

Density is a product decision, recorded in config. Do not change it as a side
effect of another task. Increasing whitespace on a dense operator tool is a
regression even when it photographs better.

When density genuinely needs to change, move one scale step and stop. Two steps
is a different product.

## Preserve

- **Use the product's scale.** If it is 4px, every value is a multiple of 4. If
  it is an 8px scale with a 4px half-step, respect that.
- **Do not introduce a new spacing token** when an existing one is within one
  step. A near-duplicate token is design-system drift, and drift costs more later
  than the 2px gains now.
- Prefer changing the values on the surface to changing the scale. Changing the
  scale is a structural change with a project-wide blast radius.

## Verify

- Every value you touched is on the product's scale.
- Group boundaries are visible without borders.
- Nothing touches the viewport edge at 375px.
- The change survives long content: a 60-character label, an empty value, a
  number four digits longer than the example.
