import QtQuick
import qs

// Generic draggable pill-slider. Source-agnostic: give it a value (0..1) and
// an icon glyph; it emits moved(fraction) as you drag. The panel wires each
// one to a service (Audio / Backlight).
Item {
    id: root

    property real value: 0                 // 0..1, driven by the service
    property string icon: ""
    property color fillColor: Theme.textPrimary
    signal moved(real value)               // user dragged; fraction 0..1

    implicitHeight: 28

    readonly property real _frac: Math.min(Math.max(root.value, 0), 1)
    // Track the finger 1:1 while dragging; otherwise follow the service value.
    readonly property real _target: dragArea.pressed ? dragArea.frac : root._frac

    // Animated fraction. It animates when the *value* changes, but the fill's
    // pixel width follows this instantly — so resizing the track (panel morph)
    // doesn't make the fill "grow in" on open.
    property real _shown: root._target
    Behavior on _shown {
        enabled: !dragArea.pressed
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    // Track
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.bgAccent

        // Fill (keeps at least one icon-width so the glyph always sits on green)
        Rectangle {
            height: parent.height
            radius: parent.radius
            width: Math.max(height, parent.width * root._shown)
            color: root.fillColor

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12
                text: root.icon
                color: Theme.textAccent
                font.family: Theme.fontFamily
                font.pixelSize: 16
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        property real frac: 0
        function update(x) {
            frac = Math.max(0, Math.min(1, x / width));
            root.moved(frac);
        }
        onPressed: (mouse) => update(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) update(mouse.x); }
    }
}
