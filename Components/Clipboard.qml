import Quickshell
import QtQuick
import Quickshell.Io
import QtQuick.Layouts
import qs

Item {
    id: root

    property bool tileHidden: false
    property bool showList: false

    // Parsed history: [{ id: "123", preview: "some text" }, ...]
    property var entries: []
    property string copiedId: ""

    implicitWidth: tileView.width
    implicitHeight: tileView.height

    width: showList ? parent.width : implicitWidth
    height: showList ? parent.height - root.y - 10 : implicitHeight

    onShowListChanged: if (showList) listProc.running = true


    // `cliphist list` → one "<id>\t<preview>" line per entry.
    Process {
        id: listProc

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                const lines = text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (line.length === 0) continue;
                    const tab = line.indexOf("\t");
                    if (tab === -1) continue;
                    out.push({
                        id: line.substring(0, tab),
                        preview: line.substring(tab + 1)
                    });
                }
                root.entries = out;
                //console.log("[list] entries:", out.length);
            }
        }
    }

        // Copy: decode the entry to its original bytes, then pipe those into
    // wl-copy's stdin (same fresh-process path as delete).
    Process {
        id: decodeProc

        property string pendingId: ""

        stdout: StdioCollector {
            onStreamFinished: {
                root.pipeToStdin(["wl-copy"], text);
                root.copiedId = decodeProc.pendingId;
                copiedReset.restart();
            }
        }
    }

    Timer {
        id: copiedReset
        interval: 1200
        onTriggered: root.copiedId = ""
    }

    // A fresh Process per stdin-write. Reusing one Process doesn't work: once its
    // stdin is closed to send EOF, write() is latched off for that object even if
    // stdinEnabled is set true again. A new object each time has an open stdin.
    Component {
        id: stdinProc

        Process {
            property string payload: ""
            property var onDone: null

            stdinEnabled: true

            onStarted: {
                //console.log("[del] writing:", JSON.stringify(payload));
                write(payload);
                stdinEnabled = false;   // EOF: cliphist reads the id and exits
            }

            onExited: (code, status) => {
                //console.log("[del] exit code:", code);
                if (onDone)
                    onDone();
                destroy();
            }
        }
    }

    function pipeToStdin(cmd, data, done) {
        const obj = stdinProc.createObject(root, { command: cmd, payload: data, onDone: done || null });
        if (!obj) {
            console.warn("[del] createObject FAILED");
            return;
        }
        obj.running = true;   // launch it — creating the object doesn't start it
    }

    // cliphist delete only reads the numeric id before the first tab; the
    // preview is ignored, so id + "\t" is all it needs.
    function deleteEntry(entry) {
        //console.log("[del] called:", entry.id);
        root.pipeToStdin(["cliphist", "delete"],
                         entry.id + "\t",
                         function() { console.log("[del] done, refreshing"); listProc.running = true; });
    }

    // Clears the entire cliphist database, then refreshes the (now empty) list.
    function clearAll() {
        //console.log("[clear] wiping clipboard");
        wipeProc.running = true;
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        onExited: (code, status) => listProc.running = true
    }

    function copyEntry(entry) {
        //console.log("[copy] called:", entry.id);
        decodeProc.pendingId = entry.id;
        decodeProc.command = ["cliphist", "decode", entry.id];
        decodeProc.running = true;
    }

    // ============================ TILE VIEW ==========================

    Rectangle {
        id: tileView

        width: 46
        height: 50
        radius: 8

        color: Theme.panelScrim
        visible: (root.showList || root.tileHidden) ? false : true
        
        //Icon
        Text {
            anchors.centerIn: parent
            color: Theme.textPrimary

            font {
                family: Theme.fontFamily
                pixelSize: 22
            }

            text: ""
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.showList = true
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
            spacing: 10

            // ---- Empty state ----
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.entries.length === 0

                Text {
                    anchors { centerIn: parent }
                    color: Theme.textMuted

                    font {
                        family: Theme.fontFamily
                        pixelSize: 20
                    }

                    text: "Clipboard is empty"
                }
            }

            // ---- Show Cliboard List ----
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.entries.length > 0
                clip: true
                spacing: 6
                model: root.entries

                delegate: Rectangle {
                    id: entryRow

                    required property var modelData

                    width: ListView.view.width
                    height: 44
                    radius: 6
                    color: Theme.panelScrim

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 8
                        }
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            maximumLineCount: 1

                            font {
                                family: Theme.fontFamily
                                pixelSize: 14
                            }

                            text: entryRow.modelData.preview
                        }

                        // Copy
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 24
                            horizontalAlignment: Text.AlignHCenter
                            color: root.copiedId === entryRow.modelData.id
                                   ? Theme.success
                                   : (copyArea.containsMouse ? Theme.textPrimary : Theme.textMuted)

                            font {
                                family: Theme.fontFamily
                                pixelSize: 16
                            }

                            // check when just copied, else copy glyph
                            text: root.copiedId === entryRow.modelData.id
                                  ? String.fromCodePoint(0xF012C)   // md-check
                                  : String.fromCodePoint(0xF018F)   // md-content-copy

                            MouseArea {
                                id: copyArea
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                onClicked: root.copyEntry(entryRow.modelData)
                            }
                        }


                        // Delete
                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 24
                            horizontalAlignment: Text.AlignHCenter
                            color: delArea.containsMouse ? Theme.danger : Theme.textMuted

                            font {
                                family: Theme.fontFamily
                                pixelSize: 16
                            }

                            text: "󰧧"

                            MouseArea {
                                id: delArea
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                onClicked: root.deleteEntry(entryRow.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}