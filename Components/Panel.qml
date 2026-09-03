import QtQuick
import QtQuick.Layouts
import qs.Utils
import "../Utils/audioHelpers.js" as AudioHelpers
import "../Utils/brightnessHelpers.js" as BrightnessHelpers

Item {
    id: panelContent

    property var pill
    property bool needsKeyboard: wifiModule.passwordPrompt

    visible: pill.isExpanded

    anchors.fill: parent

    // Closes all list views when closing the Panel
    Connections {
        function onIsExpandedChanged() {
            if (!pill.isExpanded) {
                // Add Future Modules Here
                wifiModule.showList = false;
                wifiModule.pendingSsid = "";
                bluetoothModule.showList = false;
                bluetoothModule.pendingMac = "";
                audioModule.showList = false;
                batteryModule.showList = false;
                clipboardModule.showList = false;
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
    }

    Wifi {
        id: wifiModule
        tileHidden: bluetoothModule.showList || audioModule.showList || batteryModule.showList || clipboardModule.showList
        anchors {
            left: parent.left
            leftMargin: 12
            top: header.bottom
            topMargin: 20
        }
    }

    Bluetooth {
        id: bluetoothModule
        tileHidden: wifiModule.showList || audioModule.showList || batteryModule.showList || clipboardModule.showList

        anchors {
            left: bluetoothModule.showList ? parent.left : wifiModule.right
            leftMargin: 8
            top: header.bottom
            topMargin: 20
        }
    }

    AudioSink {
        id: audioModule
        tileHidden: wifiModule.showList || bluetoothModule.showList || batteryModule.showList || clipboardModule.showList

        anchors {
            left: audioModule.showList ? parent.left : bluetoothModule.right
            leftMargin: 8
            top: header.bottom
            topMargin: 20
        }
    }

    Battery {
        id: batteryModule
        tileHidden: wifiModule.showList || bluetoothModule.showList || audioModule.showList || clipboardModule.showList

        anchors {
            left: parent.left
            leftMargin: 12
            top: batteryModule.showList ? header.bottom : wifiModule.bottom
            topMargin: 10
        }
    }

    Dnd {
        id: dndModule
        tileHidden: wifiModule.showList || bluetoothModule.showList || audioModule.showList || batteryModule.showList || clipboardModule.showList

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
        tileHidden: wifiModule.showList || bluetoothModule.showList || audioModule.showList || batteryModule.showList

        anchors {
            left: clipboardModule.showList ? parent.left : nightModule.right
            leftMargin: 8
            top: clipboardModule.showList ? header.bottom : wifiModule.bottom
            topMargin: 10
        }
    }

    // Volume + Brightness sliders
    ColumnLayout {
        anchors.top: batteryModule.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 16
        spacing: 10
        visible: !(wifiModule.showList || bluetoothModule.showList || audioModule.showList || clipboardModule.showList)

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
}
