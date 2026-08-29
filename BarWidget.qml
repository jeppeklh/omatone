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
  property string helperState: "inactive"
  property string helperErrorCode: ""
  property string helperError: ""
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
  property real referenceAHz: 440.0
  property string noteSpelling: "sharps"
  property string selectedPresetId: "guitar.standard"
  property int selectedReferenceMidiNumber: 69
  property var pendingCommandLines: []
  property string lastProtocolType: ""
  property string lastProtocolLine: ""
  property string lastStderrLine: ""
  property int lastExitCode: 0

  readonly property int minimumReferenceMidiNumber: 12
  readonly property int maximumReferenceMidiNumber: 119
  readonly property real minimumReferenceAHz: 400.0
  readonly property real maximumReferenceAHz: 480.0
  readonly property var sharpPitchClasses: ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
  readonly property var flatPitchClasses: ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
  readonly property var pitchClasses: noteSpelling === "flats" ? flatPitchClasses : sharpPitchClasses
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
  readonly property bool hasAlert: helperState === "error" || runtimeErrorMessage !== ""
  readonly property int selectedReferencePitchClassIndex: ((selectedReferenceMidiNumber % 12) + 12) % 12
  readonly property int selectedReferenceOctave: Math.floor(selectedReferenceMidiNumber / 12) - 1
  readonly property var selectedPreset: presetById(selectedPresetId)
  readonly property var selectedPresetNotes: selectedPreset ? selectedPreset.notes : []
  readonly property string selectedPresetLabel: selectedPreset ? (selectedPreset.groupLabel + " | " + selectedPreset.label) : "Guitar | Standard"
  readonly property string selectedReferenceCommandNoteLabel: formatMidiNote(selectedReferenceMidiNumber, "sharps")
  readonly property string selectedReferenceNoteLabel: formatMidiNote(selectedReferenceMidiNumber, noteSpelling)
  readonly property string detectedNoteLabel: displayNoteLabel(detectedNote)
  readonly property string activeToneNoteLabel: displayNoteLabel(activeToneNote)
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
    if (pitchActive) return detectedNoteLabel
    if (toneActive) return activeToneNoteLabel
    if (helperState === "error") return "ERR"
    if (helperState === "starting") return "..."
    if (helperState === "inactive") return "OFF"
    return "--"
  }
  readonly property string readoutFooterText: {
    if (pitchActive) return formatSignedCents(detectedCents) + " | " + formatFrequency(detectedFrequencyHz) + " Hz"
    if (toneActive) return "Reference tone | " + formatFrequency(activeToneFrequencyHz) + " Hz | A4 = " + formatReferenceA(referenceAHz)
    if (helperState === "starting") return "Opening microphone and output..."
    if (helperState === "inactive") return "Tuner is off"
    if (helperState === "error") return "Restart the helper to recover"
    if (signalState === "no_signal") return "No signal. Play a note."
    return "Listening..."
  }
  readonly property string statusText: {
    if (helperState === "error") return helperError !== "" ? helperError : "The audio helper stopped unexpectedly."
    if (runtimeErrorMessage !== "") return runtimeErrorMessage
    if (helperState === "inactive") return "Open the tuner or turn it on to begin capture."
    if (helperState === "starting") return "Starting the audio helper..."
    if (signalState === "no_signal") return "No signal. Play a steady note into the microphone."
    if (pitchActive) return "Confidence: " + Math.round(detectedConfidence * 100) + "%"
    return "Listening for pitch..."
  }
  readonly property string detailText: {
    if (toneActive)
      return "Reference tone: " + activeToneNoteLabel + " at " + formatFrequency(activeToneFrequencyHz) + " Hz"
        + " | Preset: " + selectedPresetLabel + " | A4 = " + formatReferenceA(referenceAHz)
    if (pitchActive)
      return "Detected pitch is matched against the nearest equal-tempered note at A4 = " + formatReferenceA(referenceAHz) + "."
    return "Preset: " + selectedPresetLabel + " | A4 = " + formatReferenceA(referenceAHz)
  }
  readonly property string buttonText: {
    if (helperState === "error") return "tun!"
    if (helperState === "inactive") return "tun"
    if (helperState === "starting") return "tun?"
    if (pitchActive) return vertical ? detectedNoteLabel : (detectedNoteLabel + " " + formatCompactCents(detectedCents))
    if (toneActive) return activeToneNoteLabel
    if (runtimeErrorMessage !== "") return "tun!"
    return "listen"
  }
  readonly property string tooltipText: {
    var lines = ["Omatune"]

    if (helperState === "inactive") lines.push("state: off")
    else if (helperState === "starting") lines.push("state: starting")
    else if (helperState === "error") lines.push("state: error")
    else if (pitchActive) lines.push("state: pitch")
    else if (signalState === "no_signal") lines.push("state: no signal")
    else lines.push("state: listening")

    if (pitchActive) lines.push("pitch: " + detectedNoteLabel + "  " + formatSignedCents(detectedCents) + "  " + formatFrequency(detectedFrequencyHz) + " Hz")
    if (toneActive) lines.push("tone: " + activeToneNoteLabel + "  " + formatFrequency(activeToneFrequencyHz) + " Hz")
    lines.push("preset: " + selectedPresetLabel)
    lines.push("A4: " + formatReferenceA(referenceAHz))
    lines.push("spelling: " + noteSpelling)
    if (helperError !== "") lines.push("helper error: " + helperError)
    if (runtimeErrorMessage !== "") lines.push("runtime error: " + runtimeErrorMessage)
    if (lastStderrLine !== "") lines.push("stderr: " + lastStderrLine)
    if (!helperProc.running && lastExitCode !== 0) lines.push("last exit code: " + lastExitCode)

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

  function normalizeNoteSpelling(value) {
    return String(value || "") === "flats" ? "flats" : "sharps"
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

    entry.configVersion = 1
    entry.referenceAHz = normalizeReferenceAHz(referenceAHz)
    entry.noteSpelling = normalizeNoteSpelling(noteSpelling)
    entry.selectedPresetId = selectedPresetId
    entry.selectedReferenceNote = selectedReferenceCommandNoteLabel
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
    settingsHydrating = true
    referenceAHz = normalizeReferenceAHz(root.setting("referenceAHz", 440.0))
    noteSpelling = normalizeNoteSpelling(root.setting("noteSpelling", "sharps"))
    selectedPresetId = presetById(root.setting("selectedPresetId", "guitar.standard")).id

    var persistedReferenceNote = String(root.setting("selectedReferenceNote", "A4") || "A4")
    var selectedMidiNumber = parseNoteMidiNumber(persistedReferenceNote)
    selectedReferenceMidiNumber = selectedMidiNumber === null ? 69 : selectedMidiNumber
    settingsHydrating = false

    if (Math.abs(referenceAHz - previousReferenceAHz) >= 0.0001
        && (helperWanted || helperProcessStarted || helperProc.running)) {
      queueHelperCommand({ type: "set_reference_a", frequency_hz: referenceAHz })
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

  function setNoteSpellingPreference(value) {
    var next = normalizeNoteSpelling(value)
    if (next === noteSpelling) return

    noteSpelling = next
    persistWidgetSettings()
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
  }

  function clearRuntimeError() {
    runtimeErrorCode = ""
    runtimeErrorMessage = ""
  }

  function resetLiveState() {
    clearPitchState()
    clearToneState()
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
    restartPending = false
    pendingCommandLines = []
    ensureHelperRunning()
  }

  function stopHelper() {
    restartPending = false
    helperWanted = false
    helperProcessStarted = false
    helperReadySeen = false
    helperState = "inactive"
    helperErrorCode = ""
    helperError = ""
    pendingCommandLines = []
    lastExitCode = 0
    resetLiveState()

    if (helperProc.running) helperProc.running = false
  }

  function restartHelper() {
    restartPending = false
    helperWanted = false
    helperProcessStarted = false
    helperReadySeen = false
    helperState = "starting"
    helperErrorCode = ""
    helperError = ""
    pendingCommandLines = []
    lastExitCode = 0
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
    queueHelperCommand({
      type: "play_tone",
      note: selectedReferenceCommandNoteLabel,
    })
  }

  function playReferenceNoteString(noteText) {
    if (!applySelectedReferenceFromNote(noteText)) return
    playSelectedTone()
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
  }

  function handleRuntimeError(code, messageText) {
    runtimeErrorCode = code
    runtimeErrorMessage = messageText

    if (isOutputErrorCode(code)) clearToneState()
    if (isInputErrorCode(code)) clearPitchState()
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
      if (helperProc.running) helperProc.running = false
      return
    }

    lastProtocolType = String(message.type)

    if (message.type === "ready") {
      helperState = "active"
      helperReadySeen = true
      helperErrorCode = ""
      helperError = ""
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
      return
    }

    if (message.type === "tone_started") {
      helperState = "active"
      helperReadySeen = true
      activeToneNote = String(message.note || selectedReferenceCommandNoteLabel)
      activeToneFrequencyHz = Math.max(0, finiteNumber(message.frequency_hz, 0))
      applySelectedReferenceFromNote(activeToneNote)
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

    if (message.type === "error") {
      var code = String(message.code || "internal_error")
      var messageText = String(message.message || code || "helper reported an error")

      if (!helperReadySeen) {
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
      helperWanted = false
      lastExitCode = 0
      helperRestartTimer.restart()
      return
    }

    if (!helperWanted) {
      lastExitCode = 0
      return
    }

    lastExitCode = Number(exitCode)
    helperWanted = false
    pendingCommandLines = []
    clearPitchState()
    clearToneState()

    if (helperState !== "error") {
      helperState = "error"
      helperErrorCode = "helper_exit"
      helperError = lastStderrLine !== ""
        ? lastStderrLine
        : "helper exited unexpectedly"
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
      || (root.helperState === "active" && !root.pitchActive && !root.toneActive && !root.hasAlert)
    active: root.hasAlert || root.inTune || root.toneActive
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
    interval: 120
    onTriggered: root.startHelper()
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
