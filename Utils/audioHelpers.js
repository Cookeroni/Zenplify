function labelFor(n) {
    if (!n)
        return "None";
    return n.description || n.nickname || (n.properties ? n.properties["node.description"] : "") || n.name || "Unknown";
}

function isBluetooth(n) {
    if (!n)
        return false;
    var api = n.properties ? (n.properties["device.api"] || "") : "";
    var name = (n.name || "").toLowerCase();
    return api === "bluez5" || name.indexOf("bluez") !== -1 || name.indexOf("bluetooth") !== -1;
}

// ------------------------- Device typing --------------------------
// Reads PipeWire's device.form-factor / device.bus, which use a fixed
// vocabulary (see PW_KEY_DEVICE_FORM_FACTOR). Falls back through the
// node props, the bound device's props, then the description string.
function nodeProp(n, key) {
    if (!n)
        return "";
    if (n.properties && n.properties[key])
        return n.properties[key];
    if (n.device && n.device.properties && n.device.properties[key])
        return n.device.properties[key];
    return "";
}

function iconFor(n) {
    if (!n)
        return "󰓃";

    // These three are the useful signals. form-factor is the richest but
    // lives on the DEVICE, so it may be absent on the node — checked last
    // via the device fallback. api/description are reliably node-local.
    var api = nodeProp(n, "device.api").toLowerCase();
    var ff = deviceProp(n, "device.form-factor").toLowerCase();
    var desc = (labelFor(n) || "").toLowerCase();

    // Form-factor, when present, is authoritative
    if (ff === "headphone" || ff === "headset" || ff === "hands-free")
        return "󰋋";
    if (ff === "speaker" || ff === "hifi")
        return "󰓃";
    if (ff === "handset" || ff === "portable")
        return "󰄜";
    if (ff === "tv")
        return "󰡇";

    // Description keywords — catches "buds", "airpods", HDMI, etc.
    if (desc.indexOf("headphone") !== -1 || desc.indexOf("headset") !== -1
        || desc.indexOf("buds") !== -1 || desc.indexOf("airpod") !== -1
        || desc.indexOf("earphone") !== -1)
        return "󰋋";
    if (desc.indexOf("hdmi") !== -1 || desc.indexOf("display") !== -1
        || desc.indexOf("tv") !== -1)
        return "󰡇";

    // Bluetooth with no better signal → generic BT audio (usually earbuds)
    if (api === "bluez5")
        return "󰂱";

    return "󰓃";   // speaker
}

function deviceProp(n, key) {
    if (!n)
        return "";
    // Node's own props first (sometimes mirrored there)
    if (n.properties && n.properties[key])
        return n.properties[key];
    // Then the bound device's props
    var d = n.device;
    if (d && d.properties && d.properties[key])
        return d.properties[key];
    return "";
}

function isCurrent(n) {
    return n && root.current && n.id === root.current.id;
}

function volumePercent(volume) {
    return Math.round(volume * 100) + "%";
}

// nf-md volume glyphs (muted / low / medium / high)
function volumeIcon(volume, muted) {
    if (muted || volume <= 0)
        return "󰝟";
    if (volume <= 0.34)
        return "󰕿";
    if (volume <= 0.67)
        return "󰖀";
    return "󰕾";
}