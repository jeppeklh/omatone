use crate::note::{Note, TuningModel};

pub const DEFAULT_ANALYSIS_WINDOW_SAMPLES: usize = 4_800;
pub const DEFAULT_ANALYSIS_HOP_SAMPLES: usize = 2_048;
pub const DEFAULT_MIN_FREQUENCY_HZ: f64 = 30.0;
pub const DEFAULT_MAX_FREQUENCY_HZ: f64 = 1_200.0;
pub const DEFAULT_ANALYSIS_HISTORY_FRAMES: usize = 12;

const DEFAULT_SILENCE_RMS_THRESHOLD: f64 = 0.003;
const DEFAULT_SILENCE_RELEASE_RMS_THRESHOLD: f64 = 0.0024;
const DEFAULT_YIN_THRESHOLD: f64 = 0.15;
const DEFAULT_FALLBACK_YIN_THRESHOLD: f64 = 0.35;
const DEFAULT_CONFIDENCE_FLOOR: f64 = 0.60;
const DEFAULT_IMMEDIATE_CONFIDENCE_FLOOR: f64 = 0.88;
const DEFAULT_TRANSIENT_LEVEL_RISE_RATIO: f64 = 2.4;
const DEFAULT_CANDIDATE_CONFIRM_FRAMES: usize = 2;
const DEFAULT_UNSTABLE_GRACE_FRAMES: usize = 1;
const REFERENCE_A_CHANGE_EPSILON: f64 = 0.0001;

#[derive(Clone, Debug, PartialEq)]
pub struct PitchEstimate {
    pub note: Note,
    pub frequency_hz: f64,
    pub reference_frequency_hz: f64,
    pub cents: f64,
    pub confidence: f64,
}

#[derive(Clone, Debug, PartialEq)]
pub struct PitchFrameAnalysis {
    pub history_cents: Vec<f64>,
    pub history_span_cents: f64,
    pub held: bool,
}

#[derive(Clone, Debug, PartialEq)]
pub struct PitchFrame {
    pub estimate: PitchEstimate,
    pub detector_confidence: Option<f64>,
    pub analysis: PitchFrameAnalysis,
}

#[derive(Clone, Debug, PartialEq)]
struct RawPitchEstimate {
    frequency_hz: f64,
    confidence: f64,
}

#[derive(Clone, Debug, PartialEq)]
struct TrackingOutput {
    estimate: PitchEstimate,
    detector_confidence: Option<f64>,
    held: bool,
}

pub struct PitchDetector {
    sample_rate_hz: u32,
    window_size: usize,
    min_frequency_hz: f64,
    max_frequency_hz: f64,
    min_tau: usize,
    max_tau: usize,
    silence_rms_threshold: f64,
    silence_release_rms_threshold: f64,
    yin_threshold: f64,
    fallback_yin_threshold: f64,
    confidence_floor: f64,
    immediate_confidence_floor: f64,
    transient_level_rise_ratio: f64,
    candidate_confirm_frames: usize,
    unstable_grace_frames: usize,
    analysis_history_frames: usize,
    difference: Vec<f64>,
    cumulative_normalized_difference: Vec<f64>,
    stable_estimate: Option<PitchEstimate>,
    pending_estimate: Option<PitchEstimate>,
    pending_match_frames: usize,
    unreliable_frames: usize,
    display_history_note: Option<Note>,
    display_history_cents: Vec<f64>,
    previous_level_rms: f64,
    last_reference_a_hz: Option<f64>,
    last_transposition_semitones: Option<i32>,
    last_temperament: Option<crate::note::Temperament>,
}

