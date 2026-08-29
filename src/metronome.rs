use crate::reference_tone::ToneGeneratorError;
use crate::shared_audio::SharedAudioMixer;
use std::error::Error;
use std::fmt;

pub const MIN_METRONOME_BPM: u16 = 20;
pub const MAX_METRONOME_BPM: u16 = 300;
pub const DEFAULT_METRONOME_BPM: u16 = 100;
pub const DEFAULT_METRONOME_BEATS_PER_BAR: u8 = 4;
pub const DEFAULT_METRONOME_BEAT_UNIT: u8 = 4;
pub const DEFAULT_METRONOME_SUBDIVISION: u8 = 1;
pub const MIN_METRONOME_SUBDIVISION: u8 = 1;
pub const MAX_METRONOME_SUBDIVISION: u8 = 4;

const ACCENT_FREQUENCY_HZ: f64 = 1_760.0;
const REGULAR_FREQUENCY_HZ: f64 = 1_320.0;
const SUBDIVISION_FREQUENCY_HZ: f64 = 880.0;
const ACCENT_GAIN: f32 = 0.26;
const REGULAR_GAIN: f32 = 0.18;
const SUBDIVISION_GAIN: f32 = 0.11;
const ACCENT_DURATION_MS: u32 = 48;
const REGULAR_DURATION_MS: u32 = 32;
const SUBDIVISION_DURATION_MS: u32 = 20;
const CLICK_RAMP_DURATION_MS: u32 = 3;
const SUPPORTED_METRONOME_METERS_TEXT: &str = "2/4, 3/4, 4/4, and 6/8";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MetronomeBpmError {
    OutOfRange,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MetronomeMeterError {
    Unsupported,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MetronomeSubdivisionError {
    OutOfRange,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MetronomeStateError {
    InvalidBpm(MetronomeBpmError),
    InvalidMeter(MetronomeMeterError),
    InvalidSubdivision(MetronomeSubdivisionError),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct MetronomeState {
    pub bpm: u16,
    pub beats_per_bar: u8,
    pub beat_unit: u8,
    pub subdivision: u8,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct MetronomeBeat {
    pub beat_in_bar: u8,
    pub beats_per_bar: u8,
    pub beat_unit: u8,
    pub subdivision_step: u8,
    pub subdivision: u8,
    pub accented: bool,
}

#[derive(Clone, Debug)]
pub struct ActiveMetronome {
    state: MetronomeState,
    frames_per_pulse: usize,
    frames_until_next_pulse: usize,
    next_beat_in_bar: u8,
    next_subdivision_step: u8,
    accent_pulse: PulseSpec,
    regular_pulse: PulseSpec,
    subdivision_pulse: PulseSpec,
}

#[derive(Clone, Copy, Debug)]
struct PulseSpec {
    frequency_hz: f64,
    duration_frames: usize,
    peak_gain: f32,
    ramp_frames: usize,
}

impl MetronomeState {
    pub fn new(
        bpm: u16,
        beats_per_bar: u8,
        beat_unit: u8,
        subdivision: u8,
    ) -> Result<Self, MetronomeStateError> {
        let (beats_per_bar, beat_unit) = validate_metronome_meter(beats_per_bar, beat_unit)
            .map_err(MetronomeStateError::InvalidMeter)?;

        Ok(Self {
            bpm: validate_metronome_bpm(bpm).map_err(MetronomeStateError::InvalidBpm)?,
            beats_per_bar,
            beat_unit,
            subdivision: validate_metronome_subdivision(subdivision)
                .map_err(MetronomeStateError::InvalidSubdivision)?,
        })
    }

    pub fn downbeat(self) -> MetronomeBeat {
        MetronomeBeat::new(1, self.beats_per_bar, self.beat_unit, 1, self.subdivision)
    }
}

impl fmt::Display for MetronomeBpmError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            MetronomeBpmError::OutOfRange => write!(
                f,
                "metronome BPM must be within {MIN_METRONOME_BPM}..={MAX_METRONOME_BPM}"
            ),
        }
    }
}

impl Error for MetronomeBpmError {}

impl fmt::Display for MetronomeMeterError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            MetronomeMeterError::Unsupported => write!(
                f,
                "supported metronome meters are {SUPPORTED_METRONOME_METERS_TEXT}"
            ),
        }
    }
}

impl Error for MetronomeMeterError {}

