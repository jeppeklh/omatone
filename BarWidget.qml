import Quickshell
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
    { id: "dominant7", label: "7", summary: "1 3 5 b7", intervalsSemitones: [4, 7, 10] },
    { id: "major7", label: "Delta7", summary: "1 3 5 7", intervalsSemitones: [4, 7, 11] },
    { id: "minor7", label: "m7", summary: "1 b3 5 b7", intervalsSemitones: [3, 7, 10] },
    { id: "minor_major7", label: "mDelta7", summary: "1 b3 5 7", intervalsSemitones: [3, 7, 11] },
    { id: "m7b5", label: "m7b5", summary: "1 b3 b5 b7", intervalsSemitones: [3, 6, 10] },
    { id: "diminished", label: "dim", summary: "1 b3 b5", intervalsSemitones: [3, 6] },
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
  readonly property var selectedPreset: presetById(selectedPresetId)
  readonly property var selectedPresetTargets: transposePresetTargets(selectedPreset.targets, transpositionSemitones)
  readonly property var selectedPresetNotes: selectedPresetTargetNotes(selectedPresetTargets)
  readonly property string selectedPresetLabel: selectedPreset.groupLabel + " | " + selectedPreset.label
  readonly property var selectedTemperament: temperamentById(selectedTemperamentId)
  readonly property string selectedTemperamentLabelText: String(selectedTemperament.label || fallbackTemperament.label)
  readonly property string selectedTemperamentDescription: String(selectedTemperament.description || "")
  readonly property var selectedTemperamentOffsetsCents: normalizedTemperamentOffsets(selectedTemperament.offsets_cents)
  readonly property string selectedTemperamentFingerprint: temperamentFingerprint(selectedTemperamentOffsetsCents)
  readonly property bool temperamentActive: selectedTemperament.id !== defaultTemperamentId
  readonly property bool currentQuickSwitchFavorite: indexOfQuickSwitchScene(favoriteQuickSwitches, currentQuickSwitchScene()) >= 0
  readonly property var visibleRecentQuickSwitches: recentQuickSwitchesForDisplay()
  readonly property bool hasQuickSwitches: favoriteQuickSwitches.length > 0 || visibleRecentQuickSwitches.length > 0
  readonly property bool midiInputConfigured: midiInputEnabled && normalizeMidiInputPortName(midiInputPortName) !== ""
  readonly property string transpositionLabelText: formatTranspositionLabel(transpositionSemitones)
  readonly property string selectedReferenceCommandNoteLabel: formatMidiNote(selectedReferenceMidiNumber, "sharps")
  readonly property string selectedReferenceNoteLabel: formatMidiNote(selectedReferenceMidiNumber, noteSpelling)
  readonly property int selectedReferenceIntervalPresetIndex: indexOfReferenceIntervalPreset(selectedReferenceIntervalSemitones)
  readonly property int selectedReferenceChordPresetIndex: indexOfReferenceChordPreset(selectedReferenceChordId)
  readonly property int selectedReferenceWaveformPresetIndex: indexOfReferenceWaveformPreset(selectedReferenceWaveformId)
  readonly property var selectedReferenceIntervalsSemitones: referenceSelectionIntervals(
    referencePlaybackMode,
    selectedReferenceIntervalSemitones,
    selectedReferenceChordId
  )
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
  readonly property var selectedReferencePreviewVoiceLabels: previewReferenceVoiceLabels(
    selectedReferenceMidiNumber,
    transpositionSemitones,
    selectedReferenceIntervalsSemitones,
    selectedReferenceSceneId
  )
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
  readonly property bool barHelperIndicatorActive: helperRecoveryPending || helperState === "starting" || helperState === "active"
  readonly property string barHelperIndicatorText: barHelperIndicatorActive ? "\u25CF" : "\u25CB"
  readonly property string barToneIndicatorText: toneActive ? "\u25CF" : "\u25CB"
  readonly property string barMetronomeIndicatorText: metronomeActive ? "\u25CF" : "\u25CB"
  readonly property string barMeasureText: barIconText + " " + "\u25CF \u25CF \u25CF"
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
      + " " + barHelperIndicatorText
      + " " + barToneIndicatorText
      + " " + barMetronomeIndicatorText
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

    selectedReferenceMidiNumber = normalized.midiNumber
    referencePlaybackMode = normalized.playbackMode
    selectedReferenceSceneId = normalized.sceneId
    selectedReferenceIntervalSemitones = normalized.intervalSemitones
    selectedReferenceChordId = normalized.chordId
    selectedReferenceWaveformId = normalized.waveformId
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

  function queueTranspositionUpdate(previousTransposition, nextTransposition, replaySelectedTone, activeToneAlreadyStopping) {
    if (!(helperWanted || helperProcessStarted || helperProc.running)) return

    var normalizedNextTransposition = normalizeTranspositionSemitones(nextTransposition)
    if (!activeToneAlreadyStopping && toneActive && !activeToneValidAcrossTranspositionChange(previousTransposition, normalizedNextTransposition))
      stopTone()

    queueHelperCommand({ type: "set_transposition", semitones: normalizedNextTransposition })
    if (replaySelectedTone) playSelectedTone()
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
    var root = String(rootNoteLabel || "")
    var normalizedIntervals = normalizeProtocolIntervalArray(intervals)
    if (root === "" || normalizedIntervals.length === 0) return root

    var chordPreset = normalizedIntervals.length > 1 ? chordPresetByIntervals(normalizedIntervals) : null
    if (chordPreset && String(chordPreset.label || "") !== "") return root + " " + String(chordPreset.label || "")

    var intervalText = intervalListLabel(intervals)
    if (root === "" || intervalText === "") return root
    return root + " + " + intervalText
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

  function contentPackJsonText(pack) {
    if (!pack || typeof pack !== "object") return ""

    var exported = {}
    for (var key in pack)
      if (key !== "source") exported[key] = pack[key]

    return JSON.stringify(exported, null, 2)
  }

  function exportedSelectedPresetPackJson() {
    return contentPackJsonText(presetPackByPresetId(selectedPresetId))
  }

  function exportedSelectedTemperamentPackJson() {
    return contentPackJsonText(temperamentPackByTemperamentId(selectedTemperamentId))
  }

  function importedContentPackById(packId, values, expectedKind) {
    var normalizedPackId = normalizeStableId(packId, "")
    var list = filteredContentPackList(values, expectedKind, "imported")

    for (var index = 0; index < list.length; index++)
      if (normalizeStableId(list[index].id, "") === normalizedPackId) return list[index]

    return null
  }

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
