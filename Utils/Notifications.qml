pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property bool drawerOpen: false            // NEW: notification drawer state

    readonly property var list: server.trackedNotifications ? server.trackedNotifications.values : []
    readonly property int count: root.list.length
    property var popups: []

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: (notif) => {
            notif.tracked = true;
            if (root.dnd)
                return;
            const p = root.popups.slice();
            p.push(notif);
            root.popups = p;
        }
    }

    property var _shownAt: ({})
    Timer {
        interval: 500
        repeat: true
        running: root.popups.length > 0
        onTriggered: {
            const now = Date.now();
            const kept = [];
            for (let i = 0; i < root.popups.length; i++) {
                const n = root.popups[i];
                if (!n || !n.tracked)
                    continue;
                if (root._shownAt[n.id] === undefined)
                    root._shownAt[n.id] = now;
                const critical = n.urgency === NotificationUrgency.Critical;
                if (critical || (now - root._shownAt[n.id]) < 5000)
                    kept.push(n);
            }
            if (kept.length !== root.popups.length)
                root.popups = kept;
        }
    }

    function popupDismiss(notif) { root.popups = root.popups.filter(n => n !== notif); }
    function dismiss(notif) {
        root.popups = root.popups.filter(n => n !== notif);
        if (notif) notif.dismiss();
    }
    function clearAll() {
        const l = root.list.slice();
        for (let i = 0; i < l.length; i++) l[i].dismiss();
        root.popups = [];
    }
}
