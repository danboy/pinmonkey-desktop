import Quickshell
import Quickshell.Wayland
import qs.modules.components

// Base for any layer-shell surface that toggles open/closed: stays mapped for the shell's
// whole lifetime (toggling `visible` here maps/unmaps the wl_surface, which races Qt's
// Wayland output-enter bookkeeping and segfaults in
// QWaylandWindow::calculateScreenFromSurfaceEvents - confirmed in crash dumps, this is the
// cause of quickshell's intermittent segfaults). Open/close is visual only (opacity/scale in
// the content below); click passthrough while closed is handled by `mask` instead of unmap.
WlrLayershell {
    id: root

    // Callers drive this, not `visible` (which stays permanently true).
    property bool open: false
    // Exposed so content can stay interactive through the close-fade (see CloseDelay).
    readonly property bool closing: closeDelay.active

    visible: true
    mask: closeDelay.active ? null : clickThroughMask

    CloseDelay {
        id: closeDelay

        open: root.open
    }

    Region {
        id: clickThroughMask
    }
}
