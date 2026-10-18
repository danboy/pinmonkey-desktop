import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs
import qs.modules.components
import qs.modules.osd
import qs.modules.services

Rectangle {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0

    PwObjectTracker {
        objects: [root.sink]
    }

    clip: true
    color: Config.colSurfaceVariant
    visible: sink !== null
    implicitHeight: Config.pillHeight
    implicitWidth: statusIcons.implicitWidth + Config.pillPaddingHorizontal
    radius: Config.radiusPill
    border.width: Config.borderWidth
    border.color: Config.colBorder

    StatusIcons {
        id: statusIcons

        anchors.centerIn: parent
    }

    MouseArea {
        anchors.fill: parent

        onClicked: popup.visible = !popup.visible
        onWheel: wheel => {
            if (!root.sink)
                return;
            const step = 0.05;
            const delta = wheel.angleDelta.y > 0 ? step : -step;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.volume + delta));
        }
    }

    AnchoredPopup {
        id: popup

        anchorItem: root
        onVisibleChanged: Osd.suppressed = visible

        Connections {
            target: PopupCoordinator
            function onCloseAll() {
                popup.visible = false;
            }
        }

        PowerMenu {}

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Config.borderWidth
            color: Config.colDivider
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingSmall

            WifiToggle {}
            BluetoothToggle {}
        }

        VolumeControl {}

        BrightnessControl {}
    }
}
