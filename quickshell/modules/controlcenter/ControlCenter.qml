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

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingSmall

            PowerMenu {
                Layout.fillWidth: true
            }

            IconToggle {
                // PowerMenu's own power icon sits inset by spacingSmall from the top of its
                // header row (see PowerMenu.qml's header RowLayout margins) - match that
                // offset here since this button is a sibling of PowerMenu, not inside its
                // header, so it isn't inset by the same margins automatically.
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: Config.spacingSmall
                implicitWidth: Config.tileIconBoxSize
                implicitHeight: Config.tileIconBoxSize
                iconName: "preferences-system-symbolic"
                iconFallback: "preferences-system"
                onClicked: {
                    PopupCoordinator.closeAll();
                    SettingsState.openOn("network");
                }
            }
        }

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

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingSmall

            DndToggle {}
        }

        VolumeControl {}

        BrightnessControl {}
    }
}
