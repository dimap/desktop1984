import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Puts a setting back to its default. It only shows while the setting differs
// from the default, and keeps its place in the row either way.
QQC2.ToolButton {
    property bool changed

    text: "Reset to Default"
    icon.name: "edit-reset"
    display: QQC2.AbstractButton.IconOnly
    enabled: changed
    opacity: changed ? 1 : 0

    QQC2.ToolTip.text: text
    QQC2.ToolTip.visible: hovered
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
}
