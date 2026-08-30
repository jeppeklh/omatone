import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "jeppeklh.omatune"

  property bool helperWanted: false
  property bool helperProcessStarted: false
  property bool helperReadySeen: false
  property bool restartPending: false
  property bool helperRecoveryPending: false
  property string helperState: "inactive"
  property string helperErrorCode: ""
  property string helperError: ""
  property int helperRecoveryAttempt: 0
  property string helperRecoveryMessage: ""
  property string recoverableStartupErrorCode: ""
  property string recoverableStartupErrorMessage: ""
  property int helperRestartDelayMs: 120
  property string runtimeErrorCode: ""
  property string runtimeErrorMessage: ""
  property bool settingsHydrating: false
  property string signalState: "idle"
  property string detectedNote: ""
  property real detectedFrequencyHz: 0
  property real detectedCents: 0
  property real detectedConfidence: 0
  property string activeToneNote: ""
  property real activeToneFrequencyHz: 0
  property var activeToneIntervalsSemitones: []
  property var activeToneVoices: []
  property bool metronomeActive: false
  property int metronomeBpm: 100
  property int metronomeBeatInBar: 0
  property int metronomeBeatsPerBar: 4
  property int metronomeBeatUnit: 4
  property int metronomeSubdivision: 1
  property int metronomeSubdivisionStep: 0
  property bool metronomeBeatAccented: false
  property real referenceAHz: 440.0
  property int transpositionSemitones: 0
  property string noteSpelling: "sharps"
  property string selectedPresetId: "guitar.standard"
  property int selectedReferenceMidiNumber: 69
  property string referencePlaybackMode: "single"
  property int selectedReferenceIntervalSemitones: 7
  property string selectedReferenceChordId: "major"
  property bool highContrastMode: false
  property bool reducedMotionMode: false
  property var pendingCommandLines: []
  property string lastProtocolType: ""
  property string lastProtocolLine: ""
  property string lastStderrLine: ""
  property int lastExitCode: 0
  property var metronomeTapTimes: []
  property var favoriteQuickSwitches: []
  property var recentQuickSwitches: []

  readonly property int minimumReferenceMidiNumber: 12
  readonly property int maximumReferenceMidiNumber: 119
  readonly property real minimumReferenceAHz: 400.0
  readonly property real maximumReferenceAHz: 480.0
  readonly property int minimumTranspositionSemitones: -12
  readonly property int maximumTranspositionSemitones: 12
  readonly property int minimumMetronomeBpm: 20
  readonly property int maximumMetronomeBpm: 300
  readonly property int maximumReferenceIntervalSemitones: 24
  readonly property int maximumFavoriteQuickSwitches: 6
  readonly property int maximumRecentQuickSwitches: 6
  readonly property int settingsConfigVersion: 1
  readonly property int helperRecoveryMaxAttempts: 5
  readonly property int defaultMetronomeBpm: 100
  readonly property int defaultMetronomeBeatsPerBar: 4
  readonly property int defaultMetronomeBeatUnit: 4
  readonly property int defaultMetronomeSubdivision: 1
  readonly property int metronomeTapResetMs: 2000
  readonly property int defaultReferenceIntervalSemitones: 7
  readonly property string defaultReferenceChordId: "major"
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
  readonly property var referencePlaybackModes: ["single", "drone", "chord"]
  readonly property var referenceIntervalPresets: [
    { semitones: 3, label: "m3" },
    { semitones: 4, label: "M3" },
    { semitones: 5, label: "P4" },
    { semitones: 7, label: "P5" },
    { semitones: 12, label: "Oct" },
  ]
  readonly property var referenceChordPresets: [
    { id: "major", label: "Major", intervalsSemitones: [4, 7] },
    { id: "minor", label: "Minor", intervalsSemitones: [3, 7] },
    { id: "sus2", label: "Sus2", intervalsSemitones: [2, 7] },
    { id: "sus4", label: "Sus4", intervalsSemitones: [5, 7] },
  ]
  readonly property var tuningPresetGroups: [
    {
      label: "Guitar",
      presets: [
        { id: "guitar.standard", label: "Standard", notes: ["E2", "A2", "D3", "G3", "B3", "E4"] },
        { id: "guitar.drop_d", label: "Drop D", notes: ["D2", "A2", "D3", "G3", "B3", "E4"] },
        { id: "guitar.dadgad", label: "DADGAD", notes: ["D2", "A2", "D3", "G3", "A3", "D4"] },
      ],
    },
    {
      label: "Bass",
      presets: [
        { id: "bass.standard_4", label: "4-string", notes: ["E1", "A1", "D2", "G2"] },
        { id: "bass.standard_5", label: "5-string", notes: ["B0", "E1", "A1", "D2", "G2"] },
      ],
    },
    {
      label: "Ukulele",
      presets: [
        { id: "ukulele.standard", label: "Standard", notes: ["G4", "C4", "E4", "A4"] },
        { id: "ukulele.baritone", label: "Baritone", notes: ["D3", "G3", "B3", "E4"] },
      ],
    },
    {
      label: "Violin Family",
      presets: [
        { id: "violin.violin", label: "Violin", notes: ["G3", "D4", "A4", "E5"] },
        { id: "violin.viola", label: "Viola", notes: ["C3", "G3", "D4", "A4"] },
        { id: "violin.cello", label: "Cello", notes: ["C2", "G2", "D3", "A3"] },
      ],
    },
  ]
  readonly property bool pitchActive: signalState === "pitch"
  readonly property bool toneActive: activeToneNote !== ""
  readonly property bool inTune: pitchActive && Math.abs(detectedCents) <= 5
  readonly property bool hasAlert: helperRecoveryPending || helperState === "error" || runtimeErrorMessage !== ""
  readonly property bool shouldAnimateUi: !reducedMotionMode
  readonly property bool transpositionActive: transpositionSemitones !== 0
  readonly property bool standardGuitarPresetSelected: selectedPresetId === "guitar.standard"
  readonly property int minimumDisplayedReferenceMidiNumber: minimumDisplayedReferenceMidiNumberForTransposition(transpositionSemitones)
  readonly property int maximumDisplayedReferenceMidiNumber: maximumDisplayedReferenceMidiNumberForTransposition(transpositionSemitones)
  readonly property int selectedReferencePitchClassIndex: ((selectedReferenceMidiNumber % 12) + 12) % 12
  readonly property int selectedReferenceOctave: Math.floor(selectedReferenceMidiNumber / 12) - 1
  readonly property var selectedPreset: presetById(selectedPresetId)
  readonly property var selectedPresetBaseNotes: selectedPreset ? selectedPreset.notes : []
  readonly property var selectedPresetNotes: transposeNoteTextList(selectedPresetBaseNotes, transpositionSemitones)
  readonly property string selectedPresetLabel: selectedPreset ? (selectedPreset.groupLabel + " | " + selectedPreset.label) : "Guitar | Standard"
  readonly property bool currentQuickSwitchFavorite: indexOfQuickSwitchScene(favoriteQuickSwitches, currentQuickSwitchScene()) >= 0
  readonly property var visibleRecentQuickSwitches: recentQuickSwitchesForDisplay()
  readonly property bool hasQuickSwitches: favoriteQuickSwitches.length > 0 || visibleRecentQuickSwitches.length > 0
  readonly property string transpositionLabelText: formatTranspositionLabel(transpositionSemitones)
  readonly property string selectedReferenceCommandNoteLabel: formatMidiNote(selectedReferenceMidiNumber, "sharps")
  readonly property string selectedReferenceNoteLabel: formatMidiNote(selectedReferenceMidiNumber, noteSpelling)
  readonly property int selectedReferenceIntervalPresetIndex: indexOfReferenceIntervalPreset(selectedReferenceIntervalSemitones)
  readonly property int selectedReferenceChordPresetIndex: indexOfReferenceChordPreset(selectedReferenceChordId)
  readonly property var selectedReferenceIntervalsSemitones: {
    if (referencePlaybackMode === "drone") return [selectedReferenceIntervalSemitones]

    if (referencePlaybackMode === "chord") {
      var chordPreset = chordPresetById(selectedReferenceChordId)
      return chordPreset ? chordPreset.intervalsSemitones.slice(0) : []
    }

    return []
  }
  readonly property string detectedNoteLabel: displayNoteLabel(detectedNote)
  readonly property string activeToneNoteLabel: displayNoteLabel(activeToneNote)
  readonly property string selectedReferenceSceneLabel: formatReferenceSceneLabel(selectedReferenceNoteLabel, selectedReferenceIntervalsSemitones)
  readonly property bool activeToneHasIntervals: activeToneIntervalsSemitones.length > 0
  readonly property string activeToneSceneKind: {
    if (!toneActive) return ""
    if (activeToneIntervalsSemitones.length > 1) return "chord"
    if (activeToneIntervalsSemitones.length === 1) return "interval"
    return "tone"
  }
  readonly property string activeTonePlaybackTypeText: {
    if (activeToneSceneKind === "chord") return "Reference chord"
    if (activeToneSceneKind === "interval") return "Drone interval"
    return "Reference tone"
  }
  readonly property string activeToneSceneLabel: formatReferenceSceneLabel(activeToneNoteLabel, activeToneIntervalsSemitones)
  readonly property string activeToneVoiceSummaryText: formatToneVoiceSummary(activeToneVoices)
  readonly property int selectedMetronomeMeterPresetIndex: indexOfMetronomeMeterPreset(metronomeBeatsPerBar, metronomeBeatUnit)
  readonly property string metronomeMeterLabel: metronomeMeterPresets[selectedMetronomeMeterPresetIndex].label
  readonly property int selectedMetronomeSubdivisionPresetIndex: indexOfMetronomeSubdivisionPreset(metronomeSubdivision)
  readonly property string metronomeSubdivisionLabel: metronomeSubdivisionPresets[selectedMetronomeSubdivisionPresetIndex].label
  readonly property string metronomeBeatText: {
    var beatsPerBar = normalizeMetronomeBeatsPerBar(metronomeBeatsPerBar, metronomeBeatUnit)
    var beatInBar = Math.round(finiteNumber(metronomeBeatInBar, 1))
    if (beatInBar < 1 || beatInBar > beatsPerBar) beatInBar = 1
    var beatText = "Beat " + beatInBar + " of " + beatsPerBar
    if (metronomeSubdivision <= 1) return beatText

    var subdivisionStep = Math.round(finiteNumber(metronomeSubdivisionStep, 1))
    if (subdivisionStep < 1 || subdivisionStep > metronomeSubdivision) subdivisionStep = 1
    return beatText + ", step " + subdivisionStep + " of " + metronomeSubdivision
  }
  readonly property string metronomeSummaryText: metronomeBpm + " BPM | " + metronomeMeterLabel + " | " + metronomeSubdivisionLabel + " | " + metronomeBeatText + " | Accent on 1"
  readonly property string metronomeHintText: metronomeActive
    ? "BPM, meter, and subdivision changes restart on beat one."
    : "Tap tempo, set a meter, and add subdivisions."
  readonly property bool selectedReferenceToneActive: toneActive
    && sameNoteText(activeToneNote, selectedReferenceCommandNoteLabel)
    && sameIntegerArray(activeToneIntervalsSemitones, selectedReferenceIntervalsSemitones)
  readonly property string helperRecoveryStatusText: {
    if (!helperRecoveryPending) return ""
    return "Recovering the audio helper (attempt " + helperRecoveryAttempt + " of " + helperRecoveryMaxAttempts + "). " + helperRecoveryMessage
  }
  readonly property string currentErrorSummaryText: {
    if (runtimeErrorMessage !== "") return runtimeErrorMessage
    if (helperError !== "") return helperError
    if (lastStderrLine !== "") return lastStderrLine
    if (helperState === "error") return "Restart the helper to recover."
    return ""
  }
  readonly property string pitchGuidanceText: {
    if (!pitchActive) return ""
    if (inTune) return "In tune"
    return detectedCents < 0 ? "Tune up" : "Tune down"
  }
  readonly property string barPitchStatusText: {
    if (!pitchActive) return ""
    if (inTune) return "="
    return detectedCents < 0 ? "-" : "+"
  }
  readonly property string barToneStateText: {
    if (!toneActive) return ""
    if (activeToneSceneKind === "chord") return "CHD"
    if (activeToneSceneKind === "interval") return "DRN"
    return "REF"
  }
  readonly property string barMeasureText: "CHD Bb8"
  readonly property string stateBadgeText: {
    if (helperRecoveryPending) return "Recovering"
    if (helperState === "error" || runtimeErrorMessage !== "") return "Error"
    if (helperState === "inactive") return "Off"
    if (helperState === "starting") return "Starting"
    if (pitchActive) return inTune ? "In tune" : (detectedCents < 0 ? "Tune up" : "Tune down")
    if (toneActive) {
      if (activeToneSceneKind === "chord") return "Reference chord"
      if (activeToneSceneKind === "interval") return "Drone interval"
      return "Reference tone"
    }
    if (metronomeActive) return "Metronome"
    if (signalState === "no_signal") return "No signal"
    return "Listening"
  }
  readonly property string quickTuneHeadingText: standardGuitarPresetSelected ? "Standard guitar" : "Quick tune"
  readonly property string keyboardShortcutSummary: "Keys: 1-6 notes | Ctrl+1-6 favorites | F favorite | Left/Right note | Alt+Up/Down octave | Shift+Left/Right BPM | D mode | [/] shape | M metro | Shift+M tap | Ctrl+M meter | Alt+M subdiv | P play/stop | X stop | T power | R restart | Esc close"
  readonly property bool opened: popupLoader.item ? popupLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: popupLoader.item ? popupLoader.item.popoutSwitchClosing === true : false
  readonly property string helperScriptPath: localPath("scripts/run-helper.sh")
  readonly property var helperCommand: [
    "bash",
    helperScriptPath,
    "--reference-a-hz",
    formatReferenceAForHelper(referenceAHz),
    "--transposition-semitones",
    String(normalizeTranspositionSemitones(transpositionSemitones)),
  ]
  readonly property string readoutTitleText: {
    if (helperRecoveryPending) return "Recovering audio"
    if (pitchActive) return detectedNoteLabel
    if (toneActive) return activeToneSceneLabel
    if (metronomeActive) return metronomeBpm + " BPM"
    if (helperState === "error" || runtimeErrorMessage !== "") return "Check audio"
    if (helperState === "starting") return "Opening audio"
    if (helperState === "inactive") return "Tuner off"
    if (signalState === "no_signal") return "Play a note"
    return "Ready"
  }
  readonly property string readoutFooterText: {
    if (pitchActive) return formatSignedCents(detectedCents) + " | " + formatFrequency(detectedFrequencyHz) + " Hz"
    if (toneActive) return "Root " + formatFrequency(activeToneFrequencyHz) + " Hz | A4 = " + formatReferenceA(referenceAHz)
    if (metronomeActive) return metronomeMeterLabel + " | " + metronomeSubdivisionLabel + " | " + metronomeBeatText
    if (helperRecoveryPending) return helperRecoveryStatusText
    if (helperState === "starting") return "Opening microphone and output..."
    if (helperState === "inactive") return "Turn the tuner on to begin capture."
    if (helperState === "error" || runtimeErrorMessage !== "") return currentErrorSummaryText
    if (signalState === "no_signal") return "Listening for a steady pitch."
    return "Listening for pitch..."
  }
  readonly property string statusText: {
    if (helperRecoveryPending) return "Recovering audio helper."
    if (helperState === "error") return helperError !== "" ? helperError : "The audio helper stopped."
    if (runtimeErrorMessage !== "") return runtimeErrorMessage
    if (helperState === "inactive") return "Turn on the tuner to start capture."
    if (helperState === "starting") return "Starting audio..."
    if (pitchActive) return pitchGuidanceText
    if (toneActive && metronomeActive) return "Reference tone and metronome active."
    if (toneActive) return activeTonePlaybackTypeText + " active."
    if (metronomeActive) return "Metronome active at " + metronomeBpm + " BPM."
    if (signalState === "no_signal") return "Play a steady note."
    return "Listening for pitch."
  }
  readonly property string detailText: {
    if (toneActive)
      return activeToneSceneLabel
        + (metronomeActive ? (" | " + metronomeBpm + " BPM") : "")
        + (transpositionActive ? (" | " + transpositionLabelText) : "")
        + " | " + selectedPresetLabel
    if (pitchActive)
      return selectedPresetLabel
        + (transpositionActive ? (" | " + transpositionLabelText) : "")
        + (metronomeActive ? (" | " + metronomeBpm + " BPM") : "")
        + " | A4 = " + formatReferenceA(referenceAHz)
    if (metronomeActive)
      return metronomeBpm + " BPM | " + metronomeMeterLabel + " | " + metronomeSubdivisionLabel
        + (transpositionActive ? (" | " + transpositionLabelText) : "")
        + " | " + selectedPresetLabel
    return selectedPresetLabel + (transpositionActive ? (" | " + transpositionLabelText) : "") + " | A4 = " + formatReferenceA(referenceAHz)
  }
  readonly property string buttonText: {
    if (helperRecoveryPending) return "RETRY"
    if (helperState === "error" || runtimeErrorMessage !== "") return "ERR"
    if (helperState === "inactive") return "OFF"
    if (helperState === "starting") return "START"
    if (pitchActive) return detectedNoteLabel + barPitchStatusText
    if (toneActive) return barToneStateText + " " + activeToneNoteLabel
    if (metronomeActive) return "MET"
    if (signalState === "no_signal") return "QUIET"
    return "TUNE"
  }
  readonly property string tooltipText: {
    var lines = ["Omatune"]

    if (helperRecoveryPending) {
      lines.push("Recovering audio helper (" + helperRecoveryAttempt + "/" + helperRecoveryMaxAttempts + ")")
      if (helperRecoveryMessage !== "") lines.push(helperRecoveryMessage)
      return lines.join("\n")
    }

    if (helperState === "error" || runtimeErrorMessage !== "") {
      lines.push("Audio error")
      if (currentErrorSummaryText !== "") lines.push(currentErrorSummaryText)
      return lines.join("\n")
    }

    if (helperState === "inactive") {
      lines.push("Tuner off")
      return lines.join("\n")
    }

    if (helperState === "starting") {
      lines.push("Starting audio")
      return lines.join("\n")
    }

    if (pitchActive) {
      lines.push(detectedNoteLabel + "  " + formatSignedCents(detectedCents) + "  " + formatFrequency(detectedFrequencyHz) + " Hz")
      return lines.join("\n")
    }

    if (toneActive) {
      lines.push(activeTonePlaybackTypeText + ": " + activeToneSceneLabel)
      if (activeToneVoiceSummaryText !== "") lines.push(activeToneVoiceSummaryText)
      return lines.join("\n")
    }

    if (metronomeActive) {
      lines.push("Metronome: " + metronomeBpm + " BPM | " + metronomeMeterLabel + " | " + metronomeSubdivisionLabel)
      return lines.join("\n")
    }

    if (signalState === "no_signal") {
      lines.push("No signal. Play a steady note.")
      return lines.join("\n")
    }

    lines.push("Listening for pitch")
    return lines.join("\n")
  }

  implicitWidth: Math.max(button.implicitWidth, buttonSizer.implicitWidth)
  implicitHeight: Math.max(button.implicitHeight, buttonSizer.implicitHeight)

  function localPath(relativePath) {
    return decodeURIComponent(String(Qt.resolvedUrl(relativePath)).replace(/^file:\/\//, ""))
  }

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

  function transposeNoteTextList(noteTexts, semitoneOffset) {
    var list = Array.isArray(noteTexts) ? noteTexts : []
    var transposed = []

    for (var index = 0; index < list.length; index++) {
      var noteText = transposeNoteText(list[index], semitoneOffset)
      if (noteText === "") continue
      transposed.push(noteText)
    }

    return transposed
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
    if (text === "drone" || text === "chord") return text
    return "single"
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
    if (normalizedIntervals.length === 1) return "drone"
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
    var root = String(rootNoteLabel || "")
    var normalizedIntervals = normalizeProtocolIntervalArray(intervals)
    if (root === "" || normalizedIntervals.length === 0) return root

    var chordPreset = normalizedIntervals.length > 1 ? chordPresetByIntervals(normalizedIntervals) : null
    if (chordPreset && String(chordPreset.label || "") !== "") return root + " " + String(chordPreset.label || "")

    var intervalText = intervalListLabel(intervals)
    if (root === "" || intervalText === "") return root
    return root + " + " + intervalText
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

  function presetById(presetId) {
    var targetId = String(presetId || "")

    for (var groupIndex = 0; groupIndex < tuningPresetGroups.length; groupIndex++) {
      var group = tuningPresetGroups[groupIndex]
      var presets = Array.isArray(group.presets) ? group.presets : []

      for (var presetIndex = 0; presetIndex < presets.length; presetIndex++) {
        var preset = presets[presetIndex]
        if (String(preset.id || "") !== targetId) continue

        return {
          id: String(preset.id || ""),
          label: String(preset.label || ""),
          groupLabel: String(group.label || ""),
          notes: Array.isArray(preset.notes) ? preset.notes : [],
        }
      }
    }

    return {
      id: "guitar.standard",
      label: "Standard",
      groupLabel: "Guitar",
      notes: ["E2", "A2", "D3", "G3", "B3", "E4"],
    }
  }

  function isQuickSwitchSceneCandidate(value) {
    return value && typeof value === "object"
      && ("presetId" in value
        || "referenceNote" in value
        || "transpositionSemitones" in value
        || "playbackMode" in value
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
    var referenceMidiNumber = normalizeDisplayedReferenceMidiNumberForTransposition(
      parseNoteMidiNumber(value.referenceNote) === null ? 69 : parseNoteMidiNumber(value.referenceNote),
      transposition
    )
    var metronomeMeter = metronomeMeterPresetByValues(value.metronomeBeatsPerBar, value.metronomeBeatUnit)

    return {
      presetId: presetById(value.presetId).id,
      referenceNote: formatMidiNote(referenceMidiNumber, "sharps"),
      transpositionSemitones: transposition,
      playbackMode: normalizeReferencePlaybackMode(value.playbackMode),
      intervalSemitones: normalizeSelectedReferenceIntervalSemitones(value.intervalSemitones),
      chordId: normalizeSelectedReferenceChordId(value.chordId),
      metronomeBpm: normalizeMetronomeBpm(value.metronomeBpm),
      metronomeBeatsPerBar: metronomeMeter.beatsPerBar,
      metronomeBeatUnit: metronomeMeter.beatUnit,
      metronomeSubdivision: normalizeMetronomeSubdivision(value.metronomeSubdivision),
    }
  }

  function currentQuickSwitchScene() {
    return normalizeQuickSwitchScene({
      presetId: selectedPresetId,
      referenceNote: selectedReferenceCommandNoteLabel,
      transpositionSemitones: transpositionSemitones,
      playbackMode: referencePlaybackMode,
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
      normalized.referenceNote,
      normalized.transpositionSemitones,
      normalized.playbackMode,
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
      + "|" + normalized.playbackMode + "|" + quickSwitchSceneIntervals(normalized).join(",")
  }

  function sameQuickSwitchScene(left, right) {
    var leftFingerprint = quickSwitchSceneFingerprint(left)
    return leftFingerprint !== "" && leftFingerprint === quickSwitchSceneFingerprint(right)
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

    if (normalized.playbackMode === "drone") return [normalized.intervalSemitones]

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

    return formatReferenceSceneLabel(displayNoteLabel(normalized.referenceNote), quickSwitchSceneIntervals(normalized))
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

    if (presetText !== "") primaryParts.push(presetText)
    if (referenceText !== "") primaryParts.push(referenceText)
    if (normalized.transpositionSemitones !== 0) {
      if (transpositionPreset && String(transpositionPreset.label || "") !== "")
        detailParts.push(String(transpositionPreset.label || ""))
      else detailParts.push(formatSignedSemitoneOffset(normalized.transpositionSemitones))
    }
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

  function rememberCurrentQuickSwitch() {
    recentQuickSwitches = prependedQuickSwitchSceneList(recentQuickSwitches, currentQuickSwitchScene(), maximumRecentQuickSwitches)
  }

  function toggleCurrentQuickSwitchFavorite() {
    var scene = currentQuickSwitchScene()
    if (!scene) return

    if (indexOfQuickSwitchScene(favoriteQuickSwitches, scene) >= 0)
      favoriteQuickSwitches = filteredQuickSwitchSceneList(favoriteQuickSwitches, scene, maximumFavoriteQuickSwitches)
    else {
      favoriteQuickSwitches = prependedQuickSwitchSceneList(favoriteQuickSwitches, scene, maximumFavoriteQuickSwitches)
      recentQuickSwitches = filteredQuickSwitchSceneList(recentQuickSwitches, scene, maximumRecentQuickSwitches)
    }

    persistWidgetSettings()
  }

  function applyQuickSwitchScene(scene) {
    var normalized = normalizeQuickSwitchScene(scene)
    if (!normalized) return false

    var currentReferenceState = quickSwitchReferenceStateFingerprint(currentQuickSwitchScene())
    var nextReferenceState = quickSwitchReferenceStateFingerprint(normalized)
    var metronomeChanged = metronomeBpm !== normalized.metronomeBpm
      || metronomeBeatsPerBar !== normalized.metronomeBeatsPerBar
      || metronomeBeatUnit !== normalized.metronomeBeatUnit
      || metronomeSubdivision !== normalized.metronomeSubdivision
    var transpositionChanged = transpositionSemitones !== normalized.transpositionSemitones
    var referenceMidiNumber = parseNoteMidiNumber(normalized.referenceNote)

    settingsHydrating = true
    selectedPresetId = normalized.presetId
    transpositionSemitones = normalized.transpositionSemitones
    selectedReferenceMidiNumber = normalizeDisplayedReferenceMidiNumberForTransposition(referenceMidiNumber === null ? 69 : referenceMidiNumber, normalized.transpositionSemitones)
    referencePlaybackMode = normalized.playbackMode
    selectedReferenceIntervalSemitones = normalized.intervalSemitones
    selectedReferenceChordId = normalized.chordId
    metronomeBpm = normalized.metronomeBpm
    metronomeBeatsPerBar = normalized.metronomeBeatsPerBar
    metronomeBeatUnit = normalized.metronomeBeatUnit
    metronomeSubdivision = normalized.metronomeSubdivision
    recentQuickSwitches = prependedQuickSwitchSceneList(recentQuickSwitches, normalized, maximumRecentQuickSwitches)
    settingsHydrating = false
    persistWidgetSettings()

    if (transpositionChanged && (helperWanted || helperProcessStarted || helperProc.running))
      queueHelperCommand({ type: "set_transposition", semitones: transpositionSemitones })
    if (currentReferenceState !== nextReferenceState && toneActive) playSelectedTone()
    if (metronomeChanged && metronomeActive && (helperWanted || helperProcessStarted || helperProc.running))
      queueHelperCommand(metronomeStartCommand())

    return true
  }

  function applyFavoriteQuickSwitchAt(index) {
    var numeric = Math.round(finiteNumber(index, -1))
    if (numeric < 0 || numeric >= favoriteQuickSwitches.length) return false
    return applyQuickSwitchScene(favoriteQuickSwitches[numeric])
  }

  function normalizedSettingsObject(value) {
    var source = value && typeof value === "object" ? value : ({})
    var transposition = normalizeTranspositionSemitones(source.transpositionSemitones)
    var selectedMidiNumber = normalizeDisplayedReferenceMidiNumberForTransposition(
      parseNoteMidiNumber(source.selectedReferenceNote) === null ? 69 : parseNoteMidiNumber(source.selectedReferenceNote),
      transposition
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
      selectedPresetId: presetById(source.selectedPresetId).id,
      selectedReferenceNote: formatMidiNote(selectedMidiNumber, "sharps"),
      metronomeBpm: normalizeMetronomeBpm(source.metronomeBpm),
      metronomeBeatsPerBar: metronomePreset.beatsPerBar,
      metronomeBeatUnit: metronomePreset.beatUnit,
      metronomeSubdivision: normalizeMetronomeSubdivision(source.metronomeSubdivision),
      highContrastMode: normalizeBooleanSetting(source.highContrastMode, false),
      reducedMotionMode: normalizeBooleanSetting(source.reducedMotionMode, false),
      favoriteQuickSwitches: filteredQuickSwitchSceneList(source.favoriteQuickSwitches, null, maximumFavoriteQuickSwitches),
      recentQuickSwitches: filteredQuickSwitchSceneList(source.recentQuickSwitches, null, maximumRecentQuickSwitches),
    }
  }

  function currentNormalizedSettingsObject() {
    return normalizedSettingsObject({
      referenceAHz: referenceAHz,
      transpositionSemitones: transpositionSemitones,
      noteSpelling: noteSpelling,
      selectedPresetId: selectedPresetId,
      selectedReferenceNote: selectedReferenceCommandNoteLabel,
      metronomeBpm: metronomeBpm,
      metronomeBeatsPerBar: metronomeBeatsPerBar,
      metronomeBeatUnit: metronomeBeatUnit,
      metronomeSubdivision: metronomeSubdivision,
      highContrastMode: highContrastMode,
      reducedMotionMode: reducedMotionMode,
      favoriteQuickSwitches: favoriteQuickSwitches,
      recentQuickSwitches: recentQuickSwitches,
    })
  }

  function exportedConfigurationJson() {
    return JSON.stringify(currentNormalizedSettingsObject(), null, 2)
  }

  function importedSettingsConfigVersion(settingsObject) {
    if (!settingsObject || typeof settingsObject !== "object" || Array.isArray(settingsObject)) return null
    if (!("configVersion" in settingsObject)) return null

    var numeric = Number(settingsObject.configVersion)
    if (!isFinite(numeric) || Math.round(numeric) !== numeric) return null
    return numeric
  }

  function applyNormalizedSettings(settingsObject, persistChanges) {
    var settings = settingsObject && typeof settingsObject === "object"
      ? settingsObject
      : currentNormalizedSettingsObject()
    var shouldPersist = persistChanges !== false
    var previousReferenceAHz = referenceAHz
    var previousTranspositionSemitones = transpositionSemitones
    var previousMetronomeBpm = metronomeBpm
    var previousMetronomeBeatsPerBar = metronomeBeatsPerBar
    var previousMetronomeBeatUnit = metronomeBeatUnit
    var previousMetronomeSubdivision = metronomeSubdivision
    var previousReferenceState = quickSwitchReferenceStateFingerprint(currentQuickSwitchScene())
    var selectedMidiNumber = parseNoteMidiNumber(settings.selectedReferenceNote)

    settingsHydrating = true
    referenceAHz = settings.referenceAHz
    transpositionSemitones = settings.transpositionSemitones
    noteSpelling = settings.noteSpelling
    selectedPresetId = settings.selectedPresetId
    metronomeBpm = settings.metronomeBpm
    metronomeBeatsPerBar = settings.metronomeBeatsPerBar
    metronomeBeatUnit = settings.metronomeBeatUnit
    metronomeSubdivision = settings.metronomeSubdivision
    highContrastMode = settings.highContrastMode
    reducedMotionMode = settings.reducedMotionMode
    favoriteQuickSwitches = settings.favoriteQuickSwitches
    recentQuickSwitches = settings.recentQuickSwitches
    selectedReferenceMidiNumber = normalizeDisplayedReferenceMidiNumberForTransposition(selectedMidiNumber === null ? 69 : selectedMidiNumber, transpositionSemitones)
    settingsHydrating = false

    if (shouldPersist) persistWidgetSettings()

    if (Math.abs(referenceAHz - previousReferenceAHz) >= 0.0001
        && (helperWanted || helperProcessStarted || helperProc.running)) {
      queueHelperCommand({ type: "set_reference_a", frequency_hz: referenceAHz })
    }
    if (transpositionSemitones !== previousTranspositionSemitones
        && (helperWanted || helperProcessStarted || helperProc.running)) {
      queueHelperCommand({ type: "set_transposition", semitones: transpositionSemitones })
    }

    var currentReferenceState = quickSwitchReferenceStateFingerprint(currentQuickSwitchScene())
    if (previousReferenceState !== currentReferenceState
        && toneActive
        && (helperWanted || helperProcessStarted || helperProc.running)) {
      playSelectedTone()
    }

    if ((metronomeBpm !== previousMetronomeBpm
        || metronomeBeatsPerBar !== previousMetronomeBeatsPerBar
        || metronomeBeatUnit !== previousMetronomeBeatUnit
        || metronomeSubdivision !== previousMetronomeSubdivision)
        && metronomeActive
        && (helperWanted || helperProcessStarted || helperProc.running)) {
      queueHelperCommand(metronomeStartCommand())
    }
  }

  function importConfigurationJson(text) {
    var trimmed = String(text || "").trim()
    if (trimmed === "") {
      return {
        ok: false,
        message: "Import failed: paste a JSON object with Omatune settings.",
      }
    }

    var importedSettings
    try {
      importedSettings = JSON.parse(trimmed)
    } catch (error) {
      return {
        ok: false,
        message: "Import failed: invalid JSON. " + String(error),
      }
    }

    if (!importedSettings || typeof importedSettings !== "object" || Array.isArray(importedSettings)) {
      return {
        ok: false,
        message: "Import failed: configuration must be a JSON object.",
      }
    }

    // Reject future schema versions so older builds do not silently misread newer exports.
    var importedConfigVersion = importedSettingsConfigVersion(importedSettings)
    if (importedConfigVersion !== null && importedConfigVersion > settingsConfigVersion) {
      return {
        ok: false,
        message: "Import failed: configVersion " + importedConfigVersion + " is newer than this build supports.",
      }
    }

    applyNormalizedSettings(normalizedSettingsObject(importedSettings), true)
    return {
      ok: true,
      message: "Imported configuration.",
      text: exportedConfigurationJson(),
    }
  }

  function persistedSettingsEntry() {
    var entry = { id: root.moduleName }
    var existingSettings = root.settings || ({})
    var settings = currentNormalizedSettingsObject()

    for (var key in existingSettings)
      if (key !== "id" && key !== "popupLayoutMode") entry[key] = existingSettings[key]

    for (var settingsKey in settings)
      entry[settingsKey] = settings[settingsKey]

    return entry
  }

  function persistWidgetSettings() {
    if (settingsHydrating) return

    var entry = persistedSettingsEntry()
    root.settings = entry

    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function loadPersistedSettings() {
    applyNormalizedSettings(normalizedSettingsObject(root.settings || ({})), false)
  }

  function setReferenceA(value) {
    var next = normalizeReferenceAHz(value)
    if (Math.abs(next - referenceAHz) < 0.0001) return

    referenceAHz = next
    persistWidgetSettings()

    if (helperWanted || helperProcessStarted || helperProc.running)
      queueHelperCommand({ type: "set_reference_a", frequency_hz: referenceAHz })
  }

  function changeReferenceA(delta) {
    setReferenceA(referenceAHz + finiteNumber(delta, 0))
  }

  function resetReferenceA() {
    setReferenceA(440.0)
  }

  function setTranspositionSemitones(value) {
    var previous = transpositionSemitones
    var next = normalizeTranspositionSemitones(value)
    if (next === previous) return

    var soundingMidiNumber = shiftedMidiNumber(selectedReferenceMidiNumber, -previous)
    transpositionSemitones = next
    selectedReferenceMidiNumber = normalizeDisplayedReferenceMidiNumberForTransposition(soundingMidiNumber + next, next)
    persistWidgetSettings()

    if (helperWanted || helperProcessStarted || helperProc.running)
      queueHelperCommand({ type: "set_transposition", semitones: transpositionSemitones })
  }

  function changeTranspositionSemitones(delta) {
    setTranspositionSemitones(transpositionSemitones + Math.round(finiteNumber(delta, 0)))
  }

  function resetTranspositionSemitones() {
    setTranspositionSemitones(0)
  }

  function metronomeStartCommand() {
    return {
      type: "start_metronome",
      bpm: normalizeMetronomeBpm(metronomeBpm),
      beats_per_bar: normalizeMetronomeBeatsPerBar(metronomeBeatsPerBar, metronomeBeatUnit),
      beat_unit: normalizeMetronomeBeatUnit(metronomeBeatsPerBar, metronomeBeatUnit),
      subdivision: normalizeMetronomeSubdivision(metronomeSubdivision),
    }
  }

  function restartMetronomeIfActive() {
    if (metronomeActive)
      queueHelperCommand(metronomeStartCommand())
  }

  function setMetronomeBpm(value) {
    var next = normalizeMetronomeBpm(value)
    if (next === metronomeBpm) return

    metronomeBpm = next
    persistWidgetSettings()
    restartMetronomeIfActive()
  }

  function changeMetronomeBpm(delta) {
    setMetronomeBpm(metronomeBpm + Math.round(finiteNumber(delta, 0)))
  }

  function resetMetronomeBpm() {
    setMetronomeBpm(defaultMetronomeBpm)
  }

  function setMetronomeMeter(beatsPerBar, beatUnit) {
    var preset = metronomeMeterPresetByValues(beatsPerBar, beatUnit)
    if (preset.beatsPerBar === metronomeBeatsPerBar && preset.beatUnit === metronomeBeatUnit) return

    metronomeBeatsPerBar = preset.beatsPerBar
    metronomeBeatUnit = preset.beatUnit
    persistWidgetSettings()
    restartMetronomeIfActive()
  }

  function changeMetronomeMeter(delta) {
    if (metronomeMeterPresets.length === 0) return

    var step = Math.round(finiteNumber(delta, 0))
    if (step === 0) return

    var nextIndex = (selectedMetronomeMeterPresetIndex + step) % metronomeMeterPresets.length
    if (nextIndex < 0) nextIndex += metronomeMeterPresets.length
    var nextPreset = metronomeMeterPresets[nextIndex]
    setMetronomeMeter(nextPreset.beatsPerBar, nextPreset.beatUnit)
  }

  function setMetronomeSubdivision(value) {
    var next = normalizeMetronomeSubdivision(value)
    if (next === metronomeSubdivision) return

    metronomeSubdivision = next
    persistWidgetSettings()
    restartMetronomeIfActive()
  }

  function changeMetronomeSubdivision(delta) {
    if (metronomeSubdivisionPresets.length === 0) return

    var step = Math.round(finiteNumber(delta, 0))
    if (step === 0) return

    var nextIndex = (selectedMetronomeSubdivisionPresetIndex + step) % metronomeSubdivisionPresets.length
    if (nextIndex < 0) nextIndex += metronomeSubdivisionPresets.length
    setMetronomeSubdivision(metronomeSubdivisionPresets[nextIndex].steps)
  }

  function tapMetronomeTempo() {
    var now = Date.now()
    var taps = Array.isArray(metronomeTapTimes) ? metronomeTapTimes.slice(0) : []

    if (taps.length > 0 && now - taps[taps.length - 1] > metronomeTapResetMs)
      taps = []

    taps.push(now)
    if (taps.length > 5)
      taps = taps.slice(taps.length - 5)

    metronomeTapTimes = taps
    if (taps.length < 2) return

    var totalIntervalMs = 0
    for (var index = 1; index < taps.length; index++)
      totalIntervalMs += taps[index] - taps[index - 1]

    var averageIntervalMs = totalIntervalMs / Math.max(1, taps.length - 1)
    if (!isFinite(averageIntervalMs) || averageIntervalMs <= 0) return

    setMetronomeBpm(60000 / averageIntervalMs)
  }

  function setNoteSpellingPreference(value) {
    var next = normalizeNoteSpelling(value)
    if (next === noteSpelling) return

    noteSpelling = next
    persistWidgetSettings()
  }

  function setReferencePlaybackMode(value) {
    var next = normalizeReferencePlaybackMode(value)
    if (next === referencePlaybackMode) return

    referencePlaybackMode = next
    if (toneActive) playSelectedTone()
  }

  function cycleReferencePlaybackMode() {
    var currentIndex = referencePlaybackModes.indexOf(referencePlaybackMode)
    if (currentIndex < 0) currentIndex = 0
    setReferencePlaybackMode(referencePlaybackModes[(currentIndex + 1) % referencePlaybackModes.length])
  }

  function setSelectedReferenceIntervalSemitones(value) {
    var next = normalizeSelectedReferenceIntervalSemitones(value)
    if (next === selectedReferenceIntervalSemitones) return

    selectedReferenceIntervalSemitones = next
    if (toneActive && referencePlaybackMode === "drone") playSelectedTone()
  }

  function changeSelectedReferenceIntervalPreset(delta) {
    if (referenceIntervalPresets.length === 0) return

    var step = Math.round(finiteNumber(delta, 0))
    if (step === 0) return

    var nextIndex = (selectedReferenceIntervalPresetIndex + step) % referenceIntervalPresets.length
    if (nextIndex < 0) nextIndex += referenceIntervalPresets.length
    setSelectedReferenceIntervalSemitones(referenceIntervalPresets[nextIndex].semitones)
  }

  function setSelectedReferenceChordId(value) {
    var next = normalizeSelectedReferenceChordId(value)
    if (next === selectedReferenceChordId) return

    selectedReferenceChordId = next
    if (toneActive && referencePlaybackMode === "chord") playSelectedTone()
  }

  function changeSelectedReferenceChordPreset(delta) {
    if (referenceChordPresets.length === 0) return

    var step = Math.round(finiteNumber(delta, 0))
    if (step === 0) return

    var nextIndex = (selectedReferenceChordPresetIndex + step) % referenceChordPresets.length
    if (nextIndex < 0) nextIndex += referenceChordPresets.length
    setSelectedReferenceChordId(referenceChordPresets[nextIndex].id)
  }

  function changeSelectedReferenceShapePreset(delta) {
    if (referencePlaybackMode === "chord") changeSelectedReferenceChordPreset(delta)
    else changeSelectedReferenceIntervalPreset(delta)
  }

  function setHighContrastMode(value) {
    var next = !!value
    if (next === highContrastMode) return

    highContrastMode = next
    persistWidgetSettings()
  }

  function toggleHighContrastMode() {
    setHighContrastMode(!highContrastMode)
  }

  function setReducedMotionMode(value) {
    var next = !!value
    if (next === reducedMotionMode) return

    reducedMotionMode = next
    persistWidgetSettings()
  }

  function toggleReducedMotionMode() {
    setReducedMotionMode(!reducedMotionMode)
  }

  function setSelectedReferenceMidiNumber(midiNumber) {
    var next = normalizeDisplayedReferenceMidiNumberForTransposition(midiNumber, transpositionSemitones)
    if (next === selectedReferenceMidiNumber) return false

    selectedReferenceMidiNumber = next
    persistWidgetSettings()
    return true
  }

  function applySelectedReferenceFromNote(noteText) {
    var midiNumber = parseNoteMidiNumber(noteText)
    if (midiNumber === null) return false

    setSelectedReferenceMidiNumber(midiNumber)
    return true
  }

  function selectPreset(presetId) {
    var preset = presetById(presetId)
    if (preset.id === selectedPresetId) return

    selectedPresetId = preset.id
    rememberCurrentQuickSwitch()
    persistWidgetSettings()
  }

  function clearPitchState() {
    signalState = "idle"
    detectedNote = ""
    detectedFrequencyHz = 0
    detectedCents = 0
    detectedConfidence = 0
  }

  function setNoSignal() {
    signalState = "no_signal"
    detectedNote = ""
    detectedFrequencyHz = 0
    detectedCents = 0
    detectedConfidence = 0
  }

  function clearToneState() {
    activeToneNote = ""
    activeToneFrequencyHz = 0
    activeToneIntervalsSemitones = []
    activeToneVoices = []
  }

  function clearMetronomeState() {
    metronomeActive = false
    metronomeBeatInBar = 0
    metronomeSubdivisionStep = 0
    metronomeBeatAccented = false
  }

  function clearRuntimeError() {
    runtimeErrorCode = ""
    runtimeErrorMessage = ""
  }

  function clearRecoverableStartupFailure() {
    recoverableStartupErrorCode = ""
    recoverableStartupErrorMessage = ""
  }

  function clearRecoveryState() {
    helperRecoveryPending = false
    helperRecoveryAttempt = 0
    helperRecoveryMessage = ""
    helperRestartDelayMs = 120
    clearRecoverableStartupFailure()
  }

  function helperExitMessage(exitCode) {
    if (lastStderrLine !== "") return lastStderrLine

    var numeric = Math.round(finiteNumber(exitCode, 0))
    return numeric === 0 ? "helper exited unexpectedly" : ("helper exited unexpectedly with code " + numeric)
  }

  function isRecoverableHelperErrorCode(code) {
    var value = String(code || "")
    return value === "audio_input_unavailable" || value === "audio_input_disconnected" || value === "helper_exit"
  }

  function recoveryDelayMsForAttempt(attempt) {
    var numeric = Math.max(1, Math.round(finiteNumber(attempt, 1)))
    if (numeric <= 1) return 250
    if (numeric === 2) return 500
    if (numeric === 3) return 1000
    if (numeric === 4) return 2000
    return 4000
  }

  function scheduleHelperRecovery(reason, messageText) {
    var recoveryReason = String(reason || "")
    if (!helperWanted || !isRecoverableHelperErrorCode(recoveryReason)) return false
    if (helperRecoveryPending && restartPending) return true

    var nextAttempt = helperRecoveryAttempt + 1
    var recoveryMessage = String(messageText || "helper recovery was requested")
    if (nextAttempt > helperRecoveryMaxAttempts) {
      restartPending = false
      helperWanted = false
      helperState = "error"
      helperErrorCode = recoveryReason
      helperError = recoveryMessage + " Retry limit reached; restart the tuner after the audio stack is available."
      runtimeErrorCode = recoveryReason === "helper_exit" ? "" : recoveryReason
      runtimeErrorMessage = recoveryReason === "helper_exit" ? "" : helperError
      pendingCommandLines = []
      clearPitchState()
      clearToneState()
      clearMetronomeState()
      clearRecoveryState()
      return false
    }

    helperRecoveryPending = true
    helperRecoveryAttempt = nextAttempt
    helperRecoveryMessage = recoveryMessage
    helperRestartDelayMs = recoveryDelayMsForAttempt(nextAttempt)
    helperState = "starting"
    helperReadySeen = false
    helperProcessStarted = false
    helperErrorCode = recoveryReason
    helperError = ""
    if (recoveryReason === "helper_exit") clearRuntimeError()
    else {
      runtimeErrorCode = recoveryReason
      runtimeErrorMessage = recoveryMessage
    }
    clearRecoverableStartupFailure()
    clearPitchState()
    clearToneState()
    clearMetronomeState()

    if (helperProc.running) {
      restartPending = true
      helperProc.running = false
    } else {
      restartPending = false
      helperRestartTimer.restart()
    }

    return true
  }

  function resetLiveState() {
    clearPitchState()
    clearToneState()
    clearMetronomeState()
    clearRuntimeError()
  }

  function isOutputErrorCode(code) {
    var value = String(code || "")
    return value === "audio_output_unavailable" || value === "audio_output_disconnected"
  }

  function isInputErrorCode(code) {
    var value = String(code || "")
    return value === "audio_input_unavailable" || value === "audio_input_disconnected"
  }

  function ensureHelperRunning() {
    if (helperProc.running) return

    helperWanted = true
    helperProcessStarted = false
    helperReadySeen = false
    helperState = "starting"
    helperErrorCode = ""
    helperError = ""
    clearRuntimeError()
    clearPitchState()
    clearToneState()
    lastProtocolType = ""
    lastProtocolLine = ""
    lastStderrLine = ""
    lastExitCode = 0
    helperProc.running = true
  }

  function startHelper() {
    var preserveRecoveryState = arguments.length > 0 ? !!arguments[0] : false

    helperRestartTimer.stop()
    restartPending = false
    if (!preserveRecoveryState) {
      pendingCommandLines = []
      clearRecoveryState()
    }
    ensureHelperRunning()
  }

  function stopHelper() {
    helperRestartTimer.stop()
    restartPending = false
    helperWanted = false
    helperProcessStarted = false
    helperReadySeen = false
    helperState = "inactive"
    helperErrorCode = ""
    helperError = ""
    pendingCommandLines = []
    lastExitCode = 0
    clearRecoveryState()
    resetLiveState()

    if (helperProc.running) helperProc.running = false
  }

  function restartHelper() {
    helperRestartTimer.stop()
    restartPending = false
    helperWanted = false
    helperProcessStarted = false
    helperReadySeen = false
    helperState = "starting"
    helperErrorCode = ""
    helperError = ""
    pendingCommandLines = []
    lastExitCode = 0
    clearRecoveryState()
    resetLiveState()

    if (helperProc.running) {
      restartPending = true
      helperProc.running = false
      return
    }

    helperRestartTimer.restart()
  }

  function toggleHelper() {
    if (helperWanted || helperProc.running) stopHelper()
    else startHelper()
  }

  function open() {
    if (popupLoader.item) popupLoader.item.open()
    if (helperState === "inactive") startHelper()
  }

  function close() {
    if (popupLoader.item) popupLoader.item.close()
  }

  function toggle() {
    if (popupLoader.item) {
      if (popupLoader.item.opened) popupLoader.item.close()
      else root.open()
    }
  }

  function closeForPopoutSwitch() {
    if (popupLoader.item) popupLoader.item.closeForPopoutSwitch()
  }

  function injectPopup() {
    var target = popupLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function flushPendingCommands() {
    if (!helperProcessStarted || pendingCommandLines.length === 0) return

    for (var index = 0; index < pendingCommandLines.length; index++)
      helperProc.write(String(pendingCommandLines[index]) + "\n")

    pendingCommandLines = []
  }

  function queueHelperCommand(commandObject) {
    var line = JSON.stringify(commandObject)

    if (helperProcessStarted) {
      helperProc.write(line + "\n")
      return
    }

    pendingCommandLines = pendingCommandLines.concat([line])
    ensureHelperRunning()
  }

  function playSelectedTone() {
    var command = {
      type: "play_tone",
      note: selectedReferenceCommandNoteLabel,
    }

    if (selectedReferenceIntervalsSemitones.length > 0)
      command.intervals_semitones = selectedReferenceIntervalsSemitones.slice(0)

    queueHelperCommand(command)
  }

  function startMetronome() {
    rememberCurrentQuickSwitch()
    persistWidgetSettings()
    queueHelperCommand(metronomeStartCommand())
  }

  function stopMetronome() {
    if (!helperWanted && !helperProc.running && !helperProcessStarted && pendingCommandLines.length === 0) {
      clearMetronomeState()
      return
    }

    queueHelperCommand({ type: "stop_metronome" })
  }

  function toggleMetronome() {
    if (metronomeActive) stopMetronome()
    else startMetronome()
  }

  function toggleSelectedReferenceTone() {
    if (selectedReferenceToneActive) stopTone()
    else {
      rememberCurrentQuickSwitch()
      persistWidgetSettings()
      playSelectedTone()
    }
  }

  function playReferenceNoteString(noteText) {
    var midiNumber = parseNoteMidiNumber(noteText)
    if (midiNumber === null) return

    selectedReferenceMidiNumber = midiNumber
    rememberCurrentQuickSwitch()
    persistWidgetSettings()
    playSelectedTone()
  }

  function presetNoteAt(index) {
    var numeric = Math.round(finiteNumber(index, -1))
    if (numeric < 0 || numeric >= selectedPresetNotes.length) return ""
    return String(selectedPresetNotes[numeric] || "")
  }

  function playPresetNoteAt(index) {
    var noteText = presetNoteAt(index)
    if (noteText === "") return false

    playReferenceNoteString(noteText)
    return true
  }

  function stopTone() {
    if (!helperProc.running && !helperProcessStarted) {
      pendingCommandLines = []
      clearToneState()
      return
    }

    if (!helperProcessStarted) {
      pendingCommandLines = []
      clearToneState()
      return
    }

    helperProc.write(JSON.stringify({ type: "stop_tone" }) + "\n")
  }

  function selectPitchClass(pitchClassIndex) {
    var numeric = Math.max(0, Math.min(11, Math.round(finiteNumber(pitchClassIndex, selectedReferencePitchClassIndex))))
    if (!setSelectedReferenceMidiNumber((selectedReferenceOctave + 1) * 12 + numeric)) return

    if (toneActive) playSelectedTone()
  }

  function changeReferenceSemitone(delta) {
    var next = selectedReferenceMidiNumber + Math.round(finiteNumber(delta, 0))
    next = Math.max(minimumReferenceMidiNumber, Math.min(maximumReferenceMidiNumber, next))
    if (!setSelectedReferenceMidiNumber(next)) return

    if (toneActive) playSelectedTone()
  }

  function changeReferenceOctave(delta) {
    var next = Math.max(0, Math.min(8, selectedReferenceOctave + Math.round(finiteNumber(delta, 0))))
    if (!setSelectedReferenceMidiNumber((next + 1) * 12 + selectedReferencePitchClassIndex)) return

    if (toneActive) playSelectedTone()
  }

  function handlePitchMessage(message) {
    helperState = "active"
    helperReadySeen = true
    signalState = "pitch"
    detectedNote = String(message.note || "")
    detectedFrequencyHz = Math.max(0, finiteNumber(message.frequency_hz, 0))
    detectedCents = clampNumber(message.cents, -50, 50, 0)
    detectedConfidence = clampNumber(message.confidence, 0, 1, 0)
    if (isOutputErrorCode(runtimeErrorCode)) clearRuntimeError()
  }

  function handleRuntimeError(code, messageText) {
    runtimeErrorCode = code
    runtimeErrorMessage = messageText

    if (isOutputErrorCode(code)) clearToneState()
    if (isOutputErrorCode(code)) clearMetronomeState()
    if (isInputErrorCode(code)) clearPitchState()
    if (isRecoverableHelperErrorCode(code)) scheduleHelperRecovery(code, messageText)
  }

  function handleHelperStdout(rawLine) {
    var line = String(rawLine || "").trim()
    if (line === "") return

    lastProtocolLine = line

    var message = parseJsonObject(line)
    if (!message || typeof message.type !== "string") {
      helperState = "error"
      helperErrorCode = "protocol_violation"
      helperError = "helper emitted non-protocol stdout"
      helperWanted = false
      helperReadySeen = false
      helperProcessStarted = false
      pendingCommandLines = []
      clearRecoveryState()
      if (helperProc.running) helperProc.running = false
      return
    }

    lastProtocolType = String(message.type)

    if (message.type === "ready") {
      helperState = "active"
      helperReadySeen = true
      helperErrorCode = ""
      helperError = ""
      clearRuntimeError()
      clearRecoveryState()
      return
    }

    if (message.type === "pitch") {
      handlePitchMessage(message)
      return
    }

    if (message.type === "no_signal") {
      helperState = "active"
      helperReadySeen = true
      setNoSignal()
      if (isOutputErrorCode(runtimeErrorCode)) clearRuntimeError()
      return
    }

    if (message.type === "tone_started") {
      helperState = "active"
      helperReadySeen = true
      activeToneNote = String(message.note || selectedReferenceCommandNoteLabel)
      activeToneFrequencyHz = Math.max(0, finiteNumber(message.frequency_hz, 0))
      activeToneIntervalsSemitones = normalizeProtocolIntervalArray(message.intervals_semitones)
      activeToneVoices = normalizeToneVoices(message.voices, activeToneNote, activeToneFrequencyHz)
      applySelectedReferenceFromNote(activeToneNote)
      referencePlaybackMode = playbackModeForIntervals(activeToneIntervalsSemitones)
      if (referencePlaybackMode === "drone")
        selectedReferenceIntervalSemitones = normalizeSelectedReferenceIntervalSemitones(activeToneIntervalsSemitones[0])
      else if (referencePlaybackMode === "chord") {
        var selectedChordPreset = chordPresetByIntervals(activeToneIntervalsSemitones)
        if (selectedChordPreset) selectedReferenceChordId = normalizeSelectedReferenceChordId(selectedChordPreset.id)
      }
      if (isOutputErrorCode(runtimeErrorCode)) clearRuntimeError()
      return
    }

    if (message.type === "tone_stopped") {
      helperState = "active"
      helperReadySeen = true
      clearToneState()
      if (isOutputErrorCode(runtimeErrorCode)) clearRuntimeError()
      return
    }

    if (message.type === "metronome_started") {
      helperState = "active"
      helperReadySeen = true
      metronomeActive = true
      metronomeBpm = normalizeMetronomeBpm(message.bpm)
      metronomeBeatsPerBar = normalizeMetronomeBeatsPerBar(message.beats_per_bar, message.beat_unit)
      metronomeBeatUnit = normalizeMetronomeBeatUnit(message.beats_per_bar, message.beat_unit)
      metronomeSubdivision = normalizeMetronomeSubdivision(message.subdivision)
      metronomeBeatInBar = 1
      metronomeSubdivisionStep = 1
      metronomeBeatAccented = true
      if (isOutputErrorCode(runtimeErrorCode)) clearRuntimeError()
      return
    }

    if (message.type === "metronome_beat") {
      helperState = "active"
      helperReadySeen = true
      metronomeActive = true
      metronomeBeatsPerBar = normalizeMetronomeBeatsPerBar(message.beats_per_bar, message.beat_unit)
      metronomeBeatUnit = normalizeMetronomeBeatUnit(message.beats_per_bar, message.beat_unit)
      metronomeSubdivision = normalizeMetronomeSubdivision(message.subdivision)
      metronomeBeatInBar = Math.max(1, Math.min(metronomeBeatsPerBar, Math.round(finiteNumber(message.beat_in_bar, 1))))
      metronomeSubdivisionStep = Math.max(1, Math.min(metronomeSubdivision, Math.round(finiteNumber(message.subdivision_step, 1))))
      metronomeBeatAccented = message.accented === true
      if (isOutputErrorCode(runtimeErrorCode)) clearRuntimeError()
      return
    }

    if (message.type === "metronome_stopped") {
      helperState = "active"
      helperReadySeen = true
      clearMetronomeState()
      if (isOutputErrorCode(runtimeErrorCode)) clearRuntimeError()
      return
    }

    if (message.type === "error") {
      var code = String(message.code || "internal_error")
      var messageText = String(message.message || code || "helper reported an error")

      if (!helperReadySeen) {
        if (helperWanted && isRecoverableHelperErrorCode(code)) {
          recoverableStartupErrorCode = code
          recoverableStartupErrorMessage = messageText
          helperState = "starting"
          helperErrorCode = code
          helperError = ""
          runtimeErrorCode = code
          runtimeErrorMessage = messageText
          return
        }

        helperState = "error"
        helperErrorCode = code
        helperError = messageText
        helperWanted = false
      } else {
        handleRuntimeError(code, messageText)
      }
      return
    }

    helperState = "error"
    helperErrorCode = "unknown_message_type"
    helperError = "helper emitted an unknown protocol message type"
    helperWanted = false
    helperReadySeen = false
    helperProcessStarted = false
    pendingCommandLines = []
    clearRecoveryState()
    if (helperProc.running) helperProc.running = false
  }

  function handleHelperStderr(rawLine) {
    var line = String(rawLine || "").trim()
    if (line !== "") lastStderrLine = line
  }

  function handleHelperExit(exitCode) {
    helperProcessStarted = false
    helperReadySeen = false

    if (restartPending) {
      restartPending = false
      lastExitCode = 0
      helperRestartTimer.restart()
      return
    }

    if (recoverableStartupErrorCode !== "" && helperWanted) {
      var startupErrorCode = recoverableStartupErrorCode
      var startupErrorMessage = recoverableStartupErrorMessage !== ""
        ? recoverableStartupErrorMessage
        : helperExitMessage(exitCode)
      lastExitCode = Number(exitCode)
      clearRecoverableStartupFailure()
      if (scheduleHelperRecovery(startupErrorCode, startupErrorMessage)) return
    }

    if (!helperWanted) {
      if (helperState !== "error") lastExitCode = 0
      clearRecoverableStartupFailure()
      return
    }

    lastExitCode = Number(exitCode)
    pendingCommandLines = []
    clearPitchState()
    clearToneState()
    if (scheduleHelperRecovery("helper_exit", helperExitMessage(exitCode))) return

    helperWanted = false

    if (helperState !== "error") {
      helperState = "error"
      helperErrorCode = "helper_exit"
      helperError = helperExitMessage(exitCode)
    }
  }

  Component.onCompleted: loadPersistedSettings()

  onBarChanged: injectPopup()
  onSettingsChanged: loadPersistedSettings()

  Loader {
    id: popupLoader
    active: true
    source: Qt.resolvedUrl("Popup.qml")
    visible: false
    onLoaded: {
      root.injectPopup()
      Qt.callLater(root.injectPopup)
    }
  }

  WidgetButton {
    id: buttonSizer
    visible: false
    enabled: false
    bar: root.bar
    text: root.barMeasureText
    horizontalMargin: button.horizontalMargin
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.buttonText
    tooltipText: root.tooltipText
    horizontalMargin: 7.5
    dimmed: root.helperState === "inactive"
      || (root.helperState === "active" && !root.pitchActive && !root.toneActive && !root.metronomeActive && !root.hasAlert)
    active: root.hasAlert || root.inTune || root.toneActive || root.metronomeActive
    activeColor: root.hasAlert ? Color.urgent : Color.accent
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
      else if (buttonCode === Qt.RightButton) root.toggleHelper()
      else if (buttonCode === Qt.MiddleButton) {
        if (root.toneActive) root.stopTone()
        else root.restartHelper()
      }
    }
  }

  Timer {
    id: helperRestartTimer
    interval: root.helperRestartDelayMs
    onTriggered: root.startHelper(root.helperRecoveryPending)
  }

  Process {
    id: helperProc
    running: false
    stdinEnabled: true
    command: root.helperCommand
    onStarted: {
      root.helperState = "starting"
      root.helperProcessStarted = true
      root.flushPendingCommands()
    }
    onExited: function(exitCode, exitStatus) { root.handleHelperExit(exitCode) }
    stdout: SplitParser {
      onRead: function(line) { root.handleHelperStdout(line) }
    }
    stderr: SplitParser {
      onRead: function(line) { root.handleHelperStderr(line) }
    }
  }
}
