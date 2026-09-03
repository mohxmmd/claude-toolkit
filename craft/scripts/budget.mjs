#!/usr/bin/env node
/**
 * Repository gate. Fails CI when CRAFT breaks its own contract.
 *
 * A token budget added after the fact is a token budget nobody keeps, so this
 * runs from the first commit. It checks three classes of thing:
 *
 *   1. Token budgets, because context cost is a product property here.
 *   2. Agent Skills spec conformance, so the skills stay portable outside
 *      Claude Code, where only six frontmatter fields are accepted.
 *   3. Structural rules that affect whether Claude reads a file completely:
 *      references one level deep, and a table of contents on long ones.
 *
 * Usage: node budget.mjs [--json]
 * Exit:  0 pass, 1 violations found, 2 could not run
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { splitFrontmatter, parseYaml, estimateTokens } from './lib/text.mjs';

const PLUGIN_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

/**
 * Budgets in tokens of SKILL.md *body*. Frontmatter is excluded because its
 * metadata is preloaded for every skill regardless of whether the skill runs,
 * so charging it to the body double counts.
 */
const BUDGETS = {
  'skills/craft/SKILL.md': { tokens: 1500, lines: 150 },
  'skills/atlas/SKILL.md': { tokens: 2000, lines: 220 },
  'router/INDEX.md': { tokens: 1200, lines: 160 },
  reference: { tokens: 2000, lines: 260 },
};

// Claude may preview a long file with a partial read. A table of contents at
// the top means it still sees the full scope of what the file covers.
const TOC_REQUIRED_LINES = 100;

// The six fields the Agent Skills spec accepts. Anything else hard-errors on
// claude.ai upload and API packaging, so a skill meant to be portable must not
// use one. Claude Code-only fields are allowed but reported.
const SPEC_FIELDS = new Set(['name', 'description', 'license', 'compatibility', 'metadata', 'allowed-tools']);
const CLAUDE_CODE_FIELDS = new Set([
  'when_to_use', 'argument-hint', 'arguments', 'disable-model-invocation', 'user-invocable',
  'disallowed-tools', 'model', 'effort', 'context', 'agent', 'background', 'hooks', 'paths', 'shell',
]);
const RESERVED_NAME_WORDS = ['anthropic', 'claude'];
const MAX_DESCRIPTION = 1024;
const MAX_NAME = 64;

const violations = [];
const notes = [];

function fail(file, rule, message) {
  violations.push({ file, rule, message });
}

function note(file, rule, message) {
  notes.push({ file, rule, message });
}

function checkSkill(relative) {
  const full = path.join(PLUGIN_ROOT, relative);
  if (!fs.existsSync(full)) return fail(relative, 'missing', 'file does not exist');

  const source = fs.readFileSync(full, 'utf8');
  if (!source.startsWith('---\n')) {
    return fail(relative, 'frontmatter', 'frontmatter must start on line 1 or the whole file is treated as content');
  }

  const { frontmatter, body } = splitFrontmatter(source);
  const meta = parseYaml(frontmatter);
  const budget = BUDGETS[relative];

  if (!meta.name) fail(relative, 'frontmatter', 'name is required');
  if (!meta.description) fail(relative, 'frontmatter', 'description is required');

  if (meta.name) {
    if (String(meta.name).length > MAX_NAME) fail(relative, 'name', 'over ' + MAX_NAME + ' characters');
    if (!/^[a-z0-9-]+$/.test(String(meta.name))) fail(relative, 'name', 'must be lowercase letters, numbers and hyphens only');
    for (const word of RESERVED_NAME_WORDS) {
      if (String(meta.name).includes(word)) fail(relative, 'name', 'contains the reserved word "' + word + '"');
    }
  }
  if (meta.description && String(meta.description).length > MAX_DESCRIPTION) {
    fail(relative, 'description', String(meta.description).length + ' characters, limit ' + MAX_DESCRIPTION);
  }
  if (meta.description && /^(I |You )/.test(String(meta.description))) {
    fail(relative, 'description', 'must be third person; first or second person harms skill discovery');
  }

  for (const key of Object.keys(meta)) {
    if (!SPEC_FIELDS.has(key) && !CLAUDE_CODE_FIELDS.has(key)) {
      fail(relative, 'frontmatter', 'unknown field "' + key + '"');
    } else if (!SPEC_FIELDS.has(key)) {
      note(relative, 'portability', '"' + key + '" is a Claude Code extension and is rejected by claude.ai upload');
    }
  }

  const tokens = estimateTokens(body);
  const lines = source.split('\n').length - 1;
  if (budget) {
    if (tokens > budget.tokens) fail(relative, 'tokens', tokens + ' body tokens, budget ' + budget.tokens);
    if (lines > budget.lines) fail(relative, 'lines', lines + ' lines, budget ' + budget.lines);
  }

  checkLinks(relative, full, body);
  return { tokens, lines };
}

/**
 * Every reference must be reachable in one hop from the file that names it.
 * Claude may only partially read a file reached through a chain of references,
 * which produces confident answers built on half a document.
 */
