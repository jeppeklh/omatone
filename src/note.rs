use serde::ser::{Serialize, Serializer};
use std::error::Error;
use std::fmt;
use std::str::FromStr;

pub const DEFAULT_REFERENCE_A_HZ: f64 = 440.0;
pub const MIN_OCTAVE: i32 = 0;
pub const MAX_OCTAVE: i32 = 8;

const SEMITONES_PER_OCTAVE: i32 = 12;
const A4_MIDI_NUMBER: i32 = 69;
const MIN_MIDI_NUMBER: i32 = 12;
const MAX_MIDI_NUMBER: i32 = 119;
const NOTE_NAMES: [&str; 12] = [
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
];

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub struct Note {
    midi_number: i32,
}

#[derive(Clone, Debug, PartialEq)]
pub struct NearestNote {
    pub note: Note,
    pub reference_frequency_hz: f64,
    pub cents: f64,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PitchMathError {
    InvalidFrequency,
    InvalidReferenceFrequency,
    OutOfSupportedRange,
}

impl fmt::Display for PitchMathError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PitchMathError::InvalidFrequency => {
                write!(f, "frequency must be finite and greater than zero")
            }
            PitchMathError::InvalidReferenceFrequency => {
                write!(
                    f,
                    "reference A frequency must be finite and greater than zero"
                )
            }
            PitchMathError::OutOfSupportedRange => {
                write!(f, "value is outside the supported note range")
            }
        }
    }
}

impl Error for PitchMathError {}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum NoteParseError {
    Empty,
    InvalidLetter(char),
    InvalidAccidental,
    MissingOctave,
    InvalidOctave(String),
    UnsupportedOctave(i32),
}

impl fmt::Display for NoteParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            NoteParseError::Empty => write!(f, "note is empty"),
            NoteParseError::InvalidLetter(letter) => write!(f, "invalid note letter '{letter}'"),
            NoteParseError::InvalidAccidental => write!(f, "note accidental must be '#' or 'b'"),
            NoteParseError::MissingOctave => write!(f, "note is missing an octave number"),
            NoteParseError::InvalidOctave(text) => write!(f, "invalid octave '{text}'"),
            NoteParseError::UnsupportedOctave(octave) => {
                write!(
                    f,
                    "octave {octave} is outside the supported range {MIN_OCTAVE}..={MAX_OCTAVE}"
                )
            }
        }
    }
}

impl Error for NoteParseError {}

impl Note {
    pub fn from_midi_number(midi_number: i32) -> Option<Self> {
        if (MIN_MIDI_NUMBER..=MAX_MIDI_NUMBER).contains(&midi_number) {
            Some(Self { midi_number })
        } else {
            None
        }
    }

    pub fn octave(self) -> i32 {
        self.midi_number.div_euclid(SEMITONES_PER_OCTAVE) - 1
    }

    pub fn midi_number(self) -> i32 {
        self.midi_number
    }

    pub fn frequency_hz(self, reference_a_hz: f64) -> Result<f64, PitchMathError> {
        if !is_positive_finite(reference_a_hz) {
            return Err(PitchMathError::InvalidReferenceFrequency);
        }

        let semitone_offset = self.midi_number - A4_MIDI_NUMBER;
        Ok(reference_a_hz * 2.0_f64.powf(semitone_offset as f64 / SEMITONES_PER_OCTAVE as f64))
    }
}

impl fmt::Display for Note {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let pitch_class = self.midi_number.rem_euclid(SEMITONES_PER_OCTAVE) as usize;
        write!(f, "{}{}", NOTE_NAMES[pitch_class], self.octave())
    }
}

impl Serialize for Note {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&self.to_string())
    }
}

impl FromStr for Note {
    type Err = NoteParseError;

