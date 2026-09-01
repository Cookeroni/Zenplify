import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs
import "../Utils/brightnessHelpers.js" as BrightnessHelpers

Item {
    id: root

    property bool isVisible: false

    property string device: ""
    property int max: 0
    property int raw: 0
    readonly property real value: root.max > 0 ? root.raw / root.max : 0

    // Emitted on a genuine brightness change (after the startup settle).
    signal changed()

    visible: isVisible

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
    // but the first real key press is not (mirrors Volume's arming).
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

    // Icon, Progress Bar, Percentage
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        // Icon
        Text {
            text: BrightnessHelpers.icon(root.value)
            color: Theme.textPrimary
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
                width: parent.width * root.value
                height: parent.height
                radius: parent.radius
                color: Theme.textPrimary
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }

        // Percentage
        Text {
            text: BrightnessHelpers.percent(root.value)
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 34
        }
    }
}
