# Omatune Configuration

## Purpose

This document defines the persisted user-facing configuration introduced
in Phase 1.

It covers:

-   where Omatune stores its settings;
-   the supported schema and defaults;
-   the human-readable import/export contract;
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
  "configVersion": 2,
  "referenceAHz": 440.0,
  "transpositionSemitones": 0,
  "noteSpelling": "sharps",
  "selectedPresetId": "guitar.standard",
  "selectedTemperamentId": "equal.12tet",
  "selectedReferenceNote": "A4",
  "metronomeBpm": 100,
  "metronomeBeatsPerBar": 4,
  "metronomeBeatUnit": 4,
  "metronomeSubdivision": 1,
  "highContrastMode": false,
  "reducedMotionMode": false,
  "favoriteQuickSwitches": [],
  "recentQuickSwitches": [],
  "importedTemperamentPacks": [],
  "importedPresetPacks": []
}
```

Omatune updates that inline entry through the bar host's
`updateEntryInline()` path rather than maintaining a second plugin-owned
settings file.

## Supported Fields

-   `configVersion`: integer schema version. Current value: `2`.
-   `referenceAHz`: reference A frequency in Hz.
-   `transpositionSemitones`: integer semitone offset from sounding pitch
    to displayed/selected note names.
-   `noteSpelling`: `"sharps"` or `"flats"`.
-   `selectedPresetId`: currently selected tuning preset identifier.
-   `selectedTemperamentId`: currently selected temperament identifier.
-   `selectedReferenceNote`: last selected chromatic reference note.
-   `metronomeBpm`: last selected whole-number metronome tempo.
-   `metronomeBeatsPerBar`: last selected metronome meter numerator.
-   `metronomeBeatUnit`: last selected metronome meter denominator.
-   `metronomeSubdivision`: last selected per-beat subdivision count.
-   `highContrastMode`: boolean display-preference flag.
-   `reducedMotionMode`: boolean display-preference flag.
-   `favoriteQuickSwitches`: bounded list of saved workflow snapshots.
-   `recentQuickSwitches`: bounded list of recent workflow snapshots.
-   `importedTemperamentPacks`: locally installed normalized temperament
    packs.
-   `importedPresetPacks`: locally installed normalized preset packs.

Unknown keys are preserved when Omatune rewrites its settings entry,
except for the legacy `popupLayoutMode` key which is removed on the
next write.

## Human-Readable Import/Export

Omatune's `Advanced` popup destination exposes two copy/paste surfaces:

-   a configuration editor for the stable settings schema;
-   a content-pack editor for preset packs and temperament packs.

The configuration export is pretty-printed JSON containing only the
supported fields listed above, in a stable order. It intentionally omits
the widget `id` and any unrelated host-side keys from the surrounding
`shell.json` entry.

Configuration import accepts that same JSON object. It also tolerates a
pasted widget entry copied directly from `shell.json`; any `id` or other
unknown keys are ignored by the transfer layer. Missing or invalid
supported fields normalize with the same defaults and validation rules
used for persisted settings.

If the imported document contains a numeric `configVersion` newer than
the current build supports, Omatune rejects the import rather than
silently downgrading it.

Import rewrites the active widget settings through the normal
persistence path, so existing unknown keys already present in the local
widget entry remain preserved on the next write.

Pack import and export are separate from the configuration editor.

-   `Load preset pack` exports the currently selected preset pack.
-   `Load temperament pack` exports the currently selected temperament
    pack.
-   `Apply pack import` validates one pasted preset or temperament pack
    through the Rust helper's normalization mode before persisting it.

## Defaults

When no persisted configuration exists, Omatune uses:

-   `configVersion = 2`
-   `referenceAHz = 440.0`
-   `transpositionSemitones = 0`
-   `noteSpelling = "sharps"`
-   `selectedPresetId = "guitar.standard"`
-   `selectedTemperamentId = "equal.12tet"`
-   `selectedReferenceNote = "A4"`
-   `metronomeBpm = 100`
-   `metronomeBeatsPerBar = 4`
-   `metronomeBeatUnit = 4`
-   `metronomeSubdivision = 1`
-   `highContrastMode = false`
-   `reducedMotionMode = false`
-   `favoriteQuickSwitches = []`
-   `recentQuickSwitches = []`
-   `importedTemperamentPacks = []`
-   `importedPresetPacks = []`

The helper does not persist live runtime state such as whether the tuner
is currently on or whether a tone or metronome is actively playing.

## Validation Rules

`referenceAHz` must be finite and within `400.0..=480.0` Hz.

`transpositionSemitones` must be an integer within `-12..=12`.

`noteSpelling` must be one of:

-   `sharps`
-   `flats`

`selectedPresetId` stores a normalized preset id. When the merged
built-in plus imported library is available, unresolved ids fall back to
the built-in default `guitar.standard`.

`selectedTemperamentId` stores a normalized temperament id. When the
merged built-in plus imported library is available, unresolved ids fall
back to the built-in default `equal.12tet`.

`selectedReferenceNote` must parse as a supported chromatic note in the
range `C0` through `B8` after canonicalization.

`metronomeBpm` must be an integer within `20..=300`.

`metronomeBeatsPerBar` and `metronomeBeatUnit` must resolve to one of
the supported metronome presets:

-   `2/4`
-   `3/4`
-   `4/4`
-   `6/8`

`metronomeSubdivision` must be an integer within `1..=4`.

`highContrastMode` and `reducedMotionMode` must be boolean values.

`favoriteQuickSwitches` and `recentQuickSwitches` must be arrays of at
most six normalized workflow snapshots.

`importedTemperamentPacks` and `importedPresetPacks` must be arrays of
normalized pack objects accepted by the schemas in
`docs/temperament-packs.md` and `docs/preset-packs.md`.

Each workflow snapshot stores:

-   `presetId`
-   `temperamentId`
-   `referenceNote`
-   `transpositionSemitones`
-   `playbackMode`
-   `intervalSemitones`
-   `chordId`
-   `metronomeBpm`
-   `metronomeBeatsPerBar`
-   `metronomeBeatUnit`
-   `metronomeSubdivision`

Within those snapshots:

-   `playbackMode` must be `single`, `drone`, or `chord`.
-   `transpositionSemitones` uses the same `-12..=12` integer validation
    rule as the top-level field.
-   `intervalSemitones` must resolve to one of the built-in drone
    interval presets.
-   `chordId` must resolve to one of the built-in chord presets.
-   `presetId`, `temperamentId`, `referenceNote`, and metronome fields
    use the same validation rules as their top-level equivalents.

Those snapshot fields are validated with the rules above plus the
snapshot-specific playback-mode, interval, and chord constraints here.
Invalid fields fall back to the documented defaults for that field.
Duplicate snapshots are removed after normalization, preserving the
earliest surviving entry.

If a persisted value is invalid, Omatune falls back to the documented
default for that field.

## Runtime Config Application

The persisted `referenceAHz` value is applied in two places:

-   helper startup, via `--reference-a-hz <value>`, so the first pitch
    estimate uses the configured calibration;
-   helper runtime, via the additive `set_reference_a` protocol command,
    so live calibration changes also retune an active reference tone.

The persisted `transpositionSemitones` value is applied in two places:

-   helper startup, via `--transposition-semitones <value>`, so the first
    pitch estimate uses the configured note-label transposition;
-   helper runtime, via the additive `set_transposition` protocol
    command, so live transposition changes update pitch interpretation
    and any active reference tone labels together.

The persisted `selectedTemperamentId` value is applied through the
helper-owned temperament model:

-   helper startup, via `--temperament-offsets-cents <csv>`, so the first
    pitch estimate and first reference tone use the selected
    temperament;
-   helper runtime, via the additive `set_temperament` protocol command,
    so live temperament changes retune pitch interpretation and any
    active reference tone together.

Preset selection, saved quick-switch workflow snapshots, note-spelling
preference, metronome BPM, meter, subdivision, and display
accessibility preferences remain UI-owned state. Imported preset packs
and temperament packs are persisted by the UI, but their validation and
normalization are Rust-owned. Reference A, transposition, and the active
temperament feed one helper-owned pitch model without forking the
underlying chromatic tuner into instrument-specific engines.

## Migration Rules

### From v0.1 / pre-persistence state

Earlier builds persisted none of these settings.

Migration behavior is therefore:

-   missing fields load with defaults;
-   missing `configVersion` is treated as pre-v1 schema;
-   invalid individual fields are replaced with defaults for that field;
-   unrelated unknown keys are preserved on the next write.

This same additive rule covers the later metronome rhythm fields:
earlier saved widget entries simply fall back to the defaults of
`100 BPM`, `4/4`, and `1x` subdivision.

The later quick-switch workflow fields are additive under that same
schema version: missing favorite or recent lists simply load as empty
arrays.

The later transposition field is additive under that same schema
version: missing `transpositionSemitones` simply loads as `0`.

### From v1.x configuration version 1

Phase 1 of `v2.0` bumps the exported configuration schema to `2` to add
temperament and content-pack state.

Migration behavior from `configVersion = 1` is additive:

-   missing `selectedTemperamentId` loads as `equal.12tet`;
-   missing `importedTemperamentPacks` loads as `[]`;
-   missing `importedPresetPacks` loads as `[]`;
-   older preset and quick-switch fields keep their existing meaning.

The removed `popupLayoutMode` field from pre-`v1.5` cleanup builds is
tolerated on load and import, ignored by the runtime UI, and omitted on
the next save or export.

### Future schema changes

Any future incompatible change must:

-   bump `configVersion`;
-   document field-level migration here;
-   preserve existing defaults for users coming from missing or partial
    config;
-   avoid changing the meaning of an existing field silently.
