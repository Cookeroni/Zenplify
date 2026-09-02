import QtQuick
import QtQuick.Layouts
import qs
import qs.Utils
import "../Utils/audioHelpers.js" as AudioHelpers

// Pill mini-bar view. State lives in the Audio singleton.
Item {
    id: root

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
            text: AudioHelpers.volumeIcon(Audio.volume, Audio.muted)
            color: Audio.muted ? Theme.textMuted : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: height / 2
            color: Theme.bgAccent

            Rectangle {
                width: parent.width * Math.min(Audio.volume, 1)
                height: parent.height
                radius: parent.radius
                color: Audio.muted ? Theme.textMuted : Theme.textPrimary
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            text: AudioHelpers.volumePercent(Audio.volume)
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 34
        }
    }
}
