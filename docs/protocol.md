# Tuner Helper Protocol

## Purpose

This document defines the boundary between the Rust audio helper and the
QML/Quickshell UI.

For runtime ownership and lifecycle boundaries, see
`docs/architecture.md`. For implementation order, see
`docs/v0.1-implementation.md`.

The helper performs both directions of audio work:

-   microphone input for pitch detection;
-   audio output for synthesized reference tones and metronome clicks.

The protocol is intentionally small so the audio implementation and UI
can evolve independently.

For Phase 3 Omarchy IPC control and optional MIDI integration, see
`docs/external-control.md`.

## Transport

Use newline-delimited JSON (NDJSON).

-   Helper -\> QML messages are written to stdout.
-   QML -\> helper commands are written to stdin.
-   Human-readable diagnostics are written to stderr.

Each line is one complete JSON object.

In protocol mode, stdout must contain protocol messages only.

## Helper CLI

Normal invocation starts the helper in protocol mode.

Supported flags:

-   `--reference-a-hz <hz>` sets startup calibration within
    `400.0..=480.0` Hz;
-   `--transposition-semitones <n>` sets startup note transposition
    within `-12..=12` semitones;
-   `--temperament-offsets-cents <csv>` sets startup pitch-class
    temperament offsets as twelve comma-separated cents values in
    `C, C#, D, D#, E, F, F#, G, G#, A, A#, B` order;
-   `--dump-tuning-library` prints the built-in temperament and preset
    library as JSON and exits;
-   `--normalize-content-pack <json>` validates and normalizes one preset
    or temperament pack JSON object and exits;
-   `--list-midi-inputs` prints available MIDI input port names as a JSON
    array and exits;
-   `--listen-midi-input <port>` listens to one MIDI input port and
    writes external-control NDJSON commands to stdout;
-   `-h`, `--help` print usage text and exit without starting audio;
-   `-V`, `--version` print the helper version and exit without starting
    audio.

`--help`, `--version`, `--dump-tuning-library`, and
`--normalize-content-pack` are the documented non-helper-protocol stdout
modes. `--listen-midi-input` also uses stdout, but it emits the separate
external-control NDJSON described in `docs/external-control.md` rather
than helper UI messages.

## Helper -\> UI Messages

### Ready

Emitted after required helper initialization succeeds.

The current helper guarantees that `ready` is emitted before any input
worker `pitch` or `no_signal` message.

    {"type":"ready"}

### Pitch

Emitted when the helper has a usable pitch estimate.

    {
      "type": "pitch",
      "note": "G3",
      "frequency_hz": 196.38,
      "cents": 3.4,
      "confidence": 0.94
    }

Fields:

-   `type`: always `pitch`
-   `note`: nearest note name including octave after the current
    transposition is applied under the active temperament model; `0`
    means concert pitch
-   `frequency_hz`: detected fundamental frequency in Hz
-   `cents`: signed deviation from the nearest note; negative is flat
    and positive is sharp
-   `confidence`: optional normalized detector confidence from 0 to 1

The UI must not assume `confidence` is always present.

The current helper emits `confidence` on `pitch` messages when a usable
estimate is available.

The current helper applies short-term Rust-side stabilization before
emitting `pitch`, so a note change that looks like a transient or an
octave flip may require one additional confirming analysis hop.

### No Signal

Emitted when input is silent, too weak, or no reliable pitch is
currently available.

    {"type":"no_signal"}

The UI should clear or relax the previous tuning indication rather than
presenting stale pitch data as current.

The helper should avoid flooding identical no-signal messages
unnecessarily.

The current helper suppresses consecutive duplicate
`no_signal` messages until a usable `pitch` estimate is emitted.

When the input is still above the silence floor but one analysis hop is
briefly unstable, the helper may retain the prior pitch for that single
hop instead of flickering straight to `no_signal`.

### Tone Started

Confirms that reference-tone playback has started.

    {
      "type": "tone_started",
      "note": "A4",
      "frequency_hz": 440.0
    }

