import Quickshell
import QtQuick
import qs

// One level of a tray item's menu. Recursive: entering a submenu mounts a child
// TrayMenuLevel while THIS level's QsMenuOpener stays alive. Keeping every
// opener on the path from the root alive is what makes lazily-populated
// submenus (nm-applet's "Available networks", VPN lists) actually fill in — a
// single re-pointed opener closes the parent and the app never populates the
// child. Only one level is visible at a time (drill-in); the ancestors are just
// hidden, not destroyed.
Column {
    id: level

    property var menuHandle            // QsMenuHandle for this level
    property int depth: 0
    signal requestClose()             // a leaf was triggered → close the drawer
    signal back()                     // this level's Back row → parent goes up

    spacing: 0

    QsMenuOpener {
        id: opener
        menu: level.menuHandle
    }

    // Handle of the submenu entered from this level, or null.
    property var _child: null

    // This level's own rows — hidden once a child level is open.
    Column {
        width: level.width
        visible: level._child === null
        spacing: 0

        // Back row (sub-levels only).
        Item {
            width: parent.width
            height: 28
            visible: level.depth > 0

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 6
                color: backMa.containsMouse ? Theme.bgAccent : "transparent"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: 6
                text: "‹  Back"
                color: Theme.textSecondary
                font { family: Theme.fontFamily; pixelSize: 13 }
            }
            MouseArea {
                id: backMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: level.back()
            }
        }

        Repeater {
            model: opener.children ? opener.children.values : []

            delegate: Item {
                id: mrow
                required property QsMenuEntry modelData

                width: level.width
                height: mrow.modelData.isSeparator ? 9 : 28

                // Separator
                Rectangle {
                    visible: mrow.modelData.isSeparator
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 6
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                // Hover background (enabled rows only)
                Rectangle {
                    visible: !mrow.modelData.isSeparator
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 6
                    color: rowMa.containsMouse && mrow.modelData.enabled
                           ? Theme.bgAccent : "transparent"
                }

                // Check/radio dot (from checkState — no enum coupling)
                Rectangle {
                    visible: !mrow.modelData.isSeparator
                             && mrow.modelData.checkState === Qt.Checked
                    anchors.verticalCenter: parent.verticalCenter
                    x: 8
                    width: 6; height: 6; radius: 3
                    color: Theme.textPrimary
                }

                Text {
                    id: lbl
                    visible: !mrow.modelData.isSeparator
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: arr.visible ? arr.left : parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 6
                    text: mrow.modelData.text
                    elide: Text.ElideRight
                    color: mrow.modelData.enabled ? Theme.textPrimary : Theme.textMuted
                    font { family: Theme.fontFamily; pixelSize: 13 }
                }

                Text {
                    id: arr
                    visible: !mrow.modelData.isSeparator && mrow.modelData.hasChildren
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    text: "›"
                    color: Theme.textSecondary
                    font { family: Theme.fontFamily; pixelSize: 15 }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !mrow.modelData.isSeparator && mrow.modelData.enabled
                    onClicked: {
                        if (mrow.modelData.hasChildren) {
                            // Prod lazily-populated submenus, then enter.
                            if (mrow.modelData.updateLayout)
                                mrow.modelData.updateLayout();
                            level._child = mrow.modelData;
                        } else {
                            mrow.modelData.triggered();
                            level.requestClose();
                        }
                    }
                }
            }
        }
    }

    // Deeper level — our opener above stays alive while this is shown. Loaded
    // by URL (not by type) so QML doesn't reject the self-reference as direct
    // recursion. Properties/signals are wired in onLoaded.
    Loader {
        id: childLoader
        active: level._child !== null
        visible: active
        source: "TrayMenuLevel.qml"

        onLoaded: {
            item.width = Qt.binding(() => level.width);
            item.menuHandle = Qt.binding(() => level._child);
            item.depth = level.depth + 1;
            item.requestClose.connect(level.requestClose);
            item.back.connect(() => { level._child = null; });
        }
    }
}
