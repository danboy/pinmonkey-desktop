import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.components
import qs.modules.services

// CTA (Chicago Transit Authority) nearby train/bus arrivals. Nearby stops come from
// the keyless Chicago Data Portal; arrivals need a free Train/Bus Tracker API key,
// read at runtime from this repo's local (gitignored) .env - see .env.example - so no
// key is ever hardcoded or committed.
WidgetLayout {
    id: root

    title: "CTA"

    property string trainKey: ""
    property string busKey: ""
    property string trainStation: ""
    property var trainArrivals: []
    property string busStop: ""
    property var busArrivals: []
    readonly property bool configured: trainKey.length > 0 || busKey.length > 0

    readonly property var trainLineNames: ({
            "Red": "Red",
            "Blue": "Blue",
            "Brn": "Brown",
            "G": "Green",
            "Org": "Orange",
            "P": "Purple",
            "Pink": "Pink",
            "Y": "Yellow"
        })

    function minutesBetween(from, to) {
        return Math.max(0, Math.round((new Date(to) - new Date(from)) / 60000));
    }

    function refreshTrain() {
        if (!root.trainKey || !Location.loaded)
            return;
        const where = `within_circle(location, ${Location.latitude}, ${Location.longitude}, 600)`;
        const url = `https://data.cityofchicago.org/resource/8pix-ypme.json?$where=${encodeURIComponent(where)}&$limit=50`;
        Http.getJson(url, rows => {
            if (!Array.isArray(rows) || rows.length === 0)
                return;
            const nearest = rows[0];
            root.trainStation = nearest.station_name;
            Http.getJson(`https://lapi.transitchicago.com/api/1.0/ttarrivals.aspx?key=${root.trainKey}&mapid=${nearest.map_id}&max=6&outputType=JSON`, data => {
                const eta = data?.ctatt?.eta;
                if (!Array.isArray(eta))
                    return;
                const now = data.ctatt.tmst;
                root.trainArrivals = eta.map(e => ({
                            route: root.trainLineNames[e.rt] || e.rt,
                            destination: e.destNm,
                            minutes: e.isApp === "1" ? 0 : root.minutesBetween(now, e.arrT)
                        })).sort((a, b) => a.minutes - b.minutes).slice(0, 3);
            }, "transit-train");
        }, "transit-train");
    }

    function refreshBus() {
        if (!root.busKey || !Location.loaded)
            return;
        const where = `within_circle(the_geom, ${Location.latitude}, ${Location.longitude}, 600)`;
        const url = `https://data.cityofchicago.org/resource/qs84-j7wh.json?$where=${encodeURIComponent(where)}&$limit=50`;
        Http.getJson(url, rows => {
            if (!Array.isArray(rows) || rows.length === 0)
                return;
            const nearest = rows[0];
            root.busStop = nearest.public_nam;
            const stpid = parseInt(nearest.systemstop, 10);
            Http.getJson(`https://www.ctabustracker.com/bustime/api/v3/getpredictions?key=${root.busKey}&stpid=${stpid}&format=json&top=6`, data => {
                const prd = data?.["bustime-response"]?.prd;
                if (!Array.isArray(prd))
                    return;
                root.busArrivals = prd.map(p => ({
                            route: p.rt,
                            destination: p.des,
                            minutes: p.prdctdn === "DUE" ? 0 : parseInt(p.prdctdn, 10)
                        })).filter(a => !Number.isNaN(a.minutes)).sort((a, b) => a.minutes - b.minutes).slice(0, 3);
            }, "transit-bus");
        }, "transit-bus");
    }

    function refreshTransit() {
        refreshTrain();
        refreshBus();
    }

    FileView {
        id: envFile

        path: Quickshell.env("HOME") + "/Projects/pinmonkey-desktop/.env"

        onLoaded: {
            const content = text();
            const trainMatch = content.match(/^CTA_TRAIN_API_KEY=(.*)$/m);
            const busMatch = content.match(/^CTA_BUS_API_KEY=(.*)$/m);
            root.trainKey = trainMatch ? trainMatch[1].trim() : "";
            root.busKey = busMatch ? busMatch[1].trim() : "";
            root.refreshTransit();
        }
    }

    Connections {
        target: Location

        function onLoadedChanged() {
            root.refreshTransit();
        }
    }

    Timer {
        interval: 30000
        running: root.configured
        repeat: true
        onTriggered: root.refreshTransit()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingXSmall
        visible: root.configured

        Text {
            Layout.fillWidth: true
            visible: root.trainKey.length > 0
            elide: Text.ElideRight
            text: root.trainArrivals.length > 0 ? root.trainArrivals.map(a => a.route + " " + a.minutes + "m").join("  ·  ") : (root.trainStation ? "No arrivals" : "Loading…")
            font.family: Config.fontFamily
            font.pixelSize: root.captionFontSize
            color: Config.colSubtext
        }

        Text {
            Layout.fillWidth: true
            visible: root.busKey.length > 0
            elide: Text.ElideRight
            text: root.busArrivals.length > 0 ? root.busArrivals.map(a => a.route + " " + a.minutes + "m").join("  ·  ") : (root.busStop ? "No arrivals" : "Loading…")
            font.family: Config.fontFamily
            font.pixelSize: root.captionFontSize
            color: Config.colSubtext
        }
    }

    Text {
        Layout.fillWidth: true
        visible: !root.configured
        text: "Transit not configured"
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
