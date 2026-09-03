#!/usr/bin/env bash
# charter/survey.sh — deterministic repository facts for Charter.
#
# Contract:
#   in   : $1 = repo root (default: $PWD)
#   out  : "key: value" lines on stdout, <= 80 lines
#   never: reads file CONTENTS beyond named manifests; never network; never writes.
#
# Secrets policy: .env and key files are reported by NAME ONLY, never opened.

set -u
ROOT="${1:-$PWD}"
cd "$ROOT" 2>/dev/null || { echo "error: cannot enter $ROOT"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }
JQ=0; have jq && JQ=1

# join a newline list into a comma list, capped
cap() { tr '\n' ',' | sed 's/,$//' | cut -c1-300; }
first() { head -n "${2:-8}"; }

say() { printf '%s: %s\n' "$1" "$2"; }
sayif() { [ -n "${2:-}" ] && say "$1" "$2"; }

echo "# charter survey v1"
say root "$ROOT"

# ---------------------------------------------------------------- git
if git rev-parse --git-dir >/dev/null 2>&1; then
  say git yes
  say git.head "$(git rev-parse HEAD 2>/dev/null || echo none)"
  say git.branch "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"
  DEF=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
  [ -z "$DEF" ] && for b in main master develop; do
    git show-ref --verify --quiet "refs/heads/$b" && DEF=$b && break
  done
  say git.default_branch "${DEF:-unknown}"
  REM=$(git remote get-url origin 2>/dev/null | sed -E 's#(git@|https://)([^:/]+).*#\2#')
  say git.remote_host "${REM:-none}"
  say git.commits "$(git rev-list --count HEAD 2>/dev/null || echo 0)"
  say git.authors_90d "$(git log --since=90.days --format='%ae' 2>/dev/null | sort -u | wc -l | tr -d ' ')"
  say git.shallow "$([ -f "$(git rev-parse --git-dir)/shallow" ] && echo yes || echo no)"
  say git.style_conventional "$(git log -30 --format=%s 2>/dev/null | grep -cE '^(feat|fix|chore|docs|refactor|test|perf|build|ci)(\(.+\))?!?:' || true)/30"
else
  say git no
fi

# ---------------------------------------------------------------- stack
STACK=""
for m in package.json composer.json pyproject.toml requirements.txt go.mod Cargo.toml \
         Gemfile pom.xml build.gradle build.gradle.kts pubspec.yaml Package.swift mix.exs; do
  [ -f "$m" ] && STACK="$STACK$m
"
done
sayif stack.manifests "$(printf '%s' "$STACK" | cap)"
[ -f package.json ] && {
  PM=npm
  [ -f pnpm-lock.yaml ] && PM=pnpm
  [ -f yarn.lock ] && PM=yarn
  [ -f bun.lockb ] && PM=bun
  say stack.node_pm "$PM"
}
[ -f composer.json ] && say stack.php_pm composer

