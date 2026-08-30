use crate::note::{
    validate_transposition_semitones, Temperament, TemperamentError, TranspositionError,
    TuningModel, DEFAULT_REFERENCE_A_HZ, DEFAULT_TRANSPOSITION_SEMITONES,
};
use std::error::Error;
use std::fmt;
use std::sync::{Arc, RwLock};

pub const MIN_REFERENCE_A_HZ: f64 = 400.0;
pub const MAX_REFERENCE_A_HZ: f64 = 480.0;

#[derive(Clone, Debug, PartialEq)]
pub enum HelperCliAction {
    Run(StartupConfig),
    DumpTuningLibrary,
    NormalizeContentPack { json: String },
    PrintHelp,
    PrintVersion,
}

#[derive(Clone, Debug, PartialEq)]
pub struct StartupConfig {
    pub reference_a_hz: f64,
    pub transposition_semitones: i32,
    pub temperament: Temperament,
}

#[derive(Clone, Debug)]
pub struct SharedConfig {
    inner: Arc<RwLock<StartupConfig>>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ReferenceAError {
    InvalidValue,
    OutOfRange,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum StartupConfigValidationError {
    InvalidReferenceA(ReferenceAError),
    InvalidTransposition(TranspositionError),
    InvalidTemperament(TemperamentError),
}

#[derive(Clone, Debug, PartialEq)]
pub enum StartupConfigError {
    MissingValue(&'static str),
    ToolMissingValue(&'static str),
    InvalidReferenceFrequency(String),
    InvalidTransposition(String),
    InvalidTemperament(String),
    UnexpectedArgument(String),
    ToolUnexpectedArgument(String),
}

impl Default for StartupConfig {
    fn default() -> Self {
        Self {
            reference_a_hz: DEFAULT_REFERENCE_A_HZ,
            transposition_semitones: DEFAULT_TRANSPOSITION_SEMITONES,
            temperament: Temperament::equal(),
        }
    }
}

impl StartupConfig {
    pub fn new(
        reference_a_hz: f64,
        transposition_semitones: i32,
        temperament: Temperament,
    ) -> Result<Self, StartupConfigValidationError> {
        Ok(Self {
            reference_a_hz: validate_reference_a_hz(reference_a_hz)
                .map_err(StartupConfigValidationError::InvalidReferenceA)?,
            transposition_semitones: validate_transposition_semitones(transposition_semitones)
                .map_err(StartupConfigValidationError::InvalidTransposition)?,
            temperament,
        })
    }
}

impl SharedConfig {
    pub fn new(startup_config: StartupConfig) -> Self {
        Self {
            inner: Arc::new(RwLock::new(startup_config)),
        }
    }

    pub fn reference_a_hz(&self) -> f64 {
        self.inner
            .read()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
            .reference_a_hz
    }

    pub fn transposition_semitones(&self) -> i32 {
        self.inner
            .read()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
            .transposition_semitones
    }

    pub fn tuning_model(&self) -> TuningModel {
        let config = self
            .inner
            .read()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
            .clone();

        TuningModel::with_temperament(
            config.reference_a_hz,
            config.transposition_semitones,
            config.temperament,
        )
        .expect("shared config should contain a valid tuning model")
    }

    pub fn set_reference_a_hz(&self, reference_a_hz: f64) -> Result<(), ReferenceAError> {
        let mut config = self
            .inner
            .write()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        config.reference_a_hz = validate_reference_a_hz(reference_a_hz)?;
        Ok(())
    }

    pub fn set_transposition_semitones(
        &self,
        transposition_semitones: i32,
    ) -> Result<(), TranspositionError> {
        let mut config = self
            .inner
            .write()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        config.transposition_semitones = validate_transposition_semitones(transposition_semitones)?;
        Ok(())
    }

    pub fn set_temperament(&self, temperament: Temperament) {
        let mut config = self
            .inner
            .write()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        config.temperament = temperament;
    }
}

impl fmt::Display for StartupConfigValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            StartupConfigValidationError::InvalidReferenceA(error) => write!(f, "{error}"),
            StartupConfigValidationError::InvalidTransposition(error) => write!(f, "{error}"),
            StartupConfigValidationError::InvalidTemperament(error) => write!(f, "{error}"),
        }
    }
}

impl Error for StartupConfigValidationError {}

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
            StartupConfigError::ToolMissingValue(flag) => write!(f, "missing value for {flag}"),
            StartupConfigError::InvalidReferenceFrequency(value) => {
                write!(f, "invalid reference A frequency '{value}'")
            }
            StartupConfigError::InvalidTransposition(value) => {
                write!(f, "invalid transposition '{value}'")
            }
            StartupConfigError::InvalidTemperament(value) => {
                write!(f, "invalid temperament offsets '{value}'")
            }
            StartupConfigError::UnexpectedArgument(argument) => {
                write!(f, "unexpected argument '{argument}'")
            }
            StartupConfigError::ToolUnexpectedArgument(argument) => {
                write!(f, "unexpected argument '{argument}'")
            }
        }
    }
}

