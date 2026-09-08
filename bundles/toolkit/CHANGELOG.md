# Changelog

All notable changes to the Toolkit bundle are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The bundle's version tracks its own manifest and skill, not the components it
depends on. A component release does not require a bundle release unless the
pinned range no longer resolves.

## [0.1.0] — 2026-09-08

### Added

- The bundle. Declares Charter `^0.1.0`, Craft `^0.1.0` and TARS `^1.1.0` as
  dependencies, so one install command produces all three.
- `/toolkit:setup` — runs `/charter:init` and reports what all three components
  ended up doing. Writes nothing itself; every file that appears comes from
  Charter's own writes.

### Notes

- Ranges are pinned deliberately. An unpinned dependency drags a broken
  component release into every new install of the bundle.
- The bundle cannot be loaded with `--plugin-dir`: dependencies cannot resolve
  outside a marketplace, and Claude Code disables a plugin whose dependencies
  are unsatisfied. This is why the coupling lives here rather than in Charter,
  where it would have broken vendoring the directory on its own.
