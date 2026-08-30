use crate::config::SharedConfig;
use crate::metronome::{ActiveMetronome, MetronomeBeat, MetronomeStartError, MetronomeState};
use crate::note::{Note, PitchMathError, TuningModel};
use crate::protocol::{ErrorCode, ToneVoice, UiMessage};
use crate::protocol_io::ProtocolWriter;
use crate::reference_tone::{
    ReferenceToneScene, ReferenceToneSceneError, ReferenceToneSceneId, ReferenceToneVoice,
    ReferenceToneWaveformId, ToneGeneratorError, DEFAULT_OUTPUT_LEVEL, DEFAULT_RAMP_DURATION_MS,
    DEFAULT_SAMPLE_RATE_HZ,
};
use crate::shared_audio::SharedAudioMixer;
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
const MAX_SHUTDOWN_DRAIN_CHUNKS: usize = 8;

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
    active_metronome: Option<MetronomeState>,
}

enum PlaybackCommand {
    Play {
        scene: ReferenceToneScene,
        reply: SyncSender<Result<ActiveTone, OutputControlError>>,
    },
    RefreshTuning {
        reply: SyncSender<Result<Option<ActiveTone>, OutputControlError>>,
    },
    PreviewTuning {
        tuning_model: TuningModel,
        reply: SyncSender<Result<Option<ActiveTone>, OutputControlError>>,
    },
    Stop {
        reply: SyncSender<Result<(), OutputControlError>>,
    },
    StartMetronome {
        state: MetronomeState,
        reply: SyncSender<Result<MetronomeState, OutputControlError>>,
    },
    StopMetronome {
        reply: SyncSender<Result<(), OutputControlError>>,
    },
    Shutdown,
}

#[derive(Clone, Debug, PartialEq)]
pub struct ActiveTone {
    pub note: Note,
    pub frequency_hz: f64,
    pub scene_id: ReferenceToneSceneId,
    pub waveform_id: ReferenceToneWaveformId,
    pub intervals_semitones: Vec<i32>,
    pub voices: Vec<ToneVoice>,
    generator_voices: Vec<ReferenceToneVoice>,
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
                    active_metronome: None,
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