impl fmt::Display for MetronomeSubdivisionError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            MetronomeSubdivisionError::OutOfRange => write!(
                f,
                "metronome subdivision must be within {MIN_METRONOME_SUBDIVISION}..={MAX_METRONOME_SUBDIVISION}"
            ),
        }
    }
}

impl Error for MetronomeSubdivisionError {}

impl fmt::Display for MetronomeStateError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            MetronomeStateError::InvalidBpm(error) => write!(f, "{error}"),
            MetronomeStateError::InvalidMeter(error) => write!(f, "{error}"),
            MetronomeStateError::InvalidSubdivision(error) => write!(f, "{error}"),
        }
    }
}

impl Error for MetronomeStateError {}

impl ActiveMetronome {
    pub fn start(
        sample_rate_hz: u32,
        state: MetronomeState,
        mixer: &mut SharedAudioMixer,
    ) -> Result<(Self, MetronomeBeat), MetronomeStartError> {
        let mut metronome = Self::new(sample_rate_hz, state);
        let initial_beat = state.downbeat();

        metronome.schedule_beat(mixer, 0, initial_beat)?;
        (metronome.next_beat_in_bar, metronome.next_subdivision_step) = advance_metronome_position(
            initial_beat.beat_in_bar,
            initial_beat.subdivision_step,
            state.beats_per_bar,
            state.subdivision,
        );
        metronome.frames_until_next_pulse = metronome.frames_per_pulse;

        Ok((metronome, initial_beat))
    }

    pub fn state(&self) -> MetronomeState {
        self.state
    }

    pub fn schedule_chunk(
        &mut self,
        mixer: &mut SharedAudioMixer,
        chunk_frames: usize,
    ) -> Result<Vec<MetronomeBeat>, ToneGeneratorError> {
        if chunk_frames == 0 {
            return Ok(Vec::new());
        }

        let mut events = Vec::new();
        let mut beat_offset = self.frames_until_next_pulse;
        let mut beat_in_bar = self.next_beat_in_bar;
        let mut subdivision_step = self.next_subdivision_step;

        while beat_offset < chunk_frames {
            let beat = MetronomeBeat::new(
                beat_in_bar,
                self.state.beats_per_bar,
                self.state.beat_unit,
                subdivision_step,
                self.state.subdivision,
            );
            self.schedule_beat(mixer, beat_offset, beat)?;
            events.push(beat);

            (beat_in_bar, subdivision_step) = advance_metronome_position(
                beat_in_bar,
                subdivision_step,
                self.state.beats_per_bar,
                self.state.subdivision,
            );
            beat_offset += self.frames_per_pulse;
        }

        self.next_beat_in_bar = beat_in_bar;
        self.next_subdivision_step = subdivision_step;
        self.frames_until_next_pulse = beat_offset.saturating_sub(chunk_frames);

        Ok(events)
    }

    fn new(sample_rate_hz: u32, state: MetronomeState) -> Self {
        let sample_rate_hz = sample_rate_hz.max(1);

        Self {
            state,
            frames_per_pulse: ((sample_rate_hz as f64 * 60.0)
                / (state.bpm as f64 * state.subdivision as f64))
                .round()
                .max(1.0) as usize,
            frames_until_next_pulse: 0,
            next_beat_in_bar: 1,
            next_subdivision_step: 1,
            accent_pulse: PulseSpec::new(
                sample_rate_hz,
                ACCENT_FREQUENCY_HZ,
                ACCENT_DURATION_MS,
                ACCENT_GAIN,
                CLICK_RAMP_DURATION_MS,
            ),
            regular_pulse: PulseSpec::new(
                sample_rate_hz,
                REGULAR_FREQUENCY_HZ,
                REGULAR_DURATION_MS,
                REGULAR_GAIN,
                CLICK_RAMP_DURATION_MS,
            ),
            subdivision_pulse: PulseSpec::new(
                sample_rate_hz,
                SUBDIVISION_FREQUENCY_HZ,
                SUBDIVISION_DURATION_MS,
                SUBDIVISION_GAIN,
                CLICK_RAMP_DURATION_MS,
            ),
        }
    }

    fn schedule_beat(
        &self,
        mixer: &mut SharedAudioMixer,
        start_after_frames: usize,
        beat: MetronomeBeat,
    ) -> Result<(), ToneGeneratorError> {
        let pulse = if beat.accented {
            self.accent_pulse
        } else if beat.is_primary() {
            self.regular_pulse
        } else {
            self.subdivision_pulse
        };

        pulse.schedule(mixer, start_after_frames)
    }
}

