import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 800
    height: 600
    minimumWidth: 700
    minimumHeight: 500
    title: "简易串口助手"
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

    // ========== Top Toolbar ==========
    Rectangle {
        id: toolbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 50
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
                indicator: Item {
                    x: parent.width - width
                    width: 30
                    height: parent.height
                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 6
                        color: "transparent"
                        Canvas {
                            anchors.fill: parent
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

            // Baud rate selector
            ComboBox {
                id: baudCombo
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                model: serialBridge.baudRates
                currentIndex: 4  // 115200
                background: Rectangle {
                    color: "#3a3a4e"
                    radius: 4
                    border.color: borderColor
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.currentText
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
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

            Item { Layout.fillWidth: true }

            // Connect / Disconnect button
            CustomButton {
                id: connectBtn
                Layout.fillHeight: true
                Layout.preferredWidth: 100
                text: serialBridge.connected ? "断开连接" : "打开串口"
                btnColor: serialBridge.connected ? errorColor : successColor
                onClicked: {
                    if (serialBridge.connected) {
                        serialBridge.disconnect_port()
                    } else {
                        if (portCombo.currentIndex < 0) {
                            return
                        }
                        serialBridge.connect_port(portCombo.currentText, baudCombo.currentText)
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
        anchors.margins: 8
        spacing: 8

        // ====== Receive Area ======
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: surfaceColor
            radius: 6
            border.color: borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "接收区"
                        color: accentColor
                        font.bold: true
                        font.pixelSize: 14
                    }
                    Item { Layout.fillWidth: true }
                    CustomButton {
                        text: "清空"
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 50
                        font.pixelSize: 11
                        onClicked: {
                            receiveText.text = ""
                            serialBridge.clear_buffer()
                        }
                    }
                }

                // Receive text area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#1a1a2e"
                    radius: 4
                    border.color: borderColor
                    border.width: 1
                    clip: true

                    Flickable {
                        id: receiveFlick
                        anchors.fill: parent
                        anchors.margins: 4
                        contentWidth: receiveText.width
                        contentHeight: receiveText.height
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            background: Rectangle { color: "transparent" }
                            contentItem: Rectangle {
                                color: borderColor
                                radius: 2
                            }
                        }

                        TextEdit {
                            id: receiveText
                            width: Math.max(receiveFlick.width, implicitWidth)
                            color: textColor
                            font.family: "monospace"
                            font.pixelSize: 13
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            textFormat: TextEdit.PlainText
                        }
                    }
                }

                // Receive options
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    CheckBox {
                        id: autoScrollCheck
                        checked: true
                        text: "自动滚动"
                        contentItem: Text {
                            text: parent.text
                            color: subTextColor
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: parent.indicator.width + parent.spacing
                        }
                        indicator: Rectangle {
                            implicitWidth: 16
                            implicitHeight: 16
                            x: 0
                            y: parent.height / 2 - height / 2
                            radius: 3
                            color: parent.checked ? accentColor : "#3a3a4e"
                            border.color: borderColor
                            Rectangle {
                                x: 3; y: 3
                                width: 10; height: 10
                                radius: 2
                                color: parent.checked ? "#1e1e2e" : "transparent"
                            }
                        }
                    }

                    CheckBox {
                        id: hexDisplayCheck
                        text: "HEX显示"
                        contentItem: Text {
                            text: parent.text
                            color: subTextColor
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: parent.indicator.width + parent.spacing
                        }
                        indicator: Rectangle {
                            implicitWidth: 16
                            implicitHeight: 16
                            x: 0
                            y: parent.height / 2 - height / 2
                            radius: 3
                            color: parent.checked ? accentColor : "#3a3a4e"
                            border.color: borderColor
                            Rectangle {
                                x: 3; y: 3
                                width: 10; height: 10
                                radius: 2
                                color: parent.checked ? "#1e1e2e" : "transparent"
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }

        // ====== Send Area ======
        Rectangle {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: surfaceColor
            radius: 6
            border.color: borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "发送区"
                        color: accentColor
                        font.bold: true
                        font.pixelSize: 14
                    }
                    Item { Layout.fillWidth: true }
                    CustomButton {
                        text: "清空"
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 50
                        font.pixelSize: 11
                        onClicked: sendText.text = ""
                    }
                }

                // Send text area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#1a1a2e"
                    radius: 4
                    border.color: borderColor
                    border.width: 1
                    clip: true

                    Flickable {
                        id: sendFlick
                        anchors.fill: parent
                        anchors.margins: 4
                        contentWidth: sendText.width
                        contentHeight: sendText.height
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            background: Rectangle { color: "transparent" }
                            contentItem: Rectangle {
                                color: borderColor
                                radius: 2
                            }
                        }

                        TextArea {
                            id: sendText
                            width: Math.max(sendFlick.width, implicitWidth)
                            color: textColor
                            font.family: "monospace"
                            font.pixelSize: 13
                            wrapMode: TextEdit.Wrap
                            placeholderText: "输入要发送的数据..."
                            placeholderTextColor: subTextColor
                            background: null
                        }
                    }
                }

                // Send options
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    CheckBox {
                        id: hexSendCheck
                        text: "HEX发送"
                        contentItem: Text {
                            text: parent.text
                            color: subTextColor
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: parent.indicator.width + parent.spacing
                        }
                        indicator: Rectangle {
                            implicitWidth: 16
                            implicitHeight: 16
                            x: 0
                            y: parent.height / 2 - height / 2
                            radius: 3
                            color: parent.checked ? accentColor : "#3a3a4e"
                            border.color: borderColor
                            Rectangle {
                                x: 3; y: 3
                                width: 10; height: 10
                                radius: 2
                                color: parent.checked ? "#1e1e2e" : "transparent"
                            }
                        }
                    }

                    CheckBox {
                        id: appendNewlineCheck
                        checked: true
                        text: "追加换行"
                        contentItem: Text {
                            text: parent.text
                            color: subTextColor
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: parent.indicator.width + parent.spacing
                        }
                        indicator: Rectangle {
                            implicitWidth: 16
                            implicitHeight: 16
                            x: 0
                            y: parent.height / 2 - height / 2
                            radius: 3
                            color: parent.checked ? accentColor : "#3a3a4e"
                            border.color: borderColor
                            Rectangle {
                                x: 3; y: 3
                                width: 10; height: 10
                                radius: 2
                                color: parent.checked ? "#1e1e2e" : "transparent"
                            }
                        }
                    }
                }

                // Send button
                CustomButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    text: "发送"
                    btnColor: accentColor
                    enabled: serialBridge.connected && sendText.text.length > 0
                    onClicked: {
                        var data = sendText.text
                        if (appendNewlineCheck.checked) {
                            data += "\n"
                        }
                        if (hexSendCheck.checked) {
                            serialBridge.send_hex_data(data)
                        } else {
                            serialBridge.send_data(data)
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
        height: 28
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

    // ========== Connections ==========
    Connections {
        target: serialBridge
        function onDataReceived(data) {
            if (hexDisplayCheck.checked) {
                // Convert to hex string
                var hex = ""
                for (var i = 0; i < data.length; i++) {
                    hex += data.charCodeAt(i).toString(16).toUpperCase().padStart(2, "0") + " "
                }
                receiveText.text += hex
            } else {
                receiveText.text += data
            }
            if (autoScrollCheck.checked) {
                receiveFlick.contentY = receiveText.height - receiveFlick.height
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
