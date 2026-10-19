import QtQuick
import qs.modules.components
import qs.modules.services

QuickToggleTile {
    id: root

    iconName: "notifications-disabled-symbolic"
    iconFallback: "notification-disabled-symbolic"
    on: ShellSettings.notificationsDndEnabled
    title: "DnD"
    subtitle: on ? "On" : "Off"
    onToggled: ShellSettings.notificationsDndEnabled = !ShellSettings.notificationsDndEnabled
    onTitleClicked: {
        PopupCoordinator.closeAll();
        SettingsState.openOn("notifications");
    }
}
