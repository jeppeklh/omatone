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
 -   external live-control mapping from Omarchy IPC commands into widget
    state;
 -   persisted calibration, spelling, and tuning-preset preferences;
-   persisted transposition preferences for advanced tuning workflows;
-   persisted quick-switch favorites and recent workflow snapshots over
    existing tuner state;
-   persisted metronome BPM, meter, and subdivision preferences;
-   persisted popup-layout and display-accessibility preferences;
 -   helper process lifecycle from the UI side;
 -   optional MIDI-listener process lifecycle from the UI side;
 -   visual smoothing that does not change pitch correctness;
 -   displaying pitch, no-signal, and error states.

### Rust Audio Helper

Owns:

-   microphone capture;
-   reference-tone audio output;
-   shared output scheduling and mixing for sustained tones and timed
    metronome click pulses;
-   metronome timing, beat-accent scheduling, and subdivision pulses;
-   pitch detection and confidence estimation;
-   note parsing, normalization, and note/frequency math;
 -   validated helper-side reference A configuration;
 -   helper-owned transposition-aware target-note interpretation;
 -   optional MIDI input enumeration and note-listener tool modes;
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
-   Omatune exposes one Quickshell IPC target, `jeppeklh.omatune`, for
    higher-level external preset, reference, and transport control.
-   The helper writes `ready` before allowing the input worker to emit
    `pitch` or `no_signal` messages.
-   The QML side performs bounded automatic restart attempts after
    unexpected helper exit and recoverable input-side startup/runtime
    failures.
-   The QML launcher honors an explicit `OMATUNE_HELPER_BIN` override,
    then prefers a packaged plugin-local helper binary, then local build
    outputs, then a development `cargo run` fallback.
-   Persisted widget settings live in the bar entry inside Omarchy's
    `shell.json`; the helper receives the current reference A value at
    startup and can also receive additive runtime updates over the
    protocol.
-   Optional MIDI note input runs through a separate helper tool mode so
    missing MIDI support does not block the main tuner/audio-helper path.
-   Reference-tone playback must not block microphone analysis.
-   One persistent output worker owns all synthesized playback lanes.
    Reference-tone commands update only the sustained-tone lane; the
    Phase 6C metronome lane shares that same worker and stream rather
    than opening a second output path.
-   Output-lane changes must be immediate and role-scoped. Stopping or
    retuning a reference tone must not imply stopping microphone capture
    or any future timed-pulse lane.
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
    4800-sample analysis window and 2048-sample hop, yielding roughly 23
    pitch opportunities per second.
-   Search for detected fundamentals in an initial practical range of
    approximately 30 Hz to 1200 Hz.
-   Apply short-term Rust-side stability rules that use signal level for
    silence gating and detector confidence for note switching so noisy
    hops and octave glitches do not immediately replace a good lock.
-   The Phase 5 UI is a compact bar widget with an anchored popup detail
    view rather than a full summoned panel.
-   Opening the popup starts the helper when the tuner is currently off;
    closing the popup does not implicitly stop the helper.
-   Start reference tones with a sine wave plus a short amplitude ramp.
-   Reserve shared-output ownership for one sustained-tone lane plus a
    timed-pulse lane so metronome clicks can coexist without a second
    scheduler or device session.
-   For the current metronome slice, keep the rhythm model bounded to
    common preset meters (`2/4`, `3/4`, `4/4`, `6/8`), an accented beat
    one, whole-number BPM, and `1x` through `4x` subdivisions.
-   Prefer a simple, documented helper/UI protocol over tighter coupling.
-   Favor low latency over unnecessary numerical precision.
-   External live-control commands are last-writer-wins and do not
    rewrite persisted settings on every trigger.

## Decisions To Resolve During Implementation

These should be decided once and then documented in code or this file.

-   Which audio failures are recoverable in-process and which should end
    the helper.
-   Whether detector confidence is always emitted or only when the chosen
    algorithm provides a stable value.

## Non-Goals For This Document

This file should stay small. Do not turn it into a second roadmap or a
duplicate of the protocol spec.
