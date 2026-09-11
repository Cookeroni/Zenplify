import QtQuick
import QtQuick.Layouts
import qs
import qs.Utils

// System monitors takeover: bars + numbers for CPU / RAM / swap / disk / temp,
// plus uptime. Opaque, fills the panel body when shown.
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

    // One metric line: label, optional bar, value.
    component Metric: RowLayout {
        id: metric
        property string label
        property real frac: 0
        property string value
        property bool bar: true
        property color barColor: Theme.success

        Layout.fillWidth: true
        spacing: 12

        Text {
            Layout.preferredWidth: 58
            text: metric.label
            color: Theme.textSecondary
            font { family: Theme.fontFamily; pixelSize: 13 }
        }

        Rectangle {
            visible: metric.bar
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            radius: 4
            color: Theme.bgAccent

            Rectangle {
                width: parent.width * Math.min(Math.max(metric.frac, 0), 1)
                height: parent.height
                radius: parent.radius
                color: metric.barColor
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
        Item { visible: !metric.bar; Layout.fillWidth: true }

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
            frac: SysInfo.cpu / 100
            value: Math.round(SysInfo.cpu) + "%"
            barColor: root.levelColor(SysInfo.cpu / 100)
        }
        Metric {
            label: "RAM"
            frac: SysInfo.ramFrac
            value: root.fmtBytes(SysInfo.ramUsed) + " / " + root.fmtBytes(SysInfo.ramTotal)
            barColor: root.levelColor(SysInfo.ramFrac)
        }
        Metric {
            label: "Swap"
            bar: SysInfo.swapTotal > 0
            frac: SysInfo.swapFrac
            value: SysInfo.swapTotal > 0 ? (root.fmtBytes(SysInfo.swapUsed) + " / " + root.fmtBytes(SysInfo.swapTotal)) : "off"
            barColor: root.levelColor(SysInfo.swapFrac)
        }
        Metric {
            label: "Disk"
            frac: SysInfo.diskFrac
            value: root.fmtBytes(SysInfo.diskUsed) + " / " + root.fmtBytes(SysInfo.diskTotal)
            barColor: root.levelColor(SysInfo.diskFrac)
        }
        Metric {
            label: "Temp"
            bar: SysInfo.hasTemp
            frac: SysInfo.temp / 100
            value: SysInfo.hasTemp ? (Math.round(SysInfo.temp) + "°C") : "N/A"
            barColor: root.tempColor(SysInfo.temp)
        }
        Metric {
            label: "Uptime"
            bar: false
            value: root.fmtUptime(SysInfo.uptime)
        }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }
    }
}
