using Toybox.Application;
using Toybox.WatchUi;

class X6RemoteApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        X6RemoteState.ble = new X6BleDebug();
        X6RemoteState.ble.start();
    }

    function onStop(state) {
        if (X6RemoteState.ble != null) {
            X6RemoteState.ble.stop();
        }
    }

    function getInitialView() {
        return [ new X6RemoteView(), new X6RemoteInputDelegate() ];
    }
}
