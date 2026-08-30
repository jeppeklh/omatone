import Quickshell
import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "jeppeklh.omatune"

  BarWidgetModel {
    id: widgetModel
    hostWidget: root
  }

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
  property bool detectedConfidenceAvailable: false
  property var detectedPitchHistoryCents: []
  property real detectedPitchHistorySpanCents: 0
  property bool detectedPitchHeld: false
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
  property string selectedTemperamentId: "equal.12tet"
  property int selectedReferenceMidiNumber: 69
  property string referencePlaybackMode: "single"
  property int selectedReferenceIntervalSemitones: 7
  property string selectedReferenceChordId: "major"
  property string selectedReferenceSceneId: "close"
  property string selectedReferenceWaveformId: "warm"
  property string activeToneSceneId: "close"
  property string activeToneWaveformId: "warm"
  property bool highContrastMode: false
  property bool reducedMotionMode: false
  property bool analysisViewsEnabled: false
  property var pendingCommandLines: []
  property var pendingToneSelectionSyncFlags: []
  property bool activeToneSyncsReferenceSelection: true
  property string lastProtocolType: ""
  property string lastProtocolLine: ""
  property string lastStderrLine: ""
  property int lastExitCode: 0
  property var metronomeTapTimes: []
  property var favoriteQuickSwitches: []
  property var recentQuickSwitches: []
  property var importedTemperamentPacks: []
  property var importedPresetPacks: []
  property var builtInTemperamentPacks: []
  property var builtInPresetPacks: []
  property string tuningLibraryLoadError: ""
  property bool contentPackTransferBusy: false
  property string contentPackTransferStatusText: ""
  property bool contentPackTransferStatusError: false
  property string pendingContentPackJson: ""
  property string contentPackToolStdout: ""
  property string contentPackToolStderr: ""
  property string tuningLibraryStdout: ""
  property string tuningLibraryStderr: ""
  property bool midiInputEnabled: false
  property string midiInputPortName: ""
  property var availableMidiInputPorts: []
  property bool midiInputPortsLoaded: false
  property string midiInputPortsLoadError: ""
  property string midiInputPortsStdout: ""
  property string midiInputPortsStderr: ""
  property string midiInputListenerExpectedPortName: ""
  property bool midiInputListenerRestartPending: false
  property string midiInputListenerLastStderr: ""
  property string midiInputListenerError: ""
  property string lastExternalControlSource: ""
  property string lastExternalControlSummary: ""
  property string lastExternalControlError: ""

  readonly property int minimumReferenceMidiNumber: 12
  readonly property int maximumReferenceMidiNumber: 119
  readonly property real minimumReferenceAHz: 400.0
  readonly property real maximumReferenceAHz: 480.0
  readonly property int minimumTranspositionSemitones: -12
  readonly property int maximumTranspositionSemitones: 12
  readonly property int minimumMetronomeBpm: 20
  readonly property int maximumMetronomeBpm: 300
  readonly property int maximumReferenceIntervalSemitones: 24
  readonly property int maximumPitchAnalysisHistoryPoints: 12
  readonly property int maximumFavoriteQuickSwitches: 6
  readonly property int maximumRecentQuickSwitches: 6
  readonly property int settingsConfigVersion: 6
  readonly property int helperRecoveryMaxAttempts: 5
  readonly property int defaultMetronomeBpm: 100
  readonly property int defaultMetronomeBeatsPerBar: 4
  readonly property int defaultMetronomeBeatUnit: 4
  readonly property int defaultMetronomeSubdivision: 1
  readonly property int metronomeTapResetMs: 2000
  readonly property int defaultReferenceIntervalSemitones: 7
  readonly property string defaultReferenceChordId: "major"
  readonly property string defaultReferenceSceneId: "close"
  readonly property string defaultReferenceWaveformId: "warm"
  readonly property string defaultPresetId: "guitar.standard"
  readonly property string defaultTemperamentId: "equal.12tet"
  readonly property var metronomeMeterPresets: widgetModel.metronomeMeterPresets
  readonly property var metronomeSubdivisionPresets: widgetModel.metronomeSubdivisionPresets
  readonly property var pitchClasses: widgetModel.pitchClasses
  readonly property var transpositionPresets: widgetModel.transpositionPresets
  readonly property var referencePlaybackModes: widgetModel.referencePlaybackModes
  readonly property var referenceScenePresets: widgetModel.referenceScenePresets
  readonly property var referenceWaveformPresets: widgetModel.referenceWaveformPresets
  readonly property var referenceIntervalPresets: widgetModel.referenceIntervalPresets
  readonly property var referenceChordPresets: widgetModel.referenceChordPresets
  readonly property var defaultTemperamentOffsetsCents: widgetModel.defaultTemperamentOffsetsCents
  readonly property var fallbackTemperament: widgetModel.fallbackTemperament
  readonly property var fallbackPreset: widgetModel.fallbackPreset
  readonly property var allTemperamentPacks: widgetModel.allTemperamentPacks
  readonly property var allPresetPacks: widgetModel.allPresetPacks
  readonly property var temperamentPackSections: widgetModel.temperamentPackSections
  readonly property var tuningPresetGroups: widgetModel.tuningPresetGroups
  readonly property bool pitchActive: signalState === "pitch"
  readonly property bool hasDetectedPitchHistory: detectedPitchHistoryCents.length > 0
  readonly property bool toneActive: activeToneNote !== ""
  readonly property bool inTune: pitchActive && Math.abs(detectedCents) <= 5
  readonly property bool hasAlert: helperRecoveryPending || helperState === "error" || runtimeErrorMessage !== ""
  readonly property bool shouldAnimateUi: !reducedMotionMode
  readonly property bool transpositionActive: transpositionSemitones !== 0
  readonly property bool standardGuitarPresetSelected: selectedPreset.id === defaultPresetId
  readonly property int minimumDisplayedReferenceMidiNumber: minimumDisplayedReferenceMidiNumberForTransposition(transpositionSemitones)
  readonly property int maximumDisplayedReferenceMidiNumber: maximumDisplayedReferenceMidiNumberForTransposition(transpositionSemitones)
  readonly property int selectedReferencePitchClassIndex: ((selectedReferenceMidiNumber % 12) + 12) % 12
  readonly property int selectedReferenceOctave: Math.floor(selectedReferenceMidiNumber / 12) - 1
  readonly property var selectedPreset: widgetModel.selectedPreset
  readonly property var selectedPresetTargets: widgetModel.selectedPresetTargets
  readonly property var selectedPresetNotes: widgetModel.selectedPresetNotes
  readonly property string selectedPresetLabel: selectedPreset.groupLabel + " | " + selectedPreset.label
  readonly property var selectedTemperament: widgetModel.selectedTemperament
  readonly property string selectedTemperamentLabelText: String(selectedTemperament.label || fallbackTemperament.label)
  readonly property string selectedTemperamentDescription: String(selectedTemperament.description || "")
  readonly property var selectedTemperamentOffsetsCents: widgetModel.selectedTemperamentOffsetsCents
  readonly property string selectedTemperamentFingerprint: widgetModel.selectedTemperamentFingerprint
  readonly property bool temperamentActive: selectedTemperament.id !== defaultTemperamentId
  readonly property bool currentQuickSwitchFavorite: indexOfQuickSwitchScene(favoriteQuickSwitches, currentQuickSwitchScene()) >= 0
  readonly property var visibleRecentQuickSwitches: widgetModel.visibleRecentQuickSwitches
  readonly property bool hasQuickSwitches: favoriteQuickSwitches.length > 0 || visibleRecentQuickSwitches.length > 0
  readonly property bool midiInputConfigured: midiInputEnabled && normalizeMidiInputPortName(midiInputPortName) !== ""
  readonly property string transpositionLabelText: formatTranspositionLabel(transpositionSemitones)
  readonly property string selectedReferenceCommandNoteLabel: formatMidiNote(selectedReferenceMidiNumber, "sharps")
  readonly property string selectedReferenceNoteLabel: formatMidiNote(selectedReferenceMidiNumber, noteSpelling)
  readonly property int selectedReferenceIntervalPresetIndex: widgetModel.selectedReferenceIntervalPresetIndex
  readonly property int selectedReferenceChordPresetIndex: widgetModel.selectedReferenceChordPresetIndex
  readonly property int selectedReferenceWaveformPresetIndex: widgetModel.selectedReferenceWaveformPresetIndex
  readonly property var selectedReferenceIntervalsSemitones: widgetModel.selectedReferenceIntervalsSemitones
  readonly property string detectedNoteLabel: displayNoteLabel(detectedNote)
  readonly property string activeToneNoteLabel: displayNoteLabel(activeToneNote)
  readonly property string selectedReferenceVoicingLabel: referenceScenePresetLabel(selectedReferenceSceneId)
  readonly property string selectedReferenceSceneLabel: formatReferenceSceneLabel(selectedReferenceNoteLabel, selectedReferenceIntervalsSemitones)
  readonly property string selectedReferencePlaybackLabel: formatReferencePlaybackLabel(selectedReferenceSceneLabel, selectedReferenceSceneId)
  readonly property string selectedReferenceWaveformLabel: referenceWaveformPresetLabel(selectedReferenceWaveformId)
  readonly property string selectedReferenceToneSummaryLabel: formatReferenceToneSummaryLabel(
    selectedReferenceSceneLabel,
    selectedReferenceSceneId,
    selectedReferenceWaveformId
  )
  readonly property var selectedReferencePreviewVoiceLabels: widgetModel.selectedReferencePreviewVoiceLabels
  readonly property bool activeToneIsSingleNote: toneActive
    && activeToneIntervalsSemitones.length === 0
    && normalizeSelectedReferenceSceneId(activeToneSceneId) === defaultReferenceSceneId
  readonly property bool activeToneHasIntervals: activeToneIntervalsSemitones.length > 0
  readonly property string activeToneVoicingLabel: referenceScenePresetLabel(activeToneSceneId)
  readonly property string activeToneWaveformLabel: referenceWaveformPresetLabel(activeToneWaveformId)
  readonly property string activeToneSceneKind: {
    if (!toneActive) return ""
    if (activeToneIntervalsSemitones.length > 1) return "chord"
    if (activeToneIntervalsSemitones.length === 1) return "interval"
    return "tone"
  }
  readonly property string activeTonePlaybackTypeText: {
    if (activeToneSceneKind === "chord") return "Chord"
    if (activeToneSceneKind === "interval") return "Interval"
    return "Single"
  }
  readonly property string activeToneSceneLabel: formatReferenceSceneLabel(activeToneNoteLabel, activeToneIntervalsSemitones)
  readonly property string activeTonePlaybackLabel: formatReferencePlaybackLabel(activeToneSceneLabel, activeToneSceneId)
  readonly property string activeToneSummaryLabel: formatReferenceToneSummaryLabel(
    activeToneSceneLabel,
    activeToneSceneId,
    activeToneWaveformId
  )
  readonly property string activeToneVoiceSummaryText: formatToneVoiceSummary(activeToneVoices)
  readonly property int selectedMetronomeMeterPresetIndex: widgetModel.selectedMetronomeMeterPresetIndex
  readonly property string metronomeMeterLabel: metronomeMeterPresets[selectedMetronomeMeterPresetIndex].label
  readonly property int selectedMetronomeSubdivisionPresetIndex: widgetModel.selectedMetronomeSubdivisionPresetIndex
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
    && normalizeSelectedReferenceSceneId(activeToneSceneId) === normalizeSelectedReferenceSceneId(selectedReferenceSceneId)
    && normalizeSelectedReferenceWaveformId(activeToneWaveformId) === normalizeSelectedReferenceWaveformId(selectedReferenceWaveformId)
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
  readonly property string pitchAnalysisSummaryText: {
    if (!analysisViewsEnabled) return ""
    if (!pitchActive || !hasDetectedPitchHistory)
      return "Play a steady note to populate the recent helper trace."

    var parts = [detectedPitchHeld ? "Lock held" : "Live lock"]
    parts.push("Spread " + formatPitchHistorySpan(detectedPitchHistorySpanCents))
    parts.push(detectedConfidenceAvailable ? ("Confidence " + formatConfidencePercent(detectedConfidence)) : "Confidence --")
    return parts.join(" | ")
  }
  readonly property string barIconText: "\u266A"
  readonly property string stateBadgeText: {
    if (helperRecoveryPending) return "Recovering"
    if (helperState === "error" || runtimeErrorMessage !== "") return "Error"
    if (helperState === "inactive") return "Off"
    if (helperState === "starting") return "Starting"
    if (pitchActive) return inTune ? "In tune" : (detectedCents < 0 ? "Tune up" : "Tune down")
    if (toneActive) return activeTonePlaybackTypeText
    if (metronomeActive) return "Metronome"
    if (signalState === "no_signal") return "No signal"
    return "Listening"
  }
  readonly property string quickTuneHeadingText: standardGuitarPresetSelected ? "Standard guitar" : "Quick tune"
  readonly property string keyboardShortcutSummary: "Keys: 1-8 notes | Ctrl+1-6 favorites | F favorite | Left/Right note | Alt+Up/Down octave | Shift+Left/Right BPM | D mode | [/] shape | M metro | Shift+M tap | Ctrl+M meter | Alt+M subdiv | P play/stop | X stop | T power | R restart | Esc close"
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
    "--temperament-offsets-cents",
    formatTemperamentOffsetsForHelper(selectedTemperamentOffsetsCents),
  ]
  readonly property var tuningLibraryCommand: ["bash", helperScriptPath, "--dump-tuning-library"]
  readonly property var contentPackToolCommand: ["bash", helperScriptPath, "--normalize-content-pack", pendingContentPackJson]
  readonly property var midiInputPortsCommand: ["bash", helperScriptPath, "--list-midi-inputs"]
  readonly property var midiInputListenCommand: ["bash", helperScriptPath, "--listen-midi-input", normalizeMidiInputPortName(midiInputPortName)]
  readonly property string externalControlStatusText: {
    if (midiInputListenerError !== "") return midiInputListenerError
    if (midiInputConfigured && midiListenerProc.running) return "MIDI input active on " + midiInputPortName + "."
    if (lastExternalControlError !== "")
      return (lastExternalControlSource !== "" ? (lastExternalControlSource + ": ") : "") + lastExternalControlError
    if (lastExternalControlSummary !== "")
      return (lastExternalControlSource !== "" ? (lastExternalControlSource + ": ") : "") + lastExternalControlSummary
    if (midiInputEnabled && !midiInputConfigured) {
      if (midiInputPortsLoadError !== "") return midiInputPortsLoadError
      if (midiInputPortsLoaded && availableMidiInputPorts.length === 0) return "No MIDI input ports found."
      return "Choose a MIDI input port to enable note control."
    }
    if (midiInputPortsLoadError !== "") return midiInputPortsLoadError
    return "IPC target: " + moduleName
  }
  readonly property string midiInputStatusText: {
    if (midiInputListenerError !== "") return midiInputListenerError
    if (midiInputConfigured && midiListenerProc.running)
      return "Listening on " + midiInputPortName + ". Note-on events select the concert-pitch root and retune active playback."
    if (midiInputEnabled && !midiInputConfigured) {
      if (midiInputPortsLoadError !== "") return midiInputPortsLoadError
      if (midiInputPortsLoaded && availableMidiInputPorts.length === 0) return "No MIDI input ports found."
      return "Choose a MIDI input port."
    }
    if (midiInputPortsLoadError !== "") return midiInputPortsLoadError
    if (midiInputPortsLoaded && availableMidiInputPorts.length === 0) return "No MIDI input ports found."
    return "Off. Enable one MIDI input to drive the current reference selection."
  }
  readonly property string readoutTitleText: {
    if (helperRecoveryPending) return "Recovering audio"
    if (pitchActive) return detectedNoteLabel
    if (toneActive) return activeTonePlaybackLabel
    if (metronomeActive) return metronomeBpm + " BPM"
    if (helperState === "error" || runtimeErrorMessage !== "") return "Check audio"
    if (helperState === "starting") return "Opening audio"
    if (helperState === "inactive") return "Tuner off"
    if (signalState === "no_signal") return "Play a note"
    return "Ready"
  }
  readonly property string readoutFooterText: {
    if (pitchActive) return formatSignedCents(detectedCents) + " | " + formatFrequency(detectedFrequencyHz) + " Hz"
    if (toneActive)
      return "Root " + formatFrequency(activeToneFrequencyHz) + " Hz | " + activeToneVoicingLabel + " | " + activeToneWaveformLabel + " | A4 = " + formatReferenceA(referenceAHz)
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
    if (toneActive && metronomeActive) return "Tone and metronome active."
    if (toneActive) return activeTonePlaybackTypeText + " active."
    if (metronomeActive) return "Metronome active at " + metronomeBpm + " BPM."
    if (signalState === "no_signal") return "Play a steady note."
    return "Listening for pitch."
  }
  readonly property string detailText: {
    if (toneActive)
      return activeToneSummaryLabel
        + (metronomeActive ? (" | " + metronomeBpm + " BPM") : "")
        + (transpositionActive ? (" | " + transpositionLabelText) : "")
        + (temperamentActive ? (" | " + selectedTemperamentLabelText) : "")
        + " | " + selectedPresetLabel
    if (pitchActive)
      return selectedPresetLabel
        + (transpositionActive ? (" | " + transpositionLabelText) : "")
        + (temperamentActive ? (" | " + selectedTemperamentLabelText) : "")
        + (metronomeActive ? (" | " + metronomeBpm + " BPM") : "")
        + " | A4 = " + formatReferenceA(referenceAHz)
    if (metronomeActive)
      return metronomeBpm + " BPM | " + metronomeMeterLabel + " | " + metronomeSubdivisionLabel
        + (transpositionActive ? (" | " + transpositionLabelText) : "")
        + (temperamentActive ? (" | " + selectedTemperamentLabelText) : "")
        + " | " + selectedPresetLabel
    return selectedPresetLabel
      + (transpositionActive ? (" | " + transpositionLabelText) : "")
      + (temperamentActive ? (" | " + selectedTemperamentLabelText) : "")
      + " | A4 = " + formatReferenceA(referenceAHz)
  }
  readonly property string buttonText: {
    return barIconText
  }
  readonly property string tooltipText: {
    if (helperRecoveryPending) return "Omatune | Recovering audio"
    if (helperState === "error" || runtimeErrorMessage !== "") return "Omatune | Audio error"
    if (toneActive && metronomeActive) return "Omatune | Tone and metronome active"
    if (toneActive) return "Omatune | Tone active"
    if (metronomeActive) return "Omatune | Metronome active"
    if (helperState === "starting") return "Omatune | Starting audio"
    if (helperState === "active") return "Omatune | Listening"
    return "Omatune"
  }

  implicitWidth: Math.max(button.implicitWidth, buttonSizer.implicitWidth)
  implicitHeight: Math.max(button.implicitHeight, buttonSizer.implicitHeight)

  function localPath(relativePath) {
    return decodeURIComponent(String(Qt.resolvedUrl(relativePath)).replace(/^file:\/\//, ""))
  }

  function parseJsonObject(raw) { return widgetModel.parseJsonObject(raw) }
  function finiteNumber(value, fallback) { return widgetModel.finiteNumber(value, fallback) }
  function clampNumber(value, min, max, fallback) { return widgetModel.clampNumber(value, min, max, fallback) }
  function roundedCents(value) { return widgetModel.roundedCents(value) }
  function formatSignedCents(value) { return widgetModel.formatSignedCents(value) }
  function formatFrequency(value) { return widgetModel.formatFrequency(value) }
  function formatConfidencePercent(value) { return widgetModel.formatConfidencePercent(value) }
  function formatPitchHistorySpan(value) { return widgetModel.formatPitchHistorySpan(value) }
  function formatReferenceA(value) { return widgetModel.formatReferenceA(value) }
  function formatReferenceAForHelper(value) { return widgetModel.formatReferenceAForHelper(value) }
  function normalizeReferenceAHz(value) { return widgetModel.normalizeReferenceAHz(value) }
  function normalizeTranspositionSemitones(value) { return widgetModel.normalizeTranspositionSemitones(value) }
  function minimumDisplayedReferenceMidiNumberForTransposition(value) { return widgetModel.minimumDisplayedReferenceMidiNumberForTransposition(value) }
  function maximumDisplayedReferenceMidiNumberForTransposition(value) { return widgetModel.maximumDisplayedReferenceMidiNumberForTransposition(value) }
  function normalizeDisplayedReferenceMidiNumberForTransposition(midiNumber, transposition) { return widgetModel.normalizeDisplayedReferenceMidiNumberForTransposition(midiNumber, transposition) }
  function shiftedMidiNumber(midiNumber, semitoneOffset) { return widgetModel.shiftedMidiNumber(midiNumber, semitoneOffset) }
  function transposeNoteText(noteText, semitoneOffset) { return widgetModel.transposeNoteText(noteText, semitoneOffset) }
  function roundToFourDecimals(value) { return widgetModel.roundToFourDecimals(value) }
  function normalizeStableId(value, fallback) { return widgetModel.normalizeStableId(value, fallback) }
  function normalizeMidiInputPortName(value) { return widgetModel.normalizeMidiInputPortName(value) }
  function normalizedTemperamentOffsets(values) { return widgetModel.normalizedTemperamentOffsets(values) }
  function temperamentFingerprint(offsets) { return widgetModel.temperamentFingerprint(offsets) }
  function formatTemperamentOffsetsForHelper(offsets) { return widgetModel.formatTemperamentOffsetsForHelper(offsets) }
  function filteredContentPackList(values, expectedKind, source) { return widgetModel.filteredContentPackList(values, expectedKind, source) }
  function taggedContentPacks(builtInPacks, importedPacks, expectedKind) { return widgetModel.taggedContentPacks(builtInPacks, importedPacks, expectedKind) }
  function presetGroupsForDisplay(packs) { return widgetModel.presetGroupsForDisplay(packs) }
  function temperamentPackSectionsForDisplay(packs) { return widgetModel.temperamentPackSectionsForDisplay(packs) }
  function transposePresetTargets(targets, semitoneOffset) { return widgetModel.transposePresetTargets(targets, semitoneOffset) }
  function selectedPresetTargetNotes(targets) { return widgetModel.selectedPresetTargetNotes(targets) }
  function presetTargetDisplayLabel(target) { return widgetModel.presetTargetDisplayLabel(target) }
  function transpositionPresetBySemitones(value) { return widgetModel.transpositionPresetBySemitones(value) }
  function formatSignedSemitoneOffset(value) { return widgetModel.formatSignedSemitoneOffset(value) }
  function formatTranspositionLabel(value) { return widgetModel.formatTranspositionLabel(value) }
  function normalizeMetronomeBpm(value) { return widgetModel.normalizeMetronomeBpm(value) }
  function indexOfMetronomeMeterPreset(beatsPerBar, beatUnit) { return widgetModel.indexOfMetronomeMeterPreset(beatsPerBar, beatUnit) }
  function metronomeMeterPresetByValues(beatsPerBar, beatUnit) { return widgetModel.metronomeMeterPresetByValues(beatsPerBar, beatUnit) }
  function normalizeMetronomeBeatsPerBar(value, beatUnit) { return widgetModel.normalizeMetronomeBeatsPerBar(value, beatUnit) }
  function normalizeMetronomeBeatUnit(beatsPerBar, value) { return widgetModel.normalizeMetronomeBeatUnit(beatsPerBar, value) }
  function indexOfMetronomeSubdivisionPreset(value) { return widgetModel.indexOfMetronomeSubdivisionPreset(value) }
  function normalizeMetronomeSubdivision(value) { return widgetModel.normalizeMetronomeSubdivision(value) }
  function normalizeNoteSpelling(value) { return widgetModel.normalizeNoteSpelling(value) }
  function normalizeReferencePlaybackMode(value) { return widgetModel.normalizeReferencePlaybackMode(value) }
  function parseExactIntegerField(commandObject, commandType, fieldName) { return widgetModel.parseExactIntegerField(commandObject, commandType, fieldName) }
  function exactReferencePlaybackMode(value) { return widgetModel.exactReferencePlaybackMode(value) }
  function normalizeReferenceSceneStableId(value) { return widgetModel.normalizeReferenceSceneStableId(value) }
  function exactReferenceSceneId(value) { return widgetModel.exactReferenceSceneId(value) }
  function exactReferenceWaveformId(value) { return widgetModel.exactReferenceWaveformId(value) }
  function exactReferenceIntervalSemitones(value) { return widgetModel.exactReferenceIntervalSemitones(value) }
  function exactReferenceChordId(value) { return widgetModel.exactReferenceChordId(value) }
  function supportedReferenceIntervalSemitoneListText() { return widgetModel.supportedReferenceIntervalSemitoneListText() }
  function supportedReferenceChordIdListText() { return widgetModel.supportedReferenceChordIdListText() }
  function exactMetronomeMeter(beatsPerBar, beatUnit) { return widgetModel.exactMetronomeMeter(beatsPerBar, beatUnit) }
  function indexOfReferenceScenePreset(value) { return widgetModel.indexOfReferenceScenePreset(value) }
  function referenceScenePresetById(value) { return widgetModel.referenceScenePresetById(value) }
  function normalizeSelectedReferenceSceneId(value) { return widgetModel.normalizeSelectedReferenceSceneId(value) }
  function referenceScenePresetLabel(value) { return widgetModel.referenceScenePresetLabel(value) }
  function referenceScenePresetEnabled(sceneId) { return widgetModel.referenceScenePresetEnabled(sceneId) }
  function referenceScenePreviewSummary(sceneId) { return widgetModel.referenceScenePreviewSummary(sceneId) }
  function indexOfReferenceWaveformPreset(value) { return widgetModel.indexOfReferenceWaveformPreset(value) }
  function referenceWaveformPresetById(value) { return widgetModel.referenceWaveformPresetById(value) }
  function normalizeSelectedReferenceWaveformId(value) { return widgetModel.normalizeSelectedReferenceWaveformId(value) }
  function referenceWaveformPresetLabel(value) { return widgetModel.referenceWaveformPresetLabel(value) }
  function indexOfReferenceIntervalPreset(value) { return widgetModel.indexOfReferenceIntervalPreset(value) }
  function intervalPresetBySemitones(value) { return widgetModel.intervalPresetBySemitones(value) }
  function normalizeSelectedReferenceIntervalSemitones(value) { return widgetModel.normalizeSelectedReferenceIntervalSemitones(value) }
  function indexOfReferenceChordPreset(value) { return widgetModel.indexOfReferenceChordPreset(value) }
  function chordPresetById(value) { return widgetModel.chordPresetById(value) }
  function normalizeSelectedReferenceChordId(value) { return widgetModel.normalizeSelectedReferenceChordId(value) }
  function referenceSelectionIntervals(playbackMode, intervalSemitones, chordId) { return widgetModel.referenceSelectionIntervals(playbackMode, intervalSemitones, chordId) }
  function generatedReferenceVoiceMidiNumbers(displayedMidiNumber, transposition, intervals, sceneId) { return widgetModel.generatedReferenceVoiceMidiNumbers(displayedMidiNumber, transposition, intervals, sceneId) }
  function referenceSceneIsValid(displayedMidiNumber, transposition, intervals, sceneId) { return widgetModel.referenceSceneIsValid(displayedMidiNumber, transposition, intervals, sceneId) }
  function normalizedReferenceSelection(displayedMidiNumber, transposition, playbackMode, sceneId, intervalSemitones, chordId, waveformId) { return widgetModel.normalizedReferenceSelection(displayedMidiNumber, transposition, playbackMode, sceneId, intervalSemitones, chordId, waveformId) }
  function applyReferenceSelection(selection) { return widgetModel.applyReferenceSelection(selection) }
  function sameReferenceSelection(selection) { return widgetModel.sameReferenceSelection(selection) }
  function activeToneValidAcrossTranspositionChange(previousTransposition, nextTransposition) { return widgetModel.activeToneValidAcrossTranspositionChange(previousTransposition, nextTransposition) }

  function queueTranspositionUpdate(previousTransposition, nextTransposition, replaySelectedTone, activeToneAlreadyStopping) {
    if (!(helperWanted || helperProcessStarted || helperProc.running)) return

    var normalizedNextTransposition = normalizeTranspositionSemitones(nextTransposition)
    if (!activeToneAlreadyStopping && toneActive && !activeToneValidAcrossTranspositionChange(previousTransposition, normalizedNextTransposition))
      stopTone()

    queueHelperCommand({ type: "set_transposition", semitones: normalizedNextTransposition })
    if (replaySelectedTone) playSelectedTone()
  }

  function normalizeProtocolIntervalArray(values) { return widgetModel.normalizeProtocolIntervalArray(values) }
  function sameIntegerArray(left, right) { return widgetModel.sameIntegerArray(left, right) }
  function chordPresetByIntervals(intervals) { return widgetModel.chordPresetByIntervals(intervals) }
  function playbackModeForIntervals(intervals) { return widgetModel.playbackModeForIntervals(intervals) }
  function intervalLabelForSemitones(value) { return widgetModel.intervalLabelForSemitones(value) }
  function intervalListLabel(intervals) { return widgetModel.intervalListLabel(intervals) }
  function formatReferenceSceneLabel(rootNoteLabel, intervals) { return widgetModel.formatReferenceSceneLabel(rootNoteLabel, intervals) }
  function formatReferencePlaybackLabel(sceneLabel, sceneId) { return widgetModel.formatReferencePlaybackLabel(sceneLabel, sceneId) }
  function formatReferenceToneSummaryLabel(sceneLabel, sceneId, waveformId) { return widgetModel.formatReferenceToneSummaryLabel(sceneLabel, sceneId, waveformId) }
  function formatToneVoiceSummary(voices) { return widgetModel.formatToneVoiceSummary(voices) }
  function previewReferenceVoiceLabels(displayedMidiNumber, transposition, intervals, sceneId) { return widgetModel.previewReferenceVoiceLabels(displayedMidiNumber, transposition, intervals, sceneId) }
  function formatVoicePreviewSummary(labels) { return widgetModel.formatVoicePreviewSummary(labels) }
  function normalizeToneVoices(voices, fallbackNote, fallbackFrequencyHz) { return widgetModel.normalizeToneVoices(voices, fallbackNote, fallbackFrequencyHz) }
  function normalizePitchHistoryCents(values) { return widgetModel.normalizePitchHistoryCents(values) }
  function normalizeBooleanSetting(value, fallback) { return widgetModel.normalizeBooleanSetting(value, fallback) }
  function noteBasePitchClass(letter) { return widgetModel.noteBasePitchClass(letter) }
  function parseNoteMidiNumber(noteText) { return widgetModel.parseNoteMidiNumber(noteText) }
  function formatMidiNote(midiNumber, spelling) { return widgetModel.formatMidiNote(midiNumber, spelling) }
  function displayNoteLabel(noteText) { return widgetModel.displayNoteLabel(noteText) }
  function sameNoteText(left, right) { return widgetModel.sameNoteText(left, right) }
  function temperamentById(temperamentId) { return widgetModel.temperamentById(temperamentId) }
  function presetById(presetId) { return widgetModel.presetById(presetId) }
  function presetPackByPresetId(presetId) { return widgetModel.presetPackByPresetId(presetId) }
  function temperamentPackByTemperamentId(temperamentId) { return widgetModel.temperamentPackByTemperamentId(temperamentId) }
  function isQuickSwitchSceneCandidate(value) { return widgetModel.isQuickSwitchSceneCandidate(value) }
  function normalizeQuickSwitchScene(value) { return widgetModel.normalizeQuickSwitchScene(value) }
  function currentQuickSwitchScene() { return widgetModel.currentQuickSwitchScene() }
  function quickSwitchSceneFingerprint(scene) { return widgetModel.quickSwitchSceneFingerprint(scene) }
  function quickSwitchReferenceStateFingerprint(scene) { return widgetModel.quickSwitchReferenceStateFingerprint(scene) }
  function sameQuickSwitchScene(left, right) {
    var leftFingerprint = quickSwitchSceneFingerprint(left)
    return leftFingerprint !== "" && leftFingerprint === quickSwitchSceneFingerprint(right)
  }
  function filteredQuickSwitchSceneList(existingScenes, excludedScene, limit) { return widgetModel.filteredQuickSwitchSceneList(existingScenes, excludedScene, limit) }
  function prependedQuickSwitchSceneList(existingScenes, scene, limit) { return widgetModel.prependedQuickSwitchSceneList(existingScenes, scene, limit) }
  function indexOfQuickSwitchScene(scenes, scene) { return widgetModel.indexOfQuickSwitchScene(scenes, scene) }
  function recentQuickSwitchesForDisplay() { return widgetModel.recentQuickSwitchesForDisplay() }
  function quickSwitchSceneIntervals(scene) { return widgetModel.quickSwitchSceneIntervals(scene) }
  function quickSwitchPresetSummary(scene) { return widgetModel.quickSwitchPresetSummary(scene) }
  function quickSwitchSceneLabel(scene) { return widgetModel.quickSwitchSceneLabel(scene) }
  function quickSwitchButtonText(scene) { return widgetModel.quickSwitchButtonText(scene) }

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
    var previousTranspositionSemitones = transpositionSemitones
    var metronomeChanged = metronomeBpm !== normalized.metronomeBpm
      || metronomeBeatsPerBar !== normalized.metronomeBeatsPerBar
      || metronomeBeatUnit !== normalized.metronomeBeatUnit
      || metronomeSubdivision !== normalized.metronomeSubdivision
    var transpositionChanged = transpositionSemitones !== normalized.transpositionSemitones
    var temperamentChanged = normalizeStableId(selectedTemperamentId, defaultTemperamentId)
      !== normalizeStableId(normalized.temperamentId, defaultTemperamentId)
    var helperActive = helperWanted || helperProcessStarted || helperProc.running
    var shouldReplaySelectedTone = currentReferenceState !== nextReferenceState && toneActive
    var referenceMidiNumber = parseNoteMidiNumber(normalized.referenceNote)

    settingsHydrating = true
    selectedPresetId = normalized.presetId
    selectedTemperamentId = normalized.temperamentId
    transpositionSemitones = normalized.transpositionSemitones
    selectedReferenceMidiNumber = normalizeDisplayedReferenceMidiNumberForTransposition(referenceMidiNumber === null ? 69 : referenceMidiNumber, normalized.transpositionSemitones)
    referencePlaybackMode = normalized.playbackMode
    selectedReferenceSceneId = normalized.sceneId
    selectedReferenceWaveformId = normalized.waveformId
    selectedReferenceIntervalSemitones = normalized.intervalSemitones
    selectedReferenceChordId = normalized.chordId
    metronomeBpm = normalized.metronomeBpm
    metronomeBeatsPerBar = normalized.metronomeBeatsPerBar
    metronomeBeatUnit = normalized.metronomeBeatUnit
    metronomeSubdivision = normalized.metronomeSubdivision
    recentQuickSwitches = prependedQuickSwitchSceneList(recentQuickSwitches, normalized, maximumRecentQuickSwitches)
    settingsHydrating = false
    persistWidgetSettings()

    if (shouldReplaySelectedTone && helperActive) stopTone()
    if (transpositionChanged && helperActive)
      queueTranspositionUpdate(previousTranspositionSemitones, transpositionSemitones, false, shouldReplaySelectedTone)
    if (temperamentChanged && helperActive)
      queueHelperCommand({ type: "set_temperament", offsets_cents: selectedTemperamentOffsetsCents.slice(0) })
    if (shouldReplaySelectedTone && helperActive) playSelectedTone()
    if (metronomeChanged && metronomeActive && helperActive)
      queueHelperCommand(metronomeStartCommand())

    return true
  }

  function applyFavoriteQuickSwitchAt(index) {
    var numeric = Math.round(finiteNumber(index, -1))
    if (numeric < 0 || numeric >= favoriteQuickSwitches.length) return false
    return applyQuickSwitchScene(favoriteQuickSwitches[numeric])
  }

  function normalizedSettingsObject(value) { return widgetModel.normalizedSettingsObject(value) }
  function currentNormalizedSettingsObject() { return widgetModel.currentNormalizedSettingsObject() }

  function exportedConfigurationJson() {
    return JSON.stringify(currentNormalizedSettingsObject(), null, 2)
  }

  function importedSettingsConfigVersion(settingsObject) { return widgetModel.importedSettingsConfigVersion(settingsObject) }

  function applyNormalizedSettings(settingsObject, persistChanges) {
    var settings = settingsObject && typeof settingsObject === "object"
      ? settingsObject
      : currentNormalizedSettingsObject()
    var shouldPersist = persistChanges !== false
    var previousReferenceAHz = referenceAHz
    var previousTranspositionSemitones = transpositionSemitones
    var previousTemperamentId = selectedTemperamentId
    var previousMetronomeBpm = metronomeBpm
    var previousMetronomeBeatsPerBar = metronomeBeatsPerBar
    var previousMetronomeBeatUnit = metronomeBeatUnit
    var previousMetronomeSubdivision = metronomeSubdivision
    var previousMidiInputEnabled = midiInputEnabled
    var previousMidiInputPortName = normalizeMidiInputPortName(midiInputPortName)
    var previousReferenceState = quickSwitchReferenceStateFingerprint(currentQuickSwitchScene())
    var selectedMidiNumber = parseNoteMidiNumber(settings.selectedReferenceNote)

    settingsHydrating = true
    referenceAHz = settings.referenceAHz
    transpositionSemitones = settings.transpositionSemitones
    noteSpelling = settings.noteSpelling
    selectedPresetId = settings.selectedPresetId
    selectedTemperamentId = settings.selectedTemperamentId
    referencePlaybackMode = settings.referencePlaybackMode
    selectedReferenceSceneId = settings.referenceSceneId
    selectedReferenceWaveformId = settings.referenceWaveformId
    selectedReferenceIntervalSemitones = settings.referenceIntervalSemitones
    selectedReferenceChordId = settings.referenceChordId
    metronomeBpm = settings.metronomeBpm
    metronomeBeatsPerBar = settings.metronomeBeatsPerBar
    metronomeBeatUnit = settings.metronomeBeatUnit
    metronomeSubdivision = settings.metronomeSubdivision
    midiInputEnabled = settings.midiInputEnabled
    midiInputPortName = settings.midiInputPortName
    highContrastMode = settings.highContrastMode
    reducedMotionMode = settings.reducedMotionMode
    analysisViewsEnabled = settings.analysisViewsEnabled
    favoriteQuickSwitches = settings.favoriteQuickSwitches
    recentQuickSwitches = settings.recentQuickSwitches
    importedTemperamentPacks = settings.importedTemperamentPacks
    importedPresetPacks = settings.importedPresetPacks
    selectedReferenceMidiNumber = normalizeDisplayedReferenceMidiNumberForTransposition(selectedMidiNumber === null ? 69 : selectedMidiNumber, transpositionSemitones)
    settingsHydrating = false

    if (shouldPersist) persistWidgetSettings()

    var currentReferenceState = quickSwitchReferenceStateFingerprint(currentQuickSwitchScene())
    var transpositionChanged = transpositionSemitones !== previousTranspositionSemitones
    var helperActive = helperWanted || helperProcessStarted || helperProc.running
    var shouldReplaySelectedTone = previousReferenceState !== currentReferenceState && toneActive

    if (shouldReplaySelectedTone && helperActive) stopTone()
    if (Math.abs(referenceAHz - previousReferenceAHz) >= 0.0001 && helperActive)
      queueHelperCommand({ type: "set_reference_a", frequency_hz: referenceAHz })
    if (transpositionChanged && helperActive)
      queueTranspositionUpdate(previousTranspositionSemitones, transpositionSemitones, false, shouldReplaySelectedTone)
    if (normalizeStableId(selectedTemperamentId, defaultTemperamentId) !== normalizeStableId(previousTemperamentId, defaultTemperamentId)
        && helperActive) {
      queueHelperCommand({ type: "set_temperament", offsets_cents: selectedTemperamentOffsetsCents.slice(0) })
    }

    if (shouldReplaySelectedTone && helperActive) {
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

    if (midiInputEnabled !== previousMidiInputEnabled
        || normalizeMidiInputPortName(midiInputPortName) !== previousMidiInputPortName)
      syncMidiInputListener()
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

  function externalControlResult(ok, message) {
    return {
      ok: ok === true,
      message: String(message || ""),
    }
  }

  function recordExternalControlSuccess(sourceLabel, message) {
    lastExternalControlSource = String(sourceLabel || "external")
    lastExternalControlSummary = String(message || "ok")
    lastExternalControlError = ""
    return externalControlResult(true, lastExternalControlSummary)
  }

  function recordExternalControlFailure(sourceLabel, message) {
    lastExternalControlSource = String(sourceLabel || "external")
    lastExternalControlSummary = ""
    lastExternalControlError = String(message || "invalid external control command")
    return externalControlResult(false, lastExternalControlError)
  }

  function parseExternalReferenceNoteField(commandObject, commandType) {
    if (!("note" in commandObject)) {
      return {
        ok: true,
        present: false,
        midiNumber: 69,
        noteText: "",
      }
    }

    if (typeof commandObject.note !== "string") {
      return {
        ok: false,
        message: commandType + " field 'note' must be a string",
      }
    }

    var noteText = String(commandObject.note || "").trim()
    var midiNumber = parseNoteMidiNumber(noteText)
    if (midiNumber === null) {
      return {
        ok: false,
        message: "invalid note '" + noteText + "'",
      }
    }

    return {
      ok: true,
      present: true,
      midiNumber: midiNumber,
      noteText: formatMidiNote(midiNumber, "sharps"),
    }
  }

  function applyExternalReferenceCommand(commandObject, sourceLabel, shouldPlay) {
    var commandType = shouldPlay ? "play_reference" : "select_reference"
    var noteField = parseExternalReferenceNoteField(commandObject, commandType)
    if (!noteField.ok) return recordExternalControlFailure(sourceLabel, noteField.message)

    var playbackModeProvided = "playback_mode" in commandObject
    var sceneIdProvided = "scene_id" in commandObject
    var chordIdProvided = "chord_id" in commandObject
    var waveformIdProvided = "waveform_id" in commandObject
    var intervalField = parseExactIntegerField(commandObject, commandType, "interval_semitones")
    if (!intervalField.ok) return recordExternalControlFailure(sourceLabel, intervalField.message)

    if (!shouldPlay && !noteField.present && !playbackModeProvided && !sceneIdProvided && !intervalField.present && !chordIdProvided && !waveformIdProvided) {
      return recordExternalControlFailure(
        sourceLabel,
        "select_reference requires at least one of: note, playback_mode, scene_id, interval_semitones, chord_id, waveform_id"
      )
    }

    var nextPlaybackMode = referencePlaybackMode
    if (playbackModeProvided) {
      if (typeof commandObject.playback_mode !== "string")
        return recordExternalControlFailure(sourceLabel, commandType + " field 'playback_mode' must be a string")

      nextPlaybackMode = exactReferencePlaybackMode(commandObject.playback_mode)
      if (nextPlaybackMode === "") {
        return recordExternalControlFailure(
          sourceLabel,
          commandType + " field 'playback_mode' must be one of: single, interval, chord"
        )
      }
    } else if (chordIdProvided) nextPlaybackMode = "chord"
    else if (intervalField.present) nextPlaybackMode = "interval"

    if (intervalField.present && chordIdProvided) {
      return recordExternalControlFailure(
        sourceLabel,
        commandType + " cannot combine interval_semitones and chord_id"
      )
    }
    if (intervalField.present && nextPlaybackMode === "single") {
      return recordExternalControlFailure(sourceLabel, "single playback does not accept interval_semitones")
    }
    if (chordIdProvided && nextPlaybackMode === "single") {
      return recordExternalControlFailure(sourceLabel, "single playback does not accept chord_id")
    }
    if (chordIdProvided && nextPlaybackMode === "interval") {
      return recordExternalControlFailure(sourceLabel, "interval playback does not accept chord_id")
    }
    if (intervalField.present && nextPlaybackMode === "chord") {
      return recordExternalControlFailure(sourceLabel, "chord playback does not accept interval_semitones")
    }

    var nextSceneId = selectedReferenceSceneId
    if (sceneIdProvided) {
      if (typeof commandObject.scene_id !== "string")
        return recordExternalControlFailure(sourceLabel, commandType + " field 'scene_id' must be a string")

      nextSceneId = exactReferenceSceneId(commandObject.scene_id)
      if (nextSceneId === "")
        return recordExternalControlFailure(sourceLabel, commandType + " field 'scene_id' must be one of: close, bass_octave")
    }

    var nextWaveformId = selectedReferenceWaveformId
    if (waveformIdProvided) {
      if (typeof commandObject.waveform_id !== "string")
        return recordExternalControlFailure(sourceLabel, commandType + " field 'waveform_id' must be a string")

      nextWaveformId = exactReferenceWaveformId(commandObject.waveform_id)
      if (nextWaveformId === "")
        return recordExternalControlFailure(sourceLabel, commandType + " field 'waveform_id' must be one of: sine, warm")
    }

    var nextIntervalSemitones = selectedReferenceIntervalSemitones
    if (intervalField.present) {
      var exactIntervalSemitones = exactReferenceIntervalSemitones(intervalField.value)
      if (exactIntervalSemitones === null) {
        return recordExternalControlFailure(
          sourceLabel,
          commandType + " field 'interval_semitones' must be one of: " + supportedReferenceIntervalSemitoneListText()
        )
      }
      nextIntervalSemitones = exactIntervalSemitones
    }

    var nextChordId = selectedReferenceChordId
    if (chordIdProvided) {
      if (typeof commandObject.chord_id !== "string")
        return recordExternalControlFailure(sourceLabel, commandType + " field 'chord_id' must be a string")

      nextChordId = exactReferenceChordId(commandObject.chord_id)
      if (nextChordId === "")
        return recordExternalControlFailure(sourceLabel, commandType + " field 'chord_id' must be one of: " + supportedReferenceChordIdListText())
    }

    var displayedMidiNumber = noteField.present
      ? shiftedMidiNumber(noteField.midiNumber, transpositionSemitones)
      : selectedReferenceMidiNumber
    if (noteField.present
        && (displayedMidiNumber < minimumDisplayedReferenceMidiNumber
        || displayedMidiNumber > maximumDisplayedReferenceMidiNumber)) {
      return recordExternalControlFailure(
        sourceLabel,
        "note " + noteField.noteText + " is outside the supported range for transposition " + formatSignedSemitoneOffset(transpositionSemitones)
      )
    }

    var intervals = referenceSelectionIntervals(nextPlaybackMode, nextIntervalSemitones, nextChordId)
    if (!referenceSceneIsValid(displayedMidiNumber, transpositionSemitones, intervals, nextSceneId))
      return recordExternalControlFailure(sourceLabel, "requested reference scene is outside the supported note range")

    // External control stays live-only so MIDI note streams and IPC triggers do not rewrite shell.json on every action.
    applyReferenceSelection({
      midiNumber: displayedMidiNumber,
      playbackMode: nextPlaybackMode,
      sceneId: nextSceneId,
      intervalSemitones: nextIntervalSemitones,
      chordId: nextChordId,
      waveformId: nextWaveformId,
    })

    if (shouldPlay || toneActive) playSelectedTone()

    if (shouldPlay) return recordExternalControlSuccess(sourceLabel, "Playing " + selectedReferenceToneSummaryLabel)
    if (toneActive) return recordExternalControlSuccess(sourceLabel, "Retuned " + selectedReferenceToneSummaryLabel)
    return recordExternalControlSuccess(sourceLabel, "Selected " + selectedReferenceToneSummaryLabel)
  }

  function applyExternalPresetCommand(commandObject, sourceLabel) {
    if (typeof commandObject.preset_id !== "string")
      return recordExternalControlFailure(sourceLabel, "select_preset requires string field 'preset_id'")

    var requestedPresetId = normalizeStableId(commandObject.preset_id, "")
    if (requestedPresetId === "")
      return recordExternalControlFailure(sourceLabel, "select_preset requires non-empty string field 'preset_id'")

    var preset = presetById(requestedPresetId)
    if (!preset || normalizeStableId(preset.id, "") !== requestedPresetId)
      return recordExternalControlFailure(sourceLabel, "unknown preset id '" + requestedPresetId + "'")

    selectedPresetId = preset.id
    return recordExternalControlSuccess(sourceLabel, "Selected preset " + selectedPresetLabel)
  }

  function applyExternalStartMetronomeCommand(commandObject, sourceLabel) {
    var bpmField = parseExactIntegerField(commandObject, "start_metronome", "bpm")
    if (!bpmField.ok) return recordExternalControlFailure(sourceLabel, bpmField.message)
    var beatsPerBarField = parseExactIntegerField(commandObject, "start_metronome", "beats_per_bar")
    if (!beatsPerBarField.ok) return recordExternalControlFailure(sourceLabel, beatsPerBarField.message)
    var beatUnitField = parseExactIntegerField(commandObject, "start_metronome", "beat_unit")
    if (!beatUnitField.ok) return recordExternalControlFailure(sourceLabel, beatUnitField.message)
    var subdivisionField = parseExactIntegerField(commandObject, "start_metronome", "subdivision")
    if (!subdivisionField.ok) return recordExternalControlFailure(sourceLabel, subdivisionField.message)

    var nextBpm = bpmField.present ? bpmField.value : metronomeBpm
    if (nextBpm < minimumMetronomeBpm || nextBpm > maximumMetronomeBpm)
      return recordExternalControlFailure(sourceLabel, "start_metronome field 'bpm' must be within 20..=300")

    var nextBeatsPerBar = beatsPerBarField.present ? beatsPerBarField.value : metronomeBeatsPerBar
    var nextBeatUnit = beatUnitField.present ? beatUnitField.value : metronomeBeatUnit
    var meterPreset = exactMetronomeMeter(nextBeatsPerBar, nextBeatUnit)
    if ((beatsPerBarField.present || beatUnitField.present) && !meterPreset) {
      return recordExternalControlFailure(
        sourceLabel,
        "supported metronome meters are 2/4, 3/4, 4/4, and 6/8"
      )
    }
    if (!meterPreset) meterPreset = metronomeMeterPresetByValues(nextBeatsPerBar, nextBeatUnit)

    var nextSubdivision = subdivisionField.present ? subdivisionField.value : metronomeSubdivision
    if (nextSubdivision !== normalizeMetronomeSubdivision(nextSubdivision))
      return recordExternalControlFailure(sourceLabel, "start_metronome field 'subdivision' must be within 1..=4")

    metronomeBpm = nextBpm
    metronomeBeatsPerBar = meterPreset.beatsPerBar
    metronomeBeatUnit = meterPreset.beatUnit
    metronomeSubdivision = nextSubdivision
    queueHelperCommand(metronomeStartCommand())

    return recordExternalControlSuccess(
      sourceLabel,
      "Started metronome at " + metronomeBpm + " BPM | " + metronomeMeterLabel + " | " + metronomeSubdivisionLabel
    )
  }

  function applyExternalControlCommandObject(commandObject, sourceLabel) {
    if (!commandObject || typeof commandObject !== "object" || Array.isArray(commandObject))
      return recordExternalControlFailure(sourceLabel, "command must be a JSON object")
    if (typeof commandObject.type !== "string")
      return recordExternalControlFailure(sourceLabel, "missing string field 'type'")

    var commandType = String(commandObject.type || "")
    if (commandType === "select_reference") return applyExternalReferenceCommand(commandObject, sourceLabel, false)
    if (commandType === "play_reference") return applyExternalReferenceCommand(commandObject, sourceLabel, true)
    if (commandType === "stop_reference") {
      stopTone()
      return recordExternalControlSuccess(sourceLabel, "Stopped reference playback")
    }
    if (commandType === "select_preset") return applyExternalPresetCommand(commandObject, sourceLabel)
    if (commandType === "start_metronome") return applyExternalStartMetronomeCommand(commandObject, sourceLabel)
    if (commandType === "stop_metronome") {
      stopMetronome()
      return recordExternalControlSuccess(sourceLabel, "Stopped metronome")
    }

    return recordExternalControlFailure(sourceLabel, "unknown command type '" + commandType + "'")
  }

  function applyExternalControlJson(rawText, sourceLabel) {
    var commandObject = parseJsonObject(rawText)
    if (!commandObject)
      return recordExternalControlFailure(sourceLabel, "command must be one JSON object")

    return applyExternalControlCommandObject(commandObject, sourceLabel)
  }

  function normalizeMidiInputPortList(values) { return widgetModel.normalizeMidiInputPortList(values) }

  function loadMidiInputPorts() {
    if (midiInputPortsProc.running) return

    midiInputPortsLoaded = false
    midiInputPortsLoadError = ""
    midiInputPortsStdout = ""
    midiInputPortsStderr = ""
    midiInputPortsProc.running = true
  }

  function setMidiInputEnabled(value) {
    var next = !!value
    var previousPortName = normalizeMidiInputPortName(midiInputPortName)
    if (next && previousPortName === "" && availableMidiInputPorts.length > 0)
      midiInputPortName = normalizeMidiInputPortName(availableMidiInputPorts[0])

    if (next === midiInputEnabled && normalizeMidiInputPortName(midiInputPortName) === previousPortName) {
      syncMidiInputListener()
      return
    }

    midiInputEnabled = next
    if (!midiInputEnabled) midiInputListenerError = ""
    persistWidgetSettings()
    syncMidiInputListener()
  }

  function toggleMidiInputEnabled() {
    setMidiInputEnabled(!midiInputEnabled)
  }

  function setMidiInputPortName(value) {
    var next = normalizeMidiInputPortName(value)
    if (next === normalizeMidiInputPortName(midiInputPortName)) {
      syncMidiInputListener()
      return
    }

    midiInputPortName = next
    midiInputListenerError = ""
    persistWidgetSettings()
    syncMidiInputListener()
  }

  function syncMidiInputListener() {
    var targetPortName = normalizeMidiInputPortName(midiInputPortName)
    var shouldRun = midiInputEnabled && targetPortName !== ""

    if (!shouldRun) {
      midiInputListenerRestartPending = false
      midiInputListenerExpectedPortName = ""
      midiInputListenerLastStderr = ""
      if (midiListenerProc.running) midiListenerProc.running = false
      return
    }

    if (midiListenerProc.running) {
      if (midiInputListenerExpectedPortName === targetPortName) return

      midiInputListenerRestartPending = true
      midiInputListenerExpectedPortName = ""
      midiListenerProc.running = false
      return
    }

    midiInputListenerRestartPending = false
    midiInputListenerExpectedPortName = targetPortName
    midiInputListenerLastStderr = ""
    midiInputListenerError = ""
    midiListenerProc.running = true
  }

  function handleMidiInputPortsStdout(rawLine) {
    var line = String(rawLine || "").trim()
    if (line !== "") midiInputPortsStdout = line
  }

  function handleMidiInputPortsStderr(rawLine) {
    var line = String(rawLine || "").trim()
    if (line !== "") midiInputPortsStderr = line
  }

  function handleMidiInputPortsExit(exitCode) {
    midiInputPortsLoaded = true
    if (Number(exitCode) !== 0) {
      availableMidiInputPorts = []
      midiInputPortsLoadError = midiInputPortsStderr !== ""
        ? midiInputPortsStderr
        : "Unable to list MIDI input ports."
      return
    }

    var ports = parseJsonObject(midiInputPortsStdout)
    if (!Array.isArray(ports)) {
      availableMidiInputPorts = []
      midiInputPortsLoadError = "Unable to parse MIDI input port list."
      return
    }

    availableMidiInputPorts = normalizeMidiInputPortList(ports)
    midiInputPortsLoadError = ""
  }

  function handleMidiListenerStdout(rawLine) {
    var line = String(rawLine || "").trim()
    if (line === "") return

    var result = applyExternalControlJson(line, "midi")
    if (!result.ok) midiInputListenerError = result.message
  }

  function handleMidiListenerStderr(rawLine) {
    var line = String(rawLine || "").trim()
    if (line !== "") midiInputListenerLastStderr = line
  }

  function handleMidiListenerExit(exitCode) {
    var exitedPortName = midiInputListenerExpectedPortName
    midiInputListenerExpectedPortName = ""

    if (midiInputListenerRestartPending) {
      midiInputListenerRestartPending = false
      Qt.callLater(syncMidiInputListener)
      return
    }

    if (!midiInputEnabled || normalizeMidiInputPortName(midiInputPortName) === "") return

    if (exitCode !== 0 || exitedPortName !== "") {
      midiInputListenerError = midiInputListenerLastStderr !== ""
        ? midiInputListenerLastStderr
        : "MIDI input listener exited unexpectedly."
    }
  }

  function storedContentPackList(values, expectedKind) { return widgetModel.storedContentPackList(values, expectedKind) }
  function resolvedQuickSwitchScene(scene) { return widgetModel.resolvedQuickSwitchScene(scene) }
  function resolvedQuickSwitchSceneList(scenes, limit) { return widgetModel.resolvedQuickSwitchSceneList(scenes, limit) }

  function syncSelectedTemperamentWithHelper() {
    if (!(helperWanted || helperProcessStarted || helperProc.running)) return
    queueHelperCommand({ type: "set_temperament", offsets_cents: selectedTemperamentOffsetsCents.slice(0) })
  }

  function reconcileSelectedTuningSelections(persistChanges) {
    var shouldPersist = persistChanges !== false
    var previousPresetId = selectedPresetId
    var previousTemperamentId = selectedTemperamentId
    var nextPresetId = presetById(selectedPresetId).id
    var nextTemperamentId = temperamentById(selectedTemperamentId).id

    settingsHydrating = true
    selectedPresetId = nextPresetId
    selectedTemperamentId = nextTemperamentId
    favoriteQuickSwitches = resolvedQuickSwitchSceneList(favoriteQuickSwitches, maximumFavoriteQuickSwitches)
    recentQuickSwitches = resolvedQuickSwitchSceneList(recentQuickSwitches, maximumRecentQuickSwitches)
    settingsHydrating = false

    if (shouldPersist && (previousPresetId !== nextPresetId
        || previousTemperamentId !== nextTemperamentId)) {
      persistWidgetSettings()
    }
    if (previousTemperamentId !== nextTemperamentId)
      syncSelectedTemperamentWithHelper()
  }

  function applyBuiltInTuningLibrary(libraryObject) {
    if (!libraryObject || typeof libraryObject !== "object") return false

    var previousTemperamentFingerprint = selectedTemperamentFingerprint

    builtInTemperamentPacks = storedContentPackList(libraryObject.temperament_packs, "temperament_pack")
    builtInPresetPacks = storedContentPackList(libraryObject.preset_packs, "preset_pack")
    tuningLibraryLoadError = ""
    reconcileSelectedTuningSelections(true)
    if (previousTemperamentFingerprint !== selectedTemperamentFingerprint)
      syncSelectedTemperamentWithHelper()
    return true
  }

  function loadBuiltInTuningLibrary() {
    if (tuningLibraryProc.running) return

    tuningLibraryLoadError = ""
    tuningLibraryStdout = ""
    tuningLibraryStderr = ""
    tuningLibraryProc.running = true
  }

  function contentPackJsonText(pack) { return widgetModel.contentPackJsonText(pack) }

  function exportedSelectedPresetPackJson() {
    return contentPackJsonText(presetPackByPresetId(selectedPresetId))
  }

  function exportedSelectedTemperamentPackJson() {
    return contentPackJsonText(temperamentPackByTemperamentId(selectedTemperamentId))
  }

  function importedContentPackById(packId, values, expectedKind) { return widgetModel.importedContentPackById(packId, values, expectedKind) }

  function removeImportedContentPack(packId, expectedKind) {
    var normalizedPackId = normalizeStableId(packId, "")
    var sourceList = expectedKind === "temperament_pack" ? importedTemperamentPacks : importedPresetPacks
    var filtered = []

    for (var index = 0; index < sourceList.length; index++) {
      var pack = sourceList[index]
      if (normalizeStableId(pack && pack.id, "") === normalizedPackId) continue
      filtered.push(pack)
    }

    if (expectedKind === "temperament_pack") importedTemperamentPacks = storedContentPackList(filtered, expectedKind)
    else importedPresetPacks = storedContentPackList(filtered, expectedKind)

    reconcileSelectedTuningSelections(false)
    persistWidgetSettings()
    return true
  }

  function removeSelectedPresetPack() {
    var pack = presetPackByPresetId(selectedPresetId)
    if (!pack || String(pack.source || "") !== "imported") return false

    removeImportedContentPack(pack.id, "preset_pack")
    contentPackTransferStatusText = "Removed preset pack '" + String(pack.label || pack.id || "pack") + "'."
    contentPackTransferStatusError = false
    return true
  }

  function removeSelectedTemperamentPack() {
    var pack = temperamentPackByTemperamentId(selectedTemperamentId)
    if (!pack || String(pack.source || "") !== "imported") return false

    removeImportedContentPack(pack.id, "temperament_pack")
    contentPackTransferStatusText = "Removed temperament pack '" + String(pack.label || pack.id || "pack") + "'."
    contentPackTransferStatusError = false
    return true
  }

  function existingPresetIdConflict(pack) { return widgetModel.existingPresetIdConflict(pack) }
  function existingTemperamentIdConflict(pack) { return widgetModel.existingTemperamentIdConflict(pack) }
  function contentPackConflictMessage(pack) { return widgetModel.contentPackConflictMessage(pack) }

  function startContentPackImport(text) {
    var trimmed = String(text || "").trim()
    if (contentPackTransferBusy) return false
    if (trimmed === "") {
      contentPackTransferStatusText = "Import failed: paste a preset or temperament pack JSON object."
      contentPackTransferStatusError = true
      return false
    }

    pendingContentPackJson = trimmed
    contentPackToolStdout = ""
    contentPackToolStderr = ""
    contentPackTransferStatusText = "Importing content pack..."
    contentPackTransferStatusError = false
    contentPackTransferBusy = true
    contentPackToolProc.running = true
    return true
  }

  function loadPersistedSettings() {
    applyNormalizedSettings(normalizedSettingsObject(root.settings || ({})), false)
    if (builtInPresetPacks.length > 0 || builtInTemperamentPacks.length > 0)
      reconcileSelectedTuningSelections(false)
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
    var nextReferenceSelection = normalizedReferenceSelection(
      soundingMidiNumber + next,
      next,
      referencePlaybackMode,
      selectedReferenceSceneId,
      selectedReferenceIntervalSemitones,
      selectedReferenceChordId,
      selectedReferenceWaveformId
    )
    var wasToneActive = toneActive
    var wasSelectedToneActive = selectedReferenceToneActive
    var activeDisplayedMidiNumber = parseNoteMidiNumber(activeToneNote)
    var activeIntervals = normalizeProtocolIntervalArray(activeToneIntervalsSemitones)
    var activeDisplayedMidiNumberAfterChange = activeDisplayedMidiNumber === null
      ? null
      : shiftedMidiNumber(shiftedMidiNumber(activeDisplayedMidiNumber, -previous), next)
    var activeSceneValidAfterChange = !wasToneActive || (activeDisplayedMidiNumberAfterChange !== null
      && referenceSceneIsValid(activeDisplayedMidiNumberAfterChange, next, activeIntervals, activeToneSceneId))
    var nextSelectionIntervals = referenceSelectionIntervals(
      nextReferenceSelection.playbackMode,
      nextReferenceSelection.intervalSemitones,
      nextReferenceSelection.chordId
    )
    var shouldReplaySelectedTone = wasSelectedToneActive && (!activeSceneValidAfterChange
      || activeDisplayedMidiNumberAfterChange !== nextReferenceSelection.midiNumber
      || !sameIntegerArray(activeIntervals, nextSelectionIntervals)
      || normalizeSelectedReferenceSceneId(activeToneSceneId) !== nextReferenceSelection.sceneId
      || normalizeSelectedReferenceWaveformId(activeToneWaveformId) !== nextReferenceSelection.waveformId)
    var helperActive = helperWanted || helperProcessStarted || helperProc.running

    transpositionSemitones = next
    applyReferenceSelection(nextReferenceSelection)
    persistWidgetSettings()

    if (shouldReplaySelectedTone && helperActive) stopTone()
    queueTranspositionUpdate(previous, transpositionSemitones, false, shouldReplaySelectedTone)
    if (shouldReplaySelectedTone && helperActive) playSelectedTone()
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

  function setSelectedTemperamentId(value) {
    var next = temperamentById(value).id
    if (next === selectedTemperamentId) return

    rememberCurrentQuickSwitch()
    selectedTemperamentId = next
    persistWidgetSettings()
    syncSelectedTemperamentWithHelper()
  }

  function setReferencePlaybackMode(value) {
    var selection = normalizedReferenceSelection(
      selectedReferenceMidiNumber,
      transpositionSemitones,
      value,
      selectedReferenceSceneId,
      selectedReferenceIntervalSemitones,
      selectedReferenceChordId,
      selectedReferenceWaveformId
    )
    if (sameReferenceSelection(selection)) return

    applyReferenceSelection(selection)
    persistWidgetSettings()
    if (toneActive) playSelectedTone()
  }

  function cycleReferencePlaybackMode() {
    var currentIndex = referencePlaybackModes.indexOf(referencePlaybackMode)
    if (currentIndex < 0) currentIndex = 0
    setReferencePlaybackMode(referencePlaybackModes[(currentIndex + 1) % referencePlaybackModes.length])
  }

  function setSelectedReferenceIntervalSemitones(value) {
    var selection = normalizedReferenceSelection(
      selectedReferenceMidiNumber,
      transpositionSemitones,
      referencePlaybackMode,
      selectedReferenceSceneId,
      value,
      selectedReferenceChordId,
      selectedReferenceWaveformId
    )
    if (sameReferenceSelection(selection)) return

    applyReferenceSelection(selection)
    persistWidgetSettings()
    if (toneActive && referencePlaybackMode === "interval") playSelectedTone()
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
    var selection = normalizedReferenceSelection(
      selectedReferenceMidiNumber,
      transpositionSemitones,
      referencePlaybackMode,
      selectedReferenceSceneId,
      selectedReferenceIntervalSemitones,
      value,
      selectedReferenceWaveformId
    )
    if (sameReferenceSelection(selection)) return

    applyReferenceSelection(selection)
    persistWidgetSettings()
    if (toneActive && referencePlaybackMode === "chord") playSelectedTone()
  }

  function setSelectedReferenceSceneId(value) {
    var selection = normalizedReferenceSelection(
      selectedReferenceMidiNumber,
      transpositionSemitones,
      referencePlaybackMode,
      value,
      selectedReferenceIntervalSemitones,
      selectedReferenceChordId,
      selectedReferenceWaveformId
    )
    if (sameReferenceSelection(selection)) return

    applyReferenceSelection(selection)
    persistWidgetSettings()
    if (toneActive) playSelectedTone()
  }

  function setSelectedReferenceWaveformId(value) {
    var selection = normalizedReferenceSelection(
      selectedReferenceMidiNumber,
      transpositionSemitones,
      referencePlaybackMode,
      selectedReferenceSceneId,
      selectedReferenceIntervalSemitones,
      selectedReferenceChordId,
      value
    )
    if (sameReferenceSelection(selection)) return

    applyReferenceSelection(selection)
    persistWidgetSettings()
    if (toneActive) playSelectedTone()
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

  function setAnalysisViewsEnabled(value) {
    var next = !!value
    if (next === analysisViewsEnabled) return

    analysisViewsEnabled = next
    persistWidgetSettings()
  }

  function toggleAnalysisViewsEnabled() {
    setAnalysisViewsEnabled(!analysisViewsEnabled)
  }

  function setSelectedReferenceMidiNumber(midiNumber) {
    var selection = normalizedReferenceSelection(
      midiNumber,
      transpositionSemitones,
      referencePlaybackMode,
      selectedReferenceSceneId,
      selectedReferenceIntervalSemitones,
      selectedReferenceChordId,
      selectedReferenceWaveformId
    )
    if (sameReferenceSelection(selection)) return false

    applyReferenceSelection(selection)
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
    detectedConfidenceAvailable = false
    detectedPitchHistoryCents = []
    detectedPitchHistorySpanCents = 0
    detectedPitchHeld = false
  }

  function setNoSignal() {
    signalState = "no_signal"
    detectedNote = ""
    detectedFrequencyHz = 0
    detectedCents = 0
    detectedConfidence = 0
    detectedConfidenceAvailable = false
    detectedPitchHistoryCents = []
    detectedPitchHistorySpanCents = 0
    detectedPitchHeld = false
  }

  function clearToneState() {
    activeToneNote = ""
    activeToneFrequencyHz = 0
    activeToneSceneId = defaultReferenceSceneId
    activeToneWaveformId = defaultReferenceWaveformId
    activeToneIntervalsSemitones = []
    activeToneVoices = []
    activeToneSyncsReferenceSelection = true
  }

  function clearPendingToneSelectionSyncFlags() {
    pendingToneSelectionSyncFlags = []
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
      clearPendingToneSelectionSyncFlags()
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
      clearPendingToneSelectionSyncFlags()
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
    clearPendingToneSelectionSyncFlags()
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
    clearPendingToneSelectionSyncFlags()
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

  function queuePlayToneCommand(commandObject, syncReferenceSelection) {
    pendingToneSelectionSyncFlags = pendingToneSelectionSyncFlags.concat([syncReferenceSelection === true])
    queueHelperCommand(commandObject)
  }

  function playSelectedTone() {
    var command = {
      type: "play_tone",
      note: selectedReferenceCommandNoteLabel,
    }

    if (selectedReferenceSceneId !== defaultReferenceSceneId)
      command.scene_id = selectedReferenceSceneId

    if (selectedReferenceWaveformId !== defaultReferenceWaveformId)
      command.waveform_id = selectedReferenceWaveformId

    if (selectedReferenceIntervalsSemitones.length > 0)
      command.intervals_semitones = selectedReferenceIntervalsSemitones.slice(0)

    queuePlayToneCommand(command, true)
  }

  function playTuneNoteString(noteText) {
    var midiNumber = parseNoteMidiNumber(noteText)
    if (midiNumber === null) return false

    queuePlayToneCommand({
      type: "play_tone",
      note: formatMidiNote(midiNumber, "sharps"),
    }, false)
    return true
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

  function presetNoteAt(index) {
    var numeric = Math.round(finiteNumber(index, -1))
    if (numeric < 0 || numeric >= selectedPresetNotes.length) return ""
    return String(selectedPresetNotes[numeric] || "")
  }

  function playPresetNoteAt(index) {
    var noteText = presetNoteAt(index)
    if (noteText === "") return false

    return playTuneNoteString(noteText)
  }

  function stopTone() {
    if (!helperProc.running && !helperProcessStarted) {
      pendingCommandLines = []
      clearPendingToneSelectionSyncFlags()
      clearToneState()
      return
    }

    if (!helperProcessStarted) {
      pendingCommandLines = []
      clearPendingToneSelectionSyncFlags()
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
    var confidenceValue = Number(message.confidence)
    var analysis = message.analysis && typeof message.analysis === "object" && !Array.isArray(message.analysis)
      ? message.analysis
      : null

    helperState = "active"
    helperReadySeen = true
    signalState = "pitch"
    detectedNote = String(message.note || "")
    detectedFrequencyHz = Math.max(0, finiteNumber(message.frequency_hz, 0))
    detectedCents = clampNumber(message.cents, -50, 50, 0)
    detectedConfidenceAvailable = isFinite(confidenceValue)
    detectedConfidence = detectedConfidenceAvailable ? clampNumber(confidenceValue, 0, 1, 0) : 0
    detectedPitchHistoryCents = normalizePitchHistoryCents(analysis ? analysis.history_cents : [])
    detectedPitchHistorySpanCents = clampNumber(analysis ? analysis.history_span_cents : 0, 0, 100, 0)
    detectedPitchHeld = analysis ? analysis.held === true : false
    if (isOutputErrorCode(runtimeErrorCode)) clearRuntimeError()
  }

  function handleRuntimeError(code, messageText) {
    runtimeErrorCode = code
    runtimeErrorMessage = messageText

    if (isOutputErrorCode(code)) clearPendingToneSelectionSyncFlags()
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
      clearPendingToneSelectionSyncFlags()
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
      var syncReferenceSelection = activeToneSyncsReferenceSelection
      if (pendingToneSelectionSyncFlags.length > 0) {
        syncReferenceSelection = pendingToneSelectionSyncFlags[0] === true
        pendingToneSelectionSyncFlags = pendingToneSelectionSyncFlags.slice(1)
      }

      helperState = "active"
      helperReadySeen = true
      activeToneSyncsReferenceSelection = syncReferenceSelection
      activeToneNote = String(message.note || selectedReferenceCommandNoteLabel)
      activeToneFrequencyHz = Math.max(0, finiteNumber(message.frequency_hz, 0))
      activeToneSceneId = normalizeSelectedReferenceSceneId(message.scene_id)
      activeToneWaveformId = normalizeSelectedReferenceWaveformId(message.waveform_id)
      activeToneIntervalsSemitones = normalizeProtocolIntervalArray(message.intervals_semitones)
      activeToneVoices = normalizeToneVoices(message.voices, activeToneNote, activeToneFrequencyHz)
      if (activeToneSyncsReferenceSelection) {
        applySelectedReferenceFromNote(activeToneNote)
        referencePlaybackMode = playbackModeForIntervals(activeToneIntervalsSemitones)
        selectedReferenceSceneId = activeToneSceneId
        selectedReferenceWaveformId = activeToneWaveformId
        if (referencePlaybackMode === "interval")
          selectedReferenceIntervalSemitones = normalizeSelectedReferenceIntervalSemitones(activeToneIntervalsSemitones[0])
        else if (referencePlaybackMode === "chord") {
          var selectedChordPreset = chordPresetByIntervals(activeToneIntervalsSemitones)
          if (selectedChordPreset) selectedReferenceChordId = normalizeSelectedReferenceChordId(selectedChordPreset.id)
        }
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
    clearPendingToneSelectionSyncFlags()
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
    clearPendingToneSelectionSyncFlags()
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

  function handleTuningLibraryStdout(rawLine) {
    var line = String(rawLine || "").trim()
    if (line !== "") tuningLibraryStdout = line
  }

  function handleTuningLibraryStderr(rawLine) {
    var line = String(rawLine || "").trim()
    if (line !== "") tuningLibraryStderr = line
  }

  function handleTuningLibraryExit(exitCode) {
    if (Number(exitCode) !== 0) {
      tuningLibraryLoadError = tuningLibraryStderr !== ""
        ? tuningLibraryStderr
        : "Unable to load the built-in tuning library."
      return
    }

    var library = parseJsonObject(tuningLibraryStdout)
    if (!applyBuiltInTuningLibrary(library)) {
      tuningLibraryLoadError = "Unable to parse the built-in tuning library output."
      return
    }
  }

  function handleContentPackToolStdout(rawLine) {
    var line = String(rawLine || "").trim()
    if (line !== "") contentPackToolStdout = line
  }

  function handleContentPackToolStderr(rawLine) {
    var line = String(rawLine || "").trim()
    if (line !== "") contentPackToolStderr = line
  }

  function handleContentPackToolExit(exitCode) {
    contentPackTransferBusy = false

    if (Number(exitCode) !== 0) {
      contentPackTransferStatusText = contentPackToolStderr !== ""
        ? contentPackToolStderr
        : "Import failed: the helper rejected the content pack."
      contentPackTransferStatusError = true
      return
    }

    var pack = parseJsonObject(contentPackToolStdout)
    if (!pack || typeof pack.kind !== "string") {
      contentPackTransferStatusText = "Import failed: helper output did not contain a normalized content pack."
      contentPackTransferStatusError = true
      return
    }

    var conflictMessage = contentPackConflictMessage(pack)
    if (conflictMessage !== "") {
      contentPackTransferStatusText = conflictMessage
      contentPackTransferStatusError = true
      return
    }

    if (pack.kind === "temperament_pack") {
      importedTemperamentPacks = storedContentPackList(importedTemperamentPacks.concat([pack]), "temperament_pack")
      syncSelectedTemperamentWithHelper()
    } else if (pack.kind === "preset_pack") {
      importedPresetPacks = storedContentPackList(importedPresetPacks.concat([pack]), "preset_pack")
    } else {
      contentPackTransferStatusText = "Import failed: helper returned an unsupported content pack kind."
      contentPackTransferStatusError = true
      return
    }

    persistWidgetSettings()
    contentPackTransferStatusText = "Imported " + String(pack.label || pack.id || "content pack") + "."
    contentPackTransferStatusError = false
  }

  Component.onCompleted: {
    loadPersistedSettings()
    loadBuiltInTuningLibrary()
    loadMidiInputPorts()
  }

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

  IpcHandler {
    target: root.moduleName

    function ping(): string { return "ok" }

    function control(commandJson: string): string {
      var result = root.applyExternalControlJson(commandJson, "ipc")
      return result.ok ? result.message : ("error: " + result.message)
    }
  }

  WidgetButton {
    id: buttonSizer
    visible: false
    enabled: false
    bar: root.bar
    text: root.barIconText
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
    active: root.hasAlert || root.pitchActive || root.toneActive || root.metronomeActive || root.helperState === "starting"
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
    id: tuningLibraryProc
    running: false
    command: root.tuningLibraryCommand
    onExited: function(exitCode, exitStatus) { root.handleTuningLibraryExit(exitCode) }
    stdout: SplitParser {
      onRead: function(line) { root.handleTuningLibraryStdout(line) }
    }
    stderr: SplitParser {
      onRead: function(line) { root.handleTuningLibraryStderr(line) }
    }
  }

  Process {
    id: contentPackToolProc
    running: false
    command: root.contentPackToolCommand
    onExited: function(exitCode, exitStatus) { root.handleContentPackToolExit(exitCode) }
    stdout: SplitParser {
      onRead: function(line) { root.handleContentPackToolStdout(line) }
    }
    stderr: SplitParser {
      onRead: function(line) { root.handleContentPackToolStderr(line) }
    }
  }

  Process {
    id: midiInputPortsProc
    running: false
    command: root.midiInputPortsCommand
    onExited: function(exitCode, exitStatus) { root.handleMidiInputPortsExit(exitCode) }
    stdout: SplitParser {
      onRead: function(line) { root.handleMidiInputPortsStdout(line) }
    }
    stderr: SplitParser {
      onRead: function(line) { root.handleMidiInputPortsStderr(line) }
    }
  }

  Process {
    id: midiListenerProc
    running: false
    command: root.midiInputListenCommand
    onExited: function(exitCode, exitStatus) { root.handleMidiListenerExit(exitCode) }
    stdout: SplitParser {
      onRead: function(line) { root.handleMidiListenerStdout(line) }
    }
    stderr: SplitParser {
      onRead: function(line) { root.handleMidiListenerStderr(line) }
    }
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
