# AGENTS.md

## Purpose

This repository implements a small real-time chromatic tuner and
reference-tone generator for the Omarchy bar.

Guitar is the primary convenience use case, not an architectural
limitation. Keep the core tuner instrument-independent.

## Architecture Rules

-   QML owns presentation and interaction.
-   Rust owns microphone capture, audio output, signal processing, pitch
    detection, note calculations, and reference-tone synthesis.
-   Use the Linux audio stack, preferably PipeWire or a well-maintained
    Rust abstraction that integrates cleanly with it.
-   Run one persistent audio helper while the tuner is active.
-   Stream results to QML; do not poll by repeatedly spawning shell
    commands.
-   Keep the helper/UI protocol simple and documented in
    `docs/protocol.md`.
-   Never perform expensive audio analysis or audio synthesis on the QML
    UI thread.
-   Do not implement guitar strings as special cases in the pitch
    engine. They are UI presets over the general note/frequency model.

## Real-Time Behavior

-   The tuning indicator must visibly react in real time.
-   Favor low latency over unnecessary numerical precision.
-   Pitch estimates should be emitted often enough to feel continuous.
-   UI animation may smooth jitter, but must not introduce noticeable
    lag.
-   Silence and low-confidence input should produce an explicit
    no-signal state rather than stale pitch data.
-   Starting or stopping a reference tone should feel immediate.
-   Reference-tone generation must not block microphone analysis or the
    QML UI.

## v0.1 Product Scope

Implement:

-   Chromatic pitch detection
-   Automatic nearest-note detection
-   Frequency display
-   Cents deviation
-   Real-time tuning indicator
-   Tuner on/off state
-   Arbitrary chromatic reference-note selection
-   Reference-tone playback
-   Standard guitar shortcuts: E2, A2, D3, G3, B3, E4
-   A4 = 440 Hz as the default reference
-   Internal support for a configurable reference A frequency
-   Graceful silence, weak-signal, microphone-error, output-error, and
    helper-exit states

Do not add unless the scope is intentionally changed:

-   Instrument-specific pitch engines
-   Large instrument preset systems
-   Saved tuning libraries
-   User-facing A4 calibration controls
-   Audio recording
-   Network services
-   Telemetry
-   Complex animation systems

## Guitar Preset

At A4 = 440 Hz, the standard guitar shortcuts are:

-   E2: approximately 82.41 Hz
-   A2: 110.00 Hz
-   D3: approximately 146.83 Hz
-   G3: 196.00 Hz
-   B3: approximately 246.94 Hz
-   E4: approximately 329.63 Hz

Calculate these through the same general note-frequency function used
for arbitrary notes. Do not maintain a separate hard-coded frequency
engine for guitar.

## Dependency Rules

-   Prefer Rust + QML + the existing Linux/Omarchy audio and shell
    stack.
-   Do not introduce Electron, Node.js, Python, a web server, or a
    database for the core tuner.
-   Add Rust crates only when they materially reduce complexity or
    improve correctness.
-   Avoid large DSP frameworks if focused pitch detection and oscillator
    code are sufficient.
-   Do not ship prerecorded audio files when a reference tone can be
    synthesized.

## Pitch Detection

Start with a monophonic pitch detector suitable for musical instruments,
such as YIN or a comparable autocorrelation-based method.

The detector should:

-   reject silence and obviously unusable frames;
-   provide a frequency estimate;
-   expose confidence when practical;
-   avoid rapidly jumping between octaves;
-   support a useful musical range beyond standard guitar;
-   remain independent of any particular tuning or instrument.

Do not optimize prematurely. Establish correctness with synthetic and
recorded test signals before micro-optimizing.

## Reference-Tone Synthesis

Generate reference tones mathematically in Rust.

Start with a sine wave. It provides a clean, unambiguous fundamental and
avoids requiring bundled samples.

Requirements:

-   derive frequency from note + octave + reference A frequency;
-   support arbitrary chromatic notes within the documented range;
-   start and stop cleanly;
-   avoid clicks where practical by applying a short amplitude ramp;
-   use a conservative output level;
-   never allow invalid note input to produce NaN, infinity, or unsafe
    audio values.

A richer waveform may be added later, but it is not required for v0.1.

## Note/Frequency Model

Use twelve-tone equal temperament.

Default:

    A4 = 440 Hz

For `n` semitones relative to A4:

    frequency = A4 * 2^(n / 12)

For detected frequency `f` and target/reference frequency `f_ref`:

    cents = 1200 * log2(f / f_ref)

Keep the A4 value parameterized internally even if the initial UI fixes
it at 440 Hz.

## Process Boundary

The Rust helper writes newline-delimited protocol messages to stdout.

stdout is protocol data only. Diagnostics and errors belong on stderr.

If QML sends commands to the helper, use newline-delimited JSON on
stdin.

Do not print logs, banners, progress messages, or debug text to stdout.

See `docs/protocol.md`.

## Failure Handling

The Omarchy bar must remain usable if:

-   microphone permission/access fails;
-   no input device exists;
-   audio output cannot be opened;
-   an output device disappears while a tone is playing;
-   the helper crashes;
-   malformed protocol data is received;
-   the signal is too weak;
-   pitch cannot be estimated;
-   an invalid reference-note command is received.

Surface a compact tuner error/no-signal state and allow the tuner to be
restarted.

## Testing

At minimum, test these independently:

-   note -\> frequency conversion;
-   frequency -\> nearest note;
-   cents calculation;
-   pitch detection against deterministic signals;
-   reference oscillator frequency;
-   protocol command parsing.

Important reference:

-   A4 = 440 Hz
-   A3 = 220 Hz
-   A2 = 110 Hz
-   A5 = 880 Hz

Test frequencies above and below target notes, near semitone boundaries,
and across a wider range than guitar alone.

For oscillator tests, verify generated frequency numerically rather than
relying on human listening.

## Working Style

-   Keep changes small and reviewable.
-   Do not expand scope to solve hypothetical future requirements.
-   Preserve the general chromatic model even when optimizing the guitar
    workflow.
-   Update documentation when the helper protocol or architecture
    changes.
-   Verify current Omarchy plugin APIs before depending on undocumented
    behavior.
-   Optimize for a tiny, reliable utility rather than a general audio
    framework.
