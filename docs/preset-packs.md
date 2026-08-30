# Preset Packs

## Purpose

This document defines the shareable preset-pack schema introduced in
`v2.0` Phase 1.

Preset packs remain collections of note targets over Omatune's general
chromatic model. They do not introduce separate pitch engines.

## Top-Level Shape

Preset packs are JSON objects.

Required fields:

-   `schema_version`: current value `1`; missing values normalize to `1`
    for additive migration from earlier drafts.
-   `kind`: must be `preset_pack`.
-   `id`: stable pack identifier.
-   `label`: human-readable pack name.
-   `groups`: array of one or more preset groups.

Optional fields:

-   `description`: short pack description.

Example:

```json
{
  "schema_version": 1,
  "kind": "preset_pack",
  "id": "shared.alt_strings",
  "label": "Alt Strings",
  "groups": [
    {
      "id": "guitar",
      "label": "Guitar",
      "presets": [
        {
          "id": "guitar.low_c",
          "label": "Low C",
          "description": "One alternate guitar example.",
          "targets": [
            { "note": "C2", "label": "C2" },
            { "note": "G2", "label": "G string" },
            { "note": "C3", "label": "C3" },
            { "note": "F3", "label": "F3" },
            { "note": "A3", "label": "A3" },
            { "note": "D4", "label": "D4" }
          ]
        }
      ]
    }
  ]
}
```

## Group Shape

Each group requires:

-   `id`: stable group identifier inside the pack.
-   `label`: human-readable group name.
-   `presets`: array of one or more presets.

## Preset Shape

Each preset requires:

-   `id`: stable preset identifier.
-   `label`: human-readable preset name.
-   `targets`: array of note-target entries.

Optional fields:

-   `description`: short human-readable summary.

For additive migration, imports also accept a legacy `notes` array and
normalize it to `targets`.

## Target Shape

Each target may be either:

-   a note string such as `"E2"`, or
-   an object with `note` and optional `label`.

Normalized output always uses objects:

```json
{ "note": "E2", "label": "E2" }
```

Normalization rules:

-   ids are trimmed and lowercased;
-   pack, group, and preset ids may contain only lowercase ASCII
    letters, digits, `.`, `_`, and `-`;
-   labels must be non-empty after trimming;
-   note strings are parsed through Omatune's canonical note parser;
-   flats and equivalent spellings normalize to Omatune's canonical sharp
    form in exported JSON;
-   missing or empty target labels normalize to the canonical note text.

## Limits And Rejection Rules

Imports are rejected when:

-   `kind` is missing or unsupported;
-   `schema_version` is newer than this build supports;
-   the pack or preset id conflicts with a built-in pack or preset;
-   group ids repeat inside a pack;
-   preset ids repeat inside a pack;
-   a preset has no targets;
-   a preset has more than twelve targets;
-   a target note is invalid or out of Omatune's supported range;
-   a target note appears more than once inside one preset.

## Built-In Preset Coverage

The current built-in library now includes:

-   guitar: standard, drop D, DADGAD, 7-string, 8-string
-   bass: 4-string, 5-string, 6-string
-   ukulele: standard, baritone
-   violin family: violin, viola, cello, double bass
-   mandolin family: mandolin, mandola
-   folk/plucked: banjo open G, tenor guitar

## Import And Export Surface

Omatune's `Presets` destination browses the merged built-in and imported
preset library.

Omatune's `Advanced` destination can:

-   load the currently selected preset pack into the pack editor;
-   import a normalized preset pack from pasted JSON;
-   remove an imported preset pack.

The helper also exposes these tool modes for local automation:

-   `omatune-helper --dump-tuning-library`
-   `omatune-helper --normalize-content-pack '<json>'`
