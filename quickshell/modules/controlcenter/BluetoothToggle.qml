import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.modules.components
import qs.modules.services

QuickToggleTile {
    id: root

    readonly property var connectedDevice: {
        for (const d of Bluetooth.devices.values)
            if (d.connected)
                return d;
        return null;
    }

    iconName: on ? "network-bluetooth-activated-symbolic" : "network-bluetooth-inactive-symbolic"
    iconFallback: "network-bluetooth-symbolic"
    on: Bluetooth.defaultAdapter?.enabled ?? false
    title: "Bluetooth"
    subtitle: on ? (connectedDevice ? connectedDevice.name : "On") : "Off"

    onToggled: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
    onTitleClicked: {
        PopupCoordinator.closeAll();
        SettingsState.openOn("bluetooth");
    }
}
