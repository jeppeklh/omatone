# Tuner Helper Protocol

## Purpose

This document defines the boundary between the Rust audio helper and the
QML/Quickshell UI.

For runtime ownership and lifecycle boundaries, see
`docs/architecture.md`. For implementation order, see
`docs/v0.1-implementation.md`.

The helper performs both directions of audio work:

-   microphone input for pitch detection;
-   audio output for synthesized reference tones.

The protocol is intentionally small so the audio implementation and UI
can evolve independently.

## Transport

Use newline-delimited JSON (NDJSON).

-   Helper -\> QML messages are written to stdout.
-   QML -\> helper commands are written to stdin.
-   Human-readable diagnostics are written to stderr.

Each line is one complete JSON object.

stdout must contain protocol messages only.

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
-   `note`: nearest equal-tempered note name including octave
-   `frequency_hz`: detected fundamental frequency in Hz
-   `cents`: signed deviation from the nearest note; negative is flat
    and positive is sharp
-   `confidence`: optional normalized detector confidence from 0 to 1

The UI must not assume `confidence` is always present.

The current helper emits `confidence` on `pitch` messages when a usable
estimate is available.

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

### Tone Started

Confirms that reference-tone playback has started.

    {
      "type": "tone_started",
      "note": "A4",
      "frequency_hz": 440.0
    }

The reported frequency is authoritative for the tone actually being
generated.

The current helper opens audio output lazily when a tone is first
requested, rather than during initial startup.

### Tone Stopped

Confirms that reference-tone playback has stopped.

    {"type":"tone_stopped"}

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
-   `invalid_command`
-   `internal_error`

A fatal error may be followed by helper termination.

## UI -\> Helper Commands

### Play Tone

Starts a reference tone.

Preferred command:

    {
      "type": "play_tone",
      "note": "A4"
    }

The helper calculates the frequency using the current reference A value.

For v0.1 the default reference is A4 = 440 Hz.

The command works for arbitrary supported chromatic notes, not only
guitar notes.

For v0.1, the supported note range is `C0` through `B8`, inclusive.

Examples:

    {"type":"play_tone","note":"E2"}
    {"type":"play_tone","note":"C4"}
    {"type":"play_tone","note":"F#4"}
    {"type":"play_tone","note":"Bb3"}

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

### Stop Tone

    {"type":"stop_tone"}

Stops current reference-tone playback.

### Future: Set Reference A

The internal architecture should support a configurable reference A, but
a user-facing control is not required for v0.1.

If exposed later, a command may take a form such as:

    {
      "type": "set_reference_a",
      "frequency_hz": 442.0
    }

Do not implement this command merely because it is documented as a
possible extension. Add it when calibration becomes product scope.

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

The current Phase 4 helper analyzes 48 kHz mono input with a 4096-sample
window and a 2048-sample hop, which yields approximately 23 analysis
opportunities per second before any later suppression.

The current detection search range is approximately 50 Hz to 1200 Hz.

The protocol does not require every analysis frame to produce a message.
The helper may suppress redundant or low-confidence estimates.

Visual interpolation belongs to QML. Signal analysis and pitch smoothing
that affects correctness belong in Rust.

Tone start/stop commands should be acted upon promptly. Use a short
amplitude ramp when starting, stopping, or changing tones to reduce
audible clicks.

## Note Calculation

Use twelve-tone equal temperament with A4 = 440 Hz by default.

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
    {"type":"tone_stopped"}
    {"type":"no_signal"}

Invalid stdout:

    Starting tuner...
    microphone opened
    DEBUG frequency = 82.31

Those messages belong on stderr because they would break the NDJSON
consumer.
