import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    width: 800
    height: 600
    minimumWidth: 800
    minimumHeight: 500
    title: "HOPE-Link Client"
    visible: true

    // Color scheme
    readonly property color bgColor: "#1e1e2e"
    readonly property color surfaceColor: "#2a2a3e"
    readonly property color accentColor: "#89b4fa"
    readonly property color textColor: "#cdd6f4"
    readonly property color subTextColor: "#a6adc8"
    readonly property color errorColor: "#f38ba8"
    readonly property color successColor: "#a6e3a1"
    readonly property color borderColor: "#45475a"

    // OLED 参数
    readonly property int oledWidth: 128
    readonly property int oledHeight: 64
    readonly property int oledPages: 8

    // OLED 像素数据 (1024 bytes, 阴码 列行式 逆向输出)
    property var oledBuffer: []

    // 像素颜色（默认亮绿色，模拟 OLED）
    property color pixelColor: "#a6e3a1"
    property color pixelOffColor: "#000000"
    property color bgColorCustom: "#000000"

    // 缩放比例
    readonly property int pixelScale: 4
    readonly property int displayWidth: oledWidth * pixelScale
    readonly property int displayHeight: oledHeight * pixelScale

    // 全屏模式
    property bool fullScreenMode: false

    // 帧计数
    property int frameCount: 0

    // ========== Top Toolbar ==========
    Rectangle {
        id: toolbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: fullScreenMode ? 0 : 50
        clip: true
        color: surfaceColor

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // Port selector
            ComboBox {
                id: portCombo
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                model: serialBridge.ports
                currentIndex: -1
                displayText: currentIndex >= 0 ? currentText : "选择串口..."
                background: Rectangle {
                    color: parent.enabled ? "#3a3a4e" : "#2a2a3e"
                    radius: 4
                    border.color: borderColor
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.displayText
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                    elide: Text.ElideRight
                }
                indicator: Rectangle {
                    x: parent.width - width
                    width: 40
                    height: parent.height
                    color: portIndicatorMouseArea.containsMouse ? "#4a4a5e" : "transparent"
                    radius: 4

                    Canvas {
                        anchors.centerIn: parent
                        width: 10
                        height: 6
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.fillStyle = subTextColor
                            ctx.beginPath()
                            ctx.moveTo(0, 0)
                            ctx.lineTo(width, 0)
                            ctx.lineTo(width / 2, height)
                            ctx.closePath()
                            ctx.fill()
                        }
                    }

                    MouseArea {
                        id: portIndicatorMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            portCombo.popup.open()
                        }
                    }
                }
                popup: Popup {
                    y: parent.height
                    width: parent.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 1
                    background: Rectangle {
                        color: surfaceColor
                        border.color: borderColor
                        radius: 4
                    }
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: portCombo.model
                        delegate: ItemDelegate {
                            width: parent.width
                            height: 32
                            contentItem: Text {
                                text: modelData
                                color: textColor
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            background: Rectangle {
                                color: hovered ? "#3a3a4e" : "transparent"
                            }
                            onClicked: {
                                portCombo.currentIndex = index
                                portCombo.popup.close()
                            }
                        }
                    }
                }
            }

            // Baud rate selector (可编辑，支持下拉选择和手动输入)
            ComboBox {
                id: baudCombo
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                model: serialBridge.baudRates
                currentIndex: 4  // 115200
                editable: true
                validator: IntValidator {
                    bottom: 1
                    top: 9999999
                }
                // 自定义 contentItem: TextInput 用于编辑
                // 注意：必须设置 rightPadding 让出指示器区域，否则 Windows 上 TextInput
                // 会覆盖指示器导致三角符号无法点击（光标变为 I-beam）
                contentItem: TextInput {
                    text: baudCombo.displayText
                    font: baudCombo.font
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                    rightPadding: 44  // 让出指示器区域（40px + 4px 间距）
                    // 当用户输入完成时，接受自定义值
                    onAccepted: {
                        baudCombo.currentIndex = -1  // 标记为自定义值
                        baudCombo.editText = text
                    }
                }
                background: Rectangle {
                    color: "#3a3a4e"
                    radius: 4
                    border.color: borderColor
                    border.width: 1
                }
                // 指示器：使用较大的可点击区域，确保三角符号位置也能点击下拉
                // 设置 z 值高于 contentItem，确保 Windows 上也能正确捕获鼠标事件
                indicator: Rectangle {
                    x: parent.width - width
                    width: 40
                    height: parent.height
                    z: 2
                    color: indicatorMouseArea.containsMouse ? "#4a4a5e" : "transparent"
                    radius: 4

                    Canvas {
                        anchors.centerIn: parent
                        width: 10
                        height: 6
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.fillStyle = subTextColor
                            ctx.beginPath()
                            ctx.moveTo(0, 0)
                            ctx.lineTo(width, 0)
                            ctx.lineTo(width / 2, height)
                            ctx.closePath()
                            ctx.fill()
                        }
                    }

                    // 使用 MouseArea 覆盖整个指示器区域，确保三角符号位置也能点击
                    MouseArea {
                        id: indicatorMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            baudCombo.popup.open()
                        }
                    }
                }
                popup: Popup {
                    y: parent.height
                    width: parent.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 1
                    background: Rectangle {
                        color: surfaceColor
                        border.color: borderColor
                        radius: 4
                    }
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: baudCombo.model
                        delegate: ItemDelegate {
                            width: parent.width
                            height: 32
                            contentItem: Text {
                                text: modelData
                                color: textColor
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                            background: Rectangle {
                                color: hovered ? "#3a3a4e" : "transparent"
                            }
                            onClicked: {
                                baudCombo.currentIndex = index
                                baudCombo.editText = modelData
                                baudCombo.popup.close()
                            }
                        }
                    }
                }
            }

            // Refresh button
            CustomButton {
                id: refreshBtn
                Layout.fillHeight: true
                Layout.preferredWidth: 36
                text: "↻"
                tooltip: "刷新串口列表"
                onClicked: serialBridge.refresh_ports()
            }

            // Settings button
            CustomButton {
                id: settingsBtn
                Layout.fillHeight: true
                Layout.preferredWidth: 50
                text: "设置"
                font.pixelSize: 11
                tooltip: "打开设置"
                btnColor: subTextColor
                onClicked: settingsDialog.show()
            }

            // About button
            CustomButton {
                id: aboutBtn
                Layout.fillHeight: true
                Layout.preferredWidth: 50
                text: "关于"
                font.pixelSize: 11
                tooltip: "关于 HOPE-Link Client"
                btnColor: subTextColor
                onClicked: aboutDialog.show()
            }

            // Control button
            CustomButton {
                id: controlBtn
                Layout.fillHeight: true
                Layout.preferredWidth: 50
                text: "控制"
                font.pixelSize: 11
                tooltip: "打开控制面板"
                btnColor: subTextColor
                onClicked: controlDialog.show()
            }

            Item { Layout.fillWidth: true }

            // Connect / Disconnect button
            CustomButton {
                id: connectBtn
                Layout.fillHeight: true
                Layout.preferredWidth: 100
                text: serialBridge.connected ? "断开连接" : "打开串口"
                btnColor: serialBridge.connected ? errorColor : successColor
                enabled: serialBridge.connected || portCombo.count > 0
                onClicked: {
                    if (serialBridge.connected) {
                        serialBridge.disconnect_port()
                    } else {
                        if (portCombo.currentIndex < 0) {
                            return
                        }
                        // 使用 editText 获取输入框内容（支持自定义输入）
                        var baudRate = baudCombo.editText.trim()
                        if (baudRate === "") {
                            baudRate = baudCombo.currentText
                        }
                        serialBridge.connect_port(portCombo.currentText, baudRate)
                    }
                }
            }
        }
    }

    // ========== Main Content Area ==========
    RowLayout {
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: statusBar.top
        anchors.margins: fullScreenMode ? 0 : 8
        spacing: fullScreenMode ? 0 : 8

        // ====== OLED Display Area ======
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: surfaceColor
            radius: fullScreenMode ? 0 : 6
            border.color: fullScreenMode ? "transparent" : borderColor
            border.width: fullScreenMode ? 0 : 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: fullScreenMode ? 0 : 8
                spacing: fullScreenMode ? 0 : 8

                // Header (全屏时隐藏)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: fullScreenMode ? 0 : implicitHeight
                    clip: true
                    visible: !fullScreenMode
                    Text {
                        text: "OLED Screen Display"
                        color: accentColor
                        font.bold: true
                        font.pixelSize: 15
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: serialBridge.connected ? "● 已连接" : "○ 未连接"
                        color: serialBridge.connected ? successColor : errorColor
                        font.pixelSize: 12
                    }
                }

                    // OLED Screen
                    Rectangle {
                        id: oledScreen
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: fullScreenMode ? 0 : 8
                        color: bgColorCustom
                        radius: fullScreenMode ? 0 : 8
                        border.color: fullScreenMode ? "transparent" : borderColor
                        border.width: fullScreenMode ? 0 : 2

                    // OLED 像素画布
                    Canvas {
                        id: oledCanvas
                        anchors.centerIn: parent

                        // 全屏时自适应缩放
                        readonly property real scaleFactor: fullScreenMode ?
                            Math.min(parent.width / displayWidth, parent.height / displayHeight) : 1.0

                        width: displayWidth * scaleFactor
                        height: displayHeight * scaleFactor

                        onPaint: {
                            var ctx = getContext("2d")
                            if (!ctx) return

                            // 清空画布
                            ctx.fillStyle = pixelOffColor
                            ctx.fillRect(0, 0, width, height)

                            // 如果没有数据，显示占位文字
                            if (oledBuffer.length !== 1024) {
                                // 提示文字
                                ctx.fillStyle = "#88ffffff"
                                ctx.font = "bold " + (18 * scaleFactor) + "px monospace"
                                ctx.textAlign = "center"
                                ctx.textBaseline = "middle"
                                ctx.fillText("等待数据...", width / 2, height / 2)

                                // 小字提示
                                ctx.fillStyle = "#55ffffff"
                                ctx.font = (12 * scaleFactor) + "px monospace"
                                ctx.fillText("请确保 MCU 已发送 OLED 帧数据", width / 2, height / 2 + 22 * scaleFactor)
                                return
                            }

                            // 绘制像素
                            ctx.fillStyle = pixelColor
                            var sf = scaleFactor

                            for (var page = 0; page < 8; page++) {
                                for (var col = 0; col < 128; col++) {
                                    var byteVal = oledBuffer[page * 128 + col]
                                    if (byteVal === undefined) continue

                                    // 逆向输出：bit0 对应 page 内最上面的像素
                                    for (var bit = 0; bit < 8; bit++) {
                                        if (byteVal & (1 << bit)) {
                                            var px = col * pixelScale * sf
                                            var py = (page * 8 + bit) * pixelScale * sf
                                            ctx.fillRect(px, py, pixelScale * sf, pixelScale * sf)
                                        }
                                    }
                                }
                            }
                        }

                        // 收到新数据时重绘
                        Connections {
                            target: serialBridge
                            function onOledFrameReady(data) {
                                oledBuffer = data
                                frameCount++
                                oledCanvas.requestPaint()
                            }
                        }
                    }

                    // 全屏模式下的悬浮还原按钮（默认在右上角，鼠标悬浮才显示）
                    Rectangle {
                        id: exitFullBtn
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        implicitWidth: exitFullBtnText.implicitWidth + 16
                        implicitHeight: 28
                        radius: 4
                        color: exitFullBtnMouse.containsMouse ? "#9b8724d7" : "#00000000"
                        visible: fullScreenMode

                        Text {
                            id: exitFullBtnText
                            anchors.centerIn: parent
                            text: "还原"
                            color: exitFullBtnMouse.containsMouse ? textColor : "transparent"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: exitFullBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: fullScreenMode = false
                        }
                    }

                    // 非全屏模式下的全屏按钮
                    CustomButton {
                        id: fullScreenBtn
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 6
                        implicitWidth: 50
                        height: 24
                        text: "全屏"
                        font.pixelSize: 11
                        tooltip: "全屏显示"
                        visible: !fullScreenMode
                        btnColor: accentColor
                        onClicked: fullScreenMode = true
                    }
                }

                // 状态信息（全屏时隐藏）
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: fullScreenMode ? 0 : implicitHeight
                    clip: true
                    visible: !fullScreenMode
                    spacing: 12

                    Text {
                        text: "分辨率: 128×64"
                        color: subTextColor
                        font.pixelSize: 11
                    }

                    Text {
                        text: "像素: " + (oledBuffer.length > 0 ? oledBuffer.length + " bytes" : "无数据")
                        color: subTextColor
                        font.pixelSize: 11
                    }

                    Item { Layout.fillWidth: true }

                    CustomButton {
                        text: "清空显示"
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 80
                        font.pixelSize: 11
                        onClicked: {
                            oledBuffer = []
                            oledCanvas.requestPaint()
                            serialBridge.clear_buffer()
                        }
                    }
                }
            }
        }

        // ====== 右侧信息面板（全屏时隐藏）=====
        Rectangle {
            Layout.preferredWidth: fullScreenMode ? 0 : 220
            Layout.fillHeight: true
            clip: true
            visible: !fullScreenMode
            color: surfaceColor
            radius: 6
            border.color: borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                // Header
                Text {
                    text: "协议信息"
                    color: accentColor
                    font.bold: true
                    font.pixelSize: 14
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#1a1a2e"
                    radius: 4
                    border.color: borderColor
                    border.width: 1

                    Flickable {
                        id: infoFlick
                        anchors.fill: parent
                        anchors.margins: 6
                        contentWidth: infoContent.width
                        contentHeight: infoContent.height
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            background: Rectangle { color: "transparent" }
                            contentItem: Rectangle {
                                color: borderColor
                                radius: 2
                            }
                        }

                        ColumnLayout {
                            id: infoContent
                            width: parent.width
                            spacing: 4

                            // 协议说明标题
                            Text {
                                text: "协议说明"
                                color: accentColor
                                font.bold: true
                                font.pixelSize: 13
                            }

                            // 包头/数据/包尾 横向排列
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                // 包头行 (动态显示)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text { text: "包头"; color: subTextColor; font.pixelSize: 11; font.bold: true }
                                    Text { text: ":"; color: subTextColor; font.pixelSize: 11 }
                                    Text {
                                        text: {
                                            var h = serialBridge.pkgHeader
                                            if (h.length === 4) {
                                                return "0x" + h.substring(0, 2) + " 0x" + h.substring(2, 4)
                                            }
                                            return "0xA5 0xA5"
                                        }
                                        color: "#a6e3a1"
                                        font.pixelSize: 11
                                        font.family: "monospace"
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                // 数据行
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text { text: "数据"; color: subTextColor; font.pixelSize: 11; font.bold: true }
                                    Text { text: ":"; color: subTextColor; font.pixelSize: 11 }
                                    Text { text: "1024 bytes (8×128)"; color: textColor; font.pixelSize: 11 }
                                    Item { Layout.fillWidth: true }
                                }

                                // 包尾行 (动态显示)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text { text: "包尾"; color: subTextColor; font.pixelSize: 11; font.bold: true }
                                    Text { text: ":"; color: subTextColor; font.pixelSize: 11 }
                                    Text {
                                        text: {
                                            var f = serialBridge.pkgFooter
                                            if (f.length === 4) {
                                                return "0x" + f.substring(0, 2) + " 0x" + f.substring(2, 4)
                                            }
                                            return "0x5A 0x5A"
                                        }
                                        color: "#f38ba8"
                                        font.pixelSize: 11
                                        font.family: "monospace"
                                    }
                                    Item { Layout.fillWidth: true }
                                }
                            }

                            Item { Layout.preferredHeight: 4 }

                            // ====== 自定义包头包尾 ======
                            Text {
                                text: "自定义协议"
                                color: accentColor
                                font.bold: true
                                font.pixelSize: 12
                            }

                            // 包头输入
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: "包头"
                                    color: subTextColor
                                    font.pixelSize: 11
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                TextField {
                                    id: headerInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    text: serialBridge.pkgHeader
                                    color: textColor
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    placeholderText: "A5A5"
                                    placeholderTextColor: subTextColor
                                    maximumLength: 4
                                    background: Rectangle {
                                        color: "#3a3a4e"
                                        radius: 3
                                        border.color: borderColor
                                        border.width: 1
                                    }
                                    validator: RegularExpressionValidator {
                                        regularExpression: /[0-9a-fA-F]{0,4}/
                                    }
                                    onEditingFinished: {
                                        var val = text.trim().toUpperCase()
                                        if (val.length === 4) {
                                            serialBridge.pkgHeader = val
                                        }
                                    }
                                }

                                CustomButton {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 24
                                    text: "✓"
                                    font.pixelSize: 11
                                    tooltip: "应用包头"
                                    onClicked: {
                                        var val = headerInput.text.trim().toUpperCase()
                                        if (val.length === 4) {
                                            serialBridge.pkgHeader = val
                                        }
                                    }
                                }
                            }

                            // 包尾输入
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: "包尾"
                                    color: subTextColor
                                    font.pixelSize: 11
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                TextField {
                                    id: footerInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    text: serialBridge.pkgFooter
                                    color: textColor
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    placeholderText: "5A5A"
                                    placeholderTextColor: subTextColor
                                    maximumLength: 4
                                    background: Rectangle {
                                        color: "#3a3a4e"
                                        radius: 3
                                        border.color: borderColor
                                        border.width: 1
                                    }
                                    validator: RegularExpressionValidator {
                                        regularExpression: /[0-9a-fA-F]{0,4}/
                                    }
                                    onEditingFinished: {
                                        var val = text.trim().toUpperCase()
                                        if (val.length === 4) {
                                            serialBridge.pkgFooter = val
                                        }
                                    }
                                }

                                CustomButton {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 24
                                    text: "✓"
                                    font.pixelSize: 11
                                    tooltip: "应用包尾"
                                    onClicked: {
                                        var val = footerInput.text.trim().toUpperCase()
                                        if (val.length === 4) {
                                            serialBridge.pkgFooter = val
                                        }
                                    }
                                }
                            }

                            // 重置默认按钮
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Item { Layout.fillWidth: true }

                                CustomButton {
                                    Layout.preferredHeight: 24
                                    Layout.preferredWidth: 150
                                    text: "恢复默认"
                                    font.pixelSize: 10
                                    btnColor: subTextColor
                                    onClicked: {
                                        serialBridge.pkgHeader = "A5A5"
                                        serialBridge.pkgFooter = "5A5A"
                                    }
                                }
                            }

                            Item { Layout.preferredHeight: 4 }

                            // 数据格式
                            Text { text: "数据格式"; color: accentColor; font.bold: true; font.pixelSize: 12 }
                            Text { text: "• 阴码 (点亮为1)"; color: textColor; font.pixelSize: 11; leftPadding: 8 }
                            Text { text: "• 列行式 (page先行后列)"; color: textColor; font.pixelSize: 11; leftPadding: 8 }
                            Text { text: "• 逆向输出 (低位在前)"; color: textColor; font.pixelSize: 11; leftPadding: 8 }

                            Item { Layout.preferredHeight: 4 }

                            // 状态
                            Text { text: "状态"; color: accentColor; font.bold: true; font.pixelSize: 12 }
                            Text {
                                text: "• 帧数: " + frameCount
                                color: textColor; font.pixelSize: 11; leftPadding: 8
                            }
                            Text {
                                text: "• 缓冲区: " + oledBuffer.length + " bytes"
                                color: textColor; font.pixelSize: 11; leftPadding: 8
                            }
                            Text {
                                text: "• 串口: " + (serialBridge.connected ? "已连接" : "未连接")
                                color: serialBridge.connected ? "#a6e3a1" : "#f38ba8"
                                font.pixelSize: 11; leftPadding: 8
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }

                // 像素颜色选择器
                Text {
                    text: "像素颜色"
                    color: subTextColor
                    font.pixelSize: 12
                    font.bold: true
                }

                // 预设颜色按钮
                Flow {
                    Layout.fillWidth: true
                    spacing: 4

                    readonly property var colors: [
                        { name: "OLED绿", color: "#a6e3a1" },
                        { name: "白色", color: "#ffffff" },
                        { name: "蓝色", color: "#89b4fa" },
                        { name: "红色", color: "#f38ba8" },
                        { name: "黄色", color: "#f9e2af" },
                        { name: "紫色", color: "#cba6f7" }
                    ]

                    Repeater {
                        model: parent.colors
                        delegate: Rectangle {
                            id: colorRect
                            width: 28
                            height: 28
                            radius: 4
                            color: modelData.color
                            border.width: pixelColor === modelData.color ? 2 : 0
                            border.color: "white"

                            MouseArea {
                                id: colorMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    pixelColor = modelData.color
                                    oledCanvas.requestPaint()
                                }
                            }

                            ToolTip {
                                text: modelData.name
                                delay: 500
                                visible: colorMouseArea.containsMouse
                                background: Rectangle {
                                    color: surfaceColor
                                    border.color: borderColor
                                    radius: 4
                                }
                                contentItem: Text {
                                    text: modelData.name
                                    color: textColor
                                }
                            }
                        }
                    }
                }

                // 自定义颜色选择器
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: 4
                        color: pixelColor
                        border.color: borderColor
                        border.width: 1
                    }

                    TextField {
                        id: colorInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        text: pixelColor
                        color: textColor
                        font.family: "monospace"
                        font.pixelSize: 11
                        placeholderText: "#RRGGBB"
                        placeholderTextColor: subTextColor
                        background: Rectangle {
                            color: "#3a3a4e"
                            radius: 3
                            border.color: borderColor
                            border.width: 1
                        }
                        onEditingFinished: {
                            var c = colorInput.text.trim()
                            if (c.length === 7 && c[0] === '#') {
                                pixelColor = c
                                oledCanvas.requestPaint()
                            }
                        }
                    }
                }

                // 背景颜色选择器
                Text {
                    text: "背景颜色"
                    color: subTextColor
                    font.pixelSize: 12
                    font.bold: true
                }

                // 预设背景颜色按钮
                Flow {
                    Layout.fillWidth: true
                    spacing: 4

                    readonly property var bgColors: [
                        { name: "暗黑", color: "#0a0a0a" },
                        { name: "深蓝", color: "#0a0a1a" },
                        { name: "深绿", color: "#0a1a0a" },
                        { name: "深红", color: "#1a0a0a" },
                        { name: "深紫", color: "#1a0a1a" },
                        { name: "深灰", color: "#1a1a1a" }
                    ]

                    Repeater {
                        model: parent.bgColors
                        delegate: Rectangle {
                            id: bgColorRect
                            width: 28
                            height: 28
                            radius: 4
                            color: modelData.color
                            border.width: bgColorCustom === modelData.color ? 2 : 0
                            border.color: "white"

                            MouseArea {
                                id: bgColorMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    bgColorCustom = modelData.color
                                    pixelOffColor = modelData.color
                                    oledCanvas.requestPaint()
                                }
                            }

                            ToolTip {
                                text: modelData.name
                                delay: 500
                                visible: bgColorMouseArea.containsMouse
                                background: Rectangle {
                                    color: surfaceColor
                                    border.color: borderColor
                                    radius: 4
                                }
                                contentItem: Text {
                                    text: modelData.name
                                    color: textColor
                                }
                            }
                        }
                    }
                }

                // 自定义背景颜色
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: 4
                        color: bgColorCustom
                        border.color: borderColor
                        border.width: 1
                    }

                    TextField {
                        id: bgColorInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        text: bgColorCustom
                        color: textColor
                        font.family: "monospace"
                        font.pixelSize: 11
                        placeholderText: "#RRGGBB"
                        placeholderTextColor: subTextColor
                        background: Rectangle {
                            color: "#3a3a4e"
                            radius: 3
                            border.color: borderColor
                            border.width: 1
                        }
                        onEditingFinished: {
                            var c = bgColorInput.text.trim()
                            if (c.length === 7 && c[0] === '#') {
                                bgColorCustom = c
                                pixelOffColor = c
                                oledCanvas.requestPaint()
                            }
                        }
                    }
                }

            }
        }
    }

    // ========== Status Bar ==========
    Rectangle {
        id: statusBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: fullScreenMode ? 0 : 28
        clip: true
        color: surfaceColor

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: serialBridge.connected ? successColor : errorColor
            }

            Text {
                text: serialBridge.statusMessage || "就绪"
                color: subTextColor
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: serialBridge.connected ? "已连接" : "未连接"
                color: serialBridge.connected ? successColor : errorColor
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    // Auto refresh ports on startup
    Component.onCompleted: {
        serialBridge.refresh_ports()
    }

    // ========== Custom Button Component ==========
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
