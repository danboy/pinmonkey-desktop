import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs
import qs.modules.infopanel
import qs.modules.services

Item {
    id: root

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

                onPamMessage: if (pam.responseRequired)
                    pam.respond(passwordField.text)

                onCompleted: result => {
                    passwordField.text = "";
                    surface.unlocking = false;
                    if (result === PamResult.Success) {
                        errorLabel.text = "";
                        sessionLock.locked = false;
                    } else {
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
                anchors.centerIn: parent
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

                ColumnLayout {
                    id: dashboard

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Config.lockDashboardWidth
                    spacing: Config.spacingLarge

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Config.spacingLarge

                        DashboardBox {
                            WeatherWidget {}
                        }

                        DashboardBox {
                            NewsWidget {}
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Config.spacingLarge

                        DashboardBox {
                            HolidayWidget {}
                        }

                        DashboardBox {
                            TransitWidget {}
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Config.spacingLarge

                        DashboardBox {
                            CalendarWidget {}
                        }

                        DashboardBox {
                            NotificationsWidget {}
                        }
                    }
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
            PopupCoordinator.closeAll();
            sessionLock.locked = true;
        }

        function unlock(): void {
            sessionLock.locked = false;
        }
    }
}