#[derive(Debug)]
pub enum MetronomeStartError {
    InvalidPulse(ToneGeneratorError),
}

impl fmt::Display for MetronomeStartError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            MetronomeStartError::InvalidPulse(ToneGeneratorError::InvalidFrequency) => {
                write!(
                    f,
                    "metronome click generator rejected a built-in click frequency"
                )
            }
        }
    }
}

impl Error for MetronomeStartError {}

impl From<ToneGeneratorError> for MetronomeStartError {
    fn from(value: ToneGeneratorError) -> Self {
        Self::InvalidPulse(value)
    }
}

impl MetronomeBeat {
    fn new(
        beat_in_bar: u8,
        beats_per_bar: u8,
        beat_unit: u8,
        subdivision_step: u8,
        subdivision: u8,
    ) -> Self {
        Self {
            beat_in_bar,
            beats_per_bar,
            beat_unit,
            subdivision_step,
            subdivision,
            accented: beat_in_bar == 1 && subdivision_step == 1,
        }
    }

    fn is_primary(self) -> bool {
        self.subdivision_step == 1
    }
}

impl PulseSpec {
    fn new(
        sample_rate_hz: u32,
        frequency_hz: f64,
        duration_ms: u32,
        peak_gain: f32,
        ramp_duration_ms: u32,
    ) -> Self {
        Self {
            frequency_hz,
            duration_frames: frames_from_milliseconds(sample_rate_hz, duration_ms),
            peak_gain,
            ramp_frames: frames_from_milliseconds(sample_rate_hz, ramp_duration_ms),
        }
    }

    fn schedule(
        self,
        mixer: &mut SharedAudioMixer,
        start_after_frames: usize,
    ) -> Result<(), ToneGeneratorError> {
        mixer.schedule_timed_pulse(
            start_after_frames,
            self.frequency_hz,
            self.duration_frames,
            self.peak_gain,
            self.ramp_frames,
        )
    }
}

pub fn validate_metronome_bpm(bpm: u16) -> Result<u16, MetronomeBpmError> {
    if !(MIN_METRONOME_BPM..=MAX_METRONOME_BPM).contains(&bpm) {
        return Err(MetronomeBpmError::OutOfRange);
    }

    Ok(bpm)
}

pub fn validate_metronome_meter(
    beats_per_bar: u8,
    beat_unit: u8,
) -> Result<(u8, u8), MetronomeMeterError> {
    if !matches!(
        (beats_per_bar, beat_unit),
        (2, 4) | (3, 4) | (4, 4) | (6, 8)
    ) {
        return Err(MetronomeMeterError::Unsupported);
    }

    Ok((beats_per_bar, beat_unit))
}

pub fn validate_metronome_subdivision(subdivision: u8) -> Result<u8, MetronomeSubdivisionError> {
    if !(MIN_METRONOME_SUBDIVISION..=MAX_METRONOME_SUBDIVISION).contains(&subdivision) {
        return Err(MetronomeSubdivisionError::OutOfRange);
    }

    Ok(subdivision)
}

fn frames_from_milliseconds(sample_rate_hz: u32, milliseconds: u32) -> usize {
    ((sample_rate_hz as f64 * milliseconds as f64) / 1000.0)
        .round()
        .max(1.0) as usize
}

fn wrap_beat_in_bar(beat_in_bar: u8, beats_per_bar: u8) -> u8 {
    if beat_in_bar >= beats_per_bar {
        1
    } else {
        beat_in_bar + 1
    }
}

fn advance_metronome_position(
    beat_in_bar: u8,
    subdivision_step: u8,
    beats_per_bar: u8,
    subdivision: u8,
) -> (u8, u8) {
    if subdivision_step >= subdivision {
        (wrap_beat_in_bar(beat_in_bar, beats_per_bar), 1)
    } else {
        (beat_in_bar, subdivision_step + 1)
    }
}

#[cfg(test)]
mod tests {
    use super::{
        ActiveMetronome, MetronomeBeat, MetronomeBpmError, MetronomeMeterError, MetronomeState,
        MetronomeStateError, MetronomeSubdivisionError, DEFAULT_METRONOME_BEATS_PER_BAR,
        DEFAULT_METRONOME_BEAT_UNIT, DEFAULT_METRONOME_SUBDIVISION, MAX_METRONOME_BPM,
        MAX_METRONOME_SUBDIVISION, MIN_METRONOME_BPM,
    };
    use crate::reference_tone::DEFAULT_SAMPLE_RATE_HZ;
    use crate::shared_audio::SharedAudioMixer;

