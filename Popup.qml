import QtQuick
import qs.Commons
import qs.Ui

FocusScope {
  id: root

  property var bar: null
  property Item anchorItem: null
  property var hostWidget: null
  property bool opened: false
  property bool popoutSwitchClosing: false
  property string configTransferStatusText: ""
  property bool configTransferStatusError: false
  property string contentPackTransferText: ""
  property string activeDestination: "tune"

  readonly property color foreground: root.bar ? root.bar.foreground : Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property bool verticalBar: root.hostWidget ? root.hostWidget.vertical : false
  readonly property bool highContrast: root.hostWidget ? root.hostWidget.highContrastMode : false
  readonly property bool reducedMotion: root.hostWidget ? root.hostWidget.reducedMotionMode : false
  readonly property real preferredContentWidth: verticalBar ? Style.space(360) : Style.space(470)
  readonly property real popupMaxWidth: verticalBar ? Style.space(400) : Style.space(540)
  readonly property real popupMaxHeight: Style.space(620)
  readonly property int quickNoteColumns: verticalBar ? 2 : 3
  readonly property int presetColumns: verticalBar ? 1 : 2
  readonly property int toneOptionColumns: verticalBar ? 1 : 2
  readonly property int intervalOptionColumns: verticalBar ? 2 : 4
  readonly property int referenceGridColumns: verticalBar ? 3 : 4
  readonly property var popupDestinations: [
    { value: "tune", label: "Tune" },
    { value: "reference", label: "Tone" },
    { value: "metronome", label: "Metronome" },
    { value: "presets", label: "Presets" },
    { value: "advanced", label: "Advanced" },
  ]

  function normalizeDestination(value) {
    var next = String(value || "").toLowerCase()
    if (next === "tone") return "reference"
    if (next === "reference") return next
    if (next === "metronome") return next
    if (next === "presets") return next
    if (next === "advanced") return next
    return "tune"
  }

  function setActiveDestination(value) {
    var next = normalizeDestination(value)
    if (next === activeDestination) {
      if (opened) {
        scrollView.contentY = 0
        Qt.callLater(root.focusInitialControl)
      }
      return
    }

    activeDestination = next
  }

  function open() {
    activeDestination = "tune"
    opened = true
  }

  function close() {
    opened = false
    popoutSwitchClosing = false
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    opened = false
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }

  function ensureConfigTransferTextLoaded() {
    if (!hostWidget) return
    if (String(configTransferEditor.text || "").trim() !== "") return
    configTransferEditor.text = hostWidget.exportedConfigurationJson()
  }

  function loadCurrentConfigurationText() {
    if (!hostWidget) return
    configTransferEditor.text = hostWidget.exportedConfigurationJson()
    configTransferStatusText = ""
    configTransferStatusError = false
  }

  function applyImportedConfigurationText() {
    if (!hostWidget) return

    var result = hostWidget.importConfigurationJson(configTransferEditor.text)
    configTransferStatusText = String(result.message || "")
    configTransferStatusError = result.ok !== true
    if (result.ok && "text" in result)
      configTransferEditor.text = String(result.text || "")
  }

  function loadSelectedPresetPackText() {
    if (!hostWidget) return
    contentPackTransferEditor.text = hostWidget.exportedSelectedPresetPackJson()
  }

  function loadSelectedTemperamentPackText() {
    if (!hostWidget) return
    contentPackTransferEditor.text = hostWidget.exportedSelectedTemperamentPackJson()
  }

  function applyImportedContentPackText() {
    if (!hostWidget) return
    hostWidget.startContentPackImport(contentPackTransferEditor.text)
  }

  function focusInitialControl() {
    if (!opened) return

    var target = null
    if (activeDestination === "reference") target = playToneButton
    else if (activeDestination === "metronome") target = metronomeToggleButton
    else if (activeDestination === "presets") target = favoriteSceneButton
    else if (activeDestination === "advanced")
      target = restartAudioButton.enabled ? restartAudioButton : referenceAResetButton
    else target = quickNoteRepeater.count > 0 ? quickNoteRepeater.itemAt(0) : powerButton

    if (!target) target = powerButton
    if (!target) target = destinationTabRepeater.count > 0 ? destinationTabRepeater.itemAt(0) : null
    if (target && target.forceActiveFocus) target.forceActiveFocus()
  }

  onOpenedChanged: {
    if (opened) {
      scrollView.contentY = 0
      Qt.callLater(root.focusInitialControl)
      Qt.callLater(root.ensureConfigTransferTextLoaded)
    }
  }

  onActiveDestinationChanged: {
    if (!opened) return
    scrollView.contentY = 0
    Qt.callLater(root.focusInitialControl)
  }

  onHostWidgetChanged: Qt.callLater(root.ensureConfigTransferTextLoaded)

  Shortcut {
    sequence: "Escape"
    enabled: root.opened
    onActivated: root.close()
  }

  Shortcut {
    sequence: "T"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.toggleHelper()
  }

  Shortcut {
    sequence: "R"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.restartHelper()
  }

  Shortcut {
    sequence: "P"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.toggleSelectedReferenceTone()
  }

  Shortcut {
    sequence: "X"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.toneActive
    onActivated: root.hostWidget.stopTone()
  }

  Shortcut {
    sequence: "D"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.cycleReferencePlaybackMode()
  }

  Shortcut {
    sequence: "["
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.changeSelectedReferenceShapePreset(-1)
  }

  Shortcut {
    sequence: "]"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.changeSelectedReferenceShapePreset(1)
  }

  Shortcut {
    sequence: "Left"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.changeReferenceSemitone(-1)
  }

  Shortcut {
    sequence: "Right"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.changeReferenceSemitone(1)
  }

  Shortcut {
    sequence: "Alt+Up"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.changeReferenceOctave(1)
  }

  Shortcut {
    sequence: "Alt+Down"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.changeReferenceOctave(-1)
  }

  Shortcut {
    sequence: "M"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.toggleMetronome()
  }

  Shortcut {
    sequence: "Shift+M"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.tapMetronomeTempo()
  }

  Shortcut {
    sequence: "Ctrl+M"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.changeMetronomeMeter(1)
  }

  Shortcut {
    sequence: "Alt+M"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.changeMetronomeSubdivision(1)
  }

  Shortcut {
    sequence: "Shift+Left"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.changeMetronomeBpm(-1)
  }

  Shortcut {
    sequence: "Shift+Right"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.changeMetronomeBpm(1)
  }

  Shortcut {
    sequence: "F"
    enabled: root.opened && !!root.hostWidget
    onActivated: root.hostWidget.toggleCurrentQuickSwitchFavorite()
  }

  Shortcut {
    sequence: "1"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.selectedPresetNotes.length >= 1
    onActivated: root.hostWidget.playPresetNoteAt(0)
  }

  Shortcut {
    sequence: "2"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.selectedPresetNotes.length >= 2
    onActivated: root.hostWidget.playPresetNoteAt(1)
  }

  Shortcut {
    sequence: "3"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.selectedPresetNotes.length >= 3
    onActivated: root.hostWidget.playPresetNoteAt(2)
  }

  Shortcut {
    sequence: "4"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.selectedPresetNotes.length >= 4
    onActivated: root.hostWidget.playPresetNoteAt(3)
  }

  Shortcut {
    sequence: "5"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.selectedPresetNotes.length >= 5
    onActivated: root.hostWidget.playPresetNoteAt(4)
  }

  Shortcut {
    sequence: "6"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.selectedPresetNotes.length >= 6
    onActivated: root.hostWidget.playPresetNoteAt(5)
  }

  Shortcut {
    sequence: "7"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.selectedPresetNotes.length >= 7
    onActivated: root.hostWidget.playPresetNoteAt(6)
  }

  Shortcut {
    sequence: "8"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.selectedPresetNotes.length >= 8
    onActivated: root.hostWidget.playPresetNoteAt(7)
  }

  Shortcut {
    sequence: "Ctrl+1"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.favoriteQuickSwitches.length >= 1
    onActivated: root.hostWidget.applyFavoriteQuickSwitchAt(0)
  }

  Shortcut {
    sequence: "Ctrl+2"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.favoriteQuickSwitches.length >= 2
    onActivated: root.hostWidget.applyFavoriteQuickSwitchAt(1)
  }

  Shortcut {
    sequence: "Ctrl+3"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.favoriteQuickSwitches.length >= 3
    onActivated: root.hostWidget.applyFavoriteQuickSwitchAt(2)
  }

  Shortcut {
    sequence: "Ctrl+4"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.favoriteQuickSwitches.length >= 4
    onActivated: root.hostWidget.applyFavoriteQuickSwitchAt(3)
  }

  Shortcut {
    sequence: "Ctrl+5"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.favoriteQuickSwitches.length >= 5
    onActivated: root.hostWidget.applyFavoriteQuickSwitchAt(4)
  }

  Shortcut {
    sequence: "Ctrl+6"
    enabled: root.opened && !!root.hostWidget && root.hostWidget.favoriteQuickSwitches.length >= 6
    onActivated: root.hostWidget.applyFavoriteQuickSwitchAt(5)
  }

  PopupCard {
    id: popup
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root.hostWidget || root
    open: root.opened
    contentWidth: popup.fittedContentWidth(root.preferredContentWidth, root.popupMaxWidth)
    contentHeight: popup.fittedContentHeight(contentColumn.implicitHeight, root.popupMaxHeight)

    Flickable {
      id: scrollView
      anchors.fill: parent
      contentWidth: width
      contentHeight: contentColumn.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: contentColumn
        width: parent.width
        spacing: Style.space(10)

        Column {
          width: parent.width
          spacing: Style.space(4)

          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: "Omatune"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

        }

        Rectangle {
          id: readoutCard
          width: parent.width
          height: readoutColumn.implicitHeight + Style.space(14) * 2
          radius: Style.cornerRadius * 2
          color: root.hostWidget && root.hostWidget.hasAlert
            ? Util.alpha(Color.urgent, root.highContrast ? 0.18 : 0.10)
            : (root.hostWidget && root.hostWidget.inTune
              ? Util.alpha(Color.accent, root.highContrast ? 0.22 : 0.16)
              : (root.hostWidget && (root.hostWidget.toneActive || root.hostWidget.metronomeActive)
                ? Util.alpha(Color.accent, root.highContrast ? 0.12 : 0.08)
                : Util.alpha(root.foreground, root.highContrast ? 0.12 : 0.06)))
          border.width: root.highContrast ? Math.max(2, Style.normalBorderWidth) : Math.max(1, Style.normalBorderWidth)
          border.color: root.hostWidget && root.hostWidget.hasAlert
            ? Util.alpha(Color.urgent, root.highContrast ? 0.95 : 0.70)
            : (root.hostWidget && root.hostWidget.inTune
              ? Util.alpha(Color.accent, root.highContrast ? 0.92 : 0.65)
              : Util.alpha(root.foreground, root.highContrast ? 0.72 : 0.35))

          Column {
            id: readoutColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.space(14)
            anchors.rightMargin: Style.space(14)
            spacing: Style.space(8)

            Text {
              width: parent.width
              textFormat: Text.PlainText
              horizontalAlignment: Text.AlignHCenter
              text: root.hostWidget ? root.hostWidget.stateBadgeText : ""
              color: root.hostWidget && root.hostWidget.hasAlert
                ? Color.urgent
                : (root.hostWidget && (root.hostWidget.inTune || root.hostWidget.toneActive || root.hostWidget.metronomeActive)
                  ? Color.accent
                  : root.foreground)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              horizontalAlignment: Text.AlignHCenter
              text: root.hostWidget ? root.hostWidget.readoutTitleText : "--"
              color: root.hostWidget && root.hostWidget.hasAlert
                ? Color.urgent
                : (root.hostWidget && (root.hostWidget.inTune || root.hostWidget.toneActive || root.hostWidget.metronomeActive)
                  ? Color.accent
                  : root.foreground)
              font.family: root.fontFamily
              font.pixelSize: Math.round(Style.font.subtitle * 2.2)
              font.bold: true
            }

            Rectangle {
              id: meter
              width: parent.width
              height: Style.space(28)
              radius: Style.cornerRadius
              color: Util.alpha(root.foreground, root.highContrast ? 0.16 : 0.10)
              border.width: root.highContrast ? 1 : 0
              border.color: Util.alpha(root.foreground, root.highContrast ? 0.50 : 0.0)

              Rectangle {
                width: Math.max(Style.space(30), meter.width * 0.12)
                height: parent.height
                radius: parent.radius
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.hostWidget && root.hostWidget.inTune
                  ? Util.alpha(Color.accent, root.highContrast ? 0.34 : 0.24)
                  : Util.alpha(root.foreground, root.highContrast ? 0.18 : 0.10)
              }

              Rectangle {
                width: root.highContrast ? 2 : 1
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                color: Util.alpha(root.foreground, root.highContrast ? 0.80 : 0.45)
              }

              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(6)
                textFormat: Text.PlainText
                text: "FLAT"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: root.highContrast
              }

              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: "OK"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Style.space(6)
                textFormat: Text.PlainText
                text: "SHARP"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: root.highContrast
              }

              Rectangle {
                width: root.highContrast ? Style.space(5) : Style.space(3)
                height: parent.height
                radius: width / 2
                visible: root.hostWidget ? root.hostWidget.pitchActive : false
                color: root.hostWidget && root.hostWidget.inTune ? Color.accent : Color.urgent
                x: root.hostWidget
                  ? Math.max(0, Math.min(meter.width - width, (meter.width - width) * (Math.max(-50, Math.min(50, root.hostWidget.detectedCents)) + 50) / 100))
                  : 0

                Behavior on x {
                  enabled: !root.reducedMotion
                  NumberAnimation {
                    duration: 90
                  }
                }
              }
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              horizontalAlignment: Text.AlignHCenter
              text: root.hostWidget ? root.hostWidget.readoutFooterText : ""
              color: root.foreground
              opacity: root.highContrast ? 1.0 : 0.88
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
            }
          }

          Behavior on color {
            enabled: !root.reducedMotion
            ColorAnimation {
              duration: 140
            }
          }
        }

        Flow {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            id: destinationTabRepeater
            model: root.popupDestinations

            Button {
              required property var modelData

              text: String(modelData.label || "")
              selected: root.activeDestination === String(modelData.value || "")
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.space(7)
              focusable: true
              onClicked: root.setActiveDestination(String(modelData.value || ""))
            }
          }
        }

        Item {
          visible: root.activeDestination === "tune"
          width: parent.width
          height: visible ? tuneSection.implicitHeight : 0

          Column {
            id: tuneSection
            width: parent.width
            spacing: Style.space(10)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Text {
                width: Math.max(0, parent.width - powerButton.implicitWidth - parent.spacing)
                textFormat: Text.PlainText
                text: "Tune"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                verticalAlignment: Text.AlignVCenter
              }

              Button {
                id: powerButton
                text: root.hostWidget && (root.hostWidget.helperState === "inactive" || root.hostWidget.helperState === "error") ? "Turn on" : "Turn off"
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                bordered: true
                focusable: true
                enabled: root.hostWidget && root.hostWidget.helperState !== "starting"
                opacity: enabled ? 1.0 : 0.5
                onClicked: if (root.hostWidget) root.hostWidget.toggleHelper()
              }
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: root.hostWidget ? root.hostWidget.quickTuneHeadingText : "Quick tune"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Grid {
              id: quickNoteGrid
              width: parent.width
              columns: root.quickNoteColumns
              rowSpacing: Style.space(6)
              columnSpacing: Style.space(6)

              Repeater {
                id: quickNoteRepeater
                model: root.hostWidget ? root.hostWidget.selectedPresetTargets : []

                Button {
                  required property var modelData
                  required property int index

                  width: (quickNoteGrid.width - quickNoteGrid.columnSpacing * Math.max(0, quickNoteGrid.columns - 1)) / Math.max(1, quickNoteGrid.columns)
                  text: root.hostWidget ? ((index + 1) + "  " + root.hostWidget.presetTargetDisplayLabel(modelData)) : String(modelData)
                  selected: root.hostWidget
                    ? (root.hostWidget.activeToneIsSingleNote
                      && root.hostWidget.sameNoteText(root.hostWidget.activeToneNote, String(modelData.note || "")))
                    : false
                  bordered: true
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  fontSize: Style.font.bodySmall
                  verticalPadding: Style.space(8)
                  focusable: true
                  onClicked: if (root.hostWidget) root.hostWidget.playTuneNoteString(String(modelData.note || ""))
                }
              }
            }

            Item {
              visible: root.hostWidget ? root.hostWidget.analysisViewsEnabled : false
              width: parent.width
              height: visible ? analysisColumn.implicitHeight : 0

              Column {
                id: analysisColumn
                width: parent.width
                spacing: Style.space(8)

                PanelSeparator {
                  foreground: root.foreground
                }

                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: "Analysis"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Rectangle {
                  id: analysisTracePanel
                  width: parent.width
                  height: Style.space(72)
                  radius: Style.cornerRadius
                  color: Util.alpha(root.foreground, root.highContrast ? 0.10 : 0.05)
                  border.width: 1
                  border.color: Util.alpha(root.foreground, root.highContrast ? 0.48 : 0.22)
                  readonly property bool hasTrace: root.hostWidget ? root.hostWidget.hasDetectedPitchHistory : false

                  Rectangle {
                    width: parent.width
                    height: Math.max(Style.space(8), parent.height * 0.18)
                    radius: parent.radius
                    anchors.centerIn: parent
                    color: Util.alpha(root.foreground, root.highContrast ? 0.14 : 0.08)
                  }

                  Rectangle {
                    width: parent.width
                    height: root.highContrast ? 2 : 1
                    anchors.centerIn: parent
                    color: Util.alpha(root.foreground, root.highContrast ? 0.72 : 0.38)
                  }

                  Row {
                    id: analysisHistoryRow
                    anchors.fill: parent
                    anchors.margins: Style.space(10)
                    spacing: Style.space(4)
                    visible: analysisTracePanel.hasTrace

                    Repeater {
                      id: analysisHistoryRepeater
                      model: root.hostWidget ? root.hostWidget.detectedPitchHistoryCents : []

                      Item {
                        required property int index
                        required property var modelData

                        width: Math.max(Style.space(8), (analysisHistoryRow.width - analysisHistoryRow.spacing * Math.max(0, analysisHistoryRepeater.count - 1)) / Math.max(1, analysisHistoryRepeater.count))
                        height: analysisHistoryRow.height
                        readonly property real centsValue: Math.max(-50, Math.min(50, Number(modelData)))
                        readonly property real halfHeight: height / 2
                        readonly property real maxBarHeight: Math.max(0, halfHeight - Style.space(4))
                        readonly property real barHeight: Math.max(Style.space(4), Math.abs(centsValue) / 50 * maxBarHeight)
                        readonly property bool latestPoint: index === analysisHistoryRepeater.count - 1

                        Rectangle {
                          width: root.highContrast ? Math.max(4, parent.width * 0.60) : Math.max(3, parent.width * 0.45)
                          height: parent.barHeight
                          radius: width / 2
                          anchors.horizontalCenter: parent.horizontalCenter
                          y: parent.centsValue >= 0 ? (parent.halfHeight - height) : parent.halfHeight
                          color: parent.latestPoint
                            ? (root.hostWidget && root.hostWidget.detectedPitchHeld ? Color.urgent : Color.accent)
                            : Util.alpha(root.foreground, root.highContrast ? 0.72 : 0.40)
                        }
                      }
                    }
                  }

                  Text {
                    anchors.centerIn: parent
                    visible: !analysisTracePanel.hasTrace
                    textFormat: Text.PlainText
                    text: "Play a steady note"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                  }
                }

                Text {
                  width: parent.width
                  visible: root.hostWidget ? root.hostWidget.detectedPitchHeld : false
                  textFormat: Text.PlainText
                  text: "The helper is holding the last stable note while it waits for a cleaner confirming frame."
                  color: Color.urgent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }
              }
            }
          }
        }

        Item {
          visible: root.activeDestination === "presets"
          width: parent.width
          height: visible ? quickSwitchColumn.implicitHeight : 0

          Column {
            id: quickSwitchColumn
            width: parent.width
            spacing: Style.space(8)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Text {
                width: Math.max(0, parent.width - favoriteSceneButton.implicitWidth - parent.spacing)
                textFormat: Text.PlainText
                text: "Presets"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                verticalAlignment: Text.AlignVCenter
              }

              Button {
                id: favoriteSceneButton
                text: root.hostWidget && root.hostWidget.currentQuickSwitchFavorite ? "Remove favorite" : "Save favorite"
                selected: root.hostWidget ? root.hostWidget.currentQuickSwitchFavorite : false
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                bordered: true
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.toggleCurrentQuickSwitchFavorite()
              }
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Quick switch"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            Text {
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.favoriteQuickSwitches.length > 0 : false
              textFormat: Text.PlainText
              text: "Favorites"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Flow {
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.favoriteQuickSwitches.length > 0 : false
              spacing: Style.space(6)

              Repeater {
                model: root.hostWidget ? root.hostWidget.favoriteQuickSwitches : []

                Button {
                  required property var modelData
                  required property int index

                  text: root.hostWidget ? ((index + 1) + "  " + root.hostWidget.quickSwitchButtonText(modelData)) : String(modelData)
                  selected: root.hostWidget ? root.hostWidget.sameQuickSwitchScene(root.hostWidget.currentQuickSwitchScene(), modelData) : false
                  bordered: true
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  fontSize: Style.font.bodySmall
                  verticalPadding: Style.space(7)
                  focusable: true
                  onClicked: if (root.hostWidget) root.hostWidget.applyQuickSwitchScene(modelData)
                }
              }
            }

            Text {
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.visibleRecentQuickSwitches.length > 0 : false
              textFormat: Text.PlainText
              text: "Recents"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Flow {
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.visibleRecentQuickSwitches.length > 0 : false
              spacing: Style.space(6)

              Repeater {
                model: root.hostWidget ? root.hostWidget.visibleRecentQuickSwitches : []

                Button {
                  required property var modelData

                  text: root.hostWidget ? root.hostWidget.quickSwitchButtonText(modelData) : String(modelData)
                  selected: root.hostWidget ? root.hostWidget.sameQuickSwitchScene(root.hostWidget.currentQuickSwitchScene(), modelData) : false
                  bordered: true
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  fontSize: Style.font.bodySmall
                  verticalPadding: Style.space(7)
                  focusable: true
                  onClicked: if (root.hostWidget) root.hostWidget.applyQuickSwitchScene(modelData)
                }
              }
            }

          }
        }

        Item {
          visible: root.activeDestination === "presets"
          width: parent.width
          height: visible ? expandedContent.implicitHeight : 0

          Column {
            id: expandedContent
            width: parent.width
            spacing: Style.space(10)

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Temperament"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Repeater {
              model: root.hostWidget ? root.hostWidget.temperamentPackSections : []

              Column {
                required property var modelData

                width: parent.width
                spacing: Style.space(6)

                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: String(modelData.label || "")
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                }

                Flow {
                  width: parent.width
                  spacing: Style.space(6)

                  Repeater {
                    model: Array.isArray(modelData.temperaments) ? modelData.temperaments : []

                    Button {
                      required property var modelData

                      text: String(modelData.label || "")
                      selected: root.hostWidget ? root.hostWidget.selectedTemperamentId === String(modelData.id || "") : false
                      bordered: true
                      foreground: root.foreground
                      fontFamily: root.fontFamily
                      fontSize: Style.font.bodySmall
                      verticalPadding: Style.space(7)
                      focusable: true
                      onClicked: if (root.hostWidget) root.hostWidget.setSelectedTemperamentId(String(modelData.id || ""))
                    }
                  }
                }
              }
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Content packs"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Text {
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.tuningLibraryLoadError !== "" : false
              textFormat: Text.PlainText
              text: root.hostWidget ? root.hostWidget.tuningLibraryLoadError : ""
              color: Color.urgent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Button {
                text: "Load preset pack"
                width: Math.max(Style.space(118), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: root.loadSelectedPresetPackText()
              }

              Button {
                text: "Load temperament pack"
                width: Math.max(Style.space(148), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: root.loadSelectedTemperamentPackText()
              }

              Button {
                text: root.hostWidget && root.hostWidget.contentPackTransferBusy ? "Importing..." : "Apply pack import"
                width: Math.max(Style.space(126), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                enabled: root.hostWidget ? !root.hostWidget.contentPackTransferBusy : false
                opacity: enabled ? 1.0 : 0.5
                onClicked: root.applyImportedContentPackText()
              }
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)
              visible: root.hostWidget
                ? ((root.hostWidget.presetPackByPresetId(root.hostWidget.selectedPresetId)
                    && root.hostWidget.presetPackByPresetId(root.hostWidget.selectedPresetId).source === "imported")
                  || (root.hostWidget.temperamentPackByTemperamentId(root.hostWidget.selectedTemperamentId)
                    && root.hostWidget.temperamentPackByTemperamentId(root.hostWidget.selectedTemperamentId).source === "imported"))
                : false

              Button {
                visible: root.hostWidget
                  ? (root.hostWidget.presetPackByPresetId(root.hostWidget.selectedPresetId)
                    && root.hostWidget.presetPackByPresetId(root.hostWidget.selectedPresetId).source === "imported")
                  : false
                text: "Remove preset pack"
                width: Math.max(Style.space(126), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.removeSelectedPresetPack()
              }

              Button {
                visible: root.hostWidget
                  ? (root.hostWidget.temperamentPackByTemperamentId(root.hostWidget.selectedTemperamentId)
                    && root.hostWidget.temperamentPackByTemperamentId(root.hostWidget.selectedTemperamentId).source === "imported")
                  : false
                text: "Remove temperament pack"
                width: Math.max(Style.space(152), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.removeSelectedTemperamentPack()
              }
            }

            Rectangle {
              width: parent.width
              implicitHeight: Math.max(Style.space(180), contentPackTransferEditor.contentHeight + Style.space(16))
              radius: Style.cornerRadius
              color: Util.alpha(root.foreground, root.highContrast ? 0.10 : 0.05)
              border.width: 1
              border.color: Util.alpha(root.foreground, root.highContrast ? 0.48 : 0.22)

              TextEdit {
                id: contentPackTransferEditor
                anchors.fill: parent
                anchors.margins: Style.space(8)
                text: root.contentPackTransferText
                color: root.foreground
                font.family: "monospace"
                font.pixelSize: Style.font.caption
                wrapMode: TextEdit.WrapAnywhere
                selectByMouse: true
                selectByKeyboard: true
                persistentSelection: true
              }
            }

            Text {
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.contentPackTransferStatusText !== "" : false
              textFormat: Text.PlainText
              text: root.hostWidget ? root.hostWidget.contentPackTransferStatusText : ""
              color: root.hostWidget && root.hostWidget.contentPackTransferStatusError ? Color.urgent : Color.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Tuning preset"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Repeater {
              model: root.hostWidget ? root.hostWidget.tuningPresetGroups : []

              Column {
                required property var modelData

                width: parent.width
                spacing: Style.space(6)

                Text {
                  width: parent.width
                  textFormat: Text.PlainText
                  text: String(modelData.label || "")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                Grid {
                  id: presetGrid
                  width: parent.width
                  columns: root.presetColumns
                  rowSpacing: Style.space(6)
                  columnSpacing: Style.space(6)

                  Repeater {
                    model: Array.isArray(modelData.presets) ? modelData.presets : []

                    Button {
                      required property var modelData

                      width: (presetGrid.width - presetGrid.columnSpacing * Math.max(0, presetGrid.columns - 1)) / Math.max(1, presetGrid.columns)
                      text: String(modelData.label || "")
                      selected: root.hostWidget ? root.hostWidget.selectedPresetId === String(modelData.id || "") : false
                      bordered: true
                      foreground: root.foreground
                      fontFamily: root.fontFamily
                      fontSize: Style.font.bodySmall
                      verticalPadding: Style.space(7)
                      focusable: true
                      onClicked: if (root.hostWidget) root.hostWidget.selectPreset(String(modelData.id || ""))
                    }
                  }
                }
              }
            }
          }
        }

        Item {
          visible: root.activeDestination === "reference"
          width: parent.width
          height: visible ? referenceColumn.implicitHeight : 0

          Column {
            id: referenceColumn
            width: parent.width
            spacing: Style.space(10)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Text {
                width: Math.max(0, parent.width - playToneButton.implicitWidth - parent.spacing)
                textFormat: Text.PlainText
                text: "Tone"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                verticalAlignment: Text.AlignVCenter
              }

              Button {
                id: playToneButton
                text: root.hostWidget
                  ? (root.hostWidget.selectedReferenceToneActive
                    ? ("Stop " + root.hostWidget.selectedReferencePlaybackLabel)
                    : (root.hostWidget.toneActive
                      ? ("Retune to " + root.hostWidget.selectedReferencePlaybackLabel)
                      : ("Play " + root.hostWidget.selectedReferencePlaybackLabel)))
                  : "Play"
                selected: root.hostWidget ? root.hostWidget.selectedReferenceToneActive : false
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.toggleSelectedReferenceTone()
              }
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Mode"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            ButtonGroup {
              width: parent.width
              options: [
                { value: "single", label: "Single" },
                { value: "interval", label: "Interval" },
                { value: "chord", label: "Chord" },
              ]
              value: root.hostWidget ? root.hostWidget.referencePlaybackMode : "single"
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              onChanged: function(value) {
                if (root.hostWidget) root.hostWidget.setReferencePlaybackMode(value)
              }
            }

            Text {
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.referencePlaybackMode === "interval" : false
              textFormat: Text.PlainText
              text: "Interval"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Grid {
              id: intervalPresetGrid
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.referencePlaybackMode === "interval" : false
              columns: root.intervalOptionColumns
              rowSpacing: Style.space(6)
              columnSpacing: Style.space(6)

              Repeater {
                model: root.hostWidget ? root.hostWidget.referenceIntervalPresets : []

                Button {
                  required property var modelData

                  width: (intervalPresetGrid.width - intervalPresetGrid.columnSpacing * Math.max(0, intervalPresetGrid.columns - 1)) / Math.max(1, intervalPresetGrid.columns)
                  text: String(modelData.label || "")
                  selected: root.hostWidget ? root.hostWidget.selectedReferenceIntervalSemitones === Number(modelData.semitones) : false
                  bordered: true
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  fontSize: Style.font.bodySmall
                  verticalPadding: Style.space(7)
                  focusable: true
                  onClicked: if (root.hostWidget) root.hostWidget.setSelectedReferenceIntervalSemitones(Number(modelData.semitones))
                }
              }
            }

            Text {
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.referencePlaybackMode === "chord" : false
              textFormat: Text.PlainText
              text: "Chord"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Grid {
              id: chordPresetGrid
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.referencePlaybackMode === "chord" : false
              columns: root.toneOptionColumns
              rowSpacing: Style.space(8)
              columnSpacing: Style.space(8)

              Repeater {
                model: root.hostWidget ? root.hostWidget.referenceChordPresets : []

                Item {
                  required property var modelData

                  width: (chordPresetGrid.width - chordPresetGrid.columnSpacing * Math.max(0, chordPresetGrid.columns - 1)) / Math.max(1, chordPresetGrid.columns)
                  height: chordPresetOptionColumn.implicitHeight

                  Column {
                    id: chordPresetOptionColumn
                    width: parent.width
                    spacing: Style.space(4)

                    Button {
                      width: parent.width
                      text: String(modelData.label || "")
                      selected: root.hostWidget ? root.hostWidget.selectedReferenceChordId === String(modelData.id || "") : false
                      bordered: true
                      foreground: root.foreground
                      fontFamily: root.fontFamily
                      fontSize: Style.font.bodySmall
                      verticalPadding: Style.space(7)
                      focusable: true
                      onClicked: if (root.hostWidget) root.hostWidget.setSelectedReferenceChordId(String(modelData.id || ""))
                    }

                    Text {
                      width: parent.width
                      visible: text !== ""
                      textFormat: Text.PlainText
                      text: String(modelData.summary || "")
                      color: root.foreground
                      opacity: root.highContrast ? 1.0 : 0.78
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      wrapMode: Text.WordWrap
                    }
                  }
                }
              }
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Voicing"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Grid {
              id: scenePresetGrid
              width: parent.width
              columns: root.toneOptionColumns
              rowSpacing: Style.space(8)
              columnSpacing: Style.space(8)

              Repeater {
                model: root.hostWidget ? root.hostWidget.referenceScenePresets : []

                Item {
                  required property var modelData
                  readonly property string sceneId: String(modelData.id || "")
                  readonly property bool available: root.hostWidget ? root.hostWidget.referenceScenePresetEnabled(sceneId) : false

                  width: (scenePresetGrid.width - scenePresetGrid.columnSpacing * Math.max(0, scenePresetGrid.columns - 1)) / Math.max(1, scenePresetGrid.columns)
                  height: scenePresetOptionColumn.implicitHeight

                  Column {
                    id: scenePresetOptionColumn
                    width: parent.width
                    spacing: Style.space(4)

                    Button {
                      width: parent.width
                      text: String(modelData.label || "")
                      selected: root.hostWidget ? root.hostWidget.selectedReferenceSceneId === sceneId : false
                      bordered: true
                      enabled: parent.parent.available
                      opacity: enabled ? 1.0 : 0.5
                      foreground: root.foreground
                      fontFamily: root.fontFamily
                      fontSize: Style.font.bodySmall
                      verticalPadding: Style.space(7)
                      focusable: enabled
                      onClicked: if (root.hostWidget && enabled) root.hostWidget.setSelectedReferenceSceneId(sceneId)
                    }

                    Text {
                      width: parent.width
                      textFormat: Text.PlainText
                      text: root.hostWidget ? root.hostWidget.referenceScenePreviewSummary(sceneId) : ""
                      color: root.foreground
                      opacity: parent.parent.available ? (root.highContrast ? 1.0 : 0.78) : 0.58
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      wrapMode: Text.WordWrap
                    }
                  }
                }
              }
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Waveform"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Grid {
              id: waveformPresetGrid
              width: parent.width
              columns: root.toneOptionColumns
              rowSpacing: Style.space(8)
              columnSpacing: Style.space(8)

              Repeater {
                model: root.hostWidget ? root.hostWidget.referenceWaveformPresets : []

                Item {
                  required property var modelData
                  readonly property string waveformId: String(modelData.id || "")

                  width: (waveformPresetGrid.width - waveformPresetGrid.columnSpacing * Math.max(0, waveformPresetGrid.columns - 1)) / Math.max(1, waveformPresetGrid.columns)
                  height: waveformPresetOptionColumn.implicitHeight

                  Column {
                    id: waveformPresetOptionColumn
                    width: parent.width
                    spacing: Style.space(4)

                    Button {
                      width: parent.width
                      text: String(modelData.label || "")
                      selected: root.hostWidget ? root.hostWidget.selectedReferenceWaveformId === waveformId : false
                      bordered: true
                      foreground: root.foreground
                      fontFamily: root.fontFamily
                      fontSize: Style.font.bodySmall
                      verticalPadding: Style.space(7)
                      focusable: true
                      onClicked: if (root.hostWidget) root.hostWidget.setSelectedReferenceWaveformId(waveformId)
                    }

                    Text {
                      width: parent.width
                      textFormat: Text.PlainText
                      text: String(modelData.summary || "")
                      color: root.foreground
                      opacity: root.highContrast ? 1.0 : 0.78
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      wrapMode: Text.WordWrap
                    }
                  }
                }
              }
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Root note"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Grid {
              id: noteGrid
              width: parent.width
              columns: root.referenceGridColumns
              rowSpacing: Style.space(6)
              columnSpacing: Style.space(6)

              Repeater {
                model: root.hostWidget ? root.hostWidget.pitchClasses : []

                Button {
                  required property var modelData
                  required property int index

                  width: (noteGrid.width - noteGrid.columnSpacing * Math.max(0, noteGrid.columns - 1)) / Math.max(1, noteGrid.columns)
                  text: String(modelData)
                  selected: root.hostWidget ? root.hostWidget.selectedReferencePitchClassIndex === index : false
                  bordered: true
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  fontSize: Style.font.bodySmall
                  verticalPadding: Style.space(7)
                  focusable: true
                  onClicked: if (root.hostWidget) root.hostWidget.selectPitchClass(index)
                }
              }
            }

            Row {
              width: parent.width
              spacing: Style.space(6)

              Button {
                id: previousNoteButton
                width: Style.space(48)
                text: "<"
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.body
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.changeReferenceSemitone(-1)
              }

              BorderSurface {
                width: parent.width - previousNoteButton.width - nextNoteButton.width - parent.spacing * 2
                height: Math.max(previousNoteButton.implicitHeight, Style.space(34))
                radius: Style.cornerRadius
                color: Util.alpha(root.foreground, root.highContrast ? 0.10 : 0.05)
                borderSpec: Border.controlSpec(root.highContrast ? "focus" : "normal", root.foreground, Color.accent)

                Text {
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: root.hostWidget ? root.hostWidget.selectedReferenceNoteLabel : "A4"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
              }

              Button {
                id: nextNoteButton
                width: Style.space(48)
                text: ">"
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.body
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.changeReferenceSemitone(1)
              }
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Button {
                id: octaveDownButton
                text: "Oct-"
                width: Math.max(Style.space(58), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.changeReferenceOctave(-1)
              }

              Button {
                id: octaveUpButton
                text: "Oct+"
                width: Math.max(Style.space(58), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.changeReferenceOctave(1)
              }
            }
          }
        }

        Item {
          visible: root.activeDestination === "metronome"
          width: parent.width
          height: visible ? metronomeSection.implicitHeight : 0

          Column {
            id: metronomeSection
            width: parent.width
            spacing: Style.space(10)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Text {
                width: Math.max(0, parent.width - metronomeToggleButton.width - parent.spacing)
                textFormat: Text.PlainText
                text: "Metronome"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                verticalAlignment: Text.AlignVCenter
              }

              Button {
                id: metronomeToggleButton
                text: root.hostWidget && root.hostWidget.metronomeActive ? "Stop" : "Start"
                width: Math.max(Style.space(84), implicitWidth)
                selected: root.hostWidget ? root.hostWidget.metronomeActive : false
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.toggleMetronome()
              }
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Row {
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: root.hostWidget ? root.hostWidget.metronomeBeatsPerBar : 4

                Rectangle {
                  required property int index

                  width: index === 0 ? Style.space(28) : Style.space(22)
                  height: Style.space(22)
                  radius: Style.cornerRadius
                  color: root.hostWidget && root.hostWidget.metronomeBeatInBar === index + 1
                    ? Util.alpha(Color.accent, root.highContrast ? 0.34 : 0.22)
                    : Util.alpha(root.foreground, root.highContrast ? 0.10 : 0.06)
                  border.width: root.highContrast ? 1 : 0
                  border.color: root.hostWidget && root.hostWidget.metronomeBeatInBar === index + 1
                    ? Util.alpha(Color.accent, root.highContrast ? 0.92 : 0.62)
                    : Util.alpha(root.foreground, root.highContrast ? 0.44 : 0.22)

                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: String(index + 1)
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: index === 0 || (root.hostWidget ? root.hostWidget.metronomeBeatInBar === index + 1 : false)
                  }
                }
              }
            }

            Row {
              width: parent.width
              visible: root.hostWidget ? root.hostWidget.metronomeSubdivision > 1 : false
              spacing: Style.space(6)

              Repeater {
                model: root.hostWidget ? root.hostWidget.metronomeSubdivision : 1

                Rectangle {
                  required property int index

                  width: Style.space(18)
                  height: Style.space(10)
                  radius: height / 2
                  color: root.hostWidget && root.hostWidget.metronomeSubdivisionStep === index + 1
                    ? Util.alpha(Color.accent, root.highContrast ? 0.34 : 0.22)
                    : Util.alpha(root.foreground, root.highContrast ? 0.10 : 0.06)
                  border.width: root.highContrast ? 1 : 0
                  border.color: root.hostWidget && root.hostWidget.metronomeSubdivisionStep === index + 1
                    ? Util.alpha(Color.accent, root.highContrast ? 0.92 : 0.62)
                    : Util.alpha(root.foreground, root.highContrast ? 0.44 : 0.22)
                }
              }
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Button {
                text: "-1"
                width: Style.space(64)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.changeMetronomeBpm(-1)
              }

              Button {
                text: root.hostWidget ? (root.hostWidget.metronomeBpm + " BPM") : "100 BPM"
                width: Math.max(Style.space(90), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.resetMetronomeBpm()
              }

              Button {
                text: "+1"
                width: Style.space(64)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.changeMetronomeBpm(1)
              }

              Button {
                text: "Tap"
                width: Math.max(Style.space(70), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.tapMetronomeTempo()
              }
            }

            Column {
              id: metronomeControlsColumn
              width: parent.width
              spacing: Style.space(8)

              Text {
                width: parent.width
                textFormat: Text.PlainText
                text: "Meter"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }

              Flow {
                width: parent.width
                spacing: Style.space(6)

                Repeater {
                  model: root.hostWidget ? root.hostWidget.metronomeMeterPresets : []

                  Button {
                    required property var modelData

                    text: String(modelData.label || "")
                    selected: root.hostWidget
                      ? (root.hostWidget.metronomeBeatsPerBar === Number(modelData.beatsPerBar)
                        && root.hostWidget.metronomeBeatUnit === Number(modelData.beatUnit))
                      : false
                    bordered: true
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    fontSize: Style.font.bodySmall
                    verticalPadding: Style.space(7)
                    focusable: true
                    onClicked: if (root.hostWidget) root.hostWidget.setMetronomeMeter(Number(modelData.beatsPerBar), Number(modelData.beatUnit))
                  }
                }
              }

              Text {
                width: parent.width
                textFormat: Text.PlainText
                text: "Subdivision"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }

              Flow {
                width: parent.width
                spacing: Style.space(6)

                Repeater {
                  model: root.hostWidget ? root.hostWidget.metronomeSubdivisionPresets : []

                  Button {
                    required property var modelData

                    text: String(modelData.label || "")
                    selected: root.hostWidget ? root.hostWidget.metronomeSubdivision === Number(modelData.steps) : false
                    bordered: true
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    fontSize: Style.font.bodySmall
                    verticalPadding: Style.space(7)
                    focusable: true
                    onClicked: if (root.hostWidget) root.hostWidget.setMetronomeSubdivision(Number(modelData.steps))
                  }
                }
              }

          }
        }
        }

        Item {
          visible: root.activeDestination === "advanced"
          width: parent.width
          height: visible ? controlsColumn.implicitHeight : 0

          Column {
            id: controlsColumn
            width: parent.width
            spacing: Style.space(10)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Text {
                width: Math.max(0, parent.width - restartAudioButton.implicitWidth - parent.spacing)
                textFormat: Text.PlainText
                text: "Advanced"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                verticalAlignment: Text.AlignVCenter
              }

              Button {
                id: restartAudioButton
                text: "Restart audio"
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                enabled: root.hostWidget && root.hostWidget.helperState !== "starting"
                opacity: enabled ? 1.0 : 0.5
                onClicked: if (root.hostWidget) root.hostWidget.restartHelper()
              }
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Calibration"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Button {
                text: "-1"
                width: Style.space(64)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.changeReferenceA(-1)
              }

              Button {
                id: referenceAResetButton
                text: root.hostWidget ? ("A4 = " + root.hostWidget.formatReferenceA(root.hostWidget.referenceAHz)) : "A4 = 440.0 Hz"
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.resetReferenceA()
              }

              Button {
                text: "+1"
                width: Style.space(64)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.changeReferenceA(1)
              }

              Button {
                text: "440"
                width: Style.space(72)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.resetReferenceA()
              }
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Display"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Toggle {
              width: parent.width
              label: "High contrast"
              description: ""
              checked: root.hostWidget ? root.hostWidget.highContrastMode : false
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.hostWidget) root.hostWidget.toggleHighContrastMode()
            }

            Toggle {
              width: parent.width
              label: "Reduced motion"
              description: ""
              checked: root.hostWidget ? root.hostWidget.reducedMotionMode : false
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.hostWidget) root.hostWidget.toggleReducedMotionMode()
            }

            Toggle {
              width: parent.width
              label: "Analysis views"
              description: ""
              checked: root.hostWidget ? root.hostWidget.analysisViewsEnabled : false
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.hostWidget) root.hostWidget.toggleAnalysisViewsEnabled()
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Note spelling"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            ButtonGroup {
              width: parent.width
              options: [
                { value: "sharps", label: "Sharps" },
                { value: "flats", label: "Flats" },
              ]
              value: root.hostWidget ? root.hostWidget.noteSpelling : "sharps"
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              onChanged: function(value) {
                if (root.hostWidget) root.hostWidget.setNoteSpellingPreference(value)
              }
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Keyboard"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "External control"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Toggle {
              width: parent.width
              label: "MIDI input"
              description: ""
              checked: root.hostWidget ? root.hostWidget.midiInputEnabled : false
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.hostWidget) root.hostWidget.toggleMidiInputEnabled()
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Button {
                text: "Refresh MIDI ports"
                width: Math.max(Style.space(140), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.loadMidiInputPorts()
              }
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: root.hostWidget ? root.hostWidget.availableMidiInputPorts : []

                Button {
                  required property var modelData

                  text: String(modelData || "")
                  selected: root.hostWidget
                    ? root.hostWidget.normalizeMidiInputPortName(root.hostWidget.midiInputPortName) === String(modelData || "")
                    : false
                  bordered: true
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  fontSize: Style.font.bodySmall
                  verticalPadding: Style.space(7)
                  focusable: true
                  onClicked: if (root.hostWidget) root.hostWidget.setMidiInputPortName(String(modelData || ""))
                }
              }
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Advanced tuning"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Button {
                text: "-1"
                width: Style.space(64)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.changeTranspositionSemitones(-1)
              }

              Button {
                text: root.hostWidget ? root.hostWidget.transpositionLabelText : "Concert"
                width: Math.max(Style.space(120), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.resetTranspositionSemitones()
              }

              Button {
                text: "+1"
                width: Style.space(64)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: if (root.hostWidget) root.hostWidget.changeTranspositionSemitones(1)
              }
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: root.hostWidget ? root.hostWidget.transpositionPresets : []

                Button {
                  required property var modelData

                  text: String(modelData.label || "")
                  selected: root.hostWidget ? root.hostWidget.transpositionSemitones === Number(modelData.semitones) : false
                  bordered: true
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  fontSize: Style.font.bodySmall
                  verticalPadding: Style.space(7)
                  focusable: true
                  onClicked: if (root.hostWidget) root.hostWidget.setTranspositionSemitones(Number(modelData.semitones))
                }
              }
            }

            PanelSeparator {
              foreground: root.foreground
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Config transfer"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Button {
                text: "Load current"
                width: Math.max(Style.space(110), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: root.loadCurrentConfigurationText()
              }

              Button {
                text: "Apply import"
                width: Math.max(Style.space(110), implicitWidth)
                bordered: true
                foreground: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                focusable: true
                onClicked: root.applyImportedConfigurationText()
              }
            }

            Rectangle {
              width: parent.width
              implicitHeight: Math.max(Style.space(170), configTransferEditor.contentHeight + Style.space(16))
              radius: Style.cornerRadius
              color: Util.alpha(root.foreground, root.highContrast ? 0.10 : 0.05)
              border.width: 1
              border.color: Util.alpha(root.foreground, root.highContrast ? 0.48 : 0.22)

              TextEdit {
                id: configTransferEditor
                anchors.fill: parent
                anchors.margins: Style.space(8)
                text: ""
                color: root.foreground
                font.family: "monospace"
                font.pixelSize: Style.font.caption
                wrapMode: TextEdit.WrapAnywhere
                selectByMouse: true
                selectByKeyboard: true
                persistentSelection: true
              }
            }

            Text {
              width: parent.width
              visible: root.configTransferStatusText !== ""
              textFormat: Text.PlainText
              text: root.configTransferStatusText
              color: root.configTransferStatusError ? Color.urgent : Color.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
                }
              }
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Voice preview"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Flow {
              id: voicePreviewFlow
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: root.hostWidget ? root.hostWidget.selectedReferencePreviewVoiceLabels : []

                Rectangle {
                  required property var modelData

                  width: previewVoiceLabel.implicitWidth + Style.space(16)
                  height: previewVoiceLabel.implicitHeight + Style.space(10)
                  radius: height / 2
                  color: Util.alpha(Color.accent, root.highContrast ? 0.24 : 0.16)
                  border.width: root.highContrast ? 1 : 0
                  border.color: Util.alpha(Color.accent, root.highContrast ? 0.90 : 0.0)

                  Text {
                    id: previewVoiceLabel
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: String(modelData)
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }
                }
              }
            }
          }
        }
  }
}
