use crate::note::Note;
use serde::Serialize;
use serde_json::{Map, Value};
use std::fmt;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Command {
    PlayTone { note: Note },
    StopTone,
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
}

impl CommandParseError {
    pub fn code(&self) -> ErrorCode {
        match self {
            CommandParseError::InvalidNote(_) => ErrorCode::InvalidNote,
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

    Ok(Command::PlayTone { note })
}

#[cfg(test)]
mod tests {
    use super::{parse_command, Command, CommandParseError, ErrorCode, UiMessage};

    #[test]
    fn parses_play_tone_and_canonicalizes_input_note() {
        let command = parse_command(r#"{"type":"play_tone","note":"Bb3"}"#).unwrap();
        assert_eq!(
            command,
            Command::PlayTone {
                note: "A#3".parse().unwrap(),
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
    fn rejects_malformed_json_and_unknown_command_types() {
        assert!(matches!(
            parse_command("{not json}"),
            Err(CommandParseError::MalformedJson(_))
        ));

        assert_eq!(
            parse_command(r#"{"type":"set_reference_a","frequency_hz":442.0}"#).unwrap_err(),
            CommandParseError::InvalidCommand("unknown command type 'set_reference_a'".to_owned())
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
            }
            .to_json_line()
            .unwrap(),
            r#"{"type":"tone_started","note":"A#3","frequency_hz":233.08188}"#
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
    }
}
