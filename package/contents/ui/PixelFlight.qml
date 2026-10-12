import QtQuick
import QtQuick.Window

import "palettes.js" as Palettes
import "pictures.js" as Pictures

// The whole effect, free of Plasma imports so it can be previewed standalone.
//
// It plays scenes one after another. A scene starts on an empty background,
// the tiles sweep in, the view scrolls along the bitmap, and the tiles sweep
// out again. With stopAfterIntro the first scene instead glides to a halt and
// stays on screen as a still wallpaper.
Item {
    id: flight

    property string picture: "retro"     // id from pictures.js, or "custom"
    property url customImage             // used when picture is "custom"
    property int imageWidth: 480         // cells a custom image is scaled to across
    property real brightness: 0          // -1..1, shifts the mid-tones of the picture
    property real contrast: 1
    property bool dither: true
    property bool invert: false

    property real pixelSize: 0           // logical px per bitmap cell; 0 picks it from the width
    property real speed: 1.0
    property real gap: 0.1               // gap between tiles, fraction of a cell
    property real tileOpacity: 0.16      // how dark the tiles are against the background
    property real shadowSoftness: 0.6    // 0 is a crisp shadow, 1 fades out over a whole cell
    property real shadowStrength: 0.1
    property real appearSoftness: 0.5    // 0 sweeps the tiles in as a sharp wave, 1 grows them all at once
    property int theme: 0                // 0 is the drifting spectrum, N pins palette N-1
    property bool stopAfterIntro: true
    property int replayMinutes: 0        // replay a scene this often once stopped; 0 never
    property bool running: true

    // The original shows about 122 cells across the screen.
    readonly property real cell: pixelSize > 0 ? pixelSize : Math.max(6, width / 122)
    readonly property real scrollSpeed: 10   // cells per second
    readonly property real sweepTime: 3      // seconds for the tiles to sweep in or out
    readonly property real brakeTime: 4      // seconds to glide to a halt
    readonly property real emptyTime: 1.2    // seconds of empty background between scenes
    readonly property real huePeriod: 90     // seconds for the spectrum to go full circle
    readonly property real pitch: Math.PI / 4
    readonly property real yaw: Math.PI / 8

    // A custom image that is missing or unreadable falls back to the first bundled picture.
    property bool customFailed: false
    readonly property bool useCustom: picture === Pictures.custom && customImage.toString() !== "" && !customFailed
    readonly property var bundled: Pictures.find(picture)

    property var scenes: []
    property int sceneIndex: 0
    readonly property var scene: scenes[sceneIndex] ?? ({ x0: 0, y0: 0, x1: 1, y1: 0, yaw: 1, rampX: 1, rampY: 0 })
    property real t: 0            // seconds into the current scene
    property real duration: 1     // seconds the full scroll takes
    property real brakeAt: Infinity
    property real leaveAt: Infinity
    property bool frozen: false

    property real camX: 0
    property real camY: 0
    property real appear: 0
    property real vanish: 0
    property real hue: Math.random()

    function startScene(index) {
        sceneIndex = index
        const s = scene
        duration = Math.hypot(s.x1 - s.x0, s.y1 - s.y0) / scrollSpeed
        if (stopAfterIntro) {
            brakeAt = duration * 0.4
            leaveAt = Infinity
        } else {
            brakeAt = Infinity
            leaveAt = duration - sweepTime
        }
        t = 0
        frozen = false
        step(0)
    }

    function nextScene() {
        const count = scenes.length
        startScene((sceneIndex + 1 + Math.floor(Math.random() * (count - 1))) % count)
    }

    // Sweeps the still picture away and plays another scene.
    function replay() {
        if (!frozen)
            return
        leaveAt = t
        frozen = false
    }

    function step(frameTime) {
        const dt = Math.min(frameTime, 0.1) * speed
        t += dt
        if (theme === 0)
            hue = (hue + dt / huePeriod) % 1

        let travelled = t
        if (t > brakeAt) {
            const tau = Math.min(t - brakeAt, brakeTime)
            travelled = brakeAt + tau - tau * tau / (2 * brakeTime)
        }
        const f = travelled / duration
        camX = scene.x0 + (scene.x1 - scene.x0) * f
        camY = scene.y0 + (scene.y1 - scene.y0) * f

        appear = Math.min(1, t / sweepTime)
        vanish = Math.max(0, Math.min(1, (t - leaveAt) / sweepTime))

        if (t > leaveAt + sweepTime + emptyTime)
            nextScene()
        else if (leaveAt === Infinity && t >= brakeAt + brakeTime)
            frozen = true
    }

    onStopAfterIntroChanged: if (!stopAfterIntro) replay()
    onCustomImageChanged: customFailed = false

    FrameAnimation {
        running: flight.running && flight.visible && !flight.frozen && flight.scenes.length > 0
        onTriggered: flight.step(frameTime)
    }

    Timer {
        interval: flight.replayMinutes * 60000
        repeat: true
        running: flight.running && flight.frozen && flight.replayMinutes > 0
        onTriggered: flight.replay()
    }

    Image {
        id: world
        source: flight.useCustom ? flight.customImage : "../images/" + flight.bundled.file
        // Scaling a custom image down here is what turns it into "pixels".
        sourceSize.width: flight.useCustom ? flight.imageWidth : 0
        smooth: false
        visible: false

        // Every new picture starts over from an empty background.
        onStatusChanged: {
            if (status === Image.Error && flight.useCustom) {
                flight.customFailed = true
            } else if (status === Image.Ready) {
                flight.scenes = (!flight.useCustom && flight.bundled.scenes)
                    || Pictures.randomScenes(implicitWidth, implicitHeight)
                flight.startScene(Math.floor(Math.random() * flight.scenes.length))
            }
        }
    }

    ShaderEffect {
        id: effect
        anchors.fill: parent
        blending: false

        // Bitmap plane turned by yaw in its own plane, then tilted back by
        // pitch, which just squashes it vertically (orthographic view).
        readonly property real angle: flight.scene.yaw * flight.yaw
        readonly property real m00: Math.cos(angle) * flight.cell
        readonly property real m01: -Math.sin(angle) * flight.cell
        readonly property real m10: Math.sin(angle) * Math.cos(flight.pitch) * flight.cell
        readonly property real m11: Math.cos(angle) * Math.cos(flight.pitch) * flight.cell
        readonly property real det: m00 * m11 - m01 * m10

        readonly property int palette: Math.min(flight.theme, Palettes.list.length) - 1
        readonly property real baseHue: palette < 0 ? flight.hue : Palettes.list[palette].hue
        readonly property real baseSat: palette < 0 ? 0.82 : Palettes.list[palette].sat

        property var source: world
        property size resolution: Qt.size(width, height)
        property size texSize: Qt.size(Math.max(1, world.implicitWidth), Math.max(1, world.implicitHeight))
        property point center: Qt.point(flight.camX, flight.camY)
        property vector4d toScreen: Qt.vector4d(m00, m01, m10, m11)
        property vector4d toPlane: Qt.vector4d(m11 / det, -m01 / det, -m10 / det, m00 / det)
        property point ramp: Qt.point(flight.scene.rampX, flight.scene.rampY)
        property real appear: flight.appear
        property real vanish: flight.vanish
        property real band: 0.15 + 2.6 * flight.appearSoftness
        property real dpr: Screen.devicePixelRatio
        property real gap: flight.gap
        property real tileOpacity: flight.tileOpacity
        property real shadowBlur: Math.max(0.03, Math.min(1, flight.shadowSoftness))
        property real shadowDepth: flight.shadowStrength
        property real wrap: !flight.useCustom && flight.bundled.tile ? 1 : 0
        property real gamma: Math.pow(2, -1.5 * flight.brightness)
        property real contrast: flight.contrast
        property real dither: flight.dither ? 1 : 0
        property real invert: flight.invert ? 1 : 0
        property color colorTop: Qt.hsva(baseHue, baseSat * 0.86, baseSat > 0 ? 0.97 : 0.78, 1)
        property color colorBottom: Qt.hsva(baseHue, baseSat, baseSat > 0 ? 0.95 : 0.66, 1)

        fragmentShader: "../shaders/pixels.frag.qsb"
    }
}
