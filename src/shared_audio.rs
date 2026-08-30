use crate::note::Note;
use crate::reference_tone::{ReferenceToneGenerator, ReferenceToneVoice, ToneGeneratorError};
use std::f64::consts::TAU;

pub struct SharedAudioMixer {
    #[cfg_attr(not(test), allow(dead_code))]
    sample_rate_hz: u32,
    reference_tone: ReferenceToneGenerator,
    scheduled_pulses: Vec<ScheduledPulseVoice>,
}

impl SharedAudioMixer {
    pub fn new(
        sample_rate_hz: u32,
        reference_tone_level: f32,
        reference_ramp_duration_ms: u32,
    ) -> Self {
        Self {
            sample_rate_hz,
            reference_tone: ReferenceToneGenerator::new(
                sample_rate_hz,
                reference_tone_level,
                reference_ramp_duration_ms,
            ),
            scheduled_pulses: Vec::new(),
        }
    }

    pub fn play_reference_notes(
        &mut self,
        notes: &[(Note, f64)],
    ) -> Result<(), ToneGeneratorError> {
        self.reference_tone.play_notes(notes)
    }

    pub(crate) fn play_reference_voices(
        &mut self,
        voices: &[ReferenceToneVoice],
    ) -> Result<(), ToneGeneratorError> {
        self.reference_tone.play_voices(voices)
    }

    pub fn stop_reference_notes(&mut self) {
        self.reference_tone.stop();
    }

    pub fn silence_immediately(&mut self) {
        self.reference_tone.silence_immediately();
        self.scheduled_pulses.clear();
    }

    pub fn clear_timed_pulses(&mut self) {
        self.scheduled_pulses.clear();
    }

    pub fn is_idle(&self) -> bool {
        self.reference_tone.is_idle() && self.scheduled_pulses.is_empty()
    }

    pub fn reference_tone_is_audible(&self) -> bool {
        self.reference_tone.is_audible()
    }

    #[cfg_attr(not(test), allow(dead_code))]
    pub fn schedule_timed_pulse(
        &mut self,
        start_after_frames: usize,
        frequency_hz: f64,
        duration_frames: usize,
        peak_gain: f32,
        ramp_frames: usize,
    ) -> Result<(), ToneGeneratorError> {
        if !frequency_hz.is_finite() || frequency_hz <= 0.0 {
            return Err(ToneGeneratorError::InvalidFrequency);
        }

        let peak_gain = peak_gain.clamp(0.0, 1.0);
        if duration_frames == 0 || peak_gain <= 0.0 {
            return Ok(());
        }

        self.scheduled_pulses.push(ScheduledPulseVoice::new(
            self.sample_rate_hz,
            start_after_frames,
            frequency_hz,
            duration_frames,
            peak_gain,
            ramp_frames,
        ));
        Ok(())
    }

    pub fn render_mono(&mut self, output: &mut [f32]) {
        self.reference_tone.render_mono(output);

        for sample in output.iter_mut() {
            for pulse in &mut self.scheduled_pulses {
                *sample += pulse.next_sample();
            }

            // Keep mixed lanes bounded so a later click layer cannot clip the stream.
            *sample = (*sample).clamp(-1.0, 1.0);
        }

        self.scheduled_pulses.retain(|pulse| !pulse.is_finished());
    }
}

#[derive(Clone, Debug)]
struct ScheduledPulseVoice {
    pending_frames: usize,
    remaining_frames: usize,
    total_frames: usize,
    peak_gain: f32,
    ramp_frames: usize,
    phase_radians: f64,
    phase_step_radians: f64,
}

impl ScheduledPulseVoice {
    #[cfg_attr(not(test), allow(dead_code))]
    fn new(
        sample_rate_hz: u32,
        start_after_frames: usize,
        frequency_hz: f64,
        duration_frames: usize,
        peak_gain: f32,
        ramp_frames: usize,
    ) -> Self {
        Self {
            pending_frames: start_after_frames,
            remaining_frames: duration_frames,
            total_frames: duration_frames,
            peak_gain,
            ramp_frames: ramp_frames.min(duration_frames.saturating_sub(1)),
            phase_radians: 0.0,
            phase_step_radians: TAU * frequency_hz / sample_rate_hz.max(1) as f64,
        }
    }

