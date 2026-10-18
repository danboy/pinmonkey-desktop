pragma Singleton
import Quickshell
import QtQuick

// Shared IP geolocation lookup so Weather/Transit/etc don't each hit the
// geolocation API independently.
Singleton {
    id: root

    readonly property bool loaded: latitude !== 0 || longitude !== 0
    property real latitude: 0
    property real longitude: 0
    property string cityName: "Locating…"

    function locate() {
        Http.getJson("http://ip-api.com/json/", data => {
            if (data.status === "success") {
                root.latitude = data.lat;
                root.longitude = data.lon;
                root.cityName = data.city || "Unknown";
            } else {
                root.cityName = "Unavailable";
            }
        }, "location");
    }

    Component.onCompleted: locate()
}
