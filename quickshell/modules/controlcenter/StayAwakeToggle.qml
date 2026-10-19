import QtQuick
import qs.modules.components
import qs.modules.services

QuickToggleTile {
    id: root

    iconName: "preferences-desktop-screensaver-symbolic"
    iconFallback: "preferences-desktop-screensaver"
    on: ShellSettings.stayAwakeEnabled
    title: "Stay Awake"
    subtitle: on ? "Lock screen disabled" : "Off"

    onToggled: ShellSettings.stayAwakeEnabled = !ShellSettings.stayAwakeEnabled
    onTitleClicked: {
        PopupCoordinator.closeAll();
        SettingsState.openOn("lockscreen");
    }
}
