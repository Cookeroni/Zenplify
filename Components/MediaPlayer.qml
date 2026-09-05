import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs
import qs.Utils

// Panel now-playing card: album art + title/artist + prev / play-pause / next.
// State lives in the Player singleton (Spotify via MPRIS).
Item {
    id: root

    implicitHeight: 62

    // A single control glyph with a tap target and enabled/disabled coloring.
    component CtrlButton: Item {
        id: cb
        property string glyph
        property bool active: true
        property int size: 20
        signal tapped()

        implicitWidth: 30
        implicitHeight: 30

        Text {
            anchors.centerIn: parent
            text: cb.glyph
            color: cb.active ? Theme.textPrimary : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: cb.size
        }
        MouseArea {
            anchors.fill: parent
            enabled: cb.active
            onClicked: cb.tapped()
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 56
        spacing: 12

        // Album art (square; placeholder glyph when no art)
        ClippingRectangle {
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56
            radius: 5
            color: Theme.panelScrim
         
            Image {
                anchors.fill: parent
                source: Player.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: Player.artUrl !== ""
            }

            Text {
                anchors.centerIn: parent
                visible: Player.artUrl === ""
                text: "󰝚"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 22
            }
        }

        // Title + artist
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: Player.title || "Nothing playing"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 16
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: Player.artist !== ""
                text: Player.artist
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        // Controls
        CtrlButton {
            glyph: "󰒮"
            active: Player.canPrev
            onTapped: Player.previous()
        }
        CtrlButton {
            glyph: Player.isPlaying ? "󰏤" : "󰐊"
            size: 24
            active: Player.canToggle
            onTapped: Player.toggle()
        }
        CtrlButton {
            glyph: "󰒭"
            active: Player.canNext
            onTapped: Player.next()
        }
    }

    // Song progress
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 70
        height: 3
        radius: height / 2
        color: Theme.bgAccent

        Rectangle {
            id: fill
            property real frac: 0

            width: parent.width * fill.frac
            height: parent.height
            radius: parent.radius
            color: Theme.success

            // Glide with forward progress, but snap (no sweep) when progress
            // drops — i.e. on a track change or a backward seek.
            Behavior on frac {
                id: fracAnim
                NumberAnimation { duration: 1000; easing.type: Easing.Linear }
            }

            Connections {
                target: Player
                function onProgressChanged() {
                    if (Player.progress < fill.frac) {
                        fracAnim.enabled = false;      // snap back
                        fill.frac = Player.progress;
                        fracAnim.enabled = true;
                    } else {
                        fill.frac = Player.progress;   // animate forward
                    }
                }
            }

            Component.onCompleted: fill.frac = Player.progress
        }
    }
}
