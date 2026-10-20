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

    // captureFrame() allocates a GPU dmabuf buffer (GBM device + bo) for the shot and frees
    // the one it's replacing, and that request can take anywhere from under a second to
    // several seconds to actually resolve (hasContent). Confirmed against Launcher.qml's
    // popup, which uses the same show/hide pattern but no ScreencopyView and survives rapid
    // toggling fine: the crash is specifically tied to this capture, not to the hosting
    // surface's own lifecycle (destroying/recreating it on every open and just hiding it
    // were both tried, and both still crashed under rapid toggling). Two guards, used
    // together because neither alone was enough: `lastCaptureTime` throttles how often a
    // new capture can even be requested, and `pending` tracks whether one is still in
    // flight so callers can avoid flipping the hosting surface's visibility while a capture
    // is outstanding (see DesktopWidgetLayer.qml's `visible` binding) - letting the surface
    // disappear and reappear mid-capture is what kept crashing it even with the request
    // itself throttled.
    property real lastCaptureTime: 0
    readonly property int minCaptureIntervalMs: 1000
    property bool pending: false

    function capture() {
        const now = Date.now();
        if (root.pending || now - root.lastCaptureTime < root.minCaptureIntervalMs)
            return;
        root.lastCaptureTime = now;
        root.pending = true;
        pendingTimeout.restart();
        Qt.callLater(backdropCapture.captureFrame);
    }

    // Fallback in case hasContent never arrives, so a lost frame can't wedge `pending`
    // (and so the surface it gates) forever.
    Timer {
        id: pendingTimeout

        interval: 5000
        onTriggered: root.pending = false
    }

    ScreencopyView {
        id: backdropCapture

        x: 0
        y: -root.topInset
        width: root.surface.screen.width
        height: root.surface.screen.height
        live: false
        captureSource: root.surface.screen
        onHasContentChanged: if (hasContent) {
            root.pending = false;
            pendingTimeout.stop();
        }
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
