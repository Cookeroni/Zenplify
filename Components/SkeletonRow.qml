import QtQuick
import QtQuick.Layouts
import qs

// A shimmering placeholder row, shown while a list is loading. A soft
// highlight sweeps across muted placeholder shapes that mimic a real row
// (signal icon + SSID label).
Rectangle {
    id: root

    property bool animate: true

    implicitHeight: 48
    radius: 10
    color: Theme.bgAccent
    clip: true

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 14
        }
        spacing: 12

        // Icon placeholder
        Rectangle {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            radius: 9
            color: Theme.textMuted
            opacity: 0.25
        }

        // SSID placeholder
        Rectangle {
            Layout.preferredWidth: 120
            Layout.preferredHeight: 10
            radius: 5
            color: Theme.textMuted
            opacity: 0.25
        }

        Item { Layout.fillWidth: true }
    }

    // Shimmer sweep
    Rectangle {
        id: shimmer
        height: parent.height
        width: parent.width * 0.5

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: "#14FFFFFF" }
            GradientStop { position: 1.0; color: "transparent" }
        }

        NumberAnimation on x {
            running: root.animate
            loops: Animation.Infinite
            from: -shimmer.width
            to: root.width
            duration: 1100
            easing.type: Easing.InOutQuad
        }
    }
}
