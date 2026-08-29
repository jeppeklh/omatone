use crate::note::DEFAULT_REFERENCE_A_HZ;
use std::error::Error;
use std::fmt;
use std::sync::{Arc, RwLock};

pub const MIN_REFERENCE_A_HZ: f64 = 400.0;
pub const MAX_REFERENCE_A_HZ: f64 = 480.0;

#[derive(Clone, Debug, PartialEq)]
pub struct StartupConfig {
    pub reference_a_hz: f64,
}

#[derive(Clone, Debug)]
pub struct SharedConfig {
    inner: Arc<RwLock<StartupConfig>>,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum ReferenceAError {
    InvalidValue,
    OutOfRange,
}

#[derive(Clone, Debug, PartialEq)]
pub enum StartupConfigError {
    MissingValue(&'static str),
    InvalidReferenceFrequency(String),
    UnexpectedArgument(String),
}

impl Default for StartupConfig {
    fn default() -> Self {
        Self {
            reference_a_hz: DEFAULT_REFERENCE_A_HZ,
        }
    }
}

impl StartupConfig {
    pub fn new(reference_a_hz: f64) -> Result<Self, ReferenceAError> {
        Ok(Self {
            reference_a_hz: validate_reference_a_hz(reference_a_hz)?,
        })
    }
}

impl SharedConfig {
    pub fn new(reference_a_hz: f64) -> Result<Self, ReferenceAError> {
        Ok(Self {
            inner: Arc::new(RwLock::new(StartupConfig::new(reference_a_hz)?)),
        })
    }

    pub fn reference_a_hz(&self) -> f64 {
        self.inner
            .read()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
            .reference_a_hz
    }

    pub fn set_reference_a_hz(&self, reference_a_hz: f64) -> Result<(), ReferenceAError> {
        let mut config = self
            .inner
            .write()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        config.reference_a_hz = validate_reference_a_hz(reference_a_hz)?;
        Ok(())
    }
}

impl fmt::Display for ReferenceAError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ReferenceAError::InvalidValue => {
                write!(
                    f,
                    "reference A frequency must be finite and greater than zero"
                )
            }
            ReferenceAError::OutOfRange => write!(
                f,
                "reference A frequency must be within {MIN_REFERENCE_A_HZ:.1}..={MAX_REFERENCE_A_HZ:.1} Hz"
            ),
        }
    }
}

impl Error for ReferenceAError {}

impl fmt::Display for StartupConfigError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            StartupConfigError::MissingValue(flag) => write!(f, "missing value for {flag}"),
            StartupConfigError::InvalidReferenceFrequency(value) => {
                write!(f, "invalid reference A frequency '{value}'")
            }
            StartupConfigError::UnexpectedArgument(argument) => {
                write!(f, "unexpected argument '{argument}'")
            }
        }
    }
}

impl Error for StartupConfigError {}

pub fn validate_reference_a_hz(reference_a_hz: f64) -> Result<f64, ReferenceAError> {
    if !reference_a_hz.is_finite() || reference_a_hz <= 0.0 {
        return Err(ReferenceAError::InvalidValue);
    }
    if !(MIN_REFERENCE_A_HZ..=MAX_REFERENCE_A_HZ).contains(&reference_a_hz) {
        return Err(ReferenceAError::OutOfRange);
    }

    Ok(reference_a_hz)
}

pub fn parse_startup_config<I>(args: I) -> Result<StartupConfig, StartupConfigError>
where
    I: IntoIterator<Item = String>,
{
    let mut config = StartupConfig::default();
    let mut args = args.into_iter();
    let _program = args.next();

    while let Some(argument) = args.next() {
        if let Some(value) = argument.strip_prefix("--reference-a-hz=") {
            config.reference_a_hz = parse_reference_a_hz_argument(value)?;
            continue;
        }

        match argument.as_str() {
            "--reference-a-hz" => {
                let value = args
                    .next()
                    .ok_or(StartupConfigError::MissingValue("--reference-a-hz"))?;
                config.reference_a_hz = parse_reference_a_hz_argument(&value)?;
            }
            _ => return Err(StartupConfigError::UnexpectedArgument(argument)),
        }
    }

    Ok(config)
}

fn parse_reference_a_hz_argument(value: &str) -> Result<f64, StartupConfigError> {
    let reference_a_hz = value
        .trim()
        .parse::<f64>()
        .map_err(|_| StartupConfigError::InvalidReferenceFrequency(value.to_owned()))?;

    validate_reference_a_hz(reference_a_hz)
        .map_err(|_| StartupConfigError::InvalidReferenceFrequency(value.to_owned()))
}

#[cfg(test)]
mod tests {
    use super::{
        parse_startup_config, validate_reference_a_hz, ReferenceAError, StartupConfig,
        StartupConfigError, MAX_REFERENCE_A_HZ, MIN_REFERENCE_A_HZ,
    };

    #[test]
    fn validates_reference_a_frequency_range() {
        assert_eq!(
            validate_reference_a_hz(0.0).unwrap_err(),
            ReferenceAError::InvalidValue
        );
        assert_eq!(
            validate_reference_a_hz(MIN_REFERENCE_A_HZ - 0.1).unwrap_err(),
            ReferenceAError::OutOfRange
        );
        assert_eq!(
            validate_reference_a_hz(MAX_REFERENCE_A_HZ + 0.1).unwrap_err(),
            ReferenceAError::OutOfRange
        );
        assert_eq!(validate_reference_a_hz(442.0).unwrap(), 442.0);
    }

    #[test]
    fn parses_default_and_explicit_reference_a_values() {
        assert_eq!(
            parse_startup_config(vec!["omatune-helper".to_owned()]).unwrap(),
            StartupConfig::default()
        );
        assert_eq!(
            parse_startup_config(vec![
                "omatune-helper".to_owned(),
                "--reference-a-hz".to_owned(),
                "442.0".to_owned(),
            ])
            .unwrap(),
            StartupConfig {
                reference_a_hz: 442.0,
            }
        );
        assert_eq!(
            parse_startup_config(vec![
                "omatune-helper".to_owned(),
                "--reference-a-hz=432".to_owned(),
            ])
            .unwrap(),
            StartupConfig {
                reference_a_hz: 432.0,
            }
        );
    }

    #[test]
    fn rejects_invalid_startup_arguments() {
        assert_eq!(
            parse_startup_config(vec![
                "omatune-helper".to_owned(),
                "--reference-a-hz".to_owned(),
            ])
            .unwrap_err(),
            StartupConfigError::MissingValue("--reference-a-hz")
        );
        assert_eq!(
            parse_startup_config(vec![
                "omatune-helper".to_owned(),
                "--reference-a-hz".to_owned(),
                "399.0".to_owned(),
            ])
            .unwrap_err(),
            StartupConfigError::InvalidReferenceFrequency("399.0".to_owned())
        );
        assert_eq!(
            parse_startup_config(vec!["omatune-helper".to_owned(), "--unknown".to_owned(),])
                .unwrap_err(),
            StartupConfigError::UnexpectedArgument("--unknown".to_owned())
        );
    }
}
