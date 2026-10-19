import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.components
import qs.modules.services

// Management UI for the desktop widget layer - adding/removing widgets happens here;
// dragging and resizing them happens directly on the desktop layer itself (see
// DesktopWidgetLayer.qml), toggled via the grid icon at the top right of the bar.
ColumnLayout {
    id: root

    spacing: Config.spacingSmall

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Add a widget below, then toggle the desktop layer from the grid icon in the " + "top right of the bar to drag it into place and resize it."
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
    }

    Text {
        Layout.fillWidth: true
        visible: ShellSettings.desktopWidgets.length === 0
        text: "No desktop widgets yet"
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
    }

    Repeater {
        model: ShellSettings.desktopWidgets

        delegate: Rectangle {
            id: row

            required property var modelData

            Layout.fillWidth: true
            implicitHeight: Config.notificationRowHeight
            radius: Config.radiusSmall
            color: Config.colSurfaceVariant
            border.width: Config.borderWidth
            border.color: Config.colBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: Config.spacingSmall
                spacing: Config.spacingSmall

                Text {
                    Layout.fillWidth: true
                    text: WidgetRegistry.label(row.modelData.type)
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: Config.colText
                }

                Text {
                    text: "✕"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeBody
                    color: Config.colSubtext

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellSettings.removeDesktopWidget(row.modelData.id)
                    }
                }
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Config.spacingSmall

        Repeater {
            model: WidgetRegistry.types

            delegate: Rectangle {
                id: addButton

                required property string modelData

                implicitWidth: label.implicitWidth + Config.spacingLarge * 2
                implicitHeight: Config.notificationRowHeight
                radius: Config.radiusSmall
                color: Config.colSurfaceVariant
                border.width: Config.borderWidth
                border.color: Config.colBorder

                Text {
                    id: label

                    anchors.centerIn: parent
                    text: "+ " + WidgetRegistry.label(addButton.modelData)
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeCaption
                    color: Config.colAccent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellSettings.addDesktopWidget(addButton.modelData)
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
