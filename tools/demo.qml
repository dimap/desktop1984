// Renders the demo video frame by frame: make demo
//
// The animation is stepped by hand at a fixed frame rate instead of running
// in real time, so the result is smooth however slow the grabbing is.
import QtQuick
import QtQuick.Window

import "../package/contents/ui"

Window {
    id: window
    width: 1280
    height: 720
    visible: true
    title: "xflyover demo"

    readonly property int fps: 30
    readonly property size videoSize: Qt.size(1920, 1080)
    readonly property string frames: "build/frames/"

    // What to show, in order. A shot sweeps in, scrolls and sweeps out again;
    // the last one glides to a halt instead and is held as a still picture.
    readonly property var shots: [
        { picture: "retro", scene: { x0: 130, y0: 110, x1: 250, y1: 110, yaw: -1, rampX: 1, rampY: 0 }, seconds: 8 },
        { picture: "retro", scene: { x0: 110, y0: 318, x1: 230, y1: 318, yaw: 1, rampX: 1, rampY: 0 }, seconds: 8 },
        { picture: "kde2", scene: { x0: 440, y0: 185, x1: 550, y1: 185, yaw: -1, rampX: 1, rampY: 0 }, seconds: 8 },
        { picture: "kde3", scene: { x0: 730, y0: 590, x1: 730, y1: 680, yaw: 1, rampX: 0, rampY: 1 }, seconds: 8 },
        { picture: "retro", scene: { x0: 100, y0: 150, x1: 230, y1: 150, yaw: -1, rampX: 1, rampY: 0 }, seconds: 10.5, stop: true }
    ]

    property int shot: -1
    property int shotEnd: 0
    property int frame: 0

    function startShot() {
        const s = shots[++shot]
        flight.picture = s.picture
        flight.stopAfterIntro = !!s.stop
        flight.scenes = [s.scene]
        flight.startScene(0)
        if (s.stop)
            flight.brakeAt = 4
        else
            flight.leaveAt = s.seconds - flight.sweepTime - 0.5
        shotEnd = frame + Math.round(s.seconds * fps)
    }

    function renderFrame() {
        if (frame >= shotEnd) {
            if (shot + 1 >= shots.length) {
                Qt.quit()
                return
            }
            startShot()
        }
        if (!flight.frozen)
            flight.step(1 / fps)
        flight.grabToImage(result => {
            result.saveToFile(frames + String(frame).padStart(5, "0") + ".jpg")
            ++frame
            Qt.callLater(renderFrame)
        }, videoSize)
    }

    PixelFlight {
        id: flight
        anchors.fill: parent
        running: false
        hue: 0.58
    }

    // Start once the first picture has loaded and set up its own scenes,
    // or it would overwrite the first shot.
    Timer {
        interval: 500
        running: true
        onTriggered: window.renderFrame()
    }
}
