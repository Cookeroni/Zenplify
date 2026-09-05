pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Wraps Quickshell's MPRIS service and exposes the Spotify player as one
// shared source, read by both the pill mini-view and the panel card.
Singleton {
    id: root

    // The Spotify MprisPlayer, or null if Spotify isn't running.
    readonly property var player: {
        const list = Mpris.players ? Mpris.players.values : [];
        for (let i = 0; i < list.length; i++) {
            const p = list[i];
            if (p && (p.identity || "").toLowerCase() === "spotify")
                return p;
        }
        return null;
    }

    readonly property bool hasTrack: root.player !== null && (root.player.trackTitle || "") !== ""
    readonly property string title:  root.player ? root.player.trackTitle  : ""
    readonly property string artist: root.player ? root.player.trackArtist : ""
    readonly property string album:  root.player ? root.player.trackAlbum  : ""
    readonly property string artUrl: root.player ? root.player.trackArtUrl : ""
    readonly property bool isPlaying: root.player ? root.player.isPlaying : false
    readonly property bool canToggle: root.player ? root.player.canTogglePlaying : false
    readonly property bool canNext:   root.player ? root.player.canGoNext : false
    readonly property bool canPrev:   root.player ? root.player.canGoPrevious : false

    readonly property real position: root.player ? root.player.position : 0
    readonly property real length:   root.player ? root.player.length : 0
    readonly property real progress: root.length > 0 ? Math.min(Math.max(root.position / root.length, 0), 1) : 0

    // MPRIS position doesn't advance on its own; nudge it once a second while
    // playing so the progress bar moves.
    Timer {
        running: root.isPlaying
        interval: 1000
        repeat: true
        onTriggered: if (root.player) root.player.positionChanged()
    }

    function toggle()   { if (root.player && root.player.canTogglePlaying) root.player.togglePlaying(); }
    function next()     { if (root.player && root.player.canGoNext)        root.player.next(); }
    function previous() { if (root.player && root.player.canGoPrevious)    root.player.previous(); }
}
