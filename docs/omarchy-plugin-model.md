# Omatune Omarchy Plugin Model

## Purpose

This document records the Omarchy and Quickshell integration facts
confirmed during Phase 1 implementation, so later work can start from
repository-local evidence instead of re-discovering the host model.

Re-check these assumptions if the installed Omarchy shell version changes
materially.

## Source References

Confirmed against these local references:

-   `/usr/share/omarchy/shell/README.md`
-   `/usr/share/omarchy/shell/plugins/README.md`
-   `/usr/share/omarchy/shell/services/PluginRegistry.qml`
-   `/usr/share/omarchy/shell/Ui/BarWidget.qml`
-   `/usr/share/omarchy/shell/Ui/WidgetButton.qml`
-   `/home/jklh/Projects/switchlet-omarchy/manifest.json`
-   `/home/jklh/Projects/switchlet-omarchy/BarWidget.qml`

Do not edit files under `/usr/share/omarchy/`; they are installed host
references, not project-owned source.

## Confirmed Plugin Facts

-   An Omarchy plugin is a repository with a root-level `manifest.json`.
-   Third-party plugins are installed under
    `~/.config/omarchy/plugins/<plugin-id>/`.
-   `manifest.json` declares `schemaVersion`, `id`, `name`, `version`,
    `author`, `description`, `kinds`, and `entryPoints`.
-   For this project, the relevant kind is `bar-widget`.
-   `entryPoints.barWidget` is a relative path inside the plugin root.
-   `barWidget.defaultSection` must be one of `left`, `center`, or
    `right`.
-   Saving files under `~/.config/omarchy/plugins/` hot-reloads plugin
    code.

## Bar Widget Contract

The bar widget root should extend `BarWidget` from `qs.Ui`.

The host injects these base properties:

-   `bar`: the live bar host instance;
-   `moduleName`: the widget's canonical plugin id;
-   `settings`: inline shell configuration for the widget instance.

For Omatune Phase 1:

-   `moduleName` should match the manifest id;
-   the bar widget owns helper lifecycle state from the UI side;
-   the widget starts and stops one persistent helper process rather than
    polling with repeated short-lived commands.

## Quickshell Process Model

`Process` from `Quickshell.Io` is the relevant primitive for helper
integration.

Confirmed useful behavior:

-   `running: false` defines an idle process object that can be started by
    setting `running = true`.
-   `command: [...]` takes an argv array.
-   `stdinEnabled: true` is needed when the helper should keep stdin open
    or receive commands later.
-   `stdout: SplitParser` is appropriate for line-oriented streaming
    protocol data.
-   `stderr: SplitParser` is appropriate for line-oriented diagnostics.
-   `stdout: StdioCollector` is better suited to one-shot commands where
    the full output is needed only after exit.
-   `onExited` provides exit handling for unexpected helper termination.

For Omatune, Phase 1 uses:

-   one persistent `Process` instance in `BarWidget.qml`;
-   `stdout` as NDJSON protocol input for the UI;
-   `stderr` as diagnostic text only;
-   a small launcher script so QML runs one stable command while helper
    packaging remains unfinished.

## Popup Pattern

For a bar widget with an anchored detail view, the current Omatune shape
uses `PopupCard` rather than a full `PanelWindow`.

Confirmed useful pattern details:

-   the bar-widget root should expose `open()`, `close()`, `toggle()`,
    `opened`, and `closeForPopoutSwitch()` when it participates in the
    bar popout coordinator;
-   the popup is anchored to the widget's button item;
-   a `Loader` can own a separate `Popup.qml` file and inject `bar`,
    `anchorItem`, and `hostWidget` after load;
-   `PopupCard.owner` should point at the widget identity that the bar
    tracks, not only the nested popup item.

## Validation And Development Facts

Confirmed host-side validation entry point:

```bash
omarchy plugin validate /home/jklh/Projects/omatone
```

Useful local helper checks:

```bash
cargo build --bin omatune-helper
bash scripts/run-helper.sh --version
bash scripts/run-helper.sh < /dev/null
bash scripts/build-helper-release.sh
```

Additional Phase 3 helper checks:

```bash
cargo run --quiet --bin omatune-helper <<< '{"type":"play_tone","note":"A4"}'
cargo run --quiet --bin omatune-helper <<< $'{"type":"play_tone","note":"A4"}\n{"type":"stop_tone"}'
```

Additional Phase 4 helper check:

```bash
cargo test --test helper_protocol helper_can_exit_after_ready_for_recovery_testing -- --exact
```

Phase 6 deterministic helper checks:

```bash
OMATUNE_TEST_INPUT_MODE=unavailable OMATUNE_TEST_OUTPUT_MODE=ok cargo run --quiet --bin omatune-helper
cargo test --test helper_protocol repeated_startup_cycles_keep_ready_before_no_signal -- --exact
cargo test --test helper_protocol runtime_input_disconnect_is_reported_after_ready -- --exact
cargo test --test helper_protocol helper_can_exit_after_ready_for_recovery_testing -- --exact
cargo test --test helper_protocol simulated_pitch_is_emitted_after_ready -- --exact
cargo test --test helper_protocol runtime_output_failure_is_reported_without_crashing_helper -- --exact
```

The helper contract remains:

-   stdout: protocol messages only;
-   stderr: diagnostics only;
-   no shell-command polling for pitch updates.

## Phase 1 Decisions Based On These Facts

-   Use a root-level `manifest.json` plus `BarWidget.qml` entry point.
-   Keep the plugin as a `bar-widget`, not a full custom bar.
-   Launch the helper from QML with one persistent `Process`.
-   Keep the Rust helper as a separate executable boundary from the UI.
-   Use a shell launcher only as a bootstrap layer while the compiled
    helper packaging is still unresolved.
-   For Phase 3 reference output, the local host fact is that Omarchy runs
    `PulseAudio (on PipeWire ...)`, so the helper currently targets that
    compatibility layer through `libpulse-simple-binding`.
-   For Phase 4 microphone capture, the helper uses the same compatibility
    layer for input so both audio directions share one host integration
    path.
-   For Phase 5 UI, the widget opens an anchored popup for live readout,
    helper controls, guitar shortcuts, and chromatic reference-note
    selection.
-   For Phase 6 verification, the helper supports environment-driven test
    modes that simulate startup input failure, runtime input disconnect,
    deterministic helper exit, no-signal, deterministic pitch, and output
    failure.
-   For packaging, `scripts/run-helper.sh` now prefers
    `OMATUNE_HELPER_BIN` when explicitly set, then
    `bin/omatune-helper`, so a release build can stage one plugin-local
    executable instead of relying on a live Cargo build.
-   `scripts/build-helper-release.sh` stages the packaged helper through a
    temporary file before replacing `bin/omatune-helper`, so updates do
    not leave a partially copied binary in the plugin root.
