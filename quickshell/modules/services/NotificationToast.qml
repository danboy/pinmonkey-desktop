pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
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

    // The first toast of a burst - nothing was already showing when it arrived - stays up
    // (hideTimer never starts) if the user is away, so it's still there to read when they get
    // back, rather than having expired unseen. Anything that arrives while a toast is already
    // showing (including one being held like this) is a "subsequent" notification: it replaces
    // the display and dismisses on the normal schedule regardless of activity - it's still
    // captured in the notification tray either way (see Notifications.qml), so nothing is lost,
    // it just doesn't get to camp on screen waiting for the user too.
    function show(notification) {
        if (root.suppressed || ShellSettings.notificationsDndEnabled)
            return;
        const isFirstOfBurst = !root.visible;
        root.notification = notification;
        root.visible = true;
        if (isFirstOfBurst && idleMonitor.isIdle)
            hideTimer.stop();
        else
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

    // Fixed timeout, so unlike LockScreen.qml's IdleMonitor this needs no Loader-reload
    // trickery - nothing here ever changes `timeout` after creation.
    IdleMonitor {
        id: idleMonitor

        timeout: Config.notificationToastIdleTimeoutSec

        // The moment the user comes back, release whatever first-of-burst toast is being
        // held (see show() above). hideTimer.running already covers every other case: a
        // normal toast has it running from the start, so this is a no-op for those.
        onIsIdleChanged: if (!idleMonitor.isIdle && root.visible && !hideTimer.running)
            hideTimer.restart()
    }
}
