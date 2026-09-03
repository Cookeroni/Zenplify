import Quickshell
import QtQuick
import Quickshell.Services.UPower
import QtQuick.Layouts
import qs

import "../Utils/batteryHelpers.js" as BatUtils

Item {
    id: root

    property bool showList: false
    property bool tileHidden: false

    property var battery: UPower.displayDevice
    property bool charging:    battery.state === UPowerDeviceState.Charging
    property bool discharging: battery.state === UPowerDeviceState.Discharging
    property bool full:        battery.state === UPowerDeviceState.FullyCharged

    property real barFraction: battery.energyCapacity > 0 ? battery.percentage : 0
     
    readonly property int level: Math.round(battery.percentage * 100)
    readonly property color levelColor: BatUtils.levelColorFor(battery.percentage, charging)

    readonly property string icon: {
        return (charging) ? "󰂄" : (level >= 100) ? "󰁹" 
            : (level <= 10) ? "󰁺" : String.fromCodePoint(0xF007a + (Math.floor(level / 10)) - 1);
    }

    // Everything UPower knows about except the AC adapter and the internal
    // battery — the tank already covers that one.
    readonly property var peripherals: {
        const out = [];
        const devs = UPower.devices.values;
        for (let i = 0; i < devs.length; i++) {
            const d = devs[i];
            if (d.isLaptopBattery) continue;                 // type == Battery && powerSupply
            if (d.type === UPowerDeviceType.LinePower) continue;
            out.push(d);
        }
        return out;
    }
    
    implicitWidth: tileView.width
    implicitHeight: tileView.height

    width: root.showList ? parent.width : implicitWidth 
    height: root.showList ? parent.height - root.y - 10
                                : implicitHeight 
    
    // ============================ TILE VIEW ==========================
    Rectangle {
        id: tileView

        width: 182 
        height: 50
        radius: 8
        visible: (root.showList || root.tileHidden) ? false : true
        color: Theme.panelScrim

        MouseArea {
            anchors.fill: parent
            onClicked: root.showList = true
        }

        // Icon & Label
        RowLayout {
            anchors { fill: parent; margins: 2 }
            spacing: 4

            // Icon
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                color: "transparent"

                Text {
                    anchors { centerIn: parent }
                    color: Theme.textPrimary
                    rotation: 90

                    font {
                        pixelSize: 24
                        family: Theme.fontFamily
                    }

                    text: root.icon
                }
            }

            // Label + Level
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Battery"
                    Layout.fillWidth: true
                    color: Theme.textPrimary 

                    font {
                        pixelSize: 15
                        family: Theme.fontFamily
                    }
                }

                Text {
                    Layout.fillWidth: true

                    color: Theme.textSecondary

                    font {
                        family: Theme.fontFamily
                        pixelSize: 13
                    }

                    // Inject the color directly around the percentage part
                    text: {
                        // Wrap the percentage in a font color tag
                        return UPowerDeviceState.toString(root.battery.state) + " (<font color='" + levelColor + "'>" + root.level + "%</font>)";
                    }   

                    // Tell QML to read this as HTML/Rich Text
                    textFormat: Text.RichText
                }
            }
        }
        
        Behavior on width {
            NumberAnimation {
                duration: 420
                easing.overshoot: 1.05
                easing.type: Easing.OutBack
            }
        }
    }

    // ============================ LIST VIEW ==========================
    Item {
        id: listView

        anchors { 
            fill: parent 
            rightMargin: 24
            topMargin: 10
        }
        visible: root.showList

        ColumnLayout {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 12
            }

            // ======================= BATTERY STATE =======================
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                // State, Time Remaining & Draw Rate
                ColumnLayout {
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignTop 
                    spacing: 10
          
                    // State
                    Text {
                        Layout.fillWidth: true
                        color: Theme.textSecondary

                        font {
                            family: Theme.fontFamily
                            pixelSize: 20
                        }

                        text: UPowerDeviceState.toString(root.battery.state)
                    }

                    // Time Remaining
                    RowLayout {
                        spacing: 10

                        Text {
                            Layout.alignment: Qt.AlignBaseline      
                            color: Theme.textSecondary
                            elide: Text.ElideRight

                            font {
                                bold: true
                                family: Theme.fontFamily
                                pixelSize: 20
                            }

                            text: root.charging ? BatUtils.fmtTime(root.battery.timeToFull)
                                : root.discharging ? BatUtils.fmtTime(root.battery.timeToEmpty)
                                : level + "%"
                        }

                        Text {
                            Layout.alignment: Qt.AlignBaseline      
                            color: Theme.textSecondary
                            visible: root.charging || root.discharging

                            font {
                                family: Theme.fontFamily
                                pixelSize: 16
                            }

                            text: root.charging ? "until full" : "until empty"
                        }
                    }

                    // Live power draw from changeRate
                    Text {
                        Layout.topMargin: 4
                        color: Theme.charging
                        visible: (root.charging || root.discharging) && root.battery.changeRate !== 0

                        font {
                            family: Theme.fontFamily
                            pixelSize: 12
                        }

                        text: "Power Draw: " + (root.charging ? "+" : "−") + Math.abs(root.battery.changeRate).toFixed(1) + " W"
                    }

                }

                // Right: battery tank
                Item {
                    id: tankBox

                    readonly property int nubW: 6
                    readonly property real ampIdle: 1.4
                    readonly property real ampCharging: 4.5

                    // Water height 0..1. Fills on open, drains on close.
                    property real fill: root.showList ? root.level / 100 : 0
                    property real amplitude: root.charging ? ampCharging : ampIdle
                    property real phase: 0
                    property real bubbleT: 0

                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.minimumWidth: 180
                    Layout.preferredHeight: 128

                    Canvas {
                        id: tank

                        anchors.fill: parent

                        // repaint triggers
                        property real f: tankBox.fill
                        property real p: tankBox.phase
                        property real amp: tankBox.amplitude
                        property real bt: tankBox.bubbleT
                        property int lvl: root.level
                        property bool charging: root.charging
                        property color water: root.levelColor

                        onFChanged: requestPaint()
                        onPChanged: requestPaint()
                        onAmpChanged: requestPaint()
                        onBtChanged: requestPaint()
                        onLvlChanged: requestPaint()
                        onWaterChanged: requestPaint()
                        onVisibleChanged: requestPaint()
                        onWidthChanged: requestPaint()

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();

                            const lw = 2;
                            const r = 16;
                            const x0 = lw / 2;
                            const y0 = lw / 2;
                            const w = width - tankBox.nubW - lw;   // nub lives on the right
                            const h = height - lw;
                            const bottom = y0 + h;
                            const surface = y0 + h * (1 - f);

                            function bodyPath() {
                                ctx.beginPath();
                                ctx.moveTo(x0 + r, y0);
                                ctx.lineTo(x0 + w - r, y0);
                                ctx.quadraticCurveTo(x0 + w, y0, x0 + w, y0 + r);
                                ctx.lineTo(x0 + w, bottom - r);
                                ctx.quadraticCurveTo(x0 + w, bottom, x0 + w - r, bottom);
                                ctx.lineTo(x0 + r, bottom);
                                ctx.quadraticCurveTo(x0, bottom, x0, bottom - r);
                                ctx.lineTo(x0, y0 + r);
                                ctx.quadraticCurveTo(x0, y0, x0 + r, y0);
                                ctx.closePath();
                            }

                            // Wavelengths in px, not fractions of the width, so the
                            // chop looks the same however wide the panel gets
                            function surfacePts(baseY, a, ph) {
                                const pts = [];
                                const k1 = 2 * Math.PI / 130;
                                const k2 = 2 * Math.PI / 74;
                                for (let x = 0; x <= w; x += 2) {
                                    pts.push([x0 + x,
                                              baseY + a * Math.sin(k1 * x + ph)
                                                    + a * 0.45 * Math.sin(k2 * x - ph * 1.7)]);
                                }
                                return pts;
                            }

                            function wavePath(pts) {
                                ctx.beginPath();
                                ctx.moveTo(pts[0][0], pts[0][1]);
                                for (let i = 1; i < pts.length; i++)
                                    ctx.lineTo(pts[i][0], pts[i][1]);
                                ctx.lineTo(x0 + w, bottom);
                                ctx.lineTo(x0, bottom);
                                ctx.closePath();
                            }

                            const front = surfacePts(surface, amp, p);

                            // ---- terminal nub, right-hand side ----
                            const nubH = 30;
                            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.22);
                            ctx.fillRect(width - tankBox.nubW, (height - nubH) / 2,
                                         tankBox.nubW, nubH);

                            // ---- water ----
                            if (f > 0.005) {
                                ctx.save();
                                bodyPath();
                                ctx.clip();

                                // back wave, slower and offset — parallax
                                wavePath(surfacePts(surface + 2.5, amp * 0.8, p * 0.75 + 2.2));
                                ctx.fillStyle = Qt.rgba(water.r, water.g, water.b, 0.30);
                                ctx.fill();

                                // front wave with depth gradient
                                wavePath(front);
                                const g = ctx.createLinearGradient(0, surface - 6, 0, bottom);
                                g.addColorStop(0, Qt.rgba(water.r, water.g, water.b, 0.95));
                                g.addColorStop(1, Qt.rgba(water.r, water.g, water.b, 0.45));
                                ctx.fillStyle = g;
                                ctx.fill();

                                // meniscus highlight
                                ctx.beginPath();
                                ctx.moveTo(front[0][0], front[0][1]);
                                for (let i = 1; i < front.length; i++)
                                    ctx.lineTo(front[i][0], front[i][1]);
                                ctx.lineWidth = 1.5;
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.45);
                                ctx.stroke();

                                // bubbles — count scales with the tank width
                                if (charging) {
                                    const n = Math.max(4, Math.round(w / 55));
                                    for (let i = 0; i < n; i++) {
                                        const seed = Math.abs(Math.sin(i * 91.7) * 4375.85);
                                        const rx = seed - Math.floor(seed);
                                        const t = (bt + i / n) % 1;
                                        const bx = x0 + w * (0.06 + 0.88 * rx);
                                        const by = bottom - 4 - (bottom - 4 - surface) * t;
                                        ctx.beginPath();
                                        ctx.arc(bx, by, 1.4 + (i % 3) * 0.6, 0, Math.PI * 2);
                                        ctx.fillStyle = Qt.rgba(1, 1, 1, 0.35 * (1 - t));
                                        ctx.fill();
                                    }
                                }
                                ctx.restore();
                            }

                            // ---- outline ----
                            bodyPath();
                            ctx.lineWidth = lw;
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.22);
                            ctx.stroke();

                            // ---- readout, split along the waterline ----
                            const label = lvl + "%";
                            const tx = x0 + w / 2;
                            const ty = y0 + h / 2;
                            ctx.textAlign = "center";
                            ctx.textBaseline = "middle";
                            ctx.font = "bold 28px \"" + Theme.fontFamily + "\"";

                            ctx.save();
                            bodyPath();
                            ctx.clip();
                            ctx.fillStyle = Theme.textPrimary;
                            ctx.fillText(label, tx, ty);
                            ctx.restore();

                            if (f > 0.005) {
                                ctx.save();
                                wavePath(front);
                                ctx.clip();
                                ctx.fillStyle = Qt.rgba(0, 0, 0, 0.78);
                                ctx.fillText(label, tx, ty);
                                ctx.restore();
                            }
                        }
                    }

                    Behavior on fill {
                        NumberAnimation {
                            duration: 900
                            easing.type: Easing.OutBack
                            easing.overshoot: 0.7
                        }
                    }

                    Behavior on amplitude {
                        NumberAnimation { duration: 500 }
                    }

                    NumberAnimation on phase {
                        from: 0
                        to: 2 * Math.PI
                        duration: 2800
                        loops: Animation.Infinite
                        running: root.showList
                    }

                    NumberAnimation on bubbleT {
                        from: 0
                        to: 1
                        duration: 3200
                        loops: Animation.Infinite
                        running: root.showList && root.charging
                    }
                }
            }

            // ======================= OTHER DEVICES =======================
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 22
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            Text {
                Layout.topMargin: 12
                color: Theme.textSecondary

                font {
                    family: Theme.fontFamily
                    pixelSize: 14
                }

                text: "OTHER DEVICES"
            }

            Text {
                Layout.topMargin: 6
                color: Theme.textMuted
                visible: root.peripherals.length === 0

                font {
                    family: Theme.fontFamily
                    pixelSize: 13
                }

                text: "Nothing else is reporting a battery"
            }

            Repeater {
                model: root.peripherals

                delegate: RowLayout {
                    id: devRow

                    required property var modelData

                    readonly property int lvl: Math.round(modelData.percentage * 100)
                    readonly property bool devCharging: modelData.state === UPowerDeviceState.Charging
                    readonly property color accent: BatUtils.levelColorFor(modelData.percentage, devCharging)
                    

                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    spacing: 12

                    // Type glyph
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        color: devRow.accent

                        font {
                            family: Theme.fontFamily
                            pixelSize: 15
                        }

                        text: BatUtils.deviceIcon(devRow.modelData.type)
                    }

                    // Name + state
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            color: Theme.textPrimary
                            elide: Text.ElideRight

                            font {
                                family: Theme.fontFamily
                                pixelSize: 15
                            }

                            text: BatUtils.deviceName(devRow.modelData)
                        }

                        Text {
                            color: Theme.textSecondary
                            visible: devRow.devCharging

                            font {
                                family: Theme.fontFamily
                                pixelSize: 11
                            }

                            text: "charging"
                        }
                    }

                    // Level bar
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 86
                        Layout.preferredHeight: 5
                        radius: 2.5
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Rectangle {
                            color: devRow.accent
                            height: parent.height
                            radius: parent.radius
                            width: parent.width * Math.max(0, Math.min(1,
                                       root.showList ? devRow.modelData.percentage : 0))

                            Behavior on width {
                                NumberAnimation {
                                    duration: 700
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    // Percentage
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 44
                        color: Theme.textPrimary
                        horizontalAlignment: Text.AlignRight

                        font {
                            bold: true
                            family: Theme.fontFamily
                            pixelSize: 15
                        }

                        text: devRow.lvl + "%"
                    }
                }
            }
        }
    }
}