# Omarchy Tuner

A small real-time chromatic tuner and reference-tone generator for the
Omarchy bar.

## Goal

Provide a tuner that feels native to the Omarchy shell: activate it from
the bar, play a note, and see the detected note and cents deviation
update continuously.

The tuner is chromatic. Standard guitar tuning is a convenient preset,
not a limitation of the pitch detector.

The plugin also provides reference-tone playback. A user can select a
note and hear its exact reference pitch for tuning by ear.

## Documentation

-   `docs/architecture.md`: implementation-facing ownership and runtime
    boundaries
-   `docs/configuration.md`: persisted settings schema, defaults, and
    migration rules
-   `docs/omarchy-plugin-model.md`: confirmed Omarchy/Quickshell plugin
    facts and local validation workflow
-   `docs/protocol.md`: NDJSON contract between the Rust helper and the
    QML UI
-   `docs/v0.1-implementation.md`: ordered implementation phases for the
    v0.1 milestone
-   `docs/v1.0-implementation.md`: required core phases and optional
    expansion phases on the path to a stable 1.0
-   `docs/v0.1-verification.md`: automated checks, deterministic helper
    failure simulations, and the manual release checklist
-   `docs/roadmap.md`: product roadmap beyond the initial release

## Current Scope

-   Chromatic pitch detection
-   Automatic nearest-note detection
-   Real-time cents indicator
-   Display detected note and frequency
-   Microphone activation/deactivation
-   Reference-tone playback
-   Arbitrary note selection for reference tones
-   Adjustable A4 reference frequency in the supported calibration range
-   Persisted reference note, tuning preset, and sharp/flat spelling
    preference
-   Built-in guitar, bass, ukulele, and violin-family tuning presets
-   Sensible behavior for silence, weak input, invalid pitch estimates,
    and audio errors
-   QML bar widget with a small native Rust helper

Not included:

-   Instrument-specific pitch engines
-   Large saved preset libraries
-   Recording or audio storage
-   Elaborate visual effects

## Standard Guitar Reference Tones

At A4 = 440 Hz:

-   E2 --- approximately 82.41 Hz
-   A2 --- 110.00 Hz
-   D3 --- approximately 146.83 Hz
-   G3 --- 196.00 Hz
-   B3 --- approximately 246.94 Hz
-   E4 --- approximately 329.63 Hz

These are shortcuts only. The reference-tone generator must be capable
of playing arbitrary chromatic notes within its supported range.

## Architecture

The project has two primary responsibilities.

### QML / Quickshell UI

-   Lives in the Omarchy bar.
-   Starts and stops the audio helper.
-   Reads pitch updates from the helper.
-   Displays detected note, frequency, cents offset, and tuner
    indicator.
-   Lets the user select and start/stop reference tones.
-   Provides fast guitar-note shortcuts.
-   Smooths visual movement where appropriate.

### Rust Audio Helper

-   Captures microphone audio through the Linux audio stack.
-   Performs pitch detection continuously.
-   Converts frequency to the nearest equal-tempered note and cents
    deviation.
-   Generates reference tones mathematically.
-   Sends reference audio through the Linux audio output stack.
-   Streams state and pitch updates to the UI.
-   Does not own presentation.

Conceptually:

    Microphone -> PipeWire -> pitch detection --+
                                                |
                                                +-> Rust audio helper <-> QML / Quickshell -> Omarchy bar
                                                |
    Speakers <- PipeWire <- reference oscillator+

## Runtime Model

The Rust helper is a persistent process while the tuner is active. It
must not be launched once per UI refresh.

Pitch estimates should be produced frequently enough for the indicator
to feel immediate. The UI may interpolate or smooth between estimates,
but it must not hide meaningful tuning changes.

Reference tones are synthesized in real time. No collection of
prerecorded note samples is required.

## Pitch and Frequency Model

Use twelve-tone equal temperament.

The default reference is:

    A4 = 440 Hz

For a note `n` semitones away from A4:

    frequency = A4 * 2^(n / 12)

The implementation should accept the A4 reference as a parameter
internally even though v0.1 may expose only 440 Hz in the UI. This keeps
future calibration support straightforward.

## Repository Layout

Suggested initial layout:

    omarchy-tuner/
    ├── README.md
    ├── AGENTS.md
    ├── manifest.json
    ├── BarWidget.qml
    ├── Popup.qml
    ├── Cargo.toml
    ├── bin/
    │   └── omatune-helper
    ├── scripts/
    │   ├── build-helper-release.sh
    │   └── run-helper.sh
    ├── src/
    │   ├── audio_input.rs
    │   ├── audio_output.rs
    │   ├── lib.rs
    │   ├── note.rs
    │   ├── pitch_detection.rs
    │   ├── protocol_io.rs
    │   ├── protocol.rs
    │   ├── reference_tone.rs
    │   └── main.rs
    └── docs/
        ├── architecture.md
        ├── omarchy-plugin-model.md
        ├── protocol.md
        ├── roadmap.md
        ├── v0.1-implementation.md
        ├── v1.0-implementation.md
        └── v0.1-verification.md

The exact Omarchy manifest and plugin layout should be verified against
the current Omarchy plugin documentation during implementation.

## Development Principles

Keep the project small. Prefer platform-native components and avoid
adding a framework when a small dependency or standard facility is
sufficient.

Guitar should have an excellent fast path, but the core pitch model must
remain instrument-independent.

The tuner should fail gracefully. Losing microphone access, losing audio
output, or receiving unusable audio must never freeze or crash the
Omarchy bar.

## Success Criteria

v0.1 is successful when a user can:

1.  Activate the tuner and play a note into the microphone.
2.  See a stable chromatic note name plus a responsive cents indication.
3.  Select any supported chromatic note and hear its reference pitch.
4.  Quickly play the six standard guitar reference pitches without
    manually selecting them.
