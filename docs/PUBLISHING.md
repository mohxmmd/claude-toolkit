# Publishing to GitHub

What to do to get this repository onto GitHub and installable by other people.

The end state: someone runs two commands and has your tools.

```bash
claude plugin marketplace add <you>/claude-toolkit
claude plugin install toolkit@claude-toolkit
```

Nothing here requires a GitHub Action, a package registry, or a release
pipeline. A Claude Code marketplace is a git repository with a JSON file in it.

---

## Before you push

### 1. Replace the placeholder identity

Three things carry a name that is probably not yours. Change them everywhere:

| What | Where |
|---|---|
| `mohxmmd` | Every URL in every README, `install.sh`, and both docs directories |
| `Mohammed` | The `owner` and `author` fields in all five manifests |
| `claude-toolkit` | The repository name, if you rename it |

Find every occurrence first:

```bash
grep -rn 'mohxmmd\|Mohammed' --include='*.md' --include='*.json' --include='*.sh' .
```

Change them in one pass:

```bash
grep -rl 'mohxmmd' --include='*.md' --include='*.json' --include='*.sh' . \
  | xargs sed -i 's/mohxmmd/YOUR-USERNAME/g'
```

On macOS, `sed -i ''` instead of `sed -i`.

**The marketplace name is separate from the repository name.** `name` in
`.claude-plugin/marketplace.json` is what people type after `@` when installing.
Renaming the repository does not change it, and changing it breaks the install
command for everyone who already added you.

### 2. Confirm nothing personal is in the tree

```bash
git status --porcelain --ignored | grep '^!!'
```

`.gitignore` already excludes `.claude/settings.local.json`, `.claude/charter.json`
and the generated test fixtures. Confirm they are listed as ignored, not staged.
`settings.local.json` in particular is machine-local and may hold your own
permission grants.

### 3. Run the gate

Everything CI will run, locally, before it runs in public:

```bash
# manifests parse
for f in .claude-plugin/marketplace.json \
         skills/craft/.claude-plugin/plugin.json \
         skills/charter/.claude-plugin/plugin.json \
         output-styles/.claude-plugin/plugin.json \
         bundles/toolkit/.claude-plugin/plugin.json; do
  node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" || echo "BAD: $f"
done

# plugins validate
for d in ./skills/charter ./skills/craft ./output-styles ./bundles/toolkit; do
  npx -y @anthropic-ai/claude-code plugin validate "$d"
done

# scripts parse
for f in skills/charter/scripts/*.sh skills/charter/tests/*.sh; do bash -n "$f"; done
for f in skills/craft/scripts/*.mjs skills/craft/scripts/lib/*.mjs; do node --check "$f"; done
sh -n install.sh

# behaviour and budget
./skills/charter/tests/make-fixtures.sh && ./skills/charter/tests/run.sh
node skills/craft/scripts/version.mjs --check
node skills/craft/scripts/budget.mjs
```

All of it must pass. A marketplace that fails validation installs and then does
nothing, which is the worst failure mode available because it looks like success.

---

## Pushing

```bash
git init                       # if this is not already a repository
git add -A
git commit -m "feat: Claude Toolkit — Charter, Craft, TARS and the bundle"
```

Create the repository and push. With the GitHub CLI:

```bash
gh repo create claude-toolkit --public --source=. --remote=origin --push
```

Or by hand, after creating an empty repository in the web UI:

```bash
git remote add origin https://github.com/YOUR-USERNAME/claude-toolkit.git
git branch -M main
git push -u origin main
```

**The repository must be public** for anyone else to install from it. A private
repository works for you alone, provided your local git can authenticate to it.

---

## Verifying it actually installs

Do not skip this. Test it the way a stranger would, from a clean directory:

```bash
claude plugin marketplace add YOUR-USERNAME/claude-toolkit
claude plugin install toolkit@claude-toolkit
claude plugin list
```

Expect four plugins: `toolkit`, and the three it pulled in as dependencies.

Restart Claude Code, then in a scratch repository:

```
/toolkit:setup
```

If `/toolkit:setup` does not exist, one of the three dependencies failed to
enable — Claude Code disables a plugin whose dependencies are unsatisfied.
`claude plugin list` will show which.

### Removing your test install

