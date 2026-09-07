import QtQuick
import QtQuick.Layouts
import qs
import qs.Utils

// One notification, used by both the popups and the center.
Rectangle {
    id: root

    property var notif
    signal dismissed()

    radius: 12
    color: Theme.panelScrim
    implicitHeight: content.implicitHeight + 24

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 12
            rightMargin: 12
            topMargin: 10
        }
        spacing: 4

        // App name + dismiss
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: root.notif ? root.notif.appName : ""
                color: Theme.textSecondary
                elide: Text.ElideRight
                font { family: Theme.fontFamily; pixelSize: 11 }
            }
            Text {
                text: "󰅖"
                color: Theme.textMuted
                font { family: Theme.fontFamily; pixelSize: 13 }
                MouseArea { anchors.fill: parent; onClicked: root.dismissed() }
            }
        }

        // Summary
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.notif ? root.notif.summary : ""
            color: Theme.textPrimary
            elide: Text.ElideRight
            font { family: Theme.fontFamily; pixelSize: 13; bold: true }
        }

        // Body
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.notif ? root.notif.body : ""
            color: Theme.textSecondary
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 5
            elide: Text.ElideRight
            font { family: Theme.fontFamily; pixelSize: 12 }
        }

        // Actions
        RowLayout {
            Layout.fillWidth: true
            visible: root.notif && root.notif.actions && root.notif.actions.length > 0
            spacing: 6

            Repeater {
                model: root.notif ? root.notif.actions : []
                delegate: Rectangle {
                    id: act
                    required property var modelData
                    height: 26
                    implicitWidth: actLabel.implicitWidth + 22
                    radius: 6
                    color: Theme.bgAccent

                    Text {
                        id: actLabel
                        anchors.centerIn: parent
                        text: act.modelData.text !== undefined ? act.modelData.text : "Action"
                        color: Theme.textPrimary
                        font { family: Theme.fontFamily; pixelSize: 11 }
                    }
                    MouseArea { anchors.fill: parent; onClicked: act.modelData.invoke() }
                }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
