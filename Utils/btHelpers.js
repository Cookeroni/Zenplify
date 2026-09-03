function refresh(infoProc) {
    infoProc.running = true;
}

function startScan(powered, scanning, scanProc) {
    if (!root.powered) return;
    root.scanning = true;
    scanProc.running = true;
}

function setPower(actionProc, on) {
    actionProc.command = ["bluetoothctl", "power", on ? "on" : "off"];
    actionProc.running = true;
}
function connectDev(actionProc, mac) {
    actionProc.command = ["bluetoothctl", "connect", mac];
    actionProc.running = true;
}
function disconnectDev(actionProc, mac) {
    actionProc.command = ["bluetoothctl", "disconnect", mac];
    actionProc.running = true;
}

// Pair flow for a freshly-discovered device: pair, trust, connect.
// Works for "Just Works" devices; PIN/passkey pairing needs an agent, which we don't run here yet.
function pairDev(actionProc, mac) {
    actionProc.command = ["sh", "-c",
        "bluetoothctl pair " + mac
        + " && bluetoothctl trust " + mac
        + " && bluetoothctl connect " + mac];
    actionProc.running = true;
}
function forgetDev(actionProc, mac) {
    actionProc.command = ["bluetoothctl", "remove", mac];
    actionProc.running = true;
}

function iconFor(connected) {
    return connected ? "󰂱" : "󰂯";
}

// Parse one batch of `bluetoothctl` output (sections split by markers).
function parseInfo(devices,connectedName,text) {
    const lines = text.split("\n");
    const sec = ({ show: [], all: [], conn: [], pair: [] });
    let cur = "";
    for (const line of lines) {
        if (line === "##SHOW##") { cur = "show"; continue; }
        if (line === "##ALL##") { cur = "all"; continue; }
        if (line === "##CONN##") { cur = "conn"; continue; }
        if (line === "##PAIR##") { cur = "pair"; continue; }
        if (cur.length > 0)
            sec[cur].push(line);
    }

    // Adapter power
    let powered = false;
    for (const l of sec.show) {
        const t = l.trim();
        if (t.indexOf("Powered:") === 0)
            powered = (t.indexOf("yes") !== -1);
    }
    root.powered = powered;

    // "Device AA:BB:CC:DD:EE:FF Some Name" -> { mac: name }
    function devMap(arr) {
        const m = ({});
        for (const l of arr) {
            const t = l.trim();
            if (t.indexOf("Device ") !== 0)
                continue;
            const rest = t.substring(7);
            const sp = rest.indexOf(" ");
            const mac = sp === -1 ? rest : rest.substring(0, sp);
            const name = sp === -1 ? mac : rest.substring(sp + 1);
            m[mac] = name;
        }
        return m;
    }

    const all = devMap(sec.all);
    const conn = devMap(sec.conn);
    const pair = devMap(sec.pair);

    const result = [];
    let connName = "";
    for (const mac in all) {
        const isConn = conn[mac] !== undefined;
        const isPair = pair[mac] !== undefined;
        const name = all[mac];
        // BlueZ reports unresolved devices with the MAC as the "name", just
        // using dashes instead of colons (e.g. 34-09-C9-78-BF-0C). Detect that
        // so the UI can label them and sort real names to the top.
        const named = name.toUpperCase() !== mac.replace(/:/g, "-").toUpperCase()
                   && name.toUpperCase() !== mac.toUpperCase();
        if (isConn)
            connName = name;
        result.push({ mac: mac, name: name, named: named, connected: isConn, paired: isPair });
    }

    // Connected first, then paired, then named devices, then alphabetical.
    result.sort((a, b) =>
        (b.connected - a.connected)
        || (b.paired - a.paired)
        || (b.named - a.named)
        || a.name.localeCompare(b.name));

    root.connectedName = connName;
    root.devices = result;
}

