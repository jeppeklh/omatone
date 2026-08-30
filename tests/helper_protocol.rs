use omatune::note::{Note, Temperament, DEFAULT_REFERENCE_A_HZ};
use omatune::protocol::UiMessage;
use std::io::{BufRead, BufReader, Read, Write};
use std::process::{Child, Command, Output, Stdio};
use std::sync::mpsc;
use std::thread;
use std::time::Duration;

fn helper_bin() -> &'static str {
    env!("CARGO_BIN_EXE_omatune-helper")
}

fn launcher_script() -> String {
    format!("{}/scripts/run-helper.sh", env!("CARGO_MANIFEST_DIR"))
}

fn spawn_helper(input_mode: Option<&str>, output_mode: Option<&str>, args: &[&str]) -> Child {
    let mut command = Command::new(helper_bin());
    command
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    command.args(args);
    if let Some(mode) = input_mode {
        command.env("OMATUNE_TEST_INPUT_MODE", mode);
    }
    if let Some(mode) = output_mode {
        command.env("OMATUNE_TEST_OUTPUT_MODE", mode);
    }

    command.spawn().expect("failed to spawn helper")
}

fn run_helper_with_input(
    stdin_text: &str,
    input_mode: Option<&str>,
    output_mode: Option<&str>,
    args: &[&str],
) -> Output {
    let mut child = spawn_helper(input_mode, output_mode, args);
    if !stdin_text.is_empty() {
        let mut stdin = child.stdin.take().expect("missing helper stdin");
        stdin
            .write_all(stdin_text.as_bytes())
            .expect("failed to write helper stdin");
    }
    drop(child.stdin.take());

    child.wait_with_output().expect("failed to wait for helper")
}

fn run_helper_until_stdout_lines(
    stdin_text: &str,
    stdout_lines_before_eof: usize,
    input_mode: Option<&str>,
    output_mode: Option<&str>,
    args: &[&str],
) -> Output {
    let mut child = spawn_helper(input_mode, output_mode, args);
    let mut stdin = child.stdin.take().expect("missing helper stdin");
    let stdout = child.stdout.take().expect("missing helper stdout");
    let stderr = child.stderr.take().expect("missing helper stderr");
    let (line_tx, line_rx) = mpsc::sync_channel::<()>(stdout_lines_before_eof.max(1));

    let stdout_thread = thread::spawn(move || {
        let mut reader = BufReader::new(stdout);
        let mut bytes = Vec::new();

        loop {
            let mut line = String::new();
            let read = reader
                .read_line(&mut line)
                .expect("failed to read helper stdout");
            if read == 0 {
                break;
            }

            bytes.extend_from_slice(line.as_bytes());
            let _ = line_tx.send(());
        }

        bytes
    });

    let stderr_thread = thread::spawn(move || {
        let mut reader = BufReader::new(stderr);
        let mut bytes = Vec::new();
        reader
            .read_to_end(&mut bytes)
            .expect("failed to read helper stderr");
        bytes
    });

    if !stdin_text.is_empty() {
        stdin
            .write_all(stdin_text.as_bytes())
            .expect("failed to write helper stdin");
    }

    for _ in 0..stdout_lines_before_eof {
        line_rx
            .recv_timeout(Duration::from_secs(3))
            .expect("timed out waiting for helper stdout");
    }

    drop(stdin);

    let status = child.wait().expect("failed to wait for helper");
    let stdout = stdout_thread.join().expect("stdout collector panicked");
    let stderr = stderr_thread.join().expect("stderr collector panicked");

    Output {
        status,
        stdout,
        stderr,
    }
}

