use crate::config::SharedConfig;
use crate::note::Note;
use crate::protocol::{ErrorCode, ToneVoice, UiMessage};
use crate::protocol_io::ProtocolWriter;
use crate::reference_tone::{
    ReferenceToneGenerator, ReferenceToneScene, ToneGeneratorError, DEFAULT_OUTPUT_LEVEL,
    DEFAULT_RAMP_DURATION_MS, DEFAULT_SAMPLE_RATE_HZ,
};
use libpulse_binding as pulse;
use libpulse_simple_binding as psimple;
use pulse::def::BufferAttr;
use pulse::sample::{Format, Spec};
use pulse::stream::Direction;
use std::env;
use std::io;
use std::sync::mpsc::{self, Receiver, Sender, SyncSender};
use std::sync::Mutex;
use std::thread::{self, JoinHandle};

const OUTPUT_CHANNELS: u8 = 2;
const CHUNK_FRAMES: usize = 240;
const OUTPUT_BUFFER_CHUNKS: u32 = 4;
const MAX_STOP_DRAIN_CHUNKS: usize = 8;

pub struct AudioOutput {
    inner: AudioOutputInner,
}

enum AudioOutputInner {
    Worker {
        command_tx: Sender<PlaybackCommand>,
        worker: Option<JoinHandle<()>>,
    },
    Mock(Mutex<MockPlayback>),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum MockAudioOutputMode {
    Ok,
    Unavailable,
    Disconnected,
}

struct MockPlayback {
    mode: MockAudioOutputMode,
    shared_config: SharedConfig,
    active_scene: Option<ReferenceToneScene>,
}

enum PlaybackCommand {
    Play {
        scene: ReferenceToneScene,
        reply: SyncSender<Result<ActiveTone, OutputControlError>>,
    },
    RefreshReferenceA {
        reply: SyncSender<Result<Option<ActiveTone>, OutputControlError>>,
    },
    Stop {
        reply: SyncSender<Result<(), OutputControlError>>,
    },
    Shutdown,
}

#[derive(Clone, Debug, PartialEq)]
pub struct ActiveTone {
    pub note: Note,
    pub frequency_hz: f64,
    pub intervals_semitones: Vec<i32>,
    pub voices: Vec<ToneVoice>,
}

#[derive(Clone, Debug)]
pub struct OutputControlError {
    pub code: ErrorCode,
    pub message: String,
}

impl AudioOutput {
    pub fn new(protocol_writer: ProtocolWriter, shared_config: SharedConfig) -> io::Result<Self> {
        if let Some(mode) = MockAudioOutputMode::from_env() {
            let _ = protocol_writer;
            return Ok(Self {
                inner: AudioOutputInner::Mock(Mutex::new(MockPlayback {
                    mode,
                    shared_config,
                    active_scene: None,
                })),
            });
        }

        let (command_tx, command_rx) = mpsc::channel();
        let worker = thread::Builder::new()
            .name("omatune-audio-output".to_owned())
            .spawn(move || output_worker_loop(command_rx, protocol_writer, shared_config))?;

        Ok(Self {
            inner: AudioOutputInner::Worker {
                command_tx,
                worker: Some(worker),
            },
        })
    }

    pub fn play(&self, scene: ReferenceToneScene) -> Result<ActiveTone, OutputControlError> {
        match &self.inner {
            AudioOutputInner::Worker { command_tx, .. } => {
                let (reply_tx, reply_rx) = mpsc::sync_channel(1);
                command_tx
                    .send(PlaybackCommand::Play {
                        scene,
                        reply: reply_tx,
                    })
                    .map_err(|_| {
                        OutputControlError::disconnected("audio output worker is unavailable")
                    })?;

                reply_rx.recv().map_err(|_| {
                    OutputControlError::disconnected("audio output worker did not respond")
                })?
            }
            AudioOutputInner::Mock(mock) => mock
                .lock()
                .unwrap_or_else(|poisoned| poisoned.into_inner())
                .play(scene),
        }
    }

