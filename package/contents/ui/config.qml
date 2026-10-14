import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import org.kde.kirigami as Kirigami

import "palettes.js" as Palettes
import "pictures.js" as Pictures

Kirigami.FormLayout {
    id: page

    property var cfg_Pictures
    property var cfg_AddedImages
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
    property var cfg_PicturesDefault
    property var cfg_AddedImagesDefault
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

    readonly property var selection: Pictures.selection(cfg_Pictures ?? [], cfg_Picture, cfg_CustomImage)
    readonly property var added: Pictures.addedImages(cfg_AddedImages ?? [], cfg_CustomImage)
    readonly property bool isCustom: selection.some(p => !Pictures.byId(p))

    // Writes both lists in the current format, which retires the old single
    // picture. Something always stays chosen.
    function save(selection, added) {
        cfg_Pictures = selection.length > 0 ? selection : [Pictures.list[0].id]
        cfg_AddedImages = added
        cfg_Picture = cfg_PictureDefault
        cfg_CustomImage = ""
    }

    function choose(picture, chosen) {
        save(chosen ? selection.concat([picture]) : selection.filter(p => p !== picture), added)
    }

    // Whatever is added is chosen too.
    function add(urls) {
        const all = Array.from(urls, String)
        save(selection.concat(all.filter(url => !selection.includes(url))),
            added.concat(all.filter(url => !added.includes(url))))
    }

    function remove(url) {
        save(selection.filter(p => p !== url), added.filter(p => p !== url))
    }

    ColumnLayout {
        Kirigami.FormData.label: "Pictures:"
        Kirigami.FormData.labelAlignment: Qt.AlignTop
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20

        Repeater {
            model: Pictures.list.map(p => p.id).concat(page.added)

            delegate: RowLayout {
                id: row
                required property string modelData
                readonly property var bundled: Pictures.byId(modelData)
                readonly property bool isFolder: Pictures.isFolder(modelData)
                readonly property bool chosen: page.selection.includes(modelData)

                // Counts the pictures in a folder.
                Instantiator {
                    id: folder
                    model: row.isFolder ? [row.modelData] : []
                    delegate: FolderListModel {
                        required property string modelData
                        folder: modelData
                        nameFilters: Pictures.nameFilters
                        caseSensitive: false
                        showDirs: false
                    }
                }

                QQC2.CheckBox {
                    checked: row.chosen
                    // The last chosen picture cannot be unchosen.
                    enabled: !row.chosen || page.selection.length > 1
                    onToggled: {
                        page.choose(row.modelData, checked)
                        checked = Qt.binding(() => row.chosen)
                    }
                }
                Rectangle {
                    implicitWidth: Kirigami.Units.gridUnit * 3
                    implicitHeight: Kirigami.Units.gridUnit * 2
                    color: row.isFolder ? "transparent" : "white"
                    border.color: row.isFolder ? "transparent" : Kirigami.Theme.disabledTextColor
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        visible: !row.isFolder
                        source: row.bundled ? "../images/" + row.bundled.file : row.isFolder ? "" : row.modelData
                        sourceSize: Qt.size(width * 2, height * 2)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.medium
                        height: width
                        visible: row.isFolder
                        source: "folder"
                    }
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                    text: row.bundled ? row.bundled.name
                        : row.isFolder ? Pictures.fileName(row.modelData) + " (" + (folder.object?.count ?? 0) + ")"
                        : Pictures.fileName(row.modelData)
                    QQC2.ToolTip.text: row.bundled ? "" : decodeURIComponent(row.modelData.replace(/^file:\/\//, ""))
                    QQC2.ToolTip.visible: !row.bundled && hover.hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                    HoverHandler {
                        id: hover
                    }
                }
                QQC2.ToolButton {
                    visible: !row.bundled
                    icon.name: "list-remove"
                    QQC2.ToolTip.text: "Remove from the list"
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: page.remove(row.modelData)
                }
            }
        }

        RowLayout {
            QQC2.Button {
                text: "Add Files…"
                icon.name: "list-add"
                onClicked: fileDialog.open()
            }
            QQC2.Button {
                text: "Add Folder…"
                icon.name: "folder-new"
                onClicked: folderDialog.open()
            }
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
        title: "Add pictures"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Images (" + Pictures.nameFilters.join(" ") + ")", "All files (*)"]
        onAccepted: page.add(selectedFiles)
    }

    FolderDialog {
        id: folderDialog
        title: "Add a folder of pictures"
        onAccepted: page.add([selectedFolder.toString().replace(/\/?$/, "/")])
    }
}
