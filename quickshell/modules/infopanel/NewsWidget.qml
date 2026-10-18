import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.services

ColumnLayout {
    id: root

    property var headlines: []
    property int index: 0

    // No XML parser is bundled, so pull <title> text out of each <item> by hand.
    function decodeEntities(text) {
        return text.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#0?39;/g, "'");
    }

    function parseHeadlines(xml) {
        const items = xml.split("<item>").slice(1);
        return items.map(item => {
            const match = item.match(/<title>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/title>/);
            return match ? decodeEntities(match[1]) : null;
        }).filter(Boolean).slice(0, 10);
    }

    function refreshNews() {
        Http.getText("https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en", xml => {
            const parsed = root.parseHeadlines(xml);
            if (parsed.length > 0) {
                root.headlines = parsed;
                root.index = 0;
            }
        }, "news");
    }

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Config.spacingSmall

    Component.onCompleted: refreshNews()

    Timer {
        interval: Config.weatherRefreshIntervalMs
        running: true
        repeat: true
        onTriggered: root.refreshNews()
    }

    Timer {
        interval: 15000
        running: root.headlines.length > 1
        repeat: true
        onTriggered: root.index = (root.index + 1) % root.headlines.length
    }

    Text {
        text: "News"
        font.family: Config.fontFamily
        font.bold: true
        font.pixelSize: Config.fontSizeBody
        color: Config.colText
    }

    Text {
        Layout.fillWidth: true
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
        maximumLineCount: 4
        text: root.headlines.length > 0 ? root.headlines[root.index] : "Loading…"
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSizeCaption
        color: Config.colSubtext
    }
}