impl PitchDetector {
    pub fn new(sample_rate_hz: u32, min_frequency_hz: f64, max_frequency_hz: f64) -> Self {
        let sample_rate_hz = sample_rate_hz.max(1);
        let min_frequency_hz = min_frequency_hz.max(1.0);
        let max_frequency_hz = max_frequency_hz.max(min_frequency_hz + 1.0);
        let min_tau = ((sample_rate_hz as f64 / max_frequency_hz).floor() as usize).max(2);
        let max_tau = ((sample_rate_hz as f64 / min_frequency_hz).ceil() as usize)
            .min(DEFAULT_ANALYSIS_WINDOW_SAMPLES.saturating_sub(2))
            .max(min_tau + 1);

        Self {
            sample_rate_hz,
            window_size: DEFAULT_ANALYSIS_WINDOW_SAMPLES,
            min_frequency_hz,
            max_frequency_hz,
            min_tau,
            max_tau,
            silence_rms_threshold: DEFAULT_SILENCE_RMS_THRESHOLD,
            silence_release_rms_threshold: DEFAULT_SILENCE_RELEASE_RMS_THRESHOLD,
            yin_threshold: DEFAULT_YIN_THRESHOLD,
            fallback_yin_threshold: DEFAULT_FALLBACK_YIN_THRESHOLD,
            confidence_floor: DEFAULT_CONFIDENCE_FLOOR,
            immediate_confidence_floor: DEFAULT_IMMEDIATE_CONFIDENCE_FLOOR,
            transient_level_rise_ratio: DEFAULT_TRANSIENT_LEVEL_RISE_RATIO,
            candidate_confirm_frames: DEFAULT_CANDIDATE_CONFIRM_FRAMES,
            unstable_grace_frames: DEFAULT_UNSTABLE_GRACE_FRAMES,
            analysis_history_frames: DEFAULT_ANALYSIS_HISTORY_FRAMES,
            difference: vec![0.0; max_tau + 1],
            cumulative_normalized_difference: vec![0.0; max_tau + 1],
            stable_estimate: None,
            pending_estimate: None,
            pending_match_frames: 0,
            unreliable_frames: 0,
            display_history_note: None,
            display_history_cents: Vec::with_capacity(DEFAULT_ANALYSIS_HISTORY_FRAMES),
            previous_level_rms: 0.0,
            last_reference_a_hz: None,
            last_transposition_semitones: None,
            last_temperament: None,
        }
    }

    pub fn analyze_frame(
        &mut self,
        frame: &[f32],
        tuning_model: TuningModel,
    ) -> Option<PitchFrame> {
        let frame = frame.get(frame.len().checked_sub(self.window_size)?..)?;
        self.reset_for_tuning_change(tuning_model);

        let level_rms = centered_rms(frame);
        if self.is_silent(level_rms) {
            self.clear_tracking();
            self.previous_level_rms = level_rms;
            return None;
        }

        let raw_estimate = self.detect_raw_pitch(frame, tuning_model);
        let output_estimate = self.update_tracking(raw_estimate, level_rms);
        self.previous_level_rms = level_rms;

        let output_estimate = output_estimate?;
        self.record_display_history(&output_estimate.estimate);
        let history_cents = self.display_history_cents.clone();

        Some(PitchFrame {
            estimate: output_estimate.estimate,
            detector_confidence: output_estimate.detector_confidence,
            analysis: PitchFrameAnalysis {
                history_span_cents: cents_history_span(&history_cents),
                history_cents,
                held: output_estimate.held,
            },
        })
    }

    pub fn detect_pitch(
        &mut self,
        frame: &[f32],
        tuning_model: TuningModel,
    ) -> Option<PitchEstimate> {
        self.analyze_frame(frame, tuning_model)
            .map(|pitch_frame| pitch_frame.estimate)
    }

    fn detect_raw_pitch(
        &mut self,
        frame: &[f32],
        tuning_model: TuningModel,
    ) -> Option<PitchEstimate> {
        let raw_estimate = self.detect_raw_estimate(frame)?;
        let nearest = tuning_model
            .nearest_displayed_note_for_frequency(raw_estimate.frequency_hz)
            .ok()?;

        Some(PitchEstimate {
            note: nearest.note,
            frequency_hz: raw_estimate.frequency_hz,
            reference_frequency_hz: nearest.reference_frequency_hz,
            cents: nearest.cents,
            confidence: raw_estimate.confidence,
        })
    }

    fn detect_raw_estimate(&mut self, frame: &[f32]) -> Option<RawPitchEstimate> {
        self.compute_difference(frame);
        self.compute_cumulative_normalized_difference();

        let tau = self.select_period_tau()?;
        let refined_tau = self.refine_tau(tau);
        if !refined_tau.is_finite() || refined_tau <= 0.0 {
            return None;
        }

        let frequency_hz = self.sample_rate_hz as f64 / refined_tau;
        if frequency_hz < self.min_frequency_hz || frequency_hz > self.max_frequency_hz {
            return None;
        }

        let confidence = (1.0 - self.cumulative_normalized_difference[tau]).clamp(0.0, 1.0);
        if confidence < self.confidence_floor {
            return None;
        }

        Some(RawPitchEstimate {
            frequency_hz,
            confidence,
        })
    }

