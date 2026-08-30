import QtQml

QtObject {
  id: root

  required property var hostWidget

  readonly property int minimumReferenceMidiNumber: hostWidget.minimumReferenceMidiNumber
  readonly property int maximumReferenceMidiNumber: hostWidget.maximumReferenceMidiNumber
  readonly property real minimumReferenceAHz: hostWidget.minimumReferenceAHz
  readonly property real maximumReferenceAHz: hostWidget.maximumReferenceAHz
  readonly property int minimumTranspositionSemitones: hostWidget.minimumTranspositionSemitones
  readonly property int maximumTranspositionSemitones: hostWidget.maximumTranspositionSemitones
  readonly property int minimumMetronomeBpm: hostWidget.minimumMetronomeBpm
  readonly property int maximumMetronomeBpm: hostWidget.maximumMetronomeBpm
  readonly property int maximumReferenceIntervalSemitones: hostWidget.maximumReferenceIntervalSemitones
  readonly property int maximumPitchAnalysisHistoryPoints: hostWidget.maximumPitchAnalysisHistoryPoints
  readonly property int maximumFavoriteQuickSwitches: hostWidget.maximumFavoriteQuickSwitches
  readonly property int maximumRecentQuickSwitches: hostWidget.maximumRecentQuickSwitches
  readonly property int settingsConfigVersion: hostWidget.settingsConfigVersion
  readonly property int defaultMetronomeBpm: hostWidget.defaultMetronomeBpm
  readonly property int defaultMetronomeBeatsPerBar: hostWidget.defaultMetronomeBeatsPerBar
  readonly property int defaultMetronomeBeatUnit: hostWidget.defaultMetronomeBeatUnit
  readonly property int defaultMetronomeSubdivision: hostWidget.defaultMetronomeSubdivision
  readonly property int defaultReferenceIntervalSemitones: hostWidget.defaultReferenceIntervalSemitones
  readonly property string defaultReferenceChordId: hostWidget.defaultReferenceChordId
  readonly property string defaultReferenceSceneId: hostWidget.defaultReferenceSceneId
  readonly property string defaultReferenceWaveformId: hostWidget.defaultReferenceWaveformId
  readonly property string defaultPresetId: hostWidget.defaultPresetId
  readonly property string defaultTemperamentId: hostWidget.defaultTemperamentId
  readonly property string noteSpelling: hostWidget.noteSpelling
  readonly property string selectedPresetId: hostWidget.selectedPresetId
  readonly property string selectedTemperamentId: hostWidget.selectedTemperamentId
  readonly property int selectedReferenceMidiNumber: hostWidget.selectedReferenceMidiNumber
  readonly property int transpositionSemitones: hostWidget.transpositionSemitones
  readonly property string referencePlaybackMode: hostWidget.referencePlaybackMode
  readonly property int selectedReferenceIntervalSemitones: hostWidget.selectedReferenceIntervalSemitones
  readonly property string selectedReferenceChordId: hostWidget.selectedReferenceChordId
  readonly property string selectedReferenceSceneId: hostWidget.selectedReferenceSceneId
  readonly property string selectedReferenceWaveformId: hostWidget.selectedReferenceWaveformId
  readonly property string selectedReferenceCommandNoteLabel: hostWidget.selectedReferenceCommandNoteLabel
  readonly property bool toneActive: hostWidget.toneActive
  readonly property string activeToneNote: hostWidget.activeToneNote
  readonly property var activeToneIntervalsSemitones: hostWidget.activeToneIntervalsSemitones
  readonly property string activeToneSceneId: hostWidget.activeToneSceneId
  readonly property string activeToneWaveformId: hostWidget.activeToneWaveformId
  readonly property int metronomeBpm: hostWidget.metronomeBpm
  readonly property int metronomeBeatsPerBar: hostWidget.metronomeBeatsPerBar
  readonly property int metronomeBeatUnit: hostWidget.metronomeBeatUnit
  readonly property int metronomeSubdivision: hostWidget.metronomeSubdivision
  readonly property real referenceAHz: hostWidget.referenceAHz
  readonly property bool midiInputEnabled: hostWidget.midiInputEnabled
  readonly property string midiInputPortName: hostWidget.midiInputPortName
  readonly property bool highContrastMode: hostWidget.highContrastMode
  readonly property bool reducedMotionMode: hostWidget.reducedMotionMode
  readonly property bool analysisViewsEnabled: hostWidget.analysisViewsEnabled
  readonly property var favoriteQuickSwitches: hostWidget.favoriteQuickSwitches
  readonly property var recentQuickSwitches: hostWidget.recentQuickSwitches
  readonly property var builtInTemperamentPacks: hostWidget.builtInTemperamentPacks
  readonly property var importedTemperamentPacks: hostWidget.importedTemperamentPacks
  readonly property var builtInPresetPacks: hostWidget.builtInPresetPacks
  readonly property var importedPresetPacks: hostWidget.importedPresetPacks

  readonly property var metronomeMeterPresets: [
    { beatsPerBar: 2, beatUnit: 4, label: "2/4" },
    { beatsPerBar: 3, beatUnit: 4, label: "3/4" },
    { beatsPerBar: 4, beatUnit: 4, label: "4/4" },
    { beatsPerBar: 6, beatUnit: 8, label: "6/8" },
  ]
  readonly property var metronomeSubdivisionPresets: [
    { steps: 1, label: "Beat" },
    { steps: 2, label: "2x" },
    { steps: 3, label: "3x" },
    { steps: 4, label: "4x" },
  ]
  readonly property var sharpPitchClasses: ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
  readonly property var flatPitchClasses: ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
  readonly property var pitchClasses: noteSpelling === "flats" ? flatPitchClasses : sharpPitchClasses
  readonly property var transpositionPresets: [
    { semitones: 0, label: "Concert" },
    { semitones: 2, label: "Bb" },
    { semitones: 7, label: "F" },
    { semitones: 9, label: "Eb" },
  ]
  readonly property var referencePlaybackModes: ["single", "interval", "chord"]
  readonly property var referenceScenePresets: [
    { id: "close", value: "close", label: "Close" },
    { id: "bass_octave", value: "bass_octave", label: "Bass octave" },
  ]
  readonly property var referenceWaveformPresets: [
    { id: "sine", value: "sine", label: "Sine", summary: "Pure tone" },
    { id: "warm", value: "warm", label: "Warm", summary: "Gentle overtones" },
  ]
  readonly property var referenceIntervalPresets: [
    { semitones: 1, label: "m2" },
    { semitones: 2, label: "M2" },
    { semitones: 3, label: "m3" },
    { semitones: 4, label: "M3" },
    { semitones: 5, label: "P4" },
    { semitones: 6, label: "TT" },
    { semitones: 7, label: "P5" },
    { semitones: 8, label: "m6" },
    { semitones: 9, label: "M6" },
    { semitones: 10, label: "m7" },
    { semitones: 11, label: "M7" },
    { semitones: 12, label: "Oct" },
    { semitones: 13, label: "m9" },
    { semitones: 14, label: "M9" },
    { semitones: 17, label: "P11" },
    { semitones: 19, label: "P12" },
  ]
  readonly property var referenceChordPresets: [
    { id: "major", label: "Major", summary: "1 3 5", intervalsSemitones: [4, 7] },
    { id: "minor", label: "Minor", summary: "1 b3 5", intervalsSemitones: [3, 7] },
    { id: "sus2", label: "Sus2", summary: "1 2 5", intervalsSemitones: [2, 7] },
    { id: "sus4", label: "Sus4", summary: "1 4 5", intervalsSemitones: [5, 7] },
    { id: "diminished", label: "dim", summary: "1 b3 b5", intervalsSemitones: [3, 6] },
    { id: "dominant7", label: "7", summary: "1 3 5 b7", intervalsSemitones: [4, 7, 10] },
    { id: "major7", label: "\u25B37", summary: "1 3 5 7", intervalsSemitones: [4, 7, 11] },
    { id: "minor7", label: "m7", summary: "1 b3 5 b7", intervalsSemitones: [3, 7, 10] },
    { id: "minor_major7", label: "m\u25B37", summary: "1 b3 5 7", intervalsSemitones: [3, 7, 11] },
    { id: "m7b5", label: "m7b5", summary: "1 b3 b5 b7", intervalsSemitones: [3, 6, 10] },
    { id: "diminished7", label: "dim7", summary: "1 b3 b5 bb7", intervalsSemitones: [3, 6, 9] },
  ]
  readonly property var defaultTemperamentOffsetsCents: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  readonly property var fallbackTemperament: ({
    id: defaultTemperamentId,
    label: "Equal 12-TET",
    description: "The v1.x default equal temperament.",
    packId: "fallback.default",
    packLabel: "Default",
    source: "fallback",
    offsets_cents: defaultTemperamentOffsetsCents,
  })
  readonly property var fallbackPreset: ({
    id: defaultPresetId,
    label: "Standard",
    description: "Six-string standard guitar tuning.",
    groupId: "guitar",
    groupLabel: "Guitar",
    packId: "fallback.default",
    packLabel: "Default",
    source: "fallback",
    targets: [
      { note: "E2", label: "E2" },
      { note: "A2", label: "A2" },
      { note: "D3", label: "D3" },
      { note: "G3", label: "G3" },
      { note: "B3", label: "B3" },
      { note: "E4", label: "E4" },
    ],
  })
  readonly property var allTemperamentPacks: taggedContentPacks(builtInTemperamentPacks, importedTemperamentPacks, "temperament_pack")
  readonly property var allPresetPacks: taggedContentPacks(builtInPresetPacks, importedPresetPacks, "preset_pack")
  readonly property var temperamentPackSections: temperamentPackSectionsForDisplay(allTemperamentPacks)
  readonly property var tuningPresetGroups: presetGroupsForDisplay(allPresetPacks)
  readonly property var selectedPreset: presetById(selectedPresetId)
  readonly property var selectedPresetTargets: transposePresetTargets(selectedPreset.targets, transpositionSemitones)
  readonly property var selectedPresetNotes: selectedPresetTargetNotes(selectedPresetTargets)
  readonly property var selectedTemperament: temperamentById(selectedTemperamentId)
  readonly property var selectedTemperamentOffsetsCents: normalizedTemperamentOffsets(selectedTemperament.offsets_cents)
  readonly property string selectedTemperamentFingerprint: temperamentFingerprint(selectedTemperamentOffsetsCents)
  readonly property int selectedReferenceIntervalPresetIndex: indexOfReferenceIntervalPreset(selectedReferenceIntervalSemitones)
  readonly property int selectedReferenceChordPresetIndex: indexOfReferenceChordPreset(selectedReferenceChordId)
  readonly property int selectedReferenceWaveformPresetIndex: indexOfReferenceWaveformPreset(selectedReferenceWaveformId)
  readonly property var selectedReferenceIntervalsSemitones: referenceSelectionIntervals(
    referencePlaybackMode,
    selectedReferenceIntervalSemitones,
    selectedReferenceChordId
  )
  readonly property var selectedReferencePreviewVoiceLabels: previewReferenceVoiceLabels(
    selectedReferenceMidiNumber,
    transpositionSemitones,
    selectedReferenceIntervalsSemitones,
    selectedReferenceSceneId
  )
  readonly property int selectedMetronomeMeterPresetIndex: indexOfMetronomeMeterPreset(metronomeBeatsPerBar, metronomeBeatUnit)
  readonly property int selectedMetronomeSubdivisionPresetIndex: indexOfMetronomeSubdivisionPreset(metronomeSubdivision)
  readonly property var visibleRecentQuickSwitches: recentQuickSwitchesForDisplay()

  function parseJsonObject(raw) {
    var text = String(raw || "").trim()
    if (text === "") return null

    try {
      var value = JSON.parse(text)
      return value && typeof value === "object" ? value : null
    } catch (error) {
      return null
    }
  }

  function finiteNumber(value, fallback) {
    var numeric = Number(value)
    return isFinite(numeric) ? numeric : fallback
  }

  function clampNumber(value, min, max, fallback) {
    var numeric = finiteNumber(value, fallback)
    return Math.max(min, Math.min(max, numeric))
  }

  function roundedCents(value) {
    var rounded = Math.round(finiteNumber(value, 0))
    return rounded === 0 ? 0 : rounded
  }

  function formatSignedCents(value) {
    var rounded = roundedCents(value)
    return (rounded > 0 ? "+" : "") + rounded + " cents"
  }

  function formatFrequency(value) {
    var numeric = finiteNumber(value, 0)
    return numeric > 0 ? numeric.toFixed(2) : "0.00"
  }

  function formatConfidencePercent(value) {
    return Math.round(clampNumber(value, 0, 1, 0) * 100) + "%"
  }

  function formatPitchHistorySpan(value) {
    var numeric = clampNumber(value, 0, 100, 0)
    return (numeric >= 10 ? numeric.toFixed(0) : numeric.toFixed(1)) + "c"
  }

  function formatReferenceA(value) {
    return normalizeReferenceAHz(value).toFixed(1) + " Hz"
  }

  function formatReferenceAForHelper(value) {
    return normalizeReferenceAHz(value).toFixed(1)
  }

  function normalizeReferenceAHz(value) {
    var numeric = finiteNumber(value, 440.0)
    numeric = Math.round(numeric * 10) / 10
    return Math.max(minimumReferenceAHz, Math.min(maximumReferenceAHz, numeric))
  }

  function normalizeTranspositionSemitones(value) {
    return Math.max(minimumTranspositionSemitones, Math.min(maximumTranspositionSemitones, Math.round(finiteNumber(value, 0))))
  }

  function minimumDisplayedReferenceMidiNumberForTransposition(value) {
    var transposition = normalizeTranspositionSemitones(value)
    return Math.max(minimumReferenceMidiNumber, minimumReferenceMidiNumber + transposition)
  }

  function maximumDisplayedReferenceMidiNumberForTransposition(value) {
    var transposition = normalizeTranspositionSemitones(value)
    return Math.min(maximumReferenceMidiNumber, maximumReferenceMidiNumber + transposition)
  }

  function normalizeDisplayedReferenceMidiNumberForTransposition(midiNumber, transposition) {
    var numeric = Math.round(finiteNumber(midiNumber, 69))
    var minimumMidiNumber = minimumDisplayedReferenceMidiNumberForTransposition(transposition)
    var maximumMidiNumber = maximumDisplayedReferenceMidiNumberForTransposition(transposition)
    return Math.max(minimumMidiNumber, Math.min(maximumMidiNumber, numeric))
  }

  function shiftedMidiNumber(midiNumber, semitoneOffset) {
    return Math.round(finiteNumber(midiNumber, 69)) + Math.round(finiteNumber(semitoneOffset, 0))
  }

  function transposeNoteText(noteText, semitoneOffset) {
    var midiNumber = parseNoteMidiNumber(noteText)
    if (midiNumber === null) return ""

    var shifted = shiftedMidiNumber(midiNumber, semitoneOffset)
    if (shifted < minimumReferenceMidiNumber || shifted > maximumReferenceMidiNumber) return ""
    return formatMidiNote(shifted, "sharps")
  }

  function roundToFourDecimals(value) {
    var rounded = Math.round(finiteNumber(value, 0) * 10000) / 10000
    return Math.abs(rounded) < 0.00005 ? 0 : rounded
  }

  function normalizeStableId(value, fallback) {
    var text = String(value || "").trim().toLowerCase()
    return text !== "" ? text : String(fallback || "")
  }

  function normalizeMidiInputPortName(value) {
    return String(value || "").trim()
  }

  function normalizedTemperamentOffsets(values) {
    if (!Array.isArray(values) || values.length !== 12) return defaultTemperamentOffsetsCents.slice(0)

    var normalized = []
    for (var index = 0; index < values.length; index++) {
      var numeric = Number(values[index])
      if (!isFinite(numeric)) return defaultTemperamentOffsetsCents.slice(0)
      normalized.push(Math.max(-100, Math.min(100, roundToFourDecimals(numeric))))
    }

    var aOffset = normalized[9]
    for (var offsetIndex = 0; offsetIndex < normalized.length; offsetIndex++)
      normalized[offsetIndex] = roundToFourDecimals(normalized[offsetIndex] - aOffset)

    return normalized
  }

  function temperamentFingerprint(offsets) {
    var normalized = normalizedTemperamentOffsets(offsets)
    return normalized.join(",")
  }

  function formatTemperamentOffsetsForHelper(offsets) {
    var normalized = normalizedTemperamentOffsets(offsets)
    var formatted = []
    for (var index = 0; index < normalized.length; index++)
      formatted.push(Number(normalized[index]).toFixed(4))

    return formatted.join(",")
  }

  function filteredContentPackList(values, expectedKind, source) {
    var list = Array.isArray(values) ? values : []
    var filtered = []
    var seenPackIds = {}

    for (var index = 0; index < list.length; index++) {
      var pack = list[index]
      if (!pack || typeof pack !== "object" || Array.isArray(pack)) continue

      var packKind = String(pack.kind || "")
      var packId = normalizeStableId(pack.id, "")
      if (packKind !== expectedKind || packId === "" || seenPackIds[packId]) continue

      var tagged = {}
      for (var key in pack)
        tagged[key] = pack[key]

      tagged.id = packId
      tagged.source = source
      filtered.push(tagged)
      seenPackIds[packId] = true
    }

    return filtered
  }

  function taggedContentPacks(builtInPacks, importedPacks, expectedKind) {
    return filteredContentPackList(builtInPacks, expectedKind, "builtin")
      .concat(filteredContentPackList(importedPacks, expectedKind, "imported"))
  }

  function presetGroupsForDisplay(packs) {
    var list = Array.isArray(packs) ? packs : []
    var groups = []

    for (var packIndex = 0; packIndex < list.length; packIndex++) {
      var pack = list[packIndex]
      var packLabel = String(pack.label || "")
      var source = String(pack.source || "builtin")
      var packGroups = Array.isArray(pack.groups) ? pack.groups : []

      for (var groupIndex = 0; groupIndex < packGroups.length; groupIndex++) {
        var group = packGroups[groupIndex]
        var groupLabel = String(group.label || "")
        var presets = Array.isArray(group.presets) ? group.presets : []
        var displayPresets = []

        for (var presetIndex = 0; presetIndex < presets.length; presetIndex++) {
          var preset = presets[presetIndex]
          displayPresets.push({
            id: normalizeStableId(preset.id, defaultPresetId),
            label: String(preset.label || ""),
            description: String(preset.description || ""),
            targets: Array.isArray(preset.targets) ? preset.targets : [],
            groupId: normalizeStableId(group.id, "group" + groupIndex),
            groupLabel: groupLabel,
            packId: normalizeStableId(pack.id, "pack" + packIndex),
            packLabel: packLabel,
            source: source,
          })
        }

        groups.push({
          id: normalizeStableId(group.id, "group" + groupIndex),
          label: packLabel !== "" ? (packLabel + " | " + groupLabel) : groupLabel,
          groupLabel: groupLabel,
          packId: normalizeStableId(pack.id, "pack" + packIndex),
          packLabel: packLabel,
          source: source,
          presets: displayPresets,
        })
      }
    }

    if (groups.length > 0) return groups

    return [{
      id: fallbackPreset.groupId,
      label: fallbackPreset.groupLabel,
      groupLabel: fallbackPreset.groupLabel,
      packId: fallbackPreset.packId,
      packLabel: fallbackPreset.packLabel,
      source: fallbackPreset.source,
      presets: [fallbackPreset],
    }]
  }

  function temperamentPackSectionsForDisplay(packs) {
    var list = Array.isArray(packs) ? packs : []
    var sections = []

    for (var packIndex = 0; packIndex < list.length; packIndex++) {
      var pack = list[packIndex]
      var temperaments = Array.isArray(pack.temperaments) ? pack.temperaments : []
      var displayTemperaments = []

      for (var temperamentIndex = 0; temperamentIndex < temperaments.length; temperamentIndex++) {
        var temperament = temperaments[temperamentIndex]
        displayTemperaments.push({
          id: normalizeStableId(temperament.id, defaultTemperamentId),
          label: String(temperament.label || ""),
          description: String(temperament.description || ""),
          offsets_cents: normalizedTemperamentOffsets(temperament.offsets_cents),
          packId: normalizeStableId(pack.id, "pack" + packIndex),
          packLabel: String(pack.label || ""),
          source: String(pack.source || "builtin"),
        })
      }

      sections.push({
        id: normalizeStableId(pack.id, "pack" + packIndex),
        label: String(pack.label || ""),
        description: String(pack.description || ""),
        source: String(pack.source || "builtin"),
        temperaments: displayTemperaments,
      })
    }

    if (sections.length > 0) return sections
    return [{
      id: fallbackTemperament.packId,
      label: fallbackTemperament.packLabel,
      description: fallbackTemperament.description,
      source: fallbackTemperament.source,
      temperaments: [fallbackTemperament],
    }]
  }

  function transposePresetTargets(targets, semitoneOffset) {
    var list = Array.isArray(targets) ? targets : []
    var transposed = []

    for (var index = 0; index < list.length; index++) {
      var target = list[index]
      var noteText = target && typeof target === "object" && !Array.isArray(target)
        ? String(target.note || "")
        : String(target || "")
      var labelText = target && typeof target === "object" && !Array.isArray(target)
        ? String(target.label || noteText)
        : noteText
      var transposedNote = transposeNoteText(noteText, semitoneOffset)
      if (transposedNote === "") continue

      transposed.push({
        note: transposedNote,
        label: labelText.trim() !== "" ? labelText : transposedNote,
      })
    }

    return transposed
  }

  function selectedPresetTargetNotes(targets) {
    var list = Array.isArray(targets) ? targets : []
    var notes = []

    for (var index = 0; index < list.length; index++) {
      var noteText = String((list[index] && list[index].note) || "")
      if (noteText !== "") notes.push(noteText)
    }

    return notes
  }

  function presetTargetDisplayLabel(target) {
    var noteText = target && typeof target === "object" ? String(target.note || "") : String(target || "")
    var labelText = target && typeof target === "object" ? String(target.label || "").trim() : ""
    var displayedNote = displayNoteLabel(noteText)
    if (labelText === "" || sameNoteText(labelText, noteText) || labelText === displayedNote) return displayedNote
    if (displayedNote === "") return labelText
    return labelText + " | " + displayedNote
  }

  function transpositionPresetBySemitones(value) {
    var target = normalizeTranspositionSemitones(value)

    for (var index = 0; index < transpositionPresets.length; index++) {
      var preset = transpositionPresets[index]
      if (Math.round(finiteNumber(preset.semitones, 0)) === target) return preset
    }

    return null
  }

  function formatSignedSemitoneOffset(value) {
    var numeric = normalizeTranspositionSemitones(value)
    return (numeric > 0 ? "+" : "") + numeric + " st"
  }

  function formatTranspositionLabel(value) {
    var numeric = normalizeTranspositionSemitones(value)
    if (numeric === 0) return "Concert"

    var preset = transpositionPresetBySemitones(numeric)
    if (preset && String(preset.label || "") !== "")
      return String(preset.label || "") + " (" + formatSignedSemitoneOffset(numeric) + ")"

    return formatSignedSemitoneOffset(numeric)
  }

  function normalizeMetronomeBpm(value) {
    return Math.max(minimumMetronomeBpm, Math.min(maximumMetronomeBpm, Math.round(finiteNumber(value, defaultMetronomeBpm))))
  }

  function indexOfMetronomeMeterPreset(beatsPerBar, beatUnit) {
    var targetBeatsPerBar = Math.round(finiteNumber(beatsPerBar, defaultMetronomeBeatsPerBar))
    var targetBeatUnit = Math.round(finiteNumber(beatUnit, defaultMetronomeBeatUnit))

    for (var index = 0; index < metronomeMeterPresets.length; index++) {
      var preset = metronomeMeterPresets[index]
      if (preset.beatsPerBar === targetBeatsPerBar && preset.beatUnit === targetBeatUnit) return index
    }

    for (var fallbackIndex = 0; fallbackIndex < metronomeMeterPresets.length; fallbackIndex++) {
      var fallbackPreset = metronomeMeterPresets[fallbackIndex]
      if (fallbackPreset.beatsPerBar === defaultMetronomeBeatsPerBar && fallbackPreset.beatUnit === defaultMetronomeBeatUnit)
        return fallbackIndex
    }

    return 0
  }

  function metronomeMeterPresetByValues(beatsPerBar, beatUnit) {
    return metronomeMeterPresets[indexOfMetronomeMeterPreset(beatsPerBar, beatUnit)]
  }

  function normalizeMetronomeBeatsPerBar(value, beatUnit) {
    return metronomeMeterPresetByValues(value, beatUnit).beatsPerBar
  }

  function normalizeMetronomeBeatUnit(beatsPerBar, value) {
    return metronomeMeterPresetByValues(beatsPerBar, value).beatUnit
  }

  function indexOfMetronomeSubdivisionPreset(value) {
    var target = Math.round(finiteNumber(value, defaultMetronomeSubdivision))

    for (var index = 0; index < metronomeSubdivisionPresets.length; index++)
      if (metronomeSubdivisionPresets[index].steps === target) return index

    for (var fallbackIndex = 0; fallbackIndex < metronomeSubdivisionPresets.length; fallbackIndex++)
      if (metronomeSubdivisionPresets[fallbackIndex].steps === defaultMetronomeSubdivision) return fallbackIndex

    return 0
  }

  function normalizeMetronomeSubdivision(value) {
    return metronomeSubdivisionPresets[indexOfMetronomeSubdivisionPreset(value)].steps
  }

  function normalizeNoteSpelling(value) {
    return String(value || "") === "flats" ? "flats" : "sharps"
  }

  function normalizeReferencePlaybackMode(value) {
    var text = String(value || "")
    if (text === "drone") text = "interval"
    if (text === "interval" || text === "chord") return text
    return "single"
  }

  function parseExactIntegerField(commandObject, commandType, fieldName) {
    if (!(fieldName in commandObject)) {
      return {
        ok: true,
        present: false,
        value: 0,
      }
    }

    var numeric = Number(commandObject[fieldName])
    if (!isFinite(numeric) || Math.round(numeric) !== numeric) {
      return {
        ok: false,
        message: commandType + " field '" + fieldName + "' must be an integer",
      }
    }

    return {
      ok: true,
      present: true,
      value: Math.round(numeric),
    }
  }

  function exactReferencePlaybackMode(value) {
    var text = String(value || "")
    if (text === "drone") return "interval"
    if (text === "single" || text === "interval" || text === "chord") return text
    return ""
  }

  function normalizeReferenceSceneStableId(value) {
    var text = String(value || "")
    if (text === "blend") return "close"
    if (text === "pedal") return "bass_octave"
    return text
  }

  function exactReferenceSceneId(value) {
    var text = normalizeReferenceSceneStableId(value)
    if (text === "") return ""

    var preset = referenceScenePresetById(text)
    return preset && String(preset.id || "") === text ? text : ""
  }

  function exactReferenceWaveformId(value) {
    var text = String(value || "")
    if (text === "") return ""

    var preset = referenceWaveformPresetById(text)
    return preset && String(preset.id || "") === text ? text : ""
  }

  function exactReferenceIntervalSemitones(value) {
    var numeric = Number(value)
    if (!isFinite(numeric) || Math.round(numeric) !== numeric) return null

    var preset = intervalPresetBySemitones(numeric)
    return preset && preset.semitones === Math.round(numeric) ? preset.semitones : null
  }

  function exactReferenceChordId(value) {
    var text = String(value || "")
    if (text === "") return ""

    var preset = chordPresetById(text)
    return preset && String(preset.id || "") === text ? text : ""
  }

  function supportedReferenceIntervalSemitoneListText() {
    var labels = []

    for (var index = 0; index < referenceIntervalPresets.length; index++)
      labels.push(String(referenceIntervalPresets[index].semitones))

    return labels.join(", ")
  }

  function supportedReferenceChordIdListText() {
    var labels = []

    for (var index = 0; index < referenceChordPresets.length; index++)
      labels.push(String(referenceChordPresets[index].id || ""))

    return labels.join(", ")
  }

  function exactMetronomeMeter(beatsPerBar, beatUnit) {
    var numericBeatsPerBar = Number(beatsPerBar)
    var numericBeatUnit = Number(beatUnit)
    if (!isFinite(numericBeatsPerBar) || Math.round(numericBeatsPerBar) !== numericBeatsPerBar) return null
    if (!isFinite(numericBeatUnit) || Math.round(numericBeatUnit) !== numericBeatUnit) return null

    var preset = metronomeMeterPresetByValues(numericBeatsPerBar, numericBeatUnit)
    return preset
      && preset.beatsPerBar === Math.round(numericBeatsPerBar)
      && preset.beatUnit === Math.round(numericBeatUnit)
      ? preset
      : null
  }

  function indexOfReferenceScenePreset(value) {
    var targetId = normalizeReferenceSceneStableId(value)

    for (var index = 0; index < referenceScenePresets.length; index++)
      if (String(referenceScenePresets[index].id || "") === targetId) return index

    for (var fallbackIndex = 0; fallbackIndex < referenceScenePresets.length; fallbackIndex++)
      if (String(referenceScenePresets[fallbackIndex].id || "") === defaultReferenceSceneId) return fallbackIndex

    return 0
  }

  function referenceScenePresetById(value) {
    return referenceScenePresets[indexOfReferenceScenePreset(value)]
  }

  function normalizeSelectedReferenceSceneId(value) {
    var preset = referenceScenePresetById(value)
    return preset ? String(preset.id || defaultReferenceSceneId) : defaultReferenceSceneId
  }

  function referenceScenePresetLabel(value) {
    var preset = referenceScenePresetById(value)
    return preset ? String(preset.label || "") : ""
  }

  function referenceScenePresetEnabled(sceneId) {
    return referenceSceneIsValid(
      selectedReferenceMidiNumber,
      transpositionSemitones,
      selectedReferenceIntervalsSemitones,
      sceneId
    )
  }

  function referenceScenePreviewSummary(sceneId) {
    if (!referenceScenePresetEnabled(sceneId)) return "Unavailable for current note"
    return formatVoicePreviewSummary(
      previewReferenceVoiceLabels(
        selectedReferenceMidiNumber,
        transpositionSemitones,
        selectedReferenceIntervalsSemitones,
        sceneId
      )
    )
  }

  function indexOfReferenceWaveformPreset(value) {
    var targetId = String(value || "")

    for (var index = 0; index < referenceWaveformPresets.length; index++)
      if (String(referenceWaveformPresets[index].id || "") === targetId) return index

    for (var fallbackIndex = 0; fallbackIndex < referenceWaveformPresets.length; fallbackIndex++)
      if (String(referenceWaveformPresets[fallbackIndex].id || "") === defaultReferenceWaveformId) return fallbackIndex

    return 0
  }

  function referenceWaveformPresetById(value) {
    return referenceWaveformPresets[indexOfReferenceWaveformPreset(value)]
  }

  function normalizeSelectedReferenceWaveformId(value) {
    var preset = referenceWaveformPresetById(value)
    return preset ? String(preset.id || defaultReferenceWaveformId) : defaultReferenceWaveformId
  }

  function referenceWaveformPresetLabel(value) {
    var preset = referenceWaveformPresetById(value)
    return preset ? String(preset.label || "") : ""
  }

  function indexOfReferenceIntervalPreset(value) {
    var target = Math.round(finiteNumber(value, defaultReferenceIntervalSemitones))

    for (var index = 0; index < referenceIntervalPresets.length; index++)
      if (referenceIntervalPresets[index].semitones === target) return index

    for (var fallbackIndex = 0; fallbackIndex < referenceIntervalPresets.length; fallbackIndex++)
      if (referenceIntervalPresets[fallbackIndex].semitones === defaultReferenceIntervalSemitones) return fallbackIndex

    return 0
  }

  function intervalPresetBySemitones(value) {
    return referenceIntervalPresets[indexOfReferenceIntervalPreset(value)]
  }

  function normalizeSelectedReferenceIntervalSemitones(value) {
    return intervalPresetBySemitones(value).semitones
  }

  function indexOfReferenceChordPreset(value) {
    var targetId = String(value || "")

    for (var index = 0; index < referenceChordPresets.length; index++)
      if (String(referenceChordPresets[index].id || "") === targetId) return index

    for (var fallbackIndex = 0; fallbackIndex < referenceChordPresets.length; fallbackIndex++)
      if (String(referenceChordPresets[fallbackIndex].id || "") === defaultReferenceChordId) return fallbackIndex

    return 0
  }

  function chordPresetById(value) {
    return referenceChordPresets[indexOfReferenceChordPreset(value)]
  }

  function normalizeSelectedReferenceChordId(value) {
    var preset = chordPresetById(value)
    return preset ? String(preset.id || defaultReferenceChordId) : defaultReferenceChordId
  }

  function referenceSelectionIntervals(playbackMode, intervalSemitones, chordId) {
    var normalizedPlaybackMode = normalizeReferencePlaybackMode(playbackMode)
    if (normalizedPlaybackMode === "interval") return [normalizeSelectedReferenceIntervalSemitones(intervalSemitones)]

    if (normalizedPlaybackMode === "chord") {
      var chordPreset = chordPresetById(chordId)
      return chordPreset ? chordPreset.intervalsSemitones.slice(0) : []
    }

    return []
  }

  function generatedReferenceVoiceMidiNumbers(displayedMidiNumber, transposition, intervals, sceneId) {
    var normalizedTransposition = normalizeTranspositionSemitones(transposition)
    var normalizedSceneId = normalizeSelectedReferenceSceneId(sceneId)
    var displayedRootMidiNumber = Math.round(finiteNumber(displayedMidiNumber, 69))
    if (displayedRootMidiNumber < minimumReferenceMidiNumber || displayedRootMidiNumber > maximumReferenceMidiNumber) return null
    var soundingRootMidiNumber = shiftedMidiNumber(displayedRootMidiNumber, -normalizedTransposition)
    if (soundingRootMidiNumber < minimumReferenceMidiNumber || soundingRootMidiNumber > maximumReferenceMidiNumber) return null

    var generatedMidiNumbers = [soundingRootMidiNumber]
    if (normalizedSceneId === "bass_octave") {
      var lowerRootMidiNumber = soundingRootMidiNumber - 12
      if (lowerRootMidiNumber >= minimumReferenceMidiNumber)
        generatedMidiNumbers.push(lowerRootMidiNumber)
    }

    var normalizedIntervals = normalizeProtocolIntervalArray(intervals)
    for (var index = 0; index < normalizedIntervals.length; index++) {
      var intervalMidiNumber = soundingRootMidiNumber + normalizedIntervals[index]
      if (intervalMidiNumber > maximumReferenceMidiNumber) return null
      generatedMidiNumbers.push(intervalMidiNumber)
    }

    for (var voiceIndex = 0; voiceIndex < generatedMidiNumbers.length; voiceIndex++) {
      var displayedVoiceMidiNumber = generatedMidiNumbers[voiceIndex] + normalizedTransposition
      if (displayedVoiceMidiNumber < minimumReferenceMidiNumber || displayedVoiceMidiNumber > maximumReferenceMidiNumber)
        return null
    }

    return generatedMidiNumbers
  }

  function referenceSceneIsValid(displayedMidiNumber, transposition, intervals, sceneId) {
    return generatedReferenceVoiceMidiNumbers(displayedMidiNumber, transposition, intervals, sceneId) !== null
  }

  function normalizedReferenceSelection(displayedMidiNumber, transposition, playbackMode, sceneId, intervalSemitones, chordId, waveformId) {
    var normalizedTransposition = normalizeTranspositionSemitones(transposition)
    var normalizedPlaybackMode = normalizeReferencePlaybackMode(playbackMode)
    var normalizedSceneId = normalizeSelectedReferenceSceneId(sceneId)
    var normalizedIntervalSemitones = normalizeSelectedReferenceIntervalSemitones(intervalSemitones)
    var normalizedChordId = normalizeSelectedReferenceChordId(chordId)
    var normalizedWaveformId = normalizeSelectedReferenceWaveformId(waveformId)
    var normalizedMidiNumber = normalizeDisplayedReferenceMidiNumberForTransposition(displayedMidiNumber, normalizedTransposition)
    var intervals = referenceSelectionIntervals(normalizedPlaybackMode, normalizedIntervalSemitones, normalizedChordId)
    var minimumMidiNumber = minimumDisplayedReferenceMidiNumberForTransposition(normalizedTransposition)
    var maximumMidiNumber = maximumDisplayedReferenceMidiNumberForTransposition(normalizedTransposition)

    if (referenceSceneIsValid(normalizedMidiNumber, normalizedTransposition, intervals, normalizedSceneId)) {
      return {
        midiNumber: normalizedMidiNumber,
        playbackMode: normalizedPlaybackMode,
        sceneId: normalizedSceneId,
        intervalSemitones: normalizedIntervalSemitones,
        chordId: normalizedChordId,
        waveformId: normalizedWaveformId,
      }
    }

    if (normalizedSceneId === "bass_octave" && referenceSceneIsValid(normalizedMidiNumber, normalizedTransposition, intervals, defaultReferenceSceneId)) {
      return {
        midiNumber: normalizedMidiNumber,
        playbackMode: normalizedPlaybackMode,
        sceneId: defaultReferenceSceneId,
        intervalSemitones: normalizedIntervalSemitones,
        chordId: normalizedChordId,
        waveformId: normalizedWaveformId,
      }
    }

    for (var distance = 1; distance <= maximumMidiNumber - minimumMidiNumber; distance++) {
      var lowerMidiNumber = normalizedMidiNumber - distance
      if (lowerMidiNumber >= minimumMidiNumber && referenceSceneIsValid(lowerMidiNumber, normalizedTransposition, intervals, normalizedSceneId)) {
        return {
          midiNumber: lowerMidiNumber,
          playbackMode: normalizedPlaybackMode,
          sceneId: normalizedSceneId,
          intervalSemitones: normalizedIntervalSemitones,
          chordId: normalizedChordId,
          waveformId: normalizedWaveformId,
        }
      }

      var higherMidiNumber = normalizedMidiNumber + distance
      if (higherMidiNumber <= maximumMidiNumber && referenceSceneIsValid(higherMidiNumber, normalizedTransposition, intervals, normalizedSceneId)) {
        return {
          midiNumber: higherMidiNumber,
          playbackMode: normalizedPlaybackMode,
          sceneId: normalizedSceneId,
          intervalSemitones: normalizedIntervalSemitones,
          chordId: normalizedChordId,
          waveformId: normalizedWaveformId,
        }
      }
    }

    if (normalizedSceneId !== defaultReferenceSceneId) {
      for (var fallbackDistance = 0; fallbackDistance <= maximumMidiNumber - minimumMidiNumber; fallbackDistance++) {
        var fallbackLowerMidiNumber = normalizedMidiNumber - fallbackDistance
        if (fallbackLowerMidiNumber >= minimumMidiNumber && referenceSceneIsValid(fallbackLowerMidiNumber, normalizedTransposition, intervals, defaultReferenceSceneId)) {
          return {
            midiNumber: fallbackLowerMidiNumber,
            playbackMode: normalizedPlaybackMode,
            sceneId: defaultReferenceSceneId,
            intervalSemitones: normalizedIntervalSemitones,
            chordId: normalizedChordId,
            waveformId: normalizedWaveformId,
          }
        }

        var fallbackHigherMidiNumber = normalizedMidiNumber + fallbackDistance
        if (fallbackHigherMidiNumber <= maximumMidiNumber && referenceSceneIsValid(fallbackHigherMidiNumber, normalizedTransposition, intervals, defaultReferenceSceneId)) {
          return {
            midiNumber: fallbackHigherMidiNumber,
            playbackMode: normalizedPlaybackMode,
            sceneId: defaultReferenceSceneId,
            intervalSemitones: normalizedIntervalSemitones,
            chordId: normalizedChordId,
            waveformId: normalizedWaveformId,
          }
        }
      }
    }

    return {
      midiNumber: normalizedMidiNumber,
      playbackMode: normalizedPlaybackMode,
      sceneId: defaultReferenceSceneId,
      intervalSemitones: normalizedIntervalSemitones,
      chordId: normalizedChordId,
      waveformId: normalizedWaveformId,
    }
  }

  function applyReferenceSelection(selection) {
    var normalized = selection && typeof selection === "object"
      ? selection
      : normalizedReferenceSelection(
        selectedReferenceMidiNumber,
        transpositionSemitones,
        referencePlaybackMode,
        selectedReferenceSceneId,
        selectedReferenceIntervalSemitones,
        selectedReferenceChordId,
        selectedReferenceWaveformId
      )

    hostWidget.selectedReferenceMidiNumber = normalized.midiNumber
    hostWidget.referencePlaybackMode = normalized.playbackMode
    hostWidget.selectedReferenceSceneId = normalized.sceneId
    hostWidget.selectedReferenceIntervalSemitones = normalized.intervalSemitones
    hostWidget.selectedReferenceChordId = normalized.chordId
    hostWidget.selectedReferenceWaveformId = normalized.waveformId
  }

  function sameReferenceSelection(selection) {
    return selection
      && selection.midiNumber === selectedReferenceMidiNumber
      && selection.playbackMode === referencePlaybackMode
      && selection.sceneId === selectedReferenceSceneId
      && selection.intervalSemitones === selectedReferenceIntervalSemitones
      && selection.chordId === selectedReferenceChordId
      && selection.waveformId === selectedReferenceWaveformId
  }

  function activeToneValidAcrossTranspositionChange(previousTransposition, nextTransposition) {
    if (!toneActive) return true

    var activeDisplayedMidiNumber = parseNoteMidiNumber(activeToneNote)
    if (activeDisplayedMidiNumber === null) return false

    var soundingMidiNumber = shiftedMidiNumber(activeDisplayedMidiNumber, -normalizeTranspositionSemitones(previousTransposition))
    var displayedMidiNumber = soundingMidiNumber + normalizeTranspositionSemitones(nextTransposition)
    return referenceSceneIsValid(
      displayedMidiNumber,
      nextTransposition,
      normalizeProtocolIntervalArray(activeToneIntervalsSemitones),
      activeToneSceneId
    )
  }

  function normalizeProtocolIntervalArray(values) {
    if (!Array.isArray(values)) return []

    var normalized = []
    for (var index = 0; index < values.length; index++) {
      var numeric = Math.round(finiteNumber(values[index], 0))
      if (!isFinite(numeric) || numeric < 1 || numeric > maximumReferenceIntervalSemitones) continue
      if (normalized.indexOf(numeric) >= 0) continue
      normalized.push(numeric)
    }

    normalized.sort(function(left, right) { return left - right })
    return normalized
  }

  function sameIntegerArray(left, right) {
    var leftValues = Array.isArray(left) ? left : []
    var rightValues = Array.isArray(right) ? right : []
    if (leftValues.length !== rightValues.length) return false

    for (var index = 0; index < leftValues.length; index++)
      if (Math.round(finiteNumber(leftValues[index], 0)) !== Math.round(finiteNumber(rightValues[index], 0))) return false

    return true
  }

  function chordPresetByIntervals(intervals) {
    var normalizedIntervals = normalizeProtocolIntervalArray(intervals)

    for (var index = 0; index < referenceChordPresets.length; index++) {
      var preset = referenceChordPresets[index]
      if (sameIntegerArray(preset.intervalsSemitones, normalizedIntervals)) return preset
    }

    return null
  }

  function playbackModeForIntervals(intervals) {
    var normalizedIntervals = normalizeProtocolIntervalArray(intervals)
    if (normalizedIntervals.length > 1) return "chord"
    if (normalizedIntervals.length === 1) return "interval"
    return "single"
  }

  function intervalLabelForSemitones(value) {
    var preset = intervalPresetBySemitones(value)
    if (preset && preset.semitones === Math.round(finiteNumber(value, 0))) return String(preset.label || "")

    var numeric = Math.round(finiteNumber(value, 0))
    return numeric > 0 ? (String(numeric) + "st") : ""
  }

  function intervalListLabel(intervals) {
    var values = normalizeProtocolIntervalArray(intervals)
    if (values.length === 0) return ""

    var labels = []
    for (var index = 0; index < values.length; index++)
      labels.push(intervalLabelForSemitones(values[index]))

    return labels.join(" + ")
  }

  function formatReferenceSceneLabel(rootNoteLabel, intervals) {
    var rootNote = String(rootNoteLabel || "")
    var normalizedIntervals = normalizeProtocolIntervalArray(intervals)
    if (rootNote === "" || normalizedIntervals.length === 0) return rootNote

    var chordPreset = normalizedIntervals.length > 1 ? chordPresetByIntervals(normalizedIntervals) : null
    if (chordPreset && String(chordPreset.label || "") !== "") return rootNote + " " + String(chordPreset.label || "")

    var intervalText = intervalListLabel(intervals)
    if (rootNote === "" || intervalText === "") return rootNote
    return rootNote + " + " + intervalText
  }

  function formatReferencePlaybackLabel(sceneLabel, sceneId) {
    var label = String(sceneLabel || "")
    var normalizedSceneId = normalizeSelectedReferenceSceneId(sceneId)
    if (normalizedSceneId === defaultReferenceSceneId) return label

    var sceneText = referenceScenePresetLabel(normalizedSceneId)
    if (sceneText === "") return label
    if (label === "") return sceneText
    return label + " | " + sceneText
  }

  function formatReferenceToneSummaryLabel(sceneLabel, sceneId, waveformId) {
    var parts = []
    var label = String(sceneLabel || "")
    var voicingText = referenceScenePresetLabel(sceneId)
    var waveformText = referenceWaveformPresetLabel(waveformId)

    if (label !== "") parts.push(label)
    if (voicingText !== "") parts.push(voicingText)
    if (waveformText !== "") parts.push(waveformText)
    return parts.join(" | ")
  }

  function formatToneVoiceSummary(voices) {
    if (!Array.isArray(voices) || voices.length === 0) return ""

    var labels = []
    for (var index = 0; index < voices.length; index++) {
      var voice = voices[index]
      if (!voice || typeof voice !== "object") continue

      var noteText = displayNoteLabel(String(voice.note || ""))
      if (noteText === "") continue

      labels.push(noteText + " " + formatFrequency(voice.frequencyHz) + " Hz")
    }

    return labels.join(" + ")
  }

  function previewReferenceVoiceLabels(displayedMidiNumber, transposition, intervals, sceneId) {
    var generatedMidiNumbers = generatedReferenceVoiceMidiNumbers(displayedMidiNumber, transposition, intervals, sceneId)
    if (!generatedMidiNumbers) return []

    var normalizedTransposition = normalizeTranspositionSemitones(transposition)
    var labels = []
    for (var index = 0; index < generatedMidiNumbers.length; index++)
      labels.push(formatMidiNote(generatedMidiNumbers[index] + normalizedTransposition, noteSpelling))

    return labels
  }

  function formatVoicePreviewSummary(labels) {
    var values = Array.isArray(labels) ? labels : []
    if (values.length === 0) return ""
    return values.join(" + ")
  }

  function normalizeToneVoices(voices, fallbackNote, fallbackFrequencyHz) {
    var normalized = []

    if (Array.isArray(voices)) {
      for (var index = 0; index < voices.length; index++) {
        var voice = voices[index]
        if (!voice || typeof voice !== "object") continue

        var noteText = String(voice.note || "").trim()
        if (noteText === "") continue

        normalized.push({
          note: noteText,
          frequencyHz: Math.max(0, finiteNumber(voice.frequency_hz, 0)),
        })
      }
    }

    if (normalized.length > 0) return normalized

    var fallback = String(fallbackNote || "").trim()
    if (fallback === "") return []
    return [{
      note: fallback,
      frequencyHz: Math.max(0, finiteNumber(fallbackFrequencyHz, 0)),
    }]
  }

  function normalizePitchHistoryCents(values) {
    if (!Array.isArray(values)) return []

    var normalized = []
    for (var index = 0; index < values.length; index++) {
      var numeric = Number(values[index])
      if (!isFinite(numeric)) continue
      normalized.push(roundToFourDecimals(Math.max(-50, Math.min(50, numeric))))
    }

    if (normalized.length <= maximumPitchAnalysisHistoryPoints) return normalized
    return normalized.slice(normalized.length - maximumPitchAnalysisHistoryPoints)
  }

  function normalizeBooleanSetting(value, fallback) {
    if (value === true || value === false) return value

    var text = String(value)
    if (text === "true") return true
    if (text === "false") return false
    return !!fallback
  }

  function noteBasePitchClass(letter) {
    var value = String(letter || "").toUpperCase()
    if (value === "C") return 0
    if (value === "D") return 2
    if (value === "E") return 4
    if (value === "F") return 5
    if (value === "G") return 7
    if (value === "A") return 9
    if (value === "B") return 11
    return -1
  }

  function parseNoteMidiNumber(noteText) {
    var match = /^([A-Ga-g])([#b]?)(-?\d+)$/.exec(String(noteText || "").trim())
    if (!match) return null

    var pitchClass = noteBasePitchClass(match[1])
    if (pitchClass < 0) return null

    var accidentalOffset = match[2] === "#" ? 1 : (match[2] === "b" ? -1 : 0)
    var octave = parseInt(match[3], 10)
    if (!isFinite(octave)) return null

    var adjustedPitchClass = pitchClass + accidentalOffset
    var canonicalPitchClass = ((adjustedPitchClass % 12) + 12) % 12
    var canonicalOctave = octave + Math.floor(adjustedPitchClass / 12)
    if (canonicalOctave < 0 || canonicalOctave > 8) return null

    var midiNumber = (canonicalOctave + 1) * 12 + canonicalPitchClass
    if (midiNumber < minimumReferenceMidiNumber || midiNumber > maximumReferenceMidiNumber) return null
    return midiNumber
  }

  function formatMidiNote(midiNumber, spelling) {
    var numeric = Math.max(minimumReferenceMidiNumber, Math.min(maximumReferenceMidiNumber, Math.round(finiteNumber(midiNumber, 69))))
    var pitchClassIndex = ((numeric % 12) + 12) % 12
    var octave = Math.floor(numeric / 12) - 1
    var pitchNames = normalizeNoteSpelling(spelling) === "flats" ? flatPitchClasses : sharpPitchClasses
    return String(pitchNames[pitchClassIndex]) + String(octave)
  }

  function displayNoteLabel(noteText) {
    var midiNumber = parseNoteMidiNumber(noteText)
    return midiNumber === null ? String(noteText || "") : formatMidiNote(midiNumber, noteSpelling)
  }

  function sameNoteText(left, right) {
    var leftMidiNumber = parseNoteMidiNumber(left)
    var rightMidiNumber = parseNoteMidiNumber(right)
    if (leftMidiNumber === null || rightMidiNumber === null)
      return String(left || "") === String(right || "")

    return leftMidiNumber === rightMidiNumber
  }

  function temperamentById(temperamentId) {
    var targetId = normalizeStableId(temperamentId, defaultTemperamentId)

    for (var sectionIndex = 0; sectionIndex < temperamentPackSections.length; sectionIndex++) {
      var section = temperamentPackSections[sectionIndex]
      var temperaments = Array.isArray(section.temperaments) ? section.temperaments : []

      for (var temperamentIndex = 0; temperamentIndex < temperaments.length; temperamentIndex++) {
        var temperament = temperaments[temperamentIndex]
        if (normalizeStableId(temperament.id, defaultTemperamentId) !== targetId) continue
        return temperament
      }
    }

    return fallbackTemperament
  }

  function presetById(presetId) {
    var targetId = normalizeStableId(presetId, defaultPresetId)

    for (var groupIndex = 0; groupIndex < tuningPresetGroups.length; groupIndex++) {
      var group = tuningPresetGroups[groupIndex]
      var presets = Array.isArray(group.presets) ? group.presets : []

      for (var presetIndex = 0; presetIndex < presets.length; presetIndex++) {
        var preset = presets[presetIndex]
        if (normalizeStableId(preset.id, defaultPresetId) !== targetId) continue
        return preset
      }
    }

    return fallbackPreset
  }

  function presetPackByPresetId(presetId) {
    var preset = presetById(presetId)
    var targetPackId = normalizeStableId(preset.packId, "")
    var packs = allPresetPacks

    for (var index = 0; index < packs.length; index++)
      if (normalizeStableId(packs[index].id, "") === targetPackId) return packs[index]

    return null
  }

  function temperamentPackByTemperamentId(temperamentId) {
    var temperament = temperamentById(temperamentId)
    var targetPackId = normalizeStableId(temperament.packId, "")
    var packs = allTemperamentPacks

    for (var index = 0; index < packs.length; index++)
      if (normalizeStableId(packs[index].id, "") === targetPackId) return packs[index]

    return null
  }

  function isQuickSwitchSceneCandidate(value) {
    return value && typeof value === "object"
      && ("presetId" in value
        || "temperamentId" in value
        || "referenceNote" in value
        || "transpositionSemitones" in value
        || "playbackMode" in value
        || "sceneId" in value
        || "waveformId" in value
        || "intervalSemitones" in value
        || "chordId" in value
        || "metronomeBpm" in value
        || "metronomeBeatsPerBar" in value
        || "metronomeBeatUnit" in value
        || "metronomeSubdivision" in value)
  }

  function normalizeQuickSwitchScene(value) {
    if (!isQuickSwitchSceneCandidate(value)) return null

    var transposition = normalizeTranspositionSemitones(value.transpositionSemitones)
    var referenceSelection = normalizedReferenceSelection(
      parseNoteMidiNumber(value.referenceNote) === null ? 69 : parseNoteMidiNumber(value.referenceNote),
      transposition,
      value.playbackMode,
      value.sceneId,
      value.intervalSemitones,
      value.chordId,
      value.waveformId
    )
    var metronomeMeter = metronomeMeterPresetByValues(value.metronomeBeatsPerBar, value.metronomeBeatUnit)

    return {
      presetId: normalizeStableId(value.presetId, defaultPresetId),
      temperamentId: normalizeStableId(value.temperamentId, defaultTemperamentId),
      referenceNote: formatMidiNote(referenceSelection.midiNumber, "sharps"),
      transpositionSemitones: transposition,
      playbackMode: referenceSelection.playbackMode,
      sceneId: referenceSelection.sceneId,
      waveformId: referenceSelection.waveformId,
      intervalSemitones: referenceSelection.intervalSemitones,
      chordId: referenceSelection.chordId,
      metronomeBpm: normalizeMetronomeBpm(value.metronomeBpm),
      metronomeBeatsPerBar: metronomeMeter.beatsPerBar,
      metronomeBeatUnit: metronomeMeter.beatUnit,
      metronomeSubdivision: normalizeMetronomeSubdivision(value.metronomeSubdivision),
    }
  }

  function currentQuickSwitchScene() {
    return normalizeQuickSwitchScene({
      presetId: selectedPresetId,
      temperamentId: selectedTemperamentId,
      referenceNote: selectedReferenceCommandNoteLabel,
      transpositionSemitones: transpositionSemitones,
      playbackMode: referencePlaybackMode,
      sceneId: selectedReferenceSceneId,
      waveformId: selectedReferenceWaveformId,
      intervalSemitones: selectedReferenceIntervalSemitones,
      chordId: selectedReferenceChordId,
      metronomeBpm: metronomeBpm,
      metronomeBeatsPerBar: metronomeBeatsPerBar,
      metronomeBeatUnit: metronomeBeatUnit,
      metronomeSubdivision: metronomeSubdivision,
    })
  }

  function quickSwitchSceneFingerprint(scene) {
    var normalized = normalizeQuickSwitchScene(scene)
    if (!normalized) return ""

    return [
      normalized.presetId,
      normalized.temperamentId,
      normalized.referenceNote,
      normalized.transpositionSemitones,
      normalized.playbackMode,
      normalized.sceneId,
      normalized.waveformId,
      normalized.intervalSemitones,
      normalized.chordId,
      normalized.metronomeBpm,
      normalized.metronomeBeatsPerBar,
      normalized.metronomeBeatUnit,
      normalized.metronomeSubdivision,
    ].join("|")
  }

  function quickSwitchReferenceStateFingerprint(scene) {
    var normalized = normalizeQuickSwitchScene(scene)
    if (!normalized) return ""

    var referenceMidiNumber = parseNoteMidiNumber(normalized.referenceNote)
    if (referenceMidiNumber === null) return ""

    return String(shiftedMidiNumber(referenceMidiNumber, -normalized.transpositionSemitones))
      + "|" + normalized.playbackMode + "|" + normalized.sceneId + "|" + normalized.waveformId + "|" + quickSwitchSceneIntervals(normalized).join(",")
  }

  function filteredQuickSwitchSceneList(existingScenes, excludedScene, limit) {
    var max = Math.max(0, Math.round(finiteNumber(limit, 0)))
    if (max === 0) return []

    var targetFingerprint = quickSwitchSceneFingerprint(excludedScene)
    var list = Array.isArray(existingScenes) ? existingScenes : []
    var filtered = []

    for (var index = 0; index < list.length; index++) {
      var scene = normalizeQuickSwitchScene(list[index])
      if (!scene) continue
      if (targetFingerprint !== "" && quickSwitchSceneFingerprint(scene) === targetFingerprint) continue
      filtered.push(scene)
    }

    var normalized = []
    var seen = {}

    for (var sceneIndex = 0; sceneIndex < filtered.length; sceneIndex++) {
      var candidate = filtered[sceneIndex]
      var candidateFingerprint = quickSwitchSceneFingerprint(candidate)
      if (candidateFingerprint === "" || seen[candidateFingerprint]) continue

      normalized.push(candidate)
      seen[candidateFingerprint] = true
      if (normalized.length >= max) break
    }

    return normalized
  }

  function prependedQuickSwitchSceneList(existingScenes, scene, limit) {
    var normalizedScene = normalizeQuickSwitchScene(scene)
    var max = Math.max(0, Math.round(finiteNumber(limit, 0)))
    if (max === 0) return []

    var list = normalizedScene ? [normalizedScene] : []
    var existing = Array.isArray(existingScenes) ? existingScenes : []

    for (var index = 0; index < existing.length; index++)
      list.push(existing[index])

    return filteredQuickSwitchSceneList(list, null, max)
  }

  function indexOfQuickSwitchScene(scenes, scene) {
    var targetFingerprint = quickSwitchSceneFingerprint(scene)
    if (targetFingerprint === "") return -1

    var list = Array.isArray(scenes) ? scenes : []
    for (var index = 0; index < list.length; index++)
      if (quickSwitchSceneFingerprint(list[index]) === targetFingerprint) return index

    return -1
  }

  function recentQuickSwitchesForDisplay() {
    var normalizedRecents = filteredQuickSwitchSceneList(recentQuickSwitches, null, maximumRecentQuickSwitches)
    var visible = []

    for (var index = 0; index < normalizedRecents.length; index++) {
      var scene = normalizedRecents[index]
      if (indexOfQuickSwitchScene(favoriteQuickSwitches, scene) >= 0) continue
      visible.push(scene)
    }

    return visible
  }

  function quickSwitchSceneIntervals(scene) {
    var normalized = normalizeQuickSwitchScene(scene)
    if (!normalized) return []

    if (normalized.playbackMode === "interval") return [normalized.intervalSemitones]

    if (normalized.playbackMode === "chord") {
      var chordPreset = chordPresetById(normalized.chordId)
      return chordPreset ? chordPreset.intervalsSemitones.slice(0) : []
    }

    return []
  }

  function quickSwitchPresetSummary(scene) {
    var normalized = normalizeQuickSwitchScene(scene)
    if (!normalized) return ""

    var preset = presetById(normalized.presetId)
    var groupLabel = String(preset.groupLabel || "")
    var label = String(preset.label || "")
    if (label === "") return groupLabel
    if (label === "Standard" && groupLabel !== "") return groupLabel
    return label
  }

  function quickSwitchSceneLabel(scene) {
    var normalized = normalizeQuickSwitchScene(scene)
    if (!normalized) return ""

    return formatReferencePlaybackLabel(
      formatReferenceSceneLabel(displayNoteLabel(normalized.referenceNote), quickSwitchSceneIntervals(normalized)),
      normalized.sceneId
    )
  }

  function quickSwitchButtonText(scene) {
    var normalized = normalizeQuickSwitchScene(scene)
    if (!normalized) return ""

    var defaultMeterLabel = metronomeMeterPresetByValues(defaultMetronomeBeatsPerBar, defaultMetronomeBeatUnit).label
    var meterLabel = metronomeMeterPresetByValues(normalized.metronomeBeatsPerBar, normalized.metronomeBeatUnit).label
    var subdivisionLabel = metronomeSubdivisionPresets[indexOfMetronomeSubdivisionPreset(normalized.metronomeSubdivision)].label
    var primaryParts = []
    var detailParts = []
    var presetText = quickSwitchPresetSummary(normalized)
    var referenceText = quickSwitchSceneLabel(normalized)
    var transpositionPreset = transpositionPresetBySemitones(normalized.transpositionSemitones)
    var temperament = temperamentById(normalized.temperamentId)

    if (presetText !== "") primaryParts.push(presetText)
    if (referenceText !== "") primaryParts.push(referenceText)
    if (normalized.transpositionSemitones !== 0) {
      if (transpositionPreset && String(transpositionPreset.label || "") !== "")
        detailParts.push(String(transpositionPreset.label || ""))
      else detailParts.push(formatSignedSemitoneOffset(normalized.transpositionSemitones))
    }
    if (normalizeStableId(normalized.temperamentId, defaultTemperamentId) !== defaultTemperamentId)
      detailParts.push(String(temperament.label || "Temperament"))
    if (normalizeSelectedReferenceWaveformId(normalized.waveformId) !== defaultReferenceWaveformId)
      detailParts.push(referenceWaveformPresetLabel(normalized.waveformId))
    detailParts.push("M" + normalized.metronomeBpm)
    if (meterLabel !== defaultMeterLabel || normalized.metronomeSubdivision !== defaultMetronomeSubdivision)
      detailParts.push(meterLabel)
    if (normalized.metronomeSubdivision !== defaultMetronomeSubdivision)
      detailParts.push(subdivisionLabel)

    var primaryText = primaryParts.join(": ")
    if (primaryText === "") return detailParts.join(" ")
    if (detailParts.length === 0) return primaryText
    return primaryText + " | " + detailParts.join(" ")
  }

  function normalizedSettingsObject(value) {
    var source = value && typeof value === "object" ? value : ({})
    var transposition = normalizeTranspositionSemitones(source.transpositionSemitones)
    var normalizedImportedTemperamentPacks = storedContentPackList(source.importedTemperamentPacks, "temperament_pack")
    var normalizedImportedPresetPacks = storedContentPackList(source.importedPresetPacks, "preset_pack")
    var referenceSelection = normalizedReferenceSelection(
      parseNoteMidiNumber(source.selectedReferenceNote) === null ? 69 : parseNoteMidiNumber(source.selectedReferenceNote),
      transposition,
      source.referencePlaybackMode,
      source.referenceSceneId,
      source.referenceIntervalSemitones,
      source.referenceChordId,
      source.referenceWaveformId
    )
    var metronomePreset = metronomeMeterPresetByValues(
      source.metronomeBeatsPerBar,
      source.metronomeBeatUnit
    )

    return {
      configVersion: settingsConfigVersion,
      referenceAHz: normalizeReferenceAHz(source.referenceAHz),
      transpositionSemitones: transposition,
      noteSpelling: normalizeNoteSpelling(source.noteSpelling),
      selectedPresetId: normalizeStableId(source.selectedPresetId, defaultPresetId),
      selectedTemperamentId: normalizeStableId(source.selectedTemperamentId, defaultTemperamentId),
      selectedReferenceNote: formatMidiNote(referenceSelection.midiNumber, "sharps"),
      referencePlaybackMode: referenceSelection.playbackMode,
      referenceSceneId: referenceSelection.sceneId,
      referenceWaveformId: referenceSelection.waveformId,
      referenceIntervalSemitones: referenceSelection.intervalSemitones,
      referenceChordId: referenceSelection.chordId,
      metronomeBpm: normalizeMetronomeBpm(source.metronomeBpm),
      metronomeBeatsPerBar: metronomePreset.beatsPerBar,
      metronomeBeatUnit: metronomePreset.beatUnit,
      metronomeSubdivision: normalizeMetronomeSubdivision(source.metronomeSubdivision),
      midiInputEnabled: normalizeBooleanSetting(source.midiInputEnabled, false),
      midiInputPortName: normalizeMidiInputPortName(source.midiInputPortName),
      highContrastMode: normalizeBooleanSetting(source.highContrastMode, false),
      reducedMotionMode: normalizeBooleanSetting(source.reducedMotionMode, false),
      analysisViewsEnabled: normalizeBooleanSetting(source.analysisViewsEnabled, false),
      favoriteQuickSwitches: filteredQuickSwitchSceneList(source.favoriteQuickSwitches, null, maximumFavoriteQuickSwitches),
      recentQuickSwitches: filteredQuickSwitchSceneList(source.recentQuickSwitches, null, maximumRecentQuickSwitches),
      importedTemperamentPacks: normalizedImportedTemperamentPacks,
      importedPresetPacks: normalizedImportedPresetPacks,
    }
  }

  function currentNormalizedSettingsObject() {
    return normalizedSettingsObject({
      referenceAHz: referenceAHz,
      transpositionSemitones: transpositionSemitones,
      noteSpelling: noteSpelling,
      selectedPresetId: selectedPresetId,
      selectedTemperamentId: selectedTemperamentId,
      selectedReferenceNote: selectedReferenceCommandNoteLabel,
      referencePlaybackMode: referencePlaybackMode,
      referenceSceneId: selectedReferenceSceneId,
      referenceWaveformId: selectedReferenceWaveformId,
      referenceIntervalSemitones: selectedReferenceIntervalSemitones,
      referenceChordId: selectedReferenceChordId,
      metronomeBpm: metronomeBpm,
      metronomeBeatsPerBar: metronomeBeatsPerBar,
      metronomeBeatUnit: metronomeBeatUnit,
      metronomeSubdivision: metronomeSubdivision,
      midiInputEnabled: midiInputEnabled,
      midiInputPortName: midiInputPortName,
      highContrastMode: highContrastMode,
      reducedMotionMode: reducedMotionMode,
      analysisViewsEnabled: analysisViewsEnabled,
      favoriteQuickSwitches: favoriteQuickSwitches,
      recentQuickSwitches: recentQuickSwitches,
      importedTemperamentPacks: importedTemperamentPacks,
      importedPresetPacks: importedPresetPacks,
    })
  }

  function importedSettingsConfigVersion(settingsObject) {
    if (!settingsObject || typeof settingsObject !== "object" || Array.isArray(settingsObject)) return null
    if (!("configVersion" in settingsObject)) return null

    var numeric = Number(settingsObject.configVersion)
    if (!isFinite(numeric) || Math.round(numeric) !== numeric) return null
    return numeric
  }

  function normalizeMidiInputPortList(values) {
    if (!Array.isArray(values)) return []

    var normalized = []
    var seen = {}
    for (var index = 0; index < values.length; index++) {
      var portName = normalizeMidiInputPortName(values[index])
      if (portName === "" || seen[portName]) continue
      normalized.push(portName)
      seen[portName] = true
    }

    return normalized
  }

  function storedContentPackList(values, expectedKind) {
    var filtered = filteredContentPackList(values, expectedKind, "imported")
    var stored = []

    for (var index = 0; index < filtered.length; index++) {
      var pack = filtered[index]
      var clean = {}
      for (var key in pack)
        if (key !== "source") clean[key] = pack[key]

      stored.push(clean)
    }

    return stored
  }

  function resolvedQuickSwitchScene(scene) {
    var normalized = normalizeQuickSwitchScene(scene)
    if (!normalized) return null

    normalized.presetId = presetById(normalized.presetId).id
    normalized.temperamentId = temperamentById(normalized.temperamentId).id
    return normalized
  }

  function resolvedQuickSwitchSceneList(scenes, limit) {
    var list = Array.isArray(scenes) ? scenes : []
    var resolved = []

    for (var index = 0; index < list.length; index++) {
      var scene = resolvedQuickSwitchScene(list[index])
      if (scene) resolved.push(scene)
    }

    return filteredQuickSwitchSceneList(resolved, null, limit)
  }

  function contentPackJsonText(pack) {
    if (!pack || typeof pack !== "object") return ""

    var exported = {}
    for (var key in pack)
      if (key !== "source") exported[key] = pack[key]

    return JSON.stringify(exported, null, 2)
  }

  function importedContentPackById(packId, values, expectedKind) {
    var normalizedPackId = normalizeStableId(packId, "")
    var list = filteredContentPackList(values, expectedKind, "imported")

    for (var index = 0; index < list.length; index++)
      if (normalizeStableId(list[index].id, "") === normalizedPackId) return list[index]

    return null
  }

  function existingPresetIdConflict(pack) {
    var groups = Array.isArray(pack && pack.groups) ? pack.groups : []

    for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      var presets = Array.isArray(groups[groupIndex].presets) ? groups[groupIndex].presets : []
      for (var presetIndex = 0; presetIndex < presets.length; presetIndex++) {
        var presetId = normalizeStableId(presets[presetIndex].id, "")
        var existingPreset = presetById(presetId)
        if (presetId !== "" && existingPreset && normalizeStableId(existingPreset.id, "") === presetId)
          return presetId
      }
    }

    return ""
  }

  function existingTemperamentIdConflict(pack) {
    var temperaments = Array.isArray(pack && pack.temperaments) ? pack.temperaments : []

    for (var index = 0; index < temperaments.length; index++) {
      var temperamentId = normalizeStableId(temperaments[index].id, "")
      var existingTemperament = temperamentById(temperamentId)
      if (temperamentId !== "" && existingTemperament && normalizeStableId(existingTemperament.id, "") === temperamentId)
        return temperamentId
    }

    return ""
  }

  function contentPackConflictMessage(pack) {
    var packId = normalizeStableId(pack && pack.id, "")
    if (packId === "") return "Import failed: normalized pack is missing an id."

    for (var presetPackIndex = 0; presetPackIndex < allPresetPacks.length; presetPackIndex++)
      if (normalizeStableId(allPresetPacks[presetPackIndex].id, "") === packId)
        return "Import failed: pack id '" + packId + "' is already installed."

    for (var temperamentPackIndex = 0; temperamentPackIndex < allTemperamentPacks.length; temperamentPackIndex++)
      if (normalizeStableId(allTemperamentPacks[temperamentPackIndex].id, "") === packId)
        return "Import failed: pack id '" + packId + "' is already installed."

    if (String(pack.kind || "") === "preset_pack") {
      var presetConflict = existingPresetIdConflict(pack)
      if (presetConflict !== "")
        return "Import failed: preset id '" + presetConflict + "' is already installed."
    }

    if (String(pack.kind || "") === "temperament_pack") {
      var temperamentConflict = existingTemperamentIdConflict(pack)
      if (temperamentConflict !== "")
        return "Import failed: temperament id '" + temperamentConflict + "' is already installed."
    }

    return ""
  }
}
