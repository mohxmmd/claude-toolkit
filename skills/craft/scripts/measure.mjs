#!/usr/bin/env node
/**
 * Atlas measurement pass.
 *
 * Reads a codebase and reports the design system it actually uses: colours,
 * type, spacing, radius, shadow, motion, breakpoints, icons, plus five design
 * dials. Every value carries an evidence count and a confidence, because a
 * value used twice and a value used two hundred times mean different things and
 * the difference decides whether CRAFT asks a question or writes silently.
 *
 * Usage: node measure.mjs [--root <dir>] [--json]
 */
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { projectRoot, walk, readIfExists, readJsonIfExists } from './lib/paths.mjs';

// Scan caps. A boot-adjacent pass must stay predictable on a large monorepo;
// 1,200 files is well past the point where another sample changes a dominant
// value, and 400KB skips minified bundles without skipping real stylesheets.
const MAX_FILES = 1200;
const MAX_FILE_BYTES = 400_000;

// A value is canonical when it accounts for at least 60% of its kind's uses.
// Below 35% there is no dominant value at all and CRAFT must ask rather than
// guess. Between the two it writes the leader and records the drift.
const HIGH_CONFIDENCE = 0.6;
const LOW_CONFIDENCE = 0.35;

const STYLE_EXT = ['.css', '.scss', '.sass', '.less', '.styl'];
const MARKUP_EXT = ['.html', '.vue', '.svelte', '.astro', '.jsx', '.tsx', '.blade.php', '.erb', '.twig', '.hbs', '.php'];
const CODE_EXT = ['.ts', '.js', '.mjs'];

