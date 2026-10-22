import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.components

WidgetLayout {
    id: root

    title: "Calendar"

    // Not a plain `new Date()` - this widget is created once and lives for the whole shell
    // session (InfoPanel instantiates it directly, no per-open Loader), so a one-shot
    // `new Date()` freezes "today" at whichever day the shell happened to start, same bug
    // class HolidayWidget had before switching to SystemClock. viewDate's initial value
    // comes from this too, but prevMonth()/nextMonth() reassign it directly, which breaks
    // the binding - intentional, so navigating away from the current month doesn't keep
    // snapping back.
    SystemClock {
        id: clock

        precision: SystemClock.Hours
    }

    property date viewDate: clock.date
    readonly property int year: viewDate.getFullYear()
    readonly property int month: viewDate.getMonth()
    readonly property date today: clock.date

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate();
    }

    function firstWeekday(y, m) {
        return new Date(y, m, 1).getDay();
    }

    readonly property var cells: {
        const list = [];
        const leading = firstWeekday(year, month);
        for (let i = 0; i < leading; i++)
            list.push(null);
        const total = daysInMonth(year, month);
        for (let d = 1; d <= total; d++)
            list.push(d);
        return list;
    }

    function isToday(d) {
        return d === today.getDate() && month === today.getMonth() && year === today.getFullYear();
    }

    function prevMonth() {
        viewDate = new Date(year, month - 1, 1);
    }

    function nextMonth() {
        viewDate = new Date(year, month + 1, 1);
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.preferredWidth: Config.iconButtonSize
            horizontalAlignment: Text.AlignHCenter
            text: "‹"
            font.family: Config.fontFamily
            font.pixelSize: root.bodyFontSize
            color: Config.colText

            MouseArea {
                anchors.fill: parent
                onClicked: root.prevMonth()
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(root.viewDate, "MMMM yyyy")
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: root.bodyFontSize
            color: Config.colText
        }

        Text {
            Layout.preferredWidth: Config.iconButtonSize
            horizontalAlignment: Text.AlignHCenter
            text: "›"
            font.family: Config.fontFamily
            font.pixelSize: root.bodyFontSize
            color: Config.colText

            MouseArea {
                anchors.fill: parent
                onClicked: root.nextMonth()
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: Config.spacingXSmall
        columnSpacing: Config.spacingXSmall

        Repeater {
            model: ["S", "M", "T", "W", "T", "F", "S"]

            delegate: Text {
                required property string modelData

                Layout.preferredWidth: Config.calendarCellSize
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.family: Config.fontFamily
                font.pixelSize: root.captionFontSize
                color: Config.colSubtext
            }
        }

        Repeater {
            model: root.cells

            delegate: Item {
                required property var modelData

                Layout.preferredWidth: Config.calendarCellSize
                Layout.preferredHeight: Config.calendarCellSize

                Rectangle {
                    anchors.centerIn: parent
                    width: Config.calendarCellSize - 4
                    height: width
                    radius: Config.radiusPill
                    visible: modelData !== null
                    color: modelData !== null && root.isToday(modelData) ? Config.colAccent : "transparent"
                    border.width: modelData !== null && root.isToday(modelData) ? Config.borderWidth : 0
                    border.color: Config.colBorderAccent

                    Text {
                        anchors.centerIn: parent
                        text: modelData ?? ""
                        font.family: Config.fontFamily
                        font.pixelSize: root.captionFontSize
                        color: modelData !== null && root.isToday(modelData) ? Config.colAccentText : Config.colText
                    }
                }
            }
        }
    }

    // Soaks up leftover height when the box is resized taller than the content needs,
    // so content stays pinned to the top instead of ColumnLayout spreading it out.
    Item {
        Layout.fillHeight: true
    }
}
