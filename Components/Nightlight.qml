import Quickshell
import QtQuick
import Quickshell.Io
import QtQuick.Layouts
import qs

Item {
    id: root

    implicitWidth: tileView.width
    implicitHeight: tileView.height

    property bool tileHidden: false

    // Color temperature in Kelvin when on. Lower = warmer.
    //   ~4500 mild · 4000 comfortable (default) · 3400 strong · 2700 very warm
    property int temperature: 4500

    // State == process running
    readonly property bool enabled: gammaProc.running

    function toggle() { gammaProc.running = !gammaProc.running; }

    // Gammastep Command to set screen temperature (Refer to Gammastep Documentation for more info)
    Process {
        id: gammaProc
        command: ["gammastep", "-m", "wayland", "-P", "-O", String(root.temperature)]
    }

    // ============================ TILE VIEW ==========================
    Rectangle {
        id: tileView

        width: 90
        height: 50
        radius: 8
        visible: root.tileHidden ? false : true
        color: Theme.panelScrim

        MouseArea {
            anchors.fill: parent
            onClicked: root.toggle()
        }

        // ICon & Label
        RowLayout {
            anchors { fill: parent; margins: 2 }
            spacing: 3

            // Icon
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                color: "transparent"

                Text {
                    anchors { centerIn: parent }
                    color: root.enabled ? Theme.textPrimary : Theme.textMuted  

                    font {
                        pixelSize: 20
                        family: Theme.fontFamily
                    }

                    text: "󰖔"
                }
            }

             // Label + Status
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Lamp"
                    Layout.fillWidth: true
                    color: Theme.textPrimary 

                    font {
                        pixelSize: 15
                        family: Theme.fontFamily
                    }
                }

                Text {
                    text: root.enabled ? "On" : "Off"
                    Layout.fillWidth: true
                    color: Theme.textSecondary

                    font {
                        pixelSize: 13
                        family: Theme.fontFamily
                    }
                }
            }
        }
    }
}