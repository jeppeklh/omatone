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

  readonly property color foreground: root.bar ? root.bar.foreground : Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property bool verticalBar: root.hostWidget ? root.hostWidget.vertical : false
  readonly property bool expandedLayout: root.hostWidget ? root.hostWidget.popupExpanded : false
  readonly property bool highContrast: root.hostWidget ? root.hostWidget.highContrastMode : false
  readonly property bool reducedMotion: root.hostWidget ? root.hostWidget.reducedMotionMode : false
  readonly property real preferredContentWidth: expandedLayout
    ? (verticalBar ? Style.space(360) : Style.space(470))
    : (verticalBar ? Style.space(340) : Style.space(392))
  readonly property real popupMaxWidth: verticalBar ? Style.space(400) : Style.space(540)
  readonly property real popupMaxHeight: Style.space(620)
  readonly property int quickNoteColumns: verticalBar ? 2 : 3
  readonly property int presetColumns: verticalBar ? 1 : 2
  readonly property int referenceGridColumns: verticalBar ? 3 : 4
  readonly property color quietTextColor: highContrast ? root.foreground : Qt.darker(root.foreground, 1.3)
  readonly property real secondaryTextOpacity: highContrast ? 0.92 : 0.74
  readonly property string keyboardHintText: root.hostWidget ? root.hostWidget.keyboardShortcutSummary : ""

  function open() {
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

  function focusInitialControl() {
    if (!opened) return

    var target = quickNoteRepeater.count > 0 ? quickNoteRepeater.itemAt(0) : null
    if (!target) target = playToneButton
    if (!target) target = powerButton
    if (target && target.forceActiveFocus) target.forceActiveFocus()
  }

  onOpenedChanged: {
    if (opened) Qt.callLater(root.focusInitialControl)
  }

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

  PopupCard {
    id: popup
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root.hostWidget || root
    open: root.opened
    contentWidth: popup.fittedContentWidth(root.preferredContentWidth, root.popupMaxWidth)
    contentHeight: popup.fittedContentHeight(contentColumn.implicitHeight, root.popupMaxHeight)

    Flickable {
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
          spacing: Style.space(6)

          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: "Omatune"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: root.hostWidget ? root.hostWidget.selectedPresetLabel : ""
            color: root.foreground
            opacity: root.secondaryTextOpacity
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Flow {
            width: parent.width
            spacing: Style.space(6)

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

            Button {
              text: "Restart"
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              focusable: true
              enabled: root.hostWidget && root.hostWidget.helperState !== "starting"
              opacity: enabled ? 1.0 : 0.5
              onClicked: if (root.hostWidget) root.hostWidget.restartHelper()
            }

            Button {
              text: root.hostWidget && root.hostWidget.popupExpanded ? "Compact" : "Expanded"
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              focusable: true
              onClicked: if (root.hostWidget) root.hostWidget.togglePopupLayoutMode()
            }
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
              : (root.hostWidget && root.hostWidget.toneActive
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
                : (root.hostWidget && (root.hostWidget.inTune || root.hostWidget.toneActive)
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
                : (root.hostWidget && (root.hostWidget.inTune || root.hostWidget.toneActive)
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
                opacity: root.secondaryTextOpacity
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: root.highContrast
              }

              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: "OK"
                color: root.foreground
                opacity: root.secondaryTextOpacity
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
                opacity: root.secondaryTextOpacity
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

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.hostWidget ? root.hostWidget.statusText : ""
          color: root.hostWidget && root.hostWidget.hasAlert ? Color.urgent : root.foreground
          opacity: root.hostWidget && root.hostWidget.hasAlert ? 1.0 : root.secondaryTextOpacity
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: root.highContrast && root.hostWidget && root.hostWidget.pitchActive
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          visible: keyboardHintText !== ""
          textFormat: Text.PlainText
          text: keyboardHintText
          color: root.quietTextColor
          opacity: root.secondaryTextOpacity
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          visible: root.hostWidget ? root.hostWidget.detailText !== "" : false
          textFormat: Text.PlainText
          text: root.hostWidget ? root.hostWidget.detailText : ""
          color: root.quietTextColor
          opacity: root.secondaryTextOpacity
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
          text: root.hostWidget ? root.hostWidget.quickTuneHeadingText : "Quick tune"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.hostWidget ? (root.hostWidget.referencePlaybackMode === "drone"
            ? "Quick notes reuse the current drone interval. Use Left/Right to move the root and [ or ] to change the interval."
            : (root.hostWidget.referencePlaybackMode === "chord"
              ? "Quick notes reuse the current chord shape. Use Left/Right to move the root and [ or ] to change the chord."
              : (root.hostWidget.standardGuitarPresetSelected
                ? "Press 1-6 for the standard string references. Use Left/Right to step chromatically."
                : "Preset notes stay one keypress away. Use Left/Right to step chromatically."))) : ""
          color: root.quietTextColor
          opacity: root.secondaryTextOpacity
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Grid {
          id: quickNoteGrid
          width: parent.width
          columns: root.quickNoteColumns
          rowSpacing: Style.space(6)
          columnSpacing: Style.space(6)

          Repeater {
            id: quickNoteRepeater
            model: root.hostWidget ? root.hostWidget.selectedPresetNotes.slice(0, 6) : []

            Button {
              required property var modelData
              required property int index

              width: (quickNoteGrid.width - quickNoteGrid.columnSpacing * Math.max(0, quickNoteGrid.columns - 1)) / Math.max(1, quickNoteGrid.columns)
              text: root.hostWidget ? ((index + 1) + "  " + root.hostWidget.displayNoteLabel(String(modelData))) : String(modelData)
              selected: root.hostWidget ? root.hostWidget.sameNoteText(root.hostWidget.selectedReferenceCommandNoteLabel, String(modelData)) : false
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              verticalPadding: Style.space(8)
              focusable: true
              onClicked: if (root.hostWidget) root.hostWidget.playReferenceNoteString(String(modelData))
            }
          }
        }

        Item {
          visible: root.expandedLayout
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
                  opacity: root.secondaryTextOpacity
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

        PanelSeparator {
          foreground: root.foreground
        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: "Reference tone"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }

        ButtonGroup {
          width: parent.width
          options: [
            { value: "single", label: "Single" },
            { value: "drone", label: "Drone" },
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
          visible: root.hostWidget ? root.hostWidget.referencePlaybackMode === "drone" : false
          textFormat: Text.PlainText
          text: root.hostWidget
            ? ("Drone keeps " + root.hostWidget.selectedReferenceNoteLabel + " sounding and adds one note above it.")
            : ""
          color: root.quietTextColor
          opacity: root.secondaryTextOpacity
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Flow {
          width: parent.width
          visible: root.hostWidget ? root.hostWidget.referencePlaybackMode === "drone" : false
          spacing: Style.space(6)

          Repeater {
            model: root.hostWidget ? root.hostWidget.referenceIntervalPresets : []

            Button {
              required property var modelData

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
          text: root.hostWidget
            ? ("Chord keeps " + root.hostWidget.selectedReferenceNoteLabel + " as the root and adds a fixed preset shape above it.")
            : ""
          color: root.quietTextColor
          opacity: root.secondaryTextOpacity
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Flow {
          width: parent.width
          visible: root.hostWidget ? root.hostWidget.referencePlaybackMode === "chord" : false
          spacing: Style.space(6)

          Repeater {
            model: root.hostWidget ? root.hostWidget.referenceChordPresets : []

            Button {
              required property var modelData

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
          }
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

          Button {
            id: playToneButton
            text: root.hostWidget
              ? (root.hostWidget.selectedReferenceToneActive
                ? ("Stop " + root.hostWidget.selectedReferenceSceneLabel)
                : (root.hostWidget.toneActive
                  ? ("Retune to " + root.hostWidget.selectedReferenceSceneLabel)
                  : ("Play " + root.hostWidget.selectedReferenceSceneLabel)))
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

        Item {
          visible: root.expandedLayout
          width: parent.width
          height: visible ? controlsColumn.implicitHeight : 0

          Column {
            id: controlsColumn
            width: parent.width
            spacing: Style.space(10)

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

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: "Use the center button for a fast reset to concert pitch."
              color: root.quietTextColor
              opacity: root.secondaryTextOpacity
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
              text: "Display"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            ButtonGroup {
              width: parent.width
              options: [
                { value: "compact", label: "Compact" },
                { value: "expanded", label: "Expanded" },
              ]
              value: root.hostWidget ? root.hostWidget.popupLayoutMode : "compact"
              foreground: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              onChanged: function(value) {
                if (root.hostWidget) root.hostWidget.setPopupLayoutMode(value)
              }
            }

            Toggle {
              width: parent.width
              label: "High contrast"
              description: "Use stronger borders and text emphasis for legibility across themes."
              checked: root.hostWidget ? root.hostWidget.highContrastMode : false
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.hostWidget) root.hostWidget.toggleHighContrastMode()
            }

            Toggle {
              width: parent.width
              label: "Reduced motion"
              description: "Keep the meter and card transitions calmer while preserving tuner responsiveness."
              checked: root.hostWidget ? root.hostWidget.reducedMotionMode : false
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.hostWidget) root.hostWidget.toggleReducedMotionMode()
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
          }
        }
      }
    }
  }
}
