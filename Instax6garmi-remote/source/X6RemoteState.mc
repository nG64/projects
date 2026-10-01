using Toybox.System;
using Toybox.WatchUi;

module X6RemoteState {
    var status = "BOOT";
    var deviceName = "-";
    var lastRx = "-";
    var detail = "Starting...";
    var ble = null;

    function setStatus(s) {
        status = s;
        System.println("[X6] " + s);
        WatchUi.requestUpdate();
    }

    function setDetail(s) {
        detail = s;
        System.println("[X6] " + s);
        WatchUi.requestUpdate();
    }

    function setRx(s) {
        lastRx = s;
        System.println("[X6 RX] " + s);
        WatchUi.requestUpdate();
    }
}
