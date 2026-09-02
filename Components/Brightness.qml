import QtQuick
import QtQuick.Layouts
import qs
import qs.Utils
import "../Utils/brightnessHelpers.js" as BrightnessHelpers

// Pill mini-bar view. State lives in the Backlight singleton.
Item {
    id: root

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
            text: BrightnessHelpers.icon(Backlight.value)
            color: Theme.lampOn
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: height / 2
            color: Theme.bgAccent

            Rectangle {
                width: parent.width * Backlight.value
                height: parent.height
                radius: parent.radius
                color: Theme.lampOn
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            text: BrightnessHelpers.percent(Backlight.value)
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 34
        }
    }
}
