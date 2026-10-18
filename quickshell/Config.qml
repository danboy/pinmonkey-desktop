import QtQuick
import Quickshell
pragma Singleton

Singleton {
    id: root

    readonly property string appTitle: "pinmonkey"
    // --- Fonts ---
    readonly property string fontFamily: "Bitcount Grid Single"
    readonly property int fontSize: 16
    readonly property int fontSizeBody: 14
    readonly property int fontSizeCaption: 12
    readonly property int iconSizeStatus: Math.round(fontSize * 0.8)
    readonly property int iconSizeCaption: Math.round(fontSize * 0.7)
    // --- Spacing scale ---
    readonly property int spacingXSmall: 1
    readonly property int spacingSmall: 6
    readonly property int spacingMedium: 8
    readonly property int spacingLarge: 10
    readonly property int spacingXLarge: 14
    readonly property int appletRadHeight: 15
    readonly property int appletSpacing: spacingMedium
    // --- Component sizing ---
    readonly property int pillHeight: 34
    readonly property int pillPaddingHorizontal: 20
    readonly property int barHeight: 38
    readonly property int borderWidth: 1
    readonly property int tileHeight: 46
    readonly property int tileIconBoxSize: 32
    readonly property int tileContentMargin: 12
    readonly property int iconButtonSize: 30
    readonly property int iconSizeSmall: 16
    readonly property int iconSizeMedium: 18
    readonly property int sliderTrackMinWidth: 200
    readonly property int sliderTrackHeight: 6
    readonly property int sliderTrackRadius: 3
    readonly property int sliderHandleSize: 16
    readonly property int sliderHandleRadius: 8
    readonly property int percentTextWidth: 32
    readonly property int popupWidth: 340
    readonly property int popupMargin: spacingXLarge
    readonly property int popupGap: spacingMedium
    readonly property int osdWidth: 280
    readonly property int osdBottomMargin: 64
    readonly property int osdVisibleMs: 1500
    readonly property int animationDurationMs: 150
    readonly property int launcherWidth: 480
    readonly property int launcherHeight: 420
    readonly property int launcherRowHeight: 48
    readonly property int launcherIconSize: 28
    readonly property int launcherSearchHeight: 42
    readonly property int infoPanelWidth: 380
    readonly property int calendarCellSize: 32
    readonly property int notificationRowHeight: 52
    readonly property int weatherRefreshIntervalMs: 15 * 60 * 1000
    // --- Theme (pinmonkey "fall" palette, dark variant) ---
    readonly property color colBackground: "#282422"
    readonly property color colSurface: "#524840"
    readonly property color colSurfaceVariant: colBackground
    readonly property color colSurfaceHighlight: Qt.lighter(colSurface, 1.35)
    readonly property color colAccent: "#d65d0e"
    readonly property color colAccentText: "#fbf1c7"
    readonly property color colText: "#fbf1c7"
    readonly property color colDanger: "#cc241d"
    readonly property color colSubtext: Qt.rgba(0.984, 0.945, 0.78, 0.55)
    readonly property color colDivider: Qt.rgba(0.984, 0.945, 0.78, 0.1)
    readonly property color colBorder: Qt.rgba(0.984, 0.945, 0.78, 0.15)
    readonly property color colBorderAccent: Qt.rgba(colAccent.r, colAccent.g, colAccent.b, 0.5)
    readonly property real surfaceOpacity: 0.92
    readonly property int radiusLarge: 4
    readonly property int radiusMedium: 3
    readonly property int radiusSmall: 2
    readonly property int radiusPill: 4
    // --- Lock screen ---
    readonly property int lockClockFontSize: 64
    readonly property int lockDateFontSize: 20
    readonly property int lockPasswordFieldWidth: 220
    readonly property int lockDashboardWidth: popupWidth * 2
    readonly property int lockBoxWidth: (lockDashboardWidth - spacingLarge) / 2
    readonly property int lockBoxHeight: 240
    // --- Weather ---
    readonly property int weatherForecastDays: 4
    // --- Settings panel ---
    readonly property int settingsWidth: 580
    readonly property int settingsHeight: 520
    readonly property int settingsNavWidth: 140
    readonly property int settingsTabHeight: 36
    readonly property int settingsRowHeight: 52
}
