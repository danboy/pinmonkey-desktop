pragma Singleton
import QtQuick
import Quickshell
import qs

// Transient "new notification" banner, shown briefly whenever a notification arrives - fed by
// Notifications.qml's onNotification handler. Suppressed while Do Not Disturb is on or while
// the notifications list (InfoPanel's popup) is already open, same reasoning as Osd.suppressed
// in modules/osd/Osd.qml.
Singleton {
    id: root

    property bool visible: false
    property bool suppressed: false
    property var notification: null

    function show(notification) {
        if (root.suppressed || ShellSettings.notificationsDndEnabled)
            return;
        root.notification = notification;
        root.visible = true;
        hideTimer.restart();
    }

    function hide() {
        root.visible = false;
        hideTimer.stop();
    }

    // The sender (or the server itself, on expiry) can close a notification out from under us
    // at any time - drop it immediately rather than holding a reference to a dead object, since
    // Connections re-targets (and safely detaches) whenever root.notification changes.
    Connections {
        target: root.notification

        function onClosed(reason) {
            root.hide();
            root.notification = null;
        }
    }

    Timer {
        id: hideTimer

        interval: Config.notificationToastVisibleMs
        onTriggered: root.visible = false
    }
}
