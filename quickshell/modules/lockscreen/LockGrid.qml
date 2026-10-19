import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.services

// Full-screen lock dashboard, laid out from ShellSettings.lockGridRows (editable in
// Settings - see LockGridSettings.qml). Each row is a flat list of per-column widget
// types; consecutive columns sharing the same type merge into one spanning GridLayout cell
// here, so "span" is just "assign the same type next door" rather than a separate value
// the settings UI or the stored JSON has to keep in sync.
GridLayout {
    id: root

    columns: Config.lockGridColumns
    columnSpacing: Config.spacingLarge
    rowSpacing: Config.spacingLarge

    function flattenRow(row, rowIndex) {
        const cells = [];
        let col = 0;
        while (col < row.length) {
            const type = row[col];
            let span = 1;
            while (col + span < row.length && row[col + span] === type)
                span++;
            if (type && type !== "empty")
                cells.push({
                    row: rowIndex,
                    column: col,
                    span,
                    type
                });
            col += span;
        }
        return cells;
    }

    readonly property var cells: {
        let result = [];
        const rows = ShellSettings.lockGridRows;
        for (let i = 0; i < rows.length; i++)
            result = result.concat(root.flattenRow(rows[i], i));
        return result;
    }

    Repeater {
        model: root.cells

        delegate: DashboardBox {
            id: box

            required property var modelData

            Layout.row: modelData.row
            Layout.column: modelData.column
            Layout.columnSpan: modelData.span
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                id: widgetLoader

                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: WidgetRegistry.components[box.modelData.type] ?? null

                // A Loader placed inside a Layout gets its OWN size from that Layout, but
                // doesn't pass it on to the item it loads - without these, every widget
                // would collapse to its own implicit (usually tiny) content size instead of
                // filling the cell.
                Binding {
                    target: widgetLoader.item
                    property: "width"
                    value: widgetLoader.width
                    when: widgetLoader.item !== null
                }

                Binding {
                    target: widgetLoader.item
                    property: "height"
                    value: widgetLoader.height
                    when: widgetLoader.item !== null
                }
            }
        }
    }
}
