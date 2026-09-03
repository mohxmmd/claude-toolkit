/**
 * config.md is the single human configuration surface. This module reads it and
 * compiles a compact projection for the boot path.
 *
 * The compile step is what makes "one human file" affordable: the file may grow
 * to whatever a team needs, while the per-task context cost stays flat, because
 * boot loads the projection plus only the two sections that apply to every task
 * (preserve and avoid).
 */
import { splitFrontmatter, parseYaml, sections, bullets } from './text.mjs';
import { readIfExists, craftPaths, CRAFT_SCHEMA } from './paths.mjs';

export const DEFAULTS = {
  craft: CRAFT_SCHEMA,
  posture: 'evolutionary',
  design: { density: 'inherit', motion: 'inherit', ornament: 'inherit', hierarchy: 'inherit' },
  verification: 'auto',
  research: 'on-demand',
};

export const BUDGETS = {
  conservative:  { structure: 0, visual: 1, interaction: 1, brand: 0, content: 1, motion: 0 },
  evolutionary:  { structure: 1, visual: 2, interaction: 2, brand: 0, content: 1, motion: 1 },
  transformative:{ structure: Infinity, visual: Infinity, interaction: Infinity, brand: 'explicit', content: Infinity, motion: Infinity },
};

const KNOWN_KEYS = new Set([
  'craft', 'posture', 'design', 'preserve', 'avoid', 'verification', 'research',
  'budget', 'paths', 'detect', 'protected_surfaces', 'viewports', 'browsers',
  'dev_command', 'questions_max', 'taste',
]);

export function loadConfig(root) {
  const paths = craftPaths(root);
  const raw = readIfExists(paths.config);
  if (!raw) return { exists: false, ...DEFAULTS, sections: {}, unknownKeys: [] };

  const { frontmatter, body } = splitFrontmatter(raw);
  const parsed = parseYaml(frontmatter);
  const parts = sections(body);
  const unknownKeys = Object.keys(parsed).filter((k) => !KNOWN_KEYS.has(k));

  return {
    exists: true,
    raw,
    ...DEFAULTS,
    ...parsed,
    design: { ...DEFAULTS.design, ...(parsed.design ?? {}) },
    preserve: asList(parsed.preserve),
    avoid: asList(parsed.avoid),
    sections: parts,
    unknownKeys,
  };
}

function asList(value) {
  if (Array.isArray(value)) return value.map(String);
  if (typeof value === 'string' && value) return [value];
  return [];
}

/** Budget for a posture, with per-axis overrides from config applied. */
export function budgetFor(config) {
  const base = BUDGETS[config.posture] ?? BUDGETS.evolutionary;
  const overrides = config.budget && typeof config.budget === 'object' ? config.budget : {};
  return { ...base, ...overrides };
}

/**
 * The projection boot prints. Kept deliberately small; anything a specific task
 * needs beyond this is read from config.md on demand by the router.
 */
export function compile(config) {
  const doNotChange = bullets(config.sections['do not change'] ?? '');
  const known = bullets(config.sections['known problems'] ?? '');
  const about = (config.sections['about this product'] ?? '').split('\n\n')[0]?.trim() ?? '';

  return {
    posture: config.posture,
    design: config.design,
    preserve: config.preserve,
    avoid: config.avoid,
    forbidden: doNotChange,
    knownProblems: known.slice(0, 5),
    about: about.slice(0, 400),
    verification: config.verification,
    research: config.research,
    budget: budgetFor(config),
  };
}
