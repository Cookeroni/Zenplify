// Parses `brightnessctl -m` output: "device,class,current,percent,max"
// We read raw + max and compute our own percentage, so the exact format of
// the percent field doesn't matter.
function parseInfo(out) {
    const line = (out || "").trim().split("\n")[0];
    if (!line)
        return null;
    const f = line.split(",");
    if (f.length < 5)
        return null;
    return { device: f[0], raw: parseInt(f[2]), max: parseInt(f[4]) };
}

function percent(value) {
    return Math.round(value * 100) + "%";
}

// nf-md brightness glyphs (low / medium / high)
function icon(value) {
    if (value <= 0.34)
        return "󰃞";
    if (value <= 0.67)
        return "󰃝";
    return "󰃠";
}
