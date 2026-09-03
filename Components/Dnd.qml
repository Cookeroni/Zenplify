import Quickshell
import QtQuick
import Quickshell.Io
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    property bool tileHidden: false

    // True when mako's "do-not-disturb" mode is active. Sourced from mako,
    property bool dnd: false

    implicitWidth: 125
    implicitHeight: 50
    radius: 8
    color: Theme.panelScrim
    visible: !tileHidden

    // Re-read state whenever the tile becomes visible (e.g. panel opens),
    // so it's correct even if DND was changed elsewhere while closed.
    onVisibleChanged: if (visible) dndQuery.running = true

    Component.onCompleted: dndQuery.running = true

    // ============================ STATE I/O ==========================

    // Reads active modes. mako prints one mode per line; DND is on if
    // "do-not-disturb" is among them.
    Process {
        id: dndQuery

        command: ["makoctl", "mode"]

        stdout: StdioCollector {
            onStreamFinished: {
                const modes = text.trim().split("\n");
                root.dnd = modes.indexOf("do-not-disturb") !== -1;
            }
        }
    }

    // Toggles the mode, then re-queries so the tile reflects the real
    // post-toggle state rather than an optimistic guess.
    Process {
        id: dndToggle

        command: ["makoctl", "mode", "-t", "do-not-disturb"]

        onExited: (code, status) => dndQuery.running = true
    }

    // Optional: keep the tile honest against external keybind toggles while
    // the panel is open. Comment out if you don't want the periodic poll.
    // Timer {
    //     interval: 2000
    //     repeat: true
    //     running: root.visible
    //     onTriggered: dndQuery.running = true
    // }

    // ============================== TILE =============================

    MouseArea {
        anchors.fill: parent
        onClicked: dndToggle.running = true
    }

    // Icon & Label
    RowLayout {
        anchors { fill: parent; margins: 6 }
        spacing: 8

        // Icon
        Item {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                color: root.dnd ? Theme.textPrimary : Theme.textMuted

                font {
                    family: Theme.fontFamily
                    pixelSize: 22
                }

                // Spin the glyph around the fixed container's center
                //rotation: root.dnd ? 160 : -40

                Behavior on rotation {
                    NumberAnimation { duration: 200 }
                }

                text: "󰚀"
            }
        }
        

        // Label + state
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                color: Theme.textPrimary
                elide: Text.ElideRight

                font {
                    family: Theme.fontFamily
                    pixelSize: 15
                }

                text: "Zen Mode"
            }

            Text {
                color: Theme.textSecondary

                font {
                    family: Theme.fontFamily
                    pixelSize: 13
                }

                text: root.dnd ? "On" : "Off"
            }
        }
    }

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
}