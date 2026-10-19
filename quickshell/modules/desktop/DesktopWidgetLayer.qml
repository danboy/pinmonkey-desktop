import QtQuick
import QtQuick.Effects
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
            id: widgetSurface

            screen: Quickshell.screens[0]
            layer: WlrLayer.Overlay
            namespace: "desktop-widgets"
            color: "transparent"
            // None, not OnDemand: these widgets take no text input, and an OnDemand grab
            // eats the first click elsewhere (e.g. the bar's toggle icon) just to release
            // focus, forcing a second click to actually register - that was the two-click bug.
            keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Panel.qml's Top-layer surface auto-reserves an exclusive zone of Config.barHeight
            // (anchored to one edge only, default exclusionMode), and niri insets this
            // all-edges-anchored Overlay surface by that exclusive zone on its own - no margin
            // needed here. An explicit margins.top: Config.barHeight on top of that double-
            // counted the bar height, leaving a bar-height band of raw, unblurred desktop
            // exposed between the real bar and where the blur actually started.

            // One-shot screen capture, taken fresh each time this surface is (re)created (see
            // the Loader above - it's destroyed on close, so this fires again on every open),
            // before this surface itself has presented a frame. That ordering is what keeps it
            // from capturing itself: a live capture would re-blur its own previous frame every
            // tick, smearing into a feedback loop instead of a crisp backdrop.
            // Deferred a tick (Qt.callLater) - called straight from onCompleted, the view's
            // recording context isn't realized yet and the capture silently fails.
            Component.onCompleted: Qt.callLater(backdropCapture.captureFrame)

            Item {
                id: focusScope

                anchors.fill: parent
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

                // Real blur of the actual desktop/windows behind this overlay, done client-side
                // since niri's own background-effect blur (ext-background-effect-v1) only
                // samples its wallpaper/backdrop layer, not windows stacked below it - see the
                // Component.onCompleted above for why this is a still frame, not a live feed.
                // ScreencopyView has no source-rect/position awareness of its own (see
                // qs::wayland::screencopy::ScreencopyView::paint) - it always stretches the
                // *entire* captured frame to fill its own item bounds. Since this surface is
                // inset from the real screen by margins.top (Config.barHeight), anchors.fill
                // would squeeze the whole screen - panel strip included - into the shorter
                // item, shifting everything down and letterboxing the sides. Instead size this
                // to the real screen 1:1 and shift it up by the same margin the surface was
                // inset by, so the captured frame lines back up pixel-for-pixel; the portion
                // above y:0 (the panel strip) simply falls outside the surface and is clipped.
                ScreencopyView {
                    id: backdropCapture

                    x: 0
                    y: -Config.barHeight
                    width: widgetSurface.screen.width
                    height: widgetSurface.screen.height
                    live: false
                    captureSource: widgetSurface.screen
                }

                MultiEffect {
                    anchors.fill: backdropCapture
                    source: backdropCapture
                    blurEnabled: true
                    blur: 1
                    blurMax: 64
                    autoPaddingEnabled: false
                }

                // Light scrim on top of the blur for text legibility.
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, Config.desktopWidgetScrimOpacity)
                }

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
