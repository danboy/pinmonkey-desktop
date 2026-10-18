pragma Singleton
import Quickshell
import Quickshell.Services.Notifications

// A single shared NotificationServer so only one DBus notification service is
// ever registered, even though multiple widgets (control center, lock screen)
// display the tracked notification list.
Singleton {
    id: root

    readonly property alias trackedNotifications: server.trackedNotifications

    function clearAll() {
        for (const n of server.trackedNotifications.values)
            n.dismiss();
    }

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        // NotificationServer disposes a notification right after this signal returns unless a
        // handler explicitly claims it via `tracked = true` - without this, every notification
        // vanishes silently (no `closed` signal, just gone) and never reaches trackedNotifications
        // or the toast below. Do Not Disturb piggybacks on the same flag: leaving it untracked
        // still lets the DBus call return normally for the sender, it just never shows up here.
        onNotification: notification => {
            notification.tracked = !ShellSettings.notificationsDndEnabled;
            NotificationToast.show(notification);
        }
    }
}
