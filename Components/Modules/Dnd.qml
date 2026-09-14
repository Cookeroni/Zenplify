import QtQuick
import QtQuick.Layouts
import qs
import qs.Utils

// Zen Mode: toggles Quickshell's own do-not-disturb. When on, notifications
// are collected silently into the center with no on-screen toast.
Rectangle {
    id: root

    property bool tileHidden: false
    readonly property bool dnd: Notifications.dnd

    implicitWidth: 120
    implicitHeight: 50
    radius: 8
    color: Theme.panelScrim
    visible: !tileHidden

    MouseArea {
        anchors.fill: parent
        onClicked: Notifications.dnd = !Notifications.dnd
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
