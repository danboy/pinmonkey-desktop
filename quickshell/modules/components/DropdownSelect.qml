import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

// Closed-by-default select for option lists that can grow long (display resolutions,
// audio devices, etc.) - a PillSelector-style flow of pills only reads well up to a
// handful of choices; past that it wraps into an unreadable wall.
ComboBox {
    id: root

    // Each option is {label, value}, same shape as PillSelector.
    property var options: []
    property var selectedValue

    readonly property int currentOptionIndex: {
        for (let i = 0; i < root.options.length; i++)
            if (root.options[i].value === root.selectedValue)
                return i;
        return -1;
    }

    signal selected(var value)

    Layout.fillWidth: true
    model: root.options
    currentIndex: root.currentOptionIndex

    onActivated: index => root.selected(root.options[index].value)

    background: Rectangle {
        implicitHeight: label.implicitHeight + Config.spacingLarge * 2
        radius: Config.radiusMedium
        color: Config.colSurfaceVariant
        border.width: Config.borderWidth
        border.color: root.popup.visible ? Config.colBorderAccent : Config.colBorder
    }

    contentItem: Text {
        id: label

        leftPadding: Config.spacingLarge
        rightPadding: indicator.width + Config.spacingSmall
        text: root.currentOptionIndex >= 0 ? root.options[root.currentOptionIndex].label : ""
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeBody
        color: Config.colText
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: root.width - width - Config.spacingLarge
        y: root.topPadding + (root.availableHeight - height) / 2
        text: "⌄"
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeBody
        color: Config.colSubtext
    }

    delegate: Rectangle {
        id: row

        required property var modelData
        required property int index

        width: root.width
        implicitHeight: rowLabel.implicitHeight + Config.spacingMedium * 2
        color: index === root.highlightedIndex ? Config.colSurfaceHighlight : "transparent"

        Text {
            id: rowLabel

            anchors.fill: parent
            anchors.leftMargin: Config.spacingLarge
            anchors.rightMargin: Config.spacingLarge
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: row.modelData.label
            font.family: Config.fontFamily
            font.bold: index === root.currentOptionIndex
            font.pixelSize: Config.fontSizeBody
            color: Config.colText
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.highlightedIndex = row.index;
                root.popup.close();
                root.selected(row.modelData.value);
            }
        }
    }

    popup: Popup {
        id: popup

        y: root.height + Config.spacingXSmall
        width: root.width
        implicitHeight: Math.min(listView.contentHeight, Config.settingsRowHeight * 5)
        padding: Config.spacingXSmall

        background: Rectangle {
            color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
            radius: Config.radiusMedium
            border.width: Config.borderWidth
            border.color: Config.colDivider
        }

        contentItem: ListView {
            id: listView

            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}
