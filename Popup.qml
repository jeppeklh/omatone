import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property var bar: null
  property Item anchorItem: null
  property var hostWidget: null
  property bool opened: false
  property bool popoutSwitchClosing: false

  readonly property color foreground: root.bar ? root.bar.foreground : Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property real popupMaxWidth: Style.space(430)
  readonly property real popupMaxHeight: Style.space(560)

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

  PopupCard {
    id: popup
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root.hostWidget || root
    open: root.opened
    contentWidth: popup.fittedContentWidth(Style.space(390), root.popupMaxWidth)
    contentHeight: popup.fittedContentHeight(contentColumn.implicitHeight, root.popupMaxHeight)

    Column {
      id: contentColumn
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        width: parent.width
        spacing: Style.space(8)

        Text {
          width: Math.max(0, parent.width - controlRow.implicitWidth - parent.spacing)
          textFormat: Text.PlainText
          text: "Omatune"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.subtitle
          font.bold: true
          elide: Text.ElideRight
          anchors.verticalCenter: controlRow.verticalCenter
        }

        Row {
          id: controlRow
          spacing: Style.space(6)

          Button {
            text: root.hostWidget && (root.hostWidget.helperState === "inactive" || root.hostWidget.helperState === "error") ? "Turn on" : "Turn off"
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            bordered: true
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
            enabled: root.hostWidget && root.hostWidget.helperState !== "starting"
            opacity: enabled ? 1.0 : 0.5
            onClicked: if (root.hostWidget) root.hostWidget.restartHelper()
          }
        }
      }

      Rectangle {
        id: readoutCard
        width: parent.width
        height: readoutColumn.implicitHeight + Style.space(14) * 2
        radius: Style.cornerRadius * 2
        color: root.hostWidget && root.hostWidget.inTune
          ? Util.alpha(Color.accent, 0.16)
          : (root.hostWidget && root.hostWidget.toneActive
            ? Util.alpha(Color.accent, 0.08)
            : Util.alpha(root.foreground, 0.06))
        border.width: root.hostWidget && (root.hostWidget.inTune || root.hostWidget.toneActive) ? Math.max(1, Style.normalBorderWidth) : 0
        border.color: root.hostWidget && root.hostWidget.inTune
          ? Util.alpha(Color.accent, 0.65)
          : Util.alpha(root.foreground, 0.35)

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
            height: Style.space(22)
            radius: Style.cornerRadius
            color: Util.alpha(root.foreground, 0.1)

            Rectangle {
              width: Math.max(2, meter.width * 0.1)
              height: parent.height
              radius: parent.radius
              anchors.horizontalCenter: parent.horizontalCenter
              color: root.hostWidget && root.hostWidget.inTune
                ? Util.alpha(Color.accent, 0.3)
                : Util.alpha(root.foreground, 0.12)
            }

            Rectangle {
              width: 1
              height: parent.height
              anchors.horizontalCenter: parent.horizontalCenter
              color: Util.alpha(root.foreground, 0.45)
            }

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.space(6)
              textFormat: Text.PlainText
              text: "b"
              color: root.foreground
              opacity: 0.4
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.rightMargin: Style.space(6)
              textFormat: Text.PlainText
              text: "#"
              color: root.foreground
              opacity: 0.4
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Rectangle {
              width: Style.space(3)
              height: parent.height
              radius: width / 2
              visible: root.hostWidget ? root.hostWidget.pitchActive : false
              color: root.hostWidget && root.hostWidget.inTune ? Color.accent : Color.urgent
              x: root.hostWidget
                ? Math.max(0, Math.min(meter.width - width, (meter.width - width) * (Math.max(-50, Math.min(50, root.hostWidget.detectedCents)) + 50) / 100))
                : 0

              Behavior on x {
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
            opacity: 0.88
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }
        }

        Behavior on color {
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
        opacity: root.hostWidget && root.hostWidget.hasAlert ? 1.0 : 0.74
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      Text {
        width: parent.width
        visible: root.hostWidget ? root.hostWidget.detailText !== "" : false
        textFormat: Text.PlainText
        text: root.hostWidget ? root.hostWidget.detailText : ""
        color: Qt.darker(root.foreground, 1.3)
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
        text: "Guitar shortcuts"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Grid {
        id: guitarGrid
        width: parent.width
        columns: 3
        rowSpacing: Style.space(6)
        columnSpacing: Style.space(6)

        Repeater {
          model: root.hostWidget ? root.hostWidget.guitarShortcuts : []

          Button {
            required property var modelData

            width: (guitarGrid.width - guitarGrid.columnSpacing * Math.max(0, guitarGrid.columns - 1)) / Math.max(1, guitarGrid.columns)
            text: String(modelData)
            selected: root.hostWidget ? root.hostWidget.selectedReferenceNoteLabel === String(modelData) : false
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            verticalPadding: Style.space(7)
            onClicked: if (root.hostWidget) root.hostWidget.playReferenceNoteString(String(modelData))
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

      Grid {
        id: noteGrid
        width: parent.width
        columns: 4
        rowSpacing: Style.space(6)
        columnSpacing: Style.space(6)

        Repeater {
          model: root.hostWidget ? root.hostWidget.pitchClasses : []

          Button {
            required property var modelData

            width: (noteGrid.width - noteGrid.columnSpacing * Math.max(0, noteGrid.columns - 1)) / Math.max(1, noteGrid.columns)
            text: String(modelData)
            selected: root.hostWidget ? root.hostWidget.selectedPitchClass === String(modelData) : false
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            verticalPadding: Style.space(7)
            onClicked: if (root.hostWidget) root.hostWidget.selectPitchClass(String(modelData))
          }
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(6)

        Button {
          id: octaveDownButton
          width: Style.space(48)
          text: "-"
          bordered: true
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.body
          onClicked: if (root.hostWidget) root.hostWidget.changeReferenceOctave(-1)
        }

        BorderSurface {
          width: parent.width - octaveDownButton.width - octaveUpButton.width - parent.spacing * 2
          height: Math.max(octaveDownButton.implicitHeight, Style.space(34))
          radius: Style.cornerRadius
          color: Util.alpha(root.foreground, 0.05)
          borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)

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
          id: octaveUpButton
          width: Style.space(48)
          text: "+"
          bordered: true
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.body
          onClicked: if (root.hostWidget) root.hostWidget.changeReferenceOctave(1)
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(6)

        Button {
          width: (parent.width - parent.spacing) / 2
          text: root.hostWidget ? ("Play " + root.hostWidget.selectedReferenceNoteLabel) : "Play"
          selected: root.hostWidget ? root.hostWidget.toneActive : false
          bordered: true
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.bodySmall
          onClicked: if (root.hostWidget) root.hostWidget.playSelectedTone()
        }

        Button {
          width: (parent.width - parent.spacing) / 2
          text: "Stop tone"
          bordered: true
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.bodySmall
          enabled: root.hostWidget ? root.hostWidget.toneActive : false
          opacity: enabled ? 1.0 : 0.5
          onClicked: if (root.hostWidget) root.hostWidget.stopTone()
        }
      }
    }
  }
}