For Phase 5B/5C interval, drone, or chord playback, the same message
remains in use, with additive fields:

    {
      "type": "tone_started",
      "note": "A4",
      "frequency_hz": 440.0,
      "intervals_semitones": [12],
      "voices": [
        { "note": "A4", "frequency_hz": 440.0 },
        { "note": "A5", "frequency_hz": 880.0 }
      ]
    }

Phase 2 richer reference scenes keep that same shape and add an optional
bounded `scene_id` when the active scene is not the default `blend`
rendering:

    {
      "type": "tone_started",
      "note": "A4",
      "frequency_hz": 440.0,
      "scene_id": "pedal",
      "intervals_semitones": [4, 7],
      "voices": [
        { "note": "A4", "frequency_hz": 440.0 },
        { "note": "A3", "frequency_hz": 220.0 },
        { "note": "C#5", "frequency_hz": 554.3652619537442 },
        { "note": "E5", "frequency_hz": 659.2551138257398 }
      ]
    }

Rules:

-   `note` and `frequency_hz` remain the root voice of the active
    playback scene, with `note` expressed after the active transposition
    is applied and `frequency_hz` remaining the actual generated
    sounding frequency;
-   `scene_id`, when present, identifies one bounded richer rendering
    preset; the current helper accepts `blend` and `pedal`;
-   `intervals_semitones`, when present, echoes the extra interval notes
    above the root;
-   `voices`, when present, lists every note actually being generated in
    root-first order with note labels in the current transposition space
    and authoritative sounding frequencies; richer scenes may include a
    bounded support doubling such as a lower root octave that is not
    represented as another positive interval above the root;
-   single-note playback may omit `intervals_semitones` and `voices` to
    preserve the compact v0.1 message shape when the default `blend`
    scene is active.

Phase 5C simple chord presets still use this same representation. For
example, `A4` major is rooted at `A4` with
`intervals_semitones: [4, 7]` and voices `A4`, `C#5`, and `E5`.

The current helper opens audio output lazily when a tone is first
requested, rather than during initial startup.

Phase 6A establishes the shared-output ownership contract behind this
message without changing its wire shape yet:

-   one helper output worker owns all synthesized playback;
-   `tone_started` and `tone_stopped` remain scoped to the sustained
    reference-tone lane;
-   future metronome clicks must be mixed into that same worker and
    stream rather than opening a second output session;
-   role-specific output commands must not implicitly stop microphone
    capture or unrelated output lanes.

### Tone Stopped

Confirms that reference-tone playback has stopped.

    {"type":"tone_stopped"}

### Metronome Started

Confirms that metronome playback has started or been replaced.

    {
      "type": "metronome_started",
      "bpm": 120,
      "beats_per_bar": 4,
      "beat_unit": 4,
      "subdivision": 1
    }

Phase 6B kept the first shippable metronome slice intentionally small.
Phase 6C extends that same command surface additively:

-   `bpm` is the active whole-number tempo;
-   `beats_per_bar` and `beat_unit` identify the active meter;
-   the current helper accepts only `2/4`, `3/4`, `4/4`, and `6/8`;
-   `subdivision` is the active per-beat pulse count in `1..=4`;
-   a matching immediate downbeat is emitted as a `metronome_beat`
    message right after `metronome_started`.

### Metronome Beat

Emitted for each audible metronome beat.

    {
      "type": "metronome_beat",
      "beat_in_bar": 1,
      "beats_per_bar": 4,
      "beat_unit": 4,
      "subdivision_step": 1,
      "subdivision": 1,
      "accented": true
    }

Rules:

-   `beat_in_bar` is `1`-based;
-   `beats_per_bar` and `beat_unit` echo the active meter;
-   `subdivision_step` is `1`-based inside the current beat;
-   `subdivision` is the active per-beat pulse count;
-   `accented` is `true` only on beat one, subdivision step one;
-   the current helper emits the initial downbeat immediately on start,
    then emits later beat and subdivision messages from the shared output
    worker as the timed click lane advances.

### Metronome Stopped

Confirms that metronome playback has stopped.

    {"type":"metronome_stopped"}

### Error

Emitted when the helper encounters a runtime problem that the UI should
surface.

    {
      "type": "error",
      "code": "audio_input_unavailable",
      "message": "Unable to open microphone input"
    }

Possible initial codes:

