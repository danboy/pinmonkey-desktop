import QtQuick
import QtQuick.Layouts
import qs

// Shared root for dashboard widgets (weather, holiday, transit, calendar, notifications,
// notepad - see WidgetRegistry.qml). One place to tune padding/spacing/typography so
// widget design can evolve without touching every widget file. NewsWidget opts out (its
// full-bleed background image needs the outer edge for itself, not inset by padding).
//
// `size` picks a padding/spacing/font preset from Config.widgetSizes per hosting
// context - "large" (default) for a widget that owns a whole dedicated box (desktop
// overlay, lock grid), "small" for one sitting compactly alongside others (info panel).
// Widgets read the resolved values off their own root (root.padding, root.bodyFontSize,
// etc.), never Config.widgetSizes directly, so they stay agnostic of which context
// they're in.
Item {
    id: root

    property string size: "large"
    readonly property var tokens: Config.widgetSizes[root.size] ?? Config.widgetSizes.large
    readonly property int padding: root.tokens.padding
    readonly property int spacing: root.tokens.spacing
    readonly property int titleFontSize: root.tokens.titleFontSize
    readonly property int bodyFontSize: root.tokens.bodyFontSize
    readonly property int captionFontSize: root.tokens.captionFontSize

    property string title: ""
    default property alias content: body.data

    // Item (unlike the ColumnLayout this used to be) doesn't auto-compute its implicit
    // size from children - needed when NOT filling (the "small"/info panel case, where
    // these sit in a Layout sized to their own content rather than a Loader-assigned
    // width/height), or the widget collapses toward 0 instead of hugging its content.
    implicitWidth: outer.implicitWidth
    implicitHeight: outer.implicitHeight

    // Two hosting shapes coexist: a Loader binds .width/.height directly onto this item
    // (desktop overlay/lock grid - see their Binding blocks), where these Layout.* are
    // inert no-ops since the Loader isn't itself a Layout; or this is placed straight
    // inside a Layout (info panel's RowLayout/ColumnLayout), where fillWidth/fillHeight
    // need to be real. A "large" widget owns its whole box and should fill it vertically
    // too; a "small" one sits alongside siblings whose own layout (spacers, dividers)
    // should control height instead - callers can still override either per instance.
    Layout.fillWidth: true
    Layout.fillHeight: root.size === "large"

    ColumnLayout {
        id: outer

        anchors.fill: parent
        anchors.margins: root.padding
        spacing: root.spacing

        Text {
            Layout.fillWidth: true
            visible: root.title.length > 0
            text: root.title
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: root.titleFontSize
            color: Config.colText
        }

        ColumnLayout {
            id: body

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.spacing
        }
    }
}
