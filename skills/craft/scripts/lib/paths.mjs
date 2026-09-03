/** Project and .craft path resolution. */
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

export const CRAFT_SCHEMA = 1;
const ROOT_MARKERS = ['.git', 'package.json', 'composer.json', 'Gemfile', 'go.mod', 'pyproject.toml'];

/**
 * Walk up from `start` to the nearest directory that looks like a project root.
 * An existing `.craft/` wins over every other marker, so a configured project
 * keeps its root even when a nested package would otherwise claim it.
 */
export function projectRoot(start = process.cwd()) {
  let dir = path.resolve(start);
  const home = path.resolve(os.homedir());
  let fallback = null;
  while (true) {
    if (fs.existsSync(path.join(dir, '.craft'))) return dir;
    if (!fallback && ROOT_MARKERS.some((m) => fs.existsSync(path.join(dir, m)))) fallback = dir;
    const parent = path.dirname(dir);
    if (parent === dir || dir === home) break;
    dir = parent;
  }
  return fallback ?? path.resolve(start);
}

export function craftDir(root = projectRoot()) {
  return path.join(root, '.craft');
}

export function craftPaths(root = projectRoot()) {
  const base = craftDir(root);
  return {
    root,
    base,
    config: path.join(base, 'config.md'),
    state: path.join(base, 'state.json'),
    atlas: path.join(base, 'atlas'),
    decisions: path.join(base, 'decisions.md'),
    surfaces: path.join(base, 'surfaces'),
    cache: path.join(base, 'cache'),
  };
}

export function profilePaths() {
  const base = path.join(os.homedir(), '.craft');
  return {
    base,
    preferences: path.join(base, 'preferences.md'),
    profile: path.join(base, 'profile.json'),
    evidence: path.join(base, 'evidence'),
  };
}

export function readIfExists(file) {
  try {
    return fs.readFileSync(file, 'utf8');
  } catch {
    return null;
  }
}

export function readJsonIfExists(file) {
  const raw = readIfExists(file);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

const SKIP_DIRS = new Set([
  'node_modules', '.git', 'vendor', 'dist', 'build', 'out', '.next', '.nuxt',
  'coverage', 'storage', 'public/vendor', '.craft', 'tmp', '.cache', 'target',
]);

/** Bounded recursive walk. Caps exist so a boot pass can never walk a monorepo. */
export function walk(dir, { exts, maxFiles = 4000, maxDepth = 8 } = {}) {
  const found = [];
  const visit = (current, depth) => {
    if (depth > maxDepth || found.length >= maxFiles) return;
    let entries;
    try {
      entries = fs.readdirSync(current, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      if (found.length >= maxFiles) return;
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) {
        if (SKIP_DIRS.has(entry.name) || entry.name.startsWith('.')) continue;
        visit(full, depth + 1);
      } else if (!exts || exts.some((e) => entry.name.endsWith(e))) {
        found.push(full);
      }
    }
  };
  visit(dir, 0);
  return found;
}
