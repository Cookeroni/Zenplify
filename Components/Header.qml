import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs

Item {
    property var pill
    property var wifi
    property var bt
    property var audioSink
    property var batt
    property bool listOpen: !(wifi.showList || bt.showList || audioSink.showList || batt.showList)
    
    implicitWidth: header.implicitWidth
    implicitHeight: header.implicitHeight

    anchors { 
        top: parent.top
        left: parent.left
        right: parent.right
        leftMargin: 6
        topMargin: 24
        rightMargin: 12
    }

    RowLayout {
        id: header
        
        anchors { fill: parent }
        spacing: 5

        // Return Button
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            color: "transparent"
            radius: 15

            // Icon
            Text {
                anchors { centerIn: parent }
                color: Theme.textPrimary
                text: ""

                font { 
                    pixelSize: 16 
                    family: Theme.fontFamily
                }
            }

            MouseArea {
                anchors { fill: parent }

                onClicked: {
                    if (wifi.showList) {
                        wifi.showList = false
                        wifi.pendingSsid = ""
                    } else if (bt.showList) {
                        bt.showList = false
                        bt.pendingMac = ""
                    } else if (audioSink.showList) {
                        audioSink.showList = false
                    } else if (batt.showList) {
                        batt.showList = false
                    }else {
                        pill.isExpanded = false // Close Panel
                    }
                }
            }
        }

        // Dynamic Label
        Text {
            Layout.alignment: Qt.AlignBaseline
            Layout.fillWidth: true
            Layout.topMargin: 2

            color: Theme.textPrimary
            elide: Text.ElideRight

             text: (wifi.showList) ? "Wi-Fi" 
                 : (bt.showList) ? "Bluetooth" 
                 : (audioSink.showList) ? "Audio Sink" 
                 : (batt.showList) ? "Battery" : "Control Panel"

            font {
                bold: true
                family: Theme.fontFamily
                pixelSize: 20
            }
        }

        // Display Date
        Text {
            visible: listOpen
            color: Theme.textPrimary
            text: Qt.formatDateTime(clockDate.date, "dddd, MMMM, d, yyyy")
            Layout.alignment: Qt.AlignBaseline


            font {
                pixelSize: 12
                family: Theme.fontFamily
            }

            SystemClock {
                id: clockDate
                precision: SystemClock.Hours
            }
        }

        // Rescan (Spins while scanning)
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            color: Theme.panelScrim
            radius: 15
            visible: wifi.showList || bt.showList

            // Icon
            Text {
                anchors { centerIn: parent }
                color: Theme.textPrimary
                text: "󰑐"

                font {
                    pixelSize: 15
                    family: Theme.fontFamily
                }

                transformOrigin: Item.Center

                RotationAnimator on rotation {
                    duration: 900
                    from: 0
                    loops: Animation.Infinite
                    running: wifi.showList ? wifi.scanning : bt.showList ? bt.scanning : false
                    to: 360
                }

                MouseArea {
                    anchors { fill: parent }
                    onClicked: wifi.showList ? wifi.rescan() : bt.showList ? bt.startScan() : ""
                }
            }
        }

        // Toggle On/Off
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 46
            Layout.preferredHeight: 26
            color: Theme.panelScrim
            radius: 13
            visible: wifi.showList || bt.showList

            Behavior on color {
                ColorAnimation {
                    duration: 160
                }
            }

            Rectangle {
                anchors { verticalCenter: parent.verticalCenter }
                color: (wifi.wifiEnabled && wifi.showList) || (bt.powered && bt.showList) 
                     ? Theme.textPrimary : Theme.textSecondary

                height: 20
                radius: 10
                width: 20
                x: (wifi.wifiEnabled && wifi.showList) ? parent.width - width - 3 
                 : (bt.powered && bt.showList) ? parent.width - width - 3 : 3

                Behavior on x {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutQuad
                    }
                }
            }

            MouseArea {
                anchors { fill: parent }
                onClicked: wifi.showList ? wifi.toggle() : ""
            }
        }
    }
}