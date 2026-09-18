pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io
import "niriHelpers.js" as NiriHelpers

// App-wide Niri workspace service. One event-stream reader shared by the shell.
// Structured like the Audio / Backlight singletons: niri hands us the full
// state up-front, an arm guard swallows that startup burst, and changed() fires
// only on a genuine focus switch — so window churn or a new trailing workspace
// never re-pops the pill.
Singleton {
    id: root

    // Workspaces on the focused output, sorted by idx (0-based positions).
    property var stack: []
    property int activeIdx: -1      // 0-based position within the focused output
    property int count: 0
    property int idx: 0             // focused workspace's niri index (1-based)
    property string name: ""        // focused workspace name, or its index

    // Fired on a real focus switch (after the startup settle).
    signal changed()

    // id-keyed map of every workspace niri has told us about (all outputs).
    property var _byId: ({})
    property int _focusedId: -1

    function _recompute() {
        const s = NiriHelpers.focusedStack(root._byId);
        root.stack = s.list;
        root.activeIdx = s.activeIdx;
        root.count = s.count;
        root.idx = s.idx;
        root.name = s.name;
        return s.focusedId;
    }

    function _handle(line) {
        if (!line)
            return;
        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            return;   // partial/garbage line — skip it
        }
        NiriHelpers.applyEvent(root._byId, ev);
        const nowFocused = root._recompute();
        if (nowFocused !== root._focusedId) {
            root._focusedId = nowFocused;
            if (root._armed && nowFocused !== -1)
                root.changed();
        }
    }

    // Arm 700ms after load: the initial WorkspacesChanged/WorkspaceActivated
    // burst is swallowed, the first real workspace switch is not.
    property bool _armed: false
    Timer { id: armTimer; interval: 700; running: true; onTriggered: root._armed = true }

    // Long-lived reader. SplitParser emits one signal per newline-delimited
    // event; niri keeps the stream open, so this never "finishes".
    Process {
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: (line) => root._handle(line)
        }
    }
}
