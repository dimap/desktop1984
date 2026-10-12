.pragma library
.import "scene.js" as Scene

// Bundled bitmaps. A picture without its own scenes gets random camera moves;
// tile says the bitmap may repeat past its edges instead of ending there.
var custom = "custom"

var list = [
    { id: "retro", name: "Retro desktop", file: "world.png", tile: true, scenes: Scene.scenes },
    { id: "kde1", name: "KDE 1.0 (1998)", file: "kde1.png", scenes: [
        { x0: 62, y0: 30, x1: 62, y1: 300, yaw: -1, rampX: 0, rampY: 1 },
        { x0: 62, y0: 570, x1: 62, y1: 300, yaw: 1, rampX: 0, rampY: -1 },
        { x0: 50, y0: 738, x1: 420, y1: 738, yaw: 1, rampX: 1, rampY: 0 },
        { x0: 780, y0: 738, x1: 430, y1: 738, yaw: -1, rampX: -1, rampY: 0 }
    ] },
    { id: "kde2", name: "KDE 2.2 (2001)", file: "kde2.png", scenes: [
        { x0: 380, y0: 180, x1: 680, y1: 180, yaw: 1, rampX: 1, rampY: 0 },
        { x0: 90, y0: 420, x1: 90, y1: 700, yaw: -1, rampX: 0, rampY: 1 },
        { x0: 700, y0: 330, x1: 440, y1: 330, yaw: 1, rampX: -1, rampY: 0 },
        { x0: 60, y0: 740, x1: 340, y1: 740, yaw: -1, rampX: 1, rampY: 0 },
        { x0: 240, y0: 455, x1: 240, y1: 630, yaw: 1, rampX: 0, rampY: 1 }
    ] },
    { id: "kde3", name: "KDE 3.5 (2005)", file: "kde3.png", scenes: [
        { x0: 300, y0: 125, x1: 600, y1: 125, yaw: -1, rampX: 1, rampY: 0 },
        { x0: 140, y0: 200, x1: 140, y1: 480, yaw: 1, rampX: 0, rampY: 1 },
        { x0: 1000, y0: 110, x1: 720, y1: 110, yaw: 1, rampX: -1, rampY: 0 },
        { x0: 700, y0: 290, x1: 960, y1: 290, yaw: -1, rampX: 1, rampY: 0 },
        { x0: 600, y0: 660, x1: 860, y1: 660, yaw: 1, rampX: 1, rampY: 0 }
    ] }
]

function find(id) {
    for (let i = 0; i < list.length; ++i) {
        if (list[i].id === id)
            return list[i]
    }
    return list[0]
}

// Straight scrolls along a random row or column, kept away from the edges.
function randomScenes(width, height) {
    const scenes = []
    for (let i = 0; i < 12; ++i) {
        const horizontal = i % 2 === 0
        const span = horizontal ? width : height
        const across = horizontal ? height : width
        const length = Math.max(90, Math.min(240, span * 0.6) * (0.6 + 0.4 * Math.random()))
        const room = span * 0.7 - length
        const from = room > 0 ? span * 0.15 + Math.random() * room : (span - length) / 2
        const level = across * (0.15 + 0.7 * Math.random())
        const forward = Math.random() < 0.5
        const a = forward ? from : from + length
        const b = forward ? from + length : from
        const dir = forward ? 1 : -1
        scenes.push(horizontal
            ? { x0: a, y0: level, x1: b, y1: level, rampX: dir, rampY: 0 }
            : { x0: level, y0: a, x1: level, y1: b, rampX: 0, rampY: dir })
        scenes[i].yaw = Math.random() < 0.5 ? 1 : -1
    }
    return scenes
}
