import QtQuick // for Text
import QtQuick.Layouts
import Quickshell // for PanelWindow
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.modules.components
import qs.modules.controlcenter
import qs.modules.infopanel
import qs.modules.services

Variants {
    model: Quickshell.screens

    delegate: WlrLayershell {
        required property ShellScreen modelData

        layer: WlrLayer.Top
        screen: modelData
        implicitHeight: Config.barHeight
        color: 'transparent'

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: 0
            left: 0
            right: 0
        }

        Rectangle {
            id: barContainer

            anchors.fill: parent
            color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
            radius: Config.appletRadHeight / 2
            border.width: Config.borderWidth
            border.color: Config.colDivider

            InfoPanel {
                anchors.centerIn: parent
            }

            RowLayout {
                id: leftLayout

                spacing: Config.appletSpacing
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 2

                Rectangle {
                    id: widgetToggle

                    implicitWidth: Config.pillHeight
                    implicitHeight: Config.pillHeight
                    radius: Config.radiusPill
                    color: DesktopWidgetsState.open ? Config.colAccent : Config.colSurfaceVariant
                    border.width: Config.borderWidth
                    border.color: DesktopWidgetsState.open ? Config.colBorderAccent : Config.colBorder

                    IconImage {
                        anchors.centerIn: parent
                        source: Quickshell.iconPath("view-grid-symbolic", "view-grid")
                        implicitSize: Config.iconSizeMedium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DesktopWidgetsState.toggle()
                    }

                }

                Rectangle {
                    id: titlePill

                    Layout.preferredHeight: Config.pillHeight
                    implicitWidth: titleText.width + Config.pillPaddingHorizontal
                    radius: Config.radiusPill
                    color: Config.colSurfaceVariant
                    border.width: Config.borderWidth
                    border.color: Config.colBorder
                    visible: ActiveWindow.title.length > 0

                    Text {
                        id: titleText

                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, Config.panelWindowTitleMaxWidth - Config.pillPaddingHorizontal)
                        elide: Text.ElideRight
                        text: ActiveWindow.title
                        font.family: Config.fontFamily
                        font.bold: true
                        font.pixelSize: Config.fontSizeCaption
                        color: Config.colText
                    }

                }

            }

            RowLayout {
                id: rightLayout

                spacing: Config.appletSpacing
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 2

                RecordingIndicator {
                }

                SystemTray {
                }

                ControlCenter {
                    Layout.rightMargin: Config.appletSpacing / 2
                }

            }

        }

    }

}
