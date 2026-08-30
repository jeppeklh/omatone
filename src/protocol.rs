use crate::config::validate_reference_a_hz;
use crate::metronome::{
    validate_metronome_bpm, MetronomeState, MetronomeStateError, DEFAULT_METRONOME_BEATS_PER_BAR,
    DEFAULT_METRONOME_BEAT_UNIT, DEFAULT_METRONOME_SUBDIVISION,
};
use crate::note::{validate_transposition_semitones, Note, Temperament};
use crate::reference_tone::{ReferenceToneScene, ReferenceToneSceneId, ReferenceToneWaveformId};
use serde::Serialize;
use serde_json::{Map, Value};
use std::fmt;

#[derive(Clone, Debug, PartialEq)]
pub enum Command {
    PlayTone { scene: ReferenceToneScene },
    SetReferenceA { frequency_hz: f64 },
    SetTransposition { semitones: i32 },
    SetTemperament { temperament: Temperament },
    StopTone,
    StartMetronome { state: MetronomeState },
    StopMetronome,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ExternalReferencePlaybackMode {
    Single,
    Interval,
    Chord,
}

impl ExternalReferencePlaybackMode {
    pub fn parse(value: &str) -> Option<Self> {
        match value {
            "single" => Some(Self::Single),
            "interval" | "drone" => Some(Self::Interval),
            "chord" => Some(Self::Chord),
            _ => None,
        }
    }