fn run_helper_until_exit(
    stdin_text: &str,
    input_mode: Option<&str>,
    output_mode: Option<&str>,
    args: &[&str],
) -> Output {
    let mut child = spawn_helper(input_mode, output_mode, args);
    let mut stdin = child.stdin.take().expect("missing helper stdin");
    let stdout = child.stdout.take().expect("missing helper stdout");
    let stderr = child.stderr.take().expect("missing helper stderr");

    let stdout_thread = thread::spawn(move || {
        let mut reader = BufReader::new(stdout);
        let mut bytes = Vec::new();
        reader
            .read_to_end(&mut bytes)
            .expect("failed to read helper stdout");
        bytes
    });

    let stderr_thread = thread::spawn(move || {
        let mut reader = BufReader::new(stderr);
        let mut bytes = Vec::new();
        reader
            .read_to_end(&mut bytes)
            .expect("failed to read helper stderr");
        bytes
    });

    if !stdin_text.is_empty() {
        stdin
            .write_all(stdin_text.as_bytes())
            .expect("failed to write helper stdin");
    }

    let status = child.wait().expect("failed to wait for helper");
    drop(stdin);

    let stdout = stdout_thread.join().expect("stdout collector panicked");
    let stderr = stderr_thread.join().expect("stderr collector panicked");

    Output {
        status,
        stdout,
        stderr,
    }
}

fn stdout_lines(output: &Output) -> Vec<String> {
    String::from_utf8(output.stdout.clone())
        .expect("stdout was not utf-8")
        .lines()
        .map(str::to_owned)
        .collect()
}

#[test]
fn helper_cli_help_is_stable() {
    let output = Command::new(helper_bin())
        .arg("--help")
        .output()
        .expect("failed to run helper --help");

    assert!(output.status.success());
    assert_eq!(
        String::from_utf8(output.stdout).unwrap(),
        "Usage: omatune-helper [--reference-a-hz <hz>] [--transposition-semitones <n>] [--temperament-offsets-cents <csv>] [--help] [--version]\n       omatune-helper --dump-tuning-library\n       omatune-helper --normalize-content-pack <json>\n\nStarts Omatune's NDJSON audio helper.\nReads commands from stdin, writes protocol messages to stdout, and writes diagnostics to stderr.\n\nOptions:\n  --reference-a-hz <hz>          Set startup calibration within 400.0..=480.0 Hz\n  --transposition-semitones <n>  Set startup transposition within -12..=12 semitones\n  --temperament-offsets-cents    Set startup pitch-class offsets as 12 comma-separated cents values\n  --dump-tuning-library          Print the built-in temperament and preset library as JSON and exit\n  --normalize-content-pack <json>  Normalize one preset or temperament pack JSON object and exit\n  -h, --help                     Print this help text and exit\n  -V, --version                  Print helper version and exit\n"
    );
    assert_eq!(String::from_utf8(output.stderr).unwrap(), "");
}

#[test]
fn helper_cli_version_is_stable() {
    let output = Command::new(helper_bin())
        .arg("--version")
        .output()
        .expect("failed to run helper --version");

    assert!(output.status.success());
    assert_eq!(
        String::from_utf8(output.stdout).unwrap(),
        format!("omatune-helper {}\n", env!("CARGO_PKG_VERSION"))
    );
    assert_eq!(String::from_utf8(output.stderr).unwrap(), "");
}

#[test]
fn launcher_override_forwards_cli_args_to_helper() {
    let output = Command::new("bash")
        .arg(launcher_script())
        .arg("--version")
        .env("OMATUNE_HELPER_BIN", helper_bin())
        .output()
        .expect("failed to run helper launcher");

    assert!(output.status.success());
    assert_eq!(
        String::from_utf8(output.stdout).unwrap(),
        format!("omatune-helper {}\n", env!("CARGO_PKG_VERSION"))
    );
}

#[test]
fn launcher_fails_clearly_for_non_executable_override() {
    let output = Command::new("bash")
        .arg(launcher_script())
        .arg("--version")
        .env("OMATUNE_HELPER_BIN", "/definitely/missing/omatune-helper")
        .output()
        .expect("failed to run helper launcher with bad override");

    assert!(!output.status.success());
    assert_eq!(String::from_utf8(output.stdout).unwrap(), "");
    assert!(String::from_utf8(output.stderr)
        .unwrap()
        .contains("OMATUNE_HELPER_BIN is set but not executable"));
}

#[test]
fn startup_input_failure_emits_error_before_ready() {
    let output = run_helper_with_input("", Some("unavailable"), Some("ok"), &[]);
    let lines = stdout_lines(&output);

    assert!(!output.status.success());
    assert_eq!(lines.len(), 1);
    assert_eq!(
        lines[0],
        r#"{"type":"error","code":"audio_input_unavailable","message":"simulated microphone input unavailable"}"#
    );
}

