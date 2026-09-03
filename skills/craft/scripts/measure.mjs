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
  const stack = detectStack(root);
  const files = collectFiles(root);
  const corpus = readCorpus(files);

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
    files_scanned: files.length,
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
      focus_visible: countMatches(corpus, /:focus-visible|focus-visible:/g),
      reduced_motion: countMatches(corpus, /prefers-reduced-motion/g),
      dark_mode: countMatches(corpus, /prefers-color-scheme|dark:|\.dark\b|\[data-theme/g),
      gradients: countMatches(corpus, /linear-gradient|radial-gradient|bg-gradient-to-/g),
      backdrop_filter: countMatches(corpus, /backdrop-filter|backdrop-blur/g),
      transitions: durations.total,
    },
    dials: dials({ spacing, utilities, colors, durations, shadows, fonts, corpus }),
  };
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
const VENDOR_RE = /(^|\/)(vendor|vendors|libs?|plugins?|bower_components|third[-_]party|fontawesome|bootstrap|jquery|select2|datatables|summernote|swiper|slick)(\/|[-.])|\.min\.(css|js)$/i;

function collectFiles(root) {
  const found = walk(root, { exts: [...STYLE_EXT, ...MARKUP_EXT, ...CODE_EXT], maxFiles: MAX_FILES * 3 })
    .filter((f) => !VENDOR_RE.test(f));
  // Stylesheets first: when the cap bites, the file that defines the system
  // matters more than the four hundredth file that consumes it.
  const weight = (f) => (STYLE_EXT.some((e) => f.endsWith(e)) ? 0 : MARKUP_EXT.some((e) => f.endsWith(e)) ? 1 : 2);
  return found.sort((a, b) => weight(a) - weight(b)).slice(0, MAX_FILES);
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

function tally(corpus, regex, normalise) {
  const counts = new Map();
  const sources = new Map();
  let total = 0;
  for (const { file, text } of corpus) {
    for (const match of text.matchAll(regex)) {
      const value = normalise(match);
      if (!value) continue;
      counts.set(value, (counts.get(value) ?? 0) + 1);
      if (!sources.has(value)) sources.set(value, file);
      total += 1;
    }
  }
  return { counts, sources, total };
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

function summarise({ counts, sources, total }, tokenSource, limit) {
  const entries = [...counts.entries()].sort((a, b) => b[1] - a[1]);
  const top = entries.slice(0, limit).map(([value, count]) => ({
    value,
    evidence: count,
    share: total ? Number((count / total).toFixed(3)) : 0,
    source: relative(sources.get(value)),
  }));
  return { total, distinct: entries.length, top, confidence: confidence(entries, total, tokenSource) };
}

/**
 * Confidence is a statement about how safe it is to act without asking, not a
 * statement about quality. A declared token source raises it one step, because
 * an intentional declaration outranks a popular accident.
 */
function confidence(entries, total, tokenSource) {
  if (!total) return 'absent';
  const share = entries[0][1] / total;
  if (share >= HIGH_CONFIDENCE) return 'high';
  if (share >= LOW_CONFIDENCE) return tokenSource ? 'high' : 'medium';
  return tokenSource ? 'medium' : 'low';
}

function hasTokenSource(root, stack, customProps) {
  const candidates = [
    'tailwind.config.js', 'tailwind.config.ts', 'tailwind.config.cjs', 'tailwind.config.mjs',
    'theme.json', 'tokens.json', 'design-tokens.json', 'DESIGN.md',
    'src/theme.ts', 'src/theme.js', 'src/styles/tokens.css', 'app/theme.ts',
  ];
  if (candidates.some((c) => fs.existsSync(path.join(root, c)))) return true;
  if (stack.css === 'tailwind') return true;
  // Twenty custom properties is where a palette stops being ad hoc and starts
  // being a declared system; below that they are usually one-off overrides.
  return customProps >= 20;
}

function relative(file) {
  if (!file) return null;
  return path.relative(projectRoot(), file) || path.basename(file);
}

// ── stack ───────────────────────────────────────────────────────────────────

function detectStack(root) {
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

  const css =
    has('tailwindcss') || fs.existsSync(path.join(root, 'tailwind.config.js')) || fs.existsSync(path.join(root, 'tailwind.config.ts')) ? 'tailwind' :
    has('styled-components') ? 'styled-components' : has('@emotion/react') ? 'emotion' :
    has('sass') || has('node-sass') ? 'sass' : has('bootstrap') ? 'bootstrap' : 'css';

  const components =
    has('@radix-ui/react-dialog') || fs.existsSync(path.join(root, 'components.json')) ? 'shadcn/radix' :
    has('@mui/material') ? 'mui' : has('antd') ? 'antd' : has('@chakra-ui/react') ? 'chakra' :
    has('bootstrap') ? 'bootstrap' : has('vuetify') ? 'vuetify' : null;

  const templates =
    framework === 'laravel' ? 'blade' : framework === 'rails' ? 'erb' :
    fs.existsSync(path.join(root, 'resources/views')) ? 'blade' : null;

  return {
    framework, css, components, templates,
    typescript: fs.existsSync(path.join(root, 'tsconfig.json')),
    storybook: fs.existsSync(path.join(root, '.storybook')),
    dev_command: pkg.scripts?.dev ? `npm run dev` : pkg.scripts?.start ? 'npm start' :
      framework === 'laravel' ? 'php artisan serve' : null,
  };
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

  return {
    density, hierarchy, expressiveness, motion, ornament,
    evidence: {
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

  const { stack, tokens, dials: d, signals } = result;
  const line = (label, value) => console.log(`${label.padEnd(14)} ${value}`);
  console.log(`# Measured ${result.files_scanned} files in ${path.basename(root)}\n`);
  line('stack', [stack.framework, stack.css, stack.components, stack.templates].filter(Boolean).join(' · '));
  for (const [name, group] of Object.entries(tokens)) {
    if (name === 'motion') continue;
    const top = group.top.slice(0, 4).map((t) => `${t.value} (${t.evidence})`).join(', ');
    line(name, `${group.confidence} · ${group.distinct} distinct · ${top || 'none observed'}`);
  }
  line('motion', `${tokens.motion.durations.top.slice(0, 3).map((t) => t.value).join(', ') || 'none observed'}`);
  line('dials', `density ${d.density} · hierarchy ${d.hierarchy} · expressive ${d.expressiveness} · motion ${d.motion} · ornament ${d.ornament}`);
  line('a11y signals', `focus-visible ${signals.focus_visible} · reduced-motion ${signals.reduced_motion} · dark ${signals.dark_mode}`);
}

if (import.meta.url === `file://${process.argv[1]}`) main();
