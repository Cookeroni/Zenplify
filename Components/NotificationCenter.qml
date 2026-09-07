import QtQuick
import QtQuick.Layouts
import qs
import qs.Utils

// Panel notification center: the tracked list, with per-item dismiss and
// clear-all. Reads from the same Notifications service as the popups.
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Theme.textSecondary
                font { family: Theme.fontFamily; pixelSize: 16 }
            }

            Text {
                visible: Notifications.count > 0
                text: "Clear all"
                color: Theme.textMuted
                font { family: Theme.fontFamily; pixelSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: Notifications.clearAll() }
            }
        }

        // Body: list, or empty state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                anchors.fill: parent
                visible: Notifications.count > 0
                clip: true
                spacing: 8
                model: Notifications.list

                delegate: NotifCard {
                    required property var modelData
                    width: ListView.view.width
                    notif: modelData
                    onDismissed: Notifications.dismiss(modelData)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: Notifications.count === 0
                text: "No notifications"
                color: Theme.textMuted
                font { family: Theme.fontFamily; pixelSize: 16 }
            }
        }
    }
}