# framework fingerprints (dependency NAMES only, from manifests we are allowed to read)
FW=""
add_fw() { grep -q "\"$1\"" "$2" 2>/dev/null && FW="$FW$1
"; }
if [ -f package.json ]; then
  for d in next react vue svelte @angular/core nuxt express fastify nestjs vite astro remix; do
    add_fw "$d" package.json
  done
fi
if [ -f composer.json ]; then
  for d in laravel/framework symfony/framework-bundle livewire/livewire slim/slim; do
    add_fw "$d" composer.json
  done
fi
sayif stack.frameworks "$(printf '%s' "$FW" | cap)"

# ---------------------------------------------------------------- monorepo
MONO=""
for f in pnpm-workspace.yaml turbo.json nx.json lerna.json rush.json go.work; do
  [ -f "$f" ] && MONO="$MONO$f
"
done
[ -d packages ] && MONO="${MONO}packages/
"
[ -d apps ] && MONO="${MONO}apps/
"
sayif monorepo.markers "$(printf '%s' "$MONO" | cap)"
[ -n "$MONO" ] && {
  say monorepo.package_count "$(find packages apps -maxdepth 2 -name package.json 2>/dev/null | wc -l | tr -d ' ')"
}

# ---------------------------------------------------------------- commands
if [ -f package.json ]; then
  if [ "$JQ" = 1 ]; then
    S=$(jq -r '.scripts // {} | keys[]' package.json 2>/dev/null | first - 14 | cap)
  else
    S=$(sed -n '/"scripts"/,/}/p' package.json | grep -oE '"[a-zA-Z0-9:_-]+" *:' \
        | tr -d '":' | sed 's/ *$//' | grep -v '^scripts$' | first - 14 | cap)
  fi
  sayif cmd.npm_scripts "$S"
fi
if [ -f composer.json ] && [ "$JQ" = 1 ]; then
  sayif cmd.composer_scripts "$(jq -r '.scripts // {} | keys[]' composer.json 2>/dev/null | first - 10 | cap)"
fi
[ -f Makefile ] && sayif cmd.make_targets \
  "$(grep -E '^[a-zA-Z0-9_.-]+:' Makefile | cut -d: -f1 | sort -u | first - 12 | cap)"
[ -f justfile ] || [ -f Justfile ] && sayif cmd.just_recipes \
  "$(grep -hE '^[a-zA-Z0-9_-]+( .*)?:' justfile Justfile 2>/dev/null | cut -d: -f1 | cut -d' ' -f1 | sort -u | first - 12 | cap)"
[ -f Taskfile.yml ] && say cmd.taskfile yes

# binaries that are actually present
BINS=""
for b in vendor/bin/phpunit vendor/bin/pest vendor/bin/pint vendor/bin/php-cs-fixer \
         vendor/bin/phpstan vendor/bin/psalm node_modules/.bin/jest node_modules/.bin/vitest \
         node_modules/.bin/eslint node_modules/.bin/tsc node_modules/.bin/biome; do
  [ -x "$b" ] && BINS="$BINS$b
"
done
sayif cmd.local_bins "$(printf '%s' "$BINS" | cap)"

# ---------------------------------------------------------------- quality gates
Q=""
for f in tsconfig.json jsconfig.json mypy.ini .mypy.ini pyrightconfig.json phpstan.neon \
         psalm.xml .eslintrc .eslintrc.json .eslintrc.cjs eslint.config.js biome.json \
         .prettierrc .prettierrc.json pint.json .php-cs-fixer.php ruff.toml .rubocop.yml \
         phpunit.xml phpunit.xml.dist pytest.ini tox.ini jest.config.js vitest.config.ts \
         playwright.config.ts cypress.config.js .golangci.yml; do
  [ -e "$f" ] && Q="$Q$f
"
done
sayif quality.configs "$(printf '%s' "$Q" | cap)"
for d in tests test spec __tests__ src/test; do
  [ -d "$d" ] && say quality.test_dir "$d" && break
done

# ---------------------------------------------------------------- ci
[ -d .github/workflows ] && sayif ci.github \
  "$(ls .github/workflows 2>/dev/null | first - 8 | cap)"
for f in .gitlab-ci.yml Jenkinsfile .circleci/config.yml azure-pipelines.yml bitbucket-pipelines.yml; do
  [ -e "$f" ] && say ci.other "$f"
done

# ---------------------------------------------------------------- instructions
INS=""
for f in CLAUDE.md .claude/CLAUDE.md CLAUDE.local.md AGENTS.md .cursorrules \
         .github/copilot-instructions.md .windsurfrules .clinerules CONTRIBUTING.md; do
  [ -f "$f" ] && INS="$INS$f($(wc -l <"$f" | tr -d ' ')L)
"
done
[ -d .cursor/rules ] && INS="$INS.cursor/rules/($(ls .cursor/rules | wc -l | tr -d ' ')f)
"
[ -d .claude/rules ] && INS="$INS.claude/rules/($(ls .claude/rules 2>/dev/null | wc -l | tr -d ' ')f)
"
[ -d docs ] && INS="${INS}docs/($(find docs -name '*.md' 2>/dev/null | wc -l | tr -d ' ')md)
"
sayif instructions.found "$(printf '%s' "$INS" | cap)"
FENCE=$(grep -l 'charter:start' CLAUDE.md .claude/CLAUDE.md 2>/dev/null | head -1)
say instructions.charter_fence "${FENCE:-none}"
say settings.project "$([ -f .claude/settings.json ] && echo yes || echo no)"
say settings.local "$([ -f .claude/settings.local.json ] && echo yes || echo no)"

# ---------------------------------------------------------------- danger surface
D=""
for d in database/migrations migrations db/migrate prisma/migrations alembic \
         terraform infra k8s kubernetes helm ansible deploy .platform charts; do
  [ -d "$d" ] && D="$D$d/
"
done
for f in Dockerfile docker-compose.yml compose.yaml fly.toml vercel.json Procfile \
         serverless.yml netlify.toml app.yaml cloudbuild.yaml; do
  [ -f "$f" ] && D="$D$f
"
done
sayif danger.paths "$(printf '%s' "$D" | cap)"
# NAMES ONLY — contents are never read.
# Templates are split out: .env.example must stay READABLE, because adding a new
# variable to it is normal work. A blanket Read(./.env.*) deny would block that.
ENVALL=$(ls -a 2>/dev/null | grep -E '^\.env' || true)
sayif danger.secret_files \
  "$(printf '%s\n' "$ENVALL" | grep -vE '\.(example|sample|template|dist)$' | grep . | first - 6 | cap)"
sayif danger.secret_templates \
  "$(printf '%s\n' "$ENVALL" | grep -E '\.(example|sample|template|dist)$' | grep . | first - 4 | cap)"
say danger.gitignored_env "$([ -f .gitignore ] && grep -qE '^\.?env' .gitignore && echo yes || echo no)"

# database CLI presence in the stack
DB=""
{ [ -d prisma ] || grep -qiE '"prisma"' package.json 2>/dev/null; } && DB="${DB}prisma
"
[ -d database/migrations ] && DB="${DB}laravel-artisan
"
[ -f manage.py ] && DB="${DB}django
"
[ -d db/migrate ] && DB="${DB}rails
"
[ -d alembic ] && DB="${DB}alembic
"
grep -qiE 'knex|drizzle|typeorm|sequelize' package.json 2>/dev/null && DB="${DB}node-orm
"
sayif danger.db_tooling "$(printf '%s' "$DB" | cap)"

# ---------------------------------------------------------------- shape
if git rev-parse --git-dir >/dev/null 2>&1; then
  N=$(git ls-files 2>/dev/null | wc -l | tr -d ' ')
else
  N=$(find . -type f -not -path './.git/*' 2>/dev/null | head -60000 | wc -l | tr -d ' ')
fi
say shape.tracked_files "$N"
# "new" requires BOTH a tiny tree AND no manifest — a 6-file repo with a full
# package.json is a small project, not a greenfield one.
COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo 0)
if { [ "$N" -lt 15 ] && [ -z "$STACK" ]; } || [ "$COMMITS" = 0 ]; then
  SC=new
elif [ "$N" -lt 400 ]; then SC=small
elif [ "$N" -lt 5000 ]; then SC=medium
else SC=large
fi
say shape.size_class "$SC"
say shape.top_dirs "$(find . -maxdepth 1 -type d -not -name '.' -not -name '.git' 2>/dev/null \
  | sed 's#^\./##' | sort | first - 14 | cap)"
if [ "$N" -lt 50000 ] && git rev-parse --git-dir >/dev/null 2>&1; then
  say shape.top_ext "$(git ls-files 2>/dev/null | sed -n 's/.*\.\([a-zA-Z0-9]\{1,6\}\)$/\1/p' \
    | sort | uniq -c | sort -rn | head -6 | awk '{printf "%s(%s) ", $2, $1}')"
fi

echo "# end"
