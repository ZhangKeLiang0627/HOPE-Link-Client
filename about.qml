import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: aboutWindow
    width: 420
    height: 440


    title: "关于"

    modality: Qt.ApplicationModal
    flags: Qt.Dialog | Qt.WindowCloseButtonHint | Qt.WindowTitleHint

    // Color scheme (consistent with main.qml)
    readonly property color bgColor: "#1e1e2e"
    readonly property color surfaceColor: "#2a2a3e"
    readonly property color accentColor: "#89b4fa"
    readonly property color textColor: "#cdd6f4"
    readonly property color subTextColor: "#a6adc8"
    readonly property color borderColor: "#45475a"

    color: bgColor

    Rectangle {
        anchors.fill: parent
        color: bgColor

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            width: parent.width - 40

            // Author Avatar
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 100
                height: 100
                radius: 50
                color: surfaceColor
                border.color: accentColor
                border.width: 2
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 4
                    source: "avatar.png"

                    fillMode: Image.PreserveAspectCrop
                }
            }

            // Author Name
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Hugo@kkl"
                color: textColor
                font.bold: true
                font.pixelSize: 22
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: borderColor
            }

            // Project Link
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "项目链接"
                color: subTextColor
                font.pixelSize: 13
            }

            // Clickable Link
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: linkText.implicitWidth + 20
                Layout.preferredHeight: 30
                color: "#3a3a4e"
                radius: 4
                border.color: borderColor
                border.width: 1

                Text {
                    id: linkText
                    anchors.centerIn: parent
                    text: "ZhangKeLiang0627/HOPE-Link-Client"
                    color: accentColor
                    font.pixelSize: 12
                    font.underline: linkMouse.containsMouse
                }

                MouseArea {
                    id: linkMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Qt.openUrlExternally("https://github.com/ZhangKeLiang0627/HOPE-Link-Client")
                    }
                }
            }

            // Version info
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "HOPE-Link Client v1.0"
                color: subTextColor
                font.pixelSize: 11

            }

            // Close button
            CustomButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 32
                text: "关闭"
                btnColor: accentColor
                onClicked: aboutWindow.close()
            }
        }
    }

    // Custom Button Component (reused from main.qml)
    component CustomButton : Button {
        property color btnColor: accentColor
        property string tooltip: ""

        background: Rectangle {
            color: parent.enabled ? (parent.pressed ? Qt.darker(btnColor, 1.3) :
                                     parent.hovered ? Qt.lighter(btnColor, 1.1) : btnColor) : "#3a3a4e"
            radius: 4
            opacity: parent.enabled ? 1.0 : 0.5
        }
        contentItem: Text {
            text: parent.text
            color: parent.enabled ? "#1e1e2e" : subTextColor
            font.bold: true
            font.pixelSize: parent.font.pixelSize || 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        ToolTip {
            visible: parent.hovered && tooltip.length > 0
            text: tooltip
            delay: 500
            background: Rectangle {
                color: surfaceColor
                border.color: borderColor
                radius: 4
            }
            contentItem: Text {
                text: tooltip
                color: textColor
            }
        }
    }
}