#[test]
fn repeated_startup_cycles_keep_ready_before_no_signal() {
    for _ in 0..3 {
        let output = run_helper_until_stdout_lines("", 2, Some("no_signal"), Some("ok"), &[]);
        let lines = stdout_lines(&output);

        assert!(output.status.success());
        assert_eq!(
            lines,
            vec![
                r#"{"type":"ready"}"#.to_owned(),
                r#"{"type":"no_signal"}"#.to_owned(),
            ]
        );
    }
}

#[test]
fn play_and_stop_tone_work_without_real_audio_device_in_mock_mode() {
    let output = run_helper_with_input(
        "{\"type\":\"play_tone\",\"note\":\"E2\"}\n{\"type\":\"stop_tone\"}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(lines[0], r#"{"type":"ready"}"#);
    assert_eq!(
        lines[1],
        r#"{"type":"tone_started","note":"E2","frequency_hz":82.4068892282175}"#
    );
    assert_eq!(lines[2], r#"{"type":"tone_stopped"}"#);
}

#[test]
fn start_and_stop_metronome_work_without_real_audio_device_in_mock_mode() {
    let output = run_helper_with_input(
        "{\"type\":\"start_metronome\",\"bpm\":120}\n{\"type\":\"stop_metronome\"}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"metronome_started","bpm":120,"beats_per_bar":4,"beat_unit":4,"subdivision":1}"#.to_owned(),
            r#"{"type":"metronome_beat","beat_in_bar":1,"beats_per_bar":4,"beat_unit":4,"subdivision_step":1,"subdivision":1,"accented":true}"#
                .to_owned(),
            r#"{"type":"metronome_stopped"}"#.to_owned(),
        ]
    );
}

#[test]
fn restarting_metronome_with_a_new_bpm_restarts_on_the_downbeat() {
    let output = run_helper_with_input(
        "{\"type\":\"start_metronome\",\"bpm\":120}\n{\"type\":\"start_metronome\",\"bpm\":90}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"metronome_started","bpm":120,"beats_per_bar":4,"beat_unit":4,"subdivision":1}"#.to_owned(),
            r#"{"type":"metronome_beat","beat_in_bar":1,"beats_per_bar":4,"beat_unit":4,"subdivision_step":1,"subdivision":1,"accented":true}"#
                .to_owned(),
            r#"{"type":"metronome_started","bpm":90,"beats_per_bar":4,"beat_unit":4,"subdivision":1}"#.to_owned(),
            r#"{"type":"metronome_beat","beat_in_bar":1,"beats_per_bar":4,"beat_unit":4,"subdivision_step":1,"subdivision":1,"accented":true}"#
                .to_owned(),
        ]
    );
}

#[test]
fn metronome_start_can_echo_extended_meter_and_subdivision_state() {
    let output = run_helper_with_input(
        "{\"type\":\"start_metronome\",\"bpm\":96,\"beats_per_bar\":6,\"beat_unit\":8,\"subdivision\":3}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"metronome_started","bpm":96,"beats_per_bar":6,"beat_unit":8,"subdivision":3}"#.to_owned(),
            r#"{"type":"metronome_beat","beat_in_bar":1,"beats_per_bar":6,"beat_unit":8,"subdivision_step":1,"subdivision":3,"accented":true}"#
                .to_owned(),
        ]
    );
}

#[test]
fn interval_playback_reports_root_and_all_generated_voices() {
    let output = run_helper_with_input(
        "{\"type\":\"play_tone\",\"note\":\"A4\",\"intervals_semitones\":[12]}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":440.0,"intervals_semitones":[12],"voices":[{"note":"A4","frequency_hz":440.0},{"note":"A5","frequency_hz":880.0}]}"#.to_owned(),
        ]
    );
}

