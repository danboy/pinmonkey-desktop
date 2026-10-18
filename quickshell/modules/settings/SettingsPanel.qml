import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.services

Item {
    id: root

    readonly property var sections: [
        {
            id: "network",
            label: "Network"
        },
        {
            id: "bluetooth",
            label: "Bluetooth"
        },
        {
            id: "sound",
            label: "Sound"
        },
        {
            id: "display",
            label: "Display"
        },
        {
            id: "keyboard",
            label: "Keyboard"
        },
        {
            id: "mouse",
            label: "Mouse"
        },
        {
            id: "touchpad",
            label: "Touchpad"
        },
        {
            id: "tablet",
            label: "Tablet"
        },
        {
            id: "lockscreen",
            label: "Lock Screen"
        }
    ]

    function close() {
        SettingsState.open = false;
    }

    Connections {
        target: PopupCoordinator
        function onCloseAll() {
            root.close();
        }
    }

    IpcHandler {
        target: "settings"

        function show(tab: string): void {
            SettingsState.openOn(tab.length > 0 ? tab : "network");
        }

        function hide(): void {
            root.close();
        }
    }

    // Loader-gated so the layer-shell surface (and its on-demand keyboard focus) is fully
    // destroyed on close rather than left mapped-but-hidden - see Launcher.qml for the same
    // reasoning, and PopupCoordinator for why that matters (e.g. while the lock screen is up).
    Loader {
        active: SettingsState.open

        sourceComponent: WlrLayershell {
            id: settingsSurface

            screen: Quickshell.screens[0]
            layer: WlrLayer.Overlay
            namespace: "settings"
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

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                Rectangle {
                    id: card

                    anchors.centerIn: parent
                    width: Config.settingsWidth
                    height: Config.settingsHeight
                    radius: Config.radiusLarge
                    color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
                    border.width: Config.borderWidth
                    border.color: Config.colDivider

                    MouseArea {
                        // swallow clicks so the background MouseArea doesn't close the panel
                        anchors.fill: parent
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Config.popupMargin
                        spacing: Config.spacingLarge

                        ColumnLayout {
                            Layout.preferredWidth: Config.settingsNavWidth
                            Layout.minimumWidth: Config.settingsNavWidth
                            Layout.maximumWidth: Config.settingsNavWidth
                            Layout.fillHeight: true
                            spacing: Config.spacingXSmall

                            Repeater {
                                model: root.sections

                                delegate: Rectangle {
                                    id: navButton

                                    required property var modelData
                                    readonly property bool active: SettingsState.tab === modelData.id

                                    Layout.fillWidth: true
                                    implicitHeight: Config.settingsTabHeight
                                    radius: Config.radiusMedium
                                    color: navButton.active ? Config.colAccent : "transparent"
                                    border.width: Config.borderWidth
                                    border.color: navButton.active ? Config.colBorderAccent : "transparent"

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Config.spacingMedium
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: navButton.modelData.label
                                        font.family: Config.fontFamily
                                        font.bold: navButton.active
                                        font.pixelSize: Config.fontSizeCaption
                                        color: navButton.active ? Config.colAccentText : Config.colText
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: SettingsState.tab = navButton.modelData.id
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }

                        Rectangle {
                            Layout.fillHeight: true
                            implicitWidth: Config.borderWidth
                            color: Config.colDivider
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            NetworkSettings {
                                anchors.fill: parent
                                visible: SettingsState.tab === "network"
                            }

                            BluetoothSettings {
                                anchors.fill: parent
                                visible: SettingsState.tab === "bluetooth"
                            }

                            SoundSettings {
                                anchors.fill: parent
                                visible: SettingsState.tab === "sound"
                            }

                            DisplaySettings {
                                anchors.fill: parent
                                visible: SettingsState.tab === "display"
                            }

                            KeyboardSettings {
                                anchors.fill: parent
                                visible: SettingsState.tab === "keyboard"
                            }

                            MouseSettings {
                                anchors.fill: parent
                                visible: SettingsState.tab === "mouse"
                            }

                            TouchpadSettings {
                                anchors.fill: parent
                                visible: SettingsState.tab === "touchpad"
                            }

                            TabletSettings {
                                anchors.fill: parent
                                visible: SettingsState.tab === "tablet"
                            }

                            LockScreenSettings {
                                anchors.fill: parent
                                visible: SettingsState.tab === "lockscreen"
                            }
                        }
                    }
                }
            }
        }
    }
}
