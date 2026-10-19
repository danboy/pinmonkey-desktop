import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

// Real blur of the actual desktop/windows behind an overlay surface, done client-side
// since niri's own background-effect blur (ext-background-effect-v1) only samples its
// wallpaper/backdrop layer, not windows stacked below it. A one-shot still frame, not a
// live feed - captured once via capture() and never again until the next call, so it
// can't feed back into itself by re-blurring its own previous frame every tick.
//
// Needs the hosting WlrLayershell surface and how far that surface is inset from the top
// of the real screen (e.g. Config.barHeight), so the capture - which always covers the
// full screen - can be shifted to line back up with it 1:1. See DesktopWidgetLayer.qml's
// original comment for the full reasoning on ScreencopyView's stretch-to-bounds behavior.
Item {
    id: root

    required property WlrLayershell surface
    property real topInset: 0
    property real blurAmount: 1
    property real blurMaxAmount: 64

    function capture() {
        Qt.callLater(backdropCapture.captureFrame);
    }

    ScreencopyView {
        id: backdropCapture

        x: 0
        y: -root.topInset
        width: root.surface.screen.width
        height: root.surface.screen.height
        live: false
        captureSource: root.surface.screen
    }

    MultiEffect {
        anchors.fill: backdropCapture
        source: backdropCapture
        blurEnabled: true
        blur: root.blurAmount
        blurMax: root.blurMaxAmount
        autoPaddingEnabled: false
    }
}
