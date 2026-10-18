import QtQuick // for Text
import QtQuick.Layouts
import Quickshell // for PanelWindow
import Quickshell.Wayland
import qs
import qs.modules.controlcenter
import qs.modules.infopanel

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
                id: rightLayout

                spacing: Config.appletSpacing
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Config.appletSpacing

                SystemTray {}

                ControlCenter {
                    Layout.rightMargin: Config.appletSpacing / 2
                }

            }

        }

    }

}
