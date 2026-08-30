use crate::config::validate_reference_a_hz;
use crate::metronome::{
    validate_metronome_bpm, MetronomeState, MetronomeStateError, DEFAULT_METRONOME_BEATS_PER_BAR,
    DEFAULT_METRONOME_BEAT_UNIT, DEFAULT_METRONOME_SUBDIVISION,
};
use crate::note::{validate_transposition_semitones, Note, Temperament};
use crate::reference_tone::ReferenceToneScene;
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

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct ToneVoice {
    pub note: Note,
    pub frequency_hz: f64,
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
    },
    NoSignal,
    ToneStarted {
        note: Note,
        frequency_hz: f64,
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

fn parse_play_tone(object: &Map<String, Value>) -> Result<Command, CommandParseError> {
    let note_text = object.get("note").and_then(Value::as_str).ok_or_else(|| {
        CommandParseError::InvalidCommand("play_tone requires string field 'note'".to_owned())
    })?;
    let note = note_text
        .parse::<Note>()
        .map_err(|error| CommandParseError::InvalidNote(error.to_string()))?;
    let intervals_semitones = parse_intervals_semitones(object)?;
    let scene = ReferenceToneScene::new(note, intervals_semitones)
        .map_err(|error| CommandParseError::InvalidCommand(error.to_string()))?;

    Ok(Command::PlayTone { scene })
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

#[cfg(test)]
mod tests {
    use super::{parse_command, Command, CommandParseError, ErrorCode, ToneVoice, UiMessage};
    use crate::metronome::{
        MetronomeState, DEFAULT_METRONOME_BEATS_PER_BAR, DEFAULT_METRONOME_BEAT_UNIT,
    };
    use crate::note::Temperament;
    use crate::reference_tone::ReferenceToneScene;

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
            UiMessage::ToneStarted {
                note: "A#3".parse().unwrap(),
                frequency_hz: 233.08188,
                intervals_semitones: Vec::new(),
                voices: Vec::new(),
            }
            .to_json_line()
            .unwrap(),
            r#"{"type":"tone_started","note":"A#3","frequency_hz":233.08188}"#
        );
        assert_eq!(
            UiMessage::ToneStarted {
                note: "A4".parse().unwrap(),
                frequency_hz: 440.0,
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
}
