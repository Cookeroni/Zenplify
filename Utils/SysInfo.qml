pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// System metrics from /proc + sysfs, polled on a timer.
// source -> parse -> compute -> expose. CPU is a delta between samples.
Singleton {
    id: root

    property real cpu: 0                 // 0..100
    property real ramUsed: 0             // bytes
    property real ramTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property real diskUsed: 0
    property real diskTotal: 0
    property real temp: 0                // celsius
    property bool hasTemp: false
    property real uptime: 0              // seconds

    readonly property real ramFrac: root.ramTotal > 0 ? root.ramUsed / root.ramTotal : 0
    readonly property real swapFrac: root.swapTotal > 0 ? root.swapUsed / root.swapTotal : 0
    readonly property real diskFrac: root.diskTotal > 0 ? root.diskUsed / root.diskTotal : 0

    // ---- rolling history (fractions 0..1) for the sparklines ----
    property int histLen: 60
    property var cpuHistory: []
    property var ramHistory: []
    property var swapHistory: []
    property var diskHistory: []
    property var tempHistory: []
    function _push(arr, v) {
        var a = arr.slice();
        a.push(v);
        while (a.length > root.histLen)
            a.shift();
        return a;
    }

    // ---- CPU: /proc/stat, busy fraction between two samples ----
    property real _prevTotal: 0
    property real _prevIdle: 0
    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            const f = this.text().split("\n")[0].trim().split(/\s+/);   // cpu u n s idle iowait ...
            let total = 0;
            for (let i = 1; i < f.length; i++)
                total += parseInt(f[i]) || 0;
            const idle = (parseInt(f[4]) || 0) + (parseInt(f[5]) || 0);  // idle + iowait
            const dt = total - root._prevTotal;
            const di = idle - root._prevIdle;
            if (root._prevTotal > 0 && dt > 0)
                root.cpu = Math.max(0, Math.min(100, 100 * (dt - di) / dt));
            root._prevTotal = total;
            root._prevIdle = idle;
            root.cpuHistory = root._push(root.cpuHistory, root.cpu / 100);
        }
    }

    // ---- Memory + swap: /proc/meminfo (kB) ----
    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: {
            const t = this.text();
            const kb = (key) => {
                const m = t.match(new RegExp(key + ":\\s+(\\d+)"));
                return m ? parseInt(m[1]) * 1024 : 0;
            };
            const memTotal = kb("MemTotal");
            root.ramTotal = memTotal;
            root.ramUsed = Math.max(0, memTotal - kb("MemAvailable"));
            const swapTotal = kb("SwapTotal");
            root.swapTotal = swapTotal;
            root.swapUsed = Math.max(0, swapTotal - kb("SwapFree"));
            root.ramHistory = root._push(root.ramHistory, memTotal > 0 ? root.ramUsed / memTotal : 0);
            root.swapHistory = root._push(root.swapHistory, swapTotal > 0 ? root.swapUsed / swapTotal : 0);
        }
    }

    // ---- Uptime
    FileView {
        id: upFile
        path: "/proc/uptime"
        onLoaded: root.uptime = parseFloat(this.text().split(" ")[0]) || 0
    }
    

    // ---- Temperature: auto-detected sensor (override tempPath to change) ----
    property string tempPath: ""
    Process {
        running: true
        command: ["sh", "-c", "p=$(grep -lE 'coretemp|k10temp|zenpower' /sys/class/hwmon/*/name 2>/dev/null | head -1 | sed 's|/name$|/temp1_input|'); [ -n \"$p\" ] && echo \"$p\" || echo /sys/class/thermal/thermal_zone0/temp"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim();
                if (p !== "")
                    root.tempPath = p;
            }
        }
    }
    FileView {
        id: tempFile
        path: root.tempPath
        onLoaded: {
            const v = parseInt(this.text());
            if (!isNaN(v)) {
                root.temp = v / 1000;
                root.hasTemp = true;
                root.tempHistory = root._push(root.tempHistory, root.temp / 100);
            }
        }
    }

    // ---- Disk: df on the root filesystem (bytes) ----
    Process {
        id: dfProc
        command: ["df", "-B1", "--output=size,used", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                if (lines.length >= 2) {
                    const f = lines[1].trim().split(/\s+/);
                    root.diskTotal = parseInt(f[0]) || 0;
                    root.diskUsed = parseInt(f[1]) || 0;
                    root.diskHistory = root._push(root.diskHistory, root.diskTotal > 0 ? root.diskUsed / root.diskTotal : 0);
                }
            }
        }
    }

    // ---- Polling ----
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            upFile.reload();
            if (root.tempPath !== "")
                tempFile.reload();
        }
    }
    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: dfProc.running = true
    }
}
