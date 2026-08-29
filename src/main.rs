use omatune::audio_input::{AudioInput, InputStartupError};
use omatune::audio_output::{ActiveTone, AudioOutput, OutputControlError};
use omatune::config::{parse_startup_config, SharedConfig, StartupConfigError};
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
    let protocol_writer = ProtocolWriter::new();
    let startup_config = parse_startup_config(std::env::args())
        .map_err(|error| emit_startup_protocol_error(&protocol_writer, error))?;
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