-   `audio_input_unavailable`
-   `audio_input_disconnected`
-   `audio_output_unavailable`
-   `audio_output_disconnected`
-   `unsupported_format`
-   `invalid_note`
-   `invalid_reference_frequency`
-   `invalid_transposition`
-   `invalid_temperament`
-   `invalid_metronome_bpm`
-   `invalid_metronome_meter`
-   `invalid_metronome_subdivision`
-   `invalid_command`
-   `internal_error`

A fatal error may be followed by helper termination.

The current Phase 4 widget treats helper exit plus recoverable
input-startup/input-disconnect failures as bounded auto-recovery cases
rather than requiring manual restart every time.

## UI -\> Helper Commands

### Play Tone

Starts a reference tone.

Preferred command:

    {
      "type": "play_tone",
      "note": "A4"
    }

Phase 5B/5C keeps the same command and adds an optional
`intervals_semitones` array for bounded multi-note playback rooted at
the selected note:

    {
      "type": "play_tone",
      "note": "A4",
      "intervals_semitones": [12]
    }

Phase 2 richer reference scenes also add an optional bounded `scene_id`:

    {
      "type": "play_tone",
      "note": "A4",
      "scene_id": "pedal",
      "intervals_semitones": [4, 7]
    }

The helper calculates the frequency using the current reference A value.

When transposition is non-zero, the incoming `note` is interpreted in
that transposed note space. The generated frequency still corresponds to
the underlying sounding pitch.

For v0.1 the default reference is A4 = 440 Hz.

The command works for arbitrary supported chromatic notes, not only
guitar notes.

For v0.1, the supported note range is `C0` through `B8`, inclusive.

For Phase 5B/5C bounded multi-note playback:

-   `intervals_semitones` is optional;
-   `scene_id` is optional;
-   when present, `scene_id` must be one of the documented built-in
    scene ids: `blend` or `pedal`;
-   when present, it must be an array of integers;
-   each interval must be within `1..=24` semitones above the root;
-   the helper currently accepts at most three interval entries, for a
    maximum of four target notes including the root; richer scenes such
    as `pedal` may add one bounded support voice, for a maximum of five
    simultaneously generated voices;
-   duplicate interval entries are rejected;
-   every derived note must still remain inside the supported `C0`
    through `B8` range.

Examples:

    {"type":"play_tone","note":"E2"}
    {"type":"play_tone","note":"C4"}
    {"type":"play_tone","note":"F#4"}
    {"type":"play_tone","note":"Bb3"}
    {"type":"play_tone","note":"A4","intervals_semitones":[7]}
    {"type":"play_tone","note":"A4","intervals_semitones":[12]}
    {"type":"play_tone","note":"A4","intervals_semitones":[4,7]}

The implementation should normalize or explicitly document accepted
accidental notation. Internally, prefer one canonical representation.

For v0.1, accepted input notation is:

-   note letters `A` through `G`, case-insensitive;
-   an optional single `#` or `b` accidental;
-   an octave number in the supported range after canonicalization.

The helper emits canonical note names using sharps:

-   `Bb3` is normalized to `A#3`;
-   `Cb4` is normalized to `B3`;
-   `B#3` is normalized to `C4`.

If a tone is already playing, `play_tone` replaces it without requiring
a separate stop command.

Phase 6A also fixes the runtime ownership rule for future shared output:
`play_tone` replaces only the sustained reference-tone lane. It must not
be defined later as a global "stop everything else on the speakers"
command.

The current QML UI uses the same command for both additive playback
workflows:

-   `drone`: the selected note remains the sustained root and one
    configured interval note is added above it;
-   `chord`: the selected note remains the root and one fixed preset
    shape such as major, minor, `sus2`, or `sus4` provides the upper
    voices.

Phase 2 keeps the same target-note model and adds one bounded richer
scene selector:

-   `blend`: the default scene, with gentle root weighting and a mild
    harmonic mix so multi-note references stay clear without becoming a
    general synth surface;
-   `pedal`: adds a quiet lower root octave when supported by the note
    range, keeping the same target intervals and temperament math.

### Stop Tone

    {"type":"stop_tone"}

Stops current reference-tone playback.