#[test]
fn chord_playback_reports_root_and_all_generated_voices() {
    let output = run_helper_with_input(
        "{\"type\":\"play_tone\",\"note\":\"A4\",\"intervals_semitones\":[4,7]}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":440.0,"intervals_semitones":[4,7],"voices":[{"note":"A4","frequency_hz":440.0},{"note":"C#5","frequency_hz":554.3652619537442},{"note":"E5","frequency_hz":659.2551138257398}]}"#.to_owned(),
        ]
    );
}

#[test]
fn runtime_output_failure_is_reported_without_crashing_helper() {
    let output = run_helper_with_input(
        "{\"type\":\"play_tone\",\"note\":\"A4\"}\n",
        Some("idle"),
        Some("unavailable"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"error","code":"audio_output_unavailable","message":"simulated audio output unavailable"}"#.to_owned(),
        ]
    );
}

#[test]
fn invalid_commands_do_not_crash_or_block_later_valid_commands() {
    let output = run_helper_with_input(
        "[]\n{\"type\":1}\n{\"type\":\"play_tone\",\"note\":\"H2\"}\n{\"type\":\"set_reference_a\",\"frequency_hz\":399.0}\n{\"type\":\"set_transposition\",\"semitones\":13}\n{\"type\":\"set_temperament\",\"offsets_cents\":[0,0,0]}\n{\"type\":\"start_metronome\",\"bpm\":301}\n{\"type\":\"start_metronome\",\"bpm\":120,\"beats_per_bar\":5,\"beat_unit\":4}\n{\"type\":\"start_metronome\",\"bpm\":120,\"subdivision\":5}\n{\"type\":\"play_tone\",\"note\":\"A4\"}\n{\"type\":\"stop_tone\"}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"error","code":"invalid_command","message":"invalid command: command must be a JSON object"}"#.to_owned(),
            r#"{"type":"error","code":"invalid_command","message":"invalid command: missing string field 'type'"}"#.to_owned(),
            r#"{"type":"error","code":"invalid_note","message":"invalid note: invalid note letter 'H'"}"#.to_owned(),
            r#"{"type":"error","code":"invalid_reference_frequency","message":"invalid reference A frequency: reference A frequency must be within 400.0..=480.0 Hz"}"#.to_owned(),
            r#"{"type":"error","code":"invalid_transposition","message":"invalid transposition: transposition must be within -12..=12 semitones"}"#.to_owned(),
            r#"{"type":"error","code":"invalid_temperament","message":"invalid temperament: temperament offsets must contain exactly 12 pitch classes"}"#.to_owned(),
            r#"{"type":"error","code":"invalid_metronome_bpm","message":"invalid metronome BPM: metronome BPM must be within 20..=300"}"#.to_owned(),
            r#"{"type":"error","code":"invalid_metronome_meter","message":"invalid metronome meter: supported metronome meters are 2/4, 3/4, 4/4, and 6/8"}"#.to_owned(),
            r#"{"type":"error","code":"invalid_metronome_subdivision","message":"invalid metronome subdivision: metronome subdivision must be within 1..=4"}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":440.0}"#.to_owned(),
            r#"{"type":"tone_stopped"}"#.to_owned(),
        ]
    );
}

#[test]
fn runtime_input_disconnect_is_reported_after_ready() {
    let output = run_helper_until_stdout_lines("", 2, Some("disconnect"), Some("ok"), &[]);
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"error","code":"audio_input_disconnected","message":"simulated microphone input disconnected"}"#.to_owned(),
        ]
    );
}

