import Quickshell
import QtQuick
import QtQuick.Layouts
import qs


RowLayout {
    property bool isVisible: true
    property bool showTime: true
    property bool showDate: false

    visible: isVisible

    // Display Time
    Text {
        visible: showTime
        color: Theme.textPrimary
        text: Qt.formatDateTime(clock.date, "h:mm A")

        font {
            pixelSize: 16
            letterSpacing: -1
            family: Theme.fontFamily
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }
    }
}