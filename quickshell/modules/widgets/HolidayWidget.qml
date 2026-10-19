import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.services

ColumnLayout {
    id: root

    property var holidays: []
    property var todayHoliday: null
    property var nextHoliday: null
    property int daysUntilNext: 0

    function refreshHolidays() {
        const year = new Date().getFullYear();
        Http.getJson(`https://date.nager.at/api/v3/publicholidays/${year}/US`, data => {
            root.holidays = Array.isArray(data) ? data : [];
            root.computeHoliday();
        }, "holiday");
    }

    function computeHoliday() {
        const now = new Date();
        const todayStr = Qt.formatDate(now, "yyyy-MM-dd");
        root.todayHoliday = root.holidays.find(h => h.date === todayStr) || null;
        if (root.todayHoliday) {
            root.nextHoliday = null;
            return;
        }
        const future = root.holidays.filter(h => h.date > todayStr).sort((a, b) => a.date < b.date ? -1 : 1);
        root.nextHoliday = future[0] || null;
        if (root.nextHoliday) {
            const parts = root.nextHoliday.date.split("-").map(Number);
            const target = new Date(parts[0], parts[1] - 1, parts[2]);
            root.daysUntilNext = Math.round((target - new Date(now.getFullYear(), now.getMonth(), now.getDate())) / 86400000);
        }
    }

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Config.spacingSmall

    Component.onCompleted: refreshHolidays()

    Timer {
        interval: 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.computeHoliday()
    }

    Text {
        text: "Holiday"
        font.family: Config.fontFamily
        font.bold: true
        font.pixelSize: Config.fontSizeBody
        color: Config.colText
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: {
                if (root.todayHoliday)
                    return root.todayHoliday.localName;
                if (root.nextHoliday)
                    return root.nextHoliday.localName;
                return root.holidays.length > 0 ? "No upcoming holidays" : "Loading…";
            }
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: Config.fontSizeBody
            color: Config.colText
        }

        Text {
            Layout.fillWidth: true
            text: {
                if (root.todayHoliday)
                    return "Today";
                if (root.nextHoliday)
                    return "In " + root.daysUntilNext + (root.daysUntilNext === 1 ? " day" : " days");
                return "";
            }
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeCaption
            color: Config.colSubtext
        }
    }
}
