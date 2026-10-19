import QtQuick
import QtQuick.Layouts
import qs

// A single-pixel horizontal divider line, sized/colored to the shared theme tokens - used
// anywhere a RowLayout/ColumnLayout needs to split sections apart.
Rectangle {
    Layout.fillWidth: true
    implicitHeight: Config.borderWidth
    color: Config.colDivider
}
