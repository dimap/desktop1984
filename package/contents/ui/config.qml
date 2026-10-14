import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

import "palettes.js" as Palettes
import "pictures.js" as Pictures

// The settings, and under them the pictures to show laid out like the
// slideshow wallpaper's: added folders on the left, every picture as a
// thumbnail to tick on the right.
ColumnLayout {
    id: page

    property var cfg_AddedImages
    property var cfg_UncheckedPictures
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
    property var cfg_AddedImagesDefault
    property var cfg_UncheckedPicturesDefault
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

    readonly property var added: Pictures.addedImages(cfg_AddedImages ?? [], cfg_CustomImage)
    readonly property var unchecked: Pictures.uncheckedPictures(cfg_UncheckedPictures ?? [], cfg_Picture, cfg_CustomImage)
    readonly property var addedFolders: added.filter(Pictures.isFolder)
    readonly property bool isCustom: added.length > 0

    // Every picture that can be ticked: the bundled ones, the added files and
    // the images in the added folders.
    property var thumbnails: []

    function updateThumbnails() {
        const all = Pictures.list.map(p => ({ id: p.id, name: p.name, subtitle: "Bundled",
                                             source: Qt.resolvedUrl("../images/" + p.file), removable: false }))
        const seen = new Set(all.map(p => p.id))
        const push = (url, removable) => {
            if (seen.has(url))
                return
            seen.add(url)
            all.push({ id: url, name: Pictures.fileName(url), subtitle: Pictures.fileName(url.replace(/[^/]*$/, "")),
                       source: url, removable: removable })
        }
        added.filter(p => !Pictures.isFolder(p)).forEach(url => push(url, true))
        for (let i = 0; i < folderModels.count; ++i) {
            const folder = folderModels.objectAt(i)
            for (let j = 0; folder && j < folder.count; ++j)
                push(folder.get(j, "fileUrl").toString(), false)
        }
        thumbnails = all
    }

    // Writes the lists in the current format, which retires the old single
    // picture.
    function save(added, unchecked) {
        cfg_AddedImages = added
        cfg_UncheckedPictures = unchecked
        cfg_Picture = cfg_PictureDefault
        cfg_CustomImage = ""
    }

    function check(picture, checked) {
        save(added, checked ? unchecked.filter(p => p !== picture) : unchecked.concat([picture]))
    }

    function checkAll(checked) {
        save(added, checked ? [] : thumbnails.map(p => p.id))
    }

    // Whatever is added is ticked.
    function add(urls) {
        const all = Array.from(urls, String)
        save(added.concat(all.filter(url => !added.includes(url))), unchecked.filter(p => !all.includes(p)))
    }

    function remove(url) {
        save(added.filter(p => p !== url), unchecked.filter(p => p !== url))
    }

    onAddedChanged: Qt.callLater(updateThumbnails)
    Component.onCompleted: updateThumbnails()

    Instantiator {
        id: folderModels
        model: page.addedFolders
        delegate: FolderListModel {
            required property string modelData
            folder: modelData
            nameFilters: Pictures.nameFilters
            caseSensitive: false
            showDirs: false
            sortField: FolderListModel.Name
            onCountChanged: Qt.callLater(page.updateThumbnails)
        }
        onObjectRemoved: Qt.callLater(page.updateThumbnails)
    }

    spacing: 0

    Kirigami.FormLayout {
        id: form
        Layout.bottomMargin: Kirigami.Units.largeSpacing

        // Lines the labels up with the "Wallpaper type" row above.
        Component.onCompleted: {
            if (typeof appearanceRoot !== "undefined")
                twinFormLayouts.push(appearanceRoot.parentLayout)
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
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Kirigami.Units.gridUnit * 20
        spacing: 0

        ColumnLayout {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 14
            Layout.preferredWidth: Kirigami.Units.gridUnit * 14
            spacing: 0

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                background: Rectangle {
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                    color: Kirigami.Theme.backgroundColor
                }

                ListView {
                    id: foldersView
                    headerPositioning: ListView.OverlayHeader
                    header: Kirigami.InlineViewHeader {
                        width: foldersView.width
                        text: "Folders"
                        actions: [
                            Kirigami.Action {
                                icon.name: "list-add-symbolic"
                                text: "Add…"
                                Accessible.name: "Add Folder…"
                                onTriggered: folderDialog.open()
                            }
                        ]
                    }
                    model: page.addedFolders
                    delegate: Kirigami.SubtitleDelegate {
                        id: folderItem
                        required property string modelData

                        width: foldersView.width
                        hoverEnabled: false
                        down: false
                        text: Pictures.fileName(modelData)
                        subtitle: decodeURIComponent(modelData.replace(/^file:\/\//, "").replace(/[^/]*\/$/, ""))

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.TitleSubtitle {
                                Layout.fillWidth: true
                                title: folderItem.text
                                subtitle: folderItem.subtitle
                            }
                            QQC2.ToolButton {
                                icon.name: "edit-delete-remove-symbolic"
                                text: "Remove Folder"
                                display: QQC2.Button.IconOnly
                                onClicked: page.remove(folderItem.modelData)
                                QQC2.ToolTip.visible: hovered
                                QQC2.ToolTip.text: text
                                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                            }
                            QQC2.ToolButton {
                                icon.name: "document-open-folder"
                                text: "Open Folder"
                                display: QQC2.Button.IconOnly
                                onClicked: Qt.openUrlExternally(folderItem.modelData)
                                QQC2.ToolTip.visible: hovered
                                QQC2.ToolTip.text: text
                                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                            }
                        }
                    }

                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - Kirigami.Units.largeSpacing * 4
                        visible: foldersView.count === 0
                        text: "No folders added"
                    }
                }
            }
        }

        Kirigami.Separator {
            Layout.fillHeight: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            Kirigami.InlineViewHeader {
                Layout.fillWidth: true
                text: "Pictures"
                actions: [
                    Kirigami.Action {
                        icon.name: "list-add-symbolic"
                        text: "Add…"
                        Accessible.name: "Add Pictures…"
                        onTriggered: fileDialog.open()
                    },
                    Kirigami.Action {
                        icon.name: "edit-select-all-symbolic"
                        text: "Select All"
                        displayHint: Kirigami.DisplayHint.KeepVisible
                        onTriggered: page.checkAll(true)
                    },
                    Kirigami.Action {
                        icon.name: "edit-select-none-symbolic"
                        text: "Select None"
                        displayHint: Kirigami.DisplayHint.KeepVisible
                        onTriggered: page.checkAll(false)
                    }
                ]
            }

            Kirigami.InlineMessage {
                Layout.fillWidth: true
                visible: page.thumbnails.every(p => page.unchecked.includes(p.id))
                text: "No picture is ticked, so the first bundled one is shown."
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                color: Kirigami.Theme.backgroundColor

                KCM.GridView {
                    id: grid
                    anchors.fill: parent
                    framedView: false

                    view.model: page.thumbnails
                    // Ticks say what is chosen; a highlighted cell would look chosen too.
                    view.currentIndex: -1
                    view.implicitCellWidth: Kirigami.Units.gridUnit * 8 + Kirigami.Units.smallSpacing * 2
                    view.implicitCellHeight: Kirigami.Units.gridUnit * 6 + Kirigami.Units.smallSpacing * 2
                        + Kirigami.Units.gridUnit * 3

                    view.delegate: KCM.GridDelegate {
                        id: cell
                        required property var modelData
                        readonly property bool ticked: !page.unchecked.includes(modelData.id)

                        text: modelData.name
                        subtitle: modelData.subtitle
                        hoverEnabled: true
                        onClicked: page.check(modelData.id, !ticked)

                        actions: [
                            Kirigami.Action {
                                icon.name: "edit-delete-remove"
                                tooltip: "Remove"
                                visible: cell.modelData.removable
                                onTriggered: page.remove(cell.modelData.id)
                            }
                        ]

                        // The bundled pictures are black on white.
                        thumbnail: Rectangle {
                            anchors.fill: parent
                            color: "white"

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: Kirigami.Units.iconSizes.large
                                height: width
                                source: "view-preview"
                                visible: preview.status !== Image.Ready
                            }
                            Image {
                                id: preview
                                anchors.fill: parent
                                asynchronous: true
                                cache: false
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(Kirigami.Units.gridUnit * 16, Kirigami.Units.gridUnit * 12)
                                source: cell.modelData.source
                            }
                            QQC2.CheckBox {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: Kirigami.Units.smallSpacing
                                checked: cell.ticked
                                onToggled: {
                                    page.check(cell.modelData.id, checked)
                                    checked = Qt.binding(() => cell.ticked)
                                }
                            }
                        }
                    }
                }

            }
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