impl Error for StartupConfigError {}

impl StartupConfigError {
    pub fn is_tool_mode_error(&self) -> bool {
        matches!(
            self,
            StartupConfigError::ToolMissingValue(_) | StartupConfigError::ToolUnexpectedArgument(_)
        )
    }
}

pub fn validate_reference_a_hz(reference_a_hz: f64) -> Result<f64, ReferenceAError> {
    if !reference_a_hz.is_finite() || reference_a_hz <= 0.0 {
        return Err(ReferenceAError::InvalidValue);
    }
    if !(MIN_REFERENCE_A_HZ..=MAX_REFERENCE_A_HZ).contains(&reference_a_hz) {
        return Err(ReferenceAError::OutOfRange);
    }

    Ok(reference_a_hz)
}

pub fn parse_helper_cli<I>(args: I) -> Result<HelperCliAction, StartupConfigError>
where
    I: IntoIterator<Item = String>,
{
    let mut args = args.into_iter();
    let _program = args.next();
    let remaining_args: Vec<String> = args.collect();

    if remaining_args.is_empty() {
        return Ok(HelperCliAction::Run(StartupConfig::default()));
    }

    if matches!(
        remaining_args.first().map(String::as_str),
        Some("--dump-tuning-library")
    ) {
        return parse_dump_tuning_library_cli(&remaining_args);
    }
    if matches!(
        remaining_args.first().map(String::as_str),
        Some("--normalize-content-pack")
    ) || remaining_args
        .first()
        .map(|argument| argument.starts_with("--normalize-content-pack="))
        .unwrap_or(false)
    {
        return parse_normalize_content_pack_cli(&remaining_args);
    }

    let mut config = StartupConfig::default();
    let mut args = remaining_args.into_iter();

    while let Some(argument) = args.next() {
        if let Some(value) = argument.strip_prefix("--reference-a-hz=") {
            config.reference_a_hz = parse_reference_a_hz_argument(value)?;
            continue;
        }
        if let Some(value) = argument.strip_prefix("--transposition-semitones=") {
            config.transposition_semitones = parse_transposition_argument(value)?;
            continue;
        }
        if let Some(value) = argument.strip_prefix("--temperament-offsets-cents=") {
            config.temperament = parse_temperament_argument(value)?;
            continue;
        }

        match argument.as_str() {
            "-h" | "--help" => return Ok(HelperCliAction::PrintHelp),
            "-V" | "--version" => return Ok(HelperCliAction::PrintVersion),
            "--reference-a-hz" => {
                let value = args
                    .next()
                    .ok_or(StartupConfigError::MissingValue("--reference-a-hz"))?;
                config.reference_a_hz = parse_reference_a_hz_argument(&value)?;
            }
            "--transposition-semitones" => {
                let value = args.next().ok_or(StartupConfigError::MissingValue(
                    "--transposition-semitones",
                ))?;
                config.transposition_semitones = parse_transposition_argument(&value)?;
            }
            "--temperament-offsets-cents" => {
                let value = args.next().ok_or(StartupConfigError::MissingValue(
                    "--temperament-offsets-cents",
                ))?;
                config.temperament = parse_temperament_argument(&value)?;
            }
            _ => return Err(StartupConfigError::UnexpectedArgument(argument)),
        }
    }

    Ok(HelperCliAction::Run(config))
}