    fn from_str(input: &str) -> Result<Self, Self::Err> {
        let text = input.trim();
        if text.is_empty() {
            return Err(NoteParseError::Empty);
        }

        let mut chars = text.chars();
        let raw_letter = chars.next().ok_or(NoteParseError::Empty)?;
        let letter = raw_letter.to_ascii_uppercase();
        let base_pitch_class: i32 = match letter {
            'C' => 0,
            'D' => 2,
            'E' => 4,
            'F' => 5,
            'G' => 7,
            'A' => 9,
            'B' => 11,
            _ => return Err(NoteParseError::InvalidLetter(raw_letter)),
        };

        let remainder = chars.as_str();
        let (accidental_offset, octave_text) = if let Some(rest) = remainder.strip_prefix('#') {
            (1, rest)
        } else if let Some(rest) = remainder.strip_prefix('b') {
            (-1, rest)
        } else if remainder.is_empty() {
            (0, remainder)
        } else if matches!(remainder.chars().next(), Some('0'..='9' | '-')) {
            (0, remainder)
        } else {
            return Err(NoteParseError::InvalidAccidental);
        };

        if octave_text.is_empty() {
            return Err(NoteParseError::MissingOctave);
        }

        let octave = octave_text
            .parse::<i32>()
            .map_err(|_| NoteParseError::InvalidOctave(octave_text.to_owned()))?;

        let adjusted_pitch_class: i32 = base_pitch_class + accidental_offset;
        let canonical_octave = octave + adjusted_pitch_class.div_euclid(SEMITONES_PER_OCTAVE);
        if !(MIN_OCTAVE..=MAX_OCTAVE).contains(&canonical_octave) {
            return Err(NoteParseError::UnsupportedOctave(canonical_octave));
        }

        let canonical_pitch_class = adjusted_pitch_class.rem_euclid(SEMITONES_PER_OCTAVE);
        let midi_number = (canonical_octave + 1) * SEMITONES_PER_OCTAVE + canonical_pitch_class;
        Self::from_midi_number(midi_number)
            .ok_or(NoteParseError::UnsupportedOctave(canonical_octave))
    }
}

pub fn cents_between(
    frequency_hz: f64,
    reference_frequency_hz: f64,
) -> Result<f64, PitchMathError> {
    if !is_positive_finite(frequency_hz) {
        return Err(PitchMathError::InvalidFrequency);
    }
    if !is_positive_finite(reference_frequency_hz) {
        return Err(PitchMathError::InvalidReferenceFrequency);
    }

    Ok(1200.0 * (frequency_hz / reference_frequency_hz).log2())
}

pub fn nearest_note_for_frequency(
    frequency_hz: f64,
    reference_a_hz: f64,
) -> Result<NearestNote, PitchMathError> {
    if !is_positive_finite(frequency_hz) {
        return Err(PitchMathError::InvalidFrequency);
    }
    if !is_positive_finite(reference_a_hz) {
        return Err(PitchMathError::InvalidReferenceFrequency);
    }

    let semitones_from_a4 = 12.0 * (frequency_hz / reference_a_hz).log2();
    let midi_number = (A4_MIDI_NUMBER as f64 + semitones_from_a4).round() as i32;
    let note = Note::from_midi_number(midi_number).ok_or(PitchMathError::OutOfSupportedRange)?;
    let reference_frequency_hz = note.frequency_hz(reference_a_hz)?;
    let cents = cents_between(frequency_hz, reference_frequency_hz)?;

    Ok(NearestNote {
        note,
        reference_frequency_hz,
        cents,
    })
}

fn is_positive_finite(value: f64) -> bool {
    value.is_finite() && value > 0.0
}

#[cfg(test)]
mod tests {
    use super::{
        cents_between, nearest_note_for_frequency, Note, NoteParseError, PitchMathError,
        DEFAULT_REFERENCE_A_HZ,
    };

    fn assert_close(actual: f64, expected: f64, tolerance: f64) {
        let delta = (actual - expected).abs();
        assert!(
            delta <= tolerance,
            "expected {expected} +/- {tolerance}, got {actual} (delta {delta})"
        );
    }

    #[test]
    fn parses_and_canonicalizes_supported_notes() {
        assert_eq!("A4".parse::<Note>().unwrap().to_string(), "A4");
        assert_eq!("f#4".parse::<Note>().unwrap().to_string(), "F#4");
        assert_eq!("Bb3".parse::<Note>().unwrap().to_string(), "A#3");
        assert_eq!("Cb4".parse::<Note>().unwrap().to_string(), "B3");
        assert_eq!("B#3".parse::<Note>().unwrap().to_string(), "C4");
    }

