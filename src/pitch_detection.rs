use crate::note::{nearest_note_for_frequency, Note};

pub const DEFAULT_ANALYSIS_WINDOW_SAMPLES: usize = 4_096;
pub const DEFAULT_ANALYSIS_HOP_SAMPLES: usize = 2_048;
pub const DEFAULT_MIN_FREQUENCY_HZ: f64 = 50.0;
pub const DEFAULT_MAX_FREQUENCY_HZ: f64 = 1_200.0;

const DEFAULT_SILENCE_RMS_THRESHOLD: f64 = 0.003;
const DEFAULT_YIN_THRESHOLD: f64 = 0.15;
const DEFAULT_FALLBACK_YIN_THRESHOLD: f64 = 0.35;
const DEFAULT_CONFIDENCE_FLOOR: f64 = 0.65;

#[derive(Clone, Debug, PartialEq)]
pub struct PitchEstimate {
    pub note: Note,
    pub frequency_hz: f64,
    pub reference_frequency_hz: f64,
    pub cents: f64,
    pub confidence: f64,
}

pub struct PitchDetector {
    sample_rate_hz: u32,
    window_size: usize,
    min_tau: usize,
    max_tau: usize,
    silence_rms_threshold: f64,
    yin_threshold: f64,
    fallback_yin_threshold: f64,
    confidence_floor: f64,
    difference: Vec<f64>,
    cumulative_normalized_difference: Vec<f64>,
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
            min_tau,
            max_tau,
            silence_rms_threshold: DEFAULT_SILENCE_RMS_THRESHOLD,
            yin_threshold: DEFAULT_YIN_THRESHOLD,
            fallback_yin_threshold: DEFAULT_FALLBACK_YIN_THRESHOLD,
            confidence_floor: DEFAULT_CONFIDENCE_FLOOR,
            difference: vec![0.0; max_tau + 1],
            cumulative_normalized_difference: vec![0.0; max_tau + 1],
        }
    }

    pub fn detect_pitch(&mut self, frame: &[f32], reference_a_hz: f64) -> Option<PitchEstimate> {
        let frame = frame.get(frame.len().checked_sub(self.window_size)?..)?;
        if centered_rms(frame) < self.silence_rms_threshold {
            return None;
        }

        self.compute_difference(frame);
        self.compute_cumulative_normalized_difference();

        let tau = self.select_period_tau()?;
        let refined_tau = self.refine_tau(tau);
        if !refined_tau.is_finite() || refined_tau <= 0.0 {
            return None;
        }

        let frequency_hz = self.sample_rate_hz as f64 / refined_tau;
        if frequency_hz < DEFAULT_MIN_FREQUENCY_HZ || frequency_hz > DEFAULT_MAX_FREQUENCY_HZ {
            return None;
        }

        let confidence = (1.0 - self.cumulative_normalized_difference[tau]).clamp(0.0, 1.0);
        if confidence < self.confidence_floor {
            return None;
        }

        let nearest = nearest_note_for_frequency(frequency_hz, reference_a_hz).ok()?;
        Some(PitchEstimate {
            note: nearest.note,
            frequency_hz,
            reference_frequency_hz: nearest.reference_frequency_hz,
            cents: nearest.cents,
            confidence,
        })
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

#[cfg(test)]
mod tests {
    use super::{
        PitchDetector, DEFAULT_ANALYSIS_WINDOW_SAMPLES, DEFAULT_MAX_FREQUENCY_HZ,
        DEFAULT_MIN_FREQUENCY_HZ,
    };
    use crate::note::DEFAULT_REFERENCE_A_HZ;
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

    #[test]
    fn detects_clean_sine_waves_across_a_useful_range() {
        let mut detector = PitchDetector::new(
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_MIN_FREQUENCY_HZ,
            DEFAULT_MAX_FREQUENCY_HZ,
        );

        for (expected_note, expected_frequency_hz) in [
            ("A1", 55.0),
            ("E2", 82.406_889_228_217_5),
            ("A2", 110.0),
            ("A4", 440.0),
            ("E5", 659.255_113_825_739_8),
        ] {
            let frame = generate_sine_wave(
                expected_frequency_hz,
                DEFAULT_SAMPLE_RATE_HZ,
                DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
                0.5,
            );
            let estimate = detector
                .detect_pitch(&frame, DEFAULT_REFERENCE_A_HZ)
                .unwrap_or_else(|| panic!("expected pitch estimate for {expected_note}"));

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
            .detect_pitch(&frame, DEFAULT_REFERENCE_A_HZ)
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
            .detect_pitch(&silence, DEFAULT_REFERENCE_A_HZ)
            .is_none());

        let weak_signal = generate_sine_wave(
            440.0,
            DEFAULT_SAMPLE_RATE_HZ,
            DEFAULT_ANALYSIS_WINDOW_SAMPLES * 2,
            0.001,
        );
        assert!(detector
            .detect_pitch(&weak_signal, DEFAULT_REFERENCE_A_HZ)
            .is_none());
    }
}
