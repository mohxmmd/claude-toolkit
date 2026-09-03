# Tables and dense lists

A table is for comparison. Every decision follows from which columns people
actually compare.

## Diagnose

1. Which column is the row's identity? Is it first, and is it the strongest?
2. Which columns do people scan, and which do they only read once they have
   found the row? The second group can be quieter, narrower, or hidden.
3. Are numbers right-aligned and tabular? Misaligned digits defeat comparison.
4. What happens at 375px? Horizontal scroll, stacked cards, or broken layout?
5. Are the row actions discoverable without hover? Hover-only actions do not
   exist on touch.
6. Is there an empty state, a loading state, and a "your filter matched nothing"
   state, which is not the same as empty?

## Rules

- **Identity column first, left aligned, strongest weight.** Everything else is
  supporting evidence.
- **Numbers right aligned with tabular figures** (`font-variant-numeric:
  tabular-nums`). This single change fixes most "the table looks messy"
  complaints without moving anything.
- **Dates and statuses are scannable, not decorative.** A status needs a text
  label; colour alone fails for colour-blind users and in greyscale printouts.
- **Row density is a product decision.** Do not loosen a dense operator table
  because it looks better in a screenshot. Check config first.
- **Zebra striping or row borders, not both.** Pick whichever the product already
  uses.
- **Actions are visible or in a per-row menu.** Never hover-only.

## Responsive

Mobile is not a smaller desktop table. Choose one strategy and apply it
consistently across the product:

| Strategy | Use when |
|---|---|
| Horizontal scroll with a pinned identity column | many columns, all needed, comparison matters |
| Stacked cards, one per row | few columns, reading beats comparing |
| Priority columns, the rest behind a disclosure | a clear ranking of column importance |

Whichever the product already uses elsewhere is the one to use here. A second
strategy in the same product is worse than a suboptimal first one.

## Common defects

| Defect | Fix |
|---|---|
| Every column equal weight | mute everything but identity and the compared column |
| Centred numbers | right align, tabular figures |
| Header indistinguishable from first row | weight or background on the header, not both |
| Hover-only actions | always visible, or in a row menu |
| No empty state | add one; say what would put rows here |
| Filtered-to-nothing shows the empty state | different message: the filter, and how to clear it |
| Truncation with no recourse | title attribute at minimum, or a detail view |

## Preserve

Column order encodes how the team thinks about the data. Do not reorder columns
to improve visual balance. Reordering is a structural change and needs a reason
stated in user terms.

## Verify

375, 768, 1440. One row with the longest realistic content in every column. Zero
rows. One row. Loading. Keyboard: can you reach a row action without a mouse?
