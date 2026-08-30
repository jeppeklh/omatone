use omatune::audio_input::{AudioInput, InputStartupError};
use omatune::audio_output::{AudioOutput, OutputControlError};
use omatune::config::{
    parse_helper_cli, HelperCliAction, SharedConfig, StartupConfig, StartupConfigError,
    MAX_REFERENCE_A_HZ, MIN_REFERENCE_A_HZ,
};
use omatune::note::{MAX_TRANSPOSITION_SEMITONES, MIN_TRANSPOSITION_SEMITONES};
use omatune::protocol::{parse_command, Command, ErrorCode, UiMessage};
use omatune::protocol_io::ProtocolWriter;
use omatune::tuning_library::{built_in_tuning_library, normalize_content_pack_json};
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
        Ok(HelperCliAction::DumpTuningLibrary) => {
            println!(
                "{}",
                serde_json::to_string(&built_in_tuning_library())
                    .map_err(|error| io::Error::other(error.to_string()))?
            );
            Ok(())
        }
        Ok(HelperCliAction::NormalizeContentPack { json }) => {
            let normalized_pack = normalize_content_pack_json(&json)
                .map_err(|error| io::Error::other(error.to_string()))?;
            println!(
                "{}",
                serde_json::to_string(&normalized_pack)
                    .map_err(|error| io::Error::other(error.to_string()))?
            );
            Ok(())
        }
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
            if error.is_tool_mode_error() {
                return Err(io::Error::other(error.to_string()));
            }
            let protocol_writer = ProtocolWriter::new();
            Err(emit_startup_protocol_error(&protocol_writer, error))
        }
    }
}

fn run_helper(startup_config: StartupConfig) -> io::Result<()> {
    let protocol_writer = ProtocolWriter::new();
    let shared_config = SharedConfig::new(startup_config);
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
        "Usage: omatune-helper [--reference-a-hz <hz>] [--transposition-semitones <n>] [--temperament-offsets-cents <csv>] [--help] [--version]\n       omatune-helper --dump-tuning-library\n       omatune-helper --normalize-content-pack <json>\n\nStarts Omatune's NDJSON audio helper.\nReads commands from stdin, writes protocol messages to stdout, and writes diagnostics to stderr.\n\nOptions:\n  --reference-a-hz <hz>          Set startup calibration within {MIN_REFERENCE_A_HZ:.1}..={MAX_REFERENCE_A_HZ:.1} Hz\n  --transposition-semitones <n>  Set startup transposition within {MIN_TRANSPOSITION_SEMITONES}..={MAX_TRANSPOSITION_SEMITONES} semitones\n  --temperament-offsets-cents    Set startup pitch-class offsets as 12 comma-separated cents values\n  --dump-tuning-library          Print the built-in temperament and preset library as JSON and exit\n  --normalize-content-pack <json>  Normalize one preset or temperament pack JSON object and exit\n  -h, --help                     Print this help text and exit\n  -V, --version                  Print helper version and exit"
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
        Command::PlayTone { scene } => match audio_output.play(scene) {
            Ok(active_tone) => protocol_writer.write_message(&UiMessage::ToneStarted {
                note: active_tone.note,
                frequency_hz: active_tone.frequency_hz,
                intervals_semitones: active_tone.intervals_semitones,
                voices: active_tone.voices,
            })?,
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

            match audio_output.refresh_tuning() {
                Ok(Some(active_tone)) => {
                    protocol_writer.write_message(&UiMessage::ToneStarted {
                        note: active_tone.note,
                        frequency_hz: active_tone.frequency_hz,
                        intervals_semitones: active_tone.intervals_semitones,
                        voices: active_tone.voices,
                    })?
                }
                Ok(None) => {}
                Err(error) => emit_control_error(protocol_writer, error)?,
            }
        }
        Command::SetTransposition { semitones } => {
            shared_config
                .set_transposition_semitones(semitones)
                .map_err(|error| {
                    emit_startup_error_message(
                        protocol_writer,
                        ErrorCode::InvalidTransposition,
                        error.to_string(),
                    )
                })?;

            match audio_output.refresh_tuning() {
                Ok(Some(active_tone)) => {
                    protocol_writer.write_message(&UiMessage::ToneStarted {
                        note: active_tone.note,
                        frequency_hz: active_tone.frequency_hz,
                        intervals_semitones: active_tone.intervals_semitones,
                        voices: active_tone.voices,
                    })?
                }
                Ok(None) => {}
                Err(error) => emit_control_error(protocol_writer, error)?,
            }
        }
        Command::SetTemperament { temperament } => {
            shared_config.set_temperament(temperament);

            match audio_output.refresh_tuning() {
                Ok(Some(active_tone)) => {
                    protocol_writer.write_message(&UiMessage::ToneStarted {
                        note: active_tone.note,
                        frequency_hz: active_tone.frequency_hz,
                        intervals_semitones: active_tone.intervals_semitones,
                        voices: active_tone.voices,
                    })?
                }
                Ok(None) => {}
                Err(error) => emit_control_error(protocol_writer, error)?,
            }
        }
        Command::StopTone => match audio_output.stop() {
            Ok(()) => protocol_writer.write_message(&UiMessage::ToneStopped)?,
            Err(error) => emit_control_error(protocol_writer, error)?,
        },
        Command::StartMetronome { state } => match audio_output.start_metronome(state) {
            Ok(state) => {
                protocol_writer.write_message(&UiMessage::MetronomeStarted {
                    bpm: state.bpm,
                    beats_per_bar: state.beats_per_bar,
                    beat_unit: state.beat_unit,
                    subdivision: state.subdivision,
                })?;
                let downbeat = state.downbeat();
                protocol_writer.write_message(&UiMessage::MetronomeBeat {
                    beat_in_bar: downbeat.beat_in_bar,
                    beats_per_bar: downbeat.beats_per_bar,
                    beat_unit: downbeat.beat_unit,
                    subdivision_step: downbeat.subdivision_step,
                    subdivision: downbeat.subdivision,
                    accented: downbeat.accented,
                })?
            }
            Err(error) => emit_control_error(protocol_writer, error)?,
        },
        Command::StopMetronome => match audio_output.stop_metronome() {
            Ok(()) => protocol_writer.write_message(&UiMessage::MetronomeStopped)?,
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
        StartupConfigError::InvalidTransposition(_) => ErrorCode::InvalidTransposition,
        StartupConfigError::InvalidTemperament(_) => ErrorCode::InvalidTemperament,
        StartupConfigError::UnexpectedArgument(_) => ErrorCode::InvalidCommand,
        StartupConfigError::ToolMissingValue(_) | StartupConfigError::ToolUnexpectedArgument(_) => {
            ErrorCode::InvalidCommand
        }
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
