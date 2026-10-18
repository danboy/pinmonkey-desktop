import QtQuick
import QtQuick.Layouts
import qs

// Mirrors pinmonkey's dash "Box": a sharp-cornered, full-opacity-border cell in an
// equal-width row, unlike the rounded/low-opacity-border popup cards used elsewhere.
// Fixed size (not content-sized) so the dashboard grid stays uniform - content taller than
// the box (e.g. a long notification list) is clipped rather than growing the cell.
Rectangle {
    id: root

    default property alias content: inner.data

    Layout.preferredWidth: Config.lockBoxWidth
    Layout.preferredHeight: Config.lockBoxHeight
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
