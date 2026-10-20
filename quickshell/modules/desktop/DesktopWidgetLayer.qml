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
            DesktopWidgetsState.toggle();
        }

        function show(): void {
            DesktopWidgetsState.show();
        }

        function hide(): void {
            DesktopWidgetsState.hide();
        }
    }

    CloseDelay {
        id: closeDelay

        open: DesktopWidgetsState.open
    }

    // Mapped once, for the shell's lifetime, and never unmapped again. This used to be
    // unmapped (`visible: false`) whenever closed, on the theory that only an unmapped
    // surface reliably stops swallowing clicks meant for e.g. the bar's own toggle icon.
    // That toggling is the working theory for quickshell's intermittent segfault on
    // open/close: mapping/unmapping a layer-shell surface makes it enter/leave the
    // compositor's output tracking each time, and the crash is always a null
    // QPlatformScreen inside QWaylandWindow::calculateScreenFromSurfaceEvents, which only
    // runs off that enter/leave bookkeeping. Never unmapping it at all sidesteps the churn
    // entirely. Click passthrough while closed is now handled by `mask` below instead of
    // by unmapping.
    WlrLayershell {
        id: widgetSurface

        screen: Quickshell.screens[0]
        layer: WlrLayer.Overlay
        namespace: "desktop-widgets"
        color: "transparent"
        visible: true
        // OnDemand grants real keyboard focus to whatever's clicked inside (e.g.
        // NotepadWidget's TextArea) while the surface has no input mask. Known caveat:
        // clicking the bar's toggle icon to close while something here holds focus can
        // eat that first click releasing focus instead of registering on the icon,
        // needing a second click (upstream niri/wlroots OnDemand-release behavior, same
        // class of issue as omarchy#6858) - acceptable trade for notepad actually being
        // typeable.
        keyboardFocus: WlrKeyboardFocus.OnDemand
        // No mask (full surface accepts input) while a close is still animating
        // (closeDelay.active), so widgets stay interactive through the fade-out. Once
        // that settles, mask to a zero-area Region - an empty input region - so the
        // surface, though still mapped, stops intercepting clicks anywhere (same net
        // effect the old unmap used to get, without ever touching map state).
        mask: closeDelay.active ? null : clickThroughMask

        Region {
            id: clickThroughMask
        }

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

        // Fresh one-shot screen capture on every real open (not a bounce mid-close - see
        // CloseDelay), driven off DesktopWidgetsState directly now that this surface's own
        // `visible` never changes. BlurredBackdrop defers the actual capture a tick
        // (Qt.callLater) - called synchronously here, the view's recording context isn't
        // realized yet and it silently fails.
        Connections {
            target: DesktopWidgetsState

            function onOpenChanged(): void {
                if (DesktopWidgetsState.open)
                    blur.capture();
            }
        }

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

            // See BlurredBackdrop.qml for why this is a one-shot still frame (captured by
            // the Connections above) rather than a live feed, and why it needs
            // topInset: this surface is inset from the real screen by the bar's exclusive
            // zone, and ScreencopyView always stretches its full-screen capture to fill its
            // own item bounds, so without correcting for that inset the capture would
            // squeeze the whole screen - panel strip included - into the shorter item.
            BlurredBackdrop {
                id: blur

                anchors.fill: parent
                surface: widgetSurface
                topInset: Config.barHeight
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

                    // Tracks hover independent of the drag/resize MouseAreas below (which
                    // only cover part of the box) so the resize handle can stay hidden until
                    // the pointer is actually over the widget.
                    HoverHandler {
                        id: boxHover
                    }

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

                        // Only NotepadWidget has a noteKey property - gated on type too,
                        // or this would warn on every other widget about assigning a
                        // non-existent property.
                        Binding {
                            target: widgetLoader.item
                            property: "noteKey"
                            value: box.modelData.id
                            when: widgetLoader.item !== null && box.modelData.type === "notepad"
                        }
                    }

                    // Covers the whole box so a widget can be dragged from anywhere on it,
                    // at the cost of swallowing clicks meant for the widget's own interactive
                    // bits (e.g. notifications' "Clear all") - an acceptable trade for those
                    // being glanceable widgets. Notepad only gets a header-sized drag strip
                    // so the rest of the box is free for clicks to reach its TextArea (it can
                    // actually take keyboard focus now - see keyboardFocus above).
                    MouseArea {
                        id: dragArea

                        readonly property bool headerOnly: box.modelData.type === "notepad"

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: Config.desktopWidgetResizeHandleSize
                        anchors.rightMargin: Config.desktopWidgetResizeHandleSize
                        anchors.topMargin: Config.desktopWidgetResizeHandleSize
                        height: headerOnly ? Config.desktopWidgetDragHandleHeight : (box.height - Config.desktopWidgetResizeHandleSize * 2)
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
                        // Hidden until hovered, but stays up through an active resize even
                        // if the pointer slips off it mid-drag.
                        visible: boxHover.hovered || resizeArea.pressed

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