    fn update_tracking(
        &mut self,
        raw_estimate: Option<PitchEstimate>,
        level_rms: f64,
    ) -> Option<TrackingOutput> {
        let Some(raw_estimate) = raw_estimate else {
            return self.handle_unreliable_frame();
        };
        let detector_confidence = Some(raw_estimate.confidence);

        let is_transient = self.is_transient(level_rms, raw_estimate.confidence);

        let Some(stable_estimate) = self.stable_estimate.clone() else {
            return self.lock_from_idle(raw_estimate, is_transient);
        };

        if raw_estimate.note == stable_estimate.note {
            return Some(TrackingOutput::fresh(
                self.accept_stable(raw_estimate),
                detector_confidence,
            ));
        }

        if raw_estimate.confidence >= self.immediate_confidence_floor
            && !is_transient
            && !is_octave_variant(stable_estimate.note, raw_estimate.note)
        {
            return Some(TrackingOutput::fresh(
                self.accept_stable(raw_estimate),
                detector_confidence,
            ));
        }

        self.track_pending_candidate(&raw_estimate);
        self.unreliable_frames = 0;

        if self.pending_match_frames >= self.candidate_confirm_frames {
            return Some(TrackingOutput::fresh(
                self.accept_stable(raw_estimate),
                detector_confidence,
            ));
        }

        Some(TrackingOutput::held(stable_estimate, detector_confidence))
    }

    fn lock_from_idle(
        &mut self,
        raw_estimate: PitchEstimate,
        is_transient: bool,
    ) -> Option<TrackingOutput> {
        if raw_estimate.confidence >= self.immediate_confidence_floor && !is_transient {
            return Some(TrackingOutput::fresh(
                self.accept_stable(raw_estimate.clone()),
                Some(raw_estimate.confidence),
            ));
        }

        self.track_pending_candidate(&raw_estimate);
        self.unreliable_frames = 0;

        if self.pending_match_frames >= self.candidate_confirm_frames {
            return Some(TrackingOutput::fresh(
                self.accept_stable(raw_estimate.clone()),
                Some(raw_estimate.confidence),
            ));
        }

        None
    }

    fn track_pending_candidate(&mut self, candidate: &PitchEstimate) {
        if self.pending_matches(candidate) {
            self.pending_match_frames += 1;
            return;
        }

        self.pending_estimate = Some(candidate.clone());
        self.pending_match_frames = 1;
    }

    fn pending_matches(&self, candidate: &PitchEstimate) -> bool {
        self.pending_estimate
            .as_ref()
            .map(|pending_estimate| pending_estimate.note == candidate.note)
            .unwrap_or(false)
    }

    fn handle_unreliable_frame(&mut self) -> Option<TrackingOutput> {
        self.pending_estimate = None;
        self.pending_match_frames = 0;

        if let Some(stable_estimate) = self.stable_estimate.clone() {
            if self.unreliable_frames < self.unstable_grace_frames {
                self.unreliable_frames += 1;
                return Some(TrackingOutput::held(stable_estimate, None));
            }
        }

        self.clear_tracking();
        None
    }

    fn accept_stable(&mut self, estimate: PitchEstimate) -> PitchEstimate {
        self.pending_estimate = None;
        self.pending_match_frames = 0;
        self.unreliable_frames = 0;
        self.stable_estimate = Some(estimate.clone());
        estimate
    }

    fn clear_tracking(&mut self) {
        self.stable_estimate = None;
        self.pending_estimate = None;
        self.pending_match_frames = 0;
        self.unreliable_frames = 0;
        self.display_history_note = None;
        self.display_history_cents.clear();
    }

    fn record_display_history(&mut self, estimate: &PitchEstimate) {
        if self.display_history_note != Some(estimate.note) {
            self.display_history_note = Some(estimate.note);
            self.display_history_cents.clear();
        }

        self.display_history_cents.push(estimate.cents);
        if self.display_history_cents.len() > self.analysis_history_frames {
            self.display_history_cents.remove(0);
        }
    }

