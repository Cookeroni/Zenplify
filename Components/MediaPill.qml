import QtQuick
import QtQuick.Layouts
import qs
import qs.Utils

// Compact now-playing shown in the collapsed pill while Spotify has a track.
Item {
    id: root

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
            text: "󰓇"                          // spotify glyph
            color: Player.isPlaying ? Theme.success : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        Text {
            Layout.fillWidth: true
            Layout.bottomMargin: 2
            text: Player.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 15
            elide: Text.ElideRight
        }
    }
}
