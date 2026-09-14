import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.Utils

// Right-edge slide-out drawer, on its own full-screen surface. Independent of
// the control panel — open it from the bell without touching the pill.
PanelWindow {
    id: win

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    anchors { top: true; bottom: true; left: true; right: true }

    // Catch clicks only while open; otherwise the whole surface passes through.
    mask: Region { item: Notifications.drawerOpen ? maskArea : blank }
    Item { id: blank; width: 0; height: 0 }
    Item { id: maskArea; anchors.fill: parent }

    // Dim scrim — click to close
    Rectangle {
        anchors.fill: parent
        color: Theme.dimScreen
        opacity: Notifications.drawerOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea { anchors.fill: parent; onClicked: Notifications.drawerOpen = false }
    }

    // The drawer
    Rectangle {
        id: drawer
        width: 380
        anchors { top: parent.top; bottom: parent.bottom }
        x: Notifications.drawerOpen ? parent.width - width : parent.width
        color: Theme.pillBg

        Behavior on x {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }

        // Absorb clicks so they don't fall through to the scrim
        MouseArea { anchors.fill: parent }

        NotificationCenter {
            anchors {
                fill: parent
                topMargin: 22
                bottomMargin: 22
                leftMargin: 18
                rightMargin: 18
            }
        }
    }
}
