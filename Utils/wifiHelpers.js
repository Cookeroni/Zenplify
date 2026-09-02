

// Pick a WiFi-strength glyph for a 0-100 signal value.
function iconForSignal(sig) {
    if (sig >= 75) return "󰤨";
    if (sig >= 50) return "󰤥";
    if (sig >= 25) return "󰤢";
    if (sig > 0) return "󰤟";
    return "󰤯";
}

// Split one line of `nmcli -t` output on unescaped colons.
// nmcli escapes literal ':' and '\' inside fields as '\:' and '\\'.
function parseTerse(line) {
    const fields = [];
    let cur = "";
    for (let i = 0; i < line.length; i++) {
        const c = line[i];
        if (c === "\\" && i + 1 < line.length) {
            cur += line[i + 1];
            i++;
        } else if (c === ":") {
            fields.push(cur);
            cur = "";
        } else {
            cur += c;
        }
    }
    fields.push(cur);
    return fields;
}

// Turn the raw `wifi list` output into a deduped, sorted model.
function parseList(root, text, listProc) {
    // Don't rebuild the model while a row is open (e.g. typing a password).
    // Reassigning the ListView model recreates delegates and would wipe the
    // field mid-entry. We resume on the next refresh once the row collapses.
    if (root.pendingSsid !== "") { root.scanning = false; return; }

    const lines = text.split("\n").filter(l => l.length > 0);
    const seen = ({});   // ssid -> index in result
    const result = [];
    let curSsid = "";

    for (const line of lines) {
        const f = parseTerse(line);   // [IN-USE, SIGNAL, SECURITY, SSID]
        const inUse = f[0] === "*";
        const signal = parseInt(f[1]) || 0;
        const sec = (f[2] && f[2] !== "--") ? f[2] : "";
        const ssid = f[3] || "";

        if (ssid.length === 0) continue;   // skip hidden networks

        if (inUse) curSsid = ssid;

        // Same SSID can appear multiple times (multiple APs) — keep the
        // strongest, but never lose the "in use" flag.
        if (seen[ssid] !== undefined) {
            const e = result[seen[ssid]];

            if (signal > e.signal) e.signal = signal;
            if (inUse) e.inUse = true;
            continue;
        }

        seen[ssid] = result.length;
        result.push({ ssid: ssid, signal: signal, security: sec, inUse: inUse });
    }

    // Connected first, then strongest signal.
    result.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));

    root.currentSsid = curSsid;
    root.networks = result;
    root.scanning = false;
}

// Network command functions (Pass the Process references to run them)
function refresh(radioProc, listProc, profilesProc) {
    radioProc.running = true;
    listProc.running = true;
    profilesProc.running = true;
}

function rescan(root, scanProc) {
    if (!root.wifiEnabled) return;
    root.scanning = true;
    scanProc.running = true;
}

// Trigger standard process commands
function setWifi(toggleProc, on) {
    toggleProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
    toggleProc.running = true;
}

function connectOpen(connectProc, ssid) {
    connectProc.command = ["nmcli", "device", "wifi", "connect", ssid];
    connectProc.running = true;
}

function connectSecured(connectProc, ssid, pw) {
    if (pw.length === 0) return;
    connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", pw];
    connectProc.running = true;
}

// Trigger connection modification profile commands
function disconnect(connectProc, ssid) {
    connectProc.command = ["nmcli", "connection", "down", ssid];
    connectProc.running = true;
}

function connectKnown(connectProc, ssid) {
    connectProc.command = ["nmcli", "connection", "up", "id", ssid];
    connectProc.running = true;
}

function forget(connectProc, ssid) {
    connectProc.command = ["nmcli", "connection", "delete", "id", ssid];
    connectProc.running = true;
}

function isSaved(savedSsids, ssid) {
    return savedSsids.indexOf(ssid) !== -1;
}