    pub fn refresh_tuning(&self) -> Result<Option<ActiveTone>, OutputControlError> {
        match &self.inner {
            AudioOutputInner::Worker { command_tx, .. } => {
                let (reply_tx, reply_rx) = mpsc::sync_channel(1);
                command_tx
                    .send(PlaybackCommand::RefreshTuning { reply: reply_tx })
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
                .refresh_tuning(),
        }
    }

    pub fn preview_tuning(
        &self,
        tuning_model: TuningModel,
    ) -> Result<Option<ActiveTone>, OutputControlError> {
        match &self.inner {
            AudioOutputInner::Worker { command_tx, .. } => {
                let (reply_tx, reply_rx) = mpsc::sync_channel(1);
                command_tx
                    .send(PlaybackCommand::PreviewTuning {
                        tuning_model,
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
                .preview_tuning(tuning_model),
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

    pub fn start_metronome(
        &self,
        state: MetronomeState,
    ) -> Result<MetronomeState, OutputControlError> {
        match &self.inner {
            AudioOutputInner::Worker { command_tx, .. } => {
                let (reply_tx, reply_rx) = mpsc::sync_channel(1);
                command_tx
                    .send(PlaybackCommand::StartMetronome {
                        state,
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
                .start_metronome(state),
        }
    }

    pub fn stop_metronome(&self) -> Result<(), OutputControlError> {
        match &self.inner {
            AudioOutputInner::Worker { command_tx, .. } => {
                let (reply_tx, reply_rx) = mpsc::sync_channel(1);
                command_tx
                    .send(PlaybackCommand::StopMetronome { reply: reply_tx })
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
                .stop_metronome(),
        }
    }
}

impl ActiveTone {
    fn generator_voices(&self) -> &[ReferenceToneVoice] {
        &self.generator_voices
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
        let tuning_model = self.shared_config.tuning_model();
        let sounding_scene = resolve_sounding_scene(&scene, tuning_model)?;
        let active_tone = build_active_tone(&sounding_scene, tuning_model)?;

        match self.mode {
            MockAudioOutputMode::Ok => {
                self.active_scene = Some(sounding_scene);
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

    fn refresh_tuning(&mut self) -> Result<Option<ActiveTone>, OutputControlError> {
        let Some(scene) = self.active_scene.as_ref() else {
            return Ok(None);
        };
        let active_tone = build_active_tone(scene, self.shared_config.tuning_model())?;

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

    fn preview_tuning(
        &mut self,
        tuning_model: TuningModel,
    ) -> Result<Option<ActiveTone>, OutputControlError> {
        let Some(scene) = self.active_scene.as_ref() else {
            return Ok(None);
        };

        build_active_tone(scene, tuning_model).map(Some)
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

    fn start_metronome(
        &mut self,
        state: MetronomeState,
    ) -> Result<MetronomeState, OutputControlError> {
        match self.mode {
            MockAudioOutputMode::Ok => {
                self.active_metronome = Some(state);
                Ok(state)
            }
            MockAudioOutputMode::Unavailable => Err(OutputControlError::unavailable(
                "simulated audio output unavailable",
            )),
            MockAudioOutputMode::Disconnected => Err(OutputControlError::disconnected(
                "simulated audio output disconnected",
            )),
        }
    }

    fn stop_metronome(&mut self) -> Result<(), OutputControlError> {
        self.active_metronome = None;

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

    fn invalid_transposition(message: impl Into<String>) -> Self {
        Self {
            code: ErrorCode::InvalidTransposition,
            message: message.into(),
        }
    }
}

struct PulsePlayback {
    stream: Option<psimple::Simple>,
    sample_spec: Spec,
    buffer_attr: BufferAttr,
    shared_config: SharedConfig,
    mixer: SharedAudioMixer,
    active_scene: Option<ReferenceToneScene>,
    active_metronome: Option<ActiveMetronome>,
    mono_buffer: Vec<f32>,
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
            mixer: SharedAudioMixer::new(
                DEFAULT_SAMPLE_RATE_HZ,
                DEFAULT_OUTPUT_LEVEL,
                DEFAULT_RAMP_DURATION_MS,
            ),
            active_scene: None,
            active_metronome: None,
            mono_buffer: vec![0.0; CHUNK_FRAMES],
            sample_buffer: vec![0.0; CHUNK_FRAMES * OUTPUT_CHANNELS as usize],
            byte_buffer: Vec::with_capacity(
                CHUNK_FRAMES * OUTPUT_CHANNELS as usize * std::mem::size_of::<f32>(),
            ),
        })
    }

    fn play(&mut self, scene: ReferenceToneScene) -> Result<ActiveTone, OutputControlError> {
        let tuning_model = self.shared_config.tuning_model();
        let sounding_scene = resolve_sounding_scene(&scene, tuning_model)?;
        let active_tone = build_active_tone(&sounding_scene, tuning_model)?;

        self.ensure_stream()?;
        self.mixer
            .play_reference_voices(active_tone.generator_voices())
            .map_err(|ToneGeneratorError::InvalidFrequency| {
                OutputControlError::internal(
                    "reference-tone generator rejected a valid note frequency",
                )
            })?;
        self.active_scene = Some(sounding_scene);

        Ok(active_tone)
    }

    fn refresh_tuning(&mut self) -> Result<Option<ActiveTone>, OutputControlError> {
        let Some(scene) = self.active_scene.as_ref() else {
            return Ok(None);
        };
        let active_tone = build_active_tone(scene, self.shared_config.tuning_model())?;

        self.ensure_stream()?;
        self.mixer
            .play_reference_voices(active_tone.generator_voices())
            .map_err(|ToneGeneratorError::InvalidFrequency| {
                OutputControlError::internal(
                    "reference-tone generator rejected a valid note frequency",
                )
            })?;

        Ok(Some(active_tone))
    }

    fn preview_tuning(
        &mut self,
        tuning_model: TuningModel,
    ) -> Result<Option<ActiveTone>, OutputControlError> {
        let Some(scene) = self.active_scene.as_ref() else {
            return Ok(None);
        };

        build_active_tone(scene, tuning_model).map(Some)
    }

    fn stop(&mut self) -> Result<(), OutputControlError> {
        self.active_scene = None;
        self.mixer.stop_reference_notes();

        Ok(())
    }

    fn start_metronome(
        &mut self,
        state: MetronomeState,
    ) -> Result<MetronomeState, OutputControlError> {
        self.ensure_stream()?;
        self.mixer.clear_timed_pulses();

        let (metronome, _downbeat) =
            ActiveMetronome::start(DEFAULT_SAMPLE_RATE_HZ, state, &mut self.mixer)
                .map_err(map_metronome_start_error)?;
        let state = metronome.state();
        self.active_metronome = Some(metronome);

        Ok(state)
    }

    fn stop_metronome(&mut self) -> Result<(), OutputControlError> {
        self.active_metronome = None;
        self.mixer.clear_timed_pulses();

        Ok(())
    }

    fn shutdown(&mut self) {
        self.active_scene = None;
        self.active_metronome = None;
        self.mixer.clear_timed_pulses();
        self.mixer.stop_reference_notes();

        if self.stream.is_some() {
            for _ in 0..MAX_SHUTDOWN_DRAIN_CHUNKS {
                if !self.mixer.reference_tone_is_audible() {
                    break;
                }
                if self.render_chunk().is_err() {
                    break;
                }
            }
        }

        self.mixer.silence_immediately();
    }

    fn is_idle(&self) -> bool {
        self.active_metronome.is_none() && self.mixer.is_idle()
    }

    fn render_chunk(&mut self) -> Result<Vec<MetronomeBeat>, OutputControlError> {
        let Some(stream) = self.stream.as_ref() else {
            return Ok(Vec::new());
        };

        let beat_events = if let Some(metronome) = &mut self.active_metronome {
            metronome
                .schedule_chunk(&mut self.mixer, CHUNK_FRAMES)
                .map_err(|ToneGeneratorError::InvalidFrequency| {
                    OutputControlError::internal(
                        "metronome click generator rejected a built-in click frequency",
                    )
                })?
        } else {
            Vec::new()
        };

        self.mixer.render_mono(&mut self.mono_buffer);

        for (frame, sample) in self
            .sample_buffer
            .chunks_exact_mut(OUTPUT_CHANNELS as usize)
            .zip(&self.mono_buffer)
        {
            for channel in frame {
                *channel = *sample;
            }
        }

        self.byte_buffer.clear();

        for sample in &self.sample_buffer {
            self.byte_buffer.extend_from_slice(&sample.to_ne_bytes());
        }

        stream.write(&self.byte_buffer).map_err(|error| {
            OutputControlError::disconnected(format!("audio output write failed: {error}"))
        })?;

        Ok(beat_events)
    }

    fn handle_runtime_error(&mut self) {
        self.stream = None;
        self.active_scene = None;
        self.active_metronome = None;
        self.mixer.silence_immediately();
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

        match playback.render_chunk() {
            Ok(beat_events) => emit_metronome_beats(&protocol_writer, &beat_events),
            Err(error) => {
                playback.handle_runtime_error();
                emit_output_error(&protocol_writer, error);
            }
        }
    }
}

fn handle_command(playback: &mut PulsePlayback, command: PlaybackCommand) -> bool {
    match command {
        PlaybackCommand::Play { scene, reply } => {
            let _ = reply.send(playback.play(scene));
            true
        }
        PlaybackCommand::RefreshTuning { reply } => {
            let _ = reply.send(playback.refresh_tuning());
            true
        }
        PlaybackCommand::PreviewTuning {
            tuning_model,
            reply,
        } => {
            let _ = reply.send(playback.preview_tuning(tuning_model));
            true
        }
        PlaybackCommand::Stop { reply } => {
            let _ = reply.send(playback.stop());
            true
        }
        PlaybackCommand::StartMetronome { state, reply } => {
            let _ = reply.send(playback.start_metronome(state));
            true
        }
        PlaybackCommand::StopMetronome { reply } => {
            let _ = reply.send(playback.stop_metronome());
            true
        }
        PlaybackCommand::Shutdown => {
            playback.shutdown();
            false
        }
    }
}

fn map_metronome_start_error(error: MetronomeStartError) -> OutputControlError {
    match error {
        MetronomeStartError::InvalidPulse(ToneGeneratorError::InvalidFrequency) => {
            OutputControlError::internal(
                "metronome click generator rejected a built-in click frequency",
            )
        }
    }
}

fn build_active_tone(
    scene: &ReferenceToneScene,
    tuning_model: TuningModel,
) -> Result<ActiveTone, OutputControlError> {
    let mut protocol_voices = Vec::with_capacity(2 + scene.intervals_semitones().len());
    let mut generator_voices = Vec::with_capacity(2 + scene.intervals_semitones().len());

    for voice in scene.voice_plan() {
        let frequency_hz = tuning_model
            .frequency_hz_for_sounding_note(voice.note)
            .map_err(|error| map_tone_math_error(error, voice.note, tuning_model))?;
        let displayed_note = tuning_model
            .displayed_note_for_sounding_note(voice.note)
            .map_err(|error| map_tone_math_error(error, voice.note, tuning_model))?;
        protocol_voices.push(ToneVoice {
            note: displayed_note,
            frequency_hz,
        });
        generator_voices.push(ReferenceToneVoice::new(
            voice.note,
            frequency_hz,
            voice.mix_level,
            voice.waveform,
        ));
    }

    let root_voice = protocol_voices
        .first()
        .cloned()
        .expect("reference tone scene should always include a root note");
    let protocol_voices = if scene.intervals_semitones().is_empty() && scene.scene_id().is_default()
    {
        Vec::new()
    } else {
        protocol_voices
    };

    Ok(ActiveTone {
        note: root_voice.note,
        frequency_hz: root_voice.frequency_hz,
        scene_id: scene.scene_id(),
        waveform_id: scene.waveform_id(),
        intervals_semitones: scene.intervals_semitones().to_vec(),
        voices: protocol_voices,
        generator_voices,
    })
}

fn resolve_sounding_scene(
    displayed_scene: &ReferenceToneScene,
    tuning_model: TuningModel,
) -> Result<ReferenceToneScene, OutputControlError> {
    let sounding_root_note = tuning_model
        .sounding_note_for_displayed_note(displayed_scene.root_note())
        .map_err(|error| map_tone_math_error(error, displayed_scene.root_note(), tuning_model))?;

    ReferenceToneScene::with_scene_id_and_waveform(
        sounding_root_note,
        displayed_scene.intervals_semitones().to_vec(),
        displayed_scene.scene_id(),
        displayed_scene.waveform_id(),
    )
    .map_err(|error| map_scene_resolution_error(error, displayed_scene.root_note(), tuning_model))
}

fn map_scene_resolution_error(
    error: ReferenceToneSceneError,
    note: Note,
    tuning_model: TuningModel,
) -> OutputControlError {
    match error {
        ReferenceToneSceneError::OutOfSupportedRange { .. } => {
            OutputControlError::invalid_transposition(format!(
                "note {note} with its interval shape is outside the supported sounding range for transposition {} semitones",
                tuning_model.transposition_semitones()
            ))
        }
        ReferenceToneSceneError::TooManyIntervals(_)
        | ReferenceToneSceneError::InvalidInterval(_)
        | ReferenceToneSceneError::DuplicateInterval(_) => {
            OutputControlError::internal(format!("failed to resolve reference tone scene: {error}"))
        }
    }
}

fn map_tone_math_error(
    error: PitchMathError,
    note: Note,
    tuning_model: TuningModel,
) -> OutputControlError {
    match error {
        PitchMathError::OutOfSupportedRange => OutputControlError::invalid_transposition(format!(
            "note {note} is outside the supported sounding range for transposition {} semitones",
            tuning_model.transposition_semitones()
        )),
        PitchMathError::InvalidReferenceFrequency => OutputControlError::internal(
            "failed to calculate tone frequency for the current reference A value",
        ),
        PitchMathError::InvalidFrequency => {
            OutputControlError::internal("failed to calculate tone frequency for the current note")
        }
    }
}

fn emit_output_error(protocol_writer: &ProtocolWriter, error: OutputControlError) {
    if let Err(write_error) = protocol_writer.write_message(&UiMessage::Error {
        code: error.code,
        message: error.message,
    }) {
        eprintln!("omatune-helper: failed to emit audio output error: {write_error}");
    }
}

fn emit_metronome_beats(protocol_writer: &ProtocolWriter, beat_events: &[MetronomeBeat]) {
    for beat in beat_events {
        if let Err(write_error) = protocol_writer.write_message(&UiMessage::MetronomeBeat {
            beat_in_bar: beat.beat_in_bar,
            beats_per_bar: beat.beats_per_bar,
            beat_unit: beat.beat_unit,
            subdivision_step: beat.subdivision_step,
            subdivision: beat.subdivision,
            accented: beat.accented,
        }) {
            eprintln!("omatune-helper: failed to emit metronome beat message: {write_error}");
        }
    }
}
