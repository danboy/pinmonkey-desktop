pragma Singleton
import Quickshell

// Shared so other components (e.g. the lock screen) can close the launcher synchronously,
// in-process, instead of racing an async IPC round-trip against something time-sensitive.
Singleton {
    id: root

    property bool open: false
}