    pub fn refresh_reference_a(&self) -> Result<Option<ActiveTone>, OutputControlError> {
        match &self.inner {
            AudioOutputInner::Worker { command_tx, .. } => {
                let (reply_tx, reply_rx) = mpsc::sync_channel(1);
                command_tx
                    .send(PlaybackCommand::RefreshReferenceA { reply: reply_tx })
                    .map_err(|_| {
                        OutputControlError::disconnected("audio output worker is unavailable")
                    })?;

                reply_rx.recv().map_err(|_| {
                    OutputControlError::disconnected("audio output worker did not respond")
                })?
            }
            AudioOutputInner::Mock(mock) => mock
                .lock()
                .unwrap_or_else(|poisoned| poisoned.into_inner())
                .refresh_reference_a(),
        }
    }

    pub fn stop(&self) -> Result<(), OutputControlError> {
        match &self.inner {
            AudioOutputInner::Worker { command_tx, .. } => {
                let (reply_tx, reply_rx) = mpsc::sync_channel(1);
                command_tx
                    .send(PlaybackCommand::Stop { reply: reply_tx })
                    .map_err(|_| {
                        OutputControlError::disconnected("audio output worker is unavailable")
                    })?;

                reply_rx.recv().map_err(|_| {
                    OutputControlError::disconnected("audio output worker did not respond")
                })?
            }
            AudioOutputInner::Mock(mock) => mock
                .lock()
                .unwrap_or_else(|poisoned| poisoned.into_inner())
                .stop(),
        }
    }
}

impl Drop for AudioOutput {
    fn drop(&mut self) {
        let AudioOutputInner::Worker { command_tx, worker } = &mut self.inner else {
            return;
        };

        let _ = command_tx.send(PlaybackCommand::Shutdown);
        if let Some(worker) = worker.take() {
            let _ = worker.join();
        }
    }
}

impl MockAudioOutputMode {
    fn from_env() -> Option<Self> {
        match env::var("OMATUNE_TEST_OUTPUT_MODE").ok()?.trim() {
            "ok" => Some(Self::Ok),
            "unavailable" => Some(Self::Unavailable),
            "disconnected" => Some(Self::Disconnected),
            _ => None,
        }
    }
}

impl MockPlayback {
    fn play(&mut self, scene: ReferenceToneScene) -> Result<ActiveTone, OutputControlError> {
        let active_tone = build_active_tone(&scene, self.shared_config.reference_a_hz())?;

        match self.mode {
            MockAudioOutputMode::Ok => {
                self.active_scene = Some(scene);
                Ok(active_tone)
            }
            MockAudioOutputMode::Unavailable => Err(OutputControlError::unavailable(
                "simulated audio output unavailable",
            )),
            MockAudioOutputMode::Disconnected => Err(OutputControlError::disconnected(
                "simulated audio output disconnected",
            )),
        }
    }

    fn refresh_reference_a(&mut self) -> Result<Option<ActiveTone>, OutputControlError> {
        let Some(scene) = self.active_scene.as_ref() else {
            return Ok(None);
        };
        let active_tone = build_active_tone(scene, self.shared_config.reference_a_hz())?;

        match self.mode {
            MockAudioOutputMode::Ok => Ok(Some(active_tone)),
            MockAudioOutputMode::Unavailable => Err(OutputControlError::unavailable(
                "simulated audio output unavailable",
            )),
            MockAudioOutputMode::Disconnected => Err(OutputControlError::disconnected(
                "simulated audio output disconnected",
            )),
        }
    }

    fn stop(&mut self) -> Result<(), OutputControlError> {
        self.active_scene = None;

        match self.mode {
            MockAudioOutputMode::Ok | MockAudioOutputMode::Unavailable => Ok(()),
            MockAudioOutputMode::Disconnected => Err(OutputControlError::disconnected(
                "simulated audio output disconnected",
            )),
        }
    }
}

impl OutputControlError {
    fn unavailable(message: impl Into<String>) -> Self {
        Self {
            code: ErrorCode::AudioOutputUnavailable,
            message: message.into(),
        }
    }

