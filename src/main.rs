use omatune::audio_input::{AudioInput, InputStartupError};
use omatune::audio_output::{ActiveTone, AudioOutput, OutputControlError};
use omatune::config::{
    parse_helper_cli, HelperCliAction, SharedConfig, StartupConfig, StartupConfigError,
    MAX_REFERENCE_A_HZ, MIN_REFERENCE_A_HZ,
};
use omatune::protocol::{parse_command, Command, ErrorCode, UiMessage};
use omatune::protocol_io::ProtocolWriter;
use std::io::{self, BufRead, Write};
use std::process::ExitCode;

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            let _ = writeln!(io::stderr(), "omatune-helper: {error}");
            ExitCode::FAILURE
        }
    }
}

fn run() -> io::Result<()> {
    match parse_helper_cli(std::env::args()) {
        Ok(HelperCliAction::PrintHelp) => {
            print_help();
            return Ok(());
        }
        Ok(HelperCliAction::PrintVersion) => {
            print_version();
            return Ok(());
        }
        Ok(HelperCliAction::Run(startup_config)) => run_helper(startup_config),
        Err(error) => {
            let protocol_writer = ProtocolWriter::new();
            Err(emit_startup_protocol_error(&protocol_writer, error))
        }
    }
}

fn run_helper(startup_config: StartupConfig) -> io::Result<()> {
    let protocol_writer = ProtocolWriter::new();
    let shared_config = SharedConfig::new(startup_config.reference_a_hz).map_err(|error| {
        emit_startup_error_message(
            &protocol_writer,
            ErrorCode::InvalidReferenceFrequency,
            error.to_string(),
        )
    })?;
    let audio_output = AudioOutput::new(protocol_writer.clone(), shared_config.clone())?;
    let mut audio_input = init_audio_input(&protocol_writer, shared_config.clone())?;

    protocol_writer.write_message(&UiMessage::Ready)?;
    audio_input.start();

    let stdin = io::stdin();

    for line in stdin.lock().lines() {
        let line = line?;
        let command_text = line.trim();
        if command_text.is_empty() {
            continue;
        }

        match parse_command(command_text) {
            Ok(command) => {
                handle_command(command, &audio_output, &protocol_writer, &shared_config)?
            }
            Err(error) => protocol_writer.write_message(&error.into_message())?,
        }
    }

    Ok(())
}

fn print_help() {
    println!(
        "Usage: omatune-helper [--reference-a-hz <hz>] [--help] [--version]\n\nStarts Omatune's NDJSON audio helper.\nReads commands from stdin, writes protocol messages to stdout, and writes diagnostics to stderr.\n\nOptions:\n  --reference-a-hz <hz>  Set startup calibration within {MIN_REFERENCE_A_HZ:.1}..={MAX_REFERENCE_A_HZ:.1} Hz\n  -h, --help             Print this help text and exit\n  -V, --version          Print helper version and exit"
    );
}

fn print_version() {
    println!("omatune-helper {}", env!("CARGO_PKG_VERSION"));
}

fn init_audio_input(
    protocol_writer: &ProtocolWriter,
    shared_config: SharedConfig,
) -> io::Result<AudioInput> {
    AudioInput::new(protocol_writer.clone(), shared_config)
        .map_err(|error| emit_startup_error(protocol_writer, error))
}

fn handle_command(
    command: Command,
    audio_output: &AudioOutput,
    protocol_writer: &ProtocolWriter,
    shared_config: &SharedConfig,
) -> io::Result<()> {
    match command {
        Command::PlayTone { note } => match audio_output.play(note) {
            Ok(frequency_hz) => {
                protocol_writer.write_message(&UiMessage::ToneStarted { note, frequency_hz })?
            }
            Err(error) => emit_control_error(protocol_writer, error)?,
        },
        Command::SetReferenceA { frequency_hz } => {
            shared_config
                .set_reference_a_hz(frequency_hz)
                .map_err(|error| {
                    emit_startup_error_message(
                        protocol_writer,
                        ErrorCode::InvalidReferenceFrequency,
                        error.to_string(),
                    )
                })?;

            match audio_output.refresh_reference_a() {
                Ok(Some(ActiveTone { note, frequency_hz })) => {
                    protocol_writer.write_message(&UiMessage::ToneStarted { note, frequency_hz })?
                }
                Ok(None) => {}
                Err(error) => emit_control_error(protocol_writer, error)?,
            }
        }
        Command::StopTone => match audio_output.stop() {
            Ok(()) => protocol_writer.write_message(&UiMessage::ToneStopped)?,
            Err(error) => emit_control_error(protocol_writer, error)?,
        },
    }

    Ok(())
}

fn emit_control_error(
    protocol_writer: &ProtocolWriter,
    error: OutputControlError,
) -> io::Result<()> {
    protocol_writer.write_message(&UiMessage::Error {
        code: error.code,
        message: error.message,
    })
}

fn emit_startup_error(protocol_writer: &ProtocolWriter, error: InputStartupError) -> io::Error {
    emit_startup_error_message(protocol_writer, error.code, error.message)
}

fn emit_startup_protocol_error(
    protocol_writer: &ProtocolWriter,
    error: StartupConfigError,
) -> io::Error {
    let code = match error {
        StartupConfigError::MissingValue(_) | StartupConfigError::InvalidReferenceFrequency(_) => {
            ErrorCode::InvalidReferenceFrequency
        }
        StartupConfigError::UnexpectedArgument(_) => ErrorCode::InvalidCommand,
    };

    emit_startup_error_message(protocol_writer, code, error.to_string())
}

fn emit_startup_error_message(
    protocol_writer: &ProtocolWriter,
    code: ErrorCode,
    message: String,
) -> io::Error {
    if let Err(write_error) = protocol_writer.write_message(&UiMessage::Error {
        code: code.clone(),
        message: message.clone(),
    }) {
        eprintln!("omatune-helper: failed to emit startup error: {write_error}");
    }

    io::Error::other(message)
}