    fn is_finished(&self) -> bool {
        self.pending_frames == 0 && self.remaining_frames == 0
    }

    fn next_sample(&mut self) -> f32 {
        if self.pending_frames > 0 {
            self.pending_frames -= 1;
            return 0.0;
        }

        if self.remaining_frames == 0 {
            return 0.0;
        }

        let gain = self.envelope_gain();
        let sample = (self.phase_radians.sin() as f32) * gain;
        self.phase_radians = (self.phase_radians + self.phase_step_radians).rem_euclid(TAU);
        self.remaining_frames -= 1;
        sample
    }

    fn envelope_gain(&self) -> f32 {
        if self.ramp_frames == 0 {
            return self.peak_gain;
        }

        let emitted_frames = self.total_frames.saturating_sub(self.remaining_frames);
        let attack_gain = if emitted_frames < self.ramp_frames {
            (emitted_frames + 1) as f32 / self.ramp_frames as f32
        } else {
            1.0
        };
        let release_gain = if self.remaining_frames <= self.ramp_frames {
            self.remaining_frames as f32 / self.ramp_frames as f32
        } else {
            1.0
        };

        self.peak_gain * attack_gain.min(release_gain)
    }
}

#[cfg(test)]
mod tests {
    use super::SharedAudioMixer;
    use crate::note::{Note, DEFAULT_REFERENCE_A_HZ};
    use crate::reference_tone::DEFAULT_SAMPLE_RATE_HZ;

    #[test]
    fn scheduled_pulse_waits_for_its_requested_start_time() {
        let mut mixer = SharedAudioMixer::new(DEFAULT_SAMPLE_RATE_HZ, 0.2, 8);
        mixer.schedule_timed_pulse(48, 880.0, 96, 0.4, 4).unwrap();

        let mut samples = vec![0.0; 160];
        mixer.render_mono(&mut samples);

        assert!(samples[..48].iter().all(|sample| sample.abs() <= 0.000001));
        assert!(samples[48..].iter().any(|sample| sample.abs() > 0.001));
    }

    #[test]
    fn stopping_reference_notes_keeps_scheduled_pulses_alive() {
        let mut mixer = SharedAudioMixer::new(DEFAULT_SAMPLE_RATE_HZ, 0.8, 5);
        let a4 = "A4".parse::<Note>().unwrap();

        mixer
            .play_reference_notes(&[(a4, a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap())])
            .unwrap();

        let mut warmup = vec![0.0; 2_000];
        mixer.render_mono(&mut warmup);

        mixer
            .schedule_timed_pulse(96, 1_760.0, 96, 0.35, 4)
            .unwrap();
        mixer.stop_reference_notes();

        let mut samples = vec![0.0; 256];
        mixer.render_mono(&mut samples);

        assert!(samples[120..220].iter().any(|sample| sample.abs() > 0.01));
    }

    #[test]
    fn mixed_output_is_clamped_to_safe_sample_bounds() {
        let mut mixer = SharedAudioMixer::new(DEFAULT_SAMPLE_RATE_HZ, 0.95, 1);
        let a4 = "A4".parse::<Note>().unwrap();

        mixer
            .play_reference_notes(&[(a4, a4.frequency_hz(DEFAULT_REFERENCE_A_HZ).unwrap())])
            .unwrap();

        let mut warmup = vec![0.0; 2_000];
        mixer.render_mono(&mut warmup);

        mixer.schedule_timed_pulse(0, 880.0, 256, 0.95, 1).unwrap();

        let mut samples = vec![0.0; 512];
        mixer.render_mono(&mut samples);

        assert!(samples.iter().all(|sample| sample.abs() <= 1.000001));
    }
}