    fn disconnected(message: impl Into<String>) -> Self {
        Self {
            code: ErrorCode::AudioOutputDisconnected,
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

struct PulsePlayback {
    stream: Option<psimple::Simple>,
    sample_spec: Spec,
    buffer_attr: BufferAttr,
    shared_config: SharedConfig,
    generator: ReferenceToneGenerator,
    active_scene: Option<ReferenceToneScene>,
    sample_buffer: Vec<f32>,
    byte_buffer: Vec<u8>,
}

impl PulsePlayback {
    fn new(shared_config: SharedConfig) -> Result<Self, OutputControlError> {
        let sample_spec = Spec {
            format: Format::FLOAT32NE,
            rate: DEFAULT_SAMPLE_RATE_HZ,
            channels: OUTPUT_CHANNELS,
        };

        if !sample_spec.is_valid() {
            return Err(OutputControlError::unsupported_format(
                "reference-tone sample format is invalid for this system",
            ));
        }

        let chunk_bytes = (CHUNK_FRAMES * sample_spec.frame_size()) as u32;
        let buffer_attr = BufferAttr {
            maxlength: u32::MAX,
            tlength: chunk_bytes.saturating_mul(OUTPUT_BUFFER_CHUNKS),
            prebuf: chunk_bytes,
            minreq: chunk_bytes,
            fragsize: u32::MAX,
        };

        Ok(Self {
            stream: None,
            sample_spec,
            buffer_attr,
            shared_config,
            generator: ReferenceToneGenerator::new(
                DEFAULT_SAMPLE_RATE_HZ,
                DEFAULT_OUTPUT_LEVEL,
                DEFAULT_RAMP_DURATION_MS,
            ),
            active_scene: None,
            sample_buffer: vec![0.0; CHUNK_FRAMES * OUTPUT_CHANNELS as usize],
            byte_buffer: Vec::with_capacity(
                CHUNK_FRAMES * OUTPUT_CHANNELS as usize * std::mem::size_of::<f32>(),
            ),
        })
    }

    fn play(&mut self, scene: ReferenceToneScene) -> Result<ActiveTone, OutputControlError> {
        let active_tone = build_active_tone(&scene, self.shared_config.reference_a_hz())?;

        self.ensure_stream()?;
        self.generator
            .play_notes(&generator_voices(&active_tone))
            .map_err(|ToneGeneratorError::InvalidFrequency| {
                OutputControlError::internal(
                    "reference-tone generator rejected a valid note frequency",
                )
            })?;
        self.active_scene = Some(scene);

        Ok(active_tone)
    }

    fn refresh_reference_a(&mut self) -> Result<Option<ActiveTone>, OutputControlError> {
        let Some(scene) = self.active_scene.as_ref() else {
            return Ok(None);
        };
        let active_tone = build_active_tone(scene, self.shared_config.reference_a_hz())?;

        self.ensure_stream()?;
        self.generator
            .play_notes(&generator_voices(&active_tone))
            .map_err(|ToneGeneratorError::InvalidFrequency| {
                OutputControlError::internal(
                    "reference-tone generator rejected a valid note frequency",
                )
            })?;

        Ok(Some(active_tone))
    }

    fn stop(&mut self) -> Result<(), OutputControlError> {
        self.active_scene = None;
        self.generator.stop();

        if self.stream.is_some() {
            for _ in 0..MAX_STOP_DRAIN_CHUNKS {
                if !self.generator.is_audible() {
                    break;
                }
                self.render_chunk()?;
            }
        }

        Ok(())
    }

    fn is_idle(&self) -> bool {
        self.generator.is_idle()
    }

    fn render_chunk(&mut self) -> Result<(), OutputControlError> {
        let Some(stream) = self.stream.as_ref() else {
            return Ok(());
        };

        self.generator
            .render_interleaved(OUTPUT_CHANNELS as usize, &mut self.sample_buffer);
        self.byte_buffer.clear();

        for sample in &self.sample_buffer {
            self.byte_buffer.extend_from_slice(&sample.to_ne_bytes());
        }

        stream.write(&self.byte_buffer).map_err(|error| {
            OutputControlError::disconnected(format!("audio output write failed: {error}"))
        })
    }

    fn handle_runtime_error(&mut self) {
        self.stream = None;
        self.active_scene = None;
        self.generator.silence_immediately();
    }

    fn ensure_stream(&mut self) -> Result<(), OutputControlError> {
        if self.stream.is_some() {
            return Ok(());
        }

        let stream = psimple::Simple::new(
            None,
            "Omatune",
            Direction::Playback,
            None,
            "Reference Tone",
            &self.sample_spec,
            None,
            Some(&self.buffer_attr),
        )
        .map_err(|error| {
            OutputControlError::unavailable(format!("unable to open audio output: {error}"))
        })?;

        self.stream = Some(stream);
        Ok(())
    }
}

fn output_worker_loop(
    command_rx: Receiver<PlaybackCommand>,
    protocol_writer: ProtocolWriter,
    shared_config: SharedConfig,
) {
    let mut playback = match PulsePlayback::new(shared_config) {
        Ok(playback) => playback,
        Err(error) => {
            emit_output_error(&protocol_writer, error);
            return;
        }
    };

    loop {
        if playback.is_idle() {
            match command_rx.recv() {
                Ok(command) => {
                    if !handle_command(&mut playback, command) {
                        break;
                    }
                }
                Err(_) => break,
            }
            continue;
        }

        while let Ok(command) = command_rx.try_recv() {
            if !handle_command(&mut playback, command) {
                return;
            }
        }

        if let Err(error) = playback.render_chunk() {
            playback.handle_runtime_error();
            emit_output_error(&protocol_writer, error);
        }
    }
}

fn handle_command(playback: &mut PulsePlayback, command: PlaybackCommand) -> bool {
    match command {
        PlaybackCommand::Play { scene, reply } => {
            let _ = reply.send(playback.play(scene));
            true
        }
        PlaybackCommand::RefreshReferenceA { reply } => {
            let _ = reply.send(playback.refresh_reference_a());
            true
        }
        PlaybackCommand::Stop { reply } => {
            let _ = reply.send(playback.stop());
            true
        }
        PlaybackCommand::Shutdown => {
            let _ = playback.stop();
            false
        }
    }
}

fn build_active_tone(
    scene: &ReferenceToneScene,
    reference_a_hz: f64,
) -> Result<ActiveTone, OutputControlError> {
    let mut rendered_voices = Vec::with_capacity(1 + scene.intervals_semitones().len());

    for note in scene.notes() {
        let frequency_hz = note.frequency_hz(reference_a_hz).map_err(|error| {
            OutputControlError::internal(format!("failed to calculate tone frequency: {error}"))
        })?;
        rendered_voices.push(ToneVoice { note, frequency_hz });
    }

    let root_voice = rendered_voices
        .first()
        .cloned()
        .expect("reference tone scene should always include a root note");
    let protocol_voices = if scene.intervals_semitones().is_empty() {
        Vec::new()
    } else {
        rendered_voices
    };

    Ok(ActiveTone {
        note: root_voice.note,
        frequency_hz: root_voice.frequency_hz,
        intervals_semitones: scene.intervals_semitones().to_vec(),
        voices: protocol_voices,
    })
}

fn generator_voices(active_tone: &ActiveTone) -> Vec<(Note, f64)> {
    if active_tone.voices.is_empty() {
        return vec![(active_tone.note, active_tone.frequency_hz)];
    }

    active_tone
        .voices
        .iter()
        .map(|voice| (voice.note, voice.frequency_hz))
        .collect()
}

fn emit_output_error(protocol_writer: &ProtocolWriter, error: OutputControlError) {
    if let Err(write_error) = protocol_writer.write_message(&UiMessage::Error {
        code: error.code,
        message: error.message,
    }) {
        eprintln!("omatune-helper: failed to emit audio output error: {write_error}");
    }
}
