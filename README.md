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
note and hear its exact reference pitch for tuning by ear, either alone,
as a drone interval, or with a small fixed chord shape.

The current optional practice-tool slice also includes a small
metronome with whole-number BPM, tap tempo, common meters,
subdivisions, and a beat-one accent.

## Documentation

-   `docs/architecture.md`: implementation-facing ownership and runtime
    boundaries
-   `docs/configuration.md`: persisted settings schema, defaults, and
    migration rules
-   `docs/external-control.md`: shell IPC and optional MIDI live-control
    contract
-   `docs/omarchy-plugin-model.md`: confirmed Omarchy/Quickshell plugin
    facts and local validation workflow
-   `docs/preset-packs.md`: shareable preset-pack schema and
    normalization rules
-   `docs/protocol.md`: NDJSON contract between the Rust helper and the
    QML UI
-   `docs/temperament-packs.md`: shareable temperament-pack schema and
    normalization rules
-   `docs/v0.1-implementation.md`: ordered implementation phases for the
    v0.1 milestone
-   `docs/v1.0-implementation.md`: required core phases and optional
    expansion phases on the path to a stable 1.0
-   `docs/v1.5-implementation.md`: ordered cleanup steps for the
    pre-v2.0 UX milestone
-   `docs/v2.0-implementation.md`: post-1.0 phases for broader tuning,
    interoperability, and power-user workflows
-   `docs/v2.5-ui-ux-implementation.md`: focused UI/UX cleanup, naming,
    and workflow phases after broader `v2.0` growth
-   `docs/v1.5-ux-review.md`: archived UX review and rationale for the
    shipped `v1.5` cleanup
-   `docs/v0.1-verification.md`: automated checks, deterministic helper
    failure simulations, and the manual release checklist
-   `docs/v1.0-verification.md`: Phase 4 hardening checks, bounded
    recovery validation, and install/update/remove smoke tests
-   `docs/roadmap.md`: product roadmap beyond the initial release

## Current Scope

-   Chromatic pitch detection
-   Automatic nearest-note detection
-   Real-time cents indicator
-   Display detected note and frequency
-   Microphone activation/deactivation
-   Single-note, drone-interval, and simple chord reference-tone
    playback
-   Metronome playback with start/stop, adjustable BPM, tap tempo,
    common meters, subdivisions, beat-one accent, and compact beat
    indication
-   Arbitrary note selection for reference tones
-   Adjustable A4 reference frequency in the supported calibration range
-   Optional semitone transposition across detected note labels and
    reference-tone targeting
-   Built-in equal, pythagorean, and meantone temperament choices with
    A-anchored offset handling
-   Stable-width icon-only bar feedback with bounded activity markers and
    concise hover summaries
-   Popup destinations for `Tune`, `Tone`, `Metronome`, `Presets`,
    and `Advanced`
-   Shell IPC control for live preset, reference, and metronome actions
-   Optional MIDI note input for retuning the live reference selection
-   Default `Tune` workflow with immediate `E A D G B E` access, strict
    single-note playback, and no required scrolling
-   Persisted reference note, metronome tempo/meter/subdivision, tuning
    preset, and sharp/flat spelling preference
-   Persisted quick-switch favorites and recents for workflow snapshots
    over the current preset, reference scene, and metronome setup
-   Human-readable copy/paste import/export of the supported JSON
    configuration schema
-   Dedicated preset-pack and temperament-pack import/export surface in
    `Advanced`
-   Built-in guitar, bass, ukulele, violin-family, mandolin-family,
    banjo, tenor-guitar, and extended-range string presets
-   Sensible behavior for silence, weak input, invalid pitch estimates,
    and audio errors
-   Bounded automatic recovery after unexpected helper exit and
    input-side audio failures
-   QML bar widget with a small native Rust helper

Not included:

-   Instrument-specific pitch engines
-   Large saved preset libraries
-   Recording or audio storage
-   Elaborate visual effects

## Install, Update, Remove

Install into Omarchy's plugin directory:

1.  Build the packaged helper from the repository root:

    ```bash
    bash scripts/build-helper-release.sh
    ```

2.  Copy the plugin into Omarchy's user plugin directory.

    Current local Omarchy validation rejects a symlinked plugin root, so
    local development should use a copied directory rather than a
    symlink.

    ```bash
    mkdir -p ~/.config/omarchy/plugins/jeppeklh.omatune
    rsync -a --delete --exclude ".git/" --exclude "target/" ./ ~/.config/omarchy/plugins/jeppeklh.omatune/
    ```

3.  Validate and load the copied plugin:

    ```bash
    omarchy plugin validate ~/.config/omarchy/plugins/jeppeklh.omatune
    omarchy shell shell rescanPlugins
    omarchy plugin enable jeppeklh.omatune
    omarchy restart shell
    ```

4.  Open the widget once to verify helper startup.

Refresh the installed development copy after local changes:

```bash
bash scripts/build-helper-release.sh
rsync -a --delete --exclude ".git/" --exclude "target/" ./ ~/.config/omarchy/plugins/jeppeklh.omatune/
omarchy restart shell
```

Remove the copied plugin again:

```bash
omarchy plugin disable jeppeklh.omatune
rm -rf ~/.config/omarchy/plugins/jeppeklh.omatune
omarchy shell shell rescanPlugins
omarchy restart shell
```

These removal commands delete only the copied plugin directory. They do
not delete this repository.

## Helper CLI

Normal helper mode is the NDJSON protocol process documented in
`docs/protocol.md`.

Supported flags:

-   `--reference-a-hz <hz>`: startup A4 calibration within
    `400.0..=480.0` Hz
-   `--transposition-semitones <n>`: startup note transposition within
    `-12..=12` semitones
-   `--temperament-offsets-cents <csv>`: startup temperament offsets as
    twelve comma-separated cents values in pitch-class order
-   `-h`, `--help`: print usage and exit without starting audio
-   `-V`, `--version`: print the helper version and exit without starting
    audio

Documented helper tool modes:

-   `--dump-tuning-library`: print the built-in temperament and preset
    library as JSON and exit
-   `--normalize-content-pack <json>`: validate and normalize one preset
    or temperament pack JSON object and exit
-   `--list-midi-inputs`: print available MIDI input port names as JSON
    and exit
-   `--listen-midi-input <port>`: emit external-control NDJSON for one
    MIDI input port

`scripts/run-helper.sh` resolves the helper in this order:

1.  `OMATUNE_HELPER_BIN` when it is explicitly set to an executable path
2.  `bin/omatune-helper`
3.  `target/debug/omatune-helper`
4.  `target/release/omatune-helper`
5.  `cargo run --quiet --bin omatune-helper -- ...` as a development
    fallback

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
-   Lets the user control a small metronome from the popup.
-   Provides fast guitar-note shortcuts.
-   Smooths visual movement where appropriate.

### Rust Audio Helper

-   Captures microphone audio through the Linux audio stack.
-   Performs pitch detection continuously.
-   Converts frequency to the nearest equal-tempered note and cents
    deviation.
-   Generates reference tones mathematically.
-   Generates metronome clicks mathematically on the shared output path.
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

The implementation accepts the A4 reference as a parameter internally
and now exposes that calibration in the UI within the supported
`400.0..=480.0` Hz range.

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