```bash
claude plugin uninstall toolkit@claude-toolkit
claude plugin prune
claude plugin marketplace remove claude-toolkit
```

---

## Releasing a version

> **Pushing to `main` does not ship anything.** The plugin cache is keyed by
> version. If you change a plugin's files without bumping its version,
> `claude plugin update` replies *"already at the latest version"* and every
> existing user keeps running the old code — including you.
>
> ```console
> $ claude plugin update toolkit@claude-toolkit
> ✔ toolkit is already at the latest version (0.1.0).      # nothing happened
> ```
>
> **Every change users should receive needs a version bump.** A one-line
> documentation fix inside a plugin directory is a patch release.

Versions live in two places that must agree: each `plugin.json` and the matching
entry in `.claude-plugin/marketplace.json`. CI enforces this, and there is a
built-in command that checks it too:

```bash
claude plugin tag ./skills/charter --dry-run     # check without tagging
claude plugin tag ./skills/charter --push        # tag and push it
```

It validates the manifest against the enclosing marketplace entry, refuses to
run on a dirty working tree, and creates a `charter--v0.1.0` git tag.

A release, end to end:

```bash
# 1. bump BOTH the plugin.json and the marketplace entry
# 2. write the CHANGELOG entry — what changed and which failure it fixes
# 3. verify they agree
node -e '
  const fs=require("fs");
  const mk=JSON.parse(fs.readFileSync(".claude-plugin/marketplace.json","utf8"));
  for (const p of mk.plugins) {
    const m=JSON.parse(fs.readFileSync(p.source.replace(/^\.\//,"")+"/.claude-plugin/plugin.json","utf8"));
    console.log(m.version===p.version ? `ok   ${p.name} ${p.version}` : `BAD  ${p.name}`);
  }'

# 4. commit, then tag — it refuses to run on a dirty tree, which is the point
git commit -am "release: charter 0.2.0"
git push
claude plugin tag ./skills/charter --push
```

**Bumping a component means checking the bundle.** `bundles/toolkit` pins its
dependencies with `^` ranges. A major bump of any component — or a minor bump on
a `0.x` line, which semver treats as breaking — needs the bundle's range updated
in the same commit. CI fails the build if it does not resolve.

Users get the new version with:

```bash
claude plugin marketplace update claude-toolkit    # refresh the catalogue first
claude plugin update toolkit@claude-toolkit        # then the plugin
```

Both steps matter: the first refreshes the marketplace's view of what versions
exist, the second fetches the plugin. Then restart Claude Code.

---

## What to put in the repository description

The install command is the most useful thing you can put in front of someone, so
lead with it. Suggested GitHub "About" text:

> Charter, Craft and TARS for Claude Code. `claude plugin marketplace add
> YOUR-USERNAME/claude-toolkit`

Topics worth adding: `claude-code`, `claude`, `ai`, `plugin`, `marketplace`,
`output-style`, `developer-tools`.

---

## Optional, and worth it

**Branch protection on `main`.** Settings → Branches → require the CI check to
pass. The gate is only a gate if it cannot be bypassed.

**Issue templates.** Already in `.github/ISSUE_TEMPLATE/`. They are live as soon
as you push.

**A LICENSE that names you.** `LICENSE` is Apache-2.0. Check the copyright line
says what you want it to.

**Enable Discussions** if you want questions somewhere other than the issue
tracker.

---

## Things that commonly go wrong

| Symptom | Cause |
|---|---|
| `marketplace add` fails | Repository is private, or `.claude-plugin/marketplace.json` is missing or malformed |
| Plugin installs, commands never appear | You did not restart. Plugins load at session start |
| `/toolkit:setup` missing after installing the bundle | A dependency is disabled, so the bundle is disabled too |
| A plugin's `source` path 404s | `source` in the marketplace is relative to the repository root and is case-sensitive |
| Version mismatch on install | `plugin.json` and the marketplace entry disagree. Run the check above |
| Pushed a fix, users still see the old behaviour | You did not bump the version. The cache is keyed by it |
| `plugin update` says "already at the latest version" | Same cause — bump the version, push, then update |
| Output style not in `/config` | Wrong name — a plugin install is `tars:TARS`, a file install is `TARS` |
