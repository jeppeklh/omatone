# Omatune

Omatune is an Omarchy bar plugin for tuning and practice.

It gives you a real-time chromatic tuner, reference notes, intervals,
chords, drones, a metronome, and optional MIDI note control from the
bar.

## Getting It Running

Requires Omarchy, microphone access, working audio output, and Rust with
Cargo.

```sh
omarchy plugin add https://github.com/jeppeklh/omatune.git --enable
```

Open the music-note widget in the bar to start it. The first launch
builds the Rust helper if no packaged helper binary is present.

Remove it with:

```sh
omarchy plugin remove jeppeklh.omatune
```
