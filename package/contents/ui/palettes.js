.pragma library

// Ready-made background colours, offered next to the colour picker. The tiles
// are a darker shade of the background. The spectrum instead drifts through
// all hues at spectrumSat saturation.
var list = [
    { name: "Blue",   hue: 0.583, sat: 0.85 },
    { name: "Red",    hue: 0.01,  sat: 0.74 },
    { name: "Purple", hue: 0.76,  sat: 0.62 },
    { name: "Yellow", hue: 0.12,  sat: 0.85 },
    { name: "Green",  hue: 0.38,  sat: 0.70 },
    { name: "Orange", hue: 0.07,  sat: 0.85 },
    { name: "Gray",   hue: 0.0,   sat: 0.0 }
]

var spectrumSat = 0.82

// The colour at the bottom of the background for a hue and saturation.
function shade(hue, sat) {
    return Qt.hsva(hue, sat, sat > 0 ? 0.95 : 0.66, 1)
}

function color(index) {
    return shade(list[index].hue, list[index].sat)
}

// The top of the background: a little lighter and less saturated.
function top(bottom) {
    const v = bottom.hsvValue
    return Qt.hsva(Math.max(0, bottom.hsvHue), bottom.hsvSaturation * 0.86, v + Math.min(0.12, (1 - v) * 0.38), 1)
}

// Settings before 1.3 held Theme: 0 for the spectrum, N for preset N-1. It
// still says what to show until the settings are saved again.
function spectrum(setting, legacyTheme) {
    return legacyTheme > 0 ? false : setting
}

function fixedColor(setting, legacyTheme) {
    return legacyTheme > 0 ? color(Math.min(legacyTheme, list.length) - 1) : setting
}