    fn reset_for_tuning_change(&mut self, tuning_model: TuningModel) {
        if let Some(last_reference_a_hz) = self.last_reference_a_hz {
            if (last_reference_a_hz - tuning_model.reference_a_hz()).abs()
                >= REFERENCE_A_CHANGE_EPSILON
            {
                self.clear_tracking();
            }
        }
        if let Some(last_transposition_semitones) = self.last_transposition_semitones {
            if last_transposition_semitones != tuning_model.transposition_semitones() {
                self.clear_tracking();
            }
        }
        if let Some(last_temperament) = self.last_temperament {
            if last_temperament != tuning_model.temperament() {
                self.clear_tracking();
            }
        }

        self.last_reference_a_hz = Some(tuning_model.reference_a_hz());
        self.last_transposition_semitones = Some(tuning_model.transposition_semitones());
        self.last_temperament = Some(tuning_model.temperament());
    }

    fn is_silent(&self, level_rms: f64) -> bool {
        let threshold = if self.stable_estimate.is_some() || self.pending_estimate.is_some() {
            self.silence_release_rms_threshold
        } else {
            self.silence_rms_threshold
        };

        level_rms < threshold
    }

    fn is_transient(&self, level_rms: f64, confidence: f64) -> bool {
        confidence < self.immediate_confidence_floor
            && (self.previous_level_rms <= f64::EPSILON
                || level_rms >= self.previous_level_rms * self.transient_level_rise_ratio)
    }

    fn compute_difference(&mut self, frame: &[f32]) {
        self.difference.fill(0.0);

        for tau in self.min_tau..=self.max_tau {
            let mut sum = 0.0;
            for index in 0..(frame.len() - tau) {
                let delta = frame[index] as f64 - frame[index + tau] as f64;
                sum += delta * delta;
            }
            self.difference[tau] = sum;
        }
    }

    fn compute_cumulative_normalized_difference(&mut self) {
        self.cumulative_normalized_difference.fill(1.0);

        let mut running_sum = 0.0;
        for tau in 1..=self.max_tau {
            running_sum += self.difference[tau];
            self.cumulative_normalized_difference[tau] = if running_sum <= f64::EPSILON {
                1.0
            } else {
                self.difference[tau] * tau as f64 / running_sum
            };
        }
    }

    fn select_period_tau(&self) -> Option<usize> {
        let mut tau = self.min_tau;
        while tau <= self.max_tau {
            if self.cumulative_normalized_difference[tau] < self.yin_threshold {
                let mut best_tau = tau;
                while best_tau < self.max_tau
                    && self.cumulative_normalized_difference[best_tau + 1]
                        < self.cumulative_normalized_difference[best_tau]
                {
                    best_tau += 1;
                }
                return Some(best_tau);
            }
            tau += 1;
        }

        let mut best_tau = self.min_tau;
        let mut best_value = self.cumulative_normalized_difference[self.min_tau];
        for tau in (self.min_tau + 1)..=self.max_tau {
            let value = self.cumulative_normalized_difference[tau];
            if value < best_value {
                best_value = value;
                best_tau = tau;
            }
        }

        if best_value < self.fallback_yin_threshold {
            Some(best_tau)
        } else {
            None
        }
    }

    fn refine_tau(&self, tau: usize) -> f64 {
        if tau <= self.min_tau || tau >= self.max_tau {
            return tau as f64;
        }

        let previous = self.cumulative_normalized_difference[tau - 1];
        let center = self.cumulative_normalized_difference[tau];
        let next = self.cumulative_normalized_difference[tau + 1];
        let denominator = previous - 2.0 * center + next;
        if denominator.abs() <= f64::EPSILON {
            return tau as f64;
        }

        let offset = 0.5 * (previous - next) / denominator;
        (tau as f64 + offset).clamp((tau - 1) as f64, (tau + 1) as f64)
    }
}

impl TrackingOutput {
    fn fresh(estimate: PitchEstimate, detector_confidence: Option<f64>) -> Self {
        Self {
            estimate,
            detector_confidence,
            held: false,
        }
    }

    fn held(estimate: PitchEstimate, detector_confidence: Option<f64>) -> Self {
        Self {
            estimate,
            detector_confidence,
            held: true,
        }
    }
}

fn centered_rms(frame: &[f32]) -> f64 {
    if frame.is_empty() {
        return 0.0;
    }

    let mean = frame.iter().map(|sample| *sample as f64).sum::<f64>() / frame.len() as f64;
    let energy = frame
        .iter()
        .map(|sample| {
            let centered = *sample as f64 - mean;
            centered * centered
        })
        .sum::<f64>()
        / frame.len() as f64;

    energy.sqrt()
}

