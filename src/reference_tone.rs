use std::f64::consts::TAU;

pub const DEFAULT_OUTPUT_LEVEL: f32 = 0.18;
pub const DEFAULT_RAMP_DURATION_MS: u32 = 8;
pub const DEFAULT_SAMPLE_RATE_HZ: u32 = 48_000;

#[derive(Clone, Debug)]
pub struct ReferenceToneGenerator {
    sample_rate_hz: u32,
    max_gain: f32,
    gain_step_per_sample: f32,
    phase_radians: f64,
    active_frequency_hz: Option<f64>,
    current_gain: f32,
    target_gain: f32,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum ToneGeneratorError {
    InvalidFrequency,
}

impl ReferenceToneGenerator {
    pub fn new(sample_rate_hz: u32, max_gain: f32, ramp_duration_ms: u32) -> Self {
        let sample_rate_hz = sample_rate_hz.max(1);
        let ramp_samples = ((sample_rate_hz as f32 * ramp_duration_ms as f32) / 1000.0)
            .round()
            .max(1.0);

        Self {
            sample_rate_hz,
            max_gain: max_gain.clamp(0.0, 1.0),
            gain_step_per_sample: if max_gain <= 0.0 {
                0.0
            } else {
                max_gain.clamp(0.0, 1.0) / ramp_samples
            },
            phase_radians: 0.0,
            active_frequency_hz: None,
            current_gain: 0.0,
            target_gain: 0.0,
        }
    }

    pub fn play_frequency(&mut self, frequency_hz: f64) -> Result<(), ToneGeneratorError> {
        if !frequency_hz.is_finite() || frequency_hz <= 0.0 {
            return Err(ToneGeneratorError::InvalidFrequency);
        }

        if self.active_frequency_hz.is_none() && self.current_gain <= 0.0 {
            self.phase_radians = 0.0;
        }

        self.active_frequency_hz = Some(frequency_hz);
        self.target_gain = self.max_gain;
        Ok(())
    }

    pub fn stop(&mut self) {
        self.target_gain = 0.0;
    }

    pub fn silence_immediately(&mut self) {
        self.active_frequency_hz = None;
        self.current_gain = 0.0;
        self.target_gain = 0.0;
    }

    pub fn is_audible(&self) -> bool {
        self.current_gain > 0.0 || self.target_gain > 0.0
    }

    pub fn is_idle(&self) -> bool {
        self.active_frequency_hz.is_none() && !self.is_audible()
    }

    pub fn active_frequency_hz(&self) -> Option<f64> {
        self.active_frequency_hz
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
        self.advance_gain();

        let Some(frequency_hz) = self.active_frequency_hz else {
            return 0.0;
        };

        if self.target_gain <= 0.0 && self.current_gain <= 0.0 {
            self.active_frequency_hz = None;
            return 0.0;
        }

        let sample = (self.phase_radians.sin() as f32) * self.current_gain;
        self.phase_radians =
            (self.phase_radians + TAU * frequency_hz / self.sample_rate_hz as f64).rem_euclid(TAU);

        sample
    }

    fn advance_gain(&mut self) {
        if self.current_gain < self.target_gain {
            self.current_gain =
                (self.current_gain + self.gain_step_per_sample).min(self.target_gain);
        } else if self.current_gain > self.target_gain {
            self.current_gain =
                (self.current_gain - self.gain_step_per_sample).max(self.target_gain);
            if self.current_gain <= 0.0 && self.target_gain <= 0.0 {
                self.active_frequency_hz = None;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{ReferenceToneGenerator, ToneGeneratorError, DEFAULT_SAMPLE_RATE_HZ};

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

    #[test]
    fn rejects_invalid_frequencies() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.2, 8);
        assert_eq!(
            generator.play_frequency(0.0).unwrap_err(),
            ToneGeneratorError::InvalidFrequency
        );
    }

    #[test]
    fn generates_requested_frequency_numerically() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 5);
        generator.play_frequency(440.0).unwrap();

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
    fn replacement_tone_switches_to_new_frequency() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 5);
        generator.play_frequency(220.0).unwrap();

        let mut first = vec![0.0; 8_000];
        generator.render_mono(&mut first);

        generator.play_frequency(440.0).unwrap();

        let mut warmup = vec![0.0; 2_000];
        generator.render_mono(&mut warmup);

        let mut second = vec![0.0; DEFAULT_SAMPLE_RATE_HZ as usize];
        generator.render_mono(&mut second);

        assert_close(
            estimate_frequency_hz(&second, DEFAULT_SAMPLE_RATE_HZ),
            440.0,
            0.5,
        );
    }

    #[test]
    fn stop_ramps_back_to_silence() {
        let mut generator = ReferenceToneGenerator::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 8);
        generator.play_frequency(330.0).unwrap();

        let mut attack = vec![0.0; 2_000];
        generator.render_mono(&mut attack);
        assert!(generator.is_audible());
        assert_eq!(generator.active_frequency_hz(), Some(330.0));

        generator.stop();

        let mut release = vec![0.0; 4_000];
        generator.render_mono(&mut release);

        let tail_peak = release[release.len() - 500..]
            .iter()
            .fold(0.0_f32, |peak, sample| peak.max(sample.abs()));

        assert!(tail_peak < 0.0001, "tail peak was {tail_peak}");
        assert!(generator.is_idle());
        assert_eq!(generator.active_frequency_hz(), None);
    }
}
