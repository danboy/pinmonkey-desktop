import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.services

// Mirrors pinmonkey's dash News box: the current article's thumbnail as a full-bleed
// background behind a highlighted headline, with the summary read out word-by-word
// "spritz" style (RSVP speed-reading: one word at a time, pivot letter picked out) instead
// of a static wrapped paragraph.
Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    property var articles: []
    property int index: 0
    readonly property var article: root.articles.length > 0 ? root.articles[root.index] : null

    function decodeEntities(text) {
        return text.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#0?39;/g, "'");
    }

    function parseArticles(xml) {
        const items = xml.split("<item>").slice(1);
        return items.map(item => {
            const title = item.match(/<title>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/title>/);
            if (!title)
                return null;
            const description = item.match(/<description>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?<\/description>/);
            const thumbnail = item.match(/<media:thumbnail[^>]*url="([^"]+)"/);
            return {
                title: root.decodeEntities(title[1]),
                description: description ? root.decodeEntities(description[1]) : "",
                image: thumbnail ? thumbnail[1] : ""
            };
        }).filter(Boolean).slice(0, 10);
    }

    function refreshNews() {
        Http.getText("https://feeds.bbci.co.uk/news/world/rss.xml", xml => {
            const parsed = root.parseArticles(xml);
            if (parsed.length > 0) {
                root.articles = parsed;
                root.index = 0;
            }
        }, "news");
    }

    Component.onCompleted: root.refreshNews()

    Timer {
        interval: Config.weatherRefreshIntervalMs
        running: true
        repeat: true
        onTriggered: root.refreshNews()
    }

    Timer {
        interval: 20000
        running: root.articles.length > 1
        repeat: true
        onTriggered: root.index = (root.index + 1) % root.articles.length
    }

    Image {
        id: bgImage

        anchors.fill: parent
        source: root.article?.image ?? ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 0.45 : 0
    }

    Rectangle {
        anchors.fill: parent
        color: Config.colSurface
        opacity: bgImage.status === Image.Ready ? 0 : 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingSmall

        Rectangle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            implicitHeight: headline.implicitHeight + Config.spacingSmall * 2
            radius: Config.radiusSmall
            color: Qt.rgba(Config.colAccent.r, Config.colAccent.g, Config.colAccent.b, 0.75)

            Text {
                id: headline

                anchors.fill: parent
                anchors.margins: Config.spacingSmall
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 3
                text: root.article ? root.article.title : "Loading…"
                font.family: Config.fontFamily
                font.bold: true
                font.pixelSize: Config.fontSizeCaption
                color: Config.colAccentText
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            id: spritz

            Layout.fillWidth: true
            implicitHeight: pivot.implicitHeight + Config.spacingSmall * 2
            color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, 0.75)
            border.width: 0

            property var words: []
            property int wordIndex: 0
            readonly property string currentWord: words.length > 0 ? words[wordIndex] : ""
            readonly property int highlightPos: Math.floor(currentWord.replace(/[^\w]/g, "").length / 2)

            function textToWords(text) {
                return (text || "").split(/\s+/).filter(Boolean);
            }

            function updateWords() {
                spritz.words = spritz.textToWords(root.article?.description || root.article?.title || "");
                spritz.wordIndex = 0;
            }

            Connections {
                target: root
                function onArticleChanged() {
                    spritz.updateWords();
                }
            }

            Component.onCompleted: spritz.updateWords()

            Timer {
                interval: 250
                running: spritz.words.length > 0
                repeat: true
                onTriggered: spritz.wordIndex = (spritz.wordIndex + 1) % spritz.words.length
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.4 - width / 2
                width: Config.borderWidth * 2
                height: Config.spacingSmall
                color: Config.colAccent
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.4 - width / 2
                width: Config.borderWidth * 2
                height: Config.spacingSmall
                color: Config.colAccent
            }

            Text {
                id: pivot

                // The tick marks above/below sit at 40% width - this is the ORP (optimal
                // recognition point) convention real spritz readers use, so the pivot letter's
                // *center* must land there too, not its left edge.
                x: parent.width * 0.4 - width / 2
                anchors.verticalCenter: parent.verticalCenter
                text: spritz.currentWord.length > 0 ? spritz.currentWord[spritz.highlightPos] : ""
                font.family: Config.fontFamily
                font.bold: true
                font.pixelSize: Config.fontSizeCaption
                color: Config.colAccent
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Config.spacingSmall
                anchors.right: pivot.left
                anchors.verticalCenter: pivot.verticalCenter
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
                text: spritz.highlightPos > 0 ? spritz.currentWord.slice(0, spritz.highlightPos) : ""
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeCaption
                color: Config.colText
            }

            Text {
                anchors.left: pivot.right
                anchors.right: parent.right
                anchors.rightMargin: Config.spacingSmall
                anchors.verticalCenter: pivot.verticalCenter
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                text: spritz.currentWord.slice(spritz.highlightPos + 1)
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeCaption
                color: Config.colText
            }
        }
    }
}
