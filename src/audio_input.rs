use crate::note::Note;
use crate::note::DEFAULT_REFERENCE_A_HZ;
use crate::pitch_detection::{
    PitchDetector, DEFAULT_ANALYSIS_HOP_SAMPLES, DEFAULT_ANALYSIS_WINDOW_SAMPLES,
    DEFAULT_MAX_FREQUENCY_HZ, DEFAULT_MIN_FREQUENCY_HZ,
};
use crate::protocol::{ErrorCode, UiMessage};
use crate::protocol_io::ProtocolWriter;
use crate::reference_tone::DEFAULT_SAMPLE_RATE_HZ;
use libpulse_binding as pulse;
use libpulse_simple_binding as psimple;
use pulse::def::BufferAttr;
use pulse::sample::{Format, Spec};
use pulse::stream::Direction;
use std::env;
use std::sync::mpsc::{self, SyncSender};
use std::thread::{self, JoinHandle};
use std::time::Duration;

const INPUT_CHANNELS: u8 = 1;
const INPUT_CHUNK_SAMPLES: usize = 1_024;

pub struct AudioInput {
    start_tx: Option<SyncSender<()>>,
    _worker: JoinHandle<()>,
}

enum MockInputMode {
    Idle,
    NoSignal,
    Disconnect,
    Pitch(Note),
}

#[derive(Clone, Debug)]
pub struct InputStartupError {
    pub code: ErrorCode,
    pub message: String,
}

impl AudioInput {
    pub fn new(protocol_writer: ProtocolWriter) -> Result<Self, InputStartupError> {
        if let Some(mock_mode) = MockInputMode::from_env()? {
            return spawn_mock_input_worker(protocol_writer, mock_mode);
        }

        let sample_spec = Spec {
            format: Format::FLOAT32NE,
            rate: DEFAULT_SAMPLE_RATE_HZ,
            channels: INPUT_CHANNELS,
        };
        if !sample_spec.is_valid() {
            return Err(InputStartupError::unsupported_format(
                "microphone sample format is invalid for this system",
            ));
        }

        let fragment_bytes = (INPUT_CHUNK_SAMPLES * sample_spec.frame_size()) as u32;
        let buffer_attr = BufferAttr {
            maxlength: u32::MAX,
            tlength: u32::MAX,
            prebuf: u32::MAX,
            minreq: u32::MAX,
            fragsize: fragment_bytes,
        };

        let stream = psimple::Simple::new(
            None,
            "Omatune",
            Direction::Record,
            None,
            "Pitch Detection",
            &sample_spec,
            None,
            Some(&buffer_attr),
        )
        .map_err(|error| {
            InputStartupError::unavailable(format!("unable to open microphone input: {error}"))
        })?;

        let (start_tx, start_rx) = mpsc::sync_channel(1);

        let worker = thread::Builder::new()
            .name("omatune-audio-input".to_owned())
            .spawn(move || {
                if start_rx.recv().is_err() {
                    return;
                }
                input_worker_loop(stream, protocol_writer)
            })
            .map_err(|error| {
                InputStartupError::internal(format!("unable to start microphone worker: {error}"))
            })?;

        Ok(Self {
            start_tx: Some(start_tx),
            _worker: worker,
        })
    }

    pub fn start(&mut self) {
        if let Some(start_tx) = self.start_tx.take() {
            let _ = start_tx.send(());
        }
    }
}

impl InputStartupError {
    fn unavailable(message: impl Into<String>) -> Self {
        Self {
            code: ErrorCode::AudioInputUnavailable,
            message: message.into(),
        }
    }

    fn unsupported_format(message: impl Into<String>) -> Self {
        Self {
            code: ErrorCode::UnsupportedFormat,
            message: message.into(),
        }
    }

    fn internal(message: impl Into<String>) -> Self {
        Self {
            code: ErrorCode::InternalError,
            message: message.into(),
        }
    }
}

impl MockInputMode {
    fn from_env() -> Result<Option<Self>, InputStartupError> {
        let Some(raw_mode) = env::var("OMATUNE_TEST_INPUT_MODE").ok() else {
            return Ok(None);
        };

        let mode = raw_mode.trim();
        if mode == "idle" {
            return Ok(Some(Self::Idle));
        }
        if mode == "no_signal" {
            return Ok(Some(Self::NoSignal));
        }
        if mode == "disconnect" {
            return Ok(Some(Self::Disconnect));
        }
        if mode == "unavailable" {
            return Err(InputStartupError::unavailable(
                "simulated microphone input unavailable",
            ));
        }
        if let Some(note_text) = mode.strip_prefix("pitch:") {
            let note = note_text.parse::<Note>().map_err(|error| {
                InputStartupError::internal(format!(
                    "invalid OMATUNE_TEST_INPUT_MODE pitch note: {error}"
                ))
            })?;
            return Ok(Some(Self::Pitch(note)));
        }

        Err(InputStartupError::internal(format!(
            "unsupported OMATUNE_TEST_INPUT_MODE '{mode}'"
        )))
    }
}

