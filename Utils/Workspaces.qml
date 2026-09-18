import QtQuick
import qs
import qs.Utils

// Pill mini-bar view: the transient workspace flash. A position-only vertical
// viewport rail (current = bright capsule, neighbours = dim dots — no occupancy
// encoding) with the current workspace's name/index beside it. State lives in
// the Niri singleton; this is shown for ~2s on a switch, like Volume/Brightness.
Item {
    id: root

    readonly property int slotH: 8       // vertical pitch per workspace slot
    readonly property int viewH: 24      // visible rail height (~3 slots)

    // Rail viewport — clips to three slots; the reel slides under it.
    Item {
        id: viewport
        width: 6
        height: root.viewH
        clip: true
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter

        Column {
            id: reel
            width: parent.width
            spacing: 0

            // Slide so the active slot sits at the viewport's centre. Animates
            // between workspaces when you scroll several within one flash.
            y: root.viewH / 2 - (Niri.activeIdx * root.slotH + root.slotH / 2)
            Behavior on y {
                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: Niri.count
                delegate: Item {
                    width: reel.width
                    height: root.slotH

                    Rectangle {
                        anchors.centerIn: parent
                        readonly property bool current: index === Niri.activeIdx
                        width: 3
                        height: current ? 7 : 3
                        radius: 1.5
                        color: current ? Theme.textPrimary : Theme.textMuted
                        Behavior on height {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }

    // Current workspace name (or its index when unnamed).
    Text {
        anchors.left: viewport.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        text: Niri.name
        color: Theme.textPrimary
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter

        font {
            family: Theme.fontFamily
            pixelSize: 15
        }
    }
}
