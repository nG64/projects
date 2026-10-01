# Insta360 X6 Garmin Remote

Experimental Garmin Connect IQ project for controlling an Insta360 X6 from a Garmin Edge 1050 over BLE.

## Current build: BLE diagnostic

This first build intentionally does **not** send record commands yet. It verifies the transport path first:

1. Scan for an X6 / Insta360 device advertising BE80.
2. Pair from the Edge 1050.
3. Resolve BE80 / BE81 / BE82.
4. Subscribe to BE82 notifications through the CCCD.
5. Display and log raw camera packets.

Known UUIDs:

- Service: `0000BE80-0000-1000-8000-00805F9B34FB`
- Command: `0000BE81-0000-1000-8000-00805F9B34FB`
- Notifications: `0000BE82-0000-1000-8000-00805F9B34FB`

## Build

Open the repository with the Garmin Monkey C extension / Connect IQ SDK.

Target product:

```
edge1050
```

Typical SDK build:

```bash
monkeyc -f monkey.jungle -d edge1050 -o bin/X6Remote.prg -y /path/to/developer_key
```

The exact SDK path and key path depend on your local Connect IQ installation.

## Test procedure

1. Turn the Insta360 X6 on.
2. Make sure the phone/Insta360 app is not actively connected to the camera.
3. Start **Insta360 X6 Debug** on the Edge.
4. Expected state sequence:

```
SCANNING
PAIRING
CONNECTED
SUBSCRIBE
READY RX
```

5. Leave the app open for 10–20 seconds and note any packet shown under **Last RX**.
6. Tap the screen or press START to force a clean rescan.

If it stops at `NO BE80`, `NO BE81`, `NO BE82`, `CCCD ERROR`, or disconnects, report the exact status and detail text.

## Next step

Once BE82 notifications are confirmed on X6, the next branch will add the newer sync / handshake / authorization state machine before attempting `START_CAPTURE` and `STOP_CAPTURE`.

## Sources / protocol references

This work is informed by public reverse-engineering projects including:

- arsfabula/Insta360-Remote-CIQ
- xaionaro-go/insta360ctl
- dstrat28/action-multicam-remote
