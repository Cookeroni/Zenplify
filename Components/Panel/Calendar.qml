import QtQuick
import QtQuick.Layouts
import qs

// Self-contained month grid. Pure JS Date — no service. Today is highlighted;
// arrows page through months.
Item {
    id: root

    implicitWidth: 300
    implicitHeight: col.implicitHeight

    readonly property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()          // 0-11

    function prevMonth() {
        if (root.viewMonth === 0) { root.viewMonth = 11; root.viewYear--; }
        else root.viewMonth--;
    }
    function nextMonth() {
        if (root.viewMonth === 11) { root.viewMonth = 0; root.viewYear++; }
        else root.viewMonth++;
    }

    // 42 cells (6 weeks). 0 means a blank cell (outside the current month).
    readonly property var cells: {
        var first = new Date(root.viewYear, root.viewMonth, 1);
        var start = first.getDay();                    // 0 = Sunday
        var dim = new Date(root.viewYear, root.viewMonth + 1, 0).getDate();
        var c = [];
        for (var i = 0; i < start; i++) c.push(0);
        for (var d = 1; d <= dim; d++) c.push(d);
        while (c.length < 42) c.push(0);
        return c;
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 10

        // ---- Month nav ----
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "󰅁"
                color: Theme.textSecondary
                font { family: Theme.fontFamily; pixelSize: 18 }
                MouseArea { anchors.fill: parent; onClicked: root.prevMonth() }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                color: Theme.textPrimary
                font { family: Theme.fontFamily; pixelSize: 15 }
            }
            Text {
                text: "󰅂"
                color: Theme.textSecondary
                font { family: Theme.fontFamily; pixelSize: 18 }
                MouseArea { anchors.fill: parent; onClicked: root.nextMonth() }
            }
        }

        // ---- Weekday headers ----
        GridLayout {
            Layout.fillWidth: true
            columns: 7

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.textMuted
                    font { family: Theme.fontFamily; pixelSize: 11 }
                }
            }
        }

        // ---- Day grid ----
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 2
            rowSpacing: 2

            Repeater {
                model: root.cells
                delegate: Item {
                    id: cell
                    required property int modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30

                    readonly property bool isToday: cell.modelData !== 0
                        && root.viewYear === root.today.getFullYear()
                        && root.viewMonth === root.today.getMonth()
                        && cell.modelData === root.today.getDate()

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        visible: cell.isToday
                        color: Theme.success
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: cell.modelData !== 0
                        text: cell.modelData
                        color: cell.isToday ? Theme.textAccent : Theme.textPrimary
                        font { family: Theme.fontFamily; pixelSize: 13 }
                    }
                }
            }
        }
    }
}
