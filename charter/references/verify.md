# Verification

The rule, as it appears in the working agreement:

> Run the narrowest command that would fail if the change is wrong. If you ran nothing, say "not verified" and say why.

The second clause carries more weight than the first. The failure being addressed is a false completion report, not a missing test run.

## The matrix

| What changed | Narrowest useful check | Explicitly not |
| --- | --- | --- |
| Pure function, util, helper | The one existing test file, or a direct invocation with a real input | The full suite |
| Typed code | Typecheck scoped to the changed paths where the tool supports it | Whole-repo typecheck |
| Endpoint or handler | Call it once with a realistic payload; assert the status and one field | Re-reading the code and reasoning about it |
| UI | Render it and look, if a headless browser is available; otherwise say it was not visually verified | Asserting it looks right from the diff |
| Schema or migration | Apply up, then down, on a scratch database | Applying to anything shared |
| Build config, bundler, CI | Run the build | Trusting that the config parses |
| Dependency change | Install, then the smallest command that exercises the dependency | Assuming semver held |
| Copy, docs, comments | Nothing — say so plainly | Running the suite for appearances |
| **Money, auth, tenancy, data loss** | Full relevant suite **plus one adversarial case** | The narrow path — this row is the exception |

## Scoping a check

Prefer, in order:

1. The single test file covering the changed unit.
2. The test command filtered to a pattern — `--filter`, `-k`, `-run`, `--testNamePattern`.
3. The directory's tests.
4. The full suite, only when the change is cross-cutting or the risk row above applies.

## Reporting

State what ran and what it said. Three forms, and nothing else:

- `Verified: <command> — passed.`
- `Not verified: <reason>.` — no test exists, no runner installed, needs a browser, needs credentials.
- `Verified partially: <command> passed; <aspect> not checked because <reason>.`

Never write "should work", "this will fix it", or "tests pass" without having run them. If a command was skipped because it is slow, say that — it is a legitimate reason and the user can decide.

## When there is no test infrastructure

Plenty of real repositories have none. Verification is then a direct exercise of the change: run the script, call the endpoint, load the page, import the module. Anything that would actually fail. Do not treat an absent suite as permission to skip checking, and do not propose adding a test framework unless asked.
