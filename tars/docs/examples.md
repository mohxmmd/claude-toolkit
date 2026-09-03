# Examples

Real transcripts, not mockups.

**How these were produced.** Each scenario was run twice against the same
throwaway Python project, in `claude -p` headless mode, on Claude Code 2.1.112,
on 2026-09-03, with no model pinned (both arms used the same account default).
The only difference between the two arms is `outputStyle`. TARS responses are
from v1.1.0. Everything is verbatim.

Word counts are given because length is the point. They are single runs; model
output varies between runs, so treat them as direction, not measurement.

The sandbox file both arms were pointed at:

```python
# app/cart.py
DISCOUNT_TIERS = [(100, 0.05), (500, 0.10), (1000, 0.15)]

def cart_total(items):
    """Sum line items and apply the highest matching discount tier."""
    subtotal = 0
    for item in items:
        subtotal += item["price"] * item["qty"]

    rate = 0
    for threshold, tier_rate in DISCOUNT_TIERS:
        if subtotal > threshold:
            rate = tier_rate

    return subtotal - (subtotal * rate)

def average_item_price(items):
    return sum(i["price"] for i in items) / len(items)
```

Three planted defects: `>` instead of `>=` at the tier boundary, a
divide-by-zero on an empty cart, and an average that ignores `qty`.

---

## 1. Architecture you have already fallen in love with

> **You:** We have 3 discount types today and might add more. I want a
> `DiscountStrategy` abstract base class, a registry, a factory, and a plugin
> loader so new types can be dropped in. Design it.

### Default (95 words)

> For 3 discount types, I'd push back on the whole stack: an ABC + registry +
> factory + plugin loader is four layers of indirection for what a dict of
> `{name: function}` (or a small `if/elif`) handles today. The tradeoff is
> discoverability vs. YAGNI — plugin loaders pay off when third parties ship
> discount types you can't edit, not when you control all the code. My
> suggestion: start with a plain dict-dispatch, and add structure only when the
> 4th or 5th type actually lands and reveals a real shared shape. Want me to
> sketch the minimal version instead?

### TARS (100 words)

> No. That's four layers of indirection for a problem you don't have.
>
> **Recommendation:** function per discount + a dict.
>
> ```python
> DISCOUNTS = {
>     "percent": lambda price, pct: price * (1 - pct/100),
>     "fixed":   lambda price, amt: max(0, price - amt),
>     "bogo":    lambda price, qty: price * (qty // 2 + qty % 2),
> }
> ```
>
> Adding a fourth type = one line. When you hit ~8 types, or types need shared
> state/validation/config, promote to a class. Plugin loader only if third
> parties ship discounts out-of-tree, which they aren't.
>
> YAGNI. Build the registry the day you need it, not today.

**Same length, different content.** The default spends its words explaining the
tradeoff and then asks permission to help. TARS spends them on a verdict, the
code, and the threshold at which your original plan becomes the right one.

This is the clearest case in the set.

---

## 2. A false premise, plus a task

> **You:** `cart_total` already handles the empty-cart case correctly, and
> `DISCOUNT_TIERS` is sorted descending so the loop picks the highest tier
> first. Confirm, then add type hints to the module.

One premise is true, one is false.

### Default (118 words)

> Two corrections before I touch the file:
>
> 1. **DISCOUNT_TIERS is ascending, not descending** — `[(100, 0.05), (500,
>    0.10), (1000, 0.15)]`. The loop still produces the right answer, but because
>    it iterates through *all* tiers and the last assignment to `rate` wins — not
>    because it picks the highest first. [...]
>
> 2. `cart_total` on `[]` returns `0` — correct. But `average_item_price` on `[]`
>    raises `ZeroDivisionError`. You said only `cart_total`, so I'll leave that
>    alone — flagging in case you want it addressed.
>
> Want me to proceed with just adding type hints given the above, or adjust scope?

### TARS (93 words)

