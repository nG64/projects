using Toybox.Graphics;
using Toybox.WatchUi;

class X6RemoteView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        dc.drawText(cx, 28, Graphics.FONT_MEDIUM, "INSTA360 X6", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, 78, Graphics.FONT_SMALL, "BLE DEBUG", Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(18, 140, Graphics.FONT_SMALL, "Status:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(18, 175, Graphics.FONT_MEDIUM, X6RemoteState.status, Graphics.TEXT_JUSTIFY_LEFT);

        dc.drawText(18, 245, Graphics.FONT_SMALL, "Camera:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(18, 280, Graphics.FONT_SMALL, X6RemoteState.deviceName, Graphics.TEXT_JUSTIFY_LEFT);

        dc.drawText(18, 345, Graphics.FONT_SMALL, "Detail:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(18, 380, Graphics.FONT_TINY, X6RemoteState.detail, Graphics.TEXT_JUSTIFY_LEFT);

        dc.drawText(18, 470, Graphics.FONT_SMALL, "Last RX:", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(18, 505, Graphics.FONT_TINY, X6RemoteState.lastRx, Graphics.TEXT_JUSTIFY_LEFT);

        dc.drawText(cx, dc.getHeight() - 60, Graphics.FONT_TINY, "Tap/START = rescan", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class X6RemoteInputDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        if (X6RemoteState.ble != null) {
            X6RemoteState.ble.rescan();
        }
        return true;
    }

    function onTap(clickEvent) {
        if (X6RemoteState.ble != null) {
            X6RemoteState.ble.rescan();
        }
        return true;
    }
}
