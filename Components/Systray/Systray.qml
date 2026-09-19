import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import QtQuick
import qs

// System-tray pill. A small button at top-left that morphs into the systray
// panel — the same clip + animated width/height/radius idiom as Pill.qml —
// rather than the notification-style slide-in drawer. Collapsed it shows a
// glyph + count; expanded it shows the icon strip and, on right-click, that
// item's menu (rendered by the recursive TrayMenuLevel, which keeps a
// QsMenuOpener alive per level so lazy submenus populate).
PanelWindow {
    id: win

    readonly property bool hasItems: SystemTray.items.values.length > 0

    // Collapsed (button) geometry
    readonly property int buttonW: 40
    readonly property int buttonH: 32
    readonly property int buttonRadius: 10

    // Expanded (panel) geometry — width fixed, height follows content
    readonly property int panelW: 300
    readonly property int panelRadius: 16
    readonly property int pad: 16

    property bool expanded: false
    property var _selected: null          // SystemTrayItem whose menu is shown

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    anchors { top: true; bottom: true; left: true; right: true }

    // collapsed → only the button is clickable (rest passes through);
    // expanded → whole screen clickable so the outside catcher can collapse it.
    mask: Region { item: expanded ? outside : (hasItems ? morph : blank) }
    Item { id: blank; width: 0; height: 0 }

    // Outside-click catcher — collapses when clicking away. Below the morph so
    // the panel's own controls get their clicks first.
    MouseArea {
        id: outside
        anchors.fill: parent
        visible: win.expanded
        enabled: win.expanded
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: win.collapse()
    }

    // ---- Morphing pill/panel ---------------------------------------------
    Rectangle {
        id: morph
        visible: win.hasItems
        clip: true

        anchors { top: parent.top; left: parent.left; topMargin: 8; leftMargin: 12 }

        width:  win.expanded ? win.panelW : win.buttonW
        height: win.expanded ? (content.implicitHeight + win.pad * 2) : win.buttonH
        radius: win.expanded ? win.panelRadius : win.buttonRadius
        color: Theme.pillBg

        Behavior on width  { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
        Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
        Behavior on radius { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

        // Click-to-expand (collapsed only). Declared first so expanded content
        // sits on top and receives its own clicks.
        MouseArea {
            anchors.fill: parent
            enabled: !win.expanded
            onClicked: win.expand()
        }

        // ---- Collapsed content: glyph + count badge ----------------------
        Item {
            anchors.fill: parent
            visible: !win.expanded && morph.width < 80

            Text {
                anchors.centerIn: parent
                text: "󰀻"
                color: Theme.textPrimary
                font { family: Theme.fontFamily; pixelSize: 18 }
            }

            Rectangle {
                anchors { right: parent.right; top: parent.top; rightMargin: 2; topMargin: 2 }
                width: 15; height: 15; radius: 7.5
                color: Theme.success

                Text {
                    anchors.centerIn: parent
                    text: SystemTray.items.values.length
                    color: Theme.textAccent
                    font { family: Theme.fontFamily; pixelSize: 9; bold: true }
                }
            }
        }

        // ---- Expanded content: header + icons + menu ---------------------
        // Fixed panel width so it doesn't reflow during the morph; just clipped.
        Column {
            id: content
            visible: win.expanded
            x: win.pad
            y: win.pad
            width: win.panelW - win.pad * 2
            spacing: 12

            Text {
                text: "System Tray"
                color: Theme.textPrimary
                font { family: Theme.fontFamily; pixelSize: 16; bold: true }
            }

            // Icon strip
            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: SystemTray.items.values

                    delegate: Rectangle {
                        id: iconCell
                        required property SystemTrayItem modelData

                        width: 36
                        height: 36
                        radius: 8
                        color: win._selected === modelData
                               ? Theme.panelScrim
                               : (iconMa.containsMouse ? Theme.bgAccent : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Image {
                            anchors.centerIn: parent
                            width: 20; height: 20
                            sourceSize.width: 20; sourceSize.height: 20
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            asynchronous: true
                            source: iconCell.modelData.icon
                            visible: status === Image.Ready
                        }

                        Rectangle {
                            visible: iconCell.modelData.status === SystemTrayItem.NeedsAttention
                            anchors { right: parent.right; top: parent.top; rightMargin: 3; topMargin: 3 }
                            width: 6; height: 6; radius: 3
                            color: Theme.danger
                        }

                        MouseArea {
                            id: iconMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            onClicked: (mouse) => {
                                const item = iconCell.modelData;
                                if (mouse.button === Qt.LeftButton) {
                                    if (item.onlyMenu) win.showMenuFor(item);
                                    else item.activate();
                                } else if (mouse.button === Qt.MiddleButton) {
                                    item.secondaryActivate();
                                } else if (mouse.button === Qt.RightButton) {
                                    win.showMenuFor(item);
                                }
                            }
                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y !== 0)
                                    iconCell.modelData.scroll(wheel.angleDelta.y, false);
                            }
                        }
                    }
                }
            }

            // ---- Menu section (only when an item is selected) ------------
            Column {
                width: parent.width
                spacing: 0
                visible: win._selected !== null

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                Item { width: 1; height: 8 }

                Text {
                    width: parent.width
                    text: win._selected ? (win._selected.title || win._selected.id) : ""
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                    font { family: Theme.fontFamily; pixelSize: 12 }
                }

                Item { width: 1; height: 4 }

                Loader {
                    width: parent.width
                    active: win._selected !== null
                    sourceComponent: TrayMenuLevel {
                        width: content.width
                        menuHandle: win._selected ? win._selected.menu : null
                        depth: 0
                        onRequestClose: win.collapse()
                    }
                }
            }
        }
    }

    // ---- Control ----------------------------------------------------------
    function expand() {
        win.expanded = true;
    }

    function collapse() {
        win.expanded = false;
        win._selected = null;
    }

    function showMenuFor(item) {
        if (!item.hasMenu) {
            win._selected = null;
            return;
        }
        win._selected = null;
        win._selected = item;
        if (item.menu && item.menu.updateLayout)
            item.menu.updateLayout();
    }
}