function checkLinks(relative, full, body) {
  for (const m of body.matchAll(/\[[^\]]+\]\(([^)]+)\)/g)) {
    const href = m[1];
    if (/^(https?:|#|mailto:)/.test(href)) continue;
    const resolved = path.resolve(path.dirname(full), href);
    if (!fs.existsSync(resolved)) fail(relative, 'link', 'broken link: ' + href);
  }
}

function checkReference(full) {
  const relative = path.relative(PLUGIN_ROOT, full);
  const source = fs.readFileSync(full, 'utf8');
  const { body } = splitFrontmatter(source);
  const tokens = estimateTokens(body || source);
  const lines = source.split('\n').length - 1;

  if (tokens > BUDGETS.reference.tokens) fail(relative, 'tokens', tokens + ' tokens, budget ' + BUDGETS.reference.tokens);
  if (lines > BUDGETS.reference.lines) fail(relative, 'lines', lines + ' lines, budget ' + BUDGETS.reference.lines);
  if (lines > TOC_REQUIRED_LINES && !/^##\s*Contents/m.test(source)) {
    fail(relative, 'toc', 'over ' + TOC_REQUIRED_LINES + ' lines and has no "## Contents" table of contents');
  }
  checkLinks(relative, full, source);
  return { relative, tokens, lines };
}

function checkJson(relative) {
  const full = path.join(PLUGIN_ROOT, relative);
  if (!fs.existsSync(full)) return fail(relative, 'missing', 'file does not exist');
  try {
    return JSON.parse(fs.readFileSync(full, 'utf8'));
  } catch (error) {
    return fail(relative, 'json', 'invalid JSON: ' + error.message);
  }
}

function listReferences() {
  const base = path.join(PLUGIN_ROOT, 'references');
  if (!fs.existsSync(base)) return [];
  const out = [];
  for (const group of fs.readdirSync(base)) {
    const dir = path.join(base, group);
    if (!fs.statSync(dir).isDirectory()) continue;
    for (const file of fs.readdirSync(dir)) {
      if (file.endsWith('.md')) out.push(path.join(dir, file));
    }
  }
  return out;
}

function main() {
  const skills = ['skills/craft/SKILL.md', 'skills/atlas/SKILL.md'];
  const results = { skills: {}, references: [], router: null };

  for (const skill of skills) results.skills[skill] = checkSkill(skill);

  const routerIndex = path.join(PLUGIN_ROOT, 'router/INDEX.md');
  if (fs.existsSync(routerIndex)) {
    const source = fs.readFileSync(routerIndex, 'utf8');
    const tokens = estimateTokens(source);
    const lines = source.split('\n').length - 1;
    results.router = { tokens, lines };
    if (tokens > BUDGETS['router/INDEX.md'].tokens) {
      fail('router/INDEX.md', 'tokens', tokens + ' tokens, budget ' + BUDGETS['router/INDEX.md'].tokens);
    }
    checkLinks('router/INDEX.md', routerIndex, source);
  } else {
    fail('router/INDEX.md', 'missing', 'file does not exist');
  }

  for (const file of listReferences()) results.references.push(checkReference(file));

  const plugin = checkJson('.claude-plugin/plugin.json');
  if (plugin && !plugin.name) fail('.claude-plugin/plugin.json', 'schema', 'name is required');
  if (plugin && !plugin.version) fail('.claude-plugin/plugin.json', 'schema', 'version is required for reproducible installs');
  if (plugin?.version && !/^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$/.test(plugin.version)) {
    fail('.claude-plugin/plugin.json', 'semver', 'version "' + plugin.version + '" is not semantic versioning');
  }

  if (process.argv.includes('--json')) {
    process.stdout.write(JSON.stringify({ violations, notes, results }, null, 2) + '\n');
  } else {
    report(results);
  }
  process.exit(violations.length ? 1 : 0);
}

function report(results) {
  console.log('CRAFT budget gate\n');
  for (const [file, r] of Object.entries(results.skills)) {
    if (r) console.log(pad(file) + r.tokens + ' tokens / ' + r.lines + ' lines  (budget ' + BUDGETS[file].tokens + ' / ' + BUDGETS[file].lines + ')');
  }
  if (results.router) console.log(pad('router/INDEX.md') + results.router.tokens + ' tokens / ' + results.router.lines + ' lines  (budget 1200 / 160)');

  if (results.references.length) {
    const total = results.references.reduce((sum, r) => sum + r.tokens, 0);
    const worst = [...results.references].sort((a, b) => b.tokens - a.tokens)[0];
    console.log('\n' + pad('references') + results.references.length + ' files, ' + total + ' tokens total, largest ' + worst.relative + ' at ' + worst.tokens);
  }

  if (notes.length) {
    console.log('\nNotes');
    for (const n of notes) console.log('  ' + n.file + ' [' + n.rule + '] ' + n.message);
  }

  if (violations.length) {
    console.log('\nFAIL: ' + violations.length + ' violation' + (violations.length === 1 ? '' : 's'));
    for (const v of violations) console.log('  ' + v.file + ' [' + v.rule + '] ' + v.message);
  } else {
    console.log('\nPASS');
  }
}

function pad(text) {
  return (text + '                              ').slice(0, 30);
}

main();
