import Quickshell
import QtQuick
import Quickshell.Services.Pipewire
import QtQuick.Layouts
import qs

import "../Utils/audioHelpers.js" as AudioUtils

Item {
    id: root

    implicitWidth: tileView.width
    implicitHeight: tileView.height
    width: root.showList ? parent.width : implicitWidth
    height: root.showList ? parent.height - root.y - 10
                                : implicitHeight

    property bool tileHidden: false
    property bool showList: false

    // ---------- Output (sinks) ----------
    readonly property var current: Pipewire.defaultAudioSink
    readonly property var sinks: {
        var out = []
        var all = Pipewire.nodes.values
        for (var i = 0; i < all.length; i++) {
            var n = all[i];
            if (n && n.isSink && !n.isStream)
                out.push(n);
        }
        return out
    }

    // ---------- Input (sources / mic) ----------
    // A source is an audio node that isn't a sink and isn't an app stream.
    readonly property var currentSource: Pipewire.defaultAudioSource
    readonly property bool micMuted: root.currentSource?.audio?.muted ?? false
    readonly property var sources: {
        var out = []
        var all = Pipewire.nodes.values
        for (var i = 0; i < all.length; i++) {
            var n = all[i];
            if (n && n.audio && !n.isSink && !n.isStream)
                out.push(n);
        }
        return out
    }

    function toggleMic() {
        if (root.currentSource?.ready && root.currentSource.audio)
            root.currentSource.audio.muted = !root.currentSource.audio.muted;
    }

    // Bind outputs + inputs (incl. the current defaults) so descriptions and
    // mute state are valid.
    PwObjectTracker {
        objects: root.sinks.concat(root.sources)
    }

    // Selectable device row, shared by both the output and input lists.
    component DeviceRow: Rectangle {
        id: drow
        property var node
        property bool selected: false
        property string iconGlyph: AudioUtils.iconFor(drow.node)
        signal chosen()

        width: ListView.view ? ListView.view.width : 0
        height: 56
        radius: 12
        color: Theme.panelScrim

        RowLayout {
            anchors { fill: parent; leftMargin: 22; rightMargin: 22 }
            spacing: 12

            Text {
                color: drow.selected ? Theme.textPrimary : Theme.textSecondary
                font { family: Theme.fontFamily; pixelSize: 18 }
                text: drow.iconGlyph
            }
            Text {
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                color: Theme.textPrimary
                font { family: Theme.fontFamily; pixelSize: 14 }
                text: AudioUtils.labelFor(drow.node)
            }
            Text {
                visible: drow.selected
                color: Theme.success
                font { family: Theme.fontFamily; pixelSize: 15 }
                text: "󰄬"
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: drow.chosen()
        }
    }

    // ============================ TILE VIEW ==========================
    Rectangle {
        id: tileView

        width: 170
        height: 50
        radius: 8

        visible: (root.showList || root.tileHidden) ? false : true
        color: Theme.panelScrim

        MouseArea {
            anchors.fill: parent
            onClicked: root.showList = true
        }

        RowLayout {
            anchors { fill: parent; margins: 2 }
            spacing: 0

            // Icon (current output)
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    color: Theme.textPrimary
                    font { family: Theme.fontFamily; pixelSize: 20 }
                    text: AudioUtils.iconFor(root.current)
                }
            }

            // Label + current output
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    color: Theme.textPrimary
                    font { family: Theme.fontFamily; pixelSize: 15 }
                    text: "Audio"
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Theme.textSecondary
                    font { family: Theme.fontFamily; pixelSize: 12 }
                    text: AudioUtils.labelFor(root.current)
                }
            }

            // Muted-mic indicator (only when the input is muted)
            Text {
                visible: root.micMuted
                text: "󰍭"
                color: Theme.danger
                Layout.rightMargin: 8
                font { family: Theme.fontFamily; pixelSize: 16 }
            }
        }
    }

    // ============================ LIST VIEW ==========================
    Item {
        id: listView

        anchors {
            fill: parent
            rightMargin: 24
        }
        visible: root.showList

        ColumnLayout {
            anchors { fill: parent }
            spacing: 8

            // ---------------- OUTPUT ----------------
            Text {
                text: "Output"
                color: Theme.textSecondary
                font { family: Theme.fontFamily; pixelSize: 13 }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    anchors.fill: parent
                    visible: root.sinks.length > 0
                    clip: true
                    spacing: 6
                    model: root.sinks

                    delegate: DeviceRow {
                        required property var modelData
                        node: modelData
                        selected: AudioUtils.isCurrent(root.current, modelData)
                        onChosen: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.sinks.length === 0
                    text: "No outputs found"
                    color: Theme.textMuted
                    font { family: Theme.fontFamily; pixelSize: 14 }
                }
            }

            // ---------------- INPUT ----------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Input"
                    color: Theme.textSecondary
                    font { family: Theme.fontFamily; pixelSize: 13 }
                }

                // Mic mute toggle
                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 24
                    radius: 6
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: root.micMuted ? "󰍭" : "󰍬"
                        color: root.micMuted ? Theme.danger : Theme.textPrimary
                        font { family: Theme.fontFamily; pixelSize: 16 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.toggleMic()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    anchors.fill: parent
                    visible: root.sources.length > 0
                    clip: true
                    spacing: 6
                    model: root.sources

                    delegate: DeviceRow {
                        required property var modelData
                        node: modelData
                        iconGlyph: "󰍬"
                        selected: AudioUtils.isCurrent(root.currentSource, modelData)
                        onChosen: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.sources.length === 0
                    text: "No inputs found"
                    color: Theme.textMuted
                    font { family: Theme.fontFamily; pixelSize: 14 }
                }
            }
        }
    }
}
