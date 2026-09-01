import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs
import "../Utils/audioHelpers.js" as AudioHelpers

Item {
    id: root

    property bool isVisible: false

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false

    // Emitted on a genuine volume/mute change (after the startup settle).
    signal changed()

    visible: isVisible

    // audio.volume/muted are invalid unless the node is tracked.
    PwObjectTracker { objects: [root.sink] }

    // Swallow the initial settle (and any re-settle after the default sink
    // switches) so the pill doesn't pop on launch or device change.
    property bool _armed: false
    Timer { id: armTimer; interval: 700; running: true; onTriggered: root._armed = true }
    onSinkChanged: { root._armed = false; armTimer.restart(); }

    onVolumeChanged: if (root._armed) root.changed()
    onMutedChanged: if (root._armed) root.changed()

    function setVolume(v) {
        if (root.sink?.ready && root.sink.audio) {
            root.sink.audio.muted = false;
            root.sink.audio.volume = Math.max(0, Math.min(1, v));
        }
    }

    // Icon, Progress Bar, Percentage
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        // Icon
        Text {
            text: AudioHelpers.volumeIcon(root.volume, root.muted)
            color: root.muted ? Theme.textMuted : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }

        // Progress Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: height / 2
            color: Theme.bgAccent

            Rectangle {
                width: parent.width * Math.min(root.volume, 1)
                height: parent.height
                radius: parent.radius
                color: root.muted ? Theme.textMuted : Theme.textPrimary
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }

        // Percentage
        Text {
            text: AudioHelpers.volumePercent(root.volume)
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 34
        }
    }
}
