using Toybox.BluetoothLowEnergy as BLE;
using Toybox.System;
using Toybox.WatchUi;

class X6BleDebug extends BLE.BleDelegate {
    const SERVICE_STR = "0000BE80-0000-1000-8000-00805F9B34FB";
    const WRITE_STR   = "0000BE81-0000-1000-8000-00805F9B34FB";
    const NOTIFY_STR  = "0000BE82-0000-1000-8000-00805F9B34FB";

    var _serviceUuid;
    var _writeUuid;
    var _notifyUuid;
    var _device = null;
    var _notifyChar = null;
    var _writeChar = null;
    var _scanning = false;

    function initialize() {
        BleDelegate.initialize();
        _serviceUuid = BLE.stringToUuid(SERVICE_STR);
        _writeUuid = BLE.stringToUuid(WRITE_STR);
        _notifyUuid = BLE.stringToUuid(NOTIFY_STR);
    }

    function start() {
        X6RemoteState.setStatus("REGISTER");
        registerProfile();
        rescan();
    }

    function stop() {
        try {
            BLE.setScanState(BLE.SCAN_STATE_OFF);
        } catch (e) {
        }

        if (_device != null) {
            try {
                BLE.unpairDevice(_device);
            } catch (e2) {
            }
        }
    }

    function rescan() {
        if (_device != null) {
            try {
                BLE.unpairDevice(_device);
            } catch (e) {
            }
            _device = null;
        }

        X6RemoteState.deviceName = "-";
        X6RemoteState.lastRx = "-";
        X6RemoteState.setDetail("Looking for BE80 / X6...");
        X6RemoteState.setStatus("SCANNING");

        try {
            BLE.setScanState(BLE.SCAN_STATE_SCANNING);
        } catch (e2) {
            X6RemoteState.setStatus("SCAN ERROR");
            X6RemoteState.setDetail(e2.getErrorMessage());
        }
    }

    function registerProfile() {
        var profile = {
            :uuid => _serviceUuid,
            :characteristics => [
                {
                    :uuid => _writeUuid
                },
                {
                    :uuid => _notifyUuid,
                    :descriptors => [ BLE.cccdUuid() ]
                }
            ]
        };

        try {
            BLE.registerProfile(profile);
        } catch (e) {
            X6RemoteState.setStatus("PROFILE ERROR");
            X6RemoteState.setDetail(e.getErrorMessage());
        }
    }

    function onProfileRegister(uuid, status) {
        X6RemoteState.setDetail("BE80 profile register status " + status);
    }

    function onScanStateChange(scanState, status) {
        _scanning = (scanState == BLE.SCAN_STATE_SCANNING);
        System.println("[X6] scan=" + scanState + " status=" + status);
    }

    function onScanResults(scanResults) {
        for (var result = scanResults.next(); result != null; result = scanResults.next()) {
            var name = result.getDeviceName();
            var advertised = result.getServiceUuids();

            if (name != null) {
                System.println("[X6] found " + name);
            }

            var hasBe80 = false;
            if (advertised != null) {
                for (var u = advertised.next(); u != null; u = advertised.next()) {
                    if (u.equals(_serviceUuid)) {
                        hasBe80 = true;
                        break;
                    }
                }
            }

            var looksLikeX6 = false;
            if (name != null && name.length() >= 2) {
                looksLikeX6 = name.substring(0, 2).equals("X6");
            }

            if (hasBe80 && looksLikeX6) {
                connect(result, name);
                return;
            }

            // Fallback: accept a BE80 Insta360 camera so we can still inspect
            // devices whose advertisement name is truncated or unavailable.
            if (hasBe80) {
                connect(result, name);
                return;
            }
        }
    }

    function connect(result, name) {
        try {
            BLE.setScanState(BLE.SCAN_STATE_OFF);
        } catch (e) {
        }

        X6RemoteState.deviceName = (name == null) ? "(unnamed BE80)" : name;
        X6RemoteState.setStatus("PAIRING");
        X6RemoteState.setDetail("Connecting to camera...");

        try {
            _device = BLE.pairDevice(result);
        } catch (e2) {
            X6RemoteState.setStatus("PAIR ERROR");
            X6RemoteState.setDetail(e2.getErrorMessage());
        }
    }

    function onConnectedStateChanged(dev, state) {
        System.println("[X6] connection state=" + state);

        if (state == BLE.CONNECTION_STATE_CONNECTED) {
            _device = dev;
            X6RemoteState.setStatus("CONNECTED");
            X6RemoteState.setDetail("Resolving BE80/BE81/BE82...");
            resolveGatt();
        } else {
            _notifyChar = null;
            _writeChar = null;
            if (_device == dev) {
                _device = null;
            }
            X6RemoteState.setStatus("DISCONNECTED");
            X6RemoteState.setDetail("Tap/START to scan again");
        }
    }

    function resolveGatt() {
        if (_device == null) {
            return;
        }

        var service = null;
        try {
            service = _device.getService(_serviceUuid);
        } catch (e) {
            X6RemoteState.setStatus("GATT ERROR");
            X6RemoteState.setDetail(e.getErrorMessage());
            return;
        }

        if (service == null) {
            X6RemoteState.setStatus("NO BE80");
            X6RemoteState.setDetail("Connected, but BE80 not resolved");
            return;
        }

        try {
            _writeChar = service.getCharacteristic(_writeUuid);
            _notifyChar = service.getCharacteristic(_notifyUuid);
        } catch (e2) {
            X6RemoteState.setStatus("CHAR ERROR");
            X6RemoteState.setDetail(e2.getErrorMessage());
            return;
        }

        if (_writeChar == null) {
            X6RemoteState.setStatus("NO BE81");
            return;
        }
        if (_notifyChar == null) {
            X6RemoteState.setStatus("NO BE82");
            return;
        }

        X6RemoteState.setStatus("SUBSCRIBE");
        X6RemoteState.setDetail("BE81 OK / BE82 OK; enabling notifications");

        try {
            var cccd = _notifyChar.getDescriptor(BLE.cccdUuid());
            if (cccd == null) {
                X6RemoteState.setStatus("NO CCCD");
                X6RemoteState.setDetail("BE82 has no CCCD descriptor");
                return;
            }
            cccd.requestWrite([0x01, 0x00]b);
        } catch (e3) {
            X6RemoteState.setStatus("CCCD ERROR");
            X6RemoteState.setDetail(e3.getErrorMessage());
        }
    }

    function onDescriptorWrite(descriptor, status) {
        if (status == BLE.STATUS_SUCCESS) {
            X6RemoteState.setStatus("READY RX");
            X6RemoteState.setDetail("BE82 subscribed. Waiting for camera packets.");
        } else {
            X6RemoteState.setStatus("CCCD FAIL");
            X6RemoteState.setDetail("Descriptor write status " + status);
        }
    }

    function onCharacteristicChanged(characteristic, value) {
        X6RemoteState.setRx(bytesToHex(value));
    }

    function onCharacteristicWrite(characteristic, status) {
        System.println("[X6] characteristic write status=" + status);
    }

    function bytesToHex(value) {
        if (value == null) {
            return "(null)";
        }

        var out = "";
        var max = value.size();
        if (max > 40) {
            max = 40;
        }

        for (var i = 0; i < max; i++) {
            if (i > 0) {
                out += " ";
            }
            out += value[i].format("%02X");
        }

        if (value.size() > max) {
            out += " ... (" + value.size() + "B)";
        }
        return out;
    }
}