fn cents_history_span(history_cents: &[f64]) -> f64 {
    if history_cents.is_empty() {
        return 0.0;
    }

    let mut minimum_cents = history_cents[0];
    let mut maximum_cents = history_cents[0];
    for cents in history_cents.iter().copied().skip(1) {
        minimum_cents = minimum_cents.min(cents);
        maximum_cents = maximum_cents.max(cents);
    }

    maximum_cents - minimum_cents
}

fn is_octave_variant(left: Note, right: Note) -> bool {
    left != right && left.midi_number().rem_euclid(12) == right.midi_number().rem_euclid(12)
}

#[cfg(test)]
mod tests {
    use super::{
        PitchDetector, PitchEstimate, PitchFrame, DEFAULT_ANALYSIS_WINDOW_SAMPLES,
        DEFAULT_MAX_FREQUENCY_HZ, DEFAULT_MIN_FREQUENCY_HZ,
    };
    use crate::note::{TuningModel, DEFAULT_REFERENCE_A_HZ};
    use crate::reference_tone::DEFAULT_SAMPLE_RATE_HZ;

    fn assert_close(actual: f64, expected: f64, tolerance: f64) {
        let delta = (actual - expected).abs();
        assert!(
            delta <= tolerance,
            "expected {expected} +/- {tolerance}, got {actual} (delta {delta})"
        );
    }

    fn generate_sine_wave(
        frequency_hz: f64,
        sample_rate_hz: u32,
        sample_count: usize,
        amplitude: f32,
    ) -> Vec<f32> {
        (0..sample_count)
            .map(|index| {
                let phase =
                    std::f64::consts::TAU * frequency_hz * index as f64 / sample_rate_hz as f64;
                (phase.sin() as f32) * amplitude
            })
            .collect()
    }

    fn detect_locked_pitch(detector: &mut PitchDetector, frame: &[f32]) -> PitchEstimate {
        let tuning_model = TuningModel::new(DEFAULT_REFERENCE_A_HZ, 0).unwrap();
        detector
            .detect_pitch(frame, tuning_model)
            .or_else(|| detector.detect_pitch(frame, tuning_model))
            .expect("expected pitch estimate after stabilization")
    }

    fn analyze_locked_pitch(detector: &mut PitchDetector, frame: &[f32]) -> PitchFrame {
        let tuning_model = TuningModel::new(DEFAULT_REFERENCE_A_HZ, 0).unwrap();
        detector
            .analyze_frame(frame, tuning_model)
            .or_else(|| detector.analyze_frame(frame, tuning_model))
            .expect("expected pitch analysis after stabilization")
    }

    fn default_tuning_model() -> TuningModel {
        TuningModel::new(DEFAULT_REFERENCE_A_HZ, 0).unwrap()
    }

    fn generate_harmonic_wave(
        frequency_hz: f64,
        sample_rate_hz: u32,
        sample_count: usize,
        amplitude: f32,
        harmonics: &[(u32, f32)],
    ) -> Vec<f32> {
        let total_weight: f32 = harmonics.iter().map(|(_, weight)| *weight).sum();

        (0..sample_count)
            .map(|index| {
                let envelope = ((index + 1) as f32 / 256.0).min(1.0);
                let sample = harmonics
                    .iter()
                    .map(|(multiple, weight)| {
                        let phase =
                            std::f64::consts::TAU * frequency_hz * *multiple as f64 * index as f64
                                / sample_rate_hz as f64;
                        phase.sin() as f32 * *weight
                    })
                    .sum::<f32>();

                if total_weight <= f32::EPSILON {
                    0.0
                } else {
                    amplitude * envelope * sample / total_weight
                }
            })
            .collect()
    }

    fn generate_noise(sample_count: usize, amplitude: f32) -> Vec<f32> {
        let mut state = 0x1234_5678_u32;

        (0..sample_count)
            .map(|_| {
                state = state.wrapping_mul(1_664_525).wrapping_add(1_013_904_223);
                let normalized = state as f32 / u32::MAX as f32;
                amplitude * (normalized * 2.0 - 1.0)
            })
            .collect()
    }

