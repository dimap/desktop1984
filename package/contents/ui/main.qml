import QtQuick
import org.kde.plasma.plasmoid

import "pictures.js" as Pictures

WallpaperItem {
    id: root

    PixelFlight {
        anchors.fill: parent
        pictures: Pictures.sources(Pictures.addedImages(root.configuration.AddedImages,
            root.configuration.CustomImage))
        excluded: Pictures.uncheckedPictures(root.configuration.UncheckedPictures,
            root.configuration.Picture, root.configuration.CustomImage)
        imageWidth: root.configuration.ImageWidth
        brightness: root.configuration.Brightness / 100
        contrast: root.configuration.Contrast / 100
        dither: root.configuration.Dither
        invert: root.configuration.Invert
        pixelSize: root.configuration.PixelSize
        speed: root.configuration.Speed / 100
        gap: root.configuration.Gap / 100
        tileOpacity: root.configuration.TileOpacity / 100
        shadowSoftness: root.configuration.ShadowSoftness / 100
        shadowStrength: root.configuration.ShadowStrength / 100
        appearSoftness: root.configuration.AppearSoftness / 100
        theme: root.configuration.Theme
        stopAfterIntro: root.configuration.StopAfterIntro
        replayMinutes: root.configuration.ReplayMinutes
    }
}
