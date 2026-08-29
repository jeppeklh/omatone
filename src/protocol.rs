use crate::config::validate_reference_a_hz;
use crate::note::Note;
use crate::reference_tone::ReferenceToneScene;
use serde::Serialize;
use serde_json::{Map, Value};
use std::fmt;

#[derive(Clone, Debug, PartialEq)]
pub enum Command {
    PlayTone { scene: ReferenceToneScene },
    SetReferenceA { frequency_hz: f64 },
    StopTone,
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
}

impl CommandParseError {
    pub fn code(&self) -> ErrorCode {
        match self {
            CommandParseError::InvalidNote(_) => ErrorCode::InvalidNote,
            CommandParseError::InvalidReferenceFrequency(_) => ErrorCode::InvalidReferenceFrequency,
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
            CommandParseError::MalformedJson(error) => write!(f, "malformed command JSON: {error}"),
            CommandParseError::InvalidCommand(error) => write!(f, "invalid command: {error}"),
            CommandParseError::InvalidNote(error) => write!(f, "invalid note: {error}"),
            CommandParseError::InvalidReferenceFrequency(error) => {
                write!(f, "invalid reference A frequency: {error}")
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
        "stop_tone" => Ok(Command::StopTone),
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

#[cfg(test)]
mod tests {
    use super::{parse_command, Command, CommandParseError, ErrorCode, ToneVoice, UiMessage};
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
    fn parses_reference_a_updates() {
        assert_eq!(
            parse_command(r#"{"type":"set_reference_a","frequency_hz":442.0}"#).unwrap(),
            Command::SetReferenceA {
                frequency_hz: 442.0,
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
    }
}
