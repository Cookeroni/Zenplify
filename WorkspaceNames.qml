pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io

// Frontend-only custom workspace labels, persisted as JSON — no niri config
// required. Maps a niri workspace index (the 1, 2, 3… you think in) to a display
// name. A workspace with no entry falls back to its niri name, then its number,
// so a partial map is fine. This is display-only; it never renames anything in
// niri.
//
// Storage: ${XDG_CONFIG_HOME:-~/.config}/zenplify/workspace-names.json, shaped
// { "labels": { "1": "Work", "2": "Game" } }. Human-editable and survives pulls.
Singleton {
    id: root

    // Resolved config directory, filled once at startup by the probe below.
    property string _dir: ""

    // Live map, loaded from disk and written back on change.
    readonly property var labels: file.adapter.labels

    // Custom label for a workspace index, or "" when none is set.
    function labelFor(idx) {
        return (root.labels && root.labels[String(idx)]) || "";
    }

    // Set (or clear, when name is blank) a workspace's custom label, and persist.
    // Reassigns a fresh object so the adapter's change signal fires.
    function setLabel(idx, name) {
        const key = String(idx);
        const next = Object.assign({}, file.adapter.labels);
        const trimmed = (name || "").trim();
        if (trimmed.length > 0)
            next[key] = trimmed;
        else
            delete next[key];
        file.adapter.labels = next;   // → onAdapterUpdated → writeAdapter()
    }

    // Resolve the config dir and ensure it exists before FileView touches it.
    // Single-quoted so the shell (not QML) expands the XDG/HOME variables.
    Process {
        command: ["sh", "-c", "d=\"${XDG_CONFIG_HOME:-$HOME/.config}/zenplify\"; mkdir -p \"$d\"; printf %s \"$d\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root._dir = this.text.trim()
        }
    }

    FileView {
        id: file
        path: root._dir ? (root._dir + "/workspace-names.json") : ""
        watchChanges: true
        onFileChanged: this.reload()
        onAdapterUpdated: this.writeAdapter()

        JsonAdapter {
            property var labels: ({})
        }
    }
}
