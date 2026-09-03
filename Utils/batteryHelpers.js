// Format a UPower duration (seconds) as a compact "1h 20m" / "45m" string.
function fmtTime(seconds) {
    if (!seconds || seconds <= 0)
        return "—";
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return h > 0 ? h + "h " + m + "m" : m + "m";
}

function levelColorFor(pct, isCharging) {
    const l = Math.round(pct * 100);
    return isCharging ? Theme.charging
        : (l <= 10) ? Theme.danger
            : (l < 50) ? Theme.warning
                : Theme.success;
}

function deviceName(d) {
    return (d.model && d.model !== "") ? d.model : UPowerDeviceType.toString(d.type);
}

// Material Design glyphs, codepoints checked against nerd-fonts/glyphnames.json
function deviceIcon(type) {
    switch (type) {
        case UPowerDeviceType.Mouse: return String.fromCodePoint(0xF037D);
        case UPowerDeviceType.Keyboard: return String.fromCodePoint(0xF030C);
        case UPowerDeviceType.Headset: return String.fromCodePoint(0xF02CE);
        case UPowerDeviceType.Headphones: return String.fromCodePoint(0xF02CB);
        case UPowerDeviceType.Speakers: return String.fromCodePoint(0xF04C3);
        case UPowerDeviceType.Phone: return String.fromCodePoint(0xF011C);
        case UPowerDeviceType.Tablet: return String.fromCodePoint(0xF04F6);
        case UPowerDeviceType.GamingInput: return String.fromCodePoint(0xF0297);
        case UPowerDeviceType.Pen: return String.fromCodePoint(0xF03EA);
        case UPowerDeviceType.Touchpad: return String.fromCodePoint(0xF0322);
        case UPowerDeviceType.Wearable: return String.fromCodePoint(0xF0589);
        case UPowerDeviceType.Ups: return String.fromCodePoint(0xF06A5);
        case UPowerDeviceType.Monitor: return String.fromCodePoint(0xF0379);
        case UPowerDeviceType.Printer: return String.fromCodePoint(0xF042A);
        case UPowerDeviceType.Camera: return String.fromCodePoint(0xF0100);
        case UPowerDeviceType.BluetoothGeneric: return String.fromCodePoint(0xF00AF);
        default: return String.fromCodePoint(0xF0079);
    }
}