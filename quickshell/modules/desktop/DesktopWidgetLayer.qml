import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.modules.components
import qs.modules.services

// Freeform widget canvas, toggled from the bar's grid icon (see Panel.qml). Unlike the lock
// screen's grid, these aren't slotted into columns - each entry in ShellSettings.desktopWidgets
// carries its own absolute x/y/width/height, dragged and resized directly on this surface.
Item {
    id: root

    IpcHandler {
        target: "desktopwidgets"

        function toggle(): void {
            DesktopWidgetsState.open = !DesktopWidgetsState.open;
        }

        function show(): void {
            DesktopWidgetsState.open = true;
        }

        function hide(): void {
            DesktopWidgetsState.open = false;
        }
    }

    CloseDelay {
        id: closeDelay

        open: DesktopWidgetsState.open
    }

    // The window is only instantiated while open (plus a brief tail for the close animation
    // below), same reasoning as Launcher.qml - fully destroys the layer-shell surface (and
    // its on-demand keyboard grab) on close.
    Loader {
        active: closeDelay.active

        sourceComponent: WlrLayershell {
            screen: Quickshell.screens[0]
            layer: WlrLayer.Overlay
            namespace: "desktop-widgets"
            color: "transparent"
            keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Leaves the bar's own row uncovered - without this, this surface (Overlay layer,
            // stacked above the bar's Top layer) swallows clicks on the bar's toggle icon
            // itself while open, since it extends over that strip too.
            margins.top: Config.barHeight

            FocusScope {
                id: focusScope

                anchors.fill: parent
                focus: true
                opacity: DesktopWidgetsState.open ? 1 : 0
                scale: DesktopWidgetsState.open ? 1 : 0.96

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

                Keys.onEscapePressed: DesktopWidgetsState.open = false

                Repeater {
                    model: ShellSettings.desktopWidgets

                    delegate: Rectangle {
                        id: box

                        required property var modelData

                        x: modelData.x
                        y: modelData.y
                        width: modelData.width
                        height: modelData.height
                        radius: Config.radiusMedium
                        clip: true
                        color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
                        border.width: Config.borderWidth
                        border.color: dragArea.drag.active || resizeArea.pressed ? Config.colBorderAccent : Config.colBorder

                        Loader {
                            id: widgetLoader

                            anchors.fill: parent
                            anchors.margins: Config.spacingSmall
                            sourceComponent: WidgetRegistry.components[box.modelData.type] ?? null

                            // See LockGrid.qml's identical Bindings - a Loader doesn't pass its
                            // own size on to the item it loads.
                            Binding {
                                target: widgetLoader.item
                                property: "width"
                                value: widgetLoader.width
                                when: widgetLoader.item !== null
                            }

                            Binding {
                                target: widgetLoader.item
                                property: "height"
                                value: widgetLoader.height
                                when: widgetLoader.item !== null
                            }
                        }

                        // Covers the whole box so a widget can be dragged from anywhere on
                        // it, at the cost of swallowing clicks meant for the widget's own
                        // interactive bits (e.g. notifications' "Clear all") while this layer
                        // is open - an acceptable trade for these being glanceable widgets.
                        MouseArea {
                            id: dragArea

                            anchors.fill: parent
                            anchors.margins: Config.desktopWidgetResizeHandleSize
                            drag.target: box
                            drag.axis: Drag.XAndYAxis
                            drag.minimumX: 0
                            drag.minimumY: 0
                            drag.maximumX: focusScope.width - box.width
                            drag.maximumY: focusScope.height - box.height
                            cursorShape: Qt.SizeAllCursor

                            onReleased: ShellSettings.updateDesktopWidgetRect(box.modelData.id, box.x, box.y, box.width, box.height)
                        }

                        Rectangle {
                            id: resizeHandle

                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: Config.desktopWidgetResizeHandleSize
                            height: Config.desktopWidgetResizeHandleSize
                            color: Config.colBorderAccent
                            opacity: 0.6

                            MouseArea {
                                id: resizeArea

                                property point lastGlobal

                                anchors.fill: parent
                                cursorShape: Qt.SizeFDiagCursor

                                onPressed: mouse => resizeArea.lastGlobal = resizeArea.mapToGlobal(mouse.x, mouse.y)
                                onPositionChanged: mouse => {
                                    if (!resizeArea.pressed)
                                        return;
                                    const g = resizeArea.mapToGlobal(mouse.x, mouse.y);
                                    box.width = Math.max(Config.desktopWidgetMinSize, box.width + (g.x - resizeArea.lastGlobal.x));
                                    box.height = Math.max(Config.desktopWidgetMinSize, box.height + (g.y - resizeArea.lastGlobal.y));
                                    resizeArea.lastGlobal = g;
                                }
                                onReleased: ShellSettings.updateDesktopWidgetRect(box.modelData.id, box.x, box.y, box.width, box.height)
                            }
                        }
                    }
                }
            }
        }
    }
}
