import Quickshell
import QtQuick
import Quickshell.Wayland

import "./Components/Notifications/"
import "./Components/Systray/"         

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

        mask: Region {
            item: pillBar.maskItem
        }

        Pill { id: pillBar }
    }

    // On-screen notification toasts
    NotificationPopups {}

    // Slide-out notification drawer + its trigger
    NotificationDrawer {}
    NotificationBell {}

    //Systray
    Systray {} 
}
