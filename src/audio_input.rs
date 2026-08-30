use crate::config::SharedConfig;
use crate::note::Note;
use crate::pitch_detection::{
    PitchDetector, DEFAULT_ANALYSIS_HOP_SAMPLES, DEFAULT_ANALYSIS_WINDOW_SAMPLES,
    DEFAULT_MAX_FREQUENCY_HZ, DEFAULT_MIN_FREQUENCY_HZ,
};
use crate::protocol::{ErrorCode, PitchAnalysis, UiMessage};
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
    ExitProcess(i32),
    Pitch(Note),
}

#[derive(Clone, Debug)]
pub struct InputStartupError {
    pub code: ErrorCode,
    pub message: String,
}

impl AudioInput {
    pub fn new(
        protocol_writer: ProtocolWriter,
        shared_config: SharedConfig,
    ) -> Result<Self, InputStartupError> {
        if let Some(mock_mode) = MockInputMode::from_env()? {
            return spawn_mock_input_worker(protocol_writer, shared_config, mock_mode);
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
                input_worker_loop(stream, protocol_writer, shared_config)
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
        if let Some(code_text) = mode.strip_prefix("exit:") {
            let code = code_text.parse::<i32>().map_err(|_| {
                InputStartupError::internal(format!(
                    "invalid OMATUNE_TEST_INPUT_MODE exit code '{code_text}'"
                ))
            })?;
            if !(0..=255).contains(&code) {
                return Err(InputStartupError::internal(format!(
                    "OMATUNE_TEST_INPUT_MODE exit code must be within 0..=255, got {code}"
                )));
            }
            return Ok(Some(Self::ExitProcess(code)));
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
    shared_config: SharedConfig,
    mock_mode: MockInputMode,
) -> Result<AudioInput, InputStartupError> {
    let (start_tx, start_rx) = mpsc::sync_channel(1);
    let worker = thread::Builder::new()
        .name("omatune-audio-input-mock".to_owned())
        .spawn(move || {
            if start_rx.recv().is_err() {
                return;
            }
            input_mock_worker_loop(protocol_writer, shared_config, mock_mode);
        })
        .map_err(|error| {
            InputStartupError::internal(format!("unable to start mock microphone worker: {error}"))
        })?;

    Ok(AudioInput {
        start_tx: Some(start_tx),
        _worker: worker,
    })
}

fn input_mock_worker_loop(
    protocol_writer: ProtocolWriter,
    shared_config: SharedConfig,
    mock_mode: MockInputMode,
) {
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
        MockInputMode::ExitProcess(code) => {
            thread::sleep(Duration::from_millis(75));
            std::process::exit(code);
        }
        MockInputMode::Pitch(note) => {
            let tuning_model = shared_config.tuning_model();
            let Ok(frequency_hz) = tuning_model.frequency_hz_for_sounding_note(note) else {
                emit_runtime_error(
                    &protocol_writer,
                    ErrorCode::InternalError,
                    "failed to calculate simulated pitch frequency".to_owned(),
                );
                return;
            };
            let Ok(nearest) = tuning_model.nearest_displayed_note_for_frequency(frequency_hz)
            else {
                emit_runtime_error(
                    &protocol_writer,
                    ErrorCode::InternalError,
                    "failed to map simulated pitch through the active tuning model".to_owned(),
                );
                return;
            };
            if let Err(error) = protocol_writer.write_message(&UiMessage::Pitch {
                note: nearest.note,
                frequency_hz,
                cents: nearest.cents,
                confidence: Some(1.0),
                analysis: Some(PitchAnalysis {
                    history_cents: vec![nearest.cents],
                    history_span_cents: 0.0,
                    held: false,
                }),
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

fn input_worker_loop(
    stream: psimple::Simple,
    protocol_writer: ProtocolWriter,
    shared_config: SharedConfig,
) {
    let mut detector = PitchDetector::new(
        DEFAULT_SAMPLE_RATE_HZ,
        DEFAULT_MIN_FREQUENCY_HZ,
        DEFAULT_MAX_FREQUENCY_HZ,
    );
    let mut analysis_buffer = vec![0.0_f32; DEFAULT_ANALYSIS_WINDOW_SAMPLES];
    let mut byte_buffer = vec![0_u8; INPUT_CHUNK_SAMPLES * std::mem::size_of::<f32>()];
    let mut chunk_samples = [0.0_f32; INPUT_CHUNK_SAMPLES];
    let mut filled_samples = 0_usize;
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

        for (sample, chunk) in chunk_samples
            .iter_mut()
            .zip(byte_buffer.chunks_exact(std::mem::size_of::<f32>()))
        {
            let bytes: [u8; std::mem::size_of::<f32>()] = chunk.try_into().unwrap();
            *sample = f32::from_ne_bytes(bytes);
        }

        let had_full_window = filled_samples == DEFAULT_ANALYSIS_WINDOW_SAMPLES;
        append_analysis_samples(&mut analysis_buffer, &mut filled_samples, &chunk_samples);

        if filled_samples < DEFAULT_ANALYSIS_WINDOW_SAMPLES {
            continue;
        }

        if !had_full_window {
            pending_samples = 0;
            emit_detector_update(
                &mut detector,
                &analysis_buffer,
                &shared_config,
                &protocol_writer,
                &mut last_had_pitch,
            );
            continue;
        }

        pending_samples += INPUT_CHUNK_SAMPLES;
        while pending_samples >= DEFAULT_ANALYSIS_HOP_SAMPLES {
            pending_samples -= DEFAULT_ANALYSIS_HOP_SAMPLES;
            emit_detector_update(
                &mut detector,
                &analysis_buffer,
                &shared_config,
                &protocol_writer,
                &mut last_had_pitch,
            );
        }
    }
}

fn append_analysis_samples(window: &mut [f32], filled_samples: &mut usize, samples: &[f32]) {
    debug_assert!(samples.len() <= window.len());
    let window_len = window.len();

    if *filled_samples < window_len {
        let samples_to_fill = (window_len - *filled_samples).min(samples.len());
        window[*filled_samples..(*filled_samples + samples_to_fill)]
            .copy_from_slice(&samples[..samples_to_fill]);
        *filled_samples += samples_to_fill;

        if samples_to_fill == samples.len() {
            return;
        }

        let remaining_samples = &samples[samples_to_fill..];
        window.copy_within(remaining_samples.len().., 0);
        window[window_len - remaining_samples.len()..].copy_from_slice(remaining_samples);
        *filled_samples = window_len;
        return;
    }

    window.copy_within(samples.len().., 0);
    window[window_len - samples.len()..].copy_from_slice(samples);
}

fn emit_detector_update(
    detector: &mut PitchDetector,
    analysis_buffer: &[f32],
    shared_config: &SharedConfig,
    protocol_writer: &ProtocolWriter,
    last_had_pitch: &mut Option<bool>,
) {
    let tuning_model = shared_config.tuning_model();

    let Some(pitch_frame) = detector.analyze_frame(analysis_buffer, tuning_model) else {
        if *last_had_pitch != Some(false) {
            if let Err(error) = protocol_writer.write_message(&UiMessage::NoSignal) {
                eprintln!("omatune-helper: failed to emit no-signal message: {error}");
            }
            *last_had_pitch = Some(false);
        }
        return;
    };

    if let Err(error) = protocol_writer.write_message(&UiMessage::Pitch {
        note: pitch_frame.estimate.note,
        frequency_hz: pitch_frame.estimate.frequency_hz,
        cents: pitch_frame.estimate.cents,
        confidence: pitch_frame.detector_confidence,
        analysis: Some(PitchAnalysis {
            history_cents: pitch_frame.analysis.history_cents,
            history_span_cents: pitch_frame.analysis.history_span_cents,
            held: pitch_frame.analysis.held,
        }),
    }) {
        eprintln!("omatune-helper: failed to emit pitch message: {error}");
    }
    *last_had_pitch = Some(true);
}

fn emit_runtime_error(protocol_writer: &ProtocolWriter, code: ErrorCode, message: String) {
    if let Err(error) = protocol_writer.write_message(&UiMessage::Error { code, message }) {
        eprintln!("omatune-helper: failed to emit audio input error: {error}");
    }
}
