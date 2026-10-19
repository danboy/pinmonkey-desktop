import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.components

PopupWindow {
    id: popup

    property Item anchorItem
    default property alias content: contentLayout.data
    property alias contentSpacing: contentLayout.spacing
    // Lets a popup claim more vertical room than its content needs (e.g. so children can
    // space-between into the slack) without risking clipped content if it ever grows past
    // this - content height always wins via the max().
    property int minimumContentHeight: 0

    // External callers toggle THIS, not `visible` - `visible` stays mapped a little longer
    // (via CloseDelay) so the close animation on `card` below has time to play before the
    // surface actually unmaps.
    property bool open: false

    implicitWidth: Config.popupWidth
    implicitHeight: Math.max(contentLayout.implicitHeight, minimumContentHeight) + Config.popupMargin * 2
    color: "transparent"
    visible: closeDelay.active
    grabFocus: true

    CloseDelay {
        id: closeDelay

        open: popup.open
    }

    // "anchorItem" (a bar pill) is vertically centered inside a taller bar, so its
    // bottom edge sits above the bar's own bottom edge. Rather than rely on margin
    // direction (ambiguous/unreliable with item-based anchoring), compute the exact
    // window-relative anchor point ourselves in the anchoring handler.
    //
    // "window" (not "item") is used so the rect below is interpreted in the anchor
    // window's coordinate space rather than the anchor item's own local space.
    anchor {
        window: popup.anchorItem ? popup.anchorItem.QsWindow.window : null
        edges: Edges.Bottom
        gravity: Edges.Bottom

        onAnchoring: {
            if (!popup.anchorItem)
                return;
            const topLeft = popup.anchorItem.QsWindow.itemPosition(popup.anchorItem);
            const bottomCenterX = topLeft.x + popup.anchorItem.width / 2;
            const bottomY = topLeft.y + popup.anchorItem.height;
            const gap = (Config.barHeight - Config.pillHeight) / 2 + Config.popupGap;
            popup.anchor.rect = Qt.rect(bottomCenterX - popup.implicitWidth / 2, bottomY + gap, popup.implicitWidth, 1);
        }
    }

    onVisibleChanged: if (visible)
        dismissCatcher.forceActiveFocus()

    Item {
        id: dismissCatcher

        anchors.fill: parent
        focus: true

        property bool winActive: Window.active

        Keys.onEscapePressed: popup.open = false
        onWinActiveChanged: if (!winActive)
            popup.open = false
    }

    Item {
        id: card

        anchors.fill: parent
        opacity: popup.open ? 1 : 0
        scale: popup.open ? 1 : 0.96

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animationDurationMs
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Config.animationDurationMs
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Config.colSurface.r, Config.colSurface.g, Config.colSurface.b, Config.surfaceOpacity)
            radius: Config.radiusLarge
            border.width: Config.borderWidth
            border.color: Config.colDivider
        }

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            anchors.margins: Config.popupMargin
            spacing: Config.spacingXLarge
        }
    }
}
