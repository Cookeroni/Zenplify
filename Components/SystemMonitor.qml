import QtQuick
import QtQuick.Layouts
import qs
import qs.Utils

// System monitors takeover: label + sparkline (rolling history) + number,
// for CPU / RAM / swap / disk / temp, plus uptime. Fills the panel body.
Rectangle {
    id: root

    property bool show: false

    visible: show
    color: Theme.pillBg

    // Absorb clicks so they don't reach the covered tiles
    MouseArea { anchors.fill: parent }

    function fmtBytes(b) {
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + "G";
        if (b >= 1048576) return (b / 1048576).toFixed(0) + "M";
        return (b / 1024).toFixed(0) + "K";
    }
    function fmtUptime(s) {
        const d = Math.floor(s / 86400);
        const h = Math.floor((s % 86400) / 3600);
        const m = Math.floor((s % 3600) / 60);
        let out = "";
        if (d > 0) out += d + "d ";
        if (d > 0 || h > 0) out += h + "h ";
        return out + m + "m";
    }
    function levelColor(f) {
        return f < 0.6 ? Theme.success : f < 0.85 ? Theme.warning : Theme.danger;
    }
    function tempColor(t) {
        return t < 60 ? Theme.success : t < 80 ? Theme.warning : Theme.danger;
    }

    // One metric line: label, sparkline (or spacer), value.
    component Metric: RowLayout {
        id: metric
        property string label
        property var history: []
        property string value
        property bool spark: true
        property color lineColor: Theme.success

        Layout.fillWidth: true
        spacing: 12

        Text {
            Layout.preferredWidth: 58
            text: metric.label
            color: Theme.textSecondary
            font { family: Theme.fontFamily; pixelSize: 13 }
        }

        // Sparkline
        Canvas {
            id: canvas
            visible: metric.spark
            Layout.fillWidth: true
            Layout.preferredHeight: 26

            property var data: metric.history
            property color lineColor: metric.lineColor

            onDataChanged: requestPaint()
            onLineColorChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const d = canvas.data || [];
                const n = d.length;
                if (n < 2)
                    return;
                const w = width, h = height;
                const sx = w / (n - 1);
                const yy = (v) => h - Math.min(Math.max(v, 0), 1) * (h - 2) - 1;

                // area fill
                ctx.beginPath();
                ctx.moveTo(0, yy(d[0]));
                for (let i = 1; i < n; i++)
                    ctx.lineTo(i * sx, yy(d[i]));
                ctx.lineTo(w, h);
                ctx.lineTo(0, h);
                ctx.closePath();
                ctx.fillStyle = Qt.rgba(canvas.lineColor.r, canvas.lineColor.g, canvas.lineColor.b, 0.16);
                ctx.fill();

                // line
                ctx.beginPath();
                ctx.moveTo(0, yy(d[0]));
                for (let j = 1; j < n; j++)
                    ctx.lineTo(j * sx, yy(d[j]));
                ctx.lineWidth = 1.5;
                ctx.lineJoin = "round";
                ctx.strokeStyle = canvas.lineColor;
                ctx.stroke();
            }
        }
        Item { visible: !metric.spark; Layout.fillWidth: true }

        Text {
            Layout.preferredWidth: 120
            horizontalAlignment: Text.AlignRight
            text: metric.value
            color: Theme.textPrimary
            font { family: Theme.fontFamily; pixelSize: 13 }
        }
    }

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 8
            rightMargin: 8
            topMargin: 8
        }
        spacing: 14

        Metric {
            label: "CPU"
            history: SysInfo.cpuHistory
            value: Math.round(SysInfo.cpu) + "%"
            lineColor: root.levelColor(SysInfo.cpu / 100)
        }
        Metric {
            label: "RAM"
            history: SysInfo.ramHistory
            value: root.fmtBytes(SysInfo.ramUsed) + " / " + root.fmtBytes(SysInfo.ramTotal)
            lineColor: root.levelColor(SysInfo.ramFrac)
        }
        Metric {
            label: "Swap"
            spark: SysInfo.swapTotal > 0
            history: SysInfo.swapHistory
            value: SysInfo.swapTotal > 0 ? (root.fmtBytes(SysInfo.swapUsed) + " / " + root.fmtBytes(SysInfo.swapTotal)) : "off"
            lineColor: root.levelColor(SysInfo.swapFrac)
        }
        Metric {
            label: "Disk"
            history: SysInfo.diskHistory
            value: root.fmtBytes(SysInfo.diskUsed) + " / " + root.fmtBytes(SysInfo.diskTotal)
            lineColor: root.levelColor(SysInfo.diskFrac)
        }
        Metric {
            label: "Temp"
            spark: SysInfo.hasTemp
            history: SysInfo.tempHistory
            value: SysInfo.hasTemp ? (Math.round(SysInfo.temp) + "°C") : "N/A"
            lineColor: root.tempColor(SysInfo.temp)
        }
        Metric {
            label: "Uptime"
            spark: false
            value: root.fmtUptime(SysInfo.uptime)
        }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }
    }
}
