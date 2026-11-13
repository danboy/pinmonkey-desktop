pragma Singleton
import Quickshell
import QtQuick
import qs

// Single reusable OSD controller fed by VolumeControl/BrightnessControl
// whenever their value changes, whether from the GUI slider or an external
// source like a keyboard key. Suppressed while the control center popup is
// open since its own sliders already give feedback.
Singleton {
    id: root

    property bool visible: false
    property bool suppressed: false
    property string iconName: ""
    property string iconFallback: ""
    property real value: 0
    property bool muted: false

    function show(icon, val, fallback, muted) {
        if (root.suppressed)
            return;
        root.iconName = icon;
        root.iconFallback = fallback ?? icon;
        root.value = val;
        root.muted = muted ?? false;
        root.visible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer

        interval: Config.osdVisibleMs
        onTriggered: root.visible = false
    }
}
