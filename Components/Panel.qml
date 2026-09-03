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
    }

    Wifi {
        id: wifiModule
        tileHidden: bluetoothModule.showList 
        anchors {
            left: parent.left
            leftMargin: 12
            top: header.bottom
            topMargin: 20
        }
    }

    Bluetooth {
        id: bluetoothModule
        tileHidden: wifiModule.showList 

        anchors {
            left: bluetoothModule.showList ? parent.left : wifiModule.right
            leftMargin: 8
            top: header.bottom
            topMargin: 20
        }
    }

    // Volume + Brightness sliders
    ColumnLayout {
        anchors.top: wifiModule.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 16
        spacing: 10
        visible: !(wifiModule.showList || bluetoothModule.showList)

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
