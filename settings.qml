import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: settingsWindow
    width: 500
    height: 400
    title: "设置"
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
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Header
            Text {
                text: "设置"
                color: accentColor
                font.bold: true
                font.pixelSize: 20
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: borderColor
            }

            // Placeholder content
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "⚙️"
                        font.pixelSize: 48
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "设置功能开发中..."
                        color: subTextColor
                        font.pixelSize: 16
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "此页面将用于配置应用程序参数"
                        color: subTextColor
                        font.pixelSize: 12
                    }
                }
            }

            // Close button
            CustomButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 32
                text: "关闭"
                btnColor: accentColor
                onClicked: settingsWindow.close()
            }
        }
    }

    // Custom Button Component
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
