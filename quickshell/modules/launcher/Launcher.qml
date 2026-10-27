import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs
import qs.modules.components
import qs.modules.services

Item {
    id: root

    readonly property var apps: {
        const list = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        list.sort((a, b) => a.name.localeCompare(b.name));
        return list;
    }
    property string query: ""
    readonly property var filtered: {
        const q = query.toLowerCase();
        const matches = !query ? apps : apps.filter(e => {
            if (e.name.toLowerCase().includes(q))
                return true;
            if (e.genericName && e.genericName.toLowerCase().includes(q))
                return true;
            return e.keywords.some(k => k.toLowerCase().includes(q));
        });
        // Apps previously picked after typing this same search bubble to the top, most-picked
        // first; everything else keeps its existing (alphabetical) order.
        return [...matches].sort((a, b) => LauncherState.scoreFor(query, b.id) - LauncherState.scoreFor(query, a.id));
    }
    property int selectedIndex: 0

    function openLauncher() {
        query = "";
        selectedIndex = 0;
        LauncherState.open = true;
    }

    function closeLauncher() {
        LauncherState.open = false;
    }

    function toggle() {
        if (LauncherState.open)
            closeLauncher();
        else
            openLauncher();
    }

    function moveSelection(delta) {
        selectedIndex = Math.max(0, Math.min(selectedIndex + delta, filtered.length - 1));
    }

    function launchSelected() {
        const entry = filtered[selectedIndex];
        if (entry) {
            LauncherState.recordSelection(query, entry.id);
            entry.execute();
            closeLauncher();
        }
    }

    onQueryChanged: selectedIndex = 0

    Connections {
        target: PopupCoordinator
        function onCloseAll() {
            root.closeLauncher();
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            root.toggle();
        }

        function show() {
            root.openLauncher();
        }

        function hide() {
            root.closeLauncher();
        }
    }

    CloseDelay {
        id: closeDelay

        open: LauncherState.open
    }

    // The window is only instantiated while open (plus a brief tail so the close animation
    // on `card` below can play), so closing fully destroys the layer-shell surface instead
    // of leaving a hidden exclusive-focus grab behind.
    Loader {
        active: closeDelay.active

        sourceComponent: WlrLayershell {
            // The active monitor at open time, not just "whichever niri enumerated first" -
            // see ActiveOutput.qml.
            screen: ActiveOutput.screen
            layer: WlrLayer.Overlay
            namespace: "launcher"
            color: "transparent"
            keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Component.onCompleted: Qt.callLater(() => searchField.forceActiveFocus())

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeLauncher()
            }

            Rectangle {
                id: card

                anchors.centerIn: parent
                width: Config.launcherWidth
                height: Config.launcherHeight
                radius: Config.radiusLarge
                color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
                border.width: Config.borderWidth
                border.color: Config.colDivider
                opacity: LauncherState.open ? 1 : 0
                scale: LauncherState.open ? 1 : 0.96

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

                MouseArea {
                    // swallow clicks so the background MouseArea doesn't close the launcher
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Config.popupMargin
                    spacing: Config.spacingLarge

                    TextField {
                        id: searchField

                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.launcherSearchHeight
                        placeholderText: "Search apps…"
                        text: root.query
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeBody
                        color: Config.colText
                        placeholderTextColor: Config.colSubtext
                        selectByMouse: true

                        onTextChanged: root.query = text
                        onAccepted: root.launchSelected()

                        Keys.onEscapePressed: root.closeLauncher()
                        Keys.onDownPressed: root.moveSelection(1)
                        Keys.onUpPressed: root.moveSelection(-1)

                        background: Rectangle {
                            radius: Config.radiusMedium
                            color: Config.colSurfaceVariant
                        }
                    }

                    ListView {
                        id: listView

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: Config.spacingXSmall
                        model: root.filtered
                        currentIndex: root.selectedIndex

                        delegate: LauncherRow {
                            required property var modelData
                            required property int index

                            iconName: modelData.icon
                            label: modelData.name
                            selected: index === root.selectedIndex

                            onActivated: {
                                root.selectedIndex = index;
                                root.launchSelected();
                            }
                        }
                    }
                }
            }
        }
    }
}
