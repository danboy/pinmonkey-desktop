import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.components
import qs.modules.services

ColumnLayout {
    id: root

    spacing: Config.spacingSmall

    QuickToggleTile {
        iconName: "notifications-disabled-symbolic"
        iconFallback: "notification-disabled-symbolic"
        on: ShellSettings.notificationsDndEnabled
        title: "Do Not Disturb"
        subtitle: on ? "New notifications are hidden" : "Off"
        onToggled: ShellSettings.notificationsDndEnabled = !ShellSettings.notificationsDndEnabled
    }

    Divider {}

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "This shell is the system notification daemon (no mako/dunst running " + "alongside it) - apps send notifications straight to it over D-Bus. Incoming " + "notifications appear in the Notifications widget on the lock screen and info " + "panel, and in the Control Center's Do Not Disturb toggle. There are no popup " + "toasts; everything collects into that list until dismissed. Do Not Disturb " + "above hides new notifications from that list without closing them for the " + "sending app."
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
    }

    Item {
        Layout.fillHeight: true
    }
}
