import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.components
import qs.modules.services

// Pulls from pinmonkey's own /public/events (event_type forced to "holiday" server-side),
// authenticated with a personal API key read at runtime from this repo's local (gitignored)
// .env - see .env.example - same pattern TransitWidget uses for its CTA keys. Falls back to
// showing nothing configured if no key is present, rather than silently reverting to a
// different data source.
WidgetLayout {
    id: root

    title: "Holiday"

    readonly property string apiBase: "https://api.pinmonkey.com"
    property string apiKey: ""
    readonly property bool configured: apiKey.length > 0

    property var todayHoliday: null
    property var nextHoliday: null
    property int daysUntilNext: 0
    property bool todayLoaded: false
    property bool nextLoaded: false
    readonly property bool loaded: todayLoaded && nextLoaded

    function authHeaders() {
        return {
            "X-API-Key": root.apiKey,
            "Content-Type": "application/json"
        };
    }

    // "on" matches by month/day regardless of year, so this finds today's holiday(s) even
    // though the dataset's rows are all stamped with a single seed year - unlike a plain
    // upcoming=true query, which would miss today entirely (an all-day event's start_time is
    // midnight, already in the past the moment "today" is under way).
    function refreshToday() {
        if (!root.apiKey)
            return;
        const todayStr = Qt.formatDate(new Date(), "yyyy-MM-dd");
        Http.getJson(`${root.apiBase}/public/events?on=${todayStr}&limit=5`, data => {
            const rows = data?.events?.rows;
            root.todayHoliday = Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
            root.todayLoaded = true;
        }, "holiday-today", root.authHeaders());
    }

    // upcoming=true (start_time >= now) is fine here since we only use it to find the next
    // *future* day - today, if it has a holiday, is covered by refreshToday() above instead.
    function refreshNext() {
        if (!root.apiKey)
            return;
        Http.getJson(`${root.apiBase}/public/events?upcoming=true&limit=50`, data => {
            const rows = data?.events?.rows;
            if (!Array.isArray(rows) || rows.length === 0) {
                root.nextHoliday = null;
                root.nextLoaded = true;
                return;
            }
            const todayStr = Qt.formatDate(new Date(), "yyyy-MM-dd");
            const next = rows.find(r => r.start_time.slice(0, 10) !== todayStr);
            root.nextHoliday = next || null;
            if (root.nextHoliday) {
                const parts = root.nextHoliday.start_time.slice(0, 10).split("-").map(Number);
                const target = new Date(parts[0], parts[1] - 1, parts[2]);
                const now = new Date();
                root.daysUntilNext = Math.round((target - new Date(now.getFullYear(), now.getMonth(), now.getDate())) / 86400000);
            }
            root.nextLoaded = true;
        }, "holiday-next", root.authHeaders());
    }

    function refreshHolidays() {
        refreshToday();
        refreshNext();
    }

    FileView {
        id: envFile

        path: Quickshell.env("HOME") + "/Projects/pinmonkey-desktop/.env"

        onLoaded: {
            const match = text().match(/^PINMONKEY_API_KEY=(.*)$/m);
            root.apiKey = match ? match[1].trim() : "";
            root.refreshHolidays();
        }
    }

    // Refetches on every hour boundary rather than a fixed-interval Timer offset from
    // whenever this widget happened to load - the interval version could leave "Today"
    // showing yesterday's holiday for up to an hour after local midnight, since nothing
    // tied it to the actual rollover. Hours is SystemClock's coarsest precision (there's
    // no Days), but dateChanged still fires right on the midnight boundary with it, which
    // is the one that actually matters here.
    SystemClock {
        id: hourWatcher

        precision: SystemClock.Hours
        onDateChanged: if (root.configured)
            root.refreshHolidays()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        visible: root.configured

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: {
                if (root.todayHoliday)
                    return root.todayHoliday.name;
                if (root.nextHoliday)
                    return root.nextHoliday.name;
                return root.loaded ? "No upcoming holidays" : "Loading…";
            }
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: root.bodyFontSize
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
            font.pixelSize: root.captionFontSize
            color: Config.colSubtext
        }
    }

    Text {
        Layout.fillWidth: true
        visible: !root.configured
        text: "Holiday not configured"
        font.family: Config.fontFamily
        font.pixelSize: root.captionFontSize
        color: Config.colSubtext
    }

    // Soaks up leftover height when the box is resized taller than the content needs,
    // so content stays pinned to the top instead of ColumnLayout spreading it out.
    Item {
        Layout.fillHeight: true
    }
}
