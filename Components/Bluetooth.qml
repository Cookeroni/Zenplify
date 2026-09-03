import Quickshell
import QtQuick
import Quickshell.Io
import QtQuick.Layouts
import QtQuick.Controls
import qs

import "../Utils/btHelpers.js" as BluetoothUtils

Item {
    id: root

    Layout.fillWidth: true

    property bool tileHidden: false
    property bool showList: false
    property bool powered: true
    property bool scanning: false
    property string connectedName: ""
    property string pendingMac: ""
    property var devices: []

    implicitWidth: tileView.width
    implicitHeight: tileView.height
    width: root.showList ? parent.width : implicitWidth 
    height: root.showList ? parent.height - root.y - 10 : implicitHeight 

    readonly property string tileIcon: {
        return (!powered) ? "󰂲" : (connectedName.length > 0) ? "󰂱" : "󰂯"
    }

    readonly property string tileSubtitle: {
        return (!powered) ? "Off" : (connectedName.length > 0) ? connectedName : "On/Stand-By"
    }

    function startScan() { BluetoothUtils.startScan(powered, scanning, scanProc) }
    function setPower() { BluetoothUtils.setPower(actionProc, !root.powered) }

    // Initial load so the tile is populated before it's opened.
    Component.onCompleted: BluetoothUtils.refresh(infoProc)

    Process {
        id: infoProc
        command: ["sh", "-c",
            "echo '##SHOW##'; bluetoothctl show; "
            + "echo '##ALL##'; bluetoothctl devices; "
            + "echo '##CONN##'; bluetoothctl devices Connected; "
            + "echo '##PAIR##'; bluetoothctl devices Paired"]
        stdout: StdioCollector {
            id: infoOut
            onStreamFinished: BluetoothUtils.parseInfo(devices,connectedName,infoOut.text)
        }
    }

    // Bounded scan: discovers for 15s then exits on its own.
    Process {
        id: scanProc
        command: ["bluetoothctl", "--timeout", "15", "scan", "on"]
        onExited: (code, status) => {
            root.scanning = false;
            BluetoothUtils.refresh(infoProc);
        }
    }

    Process {
        id: actionProc
        onExited: (code, status) => {
            root.pendingMac = "";
            BluetoothUtils.refresh(infoProc);
        }
    }

    // Pick up newly-discovered devices during a scan.
    Timer {
        interval: 2000
        repeat: true
        running: root.scanning
        onTriggered: BluetoothUtils.refresh(infoProc)
    }

    // Catch external changes while browsing the list (no idle polling).
    Timer {
        interval: 4000
        repeat: true
        running: root.showList && !root.scanning
        onTriggered: BluetoothUtils.refresh(infoProc)
    }

    // ============================ TILE VIEW ==========================
    Rectangle {
        id: tileView

        width: 140
        height: 50
        radius: 8
        visible: (root.showList || root.tileHidden) ? false : true
        color: Theme.panelScrim

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.showList = true;
                BluetoothUtils.refresh(infoProc);
                BluetoothUtils.startScan(powered, scanning, scanProc);
            }
        }

        RowLayout {
            anchors { fill: parent; margins: 2 }
            spacing: -3

            // Icon
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                color: "transparent"

                Text {
                    anchors { centerIn: parent }

                    color: root.powered ? Theme.textPrimary : Theme.textMuted

                    font {
                        family: Theme.fontFamily
                        pixelSize: 20
                    }

                    text: root.tileIcon
                }
            }
            
            // Current Connected Device
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: "Bluetooth"
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
                    elide: Text.ElideRight

                    font {
                        family: Theme.fontFamily
                        pixelSize: 12
                    }

                    text: root.tileSubtitle
                }
            }

        }
        Behavior on color { ColorAnimation { duration: 160 } }
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
            
            // ---- Off state ----
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !powered

                Text {
                    anchors { centerIn: parent }
                    color: Theme.textSecondary

                    font {
                        family: Theme.fontFamily
                        pixelSize: 20
                    }

                    text: "Bluetooth is off"
                }
            }

            // Device List
            ListView{
                Layout.fillHeight: true
                Layout.fillWidth: true
                clip: true
                model: root.devices
                visible: root.powered

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    readonly property bool known: modelData.connected || modelData.paired
                    readonly property bool expanded: root.pendingMac === modelData.mac

                    clip: true
                    color: modelData.connected ? Theme.panelScrim : Theme.bgAccent
                    width: ListView.view.width
                    height: expanded ? 100 : 48
                    radius: 10

                    // Info Row
                    Item {
                        id: infoRow

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: 48

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 14
                                rightMargin: 14
                            }
                            spacing: 12

                            // Signal icon
                            Text {
                                color: Theme.textPrimary
                                font {
                                    family: Theme.fontFamily
                                    pixelSize: 18
                                }
                                text: BluetoothUtils.iconFor(row.modelData.connected)
                            }

                            // Device Name + MAC
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    color: Theme.textPrimary 
                                    verticalAlignment: Text.AlignVCenter

                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: 13
                                    }
                                    text: row.modelData.named ? row.modelData.name : "Unknown device"
                                }

                                // - Unnamed: 2 lines to show address.
                                // - Named: 1 line to stay centered (status shown via highlight/icon).
                                Text {
                                    visible: !row.modelData.named
                                    color: Theme.textSecondary
                                    
                                    font {
                                        family: Theme.fontFamily
                                        pixelSize: 10
                                    }

                                    text: row.modelData.mac
                                }
                            }

                            // Status
                            Text {
                                visible: row.modelData.connected
                                color: Theme.success

                                font {
                                    family: Theme.fontFamily
                                    pixelSize: 15
                                }
                                text: "󰄬"

                            }
                        }

                        MouseArea {
                            anchors { fill: parent }
                            onClicked: {
                                if (row.expanded) {
                                    root.pendingMac = "";
                                } else if (row.known) {
                                    root.pendingMac = row.modelData.mac;   // show options
                                } else {
                                    BluetoothUtils.pairDev(actionProc, row.modelData.mac);       // discovered -> pair
                                }
                            }
                        }
                    }

                    // Options Row
                    RowLayout {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: infoRow.bottom
                            topMargin: 4
                            leftMargin: 8
                            rightMargin: 8
                        }
                        height: 36
                        spacing: 8
                        visible: row.expanded

                        // Disconnect/Connect
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            color: Theme.textMuted
                            radius: 8

                            Text {
                                anchors { centerIn: parent }
                                color: Theme.textPrimary

                                font {
                                    bold: true
                                    family: Theme.fontFamily
                                    pixelSize: 12
                                }

                                text: row.modelData.connected ? "Disconnect" : "Connect"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (row.modelData.connected)
                                        BluetoothUtils.disconnectDev(actionProc,row.modelData.mac);
                                    else
                                        BluetoothUtils.connectDev(actionProc,row.modelData.mac);
                                    root.pendingMac = "";
                                }
                            }
                        }

                        // Forget
                        Rectangle {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                color: Theme.danger
                                radius: 8

                                Text {
                                    anchors { centerIn: parent }
                                    color: Theme.textAccent

                                    font {
                                        bold: true
                                        family: Theme.fontFamily
                                        pixelSize: 12
                                    }

                                    text: "Forget"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                    BluetoothUtils.forgetDev(actionProc,row.modelData.mac);
                                    root.pendingMac = "";
                                }
                            }
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }

    }
}