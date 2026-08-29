use crate::note::{Note, DEFAULT_REFERENCE_A_HZ};
use crate::protocol::{ErrorCode, UiMessage};
use crate::protocol_io::ProtocolWriter;
use crate::reference_tone::{
    ReferenceToneGenerator, ToneGeneratorError, DEFAULT_OUTPUT_LEVEL, DEFAULT_RAMP_DURATION_MS,
    DEFAULT_SAMPLE_RATE_HZ,
};
use libpulse_binding as pulse;
use libpulse_simple_binding as psimple;
use pulse::def::BufferAttr;
use pulse::sample::{Format, Spec};
use pulse::stream::Direction;
use std::env;
use std::io;
use std::sync::mpsc::{self, Receiver, Sender, SyncSender};
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
    Mock(MockAudioOutput),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum MockAudioOutput {
    Ok,
    Unavailable,
    Disconnected,
}

enum PlaybackCommand {
    Play {
        note: Note,
        reply: SyncSender<Result<f64, OutputControlError>>,
    },
    Stop {
        reply: SyncSender<Result<(), OutputControlError>>,
    },
    Shutdown,
}

#[derive(Clone, Debug)]
pub struct OutputControlError {
    pub code: ErrorCode,
    pub message: String,
}

impl AudioOutput {
    pub fn new(protocol_writer: ProtocolWriter) -> io::Result<Self> {
        if let Some(mock) = MockAudioOutput::from_env() {
            let _ = protocol_writer;
            return Ok(Self {
                inner: AudioOutputInner::Mock(mock),
            });
        }

        let (command_tx, command_rx) = mpsc::channel();
        let worker = thread::Builder::new()
            .name("omatune-audio-output".to_owned())
            .spawn(move || output_worker_loop(command_rx, protocol_writer))?;

        Ok(Self {
            inner: AudioOutputInner::Worker {
                command_tx,
                worker: Some(worker),
            },
        })
    }

    pub fn play(&self, note: Note) -> Result<f64, OutputControlError> {
        match &self.inner {
            AudioOutputInner::Worker { command_tx, .. } => {
                let (reply_tx, reply_rx) = mpsc::sync_channel(1);
                command_tx
                    .send(PlaybackCommand::Play {
                        note,
                        reply: reply_tx,
                    })
                    .map_err(|_| {
                        OutputControlError::disconnected("audio output worker is unavailable")
                    })?;

                reply_rx.recv().map_err(|_| {
                    OutputControlError::disconnected("audio output worker did not respond")
                })?
            }
            AudioOutputInner::Mock(mock) => mock.play(note),
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
            AudioOutputInner::Mock(mock) => mock.stop(),
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

impl MockAudioOutput {
    fn from_env() -> Option<Self> {
        match env::var("OMATUNE_TEST_OUTPUT_MODE").ok()?.trim() {
            "ok" => Some(Self::Ok),
            "unavailable" => Some(Self::Unavailable),
            "disconnected" => Some(Self::Disconnected),
            _ => None,
        }
    }

    fn play(self, note: Note) -> Result<f64, OutputControlError> {
        let frequency_hz = note.frequency_hz(DEFAULT_REFERENCE_A_HZ).map_err(|error| {
            OutputControlError::internal(format!("failed to calculate tone frequency: {error}"))
        })?;

        match self {
            Self::Ok => Ok(frequency_hz),
            Self::Unavailable => Err(OutputControlError::unavailable(
                "simulated audio output unavailable",
            )),
            Self::Disconnected => Err(OutputControlError::disconnected(
                "simulated audio output disconnected",
            )),
        }
    }

    fn stop(self) -> Result<(), OutputControlError> {
        match self {
            Self::Ok | Self::Unavailable => Ok(()),
            Self::Disconnected => Err(OutputControlError::disconnected(
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
    generator: ReferenceToneGenerator,
    sample_buffer: Vec<f32>,
    byte_buffer: Vec<u8>,
}

impl PulsePlayback {
    fn new() -> Result<Self, OutputControlError> {
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
            generator: ReferenceToneGenerator::new(
                DEFAULT_SAMPLE_RATE_HZ,
                DEFAULT_OUTPUT_LEVEL,
                DEFAULT_RAMP_DURATION_MS,
            ),
            sample_buffer: vec![0.0; CHUNK_FRAMES * OUTPUT_CHANNELS as usize],
            byte_buffer: Vec::with_capacity(
                CHUNK_FRAMES * OUTPUT_CHANNELS as usize * std::mem::size_of::<f32>(),
            ),
        })
    }

    fn play(&mut self, note: Note) -> Result<f64, OutputControlError> {
        let frequency_hz = note.frequency_hz(DEFAULT_REFERENCE_A_HZ).map_err(|error| {
            OutputControlError::internal(format!("failed to calculate tone frequency: {error}"))
        })?;

        self.ensure_stream()?;
        self.generator.play_frequency(frequency_hz).map_err(
            |ToneGeneratorError::InvalidFrequency| {
                OutputControlError::internal(
                    "reference-tone generator rejected a valid note frequency",
                )
            },
        )?;

        Ok(frequency_hz)
    }

    fn stop(&mut self) -> Result<(), OutputControlError> {
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

fn output_worker_loop(command_rx: Receiver<PlaybackCommand>, protocol_writer: ProtocolWriter) {
    let mut playback = match PulsePlayback::new() {
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
        PlaybackCommand::Play { note, reply } => {
            let _ = reply.send(playback.play(note));
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

fn emit_output_error(protocol_writer: &ProtocolWriter, error: OutputControlError) {
    if let Err(write_error) = protocol_writer.write_message(&UiMessage::Error {
        code: error.code,
        message: error.message,
    }) {
        eprintln!("omatune-helper: failed to emit audio output error: {write_error}");
    }
}