    pub fn supported_ids() -> &'static [&'static str] {
        &["single", "interval", "chord"]
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ExternalReferenceChordId {
    Major,
    Minor,
    Sus2,
    Sus4,
}

impl ExternalReferenceChordId {
    pub fn parse(value: &str) -> Option<Self> {
        match value {
            "major" => Some(Self::Major),
            "minor" => Some(Self::Minor),
            "sus2" => Some(Self::Sus2),
            "sus4" => Some(Self::Sus4),
            _ => None,
        }
    }

    pub fn supported_ids() -> &'static [&'static str] {
        &["major", "minor", "sus2", "sus4"]
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ExternalControlCommand {
    SelectReference {
        #[serde(skip_serializing_if = "Option::is_none")]
        note: Option<Note>,
        #[serde(skip_serializing_if = "Option::is_none")]
        playback_mode: Option<ExternalReferencePlaybackMode>,
        #[serde(skip_serializing_if = "Option::is_none")]
        scene_id: Option<ReferenceToneSceneId>,
        #[serde(skip_serializing_if = "Option::is_none")]
        interval_semitones: Option<i32>,
        #[serde(skip_serializing_if = "Option::is_none")]
        chord_id: Option<ExternalReferenceChordId>,
        #[serde(skip_serializing_if = "Option::is_none")]
        waveform_id: Option<ReferenceToneWaveformId>,
    },
    PlayReference {
        #[serde(skip_serializing_if = "Option::is_none")]
        note: Option<Note>,
        #[serde(skip_serializing_if = "Option::is_none")]
        playback_mode: Option<ExternalReferencePlaybackMode>,
        #[serde(skip_serializing_if = "Option::is_none")]
        scene_id: Option<ReferenceToneSceneId>,
        #[serde(skip_serializing_if = "Option::is_none")]
        interval_semitones: Option<i32>,
        #[serde(skip_serializing_if = "Option::is_none")]
        chord_id: Option<ExternalReferenceChordId>,
        #[serde(skip_serializing_if = "Option::is_none")]
        waveform_id: Option<ReferenceToneWaveformId>,
    },
    StopReference,
    SelectPreset {
        preset_id: String,
    },
    StartMetronome {
        #[serde(skip_serializing_if = "Option::is_none")]
        bpm: Option<u16>,
        #[serde(skip_serializing_if = "Option::is_none")]
        beats_per_bar: Option<u8>,
        #[serde(skip_serializing_if = "Option::is_none")]
        beat_unit: Option<u8>,
        #[serde(skip_serializing_if = "Option::is_none")]
        subdivision: Option<u8>,
    },
    StopMetronome,
}

impl ExternalControlCommand {
    pub fn select_reference(note: Note) -> Self {
        Self::SelectReference {
            note: Some(note),
            playback_mode: None,
            scene_id: None,
            interval_semitones: None,
            chord_id: None,
            waveform_id: None,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct ToneVoice {
    pub note: Note,
    pub frequency_hz: f64,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct PitchAnalysis {
    pub history_cents: Vec<f64>,
    pub history_span_cents: f64,
    pub held: bool,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ErrorCode {
    AudioInputUnavailable,
    AudioInputDisconnected,
    AudioOutputUnavailable,
    AudioOutputDisconnected,
    UnsupportedFormat,
    InvalidNote,
    InvalidReferenceFrequency,
    InvalidTransposition,
    InvalidTemperament,
    InvalidMetronomeBpm,
    InvalidMetronomeMeter,
    InvalidMetronomeSubdivision,
    InvalidCommand,
    InternalError,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum UiMessage {
    Ready,
    Pitch {
        note: Note,
        frequency_hz: f64,
        cents: f64,
        #[serde(skip_serializing_if = "Option::is_none")]
        confidence: Option<f64>,
        #[serde(skip_serializing_if = "Option::is_none")]
        analysis: Option<PitchAnalysis>,
    },
    NoSignal,
    ToneStarted {
        note: Note,
        frequency_hz: f64,
        #[serde(skip_serializing_if = "ReferenceToneSceneId::is_default")]
        scene_id: ReferenceToneSceneId,
        #[serde(skip_serializing_if = "ReferenceToneWaveformId::is_default")]
        waveform_id: ReferenceToneWaveformId,
        #[serde(skip_serializing_if = "Vec::is_empty")]
        intervals_semitones: Vec<i32>,
        #[serde(skip_serializing_if = "Vec::is_empty")]
        voices: Vec<ToneVoice>,
    },
    ToneStopped,
    MetronomeStarted {
        bpm: u16,
        beats_per_bar: u8,
        beat_unit: u8,
        subdivision: u8,
    },
    MetronomeBeat {
        beat_in_bar: u8,
        beats_per_bar: u8,
        beat_unit: u8,
        subdivision_step: u8,
        subdivision: u8,
        accented: bool,
    },
    MetronomeStopped,
    Error {
        code: ErrorCode,
        message: String,
    },
}

impl UiMessage {
    pub fn to_json_line(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string(self)
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ExternalControlParseError {
    MalformedJson(String),
    InvalidCommand(String),
    InvalidNote(String),
    InvalidScene(String),
    InvalidInterval(String),
    InvalidChord(String),
    InvalidMetronomeBpm(String),
    InvalidMetronomeMeter(String),
    InvalidMetronomeSubdivision(String),
}

impl fmt::Display for ExternalControlParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ExternalControlParseError::MalformedJson(error) => {
                write!(f, "malformed external control JSON: {error}")
            }
            ExternalControlParseError::InvalidCommand(error) => {
                write!(f, "invalid external control command: {error}")
            }
            ExternalControlParseError::InvalidNote(error) => {
                write!(f, "invalid external control note: {error}")
            }
            ExternalControlParseError::InvalidScene(error) => {
                write!(f, "invalid external control scene: {error}")
            }
            ExternalControlParseError::InvalidInterval(error) => {
                write!(f, "invalid external control interval: {error}")
            }
            ExternalControlParseError::InvalidChord(error) => {
                write!(f, "invalid external control chord: {error}")
            }
            ExternalControlParseError::InvalidMetronomeBpm(error) => {
                write!(f, "invalid external control metronome BPM: {error}")
            }
            ExternalControlParseError::InvalidMetronomeMeter(error) => {
                write!(f, "invalid external control metronome meter: {error}")
            }
            ExternalControlParseError::InvalidMetronomeSubdivision(error) => {
                write!(f, "invalid external control metronome subdivision: {error}")
            }
        }
    }
}

impl std::error::Error for ExternalControlParseError {}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CommandParseError {
    MalformedJson(String),
    InvalidCommand(String),
    InvalidNote(String),
    InvalidReferenceFrequency(String),
    InvalidTransposition(String),
    InvalidTemperament(String),
    InvalidMetronomeBpm(String),
    InvalidMetronomeMeter(String),
    InvalidMetronomeSubdivision(String),
}

impl CommandParseError {
    pub fn code(&self) -> ErrorCode {
        match self {
            CommandParseError::InvalidNote(_) => ErrorCode::InvalidNote,
            CommandParseError::InvalidReferenceFrequency(_) => ErrorCode::InvalidReferenceFrequency,
            CommandParseError::InvalidTransposition(_) => ErrorCode::InvalidTransposition,
            CommandParseError::InvalidTemperament(_) => ErrorCode::InvalidTemperament,
            CommandParseError::InvalidMetronomeBpm(_) => ErrorCode::InvalidMetronomeBpm,
            CommandParseError::InvalidMetronomeMeter(_) => ErrorCode::InvalidMetronomeMeter,
            CommandParseError::InvalidMetronomeSubdivision(_) => {
                ErrorCode::InvalidMetronomeSubdivision
            }
            CommandParseError::MalformedJson(_) | CommandParseError::InvalidCommand(_) => {
                ErrorCode::InvalidCommand
            }
        }
    }

    pub fn into_message(self) -> UiMessage {
        UiMessage::Error {
            code: self.code(),
            message: self.to_string(),
        }
    }
}

impl fmt::Display for CommandParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            CommandParseError::MalformedJson(error) => {
                write!(f, "malformed command JSON: {error}")
            }
            CommandParseError::InvalidCommand(error) => write!(f, "invalid command: {error}"),
            CommandParseError::InvalidNote(error) => write!(f, "invalid note: {error}"),
            CommandParseError::InvalidReferenceFrequency(error) => {
                write!(f, "invalid reference A frequency: {error}")
            }
            CommandParseError::InvalidTransposition(error) => {
                write!(f, "invalid transposition: {error}")
            }
            CommandParseError::InvalidTemperament(error) => {
                write!(f, "invalid temperament: {error}")
            }
            CommandParseError::InvalidMetronomeBpm(error) => {
                write!(f, "invalid metronome BPM: {error}")
            }
            CommandParseError::InvalidMetronomeMeter(error) => {
                write!(f, "invalid metronome meter: {error}")
            }
            CommandParseError::InvalidMetronomeSubdivision(error) => {
                write!(f, "invalid metronome subdivision: {error}")
            }
        }
    }
}

impl std::error::Error for CommandParseError {}

pub fn parse_command(input: &str) -> Result<Command, CommandParseError> {
    let value: Value = serde_json::from_str(input)
        .map_err(|error| CommandParseError::MalformedJson(error.to_string()))?;
    let object = value.as_object().ok_or_else(|| {
        CommandParseError::InvalidCommand("command must be a JSON object".to_owned())
    })?;

    let command_type = object.get("type").and_then(Value::as_str).ok_or_else(|| {
        CommandParseError::InvalidCommand("missing string field 'type'".to_owned())
    })?;

    match command_type {
        "play_tone" => parse_play_tone(object),
        "set_reference_a" => parse_set_reference_a(object),
        "set_transposition" => parse_set_transposition(object),
        "set_temperament" => parse_set_temperament(object),
        "stop_tone" => Ok(Command::StopTone),
        "start_metronome" => parse_start_metronome(object),
        "stop_metronome" => Ok(Command::StopMetronome),
        other => Err(CommandParseError::InvalidCommand(format!(
            "unknown command type '{other}'"
        ))),
    }
}

pub fn parse_external_control_command(
    input: &str,
) -> Result<ExternalControlCommand, ExternalControlParseError> {
    let value: Value = serde_json::from_str(input)
        .map_err(|error| ExternalControlParseError::MalformedJson(error.to_string()))?;
    let object = value.as_object().ok_or_else(|| {
        ExternalControlParseError::InvalidCommand("command must be a JSON object".to_owned())
    })?;

    let command_type = object.get("type").and_then(Value::as_str).ok_or_else(|| {
        ExternalControlParseError::InvalidCommand("missing string field 'type'".to_owned())
    })?;

    match command_type {
        "select_reference" => parse_external_reference_command(object, false),
        "play_reference" => parse_external_reference_command(object, true),
        "stop_reference" => Ok(ExternalControlCommand::StopReference),
        "select_preset" => parse_external_select_preset_command(object),
        "start_metronome" => parse_external_start_metronome_command(object),
        "stop_metronome" => Ok(ExternalControlCommand::StopMetronome),
        other => Err(ExternalControlParseError::InvalidCommand(format!(
            "unknown command type '{other}'"
        ))),
    }
}

fn parse_play_tone(object: &Map<String, Value>) -> Result<Command, CommandParseError> {
    let note_text = object.get("note").and_then(Value::as_str).ok_or_else(|| {
        CommandParseError::InvalidCommand("play_tone requires string field 'note'".to_owned())
    })?;
    let note = note_text
        .parse::<Note>()
        .map_err(|error| CommandParseError::InvalidNote(error.to_string()))?;
    let scene_id = parse_scene_id(object)?;
    let waveform_id = parse_waveform_id(object)?;
    let intervals_semitones = parse_intervals_semitones(object)?;
    let scene = ReferenceToneScene::with_scene_id_and_waveform(
        note,
        intervals_semitones,
        scene_id,
        waveform_id,
    )
    .map_err(|error| CommandParseError::InvalidCommand(error.to_string()))?;

    Ok(Command::PlayTone { scene })
}

fn parse_external_reference_command(
    object: &Map<String, Value>,
    play_reference: bool,
) -> Result<ExternalControlCommand, ExternalControlParseError> {
    let note = parse_optional_external_note_field(object, "note")?;
    let playback_mode = parse_optional_external_playback_mode_field(object, "playback_mode")?;
    let scene_id = parse_optional_external_scene_id(object, "scene_id")?;
    let interval_semitones = parse_optional_external_interval_field(object, "interval_semitones")?;
    let chord_id = parse_optional_external_chord_field(object, "chord_id")?;
    let waveform_id = parse_optional_external_waveform_id(object, "waveform_id")?;

    if !play_reference
        && note.is_none()
        && playback_mode.is_none()
        && scene_id.is_none()
        && interval_semitones.is_none()
        && chord_id.is_none()
        && waveform_id.is_none()
    {
        return Err(ExternalControlParseError::InvalidCommand(
            "select_reference requires at least one of: note, playback_mode, scene_id, interval_semitones, chord_id, waveform_id"
                .to_owned(),
        ));
    }

    let playback_mode = match (playback_mode, interval_semitones, chord_id) {
        (Some(ExternalReferencePlaybackMode::Single), Some(_), _) => {
            return Err(ExternalControlParseError::InvalidCommand(
                "single playback does not accept interval_semitones".to_owned(),
            ))
        }
        (Some(ExternalReferencePlaybackMode::Single), _, Some(_)) => {
            return Err(ExternalControlParseError::InvalidCommand(
                "single playback does not accept chord_id".to_owned(),
            ))
        }
        (Some(ExternalReferencePlaybackMode::Interval), _, Some(_)) => {
            return Err(ExternalControlParseError::InvalidCommand(
                "interval playback does not accept chord_id".to_owned(),
            ))
        }
        (Some(ExternalReferencePlaybackMode::Chord), Some(_), _) => {
            return Err(ExternalControlParseError::InvalidCommand(
                "chord playback does not accept interval_semitones".to_owned(),
            ))
        }
        (None, Some(_), Some(_)) => {
            return Err(ExternalControlParseError::InvalidCommand(
                "reference commands cannot combine interval_semitones and chord_id without an explicit playback_mode"
                    .to_owned(),
            ))
        }
        (None, Some(_), None) => Some(ExternalReferencePlaybackMode::Interval),
        (None, None, Some(_)) => Some(ExternalReferencePlaybackMode::Chord),
        (mode, _, _) => mode,
    };

    let command = if play_reference {
        ExternalControlCommand::PlayReference {
            note,
            playback_mode,
            scene_id,
            interval_semitones,
            chord_id,
            waveform_id,
        }
    } else {
        ExternalControlCommand::SelectReference {
            note,
            playback_mode,
            scene_id,
            interval_semitones,
            chord_id,
            waveform_id,
        }
    };

    Ok(command)
}

fn parse_external_select_preset_command(
    object: &Map<String, Value>,
) -> Result<ExternalControlCommand, ExternalControlParseError> {
    let preset_id = object
        .get("preset_id")
        .and_then(Value::as_str)
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .ok_or_else(|| {
            ExternalControlParseError::InvalidCommand(
                "select_preset requires non-empty string field 'preset_id'".to_owned(),
            )
        })?;

    Ok(ExternalControlCommand::SelectPreset {
        preset_id: preset_id.to_owned(),
    })
}

fn parse_external_start_metronome_command(
    object: &Map<String, Value>,
) -> Result<ExternalControlCommand, ExternalControlParseError> {
    let bpm = parse_optional_external_u16_field(object, "start_metronome", "bpm")?;
    let beats_per_bar =
        parse_optional_external_u8_field(object, "start_metronome", "beats_per_bar")?;
    let beat_unit = parse_optional_external_u8_field(object, "start_metronome", "beat_unit")?;
    let subdivision = parse_optional_external_u8_field(object, "start_metronome", "subdivision")?;

    if let Some(bpm) = bpm {
        validate_metronome_bpm(bpm)
            .map_err(|error| ExternalControlParseError::InvalidMetronomeBpm(error.to_string()))?;
    }
    if let Some(subdivision) = subdivision {
        MetronomeState::new(
            bpm.unwrap_or(120),
            beats_per_bar.unwrap_or(DEFAULT_METRONOME_BEATS_PER_BAR),
            beat_unit.unwrap_or(DEFAULT_METRONOME_BEAT_UNIT),
            subdivision,
        )
        .map_err(map_external_metronome_state_error)?;
    }
    if let (Some(beats_per_bar), Some(beat_unit)) = (beats_per_bar, beat_unit) {
        MetronomeState::new(
            bpm.unwrap_or(120),
            beats_per_bar,
            beat_unit,
            subdivision.unwrap_or(DEFAULT_METRONOME_SUBDIVISION),
        )
        .map_err(map_external_metronome_state_error)?;
    }

    Ok(ExternalControlCommand::StartMetronome {
        bpm,
        beats_per_bar,
        beat_unit,
        subdivision,
    })
}

fn parse_optional_external_note_field(
    object: &Map<String, Value>,
    field_name: &str,
) -> Result<Option<Note>, ExternalControlParseError> {
    let Some(note_value) = object.get(field_name) else {
        return Ok(None);
    };

    let note_text = note_value.as_str().ok_or_else(|| {
        ExternalControlParseError::InvalidCommand(format!("field '{field_name}' must be a string"))
    })?;

    let note = note_text
        .parse::<Note>()
        .map_err(|error| ExternalControlParseError::InvalidNote(error.to_string()))?;
    Ok(Some(note))
}

fn parse_optional_external_playback_mode_field(
    object: &Map<String, Value>,
    field_name: &str,
) -> Result<Option<ExternalReferencePlaybackMode>, ExternalControlParseError> {
    let Some(playback_mode_value) = object.get(field_name) else {
        return Ok(None);
    };

    let playback_mode_text = playback_mode_value.as_str().ok_or_else(|| {
        ExternalControlParseError::InvalidCommand(format!("field '{field_name}' must be a string"))
    })?;

    ExternalReferencePlaybackMode::parse(playback_mode_text)
        .ok_or_else(|| {
            ExternalControlParseError::InvalidCommand(format!(
                "field '{field_name}' must be one of: {}",
                ExternalReferencePlaybackMode::supported_ids().join(", ")
            ))
        })
        .map(Some)
}

fn parse_optional_external_scene_id(
    object: &Map<String, Value>,
    field_name: &str,
) -> Result<Option<ReferenceToneSceneId>, ExternalControlParseError> {
    let Some(scene_value) = object.get(field_name) else {
        return Ok(None);
    };

    let scene_id = scene_value.as_str().ok_or_else(|| {
        ExternalControlParseError::InvalidCommand(format!("field '{field_name}' must be a string"))
    })?;

    ReferenceToneSceneId::parse(scene_id)
        .ok_or_else(|| {
            ExternalControlParseError::InvalidScene(format!(
                "field '{field_name}' must be one of: {}",
                ReferenceToneSceneId::supported_ids().join(", ")
            ))
        })
        .map(Some)
}

fn parse_optional_external_waveform_id(
    object: &Map<String, Value>,
    field_name: &str,
) -> Result<Option<ReferenceToneWaveformId>, ExternalControlParseError> {
    let Some(waveform_value) = object.get(field_name) else {
        return Ok(None);
    };

    let waveform_id = waveform_value.as_str().ok_or_else(|| {
        ExternalControlParseError::InvalidCommand(format!("field '{field_name}' must be a string"))
    })?;

    ReferenceToneWaveformId::parse(waveform_id)
        .ok_or_else(|| {
            ExternalControlParseError::InvalidCommand(format!(
                "field '{field_name}' must be one of: {}",
                ReferenceToneWaveformId::supported_ids().join(", ")
            ))
        })
        .map(Some)
}

fn parse_optional_external_interval_field(
    object: &Map<String, Value>,
    field_name: &str,
) -> Result<Option<i32>, ExternalControlParseError> {
    let Some(interval_value) = object.get(field_name) else {
        return Ok(None);
    };

    let interval_semitones = interval_value.as_i64().ok_or_else(|| {
        ExternalControlParseError::InvalidCommand(format!(
            "field '{field_name}' must be an integer"
        ))
    })?;
    let interval_semitones = i32::try_from(interval_semitones).map_err(|_| {
        ExternalControlParseError::InvalidInterval(
            "interval value is outside the supported integer range".to_owned(),
        )
    })?;
    if !supported_external_interval_semitones().contains(&interval_semitones) {
        return Err(ExternalControlParseError::InvalidInterval(format!(
            "field '{field_name}' must be one of: {}",
            supported_external_interval_semitones()
                .iter()
                .map(i32::to_string)
                .collect::<Vec<_>>()
                .join(", ")
        )));
    }

    Ok(Some(interval_semitones))
}

fn parse_optional_external_chord_field(
    object: &Map<String, Value>,
    field_name: &str,
) -> Result<Option<ExternalReferenceChordId>, ExternalControlParseError> {
    let Some(chord_value) = object.get(field_name) else {
        return Ok(None);
    };

    let chord_id = chord_value.as_str().ok_or_else(|| {
        ExternalControlParseError::InvalidCommand(format!("field '{field_name}' must be a string"))
    })?;

    ExternalReferenceChordId::parse(chord_id)
        .ok_or_else(|| {
            ExternalControlParseError::InvalidChord(format!(
                "field '{field_name}' must be one of: {}",
                ExternalReferenceChordId::supported_ids().join(", ")
            ))
        })
        .map(Some)
}

fn parse_optional_external_u8_field(
    object: &Map<String, Value>,
    command_name: &str,
    field_name: &str,
) -> Result<Option<u8>, ExternalControlParseError> {
    let Some(value) = object.get(field_name) else {
        return Ok(None);
    };

    let value = value.as_u64().ok_or_else(|| {
        ExternalControlParseError::InvalidCommand(format!(
            "{command_name} field '{field_name}' must be an integer"
        ))
    })?;

    u8::try_from(value).map(Some).map_err(|_| {
        ExternalControlParseError::InvalidCommand(format!(
            "{command_name} field '{field_name}' must be within 0..=255"
        ))
    })
}

fn parse_optional_external_u16_field(
    object: &Map<String, Value>,
    command_name: &str,
    field_name: &str,
) -> Result<Option<u16>, ExternalControlParseError> {
    let Some(value) = object.get(field_name) else {
        return Ok(None);
    };

    let value = value.as_u64().ok_or_else(|| {
        ExternalControlParseError::InvalidCommand(format!(
            "{command_name} field '{field_name}' must be an integer"
        ))
    })?;

    u16::try_from(value).map(Some).map_err(|_| {
        ExternalControlParseError::InvalidMetronomeBpm(format!(
            "metronome BPM must be within {}..={}",
            crate::metronome::MIN_METRONOME_BPM,
            crate::metronome::MAX_METRONOME_BPM
        ))
    })
}

fn parse_scene_id(object: &Map<String, Value>) -> Result<ReferenceToneSceneId, CommandParseError> {
    let Some(scene_value) = object.get("scene_id") else {
        return Ok(ReferenceToneSceneId::default());
    };

    let scene_id = scene_value.as_str().ok_or_else(|| {
        CommandParseError::InvalidCommand("play_tone field 'scene_id' must be a string".to_owned())
    })?;

    ReferenceToneSceneId::parse(scene_id).ok_or_else(|| {
        CommandParseError::InvalidCommand(format!(
            "play_tone field 'scene_id' must be one of: {}",
            ReferenceToneSceneId::supported_ids().join(", ")
        ))
    })
}

fn parse_waveform_id(
    object: &Map<String, Value>,
) -> Result<ReferenceToneWaveformId, CommandParseError> {
    let Some(waveform_value) = object.get("waveform_id") else {
        return Ok(ReferenceToneWaveformId::default());
    };

    let waveform_id = waveform_value.as_str().ok_or_else(|| {
        CommandParseError::InvalidCommand(
            "play_tone field 'waveform_id' must be a string".to_owned(),
        )
    })?;

    ReferenceToneWaveformId::parse(waveform_id).ok_or_else(|| {
        CommandParseError::InvalidCommand(format!(
            "play_tone field 'waveform_id' must be one of: {}",
            ReferenceToneWaveformId::supported_ids().join(", ")
        ))
    })
}

fn parse_intervals_semitones(object: &Map<String, Value>) -> Result<Vec<i32>, CommandParseError> {
    let Some(intervals_value) = object.get("intervals_semitones") else {
        return Ok(Vec::new());
    };

    let intervals_array = intervals_value.as_array().ok_or_else(|| {
        CommandParseError::InvalidCommand(
            "play_tone field 'intervals_semitones' must be an array of integers".to_owned(),
        )
    })?;

    let mut intervals_semitones = Vec::with_capacity(intervals_array.len());
    for interval_value in intervals_array {
        let interval_semitones = interval_value.as_i64().ok_or_else(|| {
            CommandParseError::InvalidCommand(
                "play_tone field 'intervals_semitones' must contain integers".to_owned(),
            )
        })?;
        let interval_semitones = i32::try_from(interval_semitones).map_err(|_| {
            CommandParseError::InvalidCommand(
                "play_tone field 'intervals_semitones' contains an out-of-range integer".to_owned(),
            )
        })?;
        intervals_semitones.push(interval_semitones);
    }

    Ok(intervals_semitones)
}

fn parse_set_reference_a(object: &Map<String, Value>) -> Result<Command, CommandParseError> {
    let frequency_hz = object
        .get("frequency_hz")
        .and_then(Value::as_f64)
        .ok_or_else(|| {
            CommandParseError::InvalidCommand(
                "set_reference_a requires numeric field 'frequency_hz'".to_owned(),
            )
        })?;

    let frequency_hz = validate_reference_a_hz(frequency_hz)
        .map_err(|error| CommandParseError::InvalidReferenceFrequency(error.to_string()))?;

    Ok(Command::SetReferenceA { frequency_hz })
}

fn parse_set_transposition(object: &Map<String, Value>) -> Result<Command, CommandParseError> {
    let semitones = object
        .get("semitones")
        .and_then(Value::as_i64)
        .ok_or_else(|| {
            CommandParseError::InvalidCommand(
                "set_transposition requires integer field 'semitones'".to_owned(),
            )
        })?;

    let semitones = i32::try_from(semitones).map_err(|_| {
        CommandParseError::InvalidTransposition(
            "transposition is outside the supported integer range".to_owned(),
        )
    })?;

    let semitones = validate_transposition_semitones(semitones)
        .map_err(|error| CommandParseError::InvalidTransposition(error.to_string()))?;

    Ok(Command::SetTransposition { semitones })
}

fn parse_set_temperament(object: &Map<String, Value>) -> Result<Command, CommandParseError> {
    let offsets_value = object.get("offsets_cents").ok_or_else(|| {
        CommandParseError::InvalidCommand(
            "set_temperament requires array field 'offsets_cents'".to_owned(),
        )
    })?;
    let offsets_array = offsets_value.as_array().ok_or_else(|| {
        CommandParseError::InvalidCommand(
            "set_temperament field 'offsets_cents' must be an array of numbers".to_owned(),
        )
    })?;

    let mut offsets_cents = Vec::with_capacity(offsets_array.len());
    for offset_value in offsets_array {
        let offset_cents = offset_value.as_f64().ok_or_else(|| {
            CommandParseError::InvalidCommand(
                "set_temperament field 'offsets_cents' must contain numeric values".to_owned(),
            )
        })?;
        offsets_cents.push(offset_cents);
    }

    let temperament = Temperament::from_offset_slice(&offsets_cents)
        .map_err(|error| CommandParseError::InvalidTemperament(error.to_string()))?;

    Ok(Command::SetTemperament { temperament })
}

fn parse_start_metronome(object: &Map<String, Value>) -> Result<Command, CommandParseError> {
    let bpm = object.get("bpm").and_then(Value::as_u64).ok_or_else(|| {
        CommandParseError::InvalidCommand("start_metronome requires integer field 'bpm'".to_owned())
    })?;

    let bpm = u16::try_from(bpm).map_err(|_| {
        CommandParseError::InvalidMetronomeBpm(format!(
            "metronome BPM must be within {}..={}",
            crate::metronome::MIN_METRONOME_BPM,
            crate::metronome::MAX_METRONOME_BPM
        ))
    })?;
    let bpm = validate_metronome_bpm(bpm)
        .map_err(|error| CommandParseError::InvalidMetronomeBpm(error.to_string()))?;

    let beats_per_bar = parse_optional_u8_field(
        object,
        "start_metronome",
        "beats_per_bar",
        DEFAULT_METRONOME_BEATS_PER_BAR,
    )?;
    let beat_unit = parse_optional_u8_field(
        object,
        "start_metronome",
        "beat_unit",
        DEFAULT_METRONOME_BEAT_UNIT,
    )?;
    let subdivision = parse_optional_u8_field(
        object,
        "start_metronome",
        "subdivision",
        DEFAULT_METRONOME_SUBDIVISION,
    )?;
    let state = MetronomeState::new(bpm, beats_per_bar, beat_unit, subdivision)
        .map_err(map_metronome_state_error)?;

    Ok(Command::StartMetronome { state })
}

fn parse_optional_u8_field(
    object: &Map<String, Value>,
    command_name: &str,
    field_name: &str,
    default_value: u8,
) -> Result<u8, CommandParseError> {
    let Some(value) = object.get(field_name) else {
        return Ok(default_value);
    };

    let value = value.as_u64().ok_or_else(|| {
        CommandParseError::InvalidCommand(format!(
            "{command_name} field '{field_name}' must be an integer"
        ))
    })?;

    u8::try_from(value).map_err(|_| {
        CommandParseError::InvalidCommand(format!(
            "{command_name} field '{field_name}' must be within 0..=255"
        ))
    })
}

fn map_metronome_state_error(error: MetronomeStateError) -> CommandParseError {
    match error {
        MetronomeStateError::InvalidBpm(error) => {
            CommandParseError::InvalidMetronomeBpm(error.to_string())
        }
        MetronomeStateError::InvalidMeter(error) => {
            CommandParseError::InvalidMetronomeMeter(error.to_string())
        }
        MetronomeStateError::InvalidSubdivision(error) => {
            CommandParseError::InvalidMetronomeSubdivision(error.to_string())
        }
    }
}

fn map_external_metronome_state_error(error: MetronomeStateError) -> ExternalControlParseError {
    match error {
        MetronomeStateError::InvalidBpm(error) => {
            ExternalControlParseError::InvalidMetronomeBpm(error.to_string())
        }
        MetronomeStateError::InvalidMeter(error) => {
            ExternalControlParseError::InvalidMetronomeMeter(error.to_string())
        }
        MetronomeStateError::InvalidSubdivision(error) => {
            ExternalControlParseError::InvalidMetronomeSubdivision(error.to_string())
        }
    }
}

fn supported_external_interval_semitones() -> &'static [i32] {
    &[3, 4, 5, 7, 12]
}

#[cfg(test)]
mod tests {
    use super::{
        parse_command, parse_external_control_command, Command, CommandParseError, ErrorCode,
        ExternalControlCommand, ExternalControlParseError, ExternalReferenceChordId,
        ExternalReferencePlaybackMode, PitchAnalysis, ToneVoice, UiMessage,
    };
    use crate::metronome::{
        MetronomeState, DEFAULT_METRONOME_BEATS_PER_BAR, DEFAULT_METRONOME_BEAT_UNIT,
    };
    use crate::note::Temperament;
    use crate::reference_tone::{
        ReferenceToneScene, ReferenceToneSceneId, ReferenceToneWaveformId,
    };

    #[test]
    fn parses_play_tone_and_canonicalizes_input_note() {
        let command = parse_command(r#"{"type":"play_tone","note":"Bb3"}"#).unwrap();
        assert_eq!(
            command,
            Command::PlayTone {
                scene: ReferenceToneScene::new("A#3".parse().unwrap(), Vec::new()).unwrap(),
            }
        );
    }

    #[test]
    fn parses_play_tone_with_interval_scene() {
        let command =
            parse_command(r#"{"type":"play_tone","note":"a4","intervals_semitones":[12,7]}"#)
                .unwrap();
        assert_eq!(
            command,
            Command::PlayTone {
                scene: ReferenceToneScene::new("A4".parse().unwrap(), vec![7, 12]).unwrap(),
            }
        );
    }

    #[test]
    fn parses_play_tone_with_named_scene() {
        let command = parse_command(
            r#"{"type":"play_tone","note":"A4","scene_id":"bass_octave","waveform_id":"sine","intervals_semitones":[4,7]}"#,
        )
        .unwrap();

        assert_eq!(
            command,
            Command::PlayTone {
                scene: ReferenceToneScene::with_scene_id_and_waveform(
                    "A4".parse().unwrap(),
                    vec![4, 7],
                    ReferenceToneSceneId::Pedal,
                    ReferenceToneWaveformId::Sine,
                )
                .unwrap(),
            }
        );
    }

    #[test]
    fn parses_legacy_reference_aliases_for_compatibility() {
        let command = parse_command(
            r#"{"type":"play_tone","note":"A4","scene_id":"pedal","waveform_id":"warm","intervals_semitones":[12]}"#,
        )
        .unwrap();

        assert_eq!(
            command,
            Command::PlayTone {
                scene: ReferenceToneScene::with_scene_id_and_waveform(
                    "A4".parse().unwrap(),
                    vec![12],
                    ReferenceToneSceneId::Pedal,
                    ReferenceToneWaveformId::Warm,
                )
                .unwrap(),
            }
        );
    }

    #[test]
    fn parses_stop_tone() {
        assert_eq!(
            parse_command(r#"{"type":"stop_tone"}"#).unwrap(),
            Command::StopTone
        );
    }

    #[test]
    fn parses_metronome_start_and_stop_commands() {
        assert_eq!(
            parse_command(r#"{"type":"start_metronome","bpm":120}"#).unwrap(),
            Command::StartMetronome {
                state: MetronomeState::new(
                    120,
                    DEFAULT_METRONOME_BEATS_PER_BAR,
                    DEFAULT_METRONOME_BEAT_UNIT,
                    1
                )
                .unwrap(),
            }
        );
        assert_eq!(
            parse_command(
                r#"{"type":"start_metronome","bpm":90,"beats_per_bar":6,"beat_unit":8,"subdivision":3}"#
            )
            .unwrap(),
            Command::StartMetronome {
                state: MetronomeState::new(90, 6, 8, 3).unwrap(),
            }
        );
        assert_eq!(
            parse_command(r#"{"type":"stop_metronome"}"#).unwrap(),
            Command::StopMetronome
        );
    }

    #[test]
    fn parses_reference_a_updates() {
        assert_eq!(
            parse_command(r#"{"type":"set_reference_a","frequency_hz":442.0}"#).unwrap(),
            Command::SetReferenceA {
                frequency_hz: 442.0,
            }
        );
        assert_eq!(
            parse_command(r#"{"type":"set_transposition","semitones":2}"#).unwrap(),
            Command::SetTransposition { semitones: 2 }
        );
        assert_eq!(
            parse_command(
                r#"{"type":"set_temperament","offsets_cents":[0,0,0,0,0,0,0,0,0,0,0,0]}"#
            )
            .unwrap(),
            Command::SetTemperament {
                temperament: Temperament::equal(),
            }
        );
    }

    #[test]
    fn rejects_malformed_json_and_unknown_command_types() {
        assert!(matches!(
            parse_command("{not json}"),
            Err(CommandParseError::MalformedJson(_))
        ));

        assert_eq!(
            parse_command(r#"{"type":"unknown"}"#).unwrap_err(),
            CommandParseError::InvalidCommand("unknown command type 'unknown'".to_owned())
        );
    }

    #[test]
    fn rejects_missing_or_invalid_note_fields() {
        assert_eq!(
            parse_command(r#"{"type":"play_tone"}"#).unwrap_err(),
            CommandParseError::InvalidCommand("play_tone requires string field 'note'".to_owned())
        );
        assert_eq!(
            parse_command(r#"{"type":"play_tone","note":"C9"}"#).unwrap_err(),
            CommandParseError::InvalidNote(
                "octave 9 is outside the supported range 0..=8".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"play_tone","note":"A4","intervals_semitones":"12"}"#)
                .unwrap_err(),
            CommandParseError::InvalidCommand(
                "play_tone field 'intervals_semitones' must be an array of integers".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"play_tone","note":"A4","intervals_semitones":[7.5]}"#)
                .unwrap_err(),
            CommandParseError::InvalidCommand(
                "play_tone field 'intervals_semitones' must contain integers".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"play_tone","note":"A4","scene_id":4}"#).unwrap_err(),
            CommandParseError::InvalidCommand(
                "play_tone field 'scene_id' must be a string".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"play_tone","note":"A4","scene_id":"wide"}"#).unwrap_err(),
            CommandParseError::InvalidCommand(
                "play_tone field 'scene_id' must be one of: close, bass_octave".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"play_tone","note":"A4","waveform_id":4}"#).unwrap_err(),
            CommandParseError::InvalidCommand(
                "play_tone field 'waveform_id' must be a string".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"play_tone","note":"A4","waveform_id":"square"}"#)
                .unwrap_err(),
            CommandParseError::InvalidCommand(
                "play_tone field 'waveform_id' must be one of: sine, warm".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"play_tone","note":"B8","intervals_semitones":[1]}"#)
                .unwrap_err(),
            CommandParseError::InvalidCommand(
                "interval 1 above B8 is outside the supported note range".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"set_reference_a"}"#).unwrap_err(),
            CommandParseError::InvalidCommand(
                "set_reference_a requires numeric field 'frequency_hz'".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"set_reference_a","frequency_hz":399.0}"#).unwrap_err(),
            CommandParseError::InvalidReferenceFrequency(
                "reference A frequency must be within 400.0..=480.0 Hz".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"set_transposition"}"#).unwrap_err(),
            CommandParseError::InvalidCommand(
                "set_transposition requires integer field 'semitones'".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"set_transposition","semitones":2.5}"#).unwrap_err(),
            CommandParseError::InvalidCommand(
                "set_transposition requires integer field 'semitones'".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"set_transposition","semitones":13}"#).unwrap_err(),
            CommandParseError::InvalidTransposition(
                "transposition must be within -12..=12 semitones".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"set_temperament"}"#).unwrap_err(),
            CommandParseError::InvalidCommand(
                "set_temperament requires array field 'offsets_cents'".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"set_temperament","offsets_cents":"0,0,0"}"#).unwrap_err(),
            CommandParseError::InvalidCommand(
                "set_temperament field 'offsets_cents' must be an array of numbers".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"set_temperament","offsets_cents":[0,0,0]}"#).unwrap_err(),
            CommandParseError::InvalidTemperament(
                "temperament offsets must contain exactly 12 pitch classes".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"start_metronome"}"#).unwrap_err(),
            CommandParseError::InvalidCommand(
                "start_metronome requires integer field 'bpm'".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"start_metronome","bpm":120.5}"#).unwrap_err(),
            CommandParseError::InvalidCommand(
                "start_metronome requires integer field 'bpm'".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"start_metronome","bpm":301}"#).unwrap_err(),
            CommandParseError::InvalidMetronomeBpm(
                "metronome BPM must be within 20..=300".to_owned()
            )
        );
        assert_eq!(
            parse_command(
                r#"{"type":"start_metronome","bpm":120,"beats_per_bar":5,"beat_unit":4}"#
            )
            .unwrap_err(),
            CommandParseError::InvalidMetronomeMeter(
                "supported metronome meters are 2/4, 3/4, 4/4, and 6/8".to_owned()
            )
        );
        assert_eq!(
            parse_command(r#"{"type":"start_metronome","bpm":120,"subdivision":5}"#).unwrap_err(),
            CommandParseError::InvalidMetronomeSubdivision(
                "metronome subdivision must be within 1..=4".to_owned()
            )
        );
    }

    #[test]
    fn serializes_protocol_messages_with_expected_shape() {
        assert_eq!(
            UiMessage::Ready.to_json_line().unwrap(),
            r#"{"type":"ready"}"#
        );
        assert_eq!(
            UiMessage::Pitch {
                note: "A4".parse().unwrap(),
                frequency_hz: 440.0,
                cents: -1.4,
                confidence: Some(0.94),
                analysis: Some(PitchAnalysis {
                    history_cents: vec![-2.8, -1.9, -1.4],
                    history_span_cents: 1.4,
                    held: false,
                }),
            }
            .to_json_line()
            .unwrap(),
            r#"{"type":"pitch","note":"A4","frequency_hz":440.0,"cents":-1.4,"confidence":0.94,"analysis":{"history_cents":[-2.8,-1.9,-1.4],"history_span_cents":1.4,"held":false}}"#
        );
        assert_eq!(
            UiMessage::ToneStarted {
                note: "A#3".parse().unwrap(),
                frequency_hz: 233.08188,
                scene_id: ReferenceToneSceneId::Blend,
                waveform_id: ReferenceToneWaveformId::Warm,
                intervals_semitones: Vec::new(),
                voices: Vec::new(),
            }
            .to_json_line()
            .unwrap(),
            r#"{"type":"tone_started","note":"A#3","frequency_hz":233.08188}"#
        );
        assert_eq!(
            UiMessage::ToneStarted {
                note: "A#3".parse().unwrap(),
                frequency_hz: 233.08188,
                scene_id: ReferenceToneSceneId::Blend,
                waveform_id: ReferenceToneWaveformId::Sine,
                intervals_semitones: Vec::new(),
                voices: Vec::new(),
            }
            .to_json_line()
            .unwrap(),
            r#"{"type":"tone_started","note":"A#3","frequency_hz":233.08188,"waveform_id":"sine"}"#
        );
        assert_eq!(
            UiMessage::ToneStarted {
                note: "A4".parse().unwrap(),
                frequency_hz: 440.0,
                scene_id: ReferenceToneSceneId::Blend,
                waveform_id: ReferenceToneWaveformId::Warm,
                intervals_semitones: vec![12],
                voices: vec![
                    ToneVoice {
                        note: "A4".parse().unwrap(),
                        frequency_hz: 440.0,
                    },
                    ToneVoice {
                        note: "A5".parse().unwrap(),
                        frequency_hz: 880.0,
                    },
                ],
            }
            .to_json_line()
            .unwrap(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":440.0,"intervals_semitones":[12],"voices":[{"note":"A4","frequency_hz":440.0},{"note":"A5","frequency_hz":880.0}]}"#
        );
        assert_eq!(
            UiMessage::ToneStarted {
                note: "A4".parse().unwrap(),
                frequency_hz: 440.0,
                scene_id: ReferenceToneSceneId::Pedal,
                waveform_id: ReferenceToneWaveformId::Warm,
                intervals_semitones: vec![4, 7],
                voices: vec![
                    ToneVoice {
                        note: "A4".parse().unwrap(),
                        frequency_hz: 440.0,
                    },
                    ToneVoice {
                        note: "A3".parse().unwrap(),
                        frequency_hz: 220.0,
                    },
                    ToneVoice {
                        note: "C#5".parse().unwrap(),
                        frequency_hz: 554.3652619537442,
                    },
                    ToneVoice {
                        note: "E5".parse().unwrap(),
                        frequency_hz: 659.2551138257398,
                    },
                ],
            }
            .to_json_line()
            .unwrap(),
            r#"{"type":"tone_started","note":"A4","frequency_hz":440.0,"scene_id":"bass_octave","intervals_semitones":[4,7],"voices":[{"note":"A4","frequency_hz":440.0},{"note":"A3","frequency_hz":220.0},{"note":"C#5","frequency_hz":554.3652619537442},{"note":"E5","frequency_hz":659.2551138257398}]}"#
        );
        assert_eq!(
            UiMessage::MetronomeStarted {
                bpm: 120,
                beats_per_bar: 6,
                beat_unit: 8,
                subdivision: 3,
            }
            .to_json_line()
            .unwrap(),
            r#"{"type":"metronome_started","bpm":120,"beats_per_bar":6,"beat_unit":8,"subdivision":3}"#
        );
        assert_eq!(
            UiMessage::MetronomeBeat {
                beat_in_bar: 1,
                beats_per_bar: 6,
                beat_unit: 8,
                subdivision_step: 2,
                subdivision: 3,
                accented: false,
            }
            .to_json_line()
            .unwrap(),
            r#"{"type":"metronome_beat","beat_in_bar":1,"beats_per_bar":6,"beat_unit":8,"subdivision_step":2,"subdivision":3,"accented":false}"#
        );
        assert_eq!(
            UiMessage::MetronomeStopped.to_json_line().unwrap(),
            r#"{"type":"metronome_stopped"}"#
        );
        assert_eq!(
            CommandParseError::InvalidCommand("missing string field 'type'".to_owned())
                .into_message()
                .to_json_line()
                .unwrap(),
            r#"{"type":"error","code":"invalid_command","message":"invalid command: missing string field 'type'"}"#
        );
    }

    #[test]
    fn maps_parse_errors_to_protocol_error_codes() {
        assert_eq!(
            CommandParseError::InvalidNote("bad".to_owned()).code(),
            ErrorCode::InvalidNote
        );
        assert_eq!(
            CommandParseError::MalformedJson("bad".to_owned()).code(),
            ErrorCode::InvalidCommand
        );
        assert_eq!(
            CommandParseError::InvalidReferenceFrequency("bad".to_owned()).code(),
            ErrorCode::InvalidReferenceFrequency
        );
        assert_eq!(
            CommandParseError::InvalidTransposition("bad".to_owned()).code(),
            ErrorCode::InvalidTransposition
        );
        assert_eq!(
            CommandParseError::InvalidTemperament("bad".to_owned()).code(),
            ErrorCode::InvalidTemperament
        );
        assert_eq!(
            CommandParseError::InvalidMetronomeBpm("bad".to_owned()).code(),
            ErrorCode::InvalidMetronomeBpm
        );
        assert_eq!(
            CommandParseError::InvalidMetronomeMeter("bad".to_owned()).code(),
            ErrorCode::InvalidMetronomeMeter
        );
        assert_eq!(
            CommandParseError::InvalidMetronomeSubdivision("bad".to_owned()).code(),
            ErrorCode::InvalidMetronomeSubdivision
        );
    }

    #[test]
    fn parses_external_reference_commands_and_infers_bounded_scene_state() {
        assert_eq!(
            parse_external_control_command(
                r#"{"type":"select_reference","note":"Bb3","interval_semitones":12}"#
            )
            .unwrap(),
            ExternalControlCommand::SelectReference {
                note: Some("A#3".parse().unwrap()),
                playback_mode: Some(ExternalReferencePlaybackMode::Interval),
                scene_id: None,
                interval_semitones: Some(12),
                chord_id: None,
                waveform_id: None,
            }
        );
        assert_eq!(
            parse_external_control_command(
                r#"{"type":"play_reference","playback_mode":"chord","chord_id":"sus4","scene_id":"bass_octave","waveform_id":"sine"}"#
            )
            .unwrap(),
            ExternalControlCommand::PlayReference {
                note: None,
                playback_mode: Some(ExternalReferencePlaybackMode::Chord),
                scene_id: Some(ReferenceToneSceneId::Pedal),
                interval_semitones: None,
                chord_id: Some(ExternalReferenceChordId::Sus4),
                waveform_id: Some(ReferenceToneWaveformId::Sine),
            }
        );
        assert_eq!(
            parse_external_control_command(r#"{"type":"play_reference"}"#).unwrap(),
            ExternalControlCommand::PlayReference {
                note: None,
                playback_mode: None,
                scene_id: None,
                interval_semitones: None,
                chord_id: None,
                waveform_id: None,
            }
        );
        assert_eq!(
            parse_external_control_command(
                r#"{"type":"play_reference","playback_mode":"drone","scene_id":"pedal"}"#
            )
            .unwrap(),
            ExternalControlCommand::PlayReference {
                note: None,
                playback_mode: Some(ExternalReferencePlaybackMode::Interval),
                scene_id: Some(ReferenceToneSceneId::Pedal),
                interval_semitones: None,
                chord_id: None,
                waveform_id: None,
            }
        );
    }

    #[test]
    fn parses_external_preset_and_metronome_commands() {
        assert_eq!(
            parse_external_control_command(
                r#"{"type":"select_preset","preset_id":"guitar.standard"}"#
            )
            .unwrap(),
            ExternalControlCommand::SelectPreset {
                preset_id: "guitar.standard".to_owned(),
            }
        );
        assert_eq!(
            parse_external_control_command(
                r#"{"type":"start_metronome","bpm":96,"beats_per_bar":6,"beat_unit":8,"subdivision":3}"#
            )
            .unwrap(),
            ExternalControlCommand::StartMetronome {
                bpm: Some(96),
                beats_per_bar: Some(6),
                beat_unit: Some(8),
                subdivision: Some(3),
            }
        );
        assert_eq!(
            parse_external_control_command(r#"{"type":"stop_metronome"}"#).unwrap(),
            ExternalControlCommand::StopMetronome
        );
    }

    #[test]
    fn rejects_invalid_external_control_commands() {
        assert!(matches!(
            parse_external_control_command("{not json}"),
            Err(ExternalControlParseError::MalformedJson(_))
        ));
        assert_eq!(
            parse_external_control_command(r#"{"type":"select_reference"}"#).unwrap_err(),
            ExternalControlParseError::InvalidCommand(
                "select_reference requires at least one of: note, playback_mode, scene_id, interval_semitones, chord_id, waveform_id"
                    .to_owned()
            )
        );
        assert_eq!(
            parse_external_control_command(
                r#"{"type":"select_reference","playback_mode":"single","interval_semitones":7}"#
            )
            .unwrap_err(),
            ExternalControlParseError::InvalidCommand(
                "single playback does not accept interval_semitones".to_owned()
            )
        );
        assert_eq!(
            parse_external_control_command(r#"{"type":"select_reference","scene_id":"wide"}"#)
                .unwrap_err(),
            ExternalControlParseError::InvalidScene(
                "field 'scene_id' must be one of: close, bass_octave".to_owned()
            )
        );
        assert_eq!(
            parse_external_control_command(r#"{"type":"select_reference","interval_semitones":6}"#)
                .unwrap_err(),
            ExternalControlParseError::InvalidInterval(
                "field 'interval_semitones' must be one of: 3, 4, 5, 7, 12".to_owned()
            )
        );
        assert_eq!(
            parse_external_control_command(r#"{"type":"select_reference","waveform_id":"square"}"#)
                .unwrap_err(),
            ExternalControlParseError::InvalidCommand(
                "field 'waveform_id' must be one of: sine, warm".to_owned()
            )
        );
        assert_eq!(
            parse_external_control_command(r#"{"type":"start_metronome","bpm":301}"#).unwrap_err(),
            ExternalControlParseError::InvalidMetronomeBpm(
                "metronome BPM must be within 20..=300".to_owned()
            )
        );
    }

    #[test]
    fn serializes_external_control_commands_with_expected_shape() {
        assert_eq!(
            serde_json::to_string(&ExternalControlCommand::select_reference(
                "A4".parse().unwrap()
            ))
            .unwrap(),
            r#"{"type":"select_reference","note":"A4"}"#
        );
        assert_eq!(
            serde_json::to_string(&ExternalControlCommand::PlayReference {
                note: Some("A4".parse().unwrap()),
                playback_mode: Some(ExternalReferencePlaybackMode::Chord),
                scene_id: Some(ReferenceToneSceneId::Pedal),
                interval_semitones: None,
                chord_id: Some(ExternalReferenceChordId::Major),
                waveform_id: Some(ReferenceToneWaveformId::Sine),
            })
            .unwrap(),
            r#"{"type":"play_reference","note":"A4","playback_mode":"chord","scene_id":"bass_octave","chord_id":"major","waveform_id":"sine"}"#
        );
        assert_eq!(
            serde_json::to_string(&ExternalControlCommand::StartMetronome {
                bpm: None,
                beats_per_bar: None,
                beat_unit: None,
                subdivision: None,
            })
            .unwrap(),
            r#"{"type":"start_metronome"}"#
        );
    }
}