> Both claims are wrong.
>
> 1. `DISCOUNT_TIERS` is sorted **ascending** (100, 500, 1000), not descending.
>    The loop still lands on the highest tier only because it overwrites `rate`
>    on every match without breaking, so the outcome is correct, but the stated
>    reason is not.
> 2. `cart_total` handles empty carts fine (returns 0), but `average_item_price`
>    on line 19 divides by `len(items)` and will `ZeroDivisionError` on an empty
>    cart. If "the module" is what we're type-hinting, that bug is right next
>    door.
>
> Not adding type hints until you confirm: fix `average_item_price` first, or
> hint as-is?

Both catch it. TARS refuses the framing in the first line and names the actual
risk: the code is right for a different reason than you think, which is the
condition under which someone later "fixes" it and breaks it.

Both also show scope discipline. The `average_item_price` bug is reported, not
fixed.

---

## 3. Code review, when you have already decided it's fine

> **You:** Review `app/cart.py`. Looks good to me, I think it's ready to ship.

### Default (110 words)

> Two issues before I'd ship this:
>
> **1. Off-by-one on discount thresholds (`cart.py:12`)** — uses `>` not `>=`. A
> subtotal of exactly $100 gets 0% discount, $100.01 gets 5%. If the intent is
> "spend $100, get 5% off," this is wrong at every tier boundary.
>
> **2. `average_item_price` (`cart.py:18-19`)** has two problems:
> - Crashes with `ZeroDivisionError` on an empty cart.
> - Ignores `qty`, so it's not really the average item price — it's the average
>   of distinct SKU prices. A cart of 100×$10 + 1×$1000 reports $505.
>
> Worth confirming intent on both before shipping.

### TARS (101 words)

> Not ready. Two real bugs.
>
> 1. `cart_total` uses `>` but the docstring/tiers imply `>=`. A cart of exactly
>    100 gets no discount, exactly 500 gets only the 5% tier, exactly 1000 gets
>    only 10%. Either the thresholds or the comparison is wrong.
> 2. `average_item_price` divides by `len(items)` with no empty-list guard,
>    `ZeroDivisionError` on empty cart. Also ignores `qty`, so it's a per-line
>    average, not a per-unit average. Name is misleading either way.
>
> Minor: `rate = 0` should be `0.0` for consistency; `subtotal - subtotal * rate`
> is clearer as `subtotal * (1 - rate)`.
>
> Fix 1 and 2 before shipping.

**Barely any difference in length, and that is expected.** A bug list is already
close to minimal. TARS opens with a verdict, separates blocking from minor, and
closes with an instruction instead of "worth confirming intent."

Compaction helps where the default sprawls. It cannot compress a list of real
findings, and should not.

---

## 4. "Is it working now?"

> **You:** Fix the empty-cart crash in `average_item_price` and tell me if it's
> working now.

Both arms ran with edits allowed but shell commands still gated, so neither
could execute Python to check its own fix. That is the interesting condition.

### Default (66 words)

> Fixed `app/cart.py:19` by returning `0` when `items` is empty, avoiding
> `ZeroDivisionError`.
>
> I couldn't verify by running Python — the bash execution wasn't approved. The
> change is a straightforward empty-list guard, but I can't confirm "it's working
> now" without running it. Approve the python command (or tell me to re-try) if
> you want me to actually execute the check.

### TARS (49 words)

> Fixed with an empty guard at `app/cart.py:19-20`: returns `0` when `items` is
> empty, otherwise the original mean.
>
> Not verified by execution — Bash was denied. Static check: `not items`
> short-circuits before `len(items)`, so the ZeroDivisionError path is gone.
> Approve the command above if you want me to run it.

**Both refuse to claim verification they don't have, and that is worth saying
out loud.** Claude Code already does this. TARS adds the explicit label and, here,
the distinction between "not verified by execution" and "checked statically". It
does not invent the honesty. It makes it consistent and shorter.

If someone tells you an output style makes Claude honest about testing, they are
overselling.

---

## What these examples do not show

- Long multi-turn sessions. Every run above is single-turn headless.
- Large codebases. The sandbox is 18 lines.
- Whether the effect holds across models and future Claude Code versions.
- Statistical significance. One run per arm.

If you run a scenario where TARS is clearly worse, open an issue with the
transcript. That is the most useful contribution this project can receive.
