import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.components
import qs.modules.services

// Editor for ShellSettings.lockGridRows - the lock screen's 3-column widget grid. Each
// column slot cycles through the available widget types on click, mirroring the
// click-to-cycle convention DisplaySettings.qml uses for rotation/VRR. Giving two adjacent
// slots in a row the same type is how you make a widget span columns (see LockGrid.qml).
ColumnLayout {
    id: root

    spacing: Config.spacingSmall

    // "empty" first so cycling always has a quick way back to a blank slot.
    readonly property var typeOptions: ["empty", ...WidgetRegistry.types]

    function label(type) {
        return WidgetRegistry.label(type);
    }

    function cycle(rowIndex, columnIndex, current) {
        const next = root.typeOptions[(root.typeOptions.indexOf(current) + 1) % root.typeOptions.length];
        ShellSettings.setLockGridCell(rowIndex, columnIndex, next);
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Each row is 3 columns - click a slot to cycle its widget. Give two slots next " + "to each other the same widget to span columns."
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
    }

    Repeater {
        model: ShellSettings.lockGridRows

        delegate: RowLayout {
            id: rowDelegate

            required property var modelData
            required property int index

            Layout.fillWidth: true
            spacing: Config.spacingSmall

            Repeater {
                model: rowDelegate.modelData

                delegate: Rectangle {
                    id: slot

                    required property string modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: Config.notificationRowHeight
                    radius: Config.radiusSmall
                    color: Config.colSurfaceVariant
                    border.width: Config.borderWidth
                    border.color: Config.colBorder

                    Text {
                        anchors.centerIn: parent
                        text: root.label(slot.modelData)
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeCaption
                        color: slot.modelData === "empty" ? Config.colSubtext : Config.colText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cycle(rowDelegate.index, slot.index, slot.modelData)
                    }
                }
            }

            Text {
                text: "✕"
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeBody
                color: Config.colSubtext

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellSettings.removeLockGridRow(rowDelegate.index)
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Config.notificationRowHeight
        radius: Config.radiusSmall
        color: Config.colSurfaceVariant
        border.width: Config.borderWidth
        border.color: Config.colBorder

        Text {
            anchors.centerIn: parent
            text: "+ Add row"
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: Config.fontSizeCaption
            color: Config.colAccent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellSettings.addLockGridRow()
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
