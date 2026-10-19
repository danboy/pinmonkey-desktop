import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs
import qs.modules.services

Item {
    id: root

    // Shared by the "lock" IPC target and the idle-timeout auto-lock below, so both close
    // other popups first (see the comment on the IpcHandler's lock() for why that matters).
    function lockSession() {
        PopupCoordinator.closeAll();
        sessionLock.locked = true;
    }

    // Loader-wrapped rather than a plain IdleMonitor: changing `timeout` on a live
    // IdleMonitor updates the QML property but doesn't appear to actually recreate the
    // underlying ext-idle-notify-v1 object, so the real timeout stays stuck at whatever it
    // was when first created - confirmed by testing (a literal 5s timeout fired correctly;
    // the ShellSettings-derived one, which starts at the 10-minute default before the
    // settings file finishes loading async and only then updates to the real value, never
    // fired even after a genuine multi-minute idle wait). Gating on ShellSettings.loaded
    // avoids ever creating it with the wrong initial value, and force-reloading on every
    // idleLockMinutes change handles the user editing it live from Settings.
    Loader {
        id: idleLoader

        active: ShellSettings.loaded

        sourceComponent: IdleMonitor {
            enabled: ShellSettings.idleLockEnabled && !ShellSettings.stayAwakeEnabled
            timeout: ShellSettings.idleLockMinutes * 60
            onIsIdleChanged: if (isIdle && !sessionLock.locked)
                root.lockSession()
        }

        // Forces a fresh IdleMonitor on every change, not just idleLockMinutes - see the
        // comment above the Loader: a live property change on an existing IdleMonitor doesn't
        // reliably reach the underlying ext-idle-notify-v1 object, confirmed for `timeout`
        // and not worth re-testing per-property here given how it fails silently.
        Connections {
            target: ShellSettings
            function onIdleLockMinutesChanged() {
                idleLoader.active = false;
                idleLoader.active = true;
            }
            function onStayAwakeEnabledChanged() {
                idleLoader.active = false;
                idleLoader.active = true;
            }
        }
    }

    WlSessionLock {
        id: sessionLock

        locked: false

        WlSessionLockSurface {
            id: surface

            property bool unlocking: false

            function tryUnlock() {
                if (passwordField.text.length === 0 || surface.unlocking)
                    return;
                errorLabel.text = "";
                surface.unlocking = true;
                pam.start();
            }

            PamContext {
                id: pam

                config: "quickshell"

                onPamMessage: {
                    // Surface PAM's own message (e.g. a faillock lockout notice) instead of
                    // only ever showing a generic failure - this is the actual reason, not
                    // just "wrong password".
                    if (pam.message.length > 0)
                        errorLabel.text = pam.message;
                    if (pam.responseRequired)
                        pam.respond(passwordField.text);
                }

                onCompleted: result => {
                    passwordField.text = "";
                    surface.unlocking = false;
                    if (result === PamResult.Success) {
                        errorLabel.text = "";
                        sessionLock.locked = false;
                    } else {
                        // Keep whatever specific message PAM already relayed (e.g. a
                        // lockout notice); only fall back to the generic text if none came.
                        if (errorLabel.text.length === 0)
                            errorLabel.text = "Authentication failed";
                        passwordField.forceActiveFocus();
                    }
                }
            }

            SystemClock {
                id: clock

                precision: SystemClock.Seconds
            }

            Rectangle {
                anchors.fill: parent
                color: Config.colBackground
            }

            // forceActiveFocus() sets Qt-internal focus flags but never calls
            // QWindow::requestActivate(), so a lock surface created before the compositor
            // hands it real window activation can lose that race permanently (a known,
            // still-open upstream issue: https://github.com/omacom/omarchy/issues/6858,
            // reproduced on this exact Quickshell version). Keep retrying whenever focus
            // isn't where it should be - covers the cold-lock race, failed-password
            // re-enable, and suspend/resume all with one reactive binding.
            Timer {
                interval: 100
                repeat: true
                running: !passwordField.activeFocus
                onTriggered: passwordField.forceActiveFocus()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Config.lockGridMargin
                spacing: Config.spacingXLarge

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Config.spacingXSmall

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "h:mm")
                        font.family: Config.fontFamily
                        font.bold: true
                        font.pixelSize: Config.lockClockFontSize
                        color: Config.colText
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                        font.family: Config.fontFamily
                        font.pixelSize: Config.lockDateFontSize
                        color: Config.colSubtext
                    }
                }

                LockGrid {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Config.spacingSmall

                    TextField {
                        id: passwordField

                        focus: true
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: Config.lockPasswordFieldWidth
                        implicitHeight: Config.pillHeight
                        horizontalAlignment: TextInput.AlignHCenter
                        echoMode: TextInput.Password
                        enabled: !surface.unlocking
                        placeholderText: "Password"
                        placeholderTextColor: Config.colSubtext
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeBody
                        color: Config.colText
                        selectionColor: Config.colAccent

                        background: Rectangle {
                            radius: Config.radiusPill
                            color: Config.colSurfaceVariant
                            border.width: Config.borderWidth
                            border.color: passwordField.activeFocus ? Config.colBorderAccent : Config.colBorder
                        }

                        onAccepted: surface.tryUnlock()
                    }

                    Text {
                        id: errorLabel

                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Config.lockPasswordFieldWidth
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeCaption
                        color: Config.colDanger
                    }
                }
            }

        }
    }

    IpcHandler {
        target: "lock"

        // The launcher and AnchoredPopup-based popups (control center, info panel) are real
        // windows with grabFocus/on-demand keyboard focus that stay mapped while open. If any
        // are still open when the session locks, niri doesn't seem to forcibly strip their
        // focus in favor of the new lock surface - the lock screen renders but silently gets
        // no input until that other surface is closed. Close them all synchronously,
        // in-process, before locking so this can't happen - an execDetached IPC round-trip
        // here would be async and could lose the race against the very next line.
        function lock(): void {
            root.lockSession();
        }

        function unlock(): void {
            sessionLock.locked = false;
        }
    }
}