fn parse_dump_tuning_library_cli(args: &[String]) -> Result<HelperCliAction, StartupConfigError> {
    if args.len() > 1 {
        return Err(StartupConfigError::ToolUnexpectedArgument(args[1].clone()));
    }

    Ok(HelperCliAction::DumpTuningLibrary)
}

fn parse_normalize_content_pack_cli(
    args: &[String],
) -> Result<HelperCliAction, StartupConfigError> {
    let first_argument =
        args.first()
            .map(String::as_str)
            .ok_or(StartupConfigError::ToolMissingValue(
                "--normalize-content-pack",
            ))?;

    if let Some(value) = first_argument.strip_prefix("--normalize-content-pack=") {
        if args.len() > 1 {
            return Err(StartupConfigError::ToolUnexpectedArgument(args[1].clone()));
        }
        if value.trim().is_empty() {
            return Err(StartupConfigError::ToolMissingValue(
                "--normalize-content-pack",
            ));
        }
        return Ok(HelperCliAction::NormalizeContentPack {
            json: value.to_owned(),
        });
    }

    let json = args.get(1).ok_or(StartupConfigError::ToolMissingValue(
        "--normalize-content-pack",
    ))?;
    if args.len() > 2 {
        return Err(StartupConfigError::ToolUnexpectedArgument(args[2].clone()));
    }

    Ok(HelperCliAction::NormalizeContentPack { json: json.clone() })
}

fn parse_reference_a_hz_argument(value: &str) -> Result<f64, StartupConfigError> {
    let reference_a_hz = value
        .trim()
        .parse::<f64>()
        .map_err(|_| StartupConfigError::InvalidReferenceFrequency(value.to_owned()))?;

    validate_reference_a_hz(reference_a_hz)
        .map_err(|_| StartupConfigError::InvalidReferenceFrequency(value.to_owned()))
}

fn parse_transposition_argument(value: &str) -> Result<i32, StartupConfigError> {
    let transposition_semitones = value
        .trim()
        .parse::<i32>()
        .map_err(|_| StartupConfigError::InvalidTransposition(value.to_owned()))?;

    validate_transposition_semitones(transposition_semitones)
        .map_err(|_| StartupConfigError::InvalidTransposition(value.to_owned()))
}

fn parse_temperament_argument(value: &str) -> Result<Temperament, StartupConfigError> {
    let offsets = value
        .split(',')
        .map(str::trim)
        .map(|part| {
            part.parse::<f64>()
                .map_err(|_| StartupConfigError::InvalidTemperament(value.to_owned()))
        })
        .collect::<Result<Vec<_>, _>>()?;

    Temperament::from_offset_slice(&offsets)
        .map_err(|_| StartupConfigError::InvalidTemperament(value.to_owned()))
}

