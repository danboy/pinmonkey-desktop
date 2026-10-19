import QtQuick
import qs

// Keeps `active` true for `duration` ms after `open` flips false, so a Loader-gated
// layer-shell surface (or a PopupWindow toggled via its own `visible`) has time to run a
// fade/scale-out animation before the thing driving it actually destroys or unmaps the
// surface. Drive the animation itself off `open` directly - it flips the instant a close is
// requested - and use `active` only for the Loader/PopupWindow's own active/visible property.
// Item (not QtObject) purely because QtObject has no default property to hold the Timer below.
Item {
    id: root

    visible: false

    property bool open: false
    property int duration: Config.animationDurationMs
    property bool active: false

    onOpenChanged: {
        if (open) {
            closeTimer.stop();
            root.active = true;
        } else {
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer

        interval: root.duration
        onTriggered: root.active = false
    }
}
