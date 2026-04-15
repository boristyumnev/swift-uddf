# UDDF v3.2.1 Spec Mirror

Local mirror of the UDDF v3.2.1 specification for reference during import/export mapping work.

- **Source**: https://www.streit.cc/extern/uddf_v321/en/
- **Version**: UDDF v3.2.1
- **Mirrored**: 2026-04-15
- **Scope**: 42 HTML pages covering every element Trident's UDDF import/export path touches (index, units, general structure, elements index, and per-element reference pages).

## Why it's here

The spec is the source of truth for units, value ranges, element nesting, and fraction-vs-percent conventions. During an audit or mapping change, consult the local mirror instead of re-fetching from the web — both for speed and so the audit has a stable snapshot to cite.

A parallel copy lives at `/Users/boris/swift-uddf/Documentation/uddf-v3.2.1/` so the swift-uddf parser team has the same reference. Keep the two copies identical.

## Known omissions

- `heartrate.html` / `pulserate.html` — swift-uddf parses these element names, but they do **not** appear in the v3.2.1 element index or samples page. They are a non-standard extension supported by some exporters (e.g. Shearwater). Not mirrored because the spec doesn't define them.
- `samples.html` — does not exist as a standalone page in v3.2.1; sample-related documentation lives under the element pages for `divetime`, `depth`, etc. and the per-element child-element sections.

## Updating

To refresh the mirror against a newer UDDF spec release:

1. Re-run the download command used in `Documentation/plans/2026-04-15-uddf-uom-audit-plan.md` §2 with an updated page list
2. Update the "Version" and "Mirrored" dates above
3. Mirror to `/Users/boris/swift-uddf/Documentation/uddf-v3.2.1/` (or whatever the new version path is)
4. Rerun the TridentKit test suite — new spec revisions may tighten or loosen unit expectations

## Element → filename map (for the pages that don't follow the obvious pattern)

| Concept | File |
|---|---|
| Dive duration | `diveduration.html` (not `duration.html`) |
| No-decompression time | `nodecotime.html` (not `ndl.html`) |
| Tank internal volume | `tankvolume.html` (not `volume.html`) |
| Tank start pressure | `tankpressurebegin.html` |
| Tank end pressure | `tankpressureend.html` |
