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

    // Created once and kept alive for the shell's lifetime - toggled via `visible` below,
    // never destroyed/recreated. This used to be instantiated fresh on every open (via a
    // Loader gated on CloseDelay, same pattern as Launcher.qml) and fully destroyed on
    // close; that meant BlurredBackdrop's capture allocated a fresh GPU dmabuf buffer on
    // every single open and freed it on every close. Repeating that create/destroy cycle
    // under rapid toggling (mashing the bar icon, spamming the IPC toggle) raced the GPU
    // buffer's teardown against the compositor and crashed quickshell outright, even with
    // DesktopWidgetsState's debounce slowing it down. Keeping the surface - and the buffer -
    // alive and just hiding it sidesteps the race instead of trying to outrun it.
    WlrLayershell {
        id: widgetSurface

        screen: Quickshell.screens[0]
        layer: WlrLayer.Overlay
        namespace: "desktop-widgets"
        color: "transparent"
        // None, not OnDemand: these widgets take no text input, and an OnDemand grab
        // eats the first click elsewhere (e.g. the bar's toggle icon) just to release
        // focus, forcing a second click to actually register - that was the two-click bug.
        keyboardFocus: WlrKeyboardFocus.None
        // Unmapping on `visible: false` (rather than destroying the surface) is also what
        // keeps this from swallowing clicks on the bar's own toggle icon while closed -
        // same requirement the old destroy-on-close approach satisfied.
        //
        // Also stays unmapped - even if the user asks to open - while BlurredBackdrop's
        // capture is still in flight (`!blur.pending`): flipping this surface's visibility
        // while a capture is outstanding was crashing quickshell outright under rapid
        // toggling, independent of how often a new capture was actually being requested.
        // Safe to read a child's property here (unlike gating a Loader's own `active` on
        // its item's property, which is circular): `blur` always exists as a permanent
        // child of this surface, so this binding doesn't control its own dependency's
        // existence. Self-resolving once the capture lands - see BlurredBackdrop.qml.
        visible: closeDelay.active && !blur.pending

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

        // Fresh one-shot screen capture each time this becomes visible again (i.e. a real
        // open from closed, not a bounce mid-close-animation - see CloseDelay), before this
        // surface has presented a frame at its new opacity. That ordering is what keeps it
        // from capturing itself: a live capture would re-blur its own previous frame every
        // tick, smearing into a feedback loop instead of a crisp backdrop. BlurredBackdrop
        // defers the actual capture a tick (Qt.callLater) - called synchronously here, the
        // view's recording context isn't realized yet and it silently fails.
        onVisibleChanged: if (visible)
            blur.capture()

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
            // the onVisibleChanged above) rather than a live feed, and why it needs
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
