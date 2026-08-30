# Omatune Roadmap

Omatune is a small, native-feeling tuning utility for Omarchy. It begins
as a real-time chromatic tuner and reference-tone generator in the
Omarchy bar, then grows carefully into a compact set of musician tools
without becoming a DAW or general-purpose audio workstation.

For the ordered implementation slices inside `v0.1`, see
`docs/v0.1-implementation.md`. For the broader path from `v0.1` to
`v1.0`, see `docs/v1.0-implementation.md`. For the post-`1.0`
implementation path toward `v2.0`, see `docs/v2.0-implementation.md`.
For the focused `v1.5` UX cleanup milestone before that broader
expansion, see `docs/v1.5-implementation.md`.

## Naming

**Omatune** combines **Omarchy** and **tune**.

Use **Omatune** as the user-facing project name and `omatune` for
command, repository, package, and plugin identifiers where lowercase
naming is appropriate.

## Roadmap Conventions

Versions describe product milestones. Implementation work *inside* a
version may be divided into phases or vertical slices. Do not use
"phase" as a synonym for a version.

Reliability, simplicity, and a small footprint take priority over
feature count.

## v0.1 --- Core Tuner

Goal: make Omatune a tuner worth keeping in the Omarchy bar.

-   Real-time chromatic pitch detection
-   Automatic nearest-note detection
-   Note name, frequency in Hz, and signed cents deviation
-   Smooth tuning meter and clear in-tune state
-   Silence, weak-signal, and error states
-   Synthesized reference-tone playback
-   Arbitrary chromatic reference-note selection
-   Standard guitar shortcuts: E2, A2, D3, G3, B3, E4
-   A4 = 440 Hz default
-   QML / Quickshell UI
-   Rust audio/DSP helper
-   PipeWire-compatible input/output
-   Persistent helper process
-   Graceful audio/helper failure handling

Guitar gets an excellent fast path, but the engine remains chromatic and
instrument-independent.

## v0.2 --- Tunings and Personalization

Goal: support different instruments, tunings, and musical contexts.

-   Adjustable reference A frequency
-   Persist selected reference pitch
-   Drop D, D standard, Eb standard, DADGAD, and common open tunings
-   Bass, ukulele, and useful violin-family presets
-   Custom tunings
-   Remember last-used tuning
-   Sharps/flats preference
-   Reference-tone volume
-   Optional lightweight waveform selection

Presets remain collections of target notes, not separate pitch engines.

## v0.3 --- Detection Quality and UX

Goal: feel comparable to a good dedicated tuner.

-   Better noisy-room rejection
-   Faster note lock
-   Fewer octave errors
-   Better low-frequency/bass detection
-   Confidence-aware stabilization
-   Better pluck-transient handling
-   More robust silence detection
-   Adjustable sensitivity where useful
-   Signal-strength indication
-   Refined note transitions and meter motion
-   Polished bar/popup behavior
-   Keyboard-first operation
-   Low CPU usage while active and near-zero overhead while inactive

## v0.4 --- Ear Tuning and Musician Tools

Goal: expand from measuring pitch into useful pitch-reference tools.

-   Drone mode
-   Continuous reference notes
-   Reference intervals
-   Simple reference chords
-   Fast octave changes
-   Keyboard note navigation
-   More capable custom instrument presets
-   Transposing-instrument support
-   Temperaments beyond 12-TET
-   Optional short-term tuning stability/history

A metronome becomes a strong candidate here because Omatune already owns
low-latency audio output.

## v0.5 --- Metronome

Goal: add a precise, immediately accessible practice clock.

-   Adjustable BPM
-   Tap tempo
-   Bar start/stop
-   Beat-one accent
-   Common meters
-   Subdivisions
-   Keyboard controls
-   Low-latency synthesized click
-   Visual beat indication
-   Persist BPM and meter
-   Predictable interaction between tuner, reference tone, and metronome
    audio

Do not add sequencing, drum-machine patterns, backing tracks, or
arrangement features.

## v0.6 --- Practice Workflow

Goal: make repeated practice actions faster.

-   Favorite tunings
-   Favorite reference notes
-   Favorite metronome settings
-   Quick-switch presets
-   Recent settings
-   Named practice presets
-   Better keyboard navigation
-   Optional global shortcuts if Omarchy supports them cleanly
-   Human-readable configuration import/export

Avoid accounts, cloud sync, and databases.

## v0.7 --- Advanced Tuning

Goal: support specialized intonation and tuning requirements.

-   Expanded temperament support
-   User-defined temperament offsets
-   Per-note target offsets where useful
-   Capo-aware guitar display
-   Transposition helpers
-   Seven/eight-string guitar presets
-   Five/six-string bass presets
-   Better very-low-frequency analysis
-   Configurable detected-note range

The default experience must remain simple.

## v0.8 --- Visual and Accessibility Refinement

Goal: make Omatune exceptionally clear across Omarchy setups.

-   Multiple compact meter presentations
-   Better bar-size/display-density scaling
-   High-contrast feedback
-   Reduced-motion behavior
-   Strong keyboard accessibility
-   Non-color-only in-tune indication
-   Compact and expanded popup layouts
-   Native Omarchy theme integration

Avoid turning customization into a large styling framework.

## v0.9 --- Hardening

Goal: prepare for a stable 1.0 contract.

-   CPU/memory profiling
-   Long-running stability tests
-   Device disconnect/reconnect tests
-   PipeWire restart recovery
-   Helper crash recovery
-   Protocol error/fuzz tests
-   Configuration migration tests
-   Pitch-detection regression suite
-   Synthetic-tone test corpus
-   Real-instrument validation
-   Installation/upgrade testing
-   Stable CLI behavior
-   Stable helper protocol
-   Stable configuration schema
-   Documentation audit

Feature additions should be minimal during v0.9.

## v1.0 --- Stable Omatune

Goal: ship a small musician utility that feels native to Omarchy.

v1.0 is defined by quality and stability rather than maximum feature
count.

-   Accurate, responsive chromatic tuning
-   Excellent standard-guitar workflow
-   Flexible tuning presets
-   Reliable reference tones
-   Calibration support
-   Mature pitch detection
-   Polished Omarchy integration
-   Low resource usage
-   Reliable PipeWire behavior
-   Predictable configuration
-   Stable helper protocol
-   Straightforward installation/updating
-   Complete user and contributor documentation

A metronome and advanced tools may be included if they meet the same
quality bar; they are not prerequisites for calling the tuner itself
1.0.

## Beyond 1.0

Possible directions should be evaluated individually:

-   Additional temperament libraries
-   More instrument/tuning preset packs
-   Improved polyphonic reference sounds
-   Optional MIDI note input for selecting reference tones
-   Integration points for other Omarchy musician plugins
-   Optional advanced pitch-analysis views
-   Community-defined preset files

## Explicit Non-Goals

Omatune should not gradually become a DAW, recorder, effects processor,
amp simulator, tablature editor, song library, backing-track service,
drum machine, or cloud music platform.

When a proposed feature moves Omatune toward one of those categories,
prefer interoperability with a dedicated tool.