Phase 6A keeps `stop_tone` scoped the same way: it stops only the
reference-tone lane. It does not imply stopping input capture or any
later timed metronome lane that shares the output worker.

### Set Reference A

Updates the helper's reference A calibration at runtime.

    {
      "type": "set_reference_a",
      "frequency_hz": 442.0
    }

### Set Transposition

Updates the helper's note-name transposition at runtime.

    {
      "type": "set_transposition",
      "semitones": 2
    }

Rules:

-   `semitones` must be an integer;
-   `semitones` must be within `-12..=12`.

Semantics:

-   `0` means concert pitch;
-   positive values shift displayed/selected note names upward relative
    to sounding pitch;
-   the helper applies the same setting to pitch messages and
    reference-tone confirmations.

When accepted:

-   subsequent pitch messages use the new transposed note labels;
-   future `play_tone` commands interpret their `note` field in the new
    transposed note space;
-   if a tone is already active, the helper keeps the sounding frequency
    consistent and emits a fresh `tone_started` confirmation with the new
    note labels.

If the requested transposition would make an already active richer scene
impossible to represent in the supported displayed note range, the
helper rejects `set_transposition` and leaves the prior transposition
and active tone unchanged.

### Set Temperament

Updates the helper's active chromatic temperament at runtime.

    {
      "type": "set_temperament",
      "offsets_cents": [-5.865, 7.82, -1.955, 11.73, 1.955, -7.82, 5.865, -3.91, 9.775, 0.0, -9.775, 3.91]
    }

Rules:

-   `offsets_cents` must be an array of exactly twelve numeric values;
-   values are interpreted in `C, C#, D, D#, E, F, F#, G, G#, A, A#, B`
    order;
-   values must remain within `+/-100.0` cents;
-   the helper normalizes the array so `A` remains exactly `0.0` cents,
    preserving the configured `A4` reference frequency.

When accepted:

-   subsequent pitch messages use the new temperament targets;
-   future `play_tone` commands use the new temperament targets;
-   if a tone is already active, the helper retunes that same scene and
    emits a fresh `tone_started` confirmation with the new authoritative
    frequencies.

### Set Reference A

Updates the helper's reference A calibration at runtime.

Rules:

-   `frequency_hz` must be numeric;
-   `frequency_hz` must be finite;
-   `frequency_hz` must be within `400.0..=480.0` Hz.

When accepted:

-   subsequent pitch messages use the new calibration;
-   future `play_tone` commands use the new calibration;
-   if a tone is already active, the helper retunes that same note and
    emits a fresh `tone_started` confirmation with the new authoritative
    frequency.

Example:

    {
      "type": "set_reference_a",
      "frequency_hz": 442.0
    }

### Start Metronome

Starts metronome playback.

    {
      "type": "start_metronome",
      "bpm": 120
    }

Extended Phase 6C example:

    {
      "type": "start_metronome",
      "bpm": 96,
      "beats_per_bar": 6,
      "beat_unit": 8,
      "subdivision": 3
    }

Rules:

-   `bpm` must be an integer;
-   `bpm` must be within `20..=300`;
-   `beats_per_bar` is optional and defaults to `4`;
-   `beat_unit` is optional and defaults to `4`;
-   `beats_per_bar` and `beat_unit`, together, must be one of the
    supported meters: `2/4`, `3/4`, `4/4`, or `6/8`;
-   `subdivision` is optional, defaults to `1`, and must be within
    `1..=4`;
-   repeated `start_metronome` commands replace the active metronome
    tempo and restart the bar on beat one;
-   `start_metronome` controls only the timed metronome lane and must not
    stop microphone capture or the sustained reference-tone lane.

Phase 6C keeps the rhythm model deliberately bounded:

-   one accent on beat one only;
-   one fixed set of common meters rather than arbitrary meter editing;
-   one evenly divided subdivision count per beat rather than patterns or
    sequencing.

### Stop Metronome

Stops current metronome playback.

    {"type":"stop_metronome"}

Like `stop_tone`, this remains role-scoped: it stops only the metronome
lane inside the shared output worker.

## Guitar Shortcuts

The QML UI should provide quick actions for standard guitar tuning:

-   E2
-   A2
-   D3
-   G3
-   B3
-   E4