#[cfg(test)]
mod tests {
    use super::{
        parse_helper_cli, validate_reference_a_hz, HelperCliAction, ReferenceAError, StartupConfig,
        StartupConfigError, MAX_REFERENCE_A_HZ, MIN_REFERENCE_A_HZ,
    };
    use crate::note::{
        validate_transposition_semitones, Temperament, TranspositionError, DEFAULT_REFERENCE_A_HZ,
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
    fn validates_transposition_range() {
        assert_eq!(validate_transposition_semitones(0).unwrap(), 0);
        assert_eq!(validate_transposition_semitones(12).unwrap(), 12);
        assert_eq!(
            validate_transposition_semitones(13).unwrap_err(),
            TranspositionError::OutOfRange
        );
    }

    #[test]
    fn parses_default_and_explicit_reference_a_values() {
        assert_eq!(
            parse_helper_cli(vec!["omatune-helper".to_owned()]).unwrap(),
            HelperCliAction::Run(StartupConfig::default())
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--reference-a-hz".to_owned(),
                "442.0".to_owned(),
            ])
            .unwrap(),
            HelperCliAction::Run(StartupConfig {
                reference_a_hz: 442.0,
                transposition_semitones: 0,
                temperament: Temperament::equal(),
            })
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--reference-a-hz=432".to_owned(),
            ])
            .unwrap(),
            HelperCliAction::Run(StartupConfig {
                reference_a_hz: 432.0,
                transposition_semitones: 0,
                temperament: Temperament::equal(),
            })
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--transposition-semitones".to_owned(),
                "2".to_owned(),
            ])
            .unwrap(),
            HelperCliAction::Run(StartupConfig {
                reference_a_hz: DEFAULT_REFERENCE_A_HZ,
                transposition_semitones: 2,
                temperament: Temperament::equal(),
            })
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--reference-a-hz=432".to_owned(),
                "--transposition-semitones=9".to_owned(),
            ])
            .unwrap(),
            HelperCliAction::Run(StartupConfig {
                reference_a_hz: 432.0,
                transposition_semitones: 9,
                temperament: Temperament::equal(),
            })
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--temperament-offsets-cents".to_owned(),
                "0,0,0,0,0,0,0,0,0,0,0,0".to_owned(),
            ])
            .unwrap(),
            HelperCliAction::Run(StartupConfig {
                reference_a_hz: DEFAULT_REFERENCE_A_HZ,
                transposition_semitones: 0,
                temperament: Temperament::equal(),
            })
        );
    }

    #[test]
    fn parses_tool_modes_without_starting_audio() {
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--dump-tuning-library".to_owned(),
            ])
            .unwrap(),
            HelperCliAction::DumpTuningLibrary
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--normalize-content-pack".to_owned(),
                r#"{"kind":"preset_pack","id":"shared.pack","label":"Pack","groups":[{"id":"guitar","label":"Guitar","presets":[{"id":"shared.one","label":"One","targets":["E2"]}]}]}"#.to_owned(),
            ])
            .unwrap(),
            HelperCliAction::NormalizeContentPack {
                json: r#"{"kind":"preset_pack","id":"shared.pack","label":"Pack","groups":[{"id":"guitar","label":"Guitar","presets":[{"id":"shared.one","label":"One","targets":["E2"]}]}]}"#.to_owned(),
            }
        );
    }

    #[test]
    fn parses_help_and_version_flags_without_starting_audio() {
        assert_eq!(
            parse_helper_cli(vec!["omatune-helper".to_owned(), "--help".to_owned()]).unwrap(),
            HelperCliAction::PrintHelp
        );
        assert_eq!(
            parse_helper_cli(vec!["omatune-helper".to_owned(), "-h".to_owned()]).unwrap(),
            HelperCliAction::PrintHelp
        );
        assert_eq!(
            parse_helper_cli(vec!["omatune-helper".to_owned(), "--version".to_owned()]).unwrap(),
            HelperCliAction::PrintVersion
        );
        assert_eq!(
            parse_helper_cli(vec!["omatune-helper".to_owned(), "-V".to_owned()]).unwrap(),
            HelperCliAction::PrintVersion
        );
    }

    #[test]
    fn rejects_invalid_startup_arguments() {
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--reference-a-hz".to_owned(),
            ])
            .unwrap_err(),
            StartupConfigError::MissingValue("--reference-a-hz")
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--transposition-semitones".to_owned(),
            ])
            .unwrap_err(),
            StartupConfigError::MissingValue("--transposition-semitones")
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--reference-a-hz".to_owned(),
                "399.0".to_owned(),
            ])
            .unwrap_err(),
            StartupConfigError::InvalidReferenceFrequency("399.0".to_owned())
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--transposition-semitones".to_owned(),
                "13".to_owned(),
            ])
            .unwrap_err(),
            StartupConfigError::InvalidTransposition("13".to_owned())
        );
        assert_eq!(
            parse_helper_cli(vec!["omatune-helper".to_owned(), "--unknown".to_owned(),])
                .unwrap_err(),
            StartupConfigError::UnexpectedArgument("--unknown".to_owned())
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--temperament-offsets-cents".to_owned(),
                "0,0,0".to_owned(),
            ])
            .unwrap_err(),
            StartupConfigError::InvalidTemperament("0,0,0".to_owned())
        );
        assert_eq!(
            parse_helper_cli(vec![
                "omatune-helper".to_owned(),
                "--normalize-content-pack".to_owned(),
            ])
            .unwrap_err(),
            StartupConfigError::ToolMissingValue("--normalize-content-pack")
        );
    }
}
