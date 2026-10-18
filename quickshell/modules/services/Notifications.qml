pragma Singleton
import Quickshell
import Quickshell.Services.Notifications

// A single shared NotificationServer so only one DBus notification service is
// ever registered, even though multiple widgets (control center, lock screen)
// display the tracked notification list.
Singleton {
    id: root

    readonly property alias trackedNotifications: server.trackedNotifications

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
    }
}
