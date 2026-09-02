pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Services.Pipewire

// App-wide audio service. One instance; the pill mini-bar and the panel
// slider both read from it. Lifted verbatim from the old Volume.qml so the
// pill's behaviour (incl. the resume-settle guard) is unchanged.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property bool ready: root.sink?.ready ?? false

    // Fired on a genuine volume/mute change (after the startup/resume settle).
    signal changed()

    PwObjectTracker { objects: [root.sink] }

    // Swallow the settle that follows any (re)connect of the audio stack
    // (launch, or waking from suspend).
    property bool _armed: false
    Timer { id: armTimer; interval: 1000; onTriggered: root._armed = true }
    function _rearm() {
        root._armed = false;
        if (root.ready)
            armTimer.restart();
    }
    Component.onCompleted: root._rearm()
    onSinkChanged: root._rearm()
    onReadyChanged: root._rearm()

    onVolumeChanged: if (root._armed && root.ready) root.changed()
    onMutedChanged: if (root._armed && root.ready) root.changed()

    function setVolume(v) {
        if (root.sink?.ready && root.sink.audio) {
            root.sink.audio.muted = false;
            root.sink.audio.volume = Math.max(0, Math.min(1, v));
        }
    }
}