    #[test]
    fn rejects_invalid_note_inputs() {
        assert_eq!("".parse::<Note>().unwrap_err(), NoteParseError::Empty);
        assert_eq!(
            "H2".parse::<Note>().unwrap_err(),
            NoteParseError::InvalidLetter('H')
        );
        assert_eq!(
            "A".parse::<Note>().unwrap_err(),
            NoteParseError::MissingOctave
        );
        assert_eq!(
            "Ax4".parse::<Note>().unwrap_err(),
            NoteParseError::InvalidAccidental
        );
        assert_eq!(
            "C9".parse::<Note>().unwrap_err(),
            NoteParseError::UnsupportedOctave(9)
        );
        assert_eq!(
            "Cb0".parse::<Note>().unwrap_err(),
            NoteParseError::UnsupportedOctave(-1)
        );
    }

    #[test]
    fn calculates_reference_frequencies() {
        assert_close(
            "A2".parse::<Note>()
                .unwrap()
                .frequency_hz(DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
            110.0,
            0.0001,
        );
        assert_close(
            "A3".parse::<Note>()
                .unwrap()
                .frequency_hz(DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
            220.0,
            0.0001,
        );
        assert_close(
            "A4".parse::<Note>()
                .unwrap()
                .frequency_hz(DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
            440.0,
            0.0001,
        );
        assert_close(
            "A5".parse::<Note>()
                .unwrap()
                .frequency_hz(DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
            880.0,
            0.0001,
        );
    }

    #[test]
    fn calculates_standard_guitar_frequencies_through_general_note_model() {
        assert_close(
            "E2".parse::<Note>()
                .unwrap()
                .frequency_hz(DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
            82.4069,
            0.001,
        );
        assert_close(
            "D3".parse::<Note>()
                .unwrap()
                .frequency_hz(DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
            146.8324,
            0.001,
        );
        assert_close(
            "G3".parse::<Note>()
                .unwrap()
                .frequency_hz(DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
            195.9977,
            0.001,
        );
        assert_close(
            "B3".parse::<Note>()
                .unwrap()
                .frequency_hz(DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
            246.9417,
            0.001,
        );
        assert_close(
            "E4".parse::<Note>()
                .unwrap()
                .frequency_hz(DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
            329.6276,
            0.001,
        );
    }

    #[test]
    fn finds_nearest_note_and_cents_near_semitone_boundaries() {
        let a4 = "A4".parse::<Note>().unwrap();
        let a_sharp4 = "A#4".parse::<Note>().unwrap();
        let boundary = (a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap()
            * a_sharp4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap())
        .sqrt();

        let below = nearest_note_for_frequency(boundary * 0.9999, DEFAULT_REFERENCE_A_HZ).unwrap();
        assert_eq!(below.note.to_string(), "A4");
        assert!(below.cents > 49.0 && below.cents < 50.0);

        let above = nearest_note_for_frequency(boundary * 1.0001, DEFAULT_REFERENCE_A_HZ).unwrap();
        assert_eq!(above.note.to_string(), "A#4");
        assert!(above.cents < -49.0 && above.cents > -50.0);
    }

    #[test]
    fn calculates_cents_offsets() {
        assert_close(cents_between(440.0, 440.0).unwrap(), 0.0, 0.0001);

        let shifted = 440.0 * 2.0_f64.powf(10.0 / 1200.0);
        assert_close(cents_between(shifted, 440.0).unwrap(), 10.0, 0.0001);
        assert_close(cents_between(440.0, shifted).unwrap(), -10.0, 0.0001);
    }

    #[test]
    fn rejects_invalid_frequency_inputs() {
        assert_eq!(
            cents_between(0.0, 440.0).unwrap_err(),
            PitchMathError::InvalidFrequency
        );
        assert_eq!(
            cents_between(440.0, 0.0).unwrap_err(),
            PitchMathError::InvalidReferenceFrequency
        );
        assert_eq!(
            nearest_note_for_frequency(8.0, DEFAULT_REFERENCE_A_HZ).unwrap_err(),
            PitchMathError::OutOfSupportedRange
        );
    }
}
