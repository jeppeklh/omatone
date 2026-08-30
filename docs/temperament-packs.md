# Temperament Packs

## Purpose

This document defines the shareable temperament-pack schema introduced in
`v2.0` Phase 1.

Temperament packs expand Omatune's chromatic target math without adding
instrument-specific pitch engines.

## Top-Level Shape

Temperament packs are JSON objects.

Required fields:

-   `schema_version`: current value `1`; missing values normalize to `1`
    for additive migration from pre-schema drafts.
-   `kind`: must be `temperament_pack`.
-   `id`: stable pack identifier.
-   `label`: human-readable pack name.
-   `temperaments`: array of one or more temperament definitions.

Optional fields:

-   `description`: short pack description.

Example:

```json
{
  "schema_version": 1,
  "kind": "temperament_pack",
  "id": "shared.historical",
  "label": "Historical Temperaments",
  "description": "A few A-anchored chromatic alternatives.",
  "temperaments": [
    {
      "id": "shared.historical.pythagorean",
      "label": "Pythagorean Fifths",
      "description": "Pure-fifth chain with A kept at the configured reference pitch.",
      "offsets_cents": [-5.865, 7.82, -1.955, 11.73, 1.955, -7.82, 5.865, -3.91, 9.775, 0.0, -9.775, 3.91]
    }
  ]
}
```

## Temperament Shape

Each temperament object requires:

-   `id`: stable temperament identifier.
-   `label`: human-readable temperament name.
-   `offsets_cents`: exactly twelve numeric pitch-class offsets.

Optional fields:

-   `description`: short human-readable summary.

`offsets_cents` order is always:

`C, C#, D, D#, E, F, F#, G, G#, A, A#, B`

## Semantics

Offsets are cents deviations from equal temperament.

Normalization rules:

-   ids are trimmed and lowercased;
-   pack and temperament ids may contain only lowercase ASCII letters,
    digits, `.`, `_`, and `-`;
-   labels must be non-empty after trimming;
-   offsets must be finite numbers;
-   offsets must remain within `+/-100.0` cents;
-   imported offsets are re-anchored so the `A` pitch class becomes
    exactly `0.0` cents.

That A-anchoring rule preserves Omatune's calibration contract:

`A4 = configured reference A frequency`

even when another temperament is active.

## Rejection Rules

Imports are rejected when:

-   `kind` is missing or unsupported;
-   `schema_version` is newer than this build supports;
-   the pack or temperament id conflicts with a built-in pack or
    temperament;
-   the pack contains duplicate temperament ids;
-   `offsets_cents` is missing, the wrong length, or non-numeric;
-   any offset is outside the supported range.

## Built-In Temperaments

The current built-in library includes:

-   `equal.12tet`
-   `pythagorean.fifths`
-   `meantone.sixth_comma`
-   `meantone.quarter_comma`

## Import And Export Surface

Omatune's `Advanced` popup destination can:

-   load the currently selected temperament pack into the pack editor;
-   import a normalized temperament pack from pasted JSON;
-   remove an imported temperament pack.

The helper also exposes two JSON-oriented tool modes for local
automation:

-   `omatune-helper --dump-tuning-library`
-   `omatune-helper --normalize-content-pack '<json>'`
