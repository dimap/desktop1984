import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

import "palettes.js" as Palettes
import "pictures.js" as Pictures

Kirigami.FormLayout {
    id: page

    property string cfg_Picture
    property string cfg_CustomImage
    property alias cfg_ImageWidth: imageWidth.value
    property alias cfg_Brightness: brightness.value
    property alias cfg_Contrast: contrast.value
    property alias cfg_Dither: dither.checked
    property alias cfg_Invert: invert.checked
    property alias cfg_Theme: theme.currentIndex
    property alias cfg_StopAfterIntro: stopAfterIntro.checked
    property alias cfg_ReplayMinutes: replayMinutes.value
    property alias cfg_PixelSize: pixelSize.value
    property alias cfg_Speed: speed.value
    property alias cfg_Gap: gap.value
    property alias cfg_AppearSoftness: appearSoftness.value
    property alias cfg_TileOpacity: tileOpacity.value
    property alias cfg_ShadowSoftness: shadowSoftness.value
    property alias cfg_ShadowStrength: shadowStrength.value

    // Plasma also hands every config page the defaults.
    property string cfg_PictureDefault
    property string cfg_CustomImageDefault
    property int cfg_ImageWidthDefault
    property int cfg_BrightnessDefault
    property int cfg_ContrastDefault
    property bool cfg_DitherDefault
    property bool cfg_InvertDefault
    property int cfg_ThemeDefault
    property bool cfg_StopAfterIntroDefault
    property int cfg_ReplayMinutesDefault
    property int cfg_PixelSizeDefault
    property int cfg_SpeedDefault
    property int cfg_GapDefault
    property int cfg_AppearSoftnessDefault
    property int cfg_TileOpacityDefault
    property int cfg_ShadowSoftnessDefault
    property int cfg_ShadowStrengthDefault

    readonly property bool isCustom: cfg_Picture === Pictures.custom

    QQC2.ComboBox {
        id: picture
        Kirigami.FormData.label: "Picture:"
        textRole: "name"
        valueRole: "id"
        model: Pictures.list.map(p => ({ id: p.id, name: p.name }))
            .concat([{ id: Pictures.custom, name: "Custom file…" }])
        Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_Picture))
        onActivated: page.cfg_Picture = currentValue
    }

    RowLayout {
        Kirigami.FormData.label: "File:"
        visible: page.isCustom

        QQC2.Button {
            text: "Choose…"
            icon.name: "document-open"
            onClicked: fileDialog.open()
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 14
            elide: Text.ElideMiddle
            text: page.cfg_CustomImage
                ? decodeURIComponent(page.cfg_CustomImage.split("/").pop())
                : "none chosen"
        }
    }

    QQC2.SpinBox {
        id: imageWidth
        Kirigami.FormData.label: "Width in pixels:"
        visible: page.isCustom
        from: 32
        to: 2048
        stepSize: 16
    }

    QQC2.Slider {
        id: brightness
        Kirigami.FormData.label: "Brightness:"
        visible: page.isCustom
        from: -100
        to: 100
        stepSize: 5
    }

    QQC2.Slider {
        id: contrast
        Kirigami.FormData.label: "Contrast:"
        visible: page.isCustom
        from: 100
        to: 400
        stepSize: 10
    }

    QQC2.CheckBox {
        id: dither
        visible: page.isCustom
        text: "Dither mid-tones"
    }

    QQC2.CheckBox {
        id: invert
        text: "Swap black and white"
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.ComboBox {
        id: theme
        Kirigami.FormData.label: "Color:"
        model: ["Spectrum"].concat(Palettes.list.map(p => p.name))
    }

    QQC2.CheckBox {
        id: stopAfterIntro
        Kirigami.FormData.label: "Animation:"
        text: "Come to rest after appearing"
    }

    QQC2.SpinBox {
        id: replayMinutes
        Kirigami.FormData.label: "Replay every:"
        enabled: stopAfterIntro.checked
        from: 0
        to: 720
        textFromValue: value => value === 0 ? "never" : value + " min"
        valueFromText: text => parseInt(text) || 0
    }

    RowLayout {
        Kirigami.FormData.label: "Appearing:"

        QQC2.Label {
            text: "as a wave"
        }
        QQC2.Slider {
            id: appearSoftness
            from: 0
            to: 100
            stepSize: 1
        }
        QQC2.Label {
            text: "all at once"
        }
    }

    QQC2.SpinBox {
        id: pixelSize
        Kirigami.FormData.label: "Pixel size:"
        from: 0
        to: 96
        textFromValue: value => value === 0 ? "auto" : value + " px"
        valueFromText: text => parseInt(text) || 0
    }

    QQC2.Slider {
        id: speed
        Kirigami.FormData.label: "Speed:"
        from: 10
        to: 300
        stepSize: 10
    }

    QQC2.Slider {
        id: gap
        Kirigami.FormData.label: "Gap between pixels:"
        from: 0
        to: 30
        stepSize: 1
    }

    RowLayout {
        Kirigami.FormData.label: "Pixel opacity:"

        QQC2.Slider {
            id: tileOpacity
            from: 0
            to: 100
            stepSize: 1
        }
        QQC2.Label {
            text: tileOpacity.value + "%"
        }
    }

    RowLayout {
        Kirigami.FormData.label: "Shadow softness:"

        QQC2.Slider {
            id: shadowSoftness
            from: 0
            to: 100
            stepSize: 1
        }
        QQC2.Label {
            text: shadowSoftness.value + "%"
        }
    }

    RowLayout {
        Kirigami.FormData.label: "Shadow strength:"

        QQC2.Slider {
            id: shadowStrength
            from: 0
            to: 60
            stepSize: 1
        }
        QQC2.Label {
            text: shadowStrength.value + "%"
        }
    }

    FileDialog {
        id: fileDialog
        title: "Choose a picture"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp *.gif *.svg)", "All files (*)"]
        onAccepted: page.cfg_CustomImage = selectedFile
    }
}