    #[test]
    fn detects_clean_sine_waves_across_a_useful_range() {
        for (expected_note, expected_frequency_hz) in [
            ("A1", 55.0),
            ("E2", 82.406_889_228_217_5),
            ("A2", 110.0),
            ("A4", 440.0),
            ("E5", 659.255_113_825_739_8),
        ] {
            let mut detector = PitchDetector::new(
                DEFAULT_SAMPLE_RATE_HZ,
                DEFAULT_MIN_FREQUENCY_HZ,
                DEFAULT_MAX_FREQUENCY_HZ,
            );
            let frame = generate_sine_wave(
                expected_frequency_hz,
                DEFAULT_SAMPLE_RATE_HZ,
                DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
                0.5,
            );
            let estimate = detect_locked_pitch(&mut detector, &frame);

            assert_eq!(estimate.note.to_string(), expected_note);
            assert_close(estimate.frequency_hz, expected_frequency_hz, 0.7);
            assert!(
                estimate.confidence >= 0.80,
                "confidence was {}",
                estimate.confidence
            );
        }
    }

    #[test]
    fn reports_cents_for_detuned_input() {
        let mut detector = PitchDetector::new(
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_MIN_FREQUENCY_HZ,
            DEFAULT_MAX_FREQUENCY_HZ,
        );
        let detuned_frequency = 440.0 * 2.0_f64.powf(12.0 / 1200.0);
        let frame = generate_sine_wave(
            detuned_frequency,
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.5,
        );

        let estimate = detector
            .detect_pitch(&frame, default_tuning_model())
            .unwrap();
        assert_eq!(estimate.note.to_string(), "A4");
        assert_close(estimate.cents, 12.0, 1.0);
    }

    #[test]
    fn rejects_silence_and_weak_signal() {
        let mut detector = PitchDetector::new(
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_MIN_FREQUENCY_HZ,
            DEFAULT_MAX_FREQUENCY_HZ,
        );

        let silence = vec![0.0; DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2];
        assert!(detector
            .detect_pitch(&silence, default_tuning_model())
            .is_none());

        let weak_signal = generate_sine_wave(
            440.0,
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.001,
        );
        assert!(detector
            .detect_pitch(&weak_signal, default_tuning_model())
            .is_none());
    }

    #[test]
    fn detects_harmonic_rich_bass_notes_down_to_b0() {
        for (expected_note, expected_frequency_hz) in [
            ("B0", 30.867_706_328_507_75),
            ("E1", 41.203_444_614_108_75),
            ("A1", 55.0),
        ] {
            let mut detector = PitchDetector::new(
                DEFAULT_SAMPLE_RATE_HZ,
                DEFAULT_MIN_FREQUENCY_HZ,
                DEFAULT_MAX_FREQUENCY_HZ,
            );
            let frame = generate_harmonic_wave(
                expected_frequency_hz,
                DEFAULT_SAMPLE_RATE_HZ,
                DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
                0.5,
                &[(1, 1.0), (2, 0.5), (3, 0.35), (4, 0.2), (5, 0.12)],
            );

            let estimate = detect_locked_pitch(&mut detector, &frame);
            assert_eq!(estimate.note.to_string(), expected_note);
            assert_close(estimate.frequency_hz, expected_frequency_hz, 1.0);
            assert!(
                estimate.confidence >= 0.60,
                "confidence was {}",
                estimate.confidence
            );
        }
    }

    #[test]
    fn rejects_broadband_noise_and_impulses() {
        let mut detector = PitchDetector::new(
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_MIN_FREQUENCY_HZ,
            DEFAULT_MAX_FREQUENCY_HZ,
        );
        let noise = generate_noise(DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2, 0.35);
        assert!(detector
            .detect_pitch(&noise, default_tuning_model())
            .is_none());

        let mut impulse = vec![0.0; DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2];
        let impulse_index = impulse.len() - 24;
        impulse[impulse_index] = 1.0;
        assert!(detector
            .detect_pitch(&impulse, default_tuning_model())
            .is_none());
    }

    #[test]
    fn holds_a_stable_pitch_through_one_unreliable_frame_then_clears_it() {
        let mut detector = PitchDetector::new(
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_MIN_FREQUENCY_HZ,
            DEFAULT_MAX_FREQUENCY_HZ,
        );
        let stable_frame = generate_sine_wave(
            110.0,
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.5,
        );
        let noisy_frame = generate_noise(DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2, 0.35);

        assert_eq!(
            detect_locked_pitch(&mut detector, &stable_frame)
                .note
                .to_string(),
            "A2"
        );
        assert_eq!(
            detector
                .detect_pitch(&noisy_frame, default_tuning_model())
                .unwrap()
                .note
                .to_string(),
            "A2"
        );
        assert!(detector
            .detect_pitch(&noisy_frame, default_tuning_model())
            .is_none());
    }

