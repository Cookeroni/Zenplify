import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Utils

// Transient on-screen toasts, top-right, in their own layer-shell surface so
// they don't tangle with the pill's input mask.
PanelWindow {
    id: win

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    anchors { top: true; right: true }
    margins { top: 12; right: 12 }

    implicitWidth: 360
    implicitHeight: Math.max(1, popupCol.implicitHeight)

    // Only the toasts catch clicks; everything else passes through.
    mask: Region { item: popupCol }

    Column {
        id: popupCol
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 10

        Repeater {
            model: Notifications.popups
            delegate: NotifCard {
                required property var modelData
                width: popupCol.width
                notif: modelData
                onDismissed: Notifications.popupDismiss(modelData)
            }
        }
    }
}
