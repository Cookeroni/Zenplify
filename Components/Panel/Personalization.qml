import QtQuick
import QtQuick.Layouts
import qs
import qs.Utils

// Personalization takeover: a home for customization tiles, mirroring the
// SystemMonitor takeover. Fills the panel body below the header; the panel
// Header supplies the title and back button. `view` switches between the tile
// grid and a tile's own editor. First tile: Workspaces (name mapping).
Rectangle {
    id: root

    property bool show: false
    property string view: "tiles"          // "tiles" | "workspaces"

    // Number of pre-nameable workspace slots (indices 1..slotCount).
    readonly property int slotCount: 7

    // Grab the keyboard while a text editor is open. Panel.needsKeyboard ORs this
    // in, which drives the layer-shell keyboard focus in shell.qml.
    readonly property bool needsKeyboard: show && view === "workspaces"

    // Reset to the grid whenever the area closes, so it always reopens on tiles.
    onShowChanged: if (!show) root.view = "tiles"

    visible: show
    color: Theme.pillBg

    // Absorb clicks so they don't reach the covered panel tiles.
    MouseArea { anchors.fill: parent }

    // ---- Tile grid ----
    Flow {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 8
            rightMargin: 8
            topMargin: 8
        }
        spacing: 12
        visible: root.view === "tiles"

        // One personalization tile: glyph + label, tap to open.
        component Tile: Rectangle {
            id: tile
            property string glyph
            property string label
            signal activated()

            width: 148
            height: 104
            radius: 16
            // Instant colour swap on hover, matching the panel's trigger buttons
            // (e.g. personBtnMa). Any colour Behavior here — even a short one —
            // stretches sub-frame hover jitter into a visible flash, so it's left off.
            color: tileMa.containsMouse ? Theme.panelScrim : Theme.bgAccent

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: tile.glyph
                    color: Theme.textPrimary
                    font { family: Theme.fontFamily; pixelSize: 26 }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: tile.label
                    color: Theme.textSecondary
                    font { family: Theme.fontFamily; pixelSize: 14 }
                }
            }

            MouseArea {
                id: tileMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: tile.activated()
            }
        }

        Tile {
            glyph: "󰕮"            // md-view-dashboard
            label: "Workspaces"
            onActivated: root.view = "workspaces"
        }
        // Future tiles (themes, nightlight defaults, …) drop in here.
    }

    // ---- Workspace name editor (fixed slots 1..slotCount, persisted) ----
    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: 12
            rightMargin: 12
            topMargin: 8
            bottomMargin: 8
        }
        spacing: 8
        visible: root.view === "workspaces"

        Text {
            Layout.fillWidth: true
            text: "Name a workspace by its index. Leave blank to fall back to its niri name, then its number. Saved to ~/.config/zenplify/workspace-names.json."
            color: Theme.textMuted
            wrapMode: Text.WordWrap
            font { family: Theme.fontFamily; pixelSize: 12 }
        }

        // One editable row per slot.
        component WsRow: RowLayout {
            id: wsRow
            property int idx

            Layout.fillWidth: true
            spacing: 12

            // Index badge — brighter when it's the currently focused workspace.
            Text {
                Layout.preferredWidth: 20
                text: wsRow.idx
                color: (wsRow.idx === Niri.idx) ? Theme.textPrimary : Theme.textMuted
                font { family: Theme.fontFamily; pixelSize: 14 }
            }

            // Editable field.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 8
                color: Theme.bgAccent
                border.width: input.activeFocus ? 1 : 0
                border.color: Theme.textMuted

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textPrimary
                    clip: true
                    selectByMouse: true
                    maximumLength: 24
                    font { family: Theme.fontFamily; pixelSize: 14 }

                    // Persist on Enter or focus loss.
                    onEditingFinished: WorkspaceNames.setLabel(wsRow.idx, text)

                    // Seed from disk, and follow external changes (disk reloads)
                    // without ever clobbering what the user is actively typing.
                    Component.onCompleted: text = WorkspaceNames.labelFor(wsRow.idx)
                    Connections {
                        target: WorkspaceNames
                        function onLabelsChanged() {
                            if (!input.activeFocus)
                                input.text = WorkspaceNames.labelFor(wsRow.idx);
                        }
                    }

                    // Placeholder: the number it falls back to when left blank.
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text.length === 0 && !input.activeFocus
                        text: wsRow.idx
                        color: Theme.textMuted
                        font: input.font
                    }
                }
            }
        }

        Repeater {
            model: root.slotCount
            WsRow { idx: index + 1 }
        }

        Item { Layout.fillHeight: true }
    }
}
