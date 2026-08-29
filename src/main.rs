use omatune::audio_input::{AudioInput, InputStartupError};
use omatune::audio_output::{AudioOutput, OutputControlError};
use omatune::protocol::{parse_command, Command, UiMessage};
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
    let audio_output = AudioOutput::new(protocol_writer.clone())?;
    let mut audio_input = init_audio_input(&protocol_writer)?;

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
            Ok(command) => handle_command(command, &audio_output, &protocol_writer)?,
            Err(error) => protocol_writer.write_message(&error.into_message())?,
        }
    }

    Ok(())
}

fn init_audio_input(protocol_writer: &ProtocolWriter) -> io::Result<AudioInput> {
    AudioInput::new(protocol_writer.clone())
        .map_err(|error| emit_startup_error(protocol_writer, error))
}

fn handle_command(
    command: Command,
    audio_output: &AudioOutput,
    protocol_writer: &ProtocolWriter,
) -> io::Result<()> {
    match command {
        Command::PlayTone { note } => match audio_output.play(note) {
            Ok(frequency_hz) => {
                protocol_writer.write_message(&UiMessage::ToneStarted { note, frequency_hz })?
            }
            Err(error) => emit_control_error(protocol_writer, error)?,
        },
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
    if let Err(write_error) = protocol_writer.write_message(&UiMessage::Error {
        code: error.code.clone(),
        message: error.message.clone(),
    }) {
        eprintln!("omatune-helper: failed to emit startup error: {write_error}");
    }

    io::Error::other(error.message)
}