    fn peak_abs(samples: &[f32]) -> f32 {
        samples
            .iter()
            .fold(0.0_f32, |peak, sample| peak.max(sample.abs()))
    }

    #[test]
    fn validates_supported_bpm_range() {
        assert_eq!(
            super::validate_metronome_bpm(MIN_METRONOME_BPM - 1).unwrap_err(),
            MetronomeBpmError::OutOfRange
        );
        assert_eq!(
            super::validate_metronome_bpm(MAX_METRONOME_BPM + 1).unwrap_err(),
            MetronomeBpmError::OutOfRange
        );
        assert_eq!(super::validate_metronome_bpm(120).unwrap(), 120);
    }

    #[test]
    fn validates_supported_meter_and_subdivision_values() {
        assert_eq!(
            MetronomeState::new(120, 5, 4, DEFAULT_METRONOME_SUBDIVISION).unwrap_err(),
            MetronomeStateError::InvalidMeter(MetronomeMeterError::Unsupported)
        );
        assert_eq!(
            MetronomeState::new(
                120,
                DEFAULT_METRONOME_BEATS_PER_BAR,
                DEFAULT_METRONOME_BEAT_UNIT,
                MAX_METRONOME_SUBDIVISION + 1,
            )
            .unwrap_err(),
            MetronomeStateError::InvalidSubdivision(MetronomeSubdivisionError::OutOfRange)
        );
        assert_eq!(
            MetronomeState::new(120, 6, 8, 3).unwrap(),
            MetronomeState {
                bpm: 120,
                beats_per_bar: 6,
                beat_unit: 8,
                subdivision: 3,
            }
        );
    }

    #[test]
    fn start_schedules_an_immediate_downbeat_and_wraps_after_four_beats() {
        let mut mixer = SharedAudioMixer::new(DEFAULT_SAMPLE_RATE_HZ, 0.0, 1);
        let state = MetronomeState::new(
            120,
            DEFAULT_METRONOME_BEATS_PER_BAR,
            DEFAULT_METRONOME_BEAT_UNIT,
            DEFAULT_METRONOME_SUBDIVISION,
        )
        .unwrap();
        let (mut metronome, downbeat) =
            ActiveMetronome::start(DEFAULT_SAMPLE_RATE_HZ, state, &mut mixer).unwrap();

        assert_eq!(
            downbeat,
            MetronomeBeat {
                beat_in_bar: 1,
                beats_per_bar: 4,
                beat_unit: 4,
                subdivision_step: 1,
                subdivision: 1,
                accented: true,
            }
        );

        let beat_frames = metronome.frames_per_pulse;

        assert!(metronome
            .schedule_chunk(&mut mixer, beat_frames)
            .unwrap()
            .is_empty());
        let mut first_chunk = vec![0.0; beat_frames];
        mixer.render_mono(&mut first_chunk);
        assert!(first_chunk.iter().any(|sample| sample.abs() > 0.01));

        let mut emitted_beats = Vec::new();

        for _ in 0..4 {
            let chunk_events = metronome.schedule_chunk(&mut mixer, beat_frames).unwrap();
            emitted_beats.extend(chunk_events);

            let mut chunk = vec![0.0; beat_frames];
            mixer.render_mono(&mut chunk);
        }

        assert_eq!(
            emitted_beats,
            vec![
                MetronomeBeat {
                    beat_in_bar: 2,
                    beats_per_bar: 4,
                    beat_unit: 4,
                    subdivision_step: 1,
                    subdivision: 1,
                    accented: false,
                },
                MetronomeBeat {
                    beat_in_bar: 3,
                    beats_per_bar: 4,
                    beat_unit: 4,
                    subdivision_step: 1,
                    subdivision: 1,
                    accented: false,
                },
                MetronomeBeat {
                    beat_in_bar: 4,
                    beats_per_bar: 4,
                    beat_unit: 4,
                    subdivision_step: 1,
                    subdivision: 1,
                    accented: false,
                },
                MetronomeBeat {
                    beat_in_bar: 1,
                    beats_per_bar: 4,
                    beat_unit: 4,
                    subdivision_step: 1,
                    subdivision: 1,
                    accented: true,
                },
            ]
        );
    }

