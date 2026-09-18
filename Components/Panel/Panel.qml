import QtQuick
import QtQuick.Layouts
import qs
import qs.Utils

import "../Modules/"

import "../../Utils/audioHelpers.js" as AudioHelpers
import "../../Utils/brightnessHelpers.js" as BrightnessHelpers



Item {
    id: panelContent

    property var pill
    property bool needsKeyboard: wifiModule.passwordPrompt || personalizationModule.needsKeyboard
    property bool showCalendar: false

    visible: pill.isExpanded

    anchors.fill: parent

    // Closes all list views when closing the Panel
    Connections {
        function onIsExpandedChanged() {
            if (!pill.isExpanded) {
                // Add Future Modules Here
                wifiModule.showList = false
                wifiModule.pendingSsid = ""
                bluetoothModule.showList = false
                bluetoothModule.pendingMac = ""
                audioModule.showList = false
                batteryModule.showList = false
                clipboardModule.showList = false
                powerMenu.expanded = false
                panelContent.showCalendar = false
                systemMonitor.show = false
                personalizationModule.show = false
            }
        }
        target: pill
    }

    // Text Header (Ex: Wifi, Bluetooth, Control Panel)
    Header {
        id: header
        pill: panelContent.pill
        wifi: wifiModule
        bt: bluetoothModule
        audioSink: audioModule
        batt: batteryModule
        clipb: clipboardModule
        sysmon: systemMonitor
        personalization: personalizationModule
        onDateClicked: panelContent.showCalendar = !panelContent.showCalendar
    }

    Wifi {
        id: wifiModule
        tileHidden: bluetoothModule.showList || audioModule.showList || batteryModule.showList || clipboardModule.showList || systemMonitor.show || personalizationModule.show

        anchors {
            left: parent.left
            leftMargin: 12
            top: header.bottom
            topMargin: 20
        }
    }

    Bluetooth {
        id: bluetoothModule
        tileHidden: wifiModule.showList || audioModule.showList || batteryModule.showList || clipboardModule.showList || systemMonitor.show || personalizationModule.show

        anchors {
            left: bluetoothModule.showList ? parent.left : wifiModule.right
            leftMargin: 8
            top: header.bottom
            topMargin: 20
        }
    }

    AudioSink {
        id: audioModule
        tileHidden: wifiModule.showList || bluetoothModule.showList || batteryModule.showList || clipboardModule.showList || systemMonitor.show || personalizationModule.show

        anchors {
            left: audioModule.showList ? parent.left : bluetoothModule.right
            leftMargin: 8
            top: header.bottom
            topMargin: 20
        }
    }

    Battery {
        id: batteryModule
        tileHidden: wifiModule.showList || bluetoothModule.showList || audioModule.showList || clipboardModule.showList || systemMonitor.show || personalizationModule.show

        anchors {
            left: parent.left
            leftMargin: 12
            top: batteryModule.showList ? header.bottom : wifiModule.bottom
            topMargin: 10
        }
    }

    Dnd {
        id: dndModule
        tileHidden: wifiModule.showList || bluetoothModule.showList || audioModule.showList || batteryModule.showList || clipboardModule.showList || systemMonitor.show || personalizationModule.show

        anchors {
            left: batteryModule.right
            leftMargin: 8
            top: bluetoothModule.bottom
            topMargin: 10
        }
    }

    Nightlight {
        id: nightModule

        tileHidden: wifiModule.showList || bluetoothModule.showList || audioModule.showList || batteryModule.showList || clipboardModule.showList

        anchors {
            left: dndModule.right
            leftMargin: 8
            top: bluetoothModule.bottom
            topMargin: 10
        }
    }

    Clipboard {
        id: clipboardModule
        tileHidden: wifiModule.showList || bluetoothModule.showList || audioModule.showList || batteryModule.showList || systemMonitor.show || personalizationModule.show

        anchors {
            left: clipboardModule.showList ? parent.left : nightModule.right
            leftMargin: 8
            top: clipboardModule.showList ? header.bottom : wifiModule.bottom
            topMargin: 10
        }
    }

    // Volume + Brightness sliders
    ColumnLayout {
        id: sliders
        anchors.top: batteryModule.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 20
        spacing: 10
        visible: !(wifiModule.showList || bluetoothModule.showList || audioModule.showList || clipboardModule.showList || batteryModule.showList || systemMonitor.show || personalizationModule.show)

        PanelSlider {
            Layout.fillWidth: true
            value: Audio.volume
            icon: AudioHelpers.volumeIcon(Audio.volume, Audio.muted)
            onMoved: (v) => Audio.setVolume(v)
        }

        PanelSlider {
            Layout.fillWidth: true
            value: Backlight.value
            icon: BrightnessHelpers.icon(Backlight.value)
            onMoved: (v) => Backlight.setPercent(v * 100)
        }
    }

    // Now-playing (Spotify) card — pinned to the bottom of the panel
    MediaPlayer {
        id: mediaModule
        visible: Player.hasTrack && !(wifiModule.showList || bluetoothModule.showList || audioModule.showList || batteryModule.showList || clipboardModule.showList)
        anchors {
            top: sliders.bottom
            left: parent.left
            right: parent.right
            topMargin: 20
            leftMargin: 16
            rightMargin: 16
        }
    }

    //Power menu (bottom-left)
    PowerMenu {
        id: powerMenu
        visible: !(wifiModule.showList || bluetoothModule.showList || audioModule.showList || batteryModule.showList || clipboardModule.showList)
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: 16
            bottomMargin: 16
        }
    }

    // System monitors trigger (bottom-right, mirrors the power menu)
    Rectangle {
        id: monitorButton
        visible: !systemMonitor.show && !(wifiModule.showList || bluetoothModule.showList || audioModule.showList || batteryModule.showList || clipboardModule.showList)
        width: 40
        height: 36
        radius: 18
        color: Theme.pillBg
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 16
            bottomMargin: 16
        }

        Text {
            anchors.centerIn: parent
            text: ""
            color: monBtnMa.containsMouse ? Theme.textPrimary : Theme.textSecondary
            font { family: Theme.fontFamily; pixelSize: 18 }
        }
        MouseArea {
            id: monBtnMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: systemMonitor.show = true
        }
    }

    // Personalization trigger (bottom-right, left of the system-monitor button)
    Rectangle {
        id: personalizationButton
        visible: !personalizationModule.show && !systemMonitor.show
                && !(wifiModule.showList || bluetoothModule.showList || audioModule.showList
                    || batteryModule.showList || clipboardModule.showList)
        width: 40
        height: 36
        radius: 18
        color: Theme.pillBg
        anchors { right: monitorButton.left; bottom: parent.bottom; rightMargin: 8; bottomMargin: 16 }

        Text {
            anchors.centerIn: parent
            text: "󰏘"          // md-palette
            color: personBtnMa.containsMouse ? Theme.textPrimary : Theme.textSecondary
            font { family: Theme.fontFamily; pixelSize: 18 }
        }
        MouseArea {
            id: personBtnMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: personalizationModule.show = true
        }
    }

    // Personalization takeover — twin of the system-monitor takeover
    Personalization {
        id: personalizationModule
        z: 50
        anchors {
            top: header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom
            topMargin: 16; leftMargin: 16; rightMargin: 16; bottomMargin: 16
        }
    }

    //System monitors takeover — fills the body below the header when shown
    SystemMonitor {
        id: systemMonitor
        z: 50
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: 16
            leftMargin: 16
            rightMargin: 16
            bottomMargin: 16
        }
    }

    // ---- Calendar overlay ----
    Item {
        anchors.fill: parent
        visible: panelContent.showCalendar
        z: 100

        // Dim + click-away to close
        Rectangle {
            anchors.fill: parent
            color: "#99000000"
            radius: 24
            MouseArea {
                anchors.fill: parent
                onClicked: panelContent.showCalendar = false
            }
        }

        // Card
        Rectangle {
            anchors.centerIn: parent
            width: 320
            height: calendar.implicitHeight + 32
            radius: 16
            color: Theme.panelScrim

            // Absorb clicks so tapping the card doesn't close it
            MouseArea { anchors.fill: parent }

            Calendar {
                id: calendar
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 16
                }
            }
        }
    }
}
