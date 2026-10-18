import Quickshell
import QtQuick
import qs.modules.panel
import qs.modules.launcher
import qs.modules.osd
import qs.modules.lockscreen

ShellRoot {
        id: root
        Panel {}
        Launcher {}
        OsdWindow {}
        LockScreen {}
}
