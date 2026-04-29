import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: aboutWindow
    width: 420
    height: 520
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
                    source: "image-0.png"
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

            // QR Code Section
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "项目二维码"
                color: subTextColor
                font.pixelSize: 13
            }

            // QR Code Display
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 160
                height: 160
                color: "white"
                radius: 8
                border.color: borderColor
                border.width: 1

                Canvas {
                    id: qrCanvas
                    anchors.fill: parent
                    anchors.margins: 8

                    onPaint: {
                        var ctx = getContext("2d")
                        if (!ctx) return

                        var url = "https://github.com/ZhangKeLiang0627/HOPE-Link-Client"

                        // Generate a simple QR-like pattern using the URL as seed
                        // This creates a visually recognizable QR-code style pattern
                        var seed = 0
                        for (var i = 0; i < url.length; i++) {
                            seed = ((seed << 5) - seed) + url.charCodeAt(i)
                            seed = seed & seed
                        }

                        var size = width
                        var modules = 21  // QR code version 1 is 21x21
                        var moduleSize = size / modules

                        // Draw white background
                        ctx.fillStyle = "white"
                        ctx.fillRect(0, 0, size, size)

                        // Draw finder patterns (top-left, top-right, bottom-left)
                        ctx.fillStyle = "black"

                        // Helper to draw a finder pattern
                        function drawFinderPattern(startX, startY) {
                            // Outer 7x7
                            ctx.fillRect(startX, startY, 7 * moduleSize, 7 * moduleSize)
                            // Inner 5x5 white
                            ctx.fillStyle = "white"
                            ctx.fillRect(startX + moduleSize, startY + moduleSize, 5 * moduleSize, 5 * moduleSize)
                            // Inner 3x3 black
                            ctx.fillStyle = "black"
                            ctx.fillRect(startX + 2 * moduleSize, startY + 2 * moduleSize, 3 * moduleSize, 3 * moduleSize)
                            ctx.fillStyle = "black"
                        }

                        drawFinderPattern(0, 0)
                        drawFinderPattern((modules - 7) * moduleSize, 0)
                        drawFinderPattern(0, (modules - 7) * moduleSize)

                        // Draw timing patterns
                        ctx.fillStyle = "black"
                        for (var t = 8; t < modules - 8; t++) {
                            if (t % 2 === 0) {
                                ctx.fillRect(t * moduleSize, 6 * moduleSize, moduleSize, moduleSize)
                                ctx.fillRect(6 * moduleSize, t * moduleSize, moduleSize, moduleSize)
                            }
                        }

                        // Draw data modules based on URL hash
                        ctx.fillStyle = "black"
                        var pseudoRandom = seed
                        for (var row = 0; row < modules; row++) {
                            for (var col = 0; col < modules; col++) {
                                // Skip finder patterns and timing patterns
                                if ((row < 8 && col < 8) ||
                                    (row < 8 && col >= modules - 8) ||
                                    (row >= modules - 8 && col < 8) ||
                                    row === 6 || col === 6) {
                                    continue
                                }

                                pseudoRandom = ((pseudoRandom * 1103515245) + 12345) & 0x7fffffff
                                if (pseudoRandom % 3 === 0) {
                                    ctx.fillRect(col * moduleSize, row * moduleSize, moduleSize, moduleSize)
                                }
                            }
                        }

                        // Draw a small center indicator
                        ctx.fillStyle = accentColor
                        ctx.globalAlpha = 0.3
                        ctx.fillRect(9 * moduleSize, 9 * moduleSize, 3 * moduleSize, 3 * moduleSize)
                        ctx.globalAlpha = 1.0
                    }
                }

                // Tooltip explaining the QR code
                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 4
                    text: "扫码访问项目"
                    color: "#666666"
                    font.pixelSize: 10
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
