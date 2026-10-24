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
    readonly property int notificationToastVisibleMs: 5000
    // How long with no input before a user counts as "away" for the toast-holding behavior
    // below (see NotificationToast.qml) - short on purpose, this just needs to catch "stepped
    // away from the desk", not a real idle/lock-grade timeout.
    readonly property real notificationToastIdleTimeoutSec: 5
    readonly property int animationDurationMs: 150
    readonly property int launcherWidth: 480
    readonly property int launcherHeight: 420
    readonly property int launcherRowHeight: 48
    readonly property int launcherIconSize: 28
    readonly property int launcherSearchHeight: 42
    // Right column (notifications) matches the toast's width (popupWidth) so a notification
    // reads the same size whether it's in this list or just arrived as a toast.
    readonly property int infoPanelLeftColumnWidth: 260
    readonly property int infoPanelWidth: infoPanelLeftColumnWidth + spacingLarge + borderWidth + popupWidth + popupMargin * 2
    readonly property int infoPanelHeight: 420
    readonly property int notificationsListMaxHeight: 240
    readonly property int panelWindowTitleMaxWidth: 320
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
    readonly property int lockGridColumns: 3
    readonly property int lockGridMargin: spacingXLarge
    // --- Widget styling (via WidgetLayout.qml) ---
    // Per-context padding/spacing/typography. "large" = a widget that owns a whole
    // dedicated box (desktop overlay, lock grid). "small" = a widget sitting compactly
    // alongside others (info panel). WidgetLayout picks a set via its `size` property;
    // widgets read the resolved values off WidgetLayout (root.padding etc), never these
    // directly.
    readonly property var widgetSizes: ({
            large: {
                padding: 28,
                spacing: spacingMedium,
                titleFontSize: 16,
                bodyFontSize: 14,
                captionFontSize: 13
            },
            small: {
                padding: spacingSmall,
                spacing: spacingXSmall,
                titleFontSize: fontSizeBody,
                bodyFontSize: fontSizeBody,
                captionFontSize: fontSizeCaption
            }
        })
    // --- Desktop widgets ---
    readonly property int desktopWidgetDefaultWidth: 280
    readonly property int desktopWidgetDefaultHeight: 200
    readonly property int desktopWidgetMinSize: 120
    readonly property int desktopWidgetResizeHandleSize: 18
    readonly property real desktopWidgetScrimOpacity: 0.2
    readonly property int desktopWidgetDragHandleHeight: 24
    // --- Weather ---
    readonly property int weatherForecastDays: 5
    readonly property int weatherIconSizeLarge: 96
    readonly property int weatherHourlyCount: 12
    readonly property int weatherHourlyRowHeight: 64
    // --- Settings panel ---
    readonly property int settingsWidth: 580
    readonly property int settingsHeight: 520
    readonly property int settingsNavWidth: 140
    readonly property int settingsTabHeight: 36
    readonly property int settingsRowHeight: 52
    // --- Screenshot panel ---
    readonly property int screenshotWidth: 360
    readonly property int screenshotModeButtonHeight: 64
    readonly property int screenshotCaptureButtonHeight: 40
}
