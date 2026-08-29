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
  property string noteSpelling: "sharps"
  property string selectedPresetId: "guitar.standard"
  property int selectedReferenceMidiNumber: 69
  property string referencePlaybackMode: "single"
  property int selectedReferenceIntervalSemitones: 7
  property string selectedReferenceChordId: "major"
  property string popupLayoutMode: "compact"
  property bool highContrastMode: false
  property bool reducedMotionMode: false
  property var pendingCommandLines: []
  property string lastProtocolType: ""
  property string lastProtocolLine: ""
  property string lastStderrLine: ""
  property int lastExitCode: 0
  property var metronomeTapTimes: []

  readonly property int minimumReferenceMidiNumber: 12
  readonly property int maximumReferenceMidiNumber: 119
  readonly property real minimumReferenceAHz: 400.0
  readonly property real maximumReferenceAHz: 480.0
  readonly property int minimumMetronomeBpm: 20
  readonly property int maximumMetronomeBpm: 300
  readonly property int maximumReferenceIntervalSemitones: 24
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
  readonly property bool popupExpanded: popupLayoutMode === "expanded"
  readonly property bool shouldAnimateUi: !reducedMotionMode
  readonly property bool standardGuitarPresetSelected: selectedPresetId === "guitar.standard"
  readonly property int selectedReferencePitchClassIndex: ((selectedReferenceMidiNumber % 12) + 12) % 12
  readonly property int selectedReferenceOctave: Math.floor(selectedReferenceMidiNumber / 12) - 1
  readonly property var selectedPreset: presetById(selectedPresetId)
  readonly property var selectedPresetNotes: selectedPreset ? selectedPreset.notes : []
  readonly property string selectedPresetLabel: selectedPreset ? (selectedPreset.groupLabel + " | " + selectedPreset.label) : "Guitar | Standard"
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
    ? (metronomeMeterLabel + " | " + metronomeSubdivisionLabel + ". BPM, meter, and subdivision changes restart on beat one.")
    : ("Tap tempo, choose a common meter, and add up to 4x subdivisions. Accent stays on 1.")
  readonly property bool selectedReferenceToneActive: toneActive
    && sameNoteText(activeToneNote, selectedReferenceCommandNoteLabel)
    && sameIntegerArray(activeToneIntervalsSemitones, selectedReferenceIntervalsSemitones)
  readonly property string helperRecoveryStatusText: {
    if (!helperRecoveryPending) return ""
    return "Recovering the audio helper (attempt " + helperRecoveryAttempt + " of " + helperRecoveryMaxAttempts + "). " + helperRecoveryMessage
  }
  readonly property string pitchGuidanceText: {
    if (!pitchActive) return ""
    if (inTune) return "In tune"
    return detectedCents < 0 ? "Tune up" : "Tune down"
  }
  readonly property string stateBadgeText: {
    if (helperRecoveryPending) return "RECOVERING"
    if (helperState === "error" || runtimeErrorMessage !== "") return "ERROR"
    if (helperState === "inactive") return "OFF"
    if (helperState === "starting") return "STARTING"
    if (signalState === "no_signal") return "NO SIGNAL"
    if (pitchActive) return inTune ? "IN TUNE" : (detectedCents < 0 ? "TUNE UP" : "TUNE DOWN")
    if (toneActive) {
      if (activeToneSceneKind === "chord") return "CHORD"
      if (activeToneSceneKind === "interval") return "DRONE"
      return "REFERENCE"
    }
    if (metronomeActive) return "METRONOME"
    return "LISTENING"
  }
  readonly property string quickTuneHeadingText: standardGuitarPresetSelected ? "Standard guitar" : "Quick tune"
  readonly property string keyboardShortcutSummary: "Keys: 1-6 notes | Left/Right note | Alt+Up/Down octave | Shift+Left/Right BPM | D mode | [/] shape | M metro | Shift+M tap | Ctrl+M meter | Alt+M subdiv | P play/stop | X stop | T power | R restart | Esc close"
  readonly property bool opened: popupLoader.item ? popupLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: popupLoader.item ? popupLoader.item.popoutSwitchClosing === true : false
  readonly property string helperScriptPath: localPath("scripts/run-helper.sh")
  readonly property var helperCommand: [
    "bash",
    helperScriptPath,
    "--reference-a-hz",
    formatReferenceAForHelper(referenceAHz),
  ]
  readonly property string readoutTitleText: {
    if (helperRecoveryPending) return "..."
    if (pitchActive) return detectedNoteLabel
    if (toneActive) return activeToneSceneLabel
    if (metronomeActive) return metronomeBpm + " BPM"
    if (helperState === "error" || runtimeErrorMessage !== "") return "ERR"
    if (helperState === "starting") return "..."
    if (helperState === "inactive") return "OFF"
    return "--"
  }
  readonly property string readoutFooterText: {
    if (pitchActive) return formatSignedCents(detectedCents) + " | " + formatFrequency(detectedFrequencyHz) + " Hz"
    if (toneActive) return activeTonePlaybackTypeText + " | Root " + formatFrequency(activeToneFrequencyHz) + " Hz | A4 = " + formatReferenceA(referenceAHz)
    if (metronomeActive) return metronomeMeterLabel + " | " + metronomeSubdivisionLabel + " | " + metronomeBeatText
    if (helperRecoveryPending) return helperRecoveryStatusText
    if (helperState === "starting") return "Opening microphone and output..."
    if (helperState === "inactive") return "Tuner is off"
    if (helperState === "error") return "Restart the helper to recover"
    if (signalState === "no_signal") return "No signal. Play a note."
    return "Listening..."
  }
  readonly property string statusText: {
    if (helperRecoveryPending) return helperRecoveryStatusText
    if (helperState === "error") return helperError !== "" ? helperError : "The audio helper stopped unexpectedly."
    if (runtimeErrorMessage !== "") return runtimeErrorMessage
    if (helperState === "inactive") return "Open the tuner or turn it on to begin capture."
    if (helperState === "starting") return "Starting the audio helper..."
    if (pitchActive) return pitchGuidanceText + " | Confidence: " + Math.round(detectedConfidence * 100) + "%"
    if (toneActive && metronomeActive) return activeTonePlaybackTypeText + " and metronome are active."
    if (toneActive) return activeTonePlaybackTypeText + " is active."
    if (metronomeActive) return "Metronome is active at " + metronomeBpm + " BPM in " + metronomeMeterLabel + " with " + metronomeSubdivisionLabel + "."
    if (signalState === "no_signal") return "No signal. Play a steady note into the microphone."
    return "Listening for pitch..."
  }
  readonly property string detailText: {
    if (toneActive)
      return activeTonePlaybackTypeText + ": " + activeToneSceneLabel
        + (activeToneVoiceSummaryText !== "" ? (" | Voices: " + activeToneVoiceSummaryText) : "")
        + (metronomeActive ? (" | Metronome: " + metronomeSummaryText) : "")
        + " | Preset: " + selectedPresetLabel + " | A4 = " + formatReferenceA(referenceAHz)
    if (pitchActive)
      return "Detected pitch is matched against the nearest equal-tempered note at A4 = " + formatReferenceA(referenceAHz) + "."
        + (metronomeActive ? (" | Metronome: " + metronomeSummaryText) : "")
    if (metronomeActive)
      return "Metronome: " + metronomeSummaryText + " | Preset: " + selectedPresetLabel + " | A4 = " + formatReferenceA(referenceAHz)
    return "Preset: " + selectedPresetLabel + " | A4 = " + formatReferenceA(referenceAHz)
  }
  readonly property string buttonText: {
    if (helperRecoveryPending) return "..."
    if (helperState === "error" || runtimeErrorMessage !== "") return "ERR"
    if (helperState === "inactive") return "OFF"
    if (helperState === "starting") return "..."
    if (pitchActive) return vertical ? (detectedNoteLabel + (inTune ? "=" : "")) : (detectedNoteLabel + (inTune ? " =" : (" " + formatCompactCents(detectedCents))))
    if (toneActive) return activeToneSceneKind === "tone" ? activeToneNoteLabel : (vertical ? (activeToneNoteLabel + "+") : (activeToneNoteLabel + " +"))
    if (metronomeActive) return "M" + metronomeBpm
    if (signalState === "no_signal") return "SIG"
    return "ON"
  }
  readonly property string tooltipText: {
    var lines = ["Omatune"]

    if (helperRecoveryPending) lines.push("state: recovering")
    else if (helperState === "inactive") lines.push("state: off")
    else if (helperState === "starting") lines.push("state: starting")
    else if (helperState === "error") lines.push("state: error")
    else if (pitchActive) lines.push("state: pitch")
    else if (signalState === "no_signal") lines.push("state: no signal")
    else lines.push("state: listening")

    if (pitchActive) lines.push("pitch: " + detectedNoteLabel + "  " + formatSignedCents(detectedCents) + "  " + formatFrequency(detectedFrequencyHz) + " Hz")
    if (toneActive) lines.push("tone: " + activeToneSceneLabel + (activeToneVoiceSummaryText !== "" ? ("  " + activeToneVoiceSummaryText) : ""))
    if (metronomeActive) lines.push("metronome: " + metronomeSummaryText)
    lines.push("preset: " + selectedPresetLabel)
    lines.push("A4: " + formatReferenceA(referenceAHz))
    lines.push("spelling: " + noteSpelling)
    if (helperRecoveryPending) lines.push("recovery: attempt " + helperRecoveryAttempt + " of " + helperRecoveryMaxAttempts)
    if (helperError !== "") lines.push("helper error: " + helperError)
    if (runtimeErrorMessage !== "") lines.push("runtime error: " + runtimeErrorMessage)
    if (lastStderrLine !== "") lines.push("stderr: " + lastStderrLine)
    if (!helperProc.running && lastExitCode !== 0) lines.push("last exit code: " + lastExitCode)
    lines.push("keys: 1-6 quick notes | left/right note | alt+up/down octave | shift+left/right bpm | d mode | [/] shape | m metro | shift+m tap | ctrl+m meter | alt+m subdiv | p play/stop | x stop | t power | r restart | esc close")

    lines.push("left click: open tuner")
    lines.push("right click: turn tuner on or off")
    lines.push(toneActive ? "middle click: stop tone" : "middle click: restart helper")
    return lines.join("\n")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

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

  function formatCompactCents(value) {
    var rounded = roundedCents(value)
    return (rounded > 0 ? "+" : "") + rounded + "c"
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

  function normalizePopupLayoutMode(value) {
    return String(value || "") === "expanded" ? "expanded" : "compact"
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

  function persistedSettingsEntry() {
    var entry = { id: root.moduleName }
    var existingSettings = root.settings || ({})

    for (var key in existingSettings)
      if (key !== "id") entry[key] = existingSettings[key]

    entry.configVersion = settingsConfigVersion
    entry.referenceAHz = normalizeReferenceAHz(referenceAHz)
    entry.noteSpelling = normalizeNoteSpelling(noteSpelling)
    entry.selectedPresetId = selectedPresetId
    entry.selectedReferenceNote = selectedReferenceCommandNoteLabel
    entry.metronomeBpm = normalizeMetronomeBpm(metronomeBpm)
    entry.metronomeBeatsPerBar = normalizeMetronomeBeatsPerBar(metronomeBeatsPerBar, metronomeBeatUnit)
    entry.metronomeBeatUnit = normalizeMetronomeBeatUnit(metronomeBeatsPerBar, metronomeBeatUnit)
    entry.metronomeSubdivision = normalizeMetronomeSubdivision(metronomeSubdivision)
    entry.popupLayoutMode = normalizePopupLayoutMode(popupLayoutMode)
    entry.highContrastMode = !!highContrastMode
    entry.reducedMotionMode = !!reducedMotionMode
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
    var previousReferenceAHz = referenceAHz
    var previousMetronomeBpm = metronomeBpm
    var previousMetronomeBeatsPerBar = metronomeBeatsPerBar
    var previousMetronomeBeatUnit = metronomeBeatUnit
    var previousMetronomeSubdivision = metronomeSubdivision
    settingsHydrating = true
    referenceAHz = normalizeReferenceAHz(root.setting("referenceAHz", 440.0))
    noteSpelling = normalizeNoteSpelling(root.setting("noteSpelling", "sharps"))
    selectedPresetId = presetById(root.setting("selectedPresetId", "guitar.standard")).id
    metronomeBpm = normalizeMetronomeBpm(root.setting("metronomeBpm", defaultMetronomeBpm))
    var persistedMetronomePreset = metronomeMeterPresetByValues(
      root.setting("metronomeBeatsPerBar", defaultMetronomeBeatsPerBar),
      root.setting("metronomeBeatUnit", defaultMetronomeBeatUnit)
    )
    metronomeBeatsPerBar = persistedMetronomePreset.beatsPerBar
    metronomeBeatUnit = persistedMetronomePreset.beatUnit
    metronomeSubdivision = normalizeMetronomeSubdivision(root.setting("metronomeSubdivision", defaultMetronomeSubdivision))
    popupLayoutMode = normalizePopupLayoutMode(root.setting("popupLayoutMode", "compact"))
    highContrastMode = normalizeBooleanSetting(root.setting("highContrastMode", false), false)
    reducedMotionMode = normalizeBooleanSetting(root.setting("reducedMotionMode", false), false)

    var persistedReferenceNote = String(root.setting("selectedReferenceNote", "A4") || "A4")
    var selectedMidiNumber = parseNoteMidiNumber(persistedReferenceNote)
    selectedReferenceMidiNumber = selectedMidiNumber === null ? 69 : selectedMidiNumber
    settingsHydrating = false

    if (Math.abs(referenceAHz - previousReferenceAHz) >= 0.0001
        && (helperWanted || helperProcessStarted || helperProc.running)) {
      queueHelperCommand({ type: "set_reference_a", frequency_hz: referenceAHz })
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

  function setPopupLayoutMode(value) {
    var next = normalizePopupLayoutMode(value)
    if (next === popupLayoutMode) return

    popupLayoutMode = next
    persistWidgetSettings()
  }

  function togglePopupLayoutMode() {
    setPopupLayoutMode(popupExpanded ? "compact" : "expanded")
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
    var next = Math.max(minimumReferenceMidiNumber, Math.min(maximumReferenceMidiNumber, Math.round(finiteNumber(midiNumber, 69))))
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
    else playSelectedTone()
  }

  function playReferenceNoteString(noteText) {
    if (!applySelectedReferenceFromNote(noteText)) return
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
