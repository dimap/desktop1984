// Standalone preview: qml-qt6 preview.qml
import QtQuick
import QtQuick.Window

import "package/contents/ui"

Window {
    width: 1280
    height: 720
    visible: true
    title: "xflyover"

    PixelFlight {
        anchors.fill: parent
        stopAfterIntro: false
    }
}
