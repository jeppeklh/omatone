# Omatune Architecture

## Purpose

This is the implementation-facing architecture contract for v0.1.

-   `README.md` covers product goals and scope.
-   `AGENTS.md` captures contributor constraints and quality bars.
-   `docs/omarchy-plugin-model.md` records verified Omarchy/Quickshell
    host facts for this repository.
-   `docs/protocol.md` defines the helper/UI wire contract.
-   This document records ownership, runtime boundaries, and the few
    implementation decisions that must stay consistent across phases.

## System Split

Omatune has two runtime components.

### QML / Quickshell UI

Owns:

-   presentation and layout;
-   tuner activation/deactivation;
-   user interaction for note selection and guitar shortcuts;
 -   persisted calibration, spelling, and tuning-preset preferences;
 -   helper process lifecycle from the UI side;
-   visual smoothing that does not change pitch correctness;
-   displaying pitch, no-signal, and error states.

### Rust Audio Helper

Owns:

-   microphone capture;
-   reference-tone audio output;
-   pitch detection and confidence estimation;
-   note parsing, normalization, and note/frequency math;
 -   validated helper-side reference A configuration;
 -   silence and weak-signal rejection;
-   helper protocol I/O;
-   audio-related error handling.

## Data Flow

Input path:

    Microphone -> Linux audio stack -> Rust helper -> pitch detector
    -> note/cents calculation -> NDJSON stdout -> QML UI

Output path:

    QML UI -> NDJSON stdin -> Rust helper -> oscillator/ramp
    -> Linux audio stack -> speakers

## Runtime Model

-   Run one persistent helper process while the tuner is active.
-   Do not respawn shell commands repeatedly to poll pitch.
-   stdout is reserved for protocol messages only.
-   stderr is reserved for diagnostics and logs.
-   The helper writes `ready` before allowing the input worker to emit
    `pitch` or `no_signal` messages.
-   The QML launcher prefers a packaged plugin-local helper binary, then
    local build outputs, then a development `cargo run` fallback.
-   Persisted widget settings live in the bar entry inside Omarchy's
    `shell.json`; the helper receives the current reference A value at
    startup and can also receive additive runtime updates over the
    protocol.
-   Reference-tone playback must not block microphone analysis.
-   Expensive DSP work must not run on the QML UI thread.

The UI may smooth meter motion, but pitch estimation and any smoothing
that affects musical correctness belong in Rust.

## State Model

### UI States

-   `inactive`: tuner is not running;
-   `starting`: helper launch requested, waiting for readiness or error;
-   `active_no_signal`: helper is alive but no usable pitch is present;
-   `active_pitch`: helper is emitting usable pitch data;
-   `error`: helper reported or encountered a recoverable or fatal
    problem.

### Helper States

-   `initializing`: opening audio resources and starting protocol loop;
-   `ready`: initialized and able to accept commands;
-   `monitoring`: analyzing input for pitch or no-signal state;
-   `playing_tone`: optional substate while reference output is active;
-   `fatal_exit`: helper cannot continue and terminates.

The protocol does not need separate messages for every internal helper
state. It only needs the externally relevant ones defined in
`docs/protocol.md`.

## Stable Decisions For v0.1

-   Keep the core tuner chromatic and instrument-independent.
-   Treat guitar notes as UI presets over the general note model.
-   Use twelve-tone equal temperament with internal A4 parameterization.
-   Accept note input in case-insensitive letter form with an optional
    single sharp/flat accidental, and emit canonical sharp note names.
-   Support chromatic notes in the range `C0` through `B8` for v0.1.
-   For Phase 3 output, use a PulseAudio-compatible Rust client against
    Omarchy's PipeWire-hosted PulseAudio server, keeping the audio helper
    as the only process boundary.
-   For Phase 4 microphone capture, use the same PulseAudio-compatible
    path so input and output share one Linux audio integration layer.
-   Open microphone input during helper startup, but open reference output
    lazily on the first `play_tone` request.
-   Use a YIN-style monophonic detector over 48 kHz mono input with a
    4096-sample analysis window and 2048-sample hop, yielding roughly 23
    pitch opportunities per second.
-   Search for detected fundamentals in an initial practical range of
    approximately 50 Hz to 1200 Hz.
-   The Phase 5 UI is a compact bar widget with an anchored popup detail
    view rather than a full summoned panel.
-   Opening the popup starts the helper when the tuner is currently off;
    closing the popup does not implicitly stop the helper.
-   Start reference tones with a sine wave plus a short amplitude ramp.
-   Prefer a simple, documented helper/UI protocol over tighter coupling.
-   Favor low latency over unnecessary numerical precision.

## Decisions To Resolve During Implementation

These should be decided once and then documented in code or this file.

-   Which audio failures are recoverable in-process and which should end
    the helper.
-   Whether detector confidence is always emitted or only when the chosen
    algorithm provides a stable value.

## Non-Goals For This Document

This file should stay small. Do not turn it into a second roadmap or a
duplicate of the protocol spec.
