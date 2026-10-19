import QtQuick
import QtQuick.Layouts
import qs

// Mirrors pinmonkey's dash "Box": a sharp-cornered, full-opacity-border cell in an
// equal-width row, unlike the rounded/low-opacity-border popup cards used elsewhere.
// Sized by whatever GridLayout parent places it (see LockGrid.qml) rather than a fixed
// size of its own - content taller than the cell (e.g. a long notification list) is
// clipped rather than growing the cell.
Rectangle {
    id: root

    default property alias content: inner.data

    clip: true
    color: "transparent"
    border.width: Config.borderWidth
    border.color: Config.colText

    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Config.spacingLarge
    }
}
