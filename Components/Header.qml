import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs

Item {
    property var pill
    property var wifi
    property bool listOpen: !wifiModule.showList
    
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

             text: (wifi.showList) ? "Wi-Fi" : "Control Panel"

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
            visible: wifi.showList 

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
                    running: wifi.scanning
                    to: 360
                }

                MouseArea {
                    anchors { fill: parent }
                    onClicked: wifi.showList ? wifi.rescan() : ""
                }
            }
        }
    }
}