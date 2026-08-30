use serde::ser::{Serialize, Serializer};
use std::error::Error;
use std::fmt;
use std::str::FromStr;

pub const DEFAULT_REFERENCE_A_HZ: f64 = 440.0;
pub const DEFAULT_TRANSPOSITION_SEMITONES: i32 = 0;
pub const MIN_OCTAVE: i32 = 0;
pub const MAX_OCTAVE: i32 = 8;
pub const MIN_TRANSPOSITION_SEMITONES: i32 = -12;
pub const MAX_TRANSPOSITION_SEMITONES: i32 = 12;
pub const PITCH_CLASSES_PER_OCTAVE: usize = 12;
pub const MAX_TEMPERAMENT_OFFSET_CENTS: f64 = 100.0;

const SEMITONES_PER_OCTAVE: i32 = PITCH_CLASSES_PER_OCTAVE as i32;
const A4_MIDI_NUMBER: i32 = 69;
const MIN_MIDI_NUMBER: i32 = 12;
const MAX_MIDI_NUMBER: i32 = 119;
const A_PITCH_CLASS_INDEX: usize = 9;
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

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct TuningModel {
    reference_a_hz: f64,
    transposition_semitones: i32,
    temperament: Temperament,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PitchMathError {
    InvalidFrequency,
    InvalidReferenceFrequency,
    OutOfSupportedRange,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TranspositionError {
    OutOfRange,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Temperament {
    offsets_cents: [f64; PITCH_CLASSES_PER_OCTAVE],
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TemperamentError {
    InvalidOffsetCount,
    InvalidOffsetValue,
    OffsetOutOfRange,
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

impl fmt::Display for TranspositionError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            TranspositionError::OutOfRange => write!(
                f,
                "transposition must be within {MIN_TRANSPOSITION_SEMITONES}..={MAX_TRANSPOSITION_SEMITONES} semitones"
            ),
        }
    }
}

impl Error for TranspositionError {}

impl fmt::Display for TemperamentError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            TemperamentError::InvalidOffsetCount => write!(
                f,
                "temperament offsets must contain exactly {PITCH_CLASSES_PER_OCTAVE} pitch classes"
            ),
            TemperamentError::InvalidOffsetValue => {
                write!(f, "temperament offsets must be finite numeric values")
            }
            TemperamentError::OffsetOutOfRange => write!(
                f,
                "temperament offsets must remain within +/-{MAX_TEMPERAMENT_OFFSET_CENTS:.1} cents"
            ),
        }
    }
}