#[test]
fn helper_can_exit_after_ready_for_recovery_testing() {
    let output = run_helper_until_exit("", Some("exit:91"), Some("ok"), &[]);
    let lines = stdout_lines(&output);

    assert!(!output.status.success());
    assert_eq!(output.status.code(), Some(91));
    assert_eq!(lines, vec![r#"{"type":"ready"}"#.to_owned()]);
}

#[test]
fn simulated_pitch_is_emitted_after_ready() {
    let output = run_helper_until_stdout_lines("", 2, Some("pitch:A4"), Some("ok"), &[]);
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(lines[0], r#"{"type":"ready"}"#);
    assert_eq!(
        lines[1],
        r#"{"type":"pitch","note":"A4","frequency_hz":440.0,"cents":0.0,"confidence":1.0}"#
    );
}

#[test]
fn startup_reference_a_argument_calibrates_initial_pitch_and_tone() {
    let output = run_helper_until_stdout_lines(
        "{\"type\":\"play_tone\",\"note\":\"A4\"}\n",
        3,
        Some("pitch:A4"),
        Some("ok"),
        &["--reference-a-hz", "442.0"],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(lines[0], r#"{"type":"ready"}"#);
    assert_eq!(lines.len(), 3);
    assert!(lines[1..].contains(
        &r#"{"type":"pitch","note":"A4","frequency_hz":442.0,"cents":0.0,"confidence":1.0}"#
            .to_owned()
    ));
    assert!(lines[1..]
        .contains(&r#"{"type":"tone_started","note":"A4","frequency_hz":442.0}"#.to_owned()));
}

#[test]
fn startup_transposition_argument_relabels_initial_pitch_and_tone() {
    let output = run_helper_until_stdout_lines(
        "{\"type\":\"play_tone\",\"note\":\"B4\"}\n",
        3,
        Some("pitch:A4"),
        Some("ok"),
        &["--transposition-semitones", "2"],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(lines[0], r#"{"type":"ready"}"#);
    assert_eq!(lines.len(), 3);
    assert!(lines[1..].contains(
        &r#"{"type":"pitch","note":"B4","frequency_hz":440.0,"cents":0.0,"confidence":1.0}"#
            .to_owned()
    ));
    assert!(lines[1..]
        .contains(&r#"{"type":"tone_started","note":"B4","frequency_hz":440.0}"#.to_owned()));
}

#[test]
fn runtime_reference_a_update_restarts_active_tone_with_calibrated_frequency() {
    let output = run_helper_with_input(
        "{\"type\":\"play_tone\",\"note\":\"A4\"}\n{\"type\":\"set_reference_a\",\"frequency_hz\":442.0}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":440.0}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":442.0}"#.to_owned(),
        ]
    );
}

#[test]
fn runtime_transposition_update_relabels_active_tone_without_changing_frequency() {
    let output = run_helper_with_input(
        "{\"type\":\"play_tone\",\"note\":\"A4\"}\n{\"type\":\"set_transposition\",\"semitones\":2}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":440.0}"#.to_owned(),
            r#"{"type":"tone_started","note":"B4","frequency_hz":440.0}"#.to_owned(),
        ]
    );
}

#[test]
fn runtime_transposition_update_relabels_active_interval_scene_without_changing_frequencies() {
    let output = run_helper_with_input(
        "{\"type\":\"play_tone\",\"note\":\"A4\",\"intervals_semitones\":[12]}\n{\"type\":\"set_transposition\",\"semitones\":2}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":440.0,"intervals_semitones":[12],"voices":[{"note":"A4","frequency_hz":440.0},{"note":"A5","frequency_hz":880.0}]}"#.to_owned(),
            r#"{"type":"tone_started","note":"B4","frequency_hz":440.0,"intervals_semitones":[12],"voices":[{"note":"B4","frequency_hz":440.0},{"note":"B5","frequency_hz":880.0}]}"#.to_owned(),
        ]
    );
}

#[test]
fn startup_temperament_argument_calibrates_initial_pitch_and_tone() {
    let temperament = Temperament::from_offset_slice(&[
        10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    ])
    .unwrap();
    let c4 = "C4".parse::<Note>().unwrap();
    let c4_frequency_hz = temperament
        .frequency_hz_for_note(c4, DEFAULT_REFERENCE_A_HZ)
        .unwrap();
    let expected_pitch = UiMessage::Pitch {
        note: c4,
        frequency_hz: c4_frequency_hz,
        cents: 0.0,
        confidence: Some(1.0),
    }
    .to_json_line()
    .unwrap();
    let expected_tone = UiMessage::ToneStarted {
        note: c4,
        frequency_hz: c4_frequency_hz,
        intervals_semitones: Vec::new(),
        voices: Vec::new(),
    }
    .to_json_line()
    .unwrap();

    let output = run_helper_until_stdout_lines(
        "{\"type\":\"play_tone\",\"note\":\"C4\"}\n",
        3,
        Some("pitch:C4"),
        Some("ok"),
        &["--temperament-offsets-cents", "10,0,0,0,0,0,0,0,0,0,0,0"],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(lines[0], r#"{"type":"ready"}"#);
    assert_eq!(lines.len(), 3);
    assert!(lines[1..].contains(&expected_pitch));
    assert!(lines[1..].contains(&expected_tone));
}

#[test]
fn runtime_temperament_update_restarts_active_tone_with_tempered_frequency() {
    let c4 = "C4".parse::<Note>().unwrap();
    let equal_c4_frequency_hz = c4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap();
    let temperament = Temperament::from_offset_slice(&[
        10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    ])
    .unwrap();
    let tempered_c4_frequency_hz = temperament
        .frequency_hz_for_note(c4, DEFAULT_REFERENCE_A_HZ)
        .unwrap();

    let output = run_helper_with_input(
        "{\"type\":\"play_tone\",\"note\":\"C4\"}\n{\"type\":\"set_temperament\",\"offsets_cents\":[10,0,0,0,0,0,0,0,0,0,0,0]}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            UiMessage::ToneStarted {
                note: c4,
                frequency_hz: equal_c4_frequency_hz,
                intervals_semitones: Vec::new(),
                voices: Vec::new(),
            }
            .to_json_line()
            .unwrap(),
            UiMessage::ToneStarted {
                note: c4,
                frequency_hz: tempered_c4_frequency_hz,
                intervals_semitones: Vec::new(),
                voices: Vec::new(),
            }
            .to_json_line()
            .unwrap(),
        ]
    );
}

#[test]
fn runtime_reference_a_update_restarts_active_interval_scene_with_calibrated_frequencies() {
    let output = run_helper_with_input(
        "{\"type\":\"play_tone\",\"note\":\"A4\",\"intervals_semitones\":[12]}\n{\"type\":\"set_reference_a\",\"frequency_hz\":442.0}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":440.0,"intervals_semitones":[12],"voices":[{"note":"A4","frequency_hz":440.0},{"note":"A5","frequency_hz":880.0}]}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":442.0,"intervals_semitones":[12],"voices":[{"note":"A4","frequency_hz":442.0},{"note":"A5","frequency_hz":884.0}]}"#.to_owned(),
        ]
    );
}

#[test]
fn runtime_reference_a_update_restarts_active_chord_scene_with_calibrated_frequencies() {
    let output = run_helper_with_input(
        "{\"type\":\"play_tone\",\"note\":\"A4\",\"intervals_semitones\":[4,7]}\n{\"type\":\"set_reference_a\",\"frequency_hz\":442.0}\n",
        Some("idle"),
        Some("ok"),
        &[],
    );
    let lines = stdout_lines(&output);

    assert!(output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"ready"}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":440.0,"intervals_semitones":[4,7],"voices":[{"note":"A4","frequency_hz":440.0},{"note":"C#5","frequency_hz":554.3652619537442},{"note":"E5","frequency_hz":659.2551138257398}]}"#.to_owned(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":442.0,"intervals_semitones":[4,7],"voices":[{"note":"A4","frequency_hz":442.0},{"note":"C#5","frequency_hz":556.885104053534},{"note":"E5","frequency_hz":662.2517279794932}]}"#.to_owned(),
        ]
    );
}

#[test]
fn invalid_startup_reference_a_emits_error_before_ready() {
    let output =
        run_helper_with_input("", Some("idle"), Some("ok"), &["--reference-a-hz", "399.0"]);
    let lines = stdout_lines(&output);

    assert!(!output.status.success());
    assert_eq!(
        lines,
        vec![
            r#"{"type":"error","code":"invalid_reference_frequency","message":"invalid reference A frequency '399.0'"}"#.to_owned(),
        ]
    );
}

#[test]
fn invalid_startup_transposition_emits_error_before_ready() {
    let output = run_helper_with_input(
        "",
        Some("idle"),
        Some("ok"),
        &["--transposition-semitones", "13"],
    );
    let lines = stdout_lines(&output);

    assert!(!output.status.success());
    assert_eq!(
        lines,
        vec![r#"{"type":"error","code":"invalid_transposition","message":"invalid transposition '13'"}"#.to_owned(),]
    );
}
