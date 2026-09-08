#!/usr/bin/env bash
# Regenerate the test fixtures. They are gitignored: nested .git directories
# would otherwise be treated as submodules by the outer repo.
#
#   ./tests/make-fixtures.sh && ./tests/run.sh

set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
F="$HERE/fixtures"
rm -rf "$F"
mkdir -p "$F"
gitinit() { git init -q .; }
commit() { git add -A; git -c user.email=t@t -c user.name=t commit -qm "$1"; }

# ---------------------------------------------------------------- node-app
mkdir -p "$F/node-app/src" "$F/node-app/prisma/migrations"
cd "$F/node-app"
cat > package.json <<'EOF'
{"name":"node-app","version":"1.0.0",
 "scripts":{"test":"vitest run","lint":"eslint .","typecheck":"tsc --noEmit",
            "build":"vite build","deploy":"vercel --prod"},
 "dependencies":{"next":"14.0.0","react":"18.2.0"}}
EOF
echo '{}' > tsconfig.json
touch .env .env.example vercel.json
printf 'node_modules\n.env\n' > .gitignore
echo 'console.log(1)' > src/index.ts
gitinit; commit "feat: init"

# ---------------------------------------------------------------- go-cli
# No package.json path. Makefile-only commands. No database, no deploy surface.
mkdir -p "$F/go-cli/cmd/app"
cd "$F/go-cli"
printf 'module example.com/app\n\ngo 1.22\n' > go.mod
printf 'test:\n\tgo test ./...\nlint:\n\tgo vet ./...\nbuild:\n\tgo build ./cmd/app\n' > Makefile
echo 'package main' > cmd/app/main.go
gitinit; commit "initial"

# ---------------------------------------------------------------- infra
# Maximum danger surface. Every deploy deny rule should fire.
mkdir -p "$F/infra/terraform" "$F/infra/k8s"
cd "$F/infra"
echo 'terraform {}' > terraform/main.tf
echo 'apiVersion: v1' > k8s/deploy.yaml
touch .env.production terraform/secrets.tfvars
gitinit; commit "infra"

# ---------------------------------------------------------------- empty
mkdir -p "$F/empty-repo"
cd "$F/empty-repo"
gitinit

# ------------------------------------------------- companion config fixtures
# Fake CLAUDE_CONFIG_DIR trees. companions.sh reads these instead of the real
# ~/.claude, so the suite never depends on what the developer has installed.

# cfg-none: no plugins, no style file anywhere.
mkdir -p "$F/cfg-none/plugins"
echo '{"version":1,"plugins":{}}' > "$F/cfg-none/plugins/installed_plugins.json"
echo '{}' > "$F/cfg-none/settings.json"

# cfg-plugin: both companions installed and enabled. Style is "tars:TARS".
mkdir -p "$F/cfg-plugin/plugins"
cat > "$F/cfg-plugin/plugins/installed_plugins.json" <<'JSON'
{"version":1,"plugins":{"tars@claude-toolkit":{"version":"1.1.0"},"craft@claude-toolkit":{"version":"0.1.0"}}}
JSON
echo '{}' > "$F/cfg-plugin/settings.json"

# cfg-file: TARS installed as a FILE, no plugins. Style is bare "TARS".
# This is the pair that breaks if the name is ever constructed rather than read.
mkdir -p "$F/cfg-file/plugins" "$F/cfg-file/output-styles"
echo '{"version":1,"plugins":{}}' > "$F/cfg-file/plugins/installed_plugins.json"
echo '{}' > "$F/cfg-file/settings.json"
printf -- '---\nname: TARS\n---\nbe direct\n' > "$F/cfg-file/output-styles/TARS.md"

# cfg-disabled: installed but switched off. Must NOT be offered.
mkdir -p "$F/cfg-disabled/plugins"
cat > "$F/cfg-disabled/plugins/installed_plugins.json" <<'JSON'
{"version":1,"plugins":{"tars@claude-toolkit":{"version":"1.1.0"},"craft@claude-toolkit":{"version":"0.1.0"}}}
JSON
cat > "$F/cfg-disabled/settings.json" <<'JSON'
{"enabledPlugins":{"tars@claude-toolkit":false,"craft@claude-toolkit":false}}
JSON

# wired: a repo that already has a fence naming /craft and a local outputStyle.
mkdir -p "$F/wired/.claude"
cd "$F/wired"
printf '# Project\n\n<!-- charter:start v1 -->\nUI/screen work: `/craft`\n<!-- charter:end -->\n' > CLAUDE.md
echo '{"outputStyle":"tars:TARS"}' > .claude/settings.local.json
gitinit; commit "wired"

echo "fixtures rebuilt in $F"
