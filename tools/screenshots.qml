// Renders the still screenshots for the store page: make screenshots
//
// Each one is a scene played until it has come to rest, exactly as the
// wallpaper looks once it stops moving.
import QtQuick
import QtQuick.Window

import "../package/contents/ui"

Window {
    id: window
    width: 1280
    height: 720
    visible: true
    title: "xflyover screenshots"

    readonly property size imageSize: Qt.size(1920, 1080)

    // x, y is the point of the picture the view comes to rest on. A pixel
    // size smaller than the automatic one fits whole windows into the frame.
    readonly property var shots: [
        { name: "01-retro-desktop", picture: "retro", theme: 1, x: 160, y: 115, yaw: -1, pixelSize: 6 },
        { name: "02-retro-xeyes", picture: "retro", theme: 6, x: 175, y: 335, yaw: 1, pixelSize: 6 },
        { name: "03-kde-2.2", picture: "kde2", theme: 3, x: 460, y: 200, yaw: -1, pixelSize: 6 },
        { name: "04-kde-3.5", picture: "kde3", theme: 5, x: 720, y: 620, yaw: 1, pixelSize: 6 },
        { name: "05-kde-1.1", picture: "kde1", theme: 2, x: 700, y: 450, yaw: -1, pixelSize: 6 }
    ]

    property int shot: 0

    function render() {
        if (shot >= shots.length) {
            Qt.quit()
            return
        }
        const s = shots[shot]
        flight.pictures = [s.picture]
        flight.theme = s.theme
        flight.pixelSize = s.pixelSize
        // A scroll that brakes to a halt exactly on the wanted point.
        const length = 100
        const run = (0.4 * length / flight.scrollSpeed + flight.brakeTime / 2) * flight.scrollSpeed
        flight.scenes = [{ x0: s.x - run, y0: s.y, x1: s.x - run + length, y1: s.y, yaw: s.yaw, rampX: 1, rampY: 0 }]
        flight.startScene(0)
        while (!flight.frozen)
            flight.step(1 / 30)
        // On a scaled display the grab comes out larger than asked for; the
        // Makefile brings every file down to the final size afterwards.
        flight.grabToImage(result => {
            result.saveToFile("screenshots/" + s.name + ".png")
            ++shot
            Qt.callLater(render)
        }, imageSize)
    }

    PixelFlight {
        id: flight
        anchors.fill: parent
        running: false
    }

    // Start once the first picture has loaded and set up its own scenes.
    Timer {
        interval: 500
        running: true
        onTriggered: window.render()
    }
}
