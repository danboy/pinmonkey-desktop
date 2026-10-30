import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.modules.components
import qs.modules.services

// Full-screen power menu: a blurred-backdrop overlay (see BlurredBackdrop.qml) with a
// centered card of action cards, toggled via PowerMenuState. Same surface/Loader pattern
// as DesktopWidgetLayer.qml and SettingsPanel.qml.
Item {
    id: root

    readonly property var actions: [
        {
            label: "Lock",
            iconName: "system-lock-screen-symbolic",
            iconFallback: "system-lock-screen",
            command: ["quickshell", "ipc", "call", "lock", "lock"]
        },
        {
            label: "Log out",
            iconName: "system-log-out-symbolic",
            iconFallback: "system-log-out",
            command: ["niri", "msg", "action", "quit"]
        },
        {
            label: "Switch user",
            iconName: "system-switch-user-symbolic",
            iconFallback: "system-switch-user",
            command: ["dbus-send", "--system", "--dest=org.gnome.DisplayManager", "--type=method_call", "/org/gnome/DisplayManager/LocalDisplayFactory", "org.gnome.DisplayManager.LocalDisplayFactory.CreateTransientDisplay"]
        },
        {
            label: "Suspend",
            iconName: "system-suspend-symbolic",
            iconFallback: "system-suspend",
            command: ["systemctl", "suspend"]
        },
        {
            label: "Restart",
            iconName: "system-reboot-symbolic",
            iconFallback: "system-reboot",
            command: ["systemctl", "reboot"]
        },
        {
            label: "Power off",
            iconName: "system-shutdown-symbolic",
            iconFallback: "system-shutdown",
            command: ["systemctl", "poweroff"]
        }
    ]

    function close() {
        PowerMenuState.open = false;
    }

    function run(command) {
        root.close();
        Quickshell.execDetached(command);
    }

    Connections {
        target: PopupCoordinator
        function onCloseAll() {
            root.close();
        }
    }

    CloseDelay {
        id: closeDelay

        open: PowerMenuState.open
    }

    // Fresh one-shot capture on every real open, same reasoning as DesktopWidgetLayer.qml.
    Connections {
        target: PowerMenuState
        function onOpenChanged(): void {
            if (PowerMenuState.open)
                blur.capture();
        }
    }

    // Loader-gated so the layer-shell surface (and its on-demand keyboard focus) is fully
    // destroyed on close rather than left mapped-but-hidden - see Launcher.qml/
    // SettingsPanel.qml for the same reasoning.
    Loader {
        active: closeDelay.active

        sourceComponent: WlrLayershell {
            id: powerSurface

            screen: Quickshell.screens[0]
            layer: WlrLayer.Overlay
            namespace: "power-menu"
            color: "transparent"
            keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Component.onCompleted: Qt.callLater(() => focusScope.forceActiveFocus())

            FocusScope {
                id: focusScope

                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: root.close()

                BlurredBackdrop {
                    id: blur

                    anchors.fill: parent
                    surface: powerSurface
                    topInset: Config.barHeight
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, Config.desktopWidgetScrimOpacity)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                Rectangle {
                    id: card

                    anchors.centerIn: parent
                    width: grid.implicitWidth + Config.popupMargin * 2
                    height: grid.implicitHeight + Config.popupMargin * 2
                    radius: Config.radiusLarge
                    color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
                    border.width: Config.borderWidth
                    border.color: Config.colDivider
                    opacity: PowerMenuState.open ? 1 : 0
                    scale: PowerMenuState.open ? 1 : 0.96

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Config.animationDurationMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Config.animationDurationMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    // swallow clicks so the background MouseArea doesn't close the modal
                    MouseArea {
                        anchors.fill: parent
                    }

                    GridLayout {
                        id: grid

                        anchors.centerIn: parent
                        columns: Config.powerModalColumns
                        rowSpacing: Config.spacingLarge
                        columnSpacing: Config.spacingLarge

                        Repeater {
                            model: root.actions

                            delegate: Rectangle {
                                id: actionCard

                                required property var modelData

                                implicitWidth: Config.powerModalCardSize
                                implicitHeight: Config.powerModalCardSize
                                radius: Config.radiusMedium
                                color: Config.colSurfaceVariant
                                border.width: Config.borderWidth
                                border.color: cardHover.hovered ? Config.colBorderAccent : Config.colBorder

                                HoverHandler {
                                    id: cardHover
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: Config.spacingMedium

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: Config.powerModalCardIconBoxSize
                                        implicitHeight: Config.powerModalCardIconBoxSize
                                        radius: Config.radiusSmall
                                        color: Config.colSurfaceHighlight
                                        border.width: Config.borderWidth
                                        border.color: Config.colBorder

                                        IconImage {
                                            anchors.centerIn: parent
                                            source: Quickshell.iconPath(actionCard.modelData.iconName, actionCard.modelData.iconFallback)
                                            implicitSize: Config.iconSizeMedium
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: actionCard.modelData.label
                                        font.family: Config.fontFamily
                                        font.pixelSize: Config.fontSizeCaption
                                        color: Config.colText
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.run(actionCard.modelData.command)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
