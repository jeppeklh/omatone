# Omatune Configuration

## Purpose

This document defines the persisted user-facing configuration introduced
in Phase 1.

It covers:

-   where Omatune stores its settings;
-   the supported schema and defaults;
-   validation rules;
-   migration behavior from the earlier no-persistence state.

For helper/UI protocol details, see `docs/protocol.md`.

## Storage Location

Omatune stores its persisted settings inline in the widget entry inside
Omarchy's `shell.json`.

For a bar widget instance, the entry shape is:

```json
{
  "id": "jeppeklh.omatune",
  "configVersion": 1,
  "referenceAHz": 440.0,
  "noteSpelling": "sharps",
  "selectedPresetId": "guitar.standard",
  "selectedReferenceNote": "A4"
}
```

Omatune updates that inline entry through the bar host's
`updateEntryInline()` path rather than maintaining a second plugin-owned
settings file.

## Supported Fields

-   `configVersion`: integer schema version. Current value: `1`.
-   `referenceAHz`: reference A frequency in Hz.
-   `noteSpelling`: `"sharps"` or `"flats"`.
-   `selectedPresetId`: built-in tuning preset identifier.
-   `selectedReferenceNote`: last selected chromatic reference note.

Unknown keys are preserved when Omatune rewrites its settings entry.

## Defaults

When no persisted configuration exists, Omatune uses:

-   `configVersion = 1`
-   `referenceAHz = 440.0`
-   `noteSpelling = "sharps"`
-   `selectedPresetId = "guitar.standard"`
-   `selectedReferenceNote = "A4"`

The helper does not persist live runtime state such as whether the tuner
is currently on or whether a tone is actively playing.

## Validation Rules

`referenceAHz` must be finite and within `400.0..=480.0` Hz.

`noteSpelling` must be one of:

-   `sharps`
-   `flats`

`selectedPresetId` must match a built-in preset shipped by the current
plugin build.

`selectedReferenceNote` must parse as a supported chromatic note in the
range `C0` through `B8` after canonicalization.

If a persisted value is invalid, Omatune falls back to the documented
default for that field.

## Runtime Config Application

The persisted `referenceAHz` value is applied in two places:

-   helper startup, via `--reference-a-hz <value>`, so the first pitch
    estimate uses the configured calibration;
-   helper runtime, via the additive `set_reference_a` protocol command,
    so live calibration changes also retune an active reference tone.

Preset selection and note-spelling preference remain UI-owned state.
They do not fork the underlying chromatic pitch model.

## Migration Rules

### From v0.1 / pre-persistence state

Earlier builds persisted none of these settings.

Migration behavior is therefore:

-   missing fields load with defaults;
-   missing `configVersion` is treated as pre-v1 schema;
-   invalid individual fields are replaced with defaults for that field;
-   unrelated unknown keys are preserved on the next write.

### Future schema changes

Any future incompatible change must:

-   bump `configVersion`;
-   document field-level migration here;
-   preserve existing defaults for users coming from missing or partial
    config;
-   avoid changing the meaning of an existing field silently.
