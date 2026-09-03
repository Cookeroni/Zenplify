import Quickshell
import QtQuick
import Quickshell.Services.Pipewire
import QtQuick.Layouts
import qs

import "../Utils/audioHelpers.js" as AudioUtils

Item {
    id: root

    Layout.fillWidth: true

    implicitWidth: tileView.width
    implicitHeight: tileView.height
    width: root.showList ? parent.width : implicitWidth 
    height: root.showList ? parent.height - root.y - 10
                                : implicitHeight 

    property bool tileHidden: false
    property bool showList: false

    // The system's current default output. Binds live — swaps automatically
    // when e.g. Bluetooth earbuds connect and PipeWire re-routes.
    readonly property var current: Pipewire.defaultAudioSink

    // All real audio output devices (exclude application playback streams).
    // .values is reactive, so this recomputes as devices come and go.
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

    // Keep every sink (and the default) bound so descriptions/volume are ready.
    PwObjectTracker {
        objects: root.sinks
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

            // Icon
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    color: Theme.textPrimary

                    font {
                        family: Theme.fontFamily
                        pixelSize: 20
                    }

                    text: AudioUtils.iconFor(root.current)
                }
            }

            // Label + Current Sink
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    color: Theme.textPrimary

                    font {
                        family: Theme.fontFamily
                        pixelSize: 15
                    }

                    text: "Audio"
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Theme.textSecondary

                    font {
                        family: Theme.fontFamily
                        pixelSize: 12
                    }

                    text: AudioUtils.labelFor(root.current)
                }
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

            // ---- Empty state ----
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.sinks.length === 0

                Text {
                    anchors { centerIn: parent }
                    color: Theme.textSecondary
                    

                    font {
                        family: Theme.fontFamily
                        pixelSize: 20
                    }

                    text: "No Audio Outputds Found"
                }
            }

            // Sink List
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.sinks.length > 0
                clip: true
                spacing: 6
                model: root.sinks

                delegate: Rectangle {
                    id: srow

                    required property var modelData
                    readonly property bool selected: AudioUtils.isCurrent(modelData)

                    width: ListView.view.width
                    height: 56
                    radius: 12
                    color: Theme.panelScrim
                    border.width: 1

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 22
                            rightMargin: 22
                        }
                        spacing: 12

                        // Icon
                        Text {
                            color: srow.selected ? Theme.textPrimary : Theme.textSecondary

                            font {
                                family: Theme.fontFamily
                                pixelSize: 18
                            }

                            text: AudioUtils.iconFor(srow.modelData)
                        }

                        // Label
                        Text {
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            color: Theme.textPrimary

                            font {
                                family: Theme.fontFamily
                                pixelSize: 14
                            }

                            text: AudioUtils.labelFor(srow.modelData)
                        }

                        // Current-device check
                        Text {
                            visible: srow.selected
                            color: Theme.success

                            font {
                                family: Theme.fontFamily
                                pixelSize: 15
                            }

                            text: "󰄬"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Pipewire.preferredDefaultAudioSink = srow.modelData
                    }
                }
            }
        }
    }
}