import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: panelContent

    // Signals an active password field to request window keyboard focus. (Implement soon)
    property bool needsKeyboard: false
    //readonly property bool needsKeyboard: wifiModule.passwordPrompt  // use this when wifi module is available

    // Reference to the Pill.qml root (passed in, since ids don't cross files).
    property var pill

    visible: pill.isExpanded

    anchors.fill: parent

    // Closes all list view when closing the Panel
    Connections {
        function onIsExpandedChanged() {
            if (!pill.isExpanded) {
               // Add Future Modules Here
            }
        }
        target: pill
    }

    // Text Header (Ex: Wifi, Bluetooth, Control Panel)
    Header {
        id: header
        pill: panelContent.pill
    }    
}