pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io
import "brightnessHelpers.js" as BrightnessHelpers

// App-wide backlight service. One probe, one sysfs watcher, shared by the
// pill mini-bar and the panel slider. Lifted verbatim from the old
// Brightness.qml, arming behaviour unchanged.
Singleton {
    id: root

    property string device: ""
    property int max: 0
    property int raw: 0
    readonly property real value: root.max > 0 ? root.raw / root.max : 0

    // Fired on a genuine brightness change (after the startup settle).
    signal changed()

    // One-shot probe to discover the backlight device + its max/current.
    Process {
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const info = BrightnessHelpers.parseInfo(this.text);
                if (!info)
                    return;
                root.device = info.device;
                root.max = info.max;
                root.raw = info.raw;
            }
        }
    }

    // Arm 700ms after the device is found: the initial sysfs read is swallowed,
    // the first real key press is not.
    property bool _armed: false
    Timer { id: armTimer; interval: 700; onTriggered: root._armed = true }
    onDeviceChanged: if (root.device !== "") armTimer.restart()

    // Watch sysfs so external changes (brightness keys) reach us without polling.
    FileView {
        path: root.device ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        watchChanges: root.device !== ""
        onFileChanged: this.reload()
        onLoaded: {
            const v = parseInt(this.text());
            if (isNaN(v))
                return;
            root.raw = v;
            if (root._armed)
                root.changed();
        }
    }

    function setPercent(pct) {
        setProc.command = ["brightnessctl", "set", Math.round(Math.max(0, Math.min(100, pct))) + "%"];
        setProc.running = true;
    }
    Process { id: setProc }
}
