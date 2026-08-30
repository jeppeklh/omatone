# Omatune External Control

## Purpose

This document defines Omatune's Phase 3 live-control contract for other
local tools, scripts, and Omarchy plugins.

For the Rust audio-helper NDJSON boundary, see `docs/protocol.md`.

## Transport

Omatune exposes one Quickshell IPC target:

-   target: `jeppeklh.omatune`
-   method: `control`
-   payload: one JSON object as a string argument

Health check:

```bash
quickshell ipc -p "$OMARCHY_PATH/shell" call jeppeklh.omatune ping
```

Control call shape:

```bash
quickshell ipc -p "$OMARCHY_PATH/shell" call jeppeklh.omatune control '{"type":"play_reference","note":"A4"}'
```

If the shell or plugin is not running, the IPC call fails at the shell
boundary instead of scraping QML state.

## Command Contract

Supported command types:

-   `select_reference`
-   `play_reference`
-   `stop_reference`
-   `select_preset`
-   `start_metronome`
-   `stop_metronome`

Unknown fields should be ignored by callers and may be added later.

### Reference Commands

`select_reference` updates the current live reference selection.

`play_reference` updates the current live reference selection, then
starts or replaces reference playback.

`stop_reference` stops the sustained reference lane.

Examples:

```json
{"type":"select_reference","note":"A4"}
{"type":"play_reference","note":"A4"}
{"type":"play_reference","note":"D3","playback_mode":"drone","interval_semitones":7}
{"type":"play_reference","playback_mode":"chord","chord_id":"minor","scene_id":"pedal"}
{"type":"stop_reference"}
```

Rules:

-   `note`, when present, is a concert-pitch note string in Omatune's
    supported `C0` through `B8` range after canonicalization;
-   `note` is interpreted before any active display transposition, so
    external callers stay stable even when the UI is in `Bb`, `F`, or
    another transposed display mode;
-   omitted reference-shape fields preserve the current live selection;
-   `playback_mode`, when present, must be `single`, `drone`, or
    `chord`;
-   `scene_id`, when present, must be `blend` or `pedal`;
-   `interval_semitones`, when present, must be one of the shipped drone
    presets: `3`, `4`, `5`, `7`, or `12`;
-   `chord_id`, when present, must be one of the shipped chord presets:
    `major`, `minor`, `sus2`, or `sus4`;
-   `single` playback does not accept `interval_semitones` or
    `chord_id`;
-   `drone` playback does not accept `chord_id`;
-   `chord` playback does not accept `interval_semitones`;
-   `select_reference` retunes the active reference immediately when a
    tone is already playing;
-   reference commands reject scenes that would fall outside Omatune's
    supported displayed note range under the current transposition.

### Preset Selection

`select_preset` switches the live preset selection by id.

Example:

```json
{"type":"select_preset","preset_id":"guitar.standard"}
```

Rules:

-   `preset_id` must be a non-empty string;
-   the id must exist in the currently loaded built-in plus imported
    preset library.

### Metronome Commands

`start_metronome` starts or replaces the metronome lane.

`stop_metronome` stops the metronome lane.

Examples:

```json
{"type":"start_metronome"}
{"type":"start_metronome","bpm":96,"beats_per_bar":6,"beat_unit":8,"subdivision":3}
{"type":"stop_metronome"}
```

Rules:

-   omitted fields preserve the current live metronome settings;
-   `bpm`, when present, must be an integer in `20..=300`;
-   `beats_per_bar` and `beat_unit`, when updated, must resolve to one
    of Omatune's supported meters: `2/4`, `3/4`, `4/4`, or `6/8`;
-   `subdivision`, when present, must be an integer in `1..=4`.

## Runtime Semantics

-   external commands update live UI and helper state only;
-   they do not rewrite `shell.json`, quick-switch recents, or favorites
    on every trigger;
-   the default user-driven workflow remains unchanged when no external
    caller invokes the IPC target;
-   when multiple sources issue commands, Omatune applies the latest
    valid command and shows that resulting state in the UI.

## MIDI Integration

Omatune's optional MIDI listener is implemented as a helper tool mode,
not as a required dependency of the main audio-helper path.

Available helper tool modes:

-   `--list-midi-inputs` prints a JSON array of available MIDI input port
    names and exits;
-   `--listen-midi-input <port>` listens to one MIDI input port and emits
    NDJSON `select_reference` commands to stdout.

Example listener output:

```json
{"type":"select_reference","note":"A4"}
```

Rules:

-   note-on events with velocity greater than zero select the
    concert-pitch root note;
-   out-of-range MIDI note numbers outside Omatune's `C0` through `B8`
    note model are ignored;
-   unavailable or unknown MIDI ports fail clearly on stderr and do not
    disable the core tuner or reference controls.
