#!/usr/bin/env node
/**
 * Inspect a single surface and the conventions around it.
 *
 * Returns a summary, never a dump. The agent reads the target file itself; this
 * script exists to answer the questions that need counting rather than reading:
 * what does this file include, which conventions do its neighbours follow, and
 * which interaction states are missing.
 *
 * Usage: node inspect.mjs <target> [--json]
 */
import fs from 'node:fs';
import path from 'node:path';
import { projectRoot, walk, readIfExists } from './lib/paths.mjs';

// Enough neighbours to establish what the local convention is, few enough that
// the pass stays instant on a large directory.
const NEIGHBOUR_LIMIT = 12;

const STATE_SIGNALS = {
  loading: /\bloading\b|\bspinner\b|\bskeleton\b|aria-busy|is-loading|\bpending\b/i,
  empty: /empty[-_ ]?state|no[-_ ](results|records|data|items)|\bnothing\b|forelse|v-if="!.*length"/i,
  error: /\berror\b|\binvalid\b|@error|aria-invalid|role="alert"|\bdanger\b/i,
  disabled: /\bdisabled\b|aria-disabled|\bis-disabled\b/i,
  focus: /:focus|focus-visible|focus:|\bfocus-within\b/i,
};

const A11Y_SIGNALS = {
  aria: /\baria-[a-z]+=/gi,
  role: /\brole="/gi,
  alt: /\balt="/gi,
  label: /<label|aria-label/gi,
  tabindex: /\btabindex=/gi,
  heading: /<h[1-6][\s>]/gi,
};

export function inspect(target, root = projectRoot()) {
  const full = path.isAbsolute(target) ? target : path.join(root, target);
  const source = readIfExists(full);
  if (source === null) {
    return { error: 'not found: ' + target, target };
  }

  const dir = path.dirname(full);
  const ext = path.extname(full);
  const neighbours = siblings(dir, ext, full);

  return {
    target: path.relative(root, full),
    lines: source.split('\n').length,
    bytes: source.length,
    includes: includes(source),
    classes: classProfile(source),
    inline_styles: (source.match(/style\s*=\s*["']/gi) ?? []).length,
    hardcoded_colors: unique(source.match(/#[0-9a-fA-F]{3,8}\b/g) ?? []).slice(0, 10),
    states: Object.fromEntries(
      Object.entries(STATE_SIGNALS).map(([name, re]) => [name, re.test(source)])
    ),
    a11y: Object.fromEntries(
      Object.entries(A11Y_SIGNALS).map(([name, re]) => [name, (source.match(re) ?? []).length])
    ),
    neighbours: neighbours.map((file) => ({
      file: path.relative(root, file),
      classes: classProfile(readIfExists(file) ?? '').top.slice(0, 6),
    })),
    convention: convention(neighbours),
  };
}

function siblings(dir, ext, exclude) {
  let entries = [];
  try {
    entries = fs.readdirSync(dir)
      .map((name) => path.join(dir, name))
      .filter((file) => file !== exclude && file.endsWith(ext) && safeIsFile(file));
  } catch {
    return [];
  }
  return entries.slice(0, NEIGHBOUR_LIMIT);
}

function safeIsFile(file) {
  try {
    return fs.statSync(file).isFile();
  } catch {
    return false;
  }
}

function includes(source) {
  const found = [];
  const patterns = [
    /@include\(\s*['"]([^'"]+)/g,        // blade
    /<x-([a-z0-9._-]+)/gi,               // blade components
    /@extends\(\s*['"]([^'"]+)/g,        // blade layout
    /from\s+['"](\.[^'"]+)['"]/g,        // relative js imports
    /<([A-Z][A-Za-z0-9]+)[\s/>]/g,       // jsx/vue components
    /render\s+['"]([^'"]+)/g,            // erb partials
  ];
  for (const re of patterns) {
    for (const m of source.matchAll(re)) found.push(m[1]);
  }
  return unique(found).slice(0, 20);
}

function classProfile(source) {
  const classes = [];
  for (const m of source.matchAll(/class(?:Name)?\s*=\s*["']([^"']+)["']/gi)) {
    classes.push(...m[1].split(/\s+/).filter(Boolean));
  }
  const counts = new Map();
  for (const c of classes) counts.set(c, (counts.get(c) ?? 0) + 1);
  return {
    total: classes.length,
    distinct: counts.size,
    top: [...counts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 12).map(([c, n]) => c + ' (' + n + ')'),
  };
}

/**
 * What the neighbouring files agree on. This is the surface convention layer of
 * the precedence order, computed rather than assumed.
 */
function convention(files) {
  const counts = new Map();
  for (const file of files) {
    const source = readIfExists(file) ?? '';
    for (const m of source.matchAll(/class(?:Name)?\s*=\s*["']([^"']+)["']/gi)) {
      for (const c of m[1].split(/\s+/).filter(Boolean)) {
        counts.set(c, (counts.get(c) ?? 0) + 1);
      }
    }
  }
  const shared = [...counts.entries()]
    .filter(([, n]) => n >= Math.max(2, Math.ceil(files.length * 0.5)))
    .sort((a, b) => b[1] - a[1])
    .slice(0, 15)
    .map(([c]) => c);
  return { files: files.length, shared_classes: shared };
}

function unique(list) {
  return [...new Set(list)];
}

function main() {
  const args = process.argv.slice(2);
  const target = args.find((a) => !a.startsWith('--'));
  if (!target) {
    console.error('usage: node inspect.mjs <target> [--json]');
    process.exit(2);
  }
  const result = inspect(target);
  if (args.includes('--json')) {
    process.stdout.write(JSON.stringify(result, null, 2) + '\n');
    return;
  }
  if (result.error) {
    console.error(result.error);
    process.exit(1);
  }
  const missing = Object.entries(result.states).filter(([, present]) => !present).map(([n]) => n);
  console.log('# ' + result.target + '  (' + result.lines + ' lines)');
  console.log('includes      ' + (result.includes.join(', ') || 'none'));
  console.log('classes       ' + result.classes.distinct + ' distinct, ' + result.classes.total + ' uses');
  console.log('top classes   ' + (result.classes.top.slice(0, 8).join(', ') || 'none'));
  console.log('inline styles ' + result.inline_styles + ' | hardcoded colours: ' + (result.hardcoded_colors.join(', ') || 'none'));
  console.log('states missing ' + (missing.join(', ') || 'none'));
  console.log('a11y          ' + Object.entries(result.a11y).map(([k, v]) => k + ' ' + v).join(' | '));
  console.log('convention    ' + result.convention.files + ' neighbours share: ' + (result.convention.shared_classes.slice(0, 10).join(', ') || 'nothing'));
}

if (import.meta.url === 'file://' + process.argv[1]) main();
