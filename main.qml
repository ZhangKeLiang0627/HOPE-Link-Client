import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    width: 850
    height: 600
    minimumWidth: 850
    minimumHeight: 500
    title: "HOPE-Link Client"
    visible: true

    // ========== Theme System ==========
    // Dark theme colors (default)
    readonly property color darkBgColor: "#1e1e2e"
    readonly property color darkSurfaceColor: "#2a2a3e"
    readonly property color darkAccentColor: "#89b4fa"
    readonly property color darkTextColor: "#cdd6f4"
    readonly property color darkSubTextColor: "#a6adc8"
    readonly property color darkErrorColor: "#f38ba8"
    readonly property color darkSuccessColor: "#a6e3a1"
    readonly property color darkBorderColor: "#45475a"
    readonly property color darkInputBgColor: "#3a3a4e"
    readonly property color darkMonitorBgColor: "#1a1a2e"

    // Light theme colors (米白色系)
    readonly property color lightBgColor: "#f5f0eb"
    readonly property color lightSurfaceColor: "#faf7f2"
    readonly property color lightAccentColor: "#4f6ef7"
    readonly property color lightTextColor: "#2c2c2c"
    readonly property color lightSubTextColor: "#78716c"
    readonly property color lightErrorColor: "#dc2626"
    readonly property color lightSuccessColor: "#16a34a"
    readonly property color lightBorderColor: "#d6d0c8"
    readonly property color lightInputBgColor: "#e8e2da"
    readonly property color lightMonitorBgColor: "#fdfbf8"

    // Current theme colors (reactive to themeManager.isDark)
    property color bgColor: themeManager && themeManager.isDark ? darkBgColor : lightBgColor
    property color surfaceColor: themeManager && themeManager.isDark ? darkSurfaceColor : lightSurfaceColor
    property color accentColor: themeManager && themeManager.isDark ? darkAccentColor : lightAccentColor
    property color textColor: themeManager && themeManager.isDark ? darkTextColor : lightTextColor
    property color subTextColor: themeManager && themeManager.isDark ? darkSubTextColor : lightSubTextColor
    property color errorColor: themeManager && themeManager.isDark ? darkErrorColor : lightErrorColor
    property color successColor: themeManager && themeManager.isDark ? darkSuccessColor : lightSuccessColor
    property color borderColor: themeManager && themeManager.isDark ? darkBorderColor : lightBorderColor
    property color inputBgColor: themeManager && themeManager.isDark ? darkInputBgColor : lightInputBgColor
    property color monitorBgColor: themeManager && themeManager.isDark ? darkMonitorBgColor : lightMonitorBgColor

    // Update colors when theme changes
    Connections {
        target: themeManager
        function onThemeChanged() {
            // Force property re-evaluation by toggling a dummy property
            // The property bindings above will automatically update
            console.log("Theme changed to:", themeManager.isDark ? "dark" : "light")
        }
    }

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

    // 当前标签页索引 (0 = OLED显示, 1 = 串口监视器)
    property int currentTab: 0

    // 监视器定时清理定时器（每30秒清理一次）
    property var monitorCleanupTimer: null

    // 监视器最大条目数（超过此数自动清理一半）
    readonly property int maxMonitorLines: 500

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
                model: serialBridge ? serialBridge.ports : []
                currentIndex: -1
                displayText: currentIndex >= 0 ? currentText : "选择串口..."
                background: Rectangle {
                    color: parent.enabled ? inputBgColor : surfaceColor
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
                model: serialBridge ? serialBridge.baudRates : []
                currentIndex: 4  // 115200
                editable: true
                validator: IntValidator {
                    bottom: 1
                    top: 9999999
                }
                contentItem: TextInput {
                    text: baudCombo.displayText
                    font: baudCombo.font
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                    rightPadding: 34
                    onAccepted: {
                        baudCombo.currentIndex = -1
                        baudCombo.editText = text
                    }
                }
                background: Rectangle {
                    color: inputBgColor
                    radius: 4
                    border.color: borderColor
                    border.width: 1
                }
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
                onClicked: { if (serialBridge) serialBridge.refresh_ports() }
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

            // Theme toggle switch (白天/黑夜模式)
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 90
                color: "transparent"

                Item {
                    anchors.centerIn: parent
                    width: 72
                    height: 32

                    // 开关背景轨道
                    Rectangle {
                        id: themeSwitch
                        anchors.centerIn: parent
                        width: 52
                        height: 28
                        radius: 14
                        color: themeManager && themeManager.isDark ? "#4a6cf7" : "#c4bdb5"
                        border.color: themeManager && themeManager.isDark ? Qt.lighter("#4a6cf7", 1.2) : "#b8b0a8"
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 200 }
                        }

                        // 白色圆形滑块（带图标）
                        Rectangle {
                            id: themeSwitchKnob
                            anchors.verticalCenter: parent.verticalCenter
                            x: themeManager && themeManager.isDark ? 26 : 2
                            width: 24
                            height: 24
                            radius: 12
                            color: "#ffffff"

                            Behavior on x {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }

                            // 滑块上的图标
                            Text {
                                anchors.centerIn: parent
                                text: themeManager && themeManager.isDark ? "🌙" : "☀️"
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (themeManager) {
                                    themeManager.toggle()
                                }
                            }
                        }
                    }

                    ToolTip {
                        text: themeManager && themeManager.isDark ? "切换到白天模式" : "切换到黑夜模式"
                        delay: 500
                        visible: themeSwitchMouseArea.containsMouse
                        background: Rectangle {
                            color: surfaceColor
                            border.color: borderColor
                            radius: 4
                        }
                        contentItem: Text {
                            text: themeManager && themeManager.isDark ? "切换到白天模式" : "切换到黑夜模式"
                            color: textColor
                        }
                    }

                    MouseArea {
                        id: themeSwitchMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Connect / Disconnect button
            CustomButton {
                id: connectBtn
                Layout.fillHeight: true
                Layout.preferredWidth: 100
                text: serialBridge && serialBridge.connected ? "断开连接" : "打开串口"
                btnColor: serialBridge && serialBridge.connected ? errorColor : successColor
                enabled: (serialBridge && serialBridge.connected) || portCombo.count > 0
                onClicked: {
                    if (!serialBridge) return
                    if (serialBridge.connected) {
                        serialBridge.disconnect_port()
                    } else {
                        if (portCombo.currentIndex < 0) {
                            return
                        }
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

    // ========== Tab Bar ==========
    Rectangle {
        id: tabBar
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: fullScreenMode ? 0 : 36
        clip: true
        visible: !fullScreenMode
        color: surfaceColor

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 2

            // Tab: OLED显示
            Rectangle {
                id: tabOled
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                color: currentTab === 0 ? bgColor : surfaceColor
                radius: 6
                // 底部圆角遮罩
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 6
                    color: parent.color
                }

                Text {
                    anchors.centerIn: parent
                    text: "🖥 OLED显示"
                    color: currentTab === 0 ? accentColor : subTextColor
                    font.pixelSize: 12
                    font.bold: currentTab === 0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: currentTab = 0
                }
            }

            // Tab: 串口监视器
            Rectangle {
                id: tabMonitor
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                color: currentTab === 1 ? bgColor : surfaceColor
                radius: 6
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 6
                    color: parent.color
                }

                Text {
                    anchors.centerIn: parent
                    text: "📟 串口监视器"
                    color: currentTab === 1 ? accentColor : subTextColor
                    font.pixelSize: 12
                    font.bold: currentTab === 1
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: currentTab = 1
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    // ========== Main Content Area ==========
    Rectangle {
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: statusBar.top
        color: bgColor

        // ====== Tab 0: OLED Display ======
        RowLayout {
            anchors.fill: parent
            anchors.margins: fullScreenMode ? 0 : 4
            spacing: fullScreenMode ? 0 : 8
            visible: currentTab === 0

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
                    anchors.margins: fullScreenMode ? 0 : 4
                    spacing: fullScreenMode ? 0 : 4

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
                            text: serialBridge && serialBridge.connected ? "● 已连接" : "○ 未连接"
                            color: serialBridge && serialBridge.connected ? successColor : errorColor
                            font.pixelSize: 12
                        }
                    }

                    // OLED Screen
                    Rectangle {
                        id: oledScreen
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: fullScreenMode ? 0 : 4
                        color: bgColorCustom
                        radius: fullScreenMode ? 0 : 8
                        border.color: fullScreenMode ? "transparent" : borderColor
                        border.width: fullScreenMode ? 0 : 2

                        // OLED 像素画布
                        Canvas {
                            id: oledCanvas
                            anchors.centerIn: parent

                            readonly property real scaleFactor: fullScreenMode ?
                                Math.min(parent.width / displayWidth, parent.height / displayHeight) : 1.0

                            width: displayWidth * scaleFactor
                            height: displayHeight * scaleFactor

                            onPaint: {
                                var ctx = getContext("2d")
                                if (!ctx) return

                                ctx.fillStyle = pixelOffColor
                                ctx.fillRect(0, 0, width, height)

                                if (oledBuffer.length !== 1024) {
                                    ctx.fillStyle = "#88ffffff"
                                    ctx.font = "bold " + (18 * scaleFactor) + "px monospace"
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "middle"
                                    ctx.fillText("等待数据...", width / 2, height / 2)

                                    ctx.fillStyle = "#55ffffff"
                                    ctx.font = (12 * scaleFactor) + "px monospace"
                                    ctx.fillText("请确保 MCU 已发送 OLED 帧数据", width / 2, height / 2 + 22 * scaleFactor)
                                    return
                                }

                                ctx.fillStyle = pixelColor
                                var sf = scaleFactor

                                for (var page = 0; page < 8; page++) {
                                    for (var col = 0; col < 128; col++) {
                                        var byteVal = oledBuffer[page * 128 + col]
                                        if (byteVal === undefined) continue

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

                            Connections {
                                target: serialBridge
                                function onOledFrameReady(data) {
                                    oledBuffer = data
                                    frameCount++
                                    oledCanvas.requestPaint()
                                }
                            }
                        }

                        // 全屏模式下的悬浮还原按钮
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
                                if (serialBridge) serialBridge.clear_buffer()
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
                        color: monitorBgColor
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
                                                var h = serialBridge ? serialBridge.pkgHeader : "A5A5"
                                                if (h && h.length === 4) {
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
                                                var f = serialBridge ? serialBridge.pkgFooter : "5A5A"
                                                if (f && f.length === 4) {
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
                                        text: serialBridge ? serialBridge.pkgHeader : "A5A5"
                                        color: textColor
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                        placeholderText: "A5A5"
                                        placeholderTextColor: subTextColor
                                        maximumLength: 4
                                        background: Rectangle {
                                            color: inputBgColor
                                            radius: 3
                                            border.color: borderColor
                                            border.width: 1
                                        }
                                        validator: RegularExpressionValidator {
                                            regularExpression: /[0-9a-fA-F]{0,4}/
                                        }
                                        onEditingFinished: {
                                            if (!serialBridge) return
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
                                            if (!serialBridge) return
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
                                        text: serialBridge ? serialBridge.pkgFooter : "5A5A"
                                        color: textColor
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                        placeholderText: "5A5A"
                                        placeholderTextColor: subTextColor
                                        maximumLength: 4
                                        background: Rectangle {
                                            color: inputBgColor
                                            radius: 3
                                            border.color: borderColor
                                            border.width: 1
                                        }
                                        validator: RegularExpressionValidator {
                                            regularExpression: /[0-9a-fA-F]{0,4}/
                                        }
                                        onEditingFinished: {
                                            if (!serialBridge) return
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
                                            if (!serialBridge) return
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
                                    text: "• 串口: " + (serialBridge && serialBridge.connected ? "已连接" : "未连接")
                                    color: serialBridge && serialBridge.connected ? "#a6e3a1" : "#f38ba8"
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
                                color: inputBgColor
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
                                color: inputBgColor
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

        // ====== Tab 1: 串口监视器 ======
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            visible: currentTab === 1
            color: surfaceColor
            radius: 6
            border.color: borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                // 监视器头部
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "串口监视器"
                        color: accentColor
                        font.bold: true
                        font.pixelSize: 15
                    }

                    Item { Layout.fillWidth: true }

                    // 显示模式切换
                    Text {
                        text: "显示:"
                        color: subTextColor
                        font.pixelSize: 11
                        verticalAlignment: Text.AlignVCenter
                    }

                    CustomButton {
                        id: hexModeBtn
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 50
                        text: "HEX"
                        font.pixelSize: 11
                        btnColor: monitorHexMode ? accentColor : subTextColor
                        onClicked: monitorHexMode = true
                    }

                    CustomButton {
                        id: textModeBtn
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 50
                        text: "文本"
                        font.pixelSize: 11
                        btnColor: monitorHexMode ? subTextColor : accentColor
                        onClicked: monitorHexMode = false
                    }

                    // 自动滚动
                    Text {
                        text: "自动滚动:"
                        color: subTextColor
                        font.pixelSize: 11
                        verticalAlignment: Text.AlignVCenter
                    }

                    CustomButton {
                        id: autoScrollBtn
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 50
                        text: monitorAutoScroll ? "开" : "关"
                        font.pixelSize: 11
                        btnColor: monitorAutoScroll ? successColor : errorColor
                        onClicked: monitorAutoScroll = !monitorAutoScroll
                    }

                    // 复制全部按钮
                    CustomButton {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 60
                        text: "复制"
                        font.pixelSize: 11
                        btnColor: accentColor
                        onClicked: {
                            // 将所有条目格式化为可读文本并复制到剪贴板
                            var allText = ""
                            for (var ei = 0; ei < monitorEntries.length; ei++) {
                                var e = monitorEntries[ei]
                                if (e.type === "rx_text_pending") continue  // 跳过未完成的行
                                if (allText.length > 0) allText += "\n"
                                allText += "[" + e.timestamp + "] " + e.content
                            }
                            if (allText.length > 0) {
                                // 使用 TextEdit 作为剪贴板中介
                                var clipHelper = Qt.createQmlObject(
                                    'import QtQuick 2.0; TextEdit { text: "" }',
                                    root
                                )
                                clipHelper.text = allText
                                clipHelper.selectAll()
                                clipHelper.copy()
                                clipHelper.destroy()
                            }
                        }
                    }

                    // 清空按钮
                    CustomButton {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 60
                        text: "清空"
                        font.pixelSize: 11
                        btnColor: subTextColor
                        onClicked: {
                            monitorLog = ""
                            monitorEntries = []
                            if (serialBridge) serialBridge.clear_monitor()
                        }
                    }
                }

                // ====== 数据显示区域 ======
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: monitorBgColor
                    radius: 4
                    border.color: borderColor
                    border.width: 1
                    clip: true

                    ListView {
                        id: monitorListView
                        anchors.fill: parent
                        anchors.margins: 4
                        model: monitorEntries
                        spacing: 2
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            background: Rectangle { color: "transparent" }
                            contentItem: Rectangle {
                                color: borderColor
                                radius: 2
                            }
                        }
                        onContentHeightChanged: {
                            if (monitorAutoScroll) {
                                monitorListView.positionViewAtEnd()
                            }
                        }

                        delegate: Item {
                            id: entryDelegate
                            width: monitorListView.width - 8
                            height: timestampText.height + contentText.height + 4

                            // 时间戳 - 小字号，不同颜色（不可选中）
                            Text {
                                id: timestampText
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                text: "[" + modelData.timestamp + "]"
                                color: {
                                    var t = modelData.type
                                    if (t === "tx_text" || t === "tx_hex") return "#89b4fa"  // 蓝色 - 发送
                                    if (t === "rx_hex") return "#a6e3a1"                      // 绿色 - 接收HEX
                                    if (t === "rx_text_pending") return "#f9e2af"             // 黄色 - 接收文本（进行中）
                                    return "#f9e2af"                                           // 黄色 - 接收文本
                                }
                                font.family: "monospace"
                                font.pixelSize: 10
                                font.bold: modelData.type === "rx_text_pending"
                                opacity: modelData.type === "rx_text_pending" ? 0.6 : 0.8
                            }

                            // 内容 - 使用 TextEdit 实现可选择/复制
                            TextEdit {
                                id: contentText
                                anchors.top: timestampText.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                text: modelData.type === "rx_text_pending" ? modelData.content + " ▏" : modelData.content
                                color: modelData.type === "rx_text_pending" ? "#a6adc8" : textColor
                                font.family: "monospace"
                                font.pixelSize: 12
                                font.italic: modelData.type === "rx_text_pending"
                                wrapMode: TextEdit.WrapAnywhere
                                readOnly: true
                                selectByMouse: true
                                selectionColor: "#3a3a5e"
                                selectedTextColor: color
                                // 右键菜单支持复制
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    cursorShape: Qt.IBeamCursor
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            contentText.selectAll()
                                            contentText.copy()
                                            contentText.deselect()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 数据接收指示器
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 4
                        width: 8
                        height: 8
                        radius: 4
                        color: monitorBlink ? successColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }

                // ====== 发送区域 ======
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    color: monitorBgColor
                    radius: 4
                    border.color: borderColor
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 6

                        // 发送模式切换
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "发送:"
                                color: subTextColor
                                font.pixelSize: 11
                                verticalAlignment: Text.AlignVCenter
                            }

                            CustomButton {
                                id: sendAsciiBtn
                                Layout.preferredHeight: 22
                                Layout.preferredWidth: 50
                                text: "ASCII"
                                font.pixelSize: 10
                                btnColor: sendHexMode ? subTextColor : accentColor
                                onClicked: sendHexMode = false
                            }

                            CustomButton {
                                id: sendHexBtn
                                Layout.preferredHeight: 22
                                Layout.preferredWidth: 50
                                text: "HEX"
                                font.pixelSize: 10
                                btnColor: sendHexMode ? accentColor : subTextColor
                                onClicked: sendHexMode = true
                            }

                            Item { Layout.fillWidth: true }

                            // 发送新行
                            Text {
                                text: "追加换行:"
                                color: subTextColor
                                font.pixelSize: 11
                                verticalAlignment: Text.AlignVCenter
                            }

                            CustomButton {
                                id: appendNewlineBtn
                                Layout.preferredHeight: 22
                                Layout.preferredWidth: 50
                                text: monitorAppendNewline ? "开" : "关"
                                font.pixelSize: 10
                                btnColor: monitorAppendNewline ? successColor : errorColor
                                onClicked: monitorAppendNewline = !monitorAppendNewline
                            }
                        }

                        // 发送输入框
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            TextField {
                                id: sendInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: textColor
                                font.family: "monospace"
                                font.pixelSize: 12
                                placeholderText: sendHexMode ? "输入十六进制数据，如: 01 02 FF" : "输入要发送的文本..."
                                placeholderTextColor: subTextColor
                                background: Rectangle {
                                    color: inputBgColor
                                    radius: 4
                                    border.color: borderColor
                                    border.width: 1
                                }
                                // 按 Enter 发送
                                Keys.onReturnPressed: {
                                    sendMonitorData()
                                }
                                Keys.onEnterPressed: {
                                    sendMonitorData()
                                }
                                // 方向键上 - 历史上一条
                                Keys.onUpPressed: {
                                    if (commandHistory.length === 0) return
                                    if (commandHistoryIndex > 0) {
                                        commandHistoryIndex--
                                        sendInput.text = commandHistory[commandHistoryIndex]
                                    }
                                }
                                // 方向键下 - 历史下一条
                                Keys.onDownPressed: {
                                    if (commandHistory.length === 0) return
                                    if (commandHistoryIndex < commandHistory.length - 1) {
                                        commandHistoryIndex++
                                        sendInput.text = commandHistory[commandHistoryIndex]
                                    } else {
                                        // 如果已经在最后一条，再按向下则清空输入框
                                        commandHistoryIndex = commandHistory.length
                                        sendInput.text = ""
                                    }
                                }
                            }

                            // 发送按钮
                            CustomButton {
                                Layout.fillHeight: true
                                Layout.preferredWidth: 80
                                text: "发送"
                                font.pixelSize: 12
                                btnColor: accentColor
                                enabled: serialBridge && serialBridge.connected && sendInput.text.trim().length > 0
                                onClicked: sendMonitorData()
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
                color: serialBridge && serialBridge.connected ? successColor : errorColor
            }

            Text {
                text: serialBridge && serialBridge.statusMessage ? serialBridge.statusMessage : "就绪"
                color: subTextColor
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: serialBridge && serialBridge.connected ? "已连接" : "未连接"
                color: serialBridge && serialBridge.connected ? successColor : errorColor
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    // ========== 监视器属性 ==========
    // HEX/文本显示模式
    property bool monitorHexMode: false
    // 自动滚动
    property bool monitorAutoScroll: true
    // 发送模式 (true=HEX, false=ASCII)
    property bool sendHexMode: false
    // 追加换行
    property bool monitorAppendNewline: true
    // 监视器日志文本 (plain text fallback)
    property string monitorLog: ""
    // 闪烁指示器
    property bool monitorBlink: false

    // 监视器日志条目列表 (每个条目包含 type, timestamp, content)
    property var monitorEntries: []

    // 命令历史
    property var commandHistory: []
    property int commandHistoryIndex: -1

    // 文本接收缓冲区 - 用于累积未遇到换行符的文本
    property string textBuffer: ""
    // 文本接收缓冲区的起始时间戳
    property string textBufferTimestamp: ""

    // 添加日志条目
    function addMonitorEntry(type, content) {
        var ts = new Date().toLocaleTimeString()
        var entry = {
            "type": type,       // "rx_text", "rx_hex", "tx_text", "tx_hex"
            "timestamp": ts,
            "content": content
        }
        // 使用展开运算符创建新数组，确保 ListView 能检测到变化
        monitorEntries = monitorEntries.concat([entry])
        // 限制条目数
        if (monitorEntries.length > maxMonitorLines) {
            monitorEntries = monitorEntries.slice(monitorEntries.length - maxMonitorLines)
        }
        // 更新纯文本 fallback
        monitorLog = monitorLog + "\n[" + ts + "] " + content
        trimMonitorLog()
        scrollToBottom()
        monitorBlink = !monitorBlink
    }

    // 发送数据函数
    function sendMonitorData() {
        if (!serialBridge || !serialBridge.connected) return
        var text = sendInput.text.trim()
        if (text.length === 0) return

        // 保存到命令历史
        commandHistory.push(text)
        commandHistoryIndex = commandHistory.length  // 指向末尾之后（新输入位置）

        if (sendHexMode) {
            serialBridge.send_hex_data(text)
            addMonitorEntry("tx_hex", text.toUpperCase())
        } else {
            if (monitorAppendNewline) {
                serialBridge.send_data(text + "\n")
            } else {
                serialBridge.send_data(text)
            }
            addMonitorEntry("tx_text", text)
        }

        sendInput.text = ""
        scrollToBottom()
    }

    function trimMonitorLog() {
        var lines = monitorLog.split("\n")
        if (lines.length > maxMonitorLines) {
            monitorLog = lines.slice(lines.length - maxMonitorLines).join("\n")
        }
    }

    function scrollToBottom() {
        if (monitorAutoScroll) {
            monitorListView.positionViewAtEnd()
        }
    }

    // 接收 HEX 数据
    Connections {
        target: serialBridge
        function onRawDataReceived(hexStr) {
            if (monitorHexMode) {
                // 格式化 HEX 显示，每行显示 16 字节
                var formatted = ""
                for (var i = 0; i < hexStr.length; i += 32) {
                    var chunk = hexStr.substring(i, Math.min(i + 32, hexStr.length))
                    // 插入空格每2个字符
                    var spaced = ""
                    for (var j = 0; j < chunk.length; j += 2) {
                        spaced += chunk.substring(j, j + 2) + " "
                    }
                    if (i === 0) {
                        formatted = spaced.trim()
                    } else {
                        formatted += "\n" + " ".repeat(12) + spaced.trim()
                    }
                }
                addMonitorEntry("rx_hex", formatted)
            }
        }
    }

    // 接收文本数据 - 使用缓冲区累积文本，遇到换行符才添加时间戳
    Connections {
        target: serialBridge
        function onRawTextReceived(text) {
            if (!monitorHexMode) {
                // 替换不可见字符为可显示形式（保留换行符）
                var display = text.replace(/[^\x20-\x7E\n\r\t]/g, function(c) {
                    return "\\x" + c.charCodeAt(0).toString(16).toUpperCase().padStart(2, "0")
                })

                // 追加到缓冲区
                textBuffer += display

                // 循环处理缓冲区中的所有完整行（以换行符分隔）
                var processed = false
                while (true) {
                    // 查找缓冲区中第一个换行符的位置
                    var newlineIdx = -1
                    for (var k = 0; k < textBuffer.length; k++) {
                        if (textBuffer.charAt(k) === "\n" || textBuffer.charAt(k) === "\r") {
                            newlineIdx = k
                            break
                        }
                    }

                    if (newlineIdx < 0) {
                        // 没有换行符，停止处理
                        break
                    }

                    // 提取换行符之前的内容作为一行
                    var line = textBuffer.substring(0, newlineIdx)
                    var ts = textBufferTimestamp !== "" ? textBufferTimestamp : new Date().toLocaleTimeString()

                    // 如果有未完成的"进行中"条目，先移除它（因为它即将被正式的完整行替代）
                    if (monitorEntries.length > 0) {
                        var lastCheck = monitorEntries[monitorEntries.length - 1]
                        if (lastCheck.type === "rx_text_pending") {
                            monitorEntries = monitorEntries.slice(0, monitorEntries.length - 1)
                        }
                    }

                    if (line.length > 0) {
                        var entry = {
                            "type": "rx_text",
                            "timestamp": ts,
                            "content": line
                        }
                        monitorEntries = monitorEntries.concat([entry])
                        if (monitorEntries.length > maxMonitorLines) {
                            monitorEntries = monitorEntries.slice(monitorEntries.length - maxMonitorLines)
                        }
                        monitorLog = monitorLog + "\n[" + ts + "] " + line
                    }

                    // 剩余部分（换行符之后的内容）继续留在缓冲区
                    textBuffer = textBuffer.substring(newlineIdx + 1)
                    textBufferTimestamp = new Date().toLocaleTimeString()
                    processed = true
                }

                // 如果没有处理出任何完整行（即缓冲区中没有换行符），
                // 且缓冲区有内容，则显示一个临时的"进行中"条目
                if (!processed && textBuffer.length > 0) {
                    // 检查最后一条条目是否是一个未完成的"进行中"条目
                    var lastEntry = monitorEntries.length > 0 ? monitorEntries[monitorEntries.length - 1] : null
                    if (lastEntry && lastEntry.type === "rx_text_pending") {
                        // 更新已有的"进行中"条目
                        lastEntry.content = textBuffer
                        monitorEntries[monitorEntries.length - 1] = lastEntry
                        monitorEntries = monitorEntries.concat([])
                    } else {
                        // 创建一个新的"进行中"条目（使用不同的类型，以便与完整行区分）
                        var pendingEntry = {
                            "type": "rx_text_pending",
                            "timestamp": textBufferTimestamp !== "" ? textBufferTimestamp : new Date().toLocaleTimeString(),
                            "content": textBuffer
                        }
                        monitorEntries = monitorEntries.concat([pendingEntry])
                        if (monitorEntries.length > maxMonitorLines) {
                            monitorEntries = monitorEntries.slice(monitorEntries.length - maxMonitorLines)
                        }
                    }
                }

                trimMonitorLog()
                scrollToBottom()
                monitorBlink = !monitorBlink
            }
        }
    }

    // 监视器清空
    Connections {
        target: serialBridge
        function onMonitorCleared() {
            monitorLog = ""
            monitorEntries = []
        }
    }

    // 当前标签页变化时，同步通知 Python 后端
    onCurrentTabChanged: {
        if (serialBridge) {
            serialBridge.monitorTabActive = (currentTab === 1)
        }
    }

    // 监视器条目定时清理（每30秒清理一次，防止无限增长）
    function cleanupMonitorEntries() {
        if (monitorEntries.length > maxMonitorLines) {
            // 保留最新的 maxMonitorLines 条
            monitorEntries = monitorEntries.slice(monitorEntries.length - maxMonitorLines)
            // 同时清理 monitorLog
            var lines = monitorLog.split("\n")
            if (lines.length > maxMonitorLines) {
                monitorLog = lines.slice(lines.length - maxMonitorLines).join("\n")
            }
        }
    }

    // Auto refresh ports on startup
    Component.onCompleted: {
        serialBridge.refresh_ports()
        // 创建定时清理定时器
        monitorCleanupTimer = Qt.createQmlObject(
            'import QtQuick 2.0; Timer { interval: 30000; running: true; repeat: true; }',
            root
        )
        monitorCleanupTimer.triggered.connect(cleanupMonitorEntries)
    }

    // ========== Custom Button Component ==========
    component CustomButton : Button {
        property color btnColor: accentColor
        property string tooltip: ""

        // 鼠标悬停状态
        property bool hoveredState: false

        // 动画属性：渐变透明度（带动画过渡）
        property real hoverGlow: 0.0

        Behavior on hoverGlow {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        background: Rectangle {
            id: bgRect
            radius: 4
            opacity: parent.enabled ? 1.0 : 0.5

            // 基础颜色
            color: parent.enabled ? (parent.pressed ? Qt.darker(btnColor, 1.3) : btnColor) : "#3a3a4e"

            // 悬停渐变叠加层
            Rectangle {
                anchors.fill: parent
                radius: 4
                visible: parent.parent.hoveredState
                opacity: parent.parent.hoverGlow

                // 渐变背景
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.lighter(btnColor, 1.3) }
                    GradientStop { position: 0.5; color: Qt.lighter(btnColor, 1.5) }
                    GradientStop { position: 1.0; color: Qt.lighter(btnColor, 1.3) }
                }

                // 边框发光效果
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.3 * parent.parent.hoverGlow)
                }
            }

            // 底部高光线（悬停时显示）
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                radius: 1
                visible: parent.parent.hoveredState
                opacity: parent.parent.hoverGlow * 0.6
                color: Qt.lighter(btnColor, 1.8)
            }
        }

        contentItem: Text {
            text: parent.text
            color: parent.enabled ? "#1e1e2e" : subTextColor
            font.bold: true
            font.pixelSize: parent.font.pixelSize || 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        // 鼠标悬停检测
        MouseArea {
            id: internalMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton  // 不拦截按钮点击事件

            onEntered: {
                parent.hoveredState = true
                parent.hoverGlow = 1.0
            }
            onExited: {
                parent.hoveredState = false
                parent.hoverGlow = 0.0
            }
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
