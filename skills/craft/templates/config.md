---
craft: 1
posture: evolutionary          # conservative | evolutionary | transformative

design:                        # detected from your code. edit freely.
  density: inherit
  motion: inherit
  ornament: inherit
  hierarchy: inherit

preserve:
  - navigation structure
  - brand colours and typography
  - existing component library

avoid:
  - unnecessary redesigns
  - decorative UI
  - excessive animation

verification: auto             # auto | checks | visual | browser | none
research: on-demand            # on-demand | never
---

# CRAFT

One file. Edit anything here and CRAFT follows it. Everything below the fold is
optional; the defaults above are enough to work with.

## About this product

<!-- Two or three sentences. Who uses it, for what, in what conditions.
     This is the single highest-value paragraph in the file. -->

## Do not change

<!-- Hard gate. CRAFT will refuse to touch anything listed here and will say so
     rather than working around it. Give the reason; the reason is what lets
     CRAFT tell an exception from a violation. -->

## Known problems

<!-- Things you already know are wrong. CRAFT uses these to prioritise, and will
     not re-report them at you as discoveries. -->

<!-- ─────────────────────────── Advanced ───────────────────────────
     Uncomment what you need. Every value shown is the default.

budget:                   # per-axis override of the posture above.
  structure: 1            # 0 forbids structural change outright
  visual: 2
  interaction: 2
  brand: 0                # never raise this without meaning it
  content: 1
  motion: 1

paths:
  ui:     ["src/**", "app/**", "resources/views/**"]
  styles: ["src/styles/**", "resources/css/**", "public/css/**"]
  ignore: ["**/vendor/**", "**/*.min.css", "**/node_modules/**"]

detect:
  contrast: true
  tap_targets: true
  token_drift: true
  generic_patterns: report_only   # off | report_only | fix
  taste: off                      # off | report_only | fix

protected_surfaces:
  "resources/views/billing/**": ask_first

surfaces:                 # map paths to .craft/surfaces/<name>.md
  "resources/views/tickets/**": tickets

viewports: [1440, 768, 375]
browsers: "> 0.5%, not dead"
dev_command: null         # e.g. "npm run dev" or "php artisan serve"
questions_max: 3

taste: null               # optional. a sentence, a vocabulary word, or a URL.
                          # left null, CRAFT preserves the product's own language.
─────────────────────────────────────────────────────────────────── -->
