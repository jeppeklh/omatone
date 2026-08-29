use std::io::Write;
use std::process::{Command, Output, Stdio};
use std::thread;
use std::time::Duration;

fn helper_bin() -> &'static str {
    env!("CARGO_BIN_EXE_omatune-helper")
}

fn run_helper_with_input(
    stdin_text: &str,
    input_mode: Option<&str>,
    output_mode: Option<&str>,
    args: &[&str],
) -> Output {
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

    let mut child = command.spawn().expect("failed to spawn helper");
    if !stdin_text.is_empty() {
        let mut stdin = child.stdin.take().expect("missing helper stdin");
        stdin
            .write_all(stdin_text.as_bytes())
            .expect("failed to write helper stdin");
    }
    drop(child.stdin.take());

    child.wait_with_output().expect("failed to wait for helper")
}

fn run_helper_with_delay_before_eof(
    delay: Duration,
    input_mode: Option<&str>,
    output_mode: Option<&str>,
    args: &[&str],
) -> Output {
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

    let mut child = command.spawn().expect("failed to spawn helper");
    let stdin = child.stdin.take().expect("missing helper stdin");
    thread::sleep(delay);
    drop(stdin);

    child.wait_with_output().expect("failed to wait for helper")
}

fn run_helper_with_input_and_delay_before_eof(
    stdin_text: &str,
    delay: Duration,
    input_mode: Option<&str>,
    output_mode: Option<&str>,
    args: &[&str],
) -> Output {
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

    let mut child = command.spawn().expect("failed to spawn helper");
    let mut stdin = child.stdin.take().expect("missing helper stdin");
    if !stdin_text.is_empty() {
        stdin
            .write_all(stdin_text.as_bytes())
            .expect("failed to write helper stdin");
    }
    thread::sleep(delay);
    drop(stdin);

    child.wait_with_output().expect("failed to wait for helper")
}

fn stdout_lines(output: &Output) -> Vec<String> {
    String::from_utf8(output.stdout.clone())
        .expect("stdout was not utf-8")
        .lines()
        .map(str::to_owned)
        .collect()
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
        let output = run_helper_with_delay_before_eof(
            Duration::from_millis(30),
            Some("no_signal"),
            Some("ok"),
            &[],
        );
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
fn runtime_input_disconnect_is_reported_after_ready() {
    let output = run_helper_with_delay_before_eof(
        Duration::from_millis(160),
        Some("disconnect"),
        Some("ok"),
        &[],
    );
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
fn simulated_pitch_is_emitted_after_ready() {
    let output = run_helper_with_delay_before_eof(
        Duration::from_millis(30),
        Some("pitch:A4"),
        Some("ok"),
        &[],
    );
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
    let output = run_helper_with_input_and_delay_before_eof(
        "{\"type\":\"play_tone\",\"note\":\"A4\"}\n",
        Duration::from_millis(30),
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