export function measure(root = projectRoot()) {
  MEASURE_ROOT = root;
  const collected = collectFiles(root);
  const read = readCorpus(collected.files);
  const { corpus, derived } = dropDerived(read);
  const stack = detectStack(root, corpus);

  const colors = tally(corpus, COLOR_RE, normaliseColor);
  const fonts = tally(corpus, FONT_RE, (m) => cleanFont(m[1] ?? m[2]));
  const radius = tally(corpus, RADIUS_RE, (m) => meaningful(m[1]));
  const shadows = tally(corpus, SHADOW_RE, (m) => meaningful(m[1], 80));
  const spacing = tally(corpus, SPACING_RE, (m) => meaningful(m[2]));
  const durations = tally(corpus, DURATION_RE, (m) => (m[1] ?? m[2] ?? '').trim() || null);
  const easings = tally(corpus, EASING_RE, (m) => (m[1] ?? '').trim() || null);
  const breakpoints = tally(corpus, BREAKPOINT_RE, (m) => (m[2] ?? '').trim() || null);
  const utilities = tallyUtilities(corpus);

  const customProps = countMatches(corpus, /--[a-z0-9-]+\s*:/gi);
  const tokenSource = hasTokenSource(root, stack, customProps);

  return {
    measured_at: new Date().toISOString(),
    root,
    stack,
    files_scanned: corpus.length,
    excluded: { ...collected.excluded, derived: derived.length, derived_files: derived.slice(0, 5) },
    components: components(corpus),
    tokens: {
      colors: summarise(colors, tokenSource, 12),
      fonts: summarise(fonts, tokenSource, 4),
      radius: summarise(radius, tokenSource, 6),
      shadows: summarise(shadows, tokenSource, 4),
      spacing: summarise(spacing, tokenSource, 10),
      motion: {
        durations: summarise(durations, tokenSource, 4),
        easings: summarise(easings, tokenSource, 4),
      },
      breakpoints: summarise(breakpoints, tokenSource, 5),
    },
    signals: {
      custom_properties: customProps,
      token_source: tokenSource,
      utility_classes: utilities.total,
      focus_visible: signal(corpus, {
        'css :focus-visible': /:focus-visible/g,
        'utility focus-visible:': /\bfocus-visible:/g,
      }),
      reduced_motion: signal(corpus, { 'prefers-reduced-motion': /prefers-reduced-motion/g }),
      dark_mode: signal(corpus, {
        'prefers-color-scheme': /prefers-color-scheme\s*:\s*dark/g,
        '[data-theme=dark]': /\[data-theme[~^$*|]?=\s*["']?dark/g,
        '.dark class selector': /(^|[\s,>+~{])\.dark(?=[\s,>+~{:.[])/gm,
        'tailwind dark: variant': /(^|[\s"'`:])dark:[a-z[]/g,
        '@custom-variant dark': /@custom-variant\s+dark/g,
      }),
      gradients: signal(corpus, {
        'css gradient': /(linear|radial|conic)-gradient\(/g,
        'utility bg-gradient': /\bbg-gradient-to-/g,
      }),
      backdrop_filter: signal(corpus, {
        'backdrop-filter': /backdrop-filter\s*:/g,
        'utility backdrop-blur': /\bbackdrop-blur\b/g,
      }),
      transitions: durations.total,
    },
    dials: dials({ spacing, utilities, colors, durations, shadows, fonts, corpus }),
  };
}

/**
 * A named-mechanism signal. `dark_mode: 1773` was a substring match on "dark",
 * and `--hlp-navy-dark: #123` contains the literal `dark:`. A bare confident
 * integer over a false positive is worse than no number at all, so every
 * signal now reports which mechanisms actually matched. An empty `matched`
 * makes a zero legible instead of merely absent.
 */
function signal(corpus, patterns) {
  const matched = [];
  const files = new Set();
  let value = 0;
  for (const [name, re] of Object.entries(patterns)) {
    let n = 0;
    for (const { file, text } of corpus) {
      const hits = (text.match(re) ?? []).length;
      if (hits) { n += hits; files.add(file); }
    }
    if (n) matched.push({ mechanism: name, evidence: n });
    value += n;
  }
  return { value, files: files.size, matched };
}

// ── extraction ──────────────────────────────────────────────────────────────

const COLOR_RE = /#(?:[0-9a-f]{3,8})\b|\b(?:rgba?|hsla?|oklch|color-mix)\([^)]{2,80}\)/gi;
const FONT_RE = /font-family\s*:\s*([^;}\n]+)|fontFamily\s*:\s*\[?\s*["']([^"']+)/gi;
const RADIUS_RE = /border-radius\s*:\s*([^;}\n]+)/gi;
const SHADOW_RE = /box-shadow\s*:\s*([^;}\n]+)/gi;
const SPACING_RE = /\b(padding|margin|gap|row-gap|column-gap)\s*:\s*([^;}\n]+)/gi;
const DURATION_RE = /(?:transition-duration|animation-duration)\s*:\s*([^;}\n]+)|transition\s*:[^;}\n]*?(\d+m?s)/gi;
const EASING_RE = /(?:transition-timing-function|animation-timing-function)\s*:\s*([^;}\n]+)/gi;
const BREAKPOINT_RE = /@media[^{]*?\((min-width|max-width)\s*:\s*([^)]+)\)/gi;

// Tailwind-style utilities, the dominant idiom in server-rendered templates
// where there is no stylesheet to read.
const UTILITY_RE = /\b(p|px|py|pt|pb|pl|pr|m|mx|my|mt|mb|ml|mr|gap|space-[xy])-(\d+(?:\.\d+)?|px)\b/g;
const RADIUS_UTIL_RE = /\brounded(?:-(none|sm|md|lg|xl|2xl|3xl|full))?\b/g;
const SHADOW_UTIL_RE = /\bshadow(?:-(sm|md|lg|xl|2xl|inner|none))?\b/g;
const TEXT_UTIL_RE = /\btext-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl)\b/g;

// Third-party CSS describes somebody else's design system. Including it makes
// every mature project look maximally ornamented and every dial read 10.
const VENDOR_RE = /(^|\/)(vendor|vendors|libs?|plugins?|bower_components|third[-_]party|fontawesome|bootstrap|jquery|select2|datatables|summernote|swiper|slick)(\/|[-.])/i;

// Build output. A content-hashed filename is the strongest signal a file was
// generated: nobody types `bundle-core.88f4182ca0.css`. Weighting one of these
// the same as a hand-written stylesheet inflates every count several-fold and
// makes the dials describe a bundler rather than a design system.
const GENERATED_RE = /\.min\.(css|js)$|[.-][0-9a-f]{8,}\.(css|js|mjs)$|\.(css|js)\.map$/i;

/**
 * Ask git which of these paths are ignored. One spawn, whatever the file count.
 * A repo's own .gitignore already names its build output, which is a better
 * exclusion list than anything this script could guess. Returns a Set; empty
 * when git is absent or this is not a repository, so the pass never fails.
 */
function gitIgnored(root, files) {
  if (!files.length) return new Set();
  try {
    const r = spawnSync('git', ['-C', root, 'check-ignore', '--stdin'], {
      input: files.join('\n'), encoding: 'utf8', timeout: 10_000, maxBuffer: 8 << 20,
    });
    // exit 0 = some ignored, 1 = none ignored, 128 = not a repo. Only 0 has output.
    if (r.status !== 0 || !r.stdout) return new Set();
    return new Set(r.stdout.split('\n').map((l) => l.trim()).filter(Boolean));
  } catch {
    return new Set();
  }
}

function collectFiles(root) {
  const all = walk(root, { exts: [...STYLE_EXT, ...MARKUP_EXT, ...CODE_EXT], maxFiles: MAX_FILES * 3 });
  const vendored = all.filter((f) => VENDOR_RE.test(f));
  const generated = all.filter((f) => !VENDOR_RE.test(f) && GENERATED_RE.test(f));
  const found = all.filter((f) => !VENDOR_RE.test(f) && !GENERATED_RE.test(f));
  const ignoredSet = gitIgnored(root, found);
  const isIgnored = (f) => ignoredSet.has(f) || ignoredSet.has(path.relative(root, f));
  const kept = found.filter((f) => !isIgnored(f));
  // Stylesheets first: when the cap bites, the file that defines the system
  // matters more than the four hundredth file that consumes it.
  const weight = (f) => (STYLE_EXT.some((e) => f.endsWith(e)) ? 0 : MARKUP_EXT.some((e) => f.endsWith(e)) ? 1 : 2);
  return {
    files: kept.sort((a, b) => weight(a) - weight(b)).slice(0, MAX_FILES),
    excluded: {
      vendored: vendored.length,
      generated: generated.length,
      gitignored: found.length - kept.length,
      examples: [...generated, ...found.filter(isIgnored)].slice(0, 5).map(relative),
    },
  };
}

function readCorpus(files) {
  const out = [];
  for (const file of files) {
    try {
      if (fs.statSync(file).size > MAX_FILE_BYTES) continue;
      out.push({ file, text: fs.readFileSync(file, 'utf8') });
    } catch {
      /* unreadable file: skip, never fail the pass */
    }
  }
  return out;
}

/**
 * Drop stylesheets that are derived copies of another stylesheet in the corpus.
 * Catches the committed-but-vendored case a filename cannot: `theme/api/css/
 * stylesheet.css` holding a superset of `theme/css/site.css`. If two files
 * share more than 70% of the smaller one's declarations, the larger is a build
 * of the smaller, and counting both doubles every value in it.
 */
const DERIVED_SHARE = 0.7;
const DEDUP_MAX = 60;   // pairwise, so bound it

function dropDerived(corpus) {
  const styles = corpus.filter(({ file }) => STYLE_EXT.some((e) => file.endsWith(e)));
  if (styles.length < 2) return { corpus, derived: [] };
  const decls = new Map();
  for (const { file, text } of styles.slice(0, DEDUP_MAX)) {
    const set = new Set([...text.matchAll(/[a-z-]+\s*:\s*[^;{}\n]{1,60}/gi)].map((m) => m[0].replace(/\s+/g, '')));
    if (set.size >= 20) decls.set(file, set);
  }
  const derived = new Set();
  const entries = [...decls.entries()];
  for (let i = 0; i < entries.length; i += 1) {
    for (let j = i + 1; j < entries.length; j += 1) {
      const [fa, a] = entries[i], [fb, b] = entries[j];
      if (derived.has(fa) || derived.has(fb)) continue;
      const [small, large, fSmall, fLarge] = a.size <= b.size ? [a, b, fa, fb] : [b, a, fb, fa];
      let shared = 0;
      for (const d of small) if (large.has(d)) shared += 1;
      if (shared / small.size > DERIVED_SHARE && large.size > small.size) derived.add(fLarge);
      void fSmall;
    }
  }
  return {
    corpus: corpus.filter(({ file }) => !derived.has(file)),
    derived: [...derived].map(relative),
  };
}

/**
 * Count files as well as occurrences, and rank on files.
 *
 * `#77a507` at 750 hits could be one file or sixty, and the two mean opposite
 * things: a value used once in one file is a one-off however many times that
 * file repeats it, while a value in sixty files is a system. Occurrence counts
 * also inherit whatever weighting the corpus happens to have, so a single large
 * file dominates. File share does not.
 */
function tally(corpus, regex, normalise) {
  const counts = new Map();
  const inFiles = new Map();
  const sources = new Map();
  let total = 0;
  for (const { file, text } of corpus) {
    for (const match of text.matchAll(regex)) {
      const value = normalise(match);
      if (!value) continue;
      counts.set(value, (counts.get(value) ?? 0) + 1);
      if (!inFiles.has(value)) inFiles.set(value, new Set());
      inFiles.get(value).add(file);
      if (!sources.has(value)) sources.set(value, file);
      total += 1;
    }
  }
  const filesWith = new Set();
  for (const set of inFiles.values()) for (const f of set) filesWith.add(f);
  return { counts, inFiles, sources, total, files: filesWith.size };
}

function tallyUtilities(corpus) {
  const spacing = new Map();
  const radius = new Map();
  const shadow = new Map();
  const text = new Map();
  let total = 0;
  const bump = (map, key) => { map.set(key, (map.get(key) ?? 0) + 1); total += 1; };
  for (const { text: src } of corpus) {
    for (const m of src.matchAll(UTILITY_RE)) bump(spacing, m[2]);
    for (const m of src.matchAll(RADIUS_UTIL_RE)) bump(radius, m[1] ?? 'default');
    for (const m of src.matchAll(SHADOW_UTIL_RE)) bump(shadow, m[1] ?? 'default');
    for (const m of src.matchAll(TEXT_UTIL_RE)) bump(text, m[1]);
  }
  return { spacing, radius, shadow, text, total };
}

function countMatches(corpus, regex) {
  let n = 0;
  for (const { text } of corpus) n += (text.match(regex) ?? []).length;
  return n;
}

function normaliseColor(match) {
  let value = match[0].toLowerCase().replace(/\s+/g, '');
  if (/^#([0-9a-f]{3})$/.test(value)) {
    value = '#' + value.slice(1).split('').map((c) => c + c).join('');
  }
  if (/^#[0-9a-f]{8}$/.test(value) && value.endsWith('ff')) value = value.slice(0, 7);
  if (/^(currentcolor|transparent|inherit)$/.test(value)) return null;
  return value;
}

// CSS keywords and bare generic families are inherited defaults, not choices.
const NON_VALUES = new Set(['0', '0px', '0rem', 'none', 'auto', 'inherit', 'initial', 'unset', 'revert', 'normal']);
const GENERIC_FAMILIES = new Set(['sans-serif', 'serif', 'monospace', 'cursive', 'fantasy', 'system-ui', 'ui-sans-serif', 'ui-serif', 'ui-monospace', '-apple-system', 'blinkmacsystemfont']);

function meaningful(raw, limit = 60) {
  if (!raw) return null;
  const value = raw.trim().replace(/\s*!important$/i, '').replace(/\s+/g, ' ');
  if (!value || NON_VALUES.has(value.toLowerCase())) return null;
  return value.slice(0, limit);
}

function cleanFont(raw) {
  if (!raw) return null;
  const first = raw.split(',')[0].trim().replace(/^["']|["']$/g, '');
  if (!first || first.startsWith('var(') || first.startsWith('$') || first.startsWith('{')) return null;
  const lower = first.toLowerCase();
  if (NON_VALUES.has(lower) || GENERIC_FAMILIES.has(lower)) return null;
  return first;
}

function summarise({ counts, inFiles, sources, total, files }, tokenSource, limit) {
  const nFiles = (v) => inFiles.get(v)?.size ?? 0;
  // Rank on file count; occurrences break the tie. A value in more files is
  // more canonical than a value repeated more often in one.
  const entries = [...counts.entries()].sort(
    (a, b) => nFiles(b[0]) - nFiles(a[0]) || b[1] - a[1],
  );
  const top = entries.slice(0, limit).map(([value, count]) => ({
    value,
    evidence: count,
    files: nFiles(value),
    file_share: files ? Number((nFiles(value) / files).toFixed(3)) : 0,
    share: total ? Number((count / total).toFixed(3)) : 0,
    source: relative(sources.get(value)),
  }));
  return {
    total, files, distinct: entries.length, top,
    confidence: confidence(entries, files, nFiles, tokenSource),
  };
}

/**
 * Confidence is a statement about how safe it is to act without asking, not a
 * statement about quality. A declared token source raises it one step, because
 * an intentional declaration outranks a popular accident.
 *
 * Measured on file share, not occurrence share, for the reason in `tally`.
 * Under three files there is no evidence of a system whatever the counts say.
 */
const MIN_FILES_FOR_CONFIDENCE = 3;

function confidence(entries, files, nFiles, tokenSource) {
  if (!entries.length || !files) return 'absent';
  const lead = nFiles(entries[0][0]);
  if (lead < MIN_FILES_FOR_CONFIDENCE) return tokenSource ? 'low' : 'absent';
  const share = lead / files;
  if (share >= HIGH_CONFIDENCE) return 'high';
  if (share >= LOW_CONFIDENCE) return tokenSource ? 'high' : 'medium';
  return tokenSource ? 'medium' : 'low';
}

// ── components ──────────────────────────────────────────────────────────────

/**
 * The partial ranking, which `components: null` refused to give. For a design
 * tool this is the highest-value output of the whole scan: it is the vocabulary
 * the product is actually built from. Ten lines of matching, ranked by the
 * number of files that use each name rather than by raw invocations.
 */
const COMPONENT_RES = [
  [/@include\s+([a-zA-Z][\w-]{2,40})\s*[({;]/g, 'scss mixin'],
  [/@extend\s+\.([a-zA-Z][\w-]{2,40})/g, 'scss placeholder'],
  [/<x-([a-z][\w.-]{1,40})/g, 'blade component'],
  [/@livewire\(\s*['"]([\w.-]{2,40})/g, 'livewire'],
  [/@component\(\s*['"][\w.]*?([\w-]{2,40})['"]/g, 'blade @component'],
  [/@include\(\s*['"]([\w.-]{2,40})['"]/g, 'blade partial'],
  [/<([A-Z][A-Za-z0-9]{1,30})[\s/>]/g, 'jsx/vue element'],
];

function components(corpus) {
  const byName = new Map();   // name -> { kind, files:Set, uses }
  for (const { file, text } of corpus) {
    for (const [re, kind] of COMPONENT_RES) {
      for (const m of text.matchAll(re)) {
        const name = m[1];
        if (!name || HTML_TAGS.has(name.toLowerCase())) continue;
        const key = `${kind}:${name}`;
        if (!byName.has(key)) byName.set(key, { name, kind, files: new Set(), uses: 0 });
        const e = byName.get(key);
        e.files.add(file); e.uses += 1;
      }
    }
  }
  const ranked = [...byName.values()]
    .map((e) => ({ name: e.name, kind: e.kind, files: e.files.size, uses: e.uses }))
    .filter((e) => e.uses >= 2)
    .sort((a, b) => b.files - a.files || b.uses - a.uses);
  return { distinct: ranked.length, top: ranked.slice(0, 20) };
}

// Capitalised tags that are HTML, not components. Without this every SVG-heavy
// file reports <Path> and <Circle> as the product's leading components.
const HTML_TAGS = new Set(['svg', 'path', 'circle', 'rect', 'g', 'line', 'text', 'html', 'head',
  'body', 'div', 'span', 'a', 'p', 'ul', 'li', 'img', 'br', 'hr', 'th', 'td', 'tr']);

function hasTokenSource(root, stack, customProps) {
  const candidates = [
    'tailwind.config.js', 'tailwind.config.ts', 'tailwind.config.cjs', 'tailwind.config.mjs',
    'theme.json', 'tokens.json', 'design-tokens.json', 'DESIGN.md',
    'src/theme.ts', 'src/theme.js', 'src/styles/tokens.css', 'app/theme.ts',
  ];
  if (candidates.some((c) => fs.existsSync(path.join(root, c)))) return true;
  if (stack.css_systems?.some((c) => c.name === 'tailwind' && c.files >= 2)) return true;
  // Twenty custom properties is where a palette stops being ad hoc and starts
  // being a declared system; below that they are usually one-off overrides.
  return customProps >= 20;
}

// The root being measured, so paths in the report are relative to the project
// under scan rather than to wherever the script happened to be invoked from.
let MEASURE_ROOT = null;

function relative(file) {
  if (!file) return null;
  return path.relative(MEASURE_ROOT ?? projectRoot(), file) || path.basename(file);
}

// ── stack ───────────────────────────────────────────────────────────────────

function detectStack(root, corpus = []) {
  const pkg = readJsonIfExists(path.join(root, 'package.json')) ?? {};
  const deps = { ...(pkg.dependencies ?? {}), ...(pkg.devDependencies ?? {}) };
  const has = (name) => Object.prototype.hasOwnProperty.call(deps, name);
  const composer = readJsonIfExists(path.join(root, 'composer.json'));

  const framework =
    has('next') ? 'next' : has('nuxt') ? 'nuxt' : has('@sveltejs/kit') ? 'sveltekit' :
    has('astro') ? 'astro' : has('react') ? 'react' : has('vue') ? 'vue' :
    has('svelte') ? 'svelte' : has('@angular/core') ? 'angular' :
    composer?.require?.['laravel/framework'] ? 'laravel' :
    fs.existsSync(path.join(root, 'Gemfile')) ? 'rails' : 'unknown';

  // A manifest says what is installed. It does not say what the product is
  // written in. `css: "tailwind"` from a package.json dependency was wrong on a
  // Bootstrap site where Tailwind was 9 lines and 2 of 98 views. Count usage in
  // the corpus, and let the schema say "two systems, split by area", which is
  // the normal state of a codebase mid-migration.
  const cssSystems = weighCss(corpus, has, root);
  const css = cssSystems.length ? cssSystems[0].name
    : has('styled-components') ? 'styled-components' : has('@emotion/react') ? 'emotion'
    : has('sass') || has('node-sass') ? 'sass' : 'css';

  const components =
    has('@radix-ui/react-dialog') || fs.existsSync(path.join(root, 'components.json')) ? 'shadcn/radix' :
    has('@mui/material') ? 'mui' : has('antd') ? 'antd' : has('@chakra-ui/react') ? 'chakra' :
    has('bootstrap') ? 'bootstrap' : has('vuetify') ? 'vuetify' : null;

  const templates =
    framework === 'laravel' ? 'blade' : framework === 'rails' ? 'erb' :
    fs.existsSync(path.join(root, 'resources/views')) ? 'blade' : null;

  return {
    framework,
    css,
    css_systems: cssSystems,
    css_split: cssSystems.length > 1 && cssSystems[1].file_share >= 0.1
      ? `${cssSystems[0].name} leads (${pct(cssSystems[0].file_share)} of files), ${cssSystems[1].name} in ${pct(cssSystems[1].file_share)} — inspect before assuming one canonical system`
      : null,
    components, templates,
    typescript: fs.existsSync(path.join(root, 'tsconfig.json')),
    storybook: fs.existsSync(path.join(root, '.storybook')),
    dev_command: pkg.scripts?.dev ? `npm run dev` : pkg.scripts?.start ? 'npm start' :
      framework === 'laravel' ? 'php artisan serve' : null,
  };
}

const pct = (n) => `${Math.round(n * 100)}%`;

// Signatures that mean "this file is written in system X". Deliberately narrow:
// `container` alone is not Bootstrap, `flex` alone is not Tailwind.
const CSS_SIGNATURES = {
  tailwind: /@tailwind\s+(base|components|utilities)|@import\s+["']tailwindcss|\b(?:sm|md|lg|xl|2xl):[a-z-]+-|\b(?:flex|grid|hidden|block)\s+[a-z-]*(?:px|py|mt|mb|gap|space-[xy])-\d/,
  bootstrap: /\b(?:col-(?:xs|sm|md|lg|xl)-\d{1,2}|container-fluid|navbar-(?:expand|toggler)|form-control\b|btn btn-|d-flex\b|row\s+justify-content-)/,
  bulma: /\b(?:is-(?:primary|danger|pulled-left)|columns\s+is-|hero-body|navbar-burger)\b/,
  foundation: /\b(?:grid-x|cell\s+(?:small|medium|large)-\d|button hollow)\b/,
};

function weighCss(corpus, has, root) {
  const counts = {};
  for (const { text } of corpus) {
    for (const [name, re] of Object.entries(CSS_SIGNATURES)) {
      if (re.test(text)) counts[name] = (counts[name] ?? 0) + 1;
    }
  }
  const total = corpus.length || 1;
  const out = Object.entries(counts)
    .map(([name, files]) => ({ name, files, file_share: Number((files / total).toFixed(3)), source: 'usage' }))
    .filter((e) => e.files >= 2)
    .sort((a, b) => b.files - a.files);
  // A declared config with no usage still counts, at the bottom, marked as
  // declared rather than observed. That is exactly the "installed but barely
  // used" case, and saying so is more useful than either dropping or leading it.
  const declaredTailwind = has('tailwindcss')
    || ['tailwind.config.js', 'tailwind.config.ts', 'tailwind.config.cjs', 'tailwind.config.mjs']
      .some((c) => fs.existsSync(path.join(root, c)));
  if (declaredTailwind && !out.some((e) => e.name === 'tailwind')) {
    out.push({ name: 'tailwind', files: 0, file_share: 0, source: 'manifest only, no usage observed' });
  }
  if (has('bootstrap') && !out.some((e) => e.name === 'bootstrap')) {
    out.push({ name: 'bootstrap', files: 0, file_share: 0, source: 'manifest only, no usage observed' });
  }
  return out;
}

// ── dials ───────────────────────────────────────────────────────────────────

/**
 * Five dials, 0-10, measured rather than asked. They exist to account for
 * change budget: the delta between the before and after reading is what a
 * budget spends. They are never shown to the user unless a budget call needs
 * explaining.
 */
function dials({ spacing, utilities, colors, durations, shadows, fonts, corpus }) {
  const medianSpacing = medianOf([...utilities.spacing.entries()].map(([k, n]) => [tailwindStep(k), n]))
    ?? medianOf([...spacing.counts.entries()].map(([k, n]) => [pxOf(k), n]));

  // Tighter spacing means a denser interface. 4px reads as 10, 32px as 0.
  const density = medianSpacing == null ? 5 : clamp(Math.round(10 - (medianSpacing - 4) / 2.8), 0, 10);

  // Hierarchy strength shows up as the spread of type sizes actually used.
  const textSteps = utilities.text.size || new Set([...corpus.flatMap(({ text }) =>
    [...text.matchAll(/font-size\s*:\s*([^;}\n]+)/gi)].map((m) => m[1].trim()))]).size;
  const hierarchy = clamp(Math.round(textSteps * 1.4), 0, 10);

  // The remaining three dials are ratios, never counts. A count makes every
  // large codebase read 10 regardless of how restrained it actually is, which
  // is useless for budget accounting.

  // Expressiveness: how much of the palette a product actually leans on carries
  // colour, judged over the colours it uses most rather than every stray hex.
  const leading = [...colors.counts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 12);
  const saturated = leading.filter(([value]) => isSaturated(value)).length;
  const expressiveness = leading.length ? clamp(Math.round((saturated / leading.length) * 10), 0, 10) : 0;

  // Motion and ornament: the share of files that reach for them at all.
  const share = (re) => corpus.length
    ? corpus.filter(({ text }) => re.test(text)).length / corpus.length
    : 0;
  const motion = clamp(Math.round(share(/transition|animation|@keyframes/i) * 10), 0, 10);
  const ornament = clamp(Math.round(share(/box-shadow|linear-gradient|radial-gradient|backdrop-filter|\bshadow-(sm|md|lg|xl)\b/i) * 10), 0, 10);

  // Say how much to trust these. They are computed after generated files and
  // derived stylesheets are excluded, but a thin corpus still yields numbers
  // that look as authoritative as a thick one. When confidence is low, atlas
  // writes them into config.md commented out rather than as facts.
  const thin = corpus.length < 12 || medianSpacing == null || textSteps === 0;
  const dialConfidence = thin ? 'low' : corpus.length < 40 ? 'medium' : 'high';

  return {
    density, hierarchy, expressiveness, motion, ornament,
    confidence: dialConfidence,
    write_to_config: dialConfidence !== 'low',
    evidence: {
      corpus_files: corpus.length,
      median_spacing_px: medianSpacing,
      type_steps: textSteps,
      leading_colors: leading.length,
      saturated_leading: saturated,
      typefaces: fonts.counts.size,
      transition_declarations: durations.total,
      shadow_declarations: shadows.total,
    },
  };
}

function tailwindStep(key) {
  if (key === 'px') return 1;
  const n = Number(key);
  return Number.isFinite(n) ? n * 4 : null; // Tailwind's default 0.25rem step
}

function pxOf(value) {
  const m = String(value).match(/(-?\d+(?:\.\d+)?)\s*(px|rem|em)/);
  if (!m) return null;
  const n = Number(m[1]);
  return m[2] === 'px' ? n : n * 16;
}

function medianOf(pairs) {
  const expanded = [];
  for (const [value, count] of pairs) {
    if (value == null || !Number.isFinite(value)) continue;
    for (let i = 0; i < Math.min(count, 500); i += 1) expanded.push(value);
  }
  if (!expanded.length) return null;
  expanded.sort((a, b) => a - b);
  return expanded[Math.floor(expanded.length / 2)];
}

function isSaturated(color) {
  const m = color.match(/^#([0-9a-f]{6})$/);
  if (!m) return /hsl|oklch/.test(color);
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(m[1].slice(i, i + 2), 16));
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  if (max === 0) return false;
  // Chroma over 15% of the maximum channel is where a colour stops reading as
  // a neutral grey and starts carrying meaning.
  return (max - min) / max > 0.15;
}

function clamp(n, lo, hi) {
  return Math.max(lo, Math.min(hi, Number.isFinite(n) ? n : lo));
}

// ── cli ─────────────────────────────────────────────────────────────────────

function main() {
  const args = process.argv.slice(2);
  const rootArg = args.indexOf('--root');
  const root = rootArg !== -1 ? path.resolve(args[rootArg + 1]) : projectRoot();
  const result = measure(root);

  if (args.includes('--json')) {
    process.stdout.write(JSON.stringify(result, null, 2) + '\n');
    return;
  }

  const { stack, tokens, dials: d, signals, excluded } = result;
  const line = (label, value) => console.log(`${label.padEnd(14)} ${value}`);
  console.log(`# Measured ${result.files_scanned} files in ${path.basename(root)}`);
  console.log(`# Excluded ${excluded.vendored} vendored, ${excluded.generated} generated, `
    + `${excluded.gitignored} gitignored, ${excluded.derived} derived`
    + `${excluded.examples.length ? `\n#   e.g. ${excluded.examples.join(', ')}` : ''}`
    + `${excluded.derived_files.length ? `\n#   derived: ${excluded.derived_files.join(', ')}` : ''}\n`);

  line('stack', [stack.framework, stack.css, stack.components, stack.templates].filter(Boolean).join(' · '));
  if (stack.css_split) line('css split', stack.css_split);

  for (const [name, group] of Object.entries(tokens)) {
    if (name === 'motion') continue;
    // "value (N files)" — a file count is the number that means something.
    const top = group.top.slice(0, 4).map((t) => `${t.value} (${t.files}f)`).join(', ');
    line(name, `${group.confidence} · ${group.distinct} distinct · ${top || 'none observed'}`);
  }
  line('motion', `${tokens.motion.durations.top.slice(0, 3).map((t) => t.value).join(', ') || 'none observed'}`);

  const c = result.components;
  line('components', c.distinct
    ? `${c.distinct} distinct · ${c.top.slice(0, 5).map((x) => `${x.name} (${x.files}f)`).join(', ')}`
    : 'none observed');

  line('dials', `${d.confidence} confidence · density ${d.density} · hierarchy ${d.hierarchy} · expressive ${d.expressiveness} · motion ${d.motion} · ornament ${d.ornament}`);
  if (!d.write_to_config) line('', 'dials are low confidence — do not write them to config.md as facts');

  // Every signal names what matched, so a zero is legible and a non-zero is
  // auditable. A bare integer over a false positive is the failure this fixes.
  for (const key of ['focus_visible', 'reduced_motion', 'dark_mode']) {
    const g = signals[key];
    line(key.replace('_', '-'), g.value
      ? `${g.value} in ${g.files} files · ${g.matched.map((m) => `${m.mechanism} ${m.evidence}`).join(', ')}`
      : '0 — no mechanism matched');
  }
}

if (import.meta.url === `file://${process.argv[1]}`) main();
