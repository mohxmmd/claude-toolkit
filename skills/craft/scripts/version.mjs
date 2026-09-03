#!/usr/bin/env node
/**
 * Version management.
 *
 * A plugin's version is pinned in plugin.json, which means users receive an
 * update only when it is bumped. Three places have to agree or an install
 * resolves to something the changelog does not describe:
 *
 *   skills/craft/.claude-plugin/plugin.json  version
 *   .claude-plugin/marketplace.json          plugins[].version and metadata.version
 *   CHANGELOG.md                             the topmost released heading
 *
 * `--check` runs in CI. `--bump` does a release so the three cannot drift.
 *
 * Usage:
 *   node version.mjs --check
 *   node version.mjs --bump <major|minor|patch> [--schema]
 *   node version.mjs --current
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const PLUGIN_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const REPO_ROOT = path.resolve(PLUGIN_ROOT, '../..');

const PLUGIN_MANIFEST = path.join(PLUGIN_ROOT, '.claude-plugin/plugin.json');
const MARKETPLACE_MANIFEST = path.join(REPO_ROOT, '.claude-plugin/marketplace.json');
const CHANGELOG = path.join(REPO_ROOT, 'CHANGELOG.md');
const PATHS_LIB = path.join(PLUGIN_ROOT, 'scripts/lib/paths.mjs');

const SEMVER = /^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?$/;

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function writeJson(file, value) {
  fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
}

/** The newest released version in the changelog, ignoring an Unreleased section. */
function changelogVersion() {
  const source = fs.readFileSync(CHANGELOG, 'utf8');
  for (const line of source.split('\n')) {
    const m = line.match(/^##\s+\[?(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)\]?/);
    if (m) return m[1];
  }
  return null;
}

function schemaVersion() {
  const source = fs.readFileSync(PATHS_LIB, 'utf8');
  const m = source.match(/export const CRAFT_SCHEMA\s*=\s*(\d+)/);
  return m ? Number(m[1]) : null;
}

function collect() {
  const plugin = readJson(PLUGIN_MANIFEST);
  const marketplace = readJson(MARKETPLACE_MANIFEST);
  const entry = marketplace.plugins.find((p) => p.name === plugin.name);
  return {
    plugin,
    marketplace,
    entry,
    versions: {
      'plugin.json': plugin.version,
      'marketplace.json plugins[]': entry?.version,
      'marketplace.json metadata': marketplace.metadata?.version,
      'CHANGELOG.md': changelogVersion(),
    },
    schema: schemaVersion(),
  };
}

function check() {
  const { versions, schema } = collect();
  const problems = [];

  for (const [where, value] of Object.entries(versions)) {
    if (!value) problems.push('missing version in ' + where);
    else if (!SEMVER.test(value)) problems.push('not semantic versioning in ' + where + ': ' + value);
  }
  const distinct = new Set(Object.values(versions).filter(Boolean));
  if (distinct.size > 1) {
    problems.push('versions disagree: ' + Object.entries(versions).map(([k, v]) => k + '=' + v).join(', '));
  }
  if (!Number.isInteger(schema)) problems.push('CRAFT_SCHEMA is not an integer in scripts/lib/paths.mjs');

  for (const [where, value] of Object.entries(versions)) console.log(pad(where) + (value ?? '-'));
  console.log(pad('craft_schema') + schema);

  if (problems.length) {
    console.error('\nFAIL');
    for (const p of problems) console.error('  ' + p);
    process.exit(1);
  }
  console.log('\nPASS');
}

function bump(kind, alsoSchema) {
  const { plugin, marketplace, entry, versions } = collect();
  const m = String(plugin.version).match(SEMVER);
  if (!m) throw new Error('plugin.json version is not semantic versioning: ' + plugin.version);

  let [, major, minor, patch] = m.map(Number);
  if (kind === 'major') { major += 1; minor = 0; patch = 0; }
  else if (kind === 'minor') { minor += 1; patch = 0; }
  else if (kind === 'patch') { patch += 1; }
  else throw new Error('bump takes major, minor or patch');

  const next = major + '.' + minor + '.' + patch;

  plugin.version = next;
  writeJson(PLUGIN_MANIFEST, plugin);
  entry.version = next;
  if (marketplace.metadata) marketplace.metadata.version = next;
  writeJson(MARKETPLACE_MANIFEST, marketplace);

  const today = new Date().toISOString().slice(0, 10);
  const changelog = fs.readFileSync(CHANGELOG, 'utf8');
  const heading = '## [' + next + '] - ' + today;
  fs.writeFileSync(
    CHANGELOG,
    changelog.includes('## [Unreleased]')
      ? changelog.replace('## [Unreleased]', '## [Unreleased]\n\n' + heading)
      : changelog.replace(/(^# Changelog\n)/m, '$1\n' + heading + '\n')
  );

  if (alsoSchema) {
    const source = fs.readFileSync(PATHS_LIB, 'utf8');
    const current = schemaVersion();
    fs.writeFileSync(PATHS_LIB, source.replace(
      /export const CRAFT_SCHEMA\s*=\s*\d+/,
      'export const CRAFT_SCHEMA = ' + (current + 1)
    ));
    console.log('craft_schema ' + current + ' -> ' + (current + 1));
    console.log('A schema bump is a breaking change to .craft/. Document the migration in CHANGELOG.md.');
  }

  console.log(versions['plugin.json'] + ' -> ' + next);
  console.log('Edit the new CHANGELOG section, then: git commit && git tag v' + next);
}

function pad(text) {
  return (text + '                              ').slice(0, 30);
}

const args = process.argv.slice(2);
if (args.includes('--check')) check();
else if (args.includes('--current')) console.log(readJson(PLUGIN_MANIFEST).version);
else if (args.includes('--bump')) bump(args[args.indexOf('--bump') + 1], args.includes('--schema'));
else {
  console.error('usage: version.mjs --check | --current | --bump <major|minor|patch> [--schema]');
  process.exit(2);
}
