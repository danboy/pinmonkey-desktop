import Quickshell
import QtQuick
import qs.modules.panel
import qs.modules.launcher
import qs.modules.osd
import qs.modules.lockscreen
import qs.modules.settings
import qs.modules.screenshot

ShellRoot {
        id: root
        Panel {}
        Launcher {}
        OsdWindow {}
        LockScreen {}
        SettingsPanel {}
        ScreenshotPanel {}
}
