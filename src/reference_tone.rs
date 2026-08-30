use crate::note::Note;
use serde::Serialize;
use std::f64::consts::TAU;
use std::fmt;

pub const DEFAULT_OUTPUT_LEVEL: f32 = 0.18;
pub const DEFAULT_RAMP_DURATION_MS: u32 = 12;
pub const DEFAULT_SAMPLE_RATE_HZ: u32 = 48_000;
pub const MAX_REFERENCE_INTERVALS: usize = 3;
pub const MAX_REFERENCE_INTERVAL_SEMITONES: i32 = 24;
pub const DEFAULT_REFERENCE_SCENE_ID: ReferenceToneSceneId = ReferenceToneSceneId::Blend;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ReferenceToneScene {
    root_note: Note,
    intervals_semitones: Vec<i32>,
    scene_id: ReferenceToneSceneId,
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ReferenceToneSceneId {
    #[default]
    Blend,
    Pedal,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ReferenceToneSceneError {
    TooManyIntervals(usize),
    InvalidInterval(i32),
    DuplicateInterval(i32),
    OutOfSupportedRange {
        root_note: Note,
        interval_semitones: i32,
    },
}

#[derive(Clone, Debug)]
pub struct ReferenceToneGenerator {
    sample_rate_hz: u32,
    max_gain: f32,
    gain_step_per_sample: f32,
    voices: Vec<ActiveVoice>,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub(crate) struct ReferenceToneVoice {
    pub note: Note,
    pub frequency_hz: f64,
    pub mix_level: f32,
    pub waveform: ReferenceToneWaveform,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub(crate) struct ReferenceToneVoicePlan {
    pub note: Note,
    pub mix_level: f32,
    pub waveform: ReferenceToneWaveform,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum ReferenceToneWaveform {
    Sine,
    Warm,
}

#[derive(Clone, Debug)]
struct ActiveVoice {
    note: Note,
    phase_radians: f64,
    phase_step_radians: f64,
    current_gain: f32,
    target_gain: f32,
    waveform: ReferenceToneWaveform,
    harmonic_gains: [f32; 3],
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum ToneGeneratorError {
    InvalidFrequency,
}

impl ReferenceToneScene {
    pub fn new(
        root_note: Note,
        intervals_semitones: Vec<i32>,
    ) -> Result<Self, ReferenceToneSceneError> {
        Self::with_scene_id(root_note, intervals_semitones, DEFAULT_REFERENCE_SCENE_ID)
    }

    pub fn with_scene_id(
        root_note: Note,
        mut intervals_semitones: Vec<i32>,
        scene_id: ReferenceToneSceneId,
    ) -> Result<Self, ReferenceToneSceneError> {
        if intervals_semitones.len() > MAX_REFERENCE_INTERVALS {
            return Err(ReferenceToneSceneError::TooManyIntervals(
                intervals_semitones.len(),
            ));
        }

        intervals_semitones.sort_unstable();

        for (index, interval_semitones) in intervals_semitones.iter().copied().enumerate() {
            if !(1..=MAX_REFERENCE_INTERVAL_SEMITONES).contains(&interval_semitones) {
                return Err(ReferenceToneSceneError::InvalidInterval(interval_semitones));
            }
            if intervals_semitones[..index].contains(&interval_semitones) {
                return Err(ReferenceToneSceneError::DuplicateInterval(
                    interval_semitones,
                ));
            }
            if resolve_interval_note(root_note, interval_semitones).is_none() {
                return Err(ReferenceToneSceneError::OutOfSupportedRange {
                    root_note,
                    interval_semitones,
                });
            }
        }

        Ok(Self {
            root_note,
            intervals_semitones,
            scene_id,
        })
    }

    pub fn root_note(&self) -> Note {
        self.root_note
    }

    pub fn intervals_semitones(&self) -> &[i32] {
        &self.intervals_semitones
    }

    pub fn scene_id(&self) -> ReferenceToneSceneId {
        self.scene_id
    }

    #[cfg(test)]
    pub(crate) fn notes(&self) -> Vec<Note> {
        let mut notes = Vec::with_capacity(1 + self.intervals_semitones.len());
        notes.push(self.root_note);

        for interval_semitones in &self.intervals_semitones {
            let interval_note = resolve_interval_note(self.root_note, *interval_semitones)
                .expect("validated reference tone scene produced an unsupported note");
            notes.push(interval_note);
        }

        notes
    }

    pub(crate) fn voice_plan(&self) -> Vec<ReferenceToneVoicePlan> {
        if self.intervals_semitones.is_empty() {
            return match self.scene_id {
                ReferenceToneSceneId::Blend => vec![ReferenceToneVoicePlan {
                    note: self.root_note,
                    mix_level: 1.0,
                    waveform: ReferenceToneWaveform::Sine,
                }],
                ReferenceToneSceneId::Pedal => build_pedal_single_voice_plan(self.root_note),
            };
        }

        match self.scene_id {
            ReferenceToneSceneId::Blend => build_blend_voice_plan(self),
            ReferenceToneSceneId::Pedal => build_pedal_voice_plan(self),
        }
    }
}

impl ReferenceToneSceneId {
    pub fn parse(input: &str) -> Option<Self> {
        match input.trim() {
            "blend" => Some(Self::Blend),
            "pedal" => Some(Self::Pedal),
            _ => None,
        }
    }

    pub fn as_str(self) -> &'static str {
        match self {
            Self::Blend => "blend",
            Self::Pedal => "pedal",
        }
    }

    pub fn is_default(&self) -> bool {
        *self == DEFAULT_REFERENCE_SCENE_ID
    }

    pub fn supported_ids() -> &'static [&'static str] {
        &["blend", "pedal"]
    }
}

impl ReferenceToneVoice {
    pub(crate) fn new(
        note: Note,
        frequency_hz: f64,
        mix_level: f32,
        waveform: ReferenceToneWaveform,
    ) -> Self {
        Self {
            note,
            frequency_hz,
            mix_level,
            waveform,
        }
    }

    pub(crate) fn sine(note: Note, frequency_hz: f64) -> Self {
        Self::new(note, frequency_hz, 1.0, ReferenceToneWaveform::Sine)
    }
}

impl fmt::Display for ReferenceToneSceneError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ReferenceToneSceneError::TooManyIntervals(count) => write!(
                f,
                "intervals_semitones supports at most {MAX_REFERENCE_INTERVALS} entries, got {count}"
            ),
            ReferenceToneSceneError::InvalidInterval(interval_semitones) => write!(
                f,
                "interval semitone offset {interval_semitones} is outside the supported range 1..={MAX_REFERENCE_INTERVAL_SEMITONES}"
            ),
            ReferenceToneSceneError::DuplicateInterval(interval_semitones) => write!(
                f,
                "interval semitone offset {interval_semitones} was provided more than once"
            ),
            ReferenceToneSceneError::OutOfSupportedRange {
                root_note,
                interval_semitones,
            } => write!(
                f,
                "interval {interval_semitones} above {root_note} is outside the supported note range"
            ),
        }
    }
}

impl std::error::Error for ReferenceToneSceneError {}

impl ReferenceToneGenerator {
    pub fn new(sample_rate_hz: u32, max_gain: f32, ramp_duration_ms: u32) -> Self {
        let sample_rate_hz = sample_rate_hz.max(1);
        let max_gain = max_gain.clamp(0.0, 1.0);
        let ramp_samples = ((sample_rate_hz as f32 * ramp_duration_ms as f32) / 1000.0)
            .round()
            .max(1.0);

        Self {
            sample_rate_hz,
            max_gain,
            gain_step_per_sample: if max_gain <= 0.0 {
                0.0
            } else {
                max_gain / ramp_samples
            },
            voices: Vec::new(),
        }
    }

    pub fn play_notes(&mut self, notes: &[(Note, f64)]) -> Result<(), ToneGeneratorError> {
        let voices = notes
            .iter()
            .map(|(note, frequency_hz)| ReferenceToneVoice::sine(*note, *frequency_hz))
            .collect::<Vec<_>>();
        self.play_voices(&voices)
    }

    pub(crate) fn play_voices(
        &mut self,
        voices: &[ReferenceToneVoice],
    ) -> Result<(), ToneGeneratorError> {
        if voices.is_empty() {
            self.stop();
            return Ok(());
        }

        let mut normalized_voices = Vec::with_capacity(voices.len());
        let mut total_mix_level = 0.0_f32;

        for voice in voices {
            if !voice.frequency_hz.is_finite() || voice.frequency_hz <= 0.0 {
                return Err(ToneGeneratorError::InvalidFrequency);
            }

            let mix_level = if voice.mix_level.is_finite() {
                voice.mix_level.clamp(0.0, 1.0)
            } else {
                0.0
            };
            if mix_level <= 0.0 {
                continue;
            }

            total_mix_level += mix_level;
            normalized_voices.push(ReferenceToneVoice {
                note: voice.note,
                frequency_hz: voice.frequency_hz,
                mix_level,
                waveform: voice.waveform,
            });
        }

        if normalized_voices.is_empty() {
            self.stop();
            return Ok(());
        }

        for voice in &mut self.voices {
            voice.target_gain = 0.0;
        }

        for voice in normalized_voices {
            let target_gain = self.max_gain * voice.mix_level / total_mix_level;

            if let Some(existing_voice) = self
                .voices
                .iter_mut()
                .find(|active| active.note == voice.note && active.waveform == voice.waveform)
            {
                existing_voice.update_rendering(
                    self.sample_rate_hz,
                    voice.frequency_hz,
                    voice.waveform,
                    target_gain,
                );
                continue;
            }

            self.voices.push(ActiveVoice::new(
                voice.note,
                self.sample_rate_hz,
                voice.frequency_hz,
                voice.waveform,
                target_gain,
            ));
        }

        Ok(())
    }

    pub fn stop(&mut self) {
        for voice in &mut self.voices {
            voice.target_gain = 0.0;
        }
    }

    pub fn silence_immediately(&mut self) {
        self.voices.clear();
    }

    pub fn is_audible(&self) -> bool {
        self.voices
            .iter()
            .any(|voice| voice.current_gain > 0.0 || voice.target_gain > 0.0)
    }

    pub fn is_idle(&self) -> bool {
        self.voices.is_empty()
    }

    pub fn active_notes(&self) -> Vec<Note> {
        self.voices.iter().map(|voice| voice.note).collect()
    }

    pub fn render_interleaved(&mut self, channels: usize, output: &mut [f32]) {
        if channels == 0 {
            return;
        }

        debug_assert_eq!(output.len() % channels, 0);

        for frame in output.chunks_exact_mut(channels) {
            let sample = self.next_sample();
            for channel in frame {
                *channel = sample;
            }
        }
    }

    pub fn render_mono(&mut self, output: &mut [f32]) {
        for sample in output.iter_mut() {
            *sample = self.next_sample();
        }
    }

    fn next_sample(&mut self) -> f32 {
        if self.voices.is_empty() {
            return 0.0;
        }

        let mut sample = 0.0_f32;

        for voice in &mut self.voices {
            voice.advance_gain(self.gain_step_per_sample);
            if voice.current_gain <= 0.0 && voice.target_gain <= 0.0 {
                continue;
            }

            sample += voice.sample() * voice.current_gain;
            voice.phase_radians = (voice.phase_radians + voice.phase_step_radians).rem_euclid(TAU);
        }

        self.voices
            .retain(|voice| voice.current_gain > 0.0 || voice.target_gain > 0.0);

        sample
    }
}

impl ActiveVoice {
    fn new(
        note: Note,
        sample_rate_hz: u32,
        frequency_hz: f64,
        waveform: ReferenceToneWaveform,
        target_gain: f32,
    ) -> Self {
        let mut voice = Self {
            note,
            phase_radians: 0.0,
            phase_step_radians: 0.0,
            current_gain: 0.0,
            target_gain: 0.0,
            waveform,
            harmonic_gains: [1.0, 0.0, 0.0],
        };
        voice.update_rendering(sample_rate_hz, frequency_hz, waveform, target_gain);
        voice
    }

    fn update_rendering(
        &mut self,
        sample_rate_hz: u32,
        frequency_hz: f64,
        waveform: ReferenceToneWaveform,
        target_gain: f32,
    ) {
        self.phase_step_radians = TAU * frequency_hz / sample_rate_hz.max(1) as f64;
        self.target_gain = target_gain;
        self.waveform = waveform;
        self.harmonic_gains = waveform.harmonic_gains(frequency_hz, sample_rate_hz);
    }

    fn advance_gain(&mut self, gain_step_per_sample: f32) {
        if self.current_gain < self.target_gain {
            self.current_gain = (self.current_gain + gain_step_per_sample).min(self.target_gain);
        } else if self.current_gain > self.target_gain {
            self.current_gain = (self.current_gain - gain_step_per_sample).max(self.target_gain);
        }
    }

    fn sample(&self) -> f32 {
        let phase = self.phase_radians;
        (phase.sin() as f32) * self.harmonic_gains[0]
            + ((phase * 2.0).sin() as f32) * self.harmonic_gains[1]
            + ((phase * 3.0).sin() as f32) * self.harmonic_gains[2]
    }
}

impl ReferenceToneWaveform {
    fn harmonic_gains(self, frequency_hz: f64, sample_rate_hz: u32) -> [f32; 3] {
        let mut gains = match self {
            Self::Sine => [1.0, 0.0, 0.0],
            Self::Warm => [1.0, 0.18, 0.07],
        };
        let nyquist_hz = sample_rate_hz.max(1) as f64 / 2.0;

        for (index, gain) in gains.iter_mut().enumerate() {
            let harmonic = (index + 1) as f64;
            if frequency_hz * harmonic >= nyquist_hz {
                *gain = 0.0;
            }
        }

        let total_gain: f32 = gains.iter().sum();
        if total_gain <= f32::EPSILON {
            return [1.0, 0.0, 0.0];
        }

        for gain in &mut gains {
            *gain /= total_gain;
        }

        gains
    }
}

fn resolve_interval_note(root_note: Note, interval_semitones: i32) -> Option<Note> {
    Note::from_midi_number(root_note.midi_number() + interval_semitones)
}

fn build_blend_voice_plan(scene: &ReferenceToneScene) -> Vec<ReferenceToneVoicePlan> {
    let mut voices = Vec::with_capacity(1 + scene.intervals_semitones.len());
    voices.push(ReferenceToneVoicePlan {
        note: scene.root_note,
        mix_level: 0.82,
        waveform: ReferenceToneWaveform::Warm,
    });

    for interval_semitones in scene.intervals_semitones() {
        voices.push(ReferenceToneVoicePlan {
            note: resolve_interval_note(scene.root_note, *interval_semitones)
                .expect("validated reference tone scene produced an unsupported note"),
            mix_level: upper_voice_mix_level(*interval_semitones),
            waveform: ReferenceToneWaveform::Sine,
        });
    }

    voices
}

fn build_pedal_voice_plan(scene: &ReferenceToneScene) -> Vec<ReferenceToneVoicePlan> {
    let mut voices = Vec::with_capacity(2 + scene.intervals_semitones.len());
    voices.push(ReferenceToneVoicePlan {
        note: scene.root_note,
        mix_level: 0.68,
        waveform: ReferenceToneWaveform::Warm,
    });

    if let Some(lower_root) = resolve_lower_pedal_root(scene.root_note) {
        voices.push(ReferenceToneVoicePlan {
            note: lower_root,
            mix_level: 0.5,
            waveform: ReferenceToneWaveform::Warm,
        });
    }

    for interval_semitones in scene.intervals_semitones() {
        voices.push(ReferenceToneVoicePlan {
            note: resolve_interval_note(scene.root_note, *interval_semitones)
                .expect("validated reference tone scene produced an unsupported note"),
            mix_level: (upper_voice_mix_level(*interval_semitones) + 0.08).min(1.0),
            waveform: ReferenceToneWaveform::Sine,
        });
    }

    voices
}

fn build_pedal_single_voice_plan(root_note: Note) -> Vec<ReferenceToneVoicePlan> {
    let mut voices = vec![ReferenceToneVoicePlan {
        note: root_note,
        mix_level: 0.74,
        waveform: ReferenceToneWaveform::Warm,
    }];

    if let Some(lower_root) = resolve_lower_pedal_root(root_note) {
        voices.push(ReferenceToneVoicePlan {
            note: lower_root,
            mix_level: 0.56,
            waveform: ReferenceToneWaveform::Warm,
        });
    }

    voices
}

fn resolve_lower_pedal_root(root_note: Note) -> Option<Note> {
    root_note.transposed(-12).ok()
}

fn upper_voice_mix_level(interval_semitones: i32) -> f32 {
    match interval_semitones.rem_euclid(12) {
        3..=5 => 1.0,
        0 | 7 => 0.8,
        2 | 8 | 9 => 0.9,
        _ => 0.86,
    }
}

#[cfg(test)]
mod tests {
    use super::{
        ReferenceToneGenerator, ReferenceToneScene, ReferenceToneSceneError, ReferenceToneSceneId,
        ReferenceToneVoice, ReferenceToneWaveform, ToneGeneratorError, DEFAULT_REFERENCE_SCENE_ID,
        DEFAULT_SAMPLE_RATE_HZ,
    };
    use crate::note::{Note, DEFAULT_REFERENCE_A_HZ};
    use std::f64::consts::TAU;

    fn assert_close(actual: f64, expected: f64, tolerance: f64) {
        let delta = (actual - expected).abs();
        assert!(
            delta <= tolerance,
            "expected {expected} +/- {tolerance}, got {actual} (delta {delta})"
        );
    }

    fn estimate_frequency_hz(samples: &[f32], sample_rate_hz: u32) -> f64 {
        let mut crossings = Vec::new();

        for index in 1..samples.len() {
            let previous = samples[index - 1];
            let current = samples[index];
            if previous < 0.0 && current >= 0.0 {
                let span = (current - previous) as f64;
                let offset = if span.abs() <= f64::EPSILON {
                    0.0
                } else {
                    (-previous as f64 / span).clamp(0.0, 1.0)
                };
                crossings.push((index - 1) as f64 + offset);
            }
        }

        assert!(
            crossings.len() >= 2,
            "not enough zero crossings to estimate frequency"
        );

        let total_period_samples: f64 = crossings
            .windows(2)
            .map(|window| window[1] - window[0])
            .sum();
        let average_period_samples = total_period_samples / (crossings.len() - 1) as f64;

        sample_rate_hz as f64 / average_period_samples
    }

    fn tone_energy_at_frequency_hz(samples: &[f32], sample_rate_hz: u32, frequency_hz: f64) -> f64 {
        let mut real = 0.0;
        let mut imaginary = 0.0;

        for (index, sample) in samples.iter().enumerate() {
            let phase = TAU * frequency_hz * index as f64 / sample_rate_hz as f64;
            real += *sample as f64 * phase.cos();
            imaginary -= *sample as f64 * phase.sin();
        }

        (real.hypot(imaginary)) / samples.len() as f64
    }

    #[test]
    fn reference_tone_scene_sorts_intervals_and_resolves_notes() {
        let a4 = "A4".parse::<Note>().unwrap();
        let scene = ReferenceToneScene::new(a4, vec![12, 7]).unwrap();

        assert_eq!(scene.root_note(), a4);
        assert_eq!(scene.intervals_semitones(), &[7, 12]);
        assert_eq!(scene.scene_id(), DEFAULT_REFERENCE_SCENE_ID);
        assert_eq!(
            scene.notes(),
            vec![
                "A4".parse().unwrap(),
                "E5".parse().unwrap(),
                "A5".parse().unwrap(),
            ]
        );
    }

    #[test]
    fn pedal_scene_adds_a_lower_root_when_supported() {
        let scene = ReferenceToneScene::with_scene_id(
            "A4".parse().unwrap(),
            vec![4, 7],
            ReferenceToneSceneId::Pedal,
        )
        .unwrap();

        assert_eq!(
            scene
                .voice_plan()
                .into_iter()
                .map(|voice| voice.note)
                .collect::<Vec<_>>(),
            vec![
                "A4".parse().unwrap(),
                "A3".parse().unwrap(),
                "C#5".parse().unwrap(),
                "E5".parse().unwrap(),
            ]
        );
    }

    #[test]
    fn pedal_scene_skips_lower_root_when_note_is_already_at_bottom_of_range() {
        let scene = ReferenceToneScene::with_scene_id(
            "C0".parse().unwrap(),
            Vec::new(),
            ReferenceToneSceneId::Pedal,
        )
        .unwrap();

        assert_eq!(
            scene
                .voice_plan()
                .into_iter()
                .map(|voice| voice.note)
                .collect::<Vec<_>>(),
            vec!["C0".parse().unwrap()]
        );
    }

    #[test]
    fn reference_tone_scene_rejects_invalid_interval_shapes() {
        let a4 = "A4".parse::<Note>().unwrap();
        let b8 = "B8".parse::<Note>().unwrap();

        assert_eq!(
            ReferenceToneScene::new(a4, vec![0]).unwrap_err(),
            ReferenceToneSceneError::InvalidInterval(0)
        );
        assert_eq!(
            ReferenceToneScene::new(a4, vec![7, 7]).unwrap_err(),
            ReferenceToneSceneError::DuplicateInterval(7)
        );
        assert_eq!(
            ReferenceToneScene::new(a4, vec![3, 5, 7, 12]).unwrap_err(),
            ReferenceToneSceneError::TooManyIntervals(4)
        );
        assert_eq!(
            ReferenceToneScene::new(b8, vec![1]).unwrap_err(),
            ReferenceToneSceneError::OutOfSupportedRange {
                root_note: b8,
                interval_semitones: 1,
            }
        );
    }

    #[test]
    fn rejects_invalid_frequencies() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.2, 8);
        let a4 = "A4".parse::<Note>().unwrap();

        assert_eq!(
            generator
                .play_voices(&[ReferenceToneVoice::sine(a4, 0.0)])
                .unwrap_err(),
            ToneGeneratorError::InvalidFrequency
        );
    }

    #[test]
    fn generates_requested_frequency_numerically() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 5);
        let a4 = "A4".parse::<Note>().unwrap();
        generator
            .play_notes(&[(a4, a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap())])
            .unwrap();

        let mut warmup = vec![0.0; 2_000];
        generator.render_mono(&mut warmup);

        let mut samples = vec![0.0; DEFAULT_SAMPLE_RATE_HZ as usize];
        generator.render_mono(&mut samples);

        assert_close(
            estimate_frequency_hz(&samples, DEFAULT_SAMPLE_RATE_HZ),
            440.0,
            0.5,
        );
        assert!(samples.iter().all(|sample| sample.abs() <= 0.8001));
    }

    #[test]
    fn mixed_notes_render_requested_frequencies() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 5);
        let a4 = "A4".parse::<Note>().unwrap();
        let e5 = "E5".parse::<Note>().unwrap();
        let c5 = "C5".parse::<Note>().unwrap();

        let a4_frequency_hz = a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap();
        let e5_frequency_hz = e5.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap();
        let c5_frequency_hz = c5.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap();

        generator
            .play_notes(&[(a4, a4_frequency_hz), (e5, e5_frequency_hz)])
            .unwrap();

        let mut warmup = vec![0.0; 2_000];
        generator.render_mono(&mut warmup);

        let mut samples = vec![0.0; DEFAULT_SAMPLE_RATE_HZ as usize];
        generator.render_mono(&mut samples);

        let a4_energy =
            tone_energy_at_frequency_hz(&samples, DEFAULT_SAMPLE_RATE_HZ, a4_frequency_hz);
        let e5_energy =
            tone_energy_at_frequency_hz(&samples, DEFAULT_SAMPLE_RATE_HZ, e5_frequency_hz);
        let c5_energy =
            tone_energy_at_frequency_hz(&samples, DEFAULT_SAMPLE_RATE_HZ, c5_frequency_hz);

        assert!(
            a4_energy > c5_energy * 8.0,
            "A4 energy {a4_energy} did not dominate C5 energy {c5_energy}"
        );
        assert!(
            e5_energy > c5_energy * 8.0,
            "E5 energy {e5_energy} did not dominate C5 energy {c5_energy}"
        );
        assert!(samples.iter().all(|sample| sample.abs() <= 0.8001));
    }

    #[test]
    fn triad_notes_render_requested_frequencies() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 5);
        let a4 = "A4".parse::<Note>().unwrap();
        let c_sharp5 = "C#5".parse::<Note>().unwrap();
        let e5 = "E5".parse::<Note>().unwrap();
        let g5 = "G5".parse::<Note>().unwrap();

        let a4_frequency_hz = a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap();
        let c_sharp5_frequency_hz = c_sharp5.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap();
        let e5_frequency_hz = e5.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap();
        let g5_frequency_hz = g5.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap();

        generator
            .play_notes(&[
                (a4, a4_frequency_hz),
                (c_sharp5, c_sharp5_frequency_hz),
                (e5, e5_frequency_hz),
            ])
            .unwrap();

        let mut warmup = vec![0.0; 2_000];
        generator.render_mono(&mut warmup);

        let mut samples = vec![0.0; DEFAULT_SAMPLE_RATE_HZ as usize];
        generator.render_mono(&mut samples);

        let a4_energy =
            tone_energy_at_frequency_hz(&samples, DEFAULT_SAMPLE_RATE_HZ, a4_frequency_hz);
        let c_sharp5_energy =
            tone_energy_at_frequency_hz(&samples, DEFAULT_SAMPLE_RATE_HZ, c_sharp5_frequency_hz);
        let e5_energy =
            tone_energy_at_frequency_hz(&samples, DEFAULT_SAMPLE_RATE_HZ, e5_frequency_hz);
        let g5_energy =
            tone_energy_at_frequency_hz(&samples, DEFAULT_SAMPLE_RATE_HZ, g5_frequency_hz);

        assert!(
            a4_energy > g5_energy * 8.0,
            "A4 energy {a4_energy} did not dominate G5 energy {g5_energy}"
        );
        assert!(
            c_sharp5_energy > g5_energy * 8.0,
            "C#5 energy {c_sharp5_energy} did not dominate G5 energy {g5_energy}"
        );
        assert!(
            e5_energy > g5_energy * 8.0,
            "E5 energy {e5_energy} did not dominate G5 energy {g5_energy}"
        );
        assert!(samples.iter().all(|sample| sample.abs() <= 0.8001));
    }

    #[test]
    fn pedal_scene_emphasizes_a_lower_root_anchor_without_clipping() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 5);
        let a3 = "A3".parse::<Note>().unwrap();
        let a4 = "A4".parse::<Note>().unwrap();
        let c_sharp5 = "C#5".parse::<Note>().unwrap();
        let e5 = "E5".parse::<Note>().unwrap();

        generator
            .play_voices(&[
                ReferenceToneVoice::new(
                    a4,
                    a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap(),
                    0.68,
                    ReferenceToneWaveform::Warm,
                ),
                ReferenceToneVoice::new(
                    a3,
                    a3.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap(),
                    0.5,
                    ReferenceToneWaveform::Warm,
                ),
                ReferenceToneVoice::sine(
                    c_sharp5,
                    c_sharp5.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap(),
                ),
                ReferenceToneVoice::sine(e5, e5.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap()),
            ])
            .unwrap();

        let mut warmup = vec![0.0; 2_000];
        generator.render_mono(&mut warmup);

        let mut samples = vec![0.0; DEFAULT_SAMPLE_RATE_HZ as usize];
        generator.render_mono(&mut samples);

        let a3_energy = tone_energy_at_frequency_hz(
            &samples,
            DEFAULT_SAMPLE_RATE_HZ,
            a3.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap(),
        );
        let f_sharp3_energy = tone_energy_at_frequency_hz(
            &samples,
            DEFAULT_SAMPLE_RATE_HZ,
            "F#3"
                .parse::<Note>()
                .unwrap()
                .frequency_hz(DEFAULT_REFERENCE_A_HZ)
                .unwrap(),
        );

        assert!(
            a3_energy > f_sharp3_energy * 4.0,
            "A3 energy {a3_energy} did not dominate unrelated F#3 energy {f_sharp3_energy}"
        );
        assert!(samples.iter().all(|sample| sample.abs() <= 0.8001));
    }

    #[test]
    fn switching_scene_waveform_for_the_same_note_crossfades_instead_of_jumping() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 5);
        let a4 = "A4".parse::<Note>().unwrap();
        let frequency_hz = a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap();

        generator
            .play_voices(&[ReferenceToneVoice::sine(a4, frequency_hz)])
            .unwrap();

        let mut steady_state = vec![0.0; 2_000];
        generator.render_mono(&mut steady_state);
        let before_switch = *steady_state.last().unwrap();

        generator
            .play_voices(&[ReferenceToneVoice::new(
                a4,
                frequency_hz,
                1.0,
                ReferenceToneWaveform::Warm,
            )])
            .unwrap();

        let mut first_transition_sample = [0.0_f32; 1];
        generator.render_mono(&mut first_transition_sample);

        let jump = (first_transition_sample[0] - before_switch).abs();
        assert!(jump < 0.03, "scene change jump was {jump}");
    }

    #[test]
    fn replacement_scene_retires_removed_notes() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 5);
        let a4 = "A4".parse::<Note>().unwrap();
        let c_sharp5 = "C#5".parse::<Note>().unwrap();
        let e5 = "E5".parse::<Note>().unwrap();

        generator
            .play_notes(&[
                (a4, a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap()),
                (e5, e5.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap()),
            ])
            .unwrap();

        let mut warmup = vec![0.0; 2_000];
        generator.render_mono(&mut warmup);

        generator
            .play_notes(&[
                (a4, a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap()),
                (
                    c_sharp5,
                    c_sharp5.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap(),
                ),
            ])
            .unwrap();

        let mut release = vec![0.0; 4_000];
        generator.render_mono(&mut release);

        assert_eq!(generator.active_notes(), vec![a4, c_sharp5]);
    }

    #[test]
    fn stop_ramps_back_to_silence() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 8);
        let a4 = "A4".parse::<Note>().unwrap();
        let e5 = "E5".parse::<Note>().unwrap();

        generator
            .play_notes(&[
                (a4, a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap()),
                (e5, e5.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap()),
            ])
            .unwrap();

        let mut attack = vec![0.0; 2_000];
        generator.render_mono(&mut attack);
        assert!(generator.is_audible());
        assert_eq!(generator.active_notes(), vec![a4, e5]);

        generator.stop();

        let mut release = vec![0.0; 4_000];
        generator.render_mono(&mut release);

        let tail_peak = release[release.len() - 500..]
            .iter()
            .fold(0.0_f32, |peak, sample| peak.max(sample.abs()));

        assert!(tail_peak < 0.0001, "tail peak was {tail_peak}");
        assert!(generator.is_idle());
        assert_eq!(generator.active_notes(), Vec::<Note>::new());
    }
}
