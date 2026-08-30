use crate::note::{Note, Temperament, PITCH_CLASSES_PER_OCTAVE};
use serde::Serialize;
use serde_json::Value;
use std::fmt;

pub const CONTENT_PACK_SCHEMA_VERSION: u32 = 1;
pub const DEFAULT_TEMPERAMENT_ID: &str = "equal.12tet";
pub const DEFAULT_PRESET_ID: &str = "guitar.standard";

const MAX_PRESET_TARGETS: usize = 12;
const FIFTH_STEPS_FROM_A: [i32; PITCH_CLASSES_PER_OCTAVE] =
    [-3, 4, -1, 6, 1, -4, 3, -2, 5, 0, -5, 2];
const PYTHAGOREAN_FIFTH_DELTA_CENTS: f64 = 701.955_000_865_387_4 - 700.0;
const SYNTONIC_COMMA_CENTS: f64 = 21.506_289_596_714_78;
const QUARTER_COMMA_MEANTONE_FIFTH_DELTA_CENTS: f64 =
    (701.955_000_865_387_4 - (SYNTONIC_COMMA_CENTS / 4.0)) - 700.0;
const SIXTH_COMMA_MEANTONE_FIFTH_DELTA_CENTS: f64 =
    (701.955_000_865_387_4 - (SYNTONIC_COMMA_CENTS / 6.0)) - 700.0;

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ContentPackKind {
    TemperamentPack,
    PresetPack,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct TuningLibrary {
    pub schema_version: u32,
    pub default_temperament_id: String,
    pub default_preset_id: String,
    pub temperament_packs: Vec<TemperamentPack>,
    pub preset_packs: Vec<PresetPack>,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct TemperamentPack {
    pub schema_version: u32,
    pub kind: ContentPackKind,
    pub id: String,
    pub label: String,
    #[serde(skip_serializing_if = "String::is_empty")]
    pub description: String,
    pub temperaments: Vec<TemperamentDefinition>,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct TemperamentDefinition {
    pub id: String,
    pub label: String,
    #[serde(skip_serializing_if = "String::is_empty")]
    pub description: String,
    pub offsets_cents: Vec<f64>,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct PresetPack {
    pub schema_version: u32,
    pub kind: ContentPackKind,
    pub id: String,
    pub label: String,
    #[serde(skip_serializing_if = "String::is_empty")]
    pub description: String,
    pub groups: Vec<PresetGroup>,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct PresetGroup {
    pub id: String,
    pub label: String,
    pub presets: Vec<TuningPreset>,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct TuningPreset {
    pub id: String,
    pub label: String,
    #[serde(skip_serializing_if = "String::is_empty")]
    pub description: String,
    pub targets: Vec<PresetTarget>,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct PresetTarget {
    pub note: Note,
    pub label: String,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(untagged)]
pub enum ContentPack {
    TemperamentPack(TemperamentPack),
    PresetPack(PresetPack),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ContentPackError(String);

pub fn built_in_tuning_library() -> TuningLibrary {
    TuningLibrary {
        schema_version: CONTENT_PACK_SCHEMA_VERSION,
        default_temperament_id: DEFAULT_TEMPERAMENT_ID.to_owned(),
        default_preset_id: DEFAULT_PRESET_ID.to_owned(),
        temperament_packs: vec![built_in_temperament_pack()],
        preset_packs: vec![built_in_core_preset_pack(), built_in_extended_preset_pack()],
    }
}

pub fn normalize_content_pack_json(input: &str) -> Result<ContentPack, ContentPackError> {
    let value: Value = serde_json::from_str(input)
        .map_err(|error| ContentPackError::new(format!("invalid JSON: {error}")))?;
    normalize_content_pack_value(&value)
}

pub fn normalize_content_pack_value(value: &Value) -> Result<ContentPack, ContentPackError> {
    let object = value
        .as_object()
        .ok_or_else(|| ContentPackError::new("content pack must be a JSON object".to_owned()))?;

    let kind = required_string_field(object, "kind")?;
    match kind.as_str() {
        "temperament_pack" => Ok(ContentPack::TemperamentPack(normalize_temperament_pack(
            object,
        )?)),
        "preset_pack" => Ok(ContentPack::PresetPack(normalize_preset_pack(object)?)),
        other => Err(ContentPackError::new(format!(
            "unsupported content pack kind '{other}'; expected 'temperament_pack' or 'preset_pack'"
        ))),
    }
}

impl ContentPack {
    pub fn id(&self) -> &str {
        match self {
            ContentPack::TemperamentPack(pack) => &pack.id,
            ContentPack::PresetPack(pack) => &pack.id,
        }
    }
}

impl ContentPackError {
    fn new(message: String) -> Self {
        Self(message)
    }
}

impl fmt::Display for ContentPackError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl std::error::Error for ContentPackError {}

fn built_in_temperament_pack() -> TemperamentPack {
    TemperamentPack {
        schema_version: CONTENT_PACK_SCHEMA_VERSION,
        kind: ContentPackKind::TemperamentPack,
        id: "builtins.temperaments".to_owned(),
        label: "Temperaments".to_owned(),
        description: "A-anchored chromatic temperaments that keep A4 fixed at the configured reference frequency.".to_owned(),
        temperaments: vec![
            equal_temperament_definition(),
            fifth_delta_temperament_definition(
                "pythagorean.fifths",
                "Pythagorean Fifths",
                "Pure-fifth chain with pitch-class offsets anchored so A remains at the configured reference frequency.",
                PYTHAGOREAN_FIFTH_DELTA_CENTS,
            ),
            fifth_delta_temperament_definition(
                "meantone.sixth_comma",
                "1/6-Comma Meantone",
                "A gentler meantone compromise that sweetens thirds while staying closer to equal temperament.",
                SIXTH_COMMA_MEANTONE_FIFTH_DELTA_CENTS,
            ),
            fifth_delta_temperament_definition(
                "meantone.quarter_comma",
                "1/4-Comma Meantone",
                "A stronger meantone flavor for sweeter thirds and more pronounced pitch-class offsets.",
                QUARTER_COMMA_MEANTONE_FIFTH_DELTA_CENTS,
            ),
        ],
    }
}

fn built_in_core_preset_pack() -> PresetPack {
    PresetPack {
        schema_version: CONTENT_PACK_SCHEMA_VERSION,
        kind: ContentPackKind::PresetPack,
        id: "builtins.core_strings".to_owned(),
        label: "Core Strings".to_owned(),
        description: "Common default tunings for fretted and bowed string instruments.".to_owned(),
        groups: vec![
            preset_group(
                "guitar",
                "Guitar",
                vec![
                    tuning_preset(
                        "guitar.standard",
                        "Standard",
                        "Six-string standard guitar tuning.",
                        &["E2", "A2", "D3", "G3", "B3", "E4"],
                    ),
                    tuning_preset(
                        "guitar.drop_d",
                        "Drop D",
                        "Standard guitar with the sixth string lowered to D.",
                        &["D2", "A2", "D3", "G3", "B3", "E4"],
                    ),
                    tuning_preset(
                        "guitar.dadgad",
                        "DADGAD",
                        "Common open suspended guitar tuning.",
                        &["D2", "A2", "D3", "G3", "A3", "D4"],
                    ),
                ],
            ),
            preset_group(
                "bass",
                "Bass",
                vec![
                    tuning_preset(
                        "bass.standard_4",
                        "4-string",
                        "Standard four-string bass tuning.",
                        &["E1", "A1", "D2", "G2"],
                    ),
                    tuning_preset(
                        "bass.standard_5",
                        "5-string",
                        "Standard five-string bass tuning with low B.",
                        &["B0", "E1", "A1", "D2", "G2"],
                    ),
                    tuning_preset(
                        "bass.standard_6",
                        "6-string",
                        "Standard six-string bass tuning.",
                        &["B0", "E1", "A1", "D2", "G2", "C3"],
                    ),
                ],
            ),
            preset_group(
                "ukulele",
                "Ukulele",
                vec![
                    tuning_preset(
                        "ukulele.standard",
                        "Standard",
                        "Re-entrant soprano, concert, and tenor ukulele tuning.",
                        &["G4", "C4", "E4", "A4"],
                    ),
                    tuning_preset(
                        "ukulele.baritone",
                        "Baritone",
                        "Baritone ukulele tuning.",
                        &["D3", "G3", "B3", "E4"],
                    ),
                ],
            ),
            preset_group(
                "violin_family",
                "Violin Family",
                vec![
                    tuning_preset(
                        "violin.violin",
                        "Violin",
                        "Standard violin tuning in fifths.",
                        &["G3", "D4", "A4", "E5"],
                    ),
                    tuning_preset(
                        "violin.viola",
                        "Viola",
                        "Standard viola tuning in fifths.",
                        &["C3", "G3", "D4", "A4"],
                    ),
                    tuning_preset(
                        "violin.cello",
                        "Cello",
                        "Standard cello tuning in fifths.",
                        &["C2", "G2", "D3", "A3"],
                    ),
                    tuning_preset(
                        "violin.double_bass",
                        "Double Bass",
                        "Standard double-bass tuning in fourths.",
                        &["E1", "A1", "D2", "G2"],
                    ),
                ],
            ),
            preset_group(
                "mandolin_family",
                "Mandolin Family",
                vec![
                    tuning_preset(
                        "mandolin.standard",
                        "Mandolin",
                        "Standard mandolin tuning in fifths.",
                        &["G3", "D4", "A4", "E5"],
                    ),
                    tuning_preset(
                        "mandola.standard",
                        "Mandola",
                        "Standard mandola tuning in fifths.",
                        &["C3", "G3", "D4", "A4"],
                    ),
                ],
            ),
        ],
    }
}

fn built_in_extended_preset_pack() -> PresetPack {
    PresetPack {
        schema_version: CONTENT_PACK_SCHEMA_VERSION,
        kind: ContentPackKind::PresetPack,
        id: "builtins.extended_strings".to_owned(),
        label: "Extended Strings".to_owned(),
        description: "Broader string-instrument presets for lower ranges and alternate ensembles."
            .to_owned(),
        groups: vec![
            preset_group(
                "extended_guitar",
                "Extended Guitar",
                vec![
                    tuning_preset(
                        "guitar.standard_7",
                        "7-string",
                        "Standard seven-string guitar tuning.",
                        &["B1", "E2", "A2", "D3", "G3", "B3", "E4"],
                    ),
                    tuning_preset(
                        "guitar.standard_8",
                        "8-string",
                        "Standard eight-string guitar tuning.",
                        &["F#1", "B1", "E2", "A2", "D3", "G3", "B3", "E4"],
                    ),
                ],
            ),
            preset_group(
                "folk_and_plucked",
                "Folk And Plucked",
                vec![
                    tuning_preset(
                        "banjo.open_g",
                        "Banjo Open G",
                        "Common five-string banjo tuning with the short drone string.",
                        &["G4", "D3", "G3", "B3", "D4"],
                    ),
                    tuning_preset(
                        "tenor_guitar.standard",
                        "Tenor Guitar",
                        "Common tenor guitar tuning in fifths.",
                        &["C3", "G3", "D4", "A4"],
                    ),
                ],
            ),
        ],
    }
}

fn equal_temperament_definition() -> TemperamentDefinition {
    temperament_definition(
        DEFAULT_TEMPERAMENT_ID,
        "Equal 12-TET",
        "The v1.x default: twelve-tone equal temperament with zero pitch-class offsets.",
        Temperament::equal(),
    )
}

fn fifth_delta_temperament_definition(
    id: &str,
    label: &str,
    description: &str,
    fifth_delta_cents: f64,
) -> TemperamentDefinition {
    let offsets_cents = FIFTH_STEPS_FROM_A.map(|steps| steps as f64 * fifth_delta_cents);
    let temperament = Temperament::from_offsets_cents(offsets_cents)
        .expect("built-in fifth-chain temperament should be valid");
    temperament_definition(id, label, description, temperament)
}

fn temperament_definition(
    id: &str,
    label: &str,
    description: &str,
    temperament: Temperament,
) -> TemperamentDefinition {
    TemperamentDefinition {
        id: id.to_owned(),
        label: label.to_owned(),
        description: description.to_owned(),
        offsets_cents: temperament.offsets_cents().into_iter().collect(),
    }
}

fn preset_group(id: &str, label: &str, presets: Vec<TuningPreset>) -> PresetGroup {
    PresetGroup {
        id: id.to_owned(),
        label: label.to_owned(),
        presets,
    }
}

fn tuning_preset(id: &str, label: &str, description: &str, targets: &[&str]) -> TuningPreset {
    TuningPreset {
        id: id.to_owned(),
        label: label.to_owned(),
        description: description.to_owned(),
        targets: targets
            .iter()
            .map(|note| preset_target(note, None))
            .collect(),
    }
}

fn preset_target(note: &str, label: Option<&str>) -> PresetTarget {
    let parsed_note = note
        .parse::<Note>()
        .expect("built-in preset target should parse as a supported note");

    PresetTarget {
        note: parsed_note,
        label: label.unwrap_or(note).to_owned(),
    }
}

fn normalize_temperament_pack(
    object: &serde_json::Map<String, Value>,
) -> Result<TemperamentPack, ContentPackError> {
    let schema_version = parse_schema_version(object)?;
    let id = normalize_identifier("temperament pack id", &required_string_field(object, "id")?)?;
    reject_builtin_pack_id_conflict(&id)?;
    let label = normalize_label(
        "temperament pack label",
        &required_string_field(object, "label")?,
    )?;
    let description = optional_string_field(object, "description")
        .map(|value| value.trim().to_owned())
        .unwrap_or_default();
    let temperaments_value = required_array_field(object, "temperaments")?;
    if temperaments_value.is_empty() {
        return Err(ContentPackError::new(
            "temperament pack must contain at least one temperament".to_owned(),
        ));
    }

    let mut temperaments = Vec::with_capacity(temperaments_value.len());
    let mut seen_temperament_ids = Vec::with_capacity(temperaments_value.len());
    for temperament_value in temperaments_value {
        let temperament_object = temperament_value.as_object().ok_or_else(|| {
            ContentPackError::new("temperament entries must be JSON objects".to_owned())
        })?;

        let temperament_id = normalize_identifier(
            "temperament id",
            &required_string_field(temperament_object, "id")?,
        )?;
        if seen_temperament_ids.contains(&temperament_id) {
            return Err(ContentPackError::new(format!(
                "temperament id '{}' appears more than once in pack '{}'",
                temperament_id, id
            )));
        }
        reject_builtin_temperament_id_conflict(&temperament_id)?;

        let temperament_label = normalize_label(
            "temperament label",
            &required_string_field(temperament_object, "label")?,
        )?;
        let temperament_description = optional_string_field(temperament_object, "description")
            .map(|value| value.trim().to_owned())
            .unwrap_or_default();
        let offsets_cents = parse_temperament_offsets_cents(temperament_object, "offsets_cents")?;
        let temperament = Temperament::from_offset_slice(&offsets_cents).map_err(|error| {
            ContentPackError::new(format!("invalid temperament '{}': {error}", temperament_id))
        })?;

        seen_temperament_ids.push(temperament_id.clone());
        temperaments.push(TemperamentDefinition {
            id: temperament_id,
            label: temperament_label,
            description: temperament_description,
            offsets_cents: temperament.offsets_cents().into_iter().collect(),
        });
    }

    Ok(TemperamentPack {
        schema_version,
        kind: ContentPackKind::TemperamentPack,
        id,
        label,
        description,
        temperaments,
    })
}

fn normalize_preset_pack(
    object: &serde_json::Map<String, Value>,
) -> Result<PresetPack, ContentPackError> {
    let schema_version = parse_schema_version(object)?;
    let id = normalize_identifier("preset pack id", &required_string_field(object, "id")?)?;
    reject_builtin_pack_id_conflict(&id)?;
    let label = normalize_label(
        "preset pack label",
        &required_string_field(object, "label")?,
    )?;
    let description = optional_string_field(object, "description")
        .map(|value| value.trim().to_owned())
        .unwrap_or_default();
    let groups_value = required_array_field(object, "groups")?;
    if groups_value.is_empty() {
        return Err(ContentPackError::new(
            "preset pack must contain at least one group".to_owned(),
        ));
    }

    let mut groups = Vec::with_capacity(groups_value.len());
    let mut seen_group_ids = Vec::with_capacity(groups_value.len());
    let mut seen_preset_ids = Vec::new();

    for group_value in groups_value {
        let group_object = group_value.as_object().ok_or_else(|| {
            ContentPackError::new("preset groups must be JSON objects".to_owned())
        })?;
        let group_id = normalize_identifier(
            "preset group id",
            &required_string_field(group_object, "id")?,
        )?;
        if seen_group_ids.contains(&group_id) {
            return Err(ContentPackError::new(format!(
                "preset group id '{}' appears more than once in pack '{}'",
                group_id, id
            )));
        }
        seen_group_ids.push(group_id.clone());

        let group_label = normalize_label(
            "preset group label",
            &required_string_field(group_object, "label")?,
        )?;
        let presets_value = required_array_field(group_object, "presets")?;
        if presets_value.is_empty() {
            return Err(ContentPackError::new(format!(
                "preset group '{}' must contain at least one preset",
                group_id
            )));
        }

        let mut presets = Vec::with_capacity(presets_value.len());
        for preset_value in presets_value {
            let preset_object = preset_value.as_object().ok_or_else(|| {
                ContentPackError::new("preset entries must be JSON objects".to_owned())
            })?;
            let preset_id =
                normalize_identifier("preset id", &required_string_field(preset_object, "id")?)?;
            if seen_preset_ids.contains(&preset_id) {
                return Err(ContentPackError::new(format!(
                    "preset id '{}' appears more than once in pack '{}'",
                    preset_id, id
                )));
            }
            reject_builtin_preset_id_conflict(&preset_id)?;

            let preset_label = normalize_label(
                "preset label",
                &required_string_field(preset_object, "label")?,
            )?;
            let preset_description = optional_string_field(preset_object, "description")
                .map(|value| value.trim().to_owned())
                .unwrap_or_default();
            let targets = parse_preset_targets(preset_object)?;

            seen_preset_ids.push(preset_id.clone());
            presets.push(TuningPreset {
                id: preset_id,
                label: preset_label,
                description: preset_description,
                targets,
            });
        }

        groups.push(PresetGroup {
            id: group_id,
            label: group_label,
            presets,
        });
    }

    Ok(PresetPack {
        schema_version,
        kind: ContentPackKind::PresetPack,
        id,
        label,
        description,
        groups,
    })
}

fn parse_schema_version(object: &serde_json::Map<String, Value>) -> Result<u32, ContentPackError> {
    let Some(schema_version_value) = object.get("schema_version") else {
        return Ok(CONTENT_PACK_SCHEMA_VERSION);
    };

    let schema_version = schema_version_value.as_u64().ok_or_else(|| {
        ContentPackError::new("schema_version must be a positive integer".to_owned())
    })?;
    let schema_version = u32::try_from(schema_version).map_err(|_| {
        ContentPackError::new("schema_version is outside the supported integer range".to_owned())
    })?;

    if schema_version != CONTENT_PACK_SCHEMA_VERSION {
        return Err(ContentPackError::new(format!(
            "schema_version {} is unsupported; expected {}",
            schema_version, CONTENT_PACK_SCHEMA_VERSION
        )));
    }

    Ok(schema_version)
}

fn parse_temperament_offsets_cents(
    object: &serde_json::Map<String, Value>,
    field_name: &str,
) -> Result<Vec<f64>, ContentPackError> {
    let offsets = required_array_field(object, field_name)?;
    if offsets.len() != PITCH_CLASSES_PER_OCTAVE {
        return Err(ContentPackError::new(format!(
            "{} must contain exactly {} pitch-class offsets in C, C#, D, D#, E, F, F#, G, G#, A, A#, B order",
            field_name, PITCH_CLASSES_PER_OCTAVE
        )));
    }

    let mut normalized = Vec::with_capacity(PITCH_CLASSES_PER_OCTAVE);
    for offset_value in offsets {
        let offset_cents = offset_value.as_f64().ok_or_else(|| {
            ContentPackError::new(format!(
                "{} must contain only numeric cents offsets",
                field_name
            ))
        })?;
        normalized.push(offset_cents);
    }

    Ok(normalized)
}

fn parse_preset_targets(
    object: &serde_json::Map<String, Value>,
) -> Result<Vec<PresetTarget>, ContentPackError> {
    let targets = if let Some(targets_value) = object.get("targets") {
        targets_value.as_array().ok_or_else(|| {
            ContentPackError::new("preset field 'targets' must be an array".to_owned())
        })?
    } else if let Some(notes_value) = object.get("notes") {
        notes_value.as_array().ok_or_else(|| {
            ContentPackError::new("preset field 'notes' must be an array".to_owned())
        })?
    } else {
        return Err(ContentPackError::new(
            "preset requires an array field named 'targets' or legacy field 'notes'".to_owned(),
        ));
    };

    if targets.is_empty() {
        return Err(ContentPackError::new(
            "preset must contain at least one target note".to_owned(),
        ));
    }
    if targets.len() > MAX_PRESET_TARGETS {
        return Err(ContentPackError::new(format!(
            "preset supports at most {} target notes, got {}",
            MAX_PRESET_TARGETS,
            targets.len()
        )));
    }

    let mut normalized_targets = Vec::with_capacity(targets.len());
    let mut seen_notes = Vec::with_capacity(targets.len());
    for target_value in targets {
        let (note_text, label_text) = if let Some(note_text) = target_value.as_str() {
            (note_text.to_owned(), note_text.to_owned())
        } else {
            let target_object = target_value.as_object().ok_or_else(|| {
                ContentPackError::new(
                    "preset targets must be note strings or objects with 'note' and optional 'label'"
                        .to_owned(),
                )
            })?;

            let note_text = required_string_field(target_object, "note")?;
            let label_text = optional_string_field(target_object, "label")
                .map(|value| value.trim().to_owned())
                .filter(|value| !value.is_empty())
                .unwrap_or_else(|| note_text.clone());

            (note_text, label_text)
        };

        let note = note_text.parse::<Note>().map_err(|error| {
            ContentPackError::new(format!(
                "invalid preset target note '{}': {error}",
                note_text
            ))
        })?;
        if seen_notes.contains(&note) {
            return Err(ContentPackError::new(format!(
                "preset target note '{}' appears more than once",
                note
            )));
        }

        seen_notes.push(note);
        normalized_targets.push(PresetTarget {
            note,
            label: label_text,
        });
    }

    Ok(normalized_targets)
}

fn required_string_field(
    object: &serde_json::Map<String, Value>,
    field_name: &str,
) -> Result<String, ContentPackError> {
    object
        .get(field_name)
        .and_then(Value::as_str)
        .map(str::to_owned)
        .ok_or_else(|| ContentPackError::new(format!("missing string field '{}'", field_name)))
}

fn optional_string_field<'a>(
    object: &'a serde_json::Map<String, Value>,
    field_name: &str,
) -> Option<&'a str> {
    object.get(field_name).and_then(Value::as_str)
}

fn required_array_field<'a>(
    object: &'a serde_json::Map<String, Value>,
    field_name: &str,
) -> Result<&'a [Value], ContentPackError> {
    object
        .get(field_name)
        .and_then(Value::as_array)
        .map(Vec::as_slice)
        .ok_or_else(|| ContentPackError::new(format!("missing array field '{}'", field_name)))
}

fn normalize_identifier(field_name: &str, value: &str) -> Result<String, ContentPackError> {
    let trimmed = value.trim().to_ascii_lowercase();
    if trimmed.is_empty() {
        return Err(ContentPackError::new(format!(
            "{} must not be empty",
            field_name
        )));
    }
    if !trimmed.chars().all(|character| {
        character.is_ascii_lowercase()
            || character.is_ascii_digit()
            || matches!(character, '.' | '_' | '-')
    }) {
        return Err(ContentPackError::new(format!(
            "{} '{}' may contain only lowercase ASCII letters, digits, '.', '_' , and '-'",
            field_name, trimmed
        )));
    }

    Ok(trimmed)
}

fn normalize_label(field_name: &str, value: &str) -> Result<String, ContentPackError> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return Err(ContentPackError::new(format!(
            "{} must not be empty",
            field_name
        )));
    }

    Ok(trimmed.to_owned())
}

fn reject_builtin_pack_id_conflict(candidate_id: &str) -> Result<(), ContentPackError> {
    let built_in_library = built_in_tuning_library();
    if built_in_library
        .temperament_packs
        .iter()
        .any(|pack| pack.id == candidate_id)
        || built_in_library
            .preset_packs
            .iter()
            .any(|pack| pack.id == candidate_id)
    {
        return Err(ContentPackError::new(format!(
            "content pack id '{}' conflicts with a built-in pack",
            candidate_id
        )));
    }

    Ok(())
}

fn reject_builtin_temperament_id_conflict(candidate_id: &str) -> Result<(), ContentPackError> {
    if built_in_tuning_library()
        .temperament_packs
        .iter()
        .flat_map(|pack| pack.temperaments.iter())
        .any(|temperament| temperament.id == candidate_id)
    {
        return Err(ContentPackError::new(format!(
            "temperament id '{}' conflicts with a built-in temperament",
            candidate_id
        )));
    }

    Ok(())
}

fn reject_builtin_preset_id_conflict(candidate_id: &str) -> Result<(), ContentPackError> {
    if built_in_tuning_library()
        .preset_packs
        .iter()
        .flat_map(|pack| pack.groups.iter())
        .flat_map(|group| group.presets.iter())
        .any(|preset| preset.id == candidate_id)
    {
        return Err(ContentPackError::new(format!(
            "preset id '{}' conflicts with a built-in preset",
            candidate_id
        )));
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::{
        built_in_tuning_library, normalize_content_pack_json, ContentPack, ContentPackError,
        CONTENT_PACK_SCHEMA_VERSION, DEFAULT_PRESET_ID, DEFAULT_TEMPERAMENT_ID,
    };

    #[test]
    fn built_in_library_has_expected_defaults_and_broader_coverage() {
        let library = built_in_tuning_library();

        assert_eq!(library.schema_version, CONTENT_PACK_SCHEMA_VERSION);
        assert_eq!(library.default_temperament_id, DEFAULT_TEMPERAMENT_ID);
        assert_eq!(library.default_preset_id, DEFAULT_PRESET_ID);
        assert!(library
            .temperament_packs
            .iter()
            .flat_map(|pack| pack.temperaments.iter())
            .any(|temperament| temperament.id == "meantone.quarter_comma"));
        assert!(library
            .preset_packs
            .iter()
            .flat_map(|pack| pack.groups.iter())
            .flat_map(|group| group.presets.iter())
            .any(|preset| preset.id == "guitar.standard_8"));
        assert!(library
            .preset_packs
            .iter()
            .flat_map(|pack| pack.groups.iter())
            .flat_map(|group| group.presets.iter())
            .any(|preset| preset.id == "mandolin.standard"));
    }

    #[test]
    fn normalizes_temperament_pack_and_anchors_a_at_zero_cents() {
        let pack = normalize_content_pack_json(
            r#"{
                "kind": "temperament_pack",
                "id": "Shared.Custom",
                "label": "Shared Custom",
                "temperaments": [
                    {
                        "id": "Shared.Custom.Mild",
                        "label": "Mild",
                        "offsets_cents": [1,2,3,4,5,6,7,8,9,10,11,12]
                    }
                ]
            }"#,
        )
        .unwrap();

        let ContentPack::TemperamentPack(pack) = pack else {
            panic!("expected a normalized temperament pack");
        };

        assert_eq!(pack.id, "shared.custom");
        assert_eq!(pack.temperaments[0].id, "shared.custom.mild");
        assert_eq!(pack.temperaments[0].offsets_cents[9], 0.0);
        assert_eq!(pack.temperaments[0].offsets_cents[0], -9.0);
    }

    #[test]
    fn normalizes_preset_pack_targets_and_legacy_notes_field() {
        let pack = normalize_content_pack_json(
            r#"{
                "kind": "preset_pack",
                "id": "shared.alt_strings",
                "label": "Alt Strings",
                "groups": [
                    {
                        "id": "guitar",
                        "label": "Guitar",
                        "presets": [
                            {
                                "id": "guitar.low_c",
                                "label": "Low C",
                                "notes": ["C2", { "note": "G2", "label": "G string" }]
                            }
                        ]
                    }
                ]
            }"#,
        )
        .unwrap();

        let ContentPack::PresetPack(pack) = pack else {
            panic!("expected a normalized preset pack");
        };

        assert_eq!(pack.id, "shared.alt_strings");
        assert_eq!(pack.groups[0].presets[0].targets[0].note.to_string(), "C2");
        assert_eq!(pack.groups[0].presets[0].targets[0].label, "C2");
        assert_eq!(pack.groups[0].presets[0].targets[1].note.to_string(), "G2");
        assert_eq!(pack.groups[0].presets[0].targets[1].label, "G string");
    }

    #[test]
    fn rejects_conflicts_with_built_in_ids_and_unsupported_shapes() {
        assert_eq!(
            normalize_content_pack_json(
                r#"{
                    "kind": "temperament_pack",
                    "id": "builtins.temperaments",
                    "label": "Conflict",
                    "temperaments": []
                }"#,
            )
            .unwrap_err(),
            ContentPackError(
                "content pack id 'builtins.temperaments' conflicts with a built-in pack".to_owned()
            )
        );

        assert_eq!(
            normalize_content_pack_json(
                r#"{
                    "kind": "preset_pack",
                    "id": "shared.bad",
                    "label": "Bad",
                    "groups": [
                        {
                            "id": "guitar",
                            "label": "Guitar",
                            "presets": [
                                { "id": "shared.dup", "label": "One", "targets": ["E2"] },
                                { "id": "shared.dup", "label": "Two", "targets": ["A2"] }
                            ]
                        }
                    ]
                }"#,
            )
            .unwrap_err(),
            ContentPackError(
                "preset id 'shared.dup' appears more than once in pack 'shared.bad'".to_owned()
            )
        );

        assert_eq!(
            normalize_content_pack_json(
                r#"{
                    "kind": "temperament_pack",
                    "id": "shared.bad",
                    "label": "Bad",
                    "schema_version": 2,
                    "temperaments": [
                        {
                            "id": "shared.bad.one",
                            "label": "One",
                            "offsets_cents": [0,0,0,0,0,0,0,0,0,0,0,0]
                        }
                    ]
                }"#,
            )
            .unwrap_err(),
            ContentPackError("schema_version 2 is unsupported; expected 1".to_owned())
        );
    }
}
