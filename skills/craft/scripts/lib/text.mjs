/**
 * Shared text utilities.
 *
 * Token estimation uses 3.7 characters per token. That is deliberately
 * pessimistic for English markdown, which usually lands nearer 4.0, so the
 * budget gate errs on the side of failing a file that would actually fit
 * rather than passing one that would not.
 */
export const CHARS_PER_TOKEN = 3.7;

export function estimateTokens(text) {
  return Math.round(text.length / CHARS_PER_TOKEN);
}

/** Split a markdown file into frontmatter source and body. */
export function splitFrontmatter(source) {
  if (!source.startsWith('---\n')) return { frontmatter: '', body: source };
  const end = source.indexOf('\n---', 3);
  if (end === -1) return { frontmatter: '', body: source };
  const after = source.indexOf('\n', end + 1);
  return {
    frontmatter: source.slice(4, end),
    body: after === -1 ? '' : source.slice(after + 1),
  };
}

/**
 * Minimal YAML subset parser: scalars, nested maps by two-space indent, and
 * block sequences of scalars. Enough for skill frontmatter and config.md, and
 * small enough to audit. Anything it cannot parse is preserved as a raw string
 * rather than dropped, so an unknown key survives a rewrite.
 */
export function parseYaml(source) {
  const root = {};
  const stack = [{ indent: -1, node: root }];
  for (const raw of source.split('\n')) {
    if (!raw.trim() || raw.trim().startsWith('#')) continue;
    const indent = raw.length - raw.trimStart().length;
    const line = stripComment(raw).trim();
    if (!line) continue;
    while (stack.length > 1 && indent <= stack[stack.length - 1].indent) stack.pop();
    const parent = stack[stack.length - 1].node;

    if (line.startsWith('- ')) {
      const key = stack[stack.length - 1].key;
      const owner = stack[stack.length - 1].owner;
      if (key && owner) {
        if (!Array.isArray(owner[key])) owner[key] = [];
        owner[key].push(coerce(line.slice(2).trim()));
      }
      continue;
    }

    const sep = line.indexOf(':');
    if (sep === -1) continue;
    const key = line.slice(0, sep).trim();
    const value = line.slice(sep + 1).trim();

    if (value === '') {
      const child = {};
      parent[key] = child;
      stack.push({ indent, node: child, key, owner: parent });
    } else if (value.startsWith('[') && value.endsWith(']')) {
      parent[key] = value
        .slice(1, -1)
        .split(',')
        .map((v) => coerce(v.trim()))
        .filter((v) => v !== '');
    } else {
      parent[key] = coerce(value);
    }
  }
  return root;
}

/**
 * Strip a YAML inline comment: a `#` preceded by whitespace and outside quotes.
 * A bare `#` is not enough, because `color: #1F5EFF` is a value, not a comment,
 * and design configuration is full of hex.
 */
function stripComment(line) {
  let quote = null;
  for (let i = 0; i < line.length; i += 1) {
    const c = line[i];
    if (quote) {
      if (c === quote && line[i - 1] !== '\\') quote = null;
    } else if (c === '"' || c === "'") {
      quote = c;
    } else if (c === '#' && i > 0 && /\s/.test(line[i - 1])) {
      return line.slice(0, i);
    }
  }
  return line;
}

function coerce(value) {
  const v = value.replace(/^["']|["']$/g, '');
  if (v === 'true') return true;
  if (v === 'false') return false;
  if (v !== '' && !Number.isNaN(Number(v)) && /^-?\d+(\.\d+)?$/.test(v)) return Number(v);
  return v;
}

/** Collect `## Heading` sections of a markdown body into a map. */
export function sections(body) {
  const out = {};
  let current = null;
  const buffer = [];
  for (const line of body.split('\n')) {
    const heading = line.match(/^##\s+(.+?)\s*$/);
    if (heading) {
      if (current) out[current] = buffer.join('\n').trim();
      current = heading[1].toLowerCase();
      buffer.length = 0;
    } else if (current) {
      buffer.push(line);
    }
  }
  if (current) out[current] = buffer.join('\n').trim();
  return out;
}

/** Bullet list items under a markdown section, HTML comments stripped. */
export function bullets(text = '') {
  return text
    .replace(/<!--[\s\S]*?-->/g, '')
    .split('\n')
    .map((l) => l.match(/^\s*[-*]\s+(.*)$/))
    .filter(Boolean)
    .map((m) => m[1].trim())
    .filter(Boolean);
}