    #[test]
    fn requires_confirmation_before_switching_to_an_octave_variant() {
        let mut detector = PitchDetector::new(
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_MIN_FREQUENCY_HZ,
            DEFAULT_MAX_FREQUENCY_HZ,
        );
        let a2_frame = generate_sine_wave(
            110.0,
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.5,
        );
        let a1_frame = generate_sine_wave(
            55.0,
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.5,
        );

        assert_eq!(
            detect_locked_pitch(&mut detector, &a2_frame)
                .note
                .to_string(),
            "A2"
        );

        let held = detector
            .detect_pitch(&a1_frame, default_tuning_model())
            .unwrap();
        assert_eq!(held.note.to_string(), "A2");

        let switched = detector
            .detect_pitch(&a1_frame, default_tuning_model())
            .unwrap();
        assert_eq!(switched.note.to_string(), "A1");
    }

    #[test]
    fn tracks_recent_cents_history_and_span_for_stable_pitch() {
        let mut detector = PitchDetector::new(
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_MIN_FREQUENCY_HZ,
            DEFAULT_MAX_FREQUENCY_HZ,
        );
        let centered_frame = generate_sine_wave(
            440.0,
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.5,
        );
        let sharp_frame = generate_sine_wave(
            440.0 * 2.0_f64.powf(4.0 / 1200.0),
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.5,
        );
        let flat_frame = generate_sine_wave(
            440.0 * 2.0_f64.powf(-3.0 / 1200.0),
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.5,
        );

        let initial = analyze_locked_pitch(&mut detector, &centered_frame);
        assert_eq!(initial.analysis.history_cents.len(), 1);
        assert_close(initial.analysis.history_span_cents, 0.0, 0.01);

        detector
            .analyze_frame(&sharp_frame, default_tuning_model())
            .expect("expected sharp frame to stay locked");
        let flat_analysis = detector
            .analyze_frame(&flat_frame, default_tuning_model())
            .expect("expected flat frame to stay locked");

        assert_eq!(flat_analysis.analysis.history_cents.len(), 3);
        assert!(flat_analysis.analysis.history_span_cents > 2.0);
        assert!(!flat_analysis.analysis.held);
    }

    #[test]
    fn marks_pending_note_changes_as_held_until_confirmed() {
        let mut detector = PitchDetector::new(
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_MIN_FREQUENCY_HZ,
            DEFAULT_MAX_FREQUENCY_HZ,
        );
        let a2_frame = generate_sine_wave(
            110.0,
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.5,
        );
        let a1_frame = generate_sine_wave(
            55.0,
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.5,
        );

        assert_eq!(
            analyze_locked_pitch(&mut detector, &a2_frame)
                .estimate
                .note
                .to_string(),
            "A2"
        );

        let held = detector
            .analyze_frame(&a1_frame, default_tuning_model())
            .expect("expected first octave-variant frame to hold the current note");
        assert_eq!(held.estimate.note.to_string(), "A2");
        assert!(held.analysis.held);
        assert!(held.detector_confidence.is_some());

        let switched = detector
            .analyze_frame(&a1_frame, default_tuning_model())
            .expect("expected second octave-variant frame to switch notes");
        assert_eq!(switched.estimate.note.to_string(), "A1");
        assert!(!switched.analysis.held);
        assert_eq!(switched.analysis.history_cents.len(), 1);
    }

    #[test]
    fn marks_grace_frame_holds_without_a_fresh_confidence() {
        let mut detector = PitchDetector::new(
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_MIN_FREQUENCY_HZ,
            DEFAULT_MAX_FREQUENCY_HZ,
        );
        let stable_frame = generate_sine_wave(
            110.0,
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.5,
        );
        let noisy_frame = generate_noise(DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2, 0.35);

        assert_eq!(
            analyze_locked_pitch(&mut detector, &stable_frame)
                .estimate
                .note
                .to_string(),
            "A2"
        );

        let held = detector
            .analyze_frame(&noisy_frame, default_tuning_model())
            .expect("expected one grace frame to hold the stable note");
        assert_eq!(held.estimate.note.to_string(), "A2");
        assert!(held.analysis.held);
        assert_eq!(held.detector_confidence, None);
    }
}
