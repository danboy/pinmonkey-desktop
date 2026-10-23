import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.modules.components

Variants {
    model: Quickshell.screens

    delegate: MaskedLayershell {
        required property ShellScreen modelData

        layer: WlrLayer.Overlay
        screen: modelData
        color: "transparent"
        open: Osd.visible
        exclusiveZone: 0

        implicitWidth: Config.osdWidth
        implicitHeight: content.implicitHeight + Config.popupMargin * 2

        anchors.bottom: true
        margins.bottom: Config.osdBottomMargin

        Rectangle {
            anchors.fill: parent
            radius: Config.radiusLarge
            color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
            border.width: Config.borderWidth
            border.color: Config.colDivider
            opacity: Osd.visible ? 1 : 0
            scale: Osd.visible ? 1 : 0.96

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.animationDurationMs
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Config.animationDurationMs
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                id: content

                anchors.fill: parent
                anchors.margins: Config.popupMargin
                spacing: Config.spacingLarge

                IconImage {
                    source: Quickshell.iconPath(Osd.iconName, Osd.iconFallback)
                    implicitSize: Config.iconSizeMedium
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Config.sliderTrackHeight
                    radius: Config.sliderTrackRadius
                    color: Config.colSurfaceHighlight

                    Rectangle {
                        width: parent.width * Osd.value
                        height: parent.height
                        radius: Config.sliderTrackRadius
                        color: Config.colAccent
                    }
                }

                Text {
                    text: Math.round(Osd.value * 100) + "%"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: Config.colSubtext
                    Layout.preferredWidth: Config.percentTextWidth
                }
            }
        }
    }
}
