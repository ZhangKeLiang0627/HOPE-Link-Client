import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: controlWindow
    width: 500
    height: 400
    title: "控制"
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

    // Light theme colors
    readonly property color lightBgColor: "#f5f5f5"
    readonly property color lightSurfaceColor: "#ffffff"
    readonly property color lightAccentColor: "#4a6cf7"
    readonly property color lightTextColor: "#1a1a2e"
    readonly property color lightSubTextColor: "#6b7280"
    readonly property color lightBorderColor: "#d1d5db"

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
            console.log("Control dialog: theme changed to:", themeManager.isDark ? "dark" : "light")
        }
    }

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
                text: "控制"
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
                        text: "🎮"
                        font.pixelSize: 48
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "控制功能开发中..."
                        color: subTextColor
                        font.pixelSize: 16
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "此页面将用于控制 OLED 显示内容"
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
                onClicked: controlWindow.close()
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
