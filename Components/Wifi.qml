import Quickshell
import QtQuick
import Quickshell.Io
import QtQuick.Layouts
import QtQuick.Controls
import qs

import "../Utils/wifiHelpers.js" as WifiUtils

Item {
    id: root

    property var networks: []
    property var savedSsids: []
    property string currentSsid: ""
    property string pendingSsid: ""
    property bool wifiEnabled: true
    property bool scanning: false
    property bool showList: false
    property bool tileHidden: false

    property string connectingSsid: ""   // network we're actively authenticating
    property string connectError: ""     // ssid whose last connect attempt failed

    implicitWidth: tileView.width
    implicitHeight: tileView.height

    width: root.showList ? parent.width : implicitWidth 
    height: root.showList ? parent.height - root.y - 10
                                : implicitHeight    


    // True while a scan is running and we have nothing to show yet.
    readonly property bool showSkeleton: wifiEnabled && scanning && networks.length === 0

    readonly property int currentSignal: {
        for(let i = 0; i < networks.length; i++) {
            if(networks[i].inUse) return networks[i].signal;
        }
        return 0;
    }

    // True only while a password field is actually on screen
    readonly property bool passwordPrompt: {
        if(pendingSsid === "") return false;

        for(let i = 0; i < networks.length; i++) {
            const n = networks[i];
            if(n.ssid === pendingSsid) return !n.inUse && !!n.security && n.security !== "";
        }
        return false;
    }

    // Tile Icon
    readonly property string tileIcon: {
        return (!wifiEnabled) ? "󰤭" : (currentSsid.length === 0) ? "󰤯" : WifiUtils.iconForSignal(currentSignal)
    }

    // Tile Subtitle
    readonly property string tileSubtitle: {
        return (!wifiEnabled) ? "Off" : (currentSsid.length === 0) ? "Not Connected" : currentSsid
    }

    // Public actions for external callers (e.g. Panel tiles)
    function toggle() { WifiUtils.setWifi(toggleProc, !wifiEnabled) }
    function rescan() { WifiUtils.rescan(root, scanProc) }

    // Load current network state at startup for immediate display.
    // Run background updates periodically to keep the status fresh.
    Component.onCompleted: WifiUtils.refresh(radioProc, listProc, profilesProc)

    Process {
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            id: radioOut
            onStreamFinished: root.wifiEnabled = (radioOut.text.trim() === "enabled")
        }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list"]
        stdout: StdioCollector {
            id: listOut

            onStreamFinished: WifiUtils.parseList(root, listOut.text, listProc)
        }
    }

    Process {
        id: scanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        
        onExited: (code, status) => {
            listProc.running = true
        }
    }

    Process {
        id: toggleProc

        onExited: (code, status) => WifiUtils.refresh(radioProc, listProc, profilesProc)
    }

    Process {
        id: connectProc

        onExited: (code, status) => {
            const ssid = root.connectingSsid;
            root.connectingSsid = "";
            if (ssid !== "" && code !== 0) {
                // Connect/auth failed (e.g. wrong password) — keep the row open.
                root.connectError = ssid;
            } else {
                root.connectError = "";
                root.pendingSsid = "";
            }
            WifiUtils.refresh(radioProc, listProc, profilesProc);
        }
    }

    Process {
        id: profilesProc

        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]

        stdout: StdioCollector {
            id: profilesOut

            onStreamFinished: {
                const out = [];
                for (const line of profilesOut.text.split("\n")) {
                    if (line.length === 0)
                        continue;
                    const f = WifiUtils.parseTerse(line);   // [NAME, TYPE]
                    if (f[1] === "802-11-wireless")
                        out.push(f[0]);
                }
                root.savedSsids = out;
            }
        }
    }

    Process {
        id: monitorProc

        command: ["nmcli", "monitor"]
        running: true

        stdout: SplitParser {
            onRead: line => refreshDebounce.restart()
        }

        // If NetworkManager restarts, monitor exits — bring it back up
        // (delayed, so a hard failure can't spin into a tight restart loop).
        onExited: (code, status) => monitorRestart.start()
    }

    // Debounce: NetworkManager often emits several lines for one event so
    // group them into a single refresh instead of spawning nmcli per line.
    Timer {
        id: refreshDebounce

        interval: 300
        repeat: false

        onTriggered: WifiUtils.refresh(radioProc, listProc, profilesProc)
    }

    Timer {
        id: monitorRestart
        interval: 2000
        repeat: false

        onTriggered: monitorProc.running = true
    }

    // 'nmcli monitor' misses signal drift and new APs; these require 'wifi list'.
    // Poll 'wifi list' ONLY when the list view is open for live signal bars.
    // Stop all polling when the view is closed to save resources.
    Timer {
        interval: 5000
        repeat: true
        running: root.showList && root.pendingSsid === ""

        onTriggered: WifiUtils.refresh(radioProc, listProc, profilesProc)
    }

    // ============================ TILE VIEW ==========================
    Rectangle {
        id: tileView

        width: 135
        height: 50
        radius: 8
        visible: (root.showList || root.tileHidden) ? false : true
        color: Theme.panelScrim

        MouseArea {
            anchors { fill: parent }
            onClicked: {
                root.showList = true
                WifiUtils.refresh(radioProc,listProc,profilesProc)
                WifiUtils.rescan(root, scanProc)
            }
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
                    anchors { centerIn: parent }
                    color: root.wifiEnabled ? Theme.textPrimary : Theme.textMuted

                    font {
                        pixelSize: 20
                        family: Theme.fontFamily
                    }

                    text: root.wifiEnabled ? "󰖩" : "󰖪"
                }
            }

            // Current Network
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: "Wi-Fi"
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

                    text: root. tileSubtitle
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
                visible: !wifiEnabled

                Text {
                    anchors { centerIn: parent }
                    text: "Wi-Fi is off"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                }
            }

            // ---- Scanning skeleton ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: root.showSkeleton

                Repeater {
                    model: 5
                    delegate: SkeletonRow {
                        Layout.fillWidth: true
                        animate: root.showSkeleton
                    }
                }

                Item { Layout.fillWidth: true; Layout.fillHeight: true }
            }

            // ---- Network list ----
            ListView {
                Layout.fillHeight: true
                Layout.fillWidth: true
                clip: true
                model: root.networks
                // spacing: 6
                visible: root.wifiEnabled && !root.showSkeleton

                delegate: Rectangle {
                    id: row

                    property bool pwReveal: false
                    required property var modelData
                    readonly property bool connecting: root.connectingSsid === modelData.ssid
                    readonly property bool expanded: root.pendingSsid === modelData.ssid || connecting
                    readonly property bool saved: WifiUtils.isSaved(root.savedSsids, modelData.ssid)
                    readonly property bool secured: modelData.security && modelData.security !== ""

                    clip: true
                    color: modelData.inUse ? Theme.panelScrim : Theme.bgAccent
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
                                text: WifiUtils.iconForSignal(modelData.signal)
                            }

                            // SSID + security
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                    font.bold: modelData.inUse
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    text: modelData.ssid
                                }
                                Text {
                                    color: modelData.inUse ? Theme.textSecondary : Theme.danger
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    text: (root.connectError === modelData.ssid) ? "Wrong password"
                                        : modelData.inUse ? "Connected"
                                        : (modelData.security && modelData.security !== "" ? "Secured" : "Open")
                                }
                            }

                            // Lock icon for secured networks
                            Text {
                                color: modelData.inUse ? Theme.success : Theme.textSecondary                   
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                text: (modelData.inUse) ? "" : (modelData.security && modelData.security !== "") ? "󰌾" : ""
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !row.connecting

                            onClicked: {
                                if (row.expanded) {            // tap again to collapse
                                    root.pendingSsid = "";
                                } else if (row.modelData.inUse) {
                                    root.pendingSsid = row.modelData.ssid;   // show options
                                } else if (row.saved) {
                                    root.connectingSsid = row.modelData.ssid; // no password!
                                    WifiUtils.connectKnown(connectProc, row.modelData.ssid);
                                } else if (row.secured) {
                                    root.pendingSsid = row.modelData.ssid;   // ask password
                                } else {
                                    root.connectingSsid = row.modelData.ssid; // open network
                                    WifiUtils.connectOpen(connectProc, row.modelData.ssid);
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
                        visible: row.modelData.inUse && !row.connecting

                        // Disconnect
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            color: Theme.textMuted
                            radius: 8

                            Text {
                                anchors.centerIn: parent
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                text: "Disconnect"
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    WifiUtils.disconnect(connectProc, row.modelData.ssid);
                                    root.pendingSsid = "";
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
                                    WifiUtils.forget(connectProc, row.modelData.ssid);
                                    root.pendingSsid = "";
                                }
                            }
                        }
                    }

                    // Password Row
                    RowLayout {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: infoRow.bottom

                            leftMargin: 8
                            rightMargin: 8
                        }
                        height: 36
                        spacing: 8
                        visible: !row.modelData.inUse && row.secured && !row.connecting

                        TextField {
                            id: pwField

                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            color: Theme.textPrimary
                            echoMode: row.pwReveal ? TextInput.Normal : TextInput.Password
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            placeholderText: "Password"
                            placeholderTextColor: Theme.textPrimary
                            leftPadding: 15

                            background: Rectangle {
                                color: Theme.panelScrim
                                radius: 8
                                border.width: (root.connectError === row.modelData.ssid) ? 1 : 0
                                border.color: Theme.danger
                            }

                            onTextEdited: root.connectError = ""
                            onAccepted: {
                                if (text.length === 0) return;
                                root.connectError = "";
                                root.connectingSsid = row.modelData.ssid;
                                WifiUtils.connectSecured(connectProc, row.modelData.ssid, text);
                            }                           
                        }

                        // Eye Icon
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 36
                            color: "transparent"
                            radius: 8

                            Text {
                                anchors.centerIn: parent
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                                text: row.pwReveal ? "󰈉" : "󰈈"
                            }
                            MouseArea {
                                anchors.fill: parent

                                onCanceled: row.pwReveal = false
                                onPressed: row.pwReveal = true
                                onReleased: row.pwReveal = false
                            }
                        }

                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 70
                            color: "transparent"
                            radius: 8

                            Text {
                                anchors.centerIn: parent
                                color: Theme.success
                                font.bold: true
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                text: "Connect"
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (pwField.text.length === 0) return;
                                    root.connectError = "";
                                    root.connectingSsid = row.modelData.ssid;
                                    WifiUtils.connectSecured(connectProc, row.modelData.ssid, pwField.text);
                                }
                            }
                        }
                    }

                    // Connecting indicator: soft shimmer sweeps while authenticating.
                    Item {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: infoRow.bottom
                            topMargin: 4
                            leftMargin: 14
                            rightMargin: 14
                        }
                        height: 36
                        visible: row.connecting

                        RowLayout {
                            anchors.fill: parent
                            spacing: 10

                            Rectangle {
                                id: connTrack
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                radius: height / 2
                                color: Theme.bgAccent
                                clip: true

                                Rectangle {
                                    id: connShimmer
                                    height: parent.height
                                    width: parent.width * 0.5

                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 0.5; color: Theme.success }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }

                                    NumberAnimation on x {
                                        running: row.connecting
                                        loops: Animation.Infinite
                                        from: -connShimmer.width
                                        to: connTrack.width
                                        duration: 1100
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }

                            Text {
                                text: "Connecting…"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
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