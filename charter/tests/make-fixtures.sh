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

echo "fixtures rebuilt in $F"
