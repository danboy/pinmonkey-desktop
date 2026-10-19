pragma Singleton
import QtQuick
import Quickshell
import qs.modules.infopanel

// Single source of truth for "what widget types exist" - shared by the lock screen grid,
// the desktop widget layer, and both of their settings editors, so adding a new widget
// type is one entry here instead of four places kept in sync by hand.
Singleton {
    id: root

    readonly property var types: ["weather", "news", "holiday", "transit", "calendar", "notifications"]

    readonly property var components: ({
            weather: weatherComponent,
            news: newsComponent,
            holiday: holidayComponent,
            transit: transitComponent,
            calendar: calendarComponent,
            notifications: notificationsComponent
        })

    function label(type) {
        return type.charAt(0).toUpperCase() + type.slice(1);
    }

    Component {
        id: weatherComponent

        WeatherWidget {}
    }

    Component {
        id: newsComponent

        NewsWidget {}
    }

    Component {
        id: holidayComponent

        HolidayWidget {}
    }

    Component {
        id: transitComponent

        TransitWidget {}
    }

    Component {
        id: calendarComponent

        CalendarWidget {}
    }

    Component {
        id: notificationsComponent

        NotificationsWidget {}
    }
}