    #[test]
    fn subdivision_pulses_land_before_the_next_primary_beat() {
        let mut mixer = SharedAudioMixer::new(DEFAULT_SAMPLE_RATE_HZ, 0.0, 1);
        let state = MetronomeState::new(120, 3, 4, 3).unwrap();
        let (mut metronome, _) =
            ActiveMetronome::start(DEFAULT_SAMPLE_RATE_HZ, state, &mut mixer).unwrap();
        let beat_frames = metronome.frames_per_pulse;

        assert!(metronome
            .schedule_chunk(&mut mixer, beat_frames)
            .unwrap()
            .is_empty());

        let mut emitted_pulses = Vec::new();
        for _ in 0..5 {
            let chunk_events = metronome.schedule_chunk(&mut mixer, beat_frames).unwrap();
            emitted_pulses.extend(chunk_events);

            let mut chunk = vec![0.0; beat_frames];
            mixer.render_mono(&mut chunk);
        }

        assert_eq!(
            emitted_pulses,
            vec![
                MetronomeBeat {
                    beat_in_bar: 1,
                    beats_per_bar: 3,
                    beat_unit: 4,
                    subdivision_step: 2,
                    subdivision: 3,
                    accented: false,
                },
                MetronomeBeat {
                    beat_in_bar: 1,
                    beats_per_bar: 3,
                    beat_unit: 4,
                    subdivision_step: 3,
                    subdivision: 3,
                    accented: false,
                },
                MetronomeBeat {
                    beat_in_bar: 2,
                    beats_per_bar: 3,
                    beat_unit: 4,
                    subdivision_step: 1,
                    subdivision: 3,
                    accented: false,
                },
                MetronomeBeat {
                    beat_in_bar: 2,
                    beats_per_bar: 3,
                    beat_unit: 4,
                    subdivision_step: 2,
                    subdivision: 3,
                    accented: false,
                },
                MetronomeBeat {
                    beat_in_bar: 2,
                    beats_per_bar: 3,
                    beat_unit: 4,
                    subdivision_step: 3,
                    subdivision: 3,
                    accented: false,
                },
            ]
        );
    }

    #[test]
    fn beat_one_click_is_stronger_than_regular_beats_and_regular_beats_are_stronger_than_subdivisions(
    ) {
        let mut mixer = SharedAudioMixer::new(DEFAULT_SAMPLE_RATE_HZ, 0.0, 1);
        let state = MetronomeState::new(120, 4, 4, 2).unwrap();
        let (mut metronome, _) =
            ActiveMetronome::start(DEFAULT_SAMPLE_RATE_HZ, state, &mut mixer).unwrap();
        let beat_frames = metronome.frames_per_pulse;

        assert!(metronome
            .schedule_chunk(&mut mixer, beat_frames)
            .unwrap()
            .is_empty());
        let mut downbeat_chunk = vec![0.0; beat_frames];
        mixer.render_mono(&mut downbeat_chunk);

        let subdivision_pulse = metronome.schedule_chunk(&mut mixer, beat_frames).unwrap();
        assert_eq!(
            subdivision_pulse,
            vec![MetronomeBeat {
                beat_in_bar: 1,
                beats_per_bar: 4,
                beat_unit: 4,
                subdivision_step: 2,
                subdivision: 2,
                accented: false,
            }]
        );

        let mut subdivision_chunk = vec![0.0; beat_frames];
        mixer.render_mono(&mut subdivision_chunk);

        let second_beat = metronome.schedule_chunk(&mut mixer, beat_frames).unwrap();
        assert_eq!(
            second_beat,
            vec![MetronomeBeat {
                beat_in_bar: 2,
                beats_per_bar: 4,
                beat_unit: 4,
                subdivision_step: 1,
                subdivision: 2,
                accented: false,
            }]
        );

        let mut regular_chunk = vec![0.0; beat_frames];
        mixer.render_mono(&mut regular_chunk);

        assert!(
            peak_abs(&downbeat_chunk) > peak_abs(&regular_chunk),
            "expected accented beat peak {} to exceed regular beat peak {}",
            peak_abs(&downbeat_chunk),
            peak_abs(&regular_chunk)
        );
        assert!(
            peak_abs(&regular_chunk) > peak_abs(&subdivision_chunk),
            "expected regular beat peak {} to exceed subdivision peak {}",
            peak_abs(&regular_chunk),
            peak_abs(&subdivision_chunk)
        );
    }
}
