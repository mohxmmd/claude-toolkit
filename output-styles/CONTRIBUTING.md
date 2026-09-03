# Contributing to TARS

TARS is a behavioral prompt. That makes contributions harder to evaluate than
code: there is no test suite that goes red. The bar is evidence.

## The one rule

**A proposed rule change needs a transcript.** Run the scenario with the current
TARS and with your edit, and paste both. Reasoning about what a prompt "should"
do is not evidence. Prompts routinely do something other than what they say.

## How to test a behavioral change

```bash
# 1. Copy the style under a new name so you can switch back
cp output-styles/TARS.md ~/.claude/output-styles/TARS-test.md
sed -i 's/^name: TARS$/name: TARS-test/' ~/.claude/output-styles/TARS-test.md

# 2. Make your edit to TARS-test.md

# 3. Run the same prompt under both styles in a throwaway project
mkdir -p /tmp/tars-check/.claude && cd /tmp/tars-check
echo '{"outputStyle":"TARS"}' > .claude/settings.local.json
claude -p "your scenario here" < /dev/null

echo '{"outputStyle":"TARS-test"}' > .claude/settings.local.json
claude -p "your scenario here" < /dev/null
```

Note your Claude Code version (`claude --version`) in the PR. Behavior shifts
between versions, and a result from an old version may not reproduce.

Model output varies between runs. A single pair of transcripts is a signal, not
a proof. If a change is subtle, run it three times each way and say so.

## What makes a good contribution

**Strong:**

- A transcript where TARS does something clearly wrong, plus the minimal rule
  change that fixes it, plus a transcript showing the fix.
- Evidence that a rule does nothing. Rules that do not change behavior are pure
  token cost and should be deleted.
- A scenario that exposes a conflict between two existing rules.
- Documentation fixes, especially anywhere the docs claim behavior TARS does not
  actually produce.
- Compatibility results from a Claude Code version other than the one in the
  README, particularly whether plugin-bundled output styles load on yours.

**Weak:**

- Rules added because they sound right.
- Rewording that does not change behavior. It costs review time and risks
  changing behavior by accident.
- New sections. Five is enough. Prefer a line in an existing section.
- Making TARS harsher. Bluntness is a means to clarity, not the point.

## Scope of the project

TARS is one output style file plus the documentation around it. Things that are
out of scope:

- Multiple style variants in this repo. Fork, or use the customization recipes.
- Skills, hooks, agents, or MCP servers. Different tools for different jobs.
- Anything that needs installing beyond copying a Markdown file.

If a change makes the file longer, it needs to justify the tokens.

## Reporting a problem

Open an issue with:

1. Your Claude Code version and OS
2. The prompt you gave
3. What TARS did
4. What you expected instead

"It felt too aggressive" is a valid report. Include the transcript so the tone
can be judged rather than described.

## Pull requests

- One behavioral change per PR.
- Update `CHANGELOG.md` under an `Unreleased` heading.
- If you change `output-styles/TARS.md`, say in the PR body which section you
  touched and which failure mode it addresses.
- Do not add a rule and an example of the rule to the docs without having run
  it. Fabricated transcripts are the one thing that would make this project
  worthless.

## License

Contributions are accepted under the Apache-2.0 license in [LICENSE](../LICENSE),
the license for this repository.
