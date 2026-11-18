pragma Singleton
import Quickshell

Singleton {
    property bool open: false

    // Last confirmed selection-capture rectangle (screen-local coords). SelectionCapture is
    // destroyed/recreated every time it opens (see ScreenshotPanel's Loader), so it has
    // nowhere else to remember this across opens - kept here instead so re-opening Selection
    // starts from the same region rather than forcing a fresh draw every time.
    property bool hasLastSelection: false
    property real lastSelX: 0
    property real lastSelY: 0
    property real lastSelW: 0
    property real lastSelH: 0
}
