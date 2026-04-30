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

    // ========== Theme System ==========
    // Dark theme colors (consistent with main.qml)
    readonly property color darkBgColor: "#1e1e2e"
    readonly property color darkSurfaceColor: "#2a2a3e"
    readonly property color darkAccentColor: "#89b4fa"
    readonly property color darkTextColor: "#cdd6f4"
    readonly property color darkSubTextColor: "#a6adc8"
    readonly property color darkBorderColor: "#45475a"

    // Light theme colors (米白色系)
    readonly property color lightBgColor: "#f5f0eb"
    readonly property color lightSurfaceColor: "#faf7f2"
    readonly property color lightAccentColor: "#4f6ef7"
    readonly property color lightTextColor: "#2c2c2c"
    readonly property color lightSubTextColor: "#78716c"
    readonly property color lightBorderColor: "#d6d0c8"

    // Current theme colors (reactive to themeManager.isDark)
    property color bgColor: themeManager && themeManager.isDark ? darkBgColor : lightBgColor
    property color surfaceColor: themeManager && themeManager.isDark ? darkSurfaceColor : lightSurfaceColor
    property color accentColor: themeManager && themeManager.isDark ? darkAccentColor : lightAccentColor
    property color textColor: themeManager && themeManager.isDark ? darkTextColor : lightTextColor
    property color subTextColor: themeManager && themeManager.isDark ? darkSubTextColor : lightSubTextColor
    property color borderColor: themeManager && themeManager.isDark ? darkBorderColor : lightBorderColor

    // Update colors when theme changes
    Connections {
        target: themeManager
        function onThemeChanged() {
            console.log("About dialog: theme changed to:", themeManager.isDark ? "dark" : "light")
        }
    }

    color: bgColor

    Rectangle {
        anchors.fill: parent
        color: bgColor

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            width: parent.width - 40

            // Author Avatar
            Image {
                Layout.alignment: Qt.AlignHCenter
                source: "avatar.png"
                sourceSize.width: 100
                sourceSize.height: 100
                fillMode: Image.PreserveAspectCrop
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