impl Error for TemperamentError {}

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

    pub fn transposed(self, semitones: i32) -> Result<Self, PitchMathError> {
        let midi_number = self
            .midi_number
            .checked_add(semitones)
            .ok_or(PitchMathError::OutOfSupportedRange)?;

        Self::from_midi_number(midi_number).ok_or(PitchMathError::OutOfSupportedRange)
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

impl TuningModel {
    pub fn new(
        reference_a_hz: f64,
        transposition_semitones: i32,
    ) -> Result<Self, TranspositionError> {
        Self::with_temperament(
            reference_a_hz,
            transposition_semitones,
            Temperament::equal(),
        )
    }

    pub fn with_temperament(
        reference_a_hz: f64,
        transposition_semitones: i32,
        temperament: Temperament,
    ) -> Result<Self, TranspositionError> {
        Ok(Self {
            reference_a_hz,
            transposition_semitones: validate_transposition_semitones(transposition_semitones)?,
            temperament,
        })
    }

    pub fn reference_a_hz(self) -> f64 {
        self.reference_a_hz
    }

    pub fn transposition_semitones(self) -> i32 {
        self.transposition_semitones
    }

    pub fn temperament(self) -> Temperament {
        self.temperament
    }

    pub fn sounding_note_for_displayed_note(
        self,
        displayed_note: Note,
    ) -> Result<Note, PitchMathError> {
        displayed_note.transposed(-self.transposition_semitones)
    }

    pub fn displayed_note_for_sounding_note(
        self,
        sounding_note: Note,
    ) -> Result<Note, PitchMathError> {
        sounding_note.transposed(self.transposition_semitones)
    }

    pub fn frequency_hz_for_sounding_note(
        self,
        sounding_note: Note,
    ) -> Result<f64, PitchMathError> {
        self.temperament
            .frequency_hz_for_note(sounding_note, self.reference_a_hz)
    }

    pub fn frequency_hz_for_displayed_note(
        self,
        displayed_note: Note,
    ) -> Result<f64, PitchMathError> {
        self.frequency_hz_for_sounding_note(self.sounding_note_for_displayed_note(displayed_note)?)
    }

    pub fn nearest_displayed_note_for_frequency(
        self,
        frequency_hz: f64,
    ) -> Result<NearestNote, PitchMathError> {
        let nearest_sounding = self.nearest_sounding_note_for_frequency(frequency_hz)?;
        let displayed_note = self.displayed_note_for_sounding_note(nearest_sounding.note)?;
        let reference_frequency_hz = self.frequency_hz_for_displayed_note(displayed_note)?;
        let cents = cents_between(frequency_hz, reference_frequency_hz)?;

        Ok(NearestNote {
            note: displayed_note,
            reference_frequency_hz,
            cents,
        })
    }

    fn nearest_sounding_note_for_frequency(
        self,
        frequency_hz: f64,
    ) -> Result<NearestNote, PitchMathError> {
        if !is_positive_finite(frequency_hz) {
            return Err(PitchMathError::InvalidFrequency);
        }
        if !is_positive_finite(self.reference_a_hz) {
            return Err(PitchMathError::InvalidReferenceFrequency);
        }

        let mut nearest: Option<NearestNote> = None;

        for midi_number in MIN_MIDI_NUMBER..=MAX_MIDI_NUMBER {
            let note = Note::from_midi_number(midi_number)
                .expect("supported MIDI range should always resolve to a note");
            let reference_frequency_hz = self.frequency_hz_for_sounding_note(note)?;
            let cents = cents_between(frequency_hz, reference_frequency_hz)?;

            let should_replace = nearest
                .as_ref()
                .map(|current| cents.abs() < current.cents.abs())
                .unwrap_or(true);
            if should_replace {
                nearest = Some(NearestNote {
                    note,
                    reference_frequency_hz,
                    cents,
                });
            }
        }

        nearest.ok_or(PitchMathError::OutOfSupportedRange)
    }
}

impl Temperament {
    pub const fn equal() -> Self {
        Self {
            offsets_cents: [0.0; PITCH_CLASSES_PER_OCTAVE],
        }
    }

    pub fn from_offset_slice(offsets_cents: &[f64]) -> Result<Self, TemperamentError> {
        if offsets_cents.len() != PITCH_CLASSES_PER_OCTAVE {
            return Err(TemperamentError::InvalidOffsetCount);
        }

        let mut copied_offsets = [0.0; PITCH_CLASSES_PER_OCTAVE];
        copied_offsets.copy_from_slice(offsets_cents);
        Self::from_offsets_cents(copied_offsets)
    }

    pub fn from_offsets_cents(
        mut offsets_cents: [f64; PITCH_CLASSES_PER_OCTAVE],
    ) -> Result<Self, TemperamentError> {
        if offsets_cents
            .iter()
            .any(|offset_cents| !offset_cents.is_finite())
        {
            return Err(TemperamentError::InvalidOffsetValue);
        }
        if offsets_cents
            .iter()
            .any(|offset_cents| offset_cents.abs() > MAX_TEMPERAMENT_OFFSET_CENTS)
        {
            return Err(TemperamentError::OffsetOutOfRange);
        }

        let a_offset_cents = offsets_cents[A_PITCH_CLASS_INDEX];
        for offset_cents in &mut offsets_cents {
            *offset_cents = round_cents(*offset_cents - a_offset_cents);
        }

        Ok(Self { offsets_cents })
    }

    pub fn offsets_cents(self) -> [f64; PITCH_CLASSES_PER_OCTAVE] {
        self.offsets_cents
    }

    pub fn frequency_hz_for_note(
        self,
        note: Note,
        reference_a_hz: f64,
    ) -> Result<f64, PitchMathError> {
        let base_frequency_hz = note.frequency_hz(reference_a_hz)?;
        Ok(base_frequency_hz * 2.0_f64.powf(self.offset_cents_for_note(note) / 1200.0))
    }

    pub fn offset_cents_for_note(self, note: Note) -> f64 {
        self.offsets_cents[note.midi_number.rem_euclid(SEMITONES_PER_OCTAVE) as usize]
    }
}

pub fn validate_transposition_semitones(
    transposition_semitones: i32,
) -> Result<i32, TranspositionError> {
    if !(MIN_TRANSPOSITION_SEMITONES..=MAX_TRANSPOSITION_SEMITONES)
        .contains(&transposition_semitones)
    {
        return Err(TranspositionError::OutOfRange);
    }

    Ok(transposition_semitones)
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

fn round_cents(value: f64) -> f64 {
    let rounded = (value * 10_000.0).round() / 10_000.0;
    if rounded.abs() <= f64::EPSILON {
        0.0
    } else {
        rounded
    }
}

#[cfg(test)]
mod tests {
    use super::{
        cents_between, nearest_note_for_frequency, validate_transposition_semitones, Note,
        NoteParseError, PitchMathError, Temperament, TemperamentError, TranspositionError,
        TuningModel, DEFAULT_REFERENCE_A_HZ,
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
    fn transposes_notes_within_supported_range() {
        assert_eq!(
            "A4".parse::<Note>()
                .unwrap()
                .transposed(2)
                .unwrap()
                .to_string(),
            "B4"
        );
        assert_eq!(
            "C4".parse::<Note>()
                .unwrap()
                .transposed(-2)
                .unwrap()
                .to_string(),
            "A#3"
        );
        assert_eq!(
            "B8".parse::<Note>().unwrap().transposed(1).unwrap_err(),
            PitchMathError::OutOfSupportedRange
        );
    }

    #[test]
    fn validates_supported_transposition_range() {
        assert_eq!(validate_transposition_semitones(0).unwrap(), 0);
        assert_eq!(validate_transposition_semitones(12).unwrap(), 12);
        assert_eq!(
            validate_transposition_semitones(13).unwrap_err(),
            TranspositionError::OutOfRange
        );
        assert_eq!(
            validate_transposition_semitones(-13).unwrap_err(),
            TranspositionError::OutOfRange
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
    fn calibrated_reference_a_changes_note_math_consistently() {
        let calibrated_reference_a_hz = 442.0;
        let a4 = "A4".parse::<Note>().unwrap();
        let e2 = "E2".parse::<Note>().unwrap();

        assert_close(
            a4.frequency_hz(calibrated_reference_a_hz).unwrap(),
            442.0,
            0.0001,
        );

        let calibrated_e2 = e2.frequency_hz(calibrated_reference_a_hz).unwrap();
        let nearest = nearest_note_for_frequency(calibrated_e2, calibrated_reference_a_hz).unwrap();
        assert_eq!(nearest.note.to_string(), "E2");
        assert_close(nearest.reference_frequency_hz, calibrated_e2, 0.0001);
        assert_close(nearest.cents, 0.0, 0.0001);
    }

    #[test]
    fn transposed_tuning_model_maps_detected_and_reference_notes_consistently() {
        let tuning = TuningModel::new(DEFAULT_REFERENCE_A_HZ, 2).unwrap();
        let displayed_c4 = "C4".parse::<Note>().unwrap();
        let sounding_a_sharp3 = "A#3".parse::<Note>().unwrap();
        let sounding_frequency_hz = sounding_a_sharp3
            .frequency_hz(DEFAULT_REFERENCE_A_HZ)
            .unwrap();

        assert_eq!(
            tuning
                .sounding_note_for_displayed_note(displayed_c4)
                .unwrap()
                .to_string(),
            "A#3"
        );
        assert_close(
            tuning
                .frequency_hz_for_displayed_note(displayed_c4)
                .unwrap(),
            sounding_frequency_hz,
            0.0001,
        );

        let nearest = tuning
            .nearest_displayed_note_for_frequency(sounding_frequency_hz)
            .unwrap();
        assert_eq!(nearest.note.to_string(), "C4");
        assert_close(
            nearest.reference_frequency_hz,
            sounding_frequency_hz,
            0.0001,
        );
        assert_close(nearest.cents, 0.0, 0.0001);
    }

    #[test]
    fn temperament_offsets_are_a_anchored_and_applied_to_frequency_math() {
        let temperament = Temperament::from_offsets_cents([
            2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0,
        ])
        .unwrap();
        let c4 = "C4".parse::<Note>().unwrap();
        let a4 = "A4".parse::<Note>().unwrap();

        assert_close(temperament.offsets_cents()[9], 0.0, 0.0001);
        assert_close(temperament.offsets_cents()[0], -9.0, 0.0001);
        assert_close(
            temperament
                .frequency_hz_for_note(a4, DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
            440.0,
            0.0001,
        );
        assert!(
            temperament
                .frequency_hz_for_note(c4, DEFAULT_REFERENCE_A_HZ)
                .unwrap()
                < c4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap()
        );
    }

    #[test]
    fn tempered_tuning_model_relabels_nearest_note_with_tempered_reference_frequency() {
        let temperament = Temperament::from_offset_slice(&[
            10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        ])
        .unwrap();
        let tuning = TuningModel::with_temperament(DEFAULT_REFERENCE_A_HZ, 0, temperament).unwrap();
        let c4 = "C4".parse::<Note>().unwrap();
        let c4_frequency_hz = tuning.frequency_hz_for_sounding_note(c4).unwrap();

        let nearest = tuning
            .nearest_displayed_note_for_frequency(c4_frequency_hz)
            .unwrap();
        assert_eq!(nearest.note.to_string(), "C4");
        assert_close(nearest.reference_frequency_hz, c4_frequency_hz, 0.0001);
        assert_close(nearest.cents, 0.0, 0.0001);
    }

    #[test]
    fn rejects_invalid_temperament_offsets() {
        assert_eq!(
            Temperament::from_offset_slice(&[0.0; 11]).unwrap_err(),
            TemperamentError::InvalidOffsetCount
        );
        assert_eq!(
            Temperament::from_offset_slice(&[
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 101.0,
            ])
            .unwrap_err(),
            TemperamentError::OffsetOutOfRange
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
