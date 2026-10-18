import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.modules.services

Variants {
    model: Quickshell.screens

    delegate: WlrLayershell {
        required property ShellScreen modelData

        layer: WlrLayer.Overlay
        screen: modelData
        color: "transparent"
        visible: NotificationToast.visible && NotificationToast.notification !== null
        exclusiveZone: 0

        implicitWidth: Config.popupWidth
        implicitHeight: content.implicitHeight + Config.popupMargin * 2

        anchors {
            top: true
            right: true
        }

        margins {
            top: Config.barHeight + Config.spacingMedium
            right: Config.spacingMedium
        }

        Rectangle {
            anchors.fill: parent
            radius: Config.radiusLarge
            color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
            border.width: Config.borderWidth
            border.color: Config.colBorderAccent

            MouseArea {
                anchors.fill: parent
                onClicked: NotificationToast.hide()
            }

            RowLayout {
                id: content

                anchors.fill: parent
                anchors.margins: Config.popupMargin
                spacing: Config.spacingSmall

                IconImage {
                    source: Quickshell.iconPath(NotificationToast.notification?.appIcon ?? "", "dialog-information-symbolic")
                    implicitSize: Config.iconSizeMedium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: NotificationToast.notification?.summary ?? ""
                        elide: Text.ElideRight
                        font.family: Config.fontFamily
                        font.bold: true
                        font.pixelSize: Config.fontSizeCaption
                        color: Config.colText
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: (NotificationToast.notification?.body ?? "").length > 0
                        text: NotificationToast.notification?.body ?? ""
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeCaption
                        color: Config.colSubtext
                    }
                }

                IconImage {
                    source: Quickshell.iconPath("window-close-symbolic", "window-close")
                    implicitSize: Config.iconSizeSmall

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationToast.hide()
                    }
                }
            }
        }
    }
}
