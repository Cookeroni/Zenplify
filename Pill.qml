import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Effects
import qs.Components


Item {
    id: root

    anchors.fill: parent

    property bool isExpanded: false
    property string pillContent: "clock"                // Set Default Pill Content

    readonly property Item maskItem: isExpanded ? root : morphPill
    readonly property bool showingProgress: pillContent === "volume" || pillContent === "brightness"

    // Pill Geometry (Not Expanded/Bar Mode)
    readonly property int pillH: 32
    readonly property int pillW: 125
    readonly property int pillRadius: 20

    // Pill Geometry (Expanded/Panel Mode)
    readonly property int panelH: 420
    readonly property int panelW: 490    
    readonly property int panelRadius: 24

    // Widen pill for Volume/Brightness Progress Bar
    readonly property int pillWiden: 200

    // True only when the panel is open AND a module needs text entry
    readonly property bool needsKeyboard: isExpanded && panel.needsKeyboard  

    // Catches outside clicks only when the panel is open.
    MouseArea {
        anchors.fill: parent
        enabled: root.isExpanded
        onClicked: root.isExpanded = false
    }

    // Pill Structure
    Rectangle {
        id: morphPill

        height: root.isExpanded ? root.panelH : root.pillH
        width: root.isExpanded ? root.panelW
                               : (root.showingProgress ? root.pillWiden : root.pillW)
        
        radius: root.isExpanded ? root.panelRadius : root.pillRadius

        clip: true
        color: Theme.pillBg

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 5
        }

        Clock {
            id: clockComp
            anchors.centerIn: parent
            visible: root.pillContent === "clock" && !root.isExpanded && morphPill.height < 50
        }

        Volume {
            id: volumeComp
            anchors.fill: parent
            visible: root.pillContent === "volume" && !root.isExpanded && morphPill.height < 50
        }

        Brightness {
            id: brightnessComp
            anchors.fill: parent
            visible: root.pillContent === "brightness" && !root.isExpanded && morphPill.height < 50
        }

        // Click to morph the Pill into Panel
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if(!root.isExpanded){
                    root.isExpanded = true
                }
            }
        }

        Behavior on width {
            NumberAnimation {
                id: widthAnim
                duration: 420
                easing.overshoot: 1.05
                easing.type: Easing.OutBack
                //easing.type: widthAnim.to > widthAnim.from ? Easing.OutBack : Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                id: heightAnim
                duration: 420
                easing.overshoot: 1.05
                easing.type: Easing.OutBack
                //easing.type: heightAnim.to > heightAnim.from ? Easing.OutBack : Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                id: radiusAnim
                duration: 420
                easing.overshoot: 1.05
                easing.type: Easing.OutBack
                //easing.type: radiusAnim.to > radiusAnim.from ? Easing.OutBack : Easing.OutCubic
            }
        }
    }

    Connections {
        target: volumeComp
        function onChanged() {
            if (root.isExpanded) return
            root.pillContent = "volume"
            visibilityTimer.restart()
        }
    }

    Connections {
        target: brightnessComp
        function onChanged() {
            if (root.isExpanded || brightnessRevertGuard.running) return
            root.pillContent = "brightness"
            visibilityTimer.restart()
        }
    }

    Timer {
        id: visibilityTimer

        interval: 2000
        repeat: false
        running: false

        onTriggered: {
            root.pillContent = "clock"
            brightnessRevertGuard.restart()
        }
    }

    // Swallows the trailing sysfs brightness read that lands just after a
    // revert, so it can't re-pop the pill while it's collapsing back to 125.
    Timer {
        id: brightnessRevertGuard

        interval: 800
        repeat: false
        running: false
    }
}