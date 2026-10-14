.pragma library
.import "scene.js" as Scene

// Bundled bitmaps. A picture without its own scenes gets random camera moves;
// tile says the bitmap may repeat past its edges instead of ending there.
//
// A picture is named by the id of a bundled one, by the URL of an image file,
// or by the URL of a folder, which always ends in "/" and stands for every
// image in it.
var custom = "custom"   // the only custom picture in settings before 1.3

var nameFilters = ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif", "*.svg"]

var list = [
    { id: "retro", name: "Retro desktop", file: "world.png", tile: true, scenes: Scene.scenes },
    { id: "kde1", name: "KDE 1.1 (1999)", file: "kde1.png", scenes: [
        { x0: 150, y0: 215, x1: 450, y1: 215, yaw: -1, rampX: 1, rampY: 0 },
        { x0: 620, y0: 420, x1: 920, y1: 420, yaw: 1, rampX: 1, rampY: 0 },
        { x0: 150, y0: 620, x1: 150, y1: 900, yaw: -1, rampX: 0, rampY: 1 },
        { x0: 380, y0: 560, x1: 380, y1: 790, yaw: 1, rampX: 0, rampY: 1 },
        { x0: 1225, y0: 200, x1: 1225, y1: 480, yaw: -1, rampX: 0, rampY: 1 },
        { x0: 60, y0: 935, x1: 360, y1: 935, yaw: 1, rampX: 1, rampY: 0 },
        { x0: 35, y0: 60, x1: 35, y1: 340, yaw: 1, rampX: 0, rampY: 1 },
        { x0: 500, y0: 12, x1: 200, y1: 12, yaw: -1, rampX: -1, rampY: 0 }
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

function byId(id) {
    for (let i = 0; i < list.length; ++i) {
        if (list[i].id === id)
            return list[i]
    }
    return null
}

function find(id) {
    return byId(id) ?? list[0]
}

function isFolder(picture) {
    return picture.endsWith("/")
}

// The name of a file or folder from its URL.
function fileName(url) {
    return decodeURIComponent(url.replace(/\/$/, "").split("/").pop())
}

// The pictures to choose from. Settings before 1.3 held a single picture, and
// they still say what to show until the list has been saved once.
function selection(pictures, legacyPicture, legacyImage) {
    if (pictures.length > 0)
        return Array.from(pictures)
    if (legacyPicture === custom && legacyImage)
        return [legacyImage]
    return [find(legacyPicture).id]
}

// Files and folders added in the settings, chosen or not.
function addedImages(images, legacyImage) {
    if (images.length > 0)
        return Array.from(images)
    return legacyImage ? [legacyImage] : []
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