fn spawn_mock_input_worker(
    protocol_writer: ProtocolWriter,
    mock_mode: MockInputMode,
) -> Result<AudioInput, InputStartupError> {
    let (start_tx, start_rx) = mpsc::sync_channel(1);
    let worker = thread::Builder::new()
        .name("omatune-audio-input-mock".to_owned())
        .spawn(move || {
            if start_rx.recv().is_err() {
                return;
            }
            input_mock_worker_loop(protocol_writer, mock_mode);
        })
        .map_err(|error| {
            InputStartupError::internal(format!("unable to start mock microphone worker: {error}"))
        })?;

    Ok(AudioInput {
        start_tx: Some(start_tx),
        _worker: worker,
    })
}

fn input_mock_worker_loop(protocol_writer: ProtocolWriter, mock_mode: MockInputMode) {
    match mock_mode {
        MockInputMode::Idle => park_until_process_exit(),
        MockInputMode::NoSignal => {
            if let Err(error) = protocol_writer.write_message(&UiMessage::NoSignal) {
                eprintln!("omatune-helper: failed to emit mock no-signal message: {error}");
            }
            park_until_process_exit();
        }
        MockInputMode::Disconnect => {
            thread::sleep(Duration::from_millis(75));
            emit_runtime_error(
                &protocol_writer,
                ErrorCode::AudioInputDisconnected,
                "simulated microphone input disconnected".to_owned(),
            );
        }
        MockInputMode::Pitch(note) => {
            let Ok(frequency_hz) = note.frequency_hz(DEFAULT_REFERENCE_A_HZ) else {
                emit_runtime_error(
                    &protocol_writer,
                    ErrorCode::InternalError,
                    "failed to calculate simulated pitch frequency".to_owned(),
                );
                return;
            };
            if let Err(error) = protocol_writer.write_message(&UiMessage::Pitch {
                note,
                frequency_hz,
                cents: 0.0,
                confidence: Some(1.0),
            }) {
                eprintln!("omatune-helper: failed to emit mock pitch message: {error}");
            }
            park_until_process_exit();
        }
    }
}

fn park_until_process_exit() {
    loop {
        thread::park_timeout(Duration::from_secs(60));
    }
}

fn input_worker_loop(stream: psimple::Simple, protocol_writer: ProtocolWriter) {
    let mut detector = PitchDetector::new(
        DEFAULT_SAMPLE_RATE_HZ,
        DEFAULT_MIN_FREQUENCY_HZ,
        DEFAULT_MAX_FREQUENCY_HZ,
    );
    let mut analysis_buffer = Vec::with_capacity(DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2);
    let mut byte_buffer = vec![0_u8; INPUT_CHUNK_SAMPLES * std::mem::size_of::<f32>()];
    let mut pending_samples = 0_usize;
    let mut last_had_pitch = None;

    loop {
        if let Err(error) = stream.read(&mut byte_buffer) {
            emit_runtime_error(
                &protocol_writer,
                ErrorCode::AudioInputDisconnected,
                format!("microphone input read failed: {error}"),
            );
            break;
        }

        analysis_buffer.extend(
            byte_buffer
                .chunks_exact(std::mem::size_of::<f32>())
                .map(|chunk| {
                    let bytes: [u8; std::mem::size_of::<f32>()] = chunk.try_into().unwrap();
                    f32::from_ne_bytes(bytes)
                }),
        );

        if analysis_buffer.len() > DEFAULT_ANALYSIS_WINDOW_SAMPLES {
            let excess = analysis_buffer.len() - DEFAULT_ANALYSIS_WINDOW_SAMPLES;
            analysis_buffer.drain(0..excess);
        }

        pending_samples += INPUT_CHUNK_SAMPLES;
        while pending_samples >= DEFAULT_ANALYSIS_HOP_SAMPLES {
            pending_samples -= DEFAULT_ANALYSIS_HOP_SAMPLES;

            let Some(estimate) = detector.detect_pitch(&analysis_buffer, DEFAULT_REFERENCE_A_HZ)
            else {
                if last_had_pitch != Some(false) {
                    if let Err(error) = protocol_writer.write_message(&UiMessage::NoSignal) {
                        eprintln!("omatune-helper: failed to emit no-signal message: {error}");
                    }
                    last_had_pitch = Some(false);
                }
                continue;
            };

            if let Err(error) = protocol_writer.write_message(&UiMessage::Pitch {
                note: estimate.note,
                frequency_hz: estimate.frequency_hz,
                cents: estimate.cents,
                confidence: Some(estimate.confidence),
            }) {
                eprintln!("omatune-helper: failed to emit pitch message: {error}");
            }
            last_had_pitch = Some(true);
        }
    }
}

fn emit_runtime_error(protocol_writer: &ProtocolWriter, code: ErrorCode, message: String) {
    if let Err(error) = protocol_writer.write_message(&UiMessage::Error { code, message }) {
        eprintln!("omatune-helper: failed to emit audio input error: {error}");
    }
}
