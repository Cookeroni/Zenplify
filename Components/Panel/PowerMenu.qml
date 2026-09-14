import QtQuick
import Quickshell.Io
import qs

// Bottom-left power menu: a power icon that slides open to reveal
// shutdown / restart / sleep / lock. State is local; the panel collapses it on close.
Item {
    id: root

    property bool expanded: false
    property string lockCmd: "swaylock"   // swap for hyprlock later

    implicitWidth: pill.width
    implicitHeight: 36

    Process { id: proc }
    function run(cmd) {
        proc.command = ["sh", "-c", cmd];
        proc.running = true;
        root.expanded = false;
    }

    // A single icon button (the toggle and the four actions).
    component PowerButton: Item {
        id: pb
        property string glyph
        property color tint: Theme.textPrimary
        property int box: 42
        signal tapped()

        width: box
        height: 36

        Text {
            anchors.centerIn: parent
            text: pb.glyph
            color: pb.tint
            opacity: pbMa.containsMouse ? 1.0 : 0.7
            font.family: Theme.fontFamily
            font.pixelSize: 18
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        MouseArea {
            id: pbMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: pb.tapped()
        }
    }

    Rectangle {
        id: pill
        height: 36
        color: Theme.pillBg
        clip: true

        readonly property int togW: 40
        readonly property int actW: 42
        width: root.expanded ? (togW + actW * 4) : togW

        Behavior on width {
            NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            // Toggle: power when closed, ✕ when open
            PowerButton {
                glyph: root.expanded ? "󰅖" : "󰣇"
                box: pill.togW
                onTapped: root.expanded = !root.expanded
            }

            PowerButton {                       // Shutdown
                glyph: "󰐥"
                box: pill.actW
                tint: Theme.danger
                onTapped: root.run("systemctl poweroff")
            }
            PowerButton {                       // Restart
                glyph: "󰜉"
                box: pill.actW
                tint: Theme.warning
                onTapped: root.run("systemctl reboot")
            }
            PowerButton {                       // Sleep / suspend
                glyph: "󰒲"
                box: pill.actW
                onTapped: root.run("systemctl suspend")
            }
            PowerButton {                       // Lock
                glyph: "󰌾"
                box: pill.actW
                onTapped: root.run(root.lockCmd)
            }
        }
    }
}