These shortcuts send ordinary `play_tone` commands. There is no
guitar-specific protocol message.

At A4 = 440 Hz their approximate frequencies are:

-   E2: 82.41 Hz
-   A2: 110.00 Hz
-   D3: 146.83 Hz
-   G3: 196.00 Hz
-   B3: 246.94 Hz
-   E4: 329.63 Hz

## Timing

Pitch updates should be frequent enough for a responsive tuner. A
practical starting target is approximately 20--50 updates per second
when a stable signal is present.

The current Phase 4 helper analyzes 48 kHz mono input with a 4800-sample
window and a 2048-sample hop, which yields approximately 23 analysis
opportunities per second before any later suppression.

The current detection search range is approximately 30 Hz to 1200 Hz.

The protocol does not require every analysis frame to produce a message.
The helper may suppress redundant or low-confidence estimates.

Visual interpolation belongs to QML. Signal analysis and pitch smoothing
that affects correctness belong in Rust.

Tone start/stop commands should be acted upon promptly. Use a short
amplitude ramp when starting, stopping, or changing tones to reduce
audible clicks.

Phase 6A shared scheduling rules:

-   microphone capture remains independent from synthesized output;
-   all synthesized audio shares one helper-owned output stream and
    scheduler;
-   continuous tones and future timed clicks may overlap and are mixed in
    that worker;
-   output failures clear synthesized playback state, but they do not by
    themselves redefine the input-side protocol contract.

The current Phase 6C metronome adds one bounded timed-click contract on
top of that shared worker:

-   tempo is a whole-number BPM in `20..=300`;
-   the meter is one of `2/4`, `3/4`, `4/4`, or `6/8`;
-   beat one is accented;
-   subdivision is an even `1x` through `4x` split of each beat;
-   start/restart emits an immediate downbeat.

## Note Calculation

Use twelve-tone equal temperament with A4 = 440 Hz by default.

When a temperament is active, each sounding note frequency is derived by
applying the active pitch-class cents offset to the equal-tempered base
frequency.

For a note `n` semitones from A4:

    frequency = A4 * 2^(n / 12)

For detected frequency `f`, the distance in semitones from A4 is:

    n = 12 * log2(f / A4)

Cents deviation from reference frequency `f_ref` is:

    cents = 1200 * log2(f / f_ref)

Expected cents values relative to the nearest note are normally
approximately -50 to +50.

## Input Validation

Reject:

-   malformed JSON;
-   unknown command types;
-   invalid note names;
-   unsupported octaves;
-   non-finite numeric values;
-   reference frequencies outside any future documented calibration
    range.

A malformed command must not crash the helper.

## Compatibility

Additional JSON fields may be added in future versions. Consumers should
ignore unknown fields.

Changing the meaning or type of an existing field requires a protocol
revision.

## Debugging Contract

Valid stdout:

    {"type":"ready"}
    {"type":"pitch","note":"E2","frequency_hz":82.31,"cents":0.1,"confidence":0.97}
    {"type":"tone_started","note":"A2","frequency_hz":110.0}
    {"type":"tone_started","note":"A4","frequency_hz":440.0,"intervals_semitones":[12],"voices":[{"note":"A4","frequency_hz":440.0},{"note":"A5","frequency_hz":880.0}]}
    {"type":"tone_started","note":"A4","frequency_hz":440.0,"intervals_semitones":[4,7],"voices":[{"note":"A4","frequency_hz":440.0},{"note":"C#5","frequency_hz":554.3652619537442},{"note":"E5","frequency_hz":659.2551138257398}]}
    {"type":"tone_started","note":"A4","frequency_hz":440.0,"scene_id":"pedal","intervals_semitones":[4,7],"voices":[{"note":"A4","frequency_hz":440.0},{"note":"A3","frequency_hz":220.0},{"note":"C#5","frequency_hz":554.3652619537442},{"note":"E5","frequency_hz":659.2551138257398}]}
    {"type":"tone_stopped"}
    {"type":"no_signal"}

Invalid stdout:

    Starting tuner...
    microphone opened
    DEBUG frequency = 82.31

Those messages belong on stderr because they would break the NDJSON
consumer.
