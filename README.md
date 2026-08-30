# Omatune

Omatune is an Omarchy bar plugin for real-time chromatic tuning.

It listens to your microphone, shows the nearest note and cents offset,
and can play reference tones and a metronome.

## Getting It Running

Requires Omarchy, microphone access, working audio output, and Rust with
Cargo.

```sh
omarchy plugin add https://github.com/jeppeklh/omatone.git --enable
```

Open the music-note widget in the bar to start it. The first launch
builds the Rust helper if no packaged helper binary is present.

Remove it with:

```sh
omarchy plugin remove jeppeklh.omatune
```
