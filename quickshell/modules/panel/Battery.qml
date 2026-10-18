import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import qs

Rectangle {
    id: root

    property var batCharMin: (UPower.displayDevice.timeToFull / 60).toFixed(2)
    property var batDisMin: (UPower.displayDevice.timeToEmpty / 60).toFixed(2)
    readonly property bool charging: UPower.displayDevice.state == UPowerDeviceState.Charging
    readonly property int pct: Math.round(UPower.displayDevice.percentage * 100)

    function getBatStat() {
        if (UPower.displayDevice.state == UPowerDeviceState.Discharging)
            return Math.floor(batDisMin / 60) + "h " + ((batDisMin - (Math.floor(batDisMin / 60) * 60)).toFixed(0)) + "min";
        if (UPower.displayDevice.state == UPowerDeviceState.Charging)
            return Math.floor(batCharMin / 60) + "h " + ((batCharMin - (Math.floor(batCharMin / 60) * 60)).toFixed(0)) + "min";
        if (UPower.displayDevice.state == UPowerDeviceState.FullyCharged)
            return "Full";

        return "";
    }

    function batStatProc() {
        return pct + "%";
    }

    function batteryIconName() {
        let level;
        if (pct >= 90)
            level = "full";
        else if (pct >= 60)
            level = "good";
        else if (pct >= 35)
            level = "low";
        else if (pct >= 15)
            level = "caution";
        else
            level = "empty";

        return "battery-" + level + (root.charging ? "-charging" : "") + "-symbolic";
    }

    clip: true
    color: Config.colSurfaceVariant
    visible: UPower.displayDevice.isPresent
    implicitHeight: Config.pillHeight
    implicitWidth: rowLayout.implicitWidth + Config.pillPaddingHorizontal
    radius: Config.radiusPill
    border.width: Config.borderWidth
    border.color: Config.colBorder

    RowLayout {
        id: rowLayout

        anchors.centerIn: parent
        spacing: Config.spacingSmall

        IconImage {
            source: Quickshell.iconPath(root.batteryIconName(), "battery-full-symbolic")
            implicitSize: Config.iconSizeCaption
        }

        Text {
            id: batText

            text: batStatProc() + " · " + getBatStat()
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeCaption
            font.bold: true
            color: Config.colText
        }
    }

}
