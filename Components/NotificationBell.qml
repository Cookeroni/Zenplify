import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.Utils

// Small top-right trigger for the drawer. Shows a count badge; only appears
// when there's something to see (or while the drawer is open).
PanelWindow {
    id: win

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: Notifications.count > 0 || Notifications.drawerOpen

    anchors { top: true; right: true }
    margins { top: 8; right: 12 }

    implicitWidth: 40
    implicitHeight: 32

    mask: Region { item: bell }

    Rectangle {
        id: bell
        anchors.fill: parent
        radius: 10
        color: bellMa.containsMouse ? Theme.panelScrim : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: "󰂚"
            color: Theme.textPrimary                // Change depending on your wallpaper
            font { family: Theme.fontFamily; pixelSize: 18 }
        }

        // Count badge
        Rectangle {
            visible: Notifications.count > 0
            anchors { right: parent.right; top: parent.top }
            width: 15; height: 15; radius: 7.5
            color: Theme.danger

            Text {
                anchors.centerIn: parent
                text: Notifications.count > 9 ? "9+" : Notifications.count
                color: Theme.textAccent
                font { family: Theme.fontFamily; pixelSize: 9; bold: true }
            }
        }

        MouseArea {
            id: bellMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Notifications.drawerOpen = !Notifications.drawerOpen
        }
    }
}
