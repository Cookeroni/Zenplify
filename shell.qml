import Quickshell
import QtQuick
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        id: panelWindow

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore


        // Focus keyboard only when typing a Wi-Fi password.
        WlrLayershell.keyboardFocus: pillBar.needsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Input mask defines click areas; outside clicks pass through to apps below.
        // - collapsed: mask = pill (rest clicks through)  
        // - expanded: mask = whole window (scrim catches clicks)
        mask: Region {
            item: pillBar.maskItem
        }

        Pill { id: pillBar }
    }
}