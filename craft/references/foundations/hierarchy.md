# Hierarchy

Hierarchy is the order in which a person notices things. Diagnose it by looking,
not by reasoning about the markup.

## Diagnose

Squint at the surface, or blur it, and answer in order:

1. What do you see first? Is it what the user came for?
2. What is the one action this surface exists to support? Is it the most
   prominent thing, or is it tied with three others?
3. Can you tell the primary content from the chrome without reading?
4. How many things compete at the top level? Three or more is usually the defect.
5. Where does the eye go after the first stop? Is that a useful second stop?

Write the answer as a user problem before proposing anything. "The user cannot
tell which button completes the task" is a defect. "Weak hierarchy" is not.

## Common defects, in the order they usually matter

| Defect | Signal | Smallest fix |
|---|---|---|
| Competing primaries | two or more filled or coloured buttons in one action group | one primary, the rest text or outline |
| Flat type scale | headings and body within 2px, or the same weight | change weight and colour before changing size |
| Everything emphasised | many bold, coloured or boxed elements | remove emphasis from the majority; emphasis is relative |
| Chrome outranks content | headers, toolbars and labels louder than the data | mute the chrome, do not amplify the content |
| No grouping | one flat list of unrelated fields or rows | group with space first, borders second, boxes last |
| Label louder than value | metadata labels at the same weight as their values | labels muted and smaller, values at body weight |

## Rules

- **Emphasis is a budget.** Emphasising everything spends it on nothing. If you
  add emphasis somewhere, remove it somewhere else.
- **Reach for weight and colour before size.** Size changes layout and breaks
  rhythm; weight and colour usually do not, which makes them the cheaper tool in
  a preserve-first change.
- **Three levels is usually enough** on a working surface: primary, secondary,
  muted. A fourth level is rarely readable.
- **Position is hierarchy too.** Moving something is often stronger than styling
  it, but it costs structure budget. Style first when style will do.
- **The most important thing is not the largest thing.** It is the thing with the
  most contrast against its neighbours.

## Preserve

Do not restyle a heading scale that is consistent across the product just because
it is subtle. A quiet but consistent scale is a design decision. Check two or
three neighbouring surfaces before concluding the scale is wrong rather than the
one surface.

If the product uses a convention you would not have chosen, for example labels
above values in uppercase, keep it. Consistency with the product outranks your
preference for the pattern.

## Verify

- The primary action is identifiable in a blurred screenshot.
- Heading levels descend without skipping (h1, h2, h3), because screen reader
  users navigate by them.
- Emphasis survives at 375px, where less fits and hierarchy matters more.
- Nothing relies on colour alone to communicate its rank.
