import sys
import serial
import serial.tools.list_ports
from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer, QByteArray
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from about import AboutDialog
from settings import SettingsDialog
from control import ControlDialog


# OLED 参数
OLED_WIDTH = 128
OLED_HEIGHT = 64
OLED_PAGES = 8  # 64 / 8
OLED_BUFFER_SIZE = OLED_WIDTH * OLED_PAGES  # 1024

# UART 协议 (默认值)
PKG_HEADER = b'\xA5\xA5'
PKG_FOOTER = b'\x5A\x5A'


class SerialBridge(QObject):
    """Bridge between Python serial backend and QML frontend."""

    # Signals to notify QML
    portsChanged = Signal()
    connectedChanged = Signal()
    dataReceived = Signal(str)
    dataSent = Signal(str)
    statusMessageChanged = Signal()
    oledFrameReady = Signal(list)  # 发送 1024 字节像素数据列表
    pkgHeaderChanged = Signal()
    pkgFooterChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._serial_port = None
        self._connected = False
        self._ports = []
        self._baud_rates = [
            "9600", "19200", "38400", "57600",
            "115200", "230400", "460800", "921600"
        ]
        self._selected_port = ""
        self._selected_baud = "115200"
        self._status_message = "就绪"
        self._timer = QTimer(self)
        self._timer.timeout.connect(self._read_data)
        self._buffer = b""

        # OLED 协议解析状态机
        self._parse_state = 0
        self._oled_data = bytearray()
        self._oled_data_count = 0

        # 可自定义的包头包尾 (默认: A5 A5 / 5A 5A)
        self._pkg_header = PKG_HEADER  # bytes, 长度2
        self._pkg_footer = PKG_FOOTER  # bytes, 长度2

    # ---------- Properties exposed to QML ----------

    @Property(list, notify=portsChanged)
    def ports(self):
        return self._ports

    @Property(bool, notify=connectedChanged)
    def connected(self):
        return self._connected

    @Property(list, constant=True)
    def baudRates(self):
        return self._baud_rates

    @Property(str, notify=statusMessageChanged)
    def statusMessage(self):
        return self._status_message

    # ---------- 可自定义的包头包尾属性 ----------

    @Property(str, notify=pkgHeaderChanged)
    def pkgHeader(self):
        """返回包头十六进制字符串，如 'A5A5'"""
        return self._pkg_header.hex().upper()

    @pkgHeader.setter
    def pkgHeader(self, hex_str):
        """设置包头，hex_str 如 'A5A5' 或 'a5 a5'"""
        try:
            cleaned = hex_str.replace(" ", "").replace("\n", "").replace("\r", "")
            data = bytes.fromhex(cleaned)
            if len(data) != 2:
                self._set_status("包头必须是2个字节 (4个十六进制字符)")
                return
            self._pkg_header = data
            self.pkgHeaderChanged.emit()
            self._set_status(f"包头已更新: {data.hex().upper()}")
            # 重置解析状态
            self._parse_state = 0
            self._oled_data = bytearray()
            self._oled_data_count = 0
        except Exception as e:
            self._set_status(f"包头格式错误: {str(e)}")

    @Property(str, notify=pkgFooterChanged)
    def pkgFooter(self):
        """返回包尾十六进制字符串，如 '5A5A'"""
        return self._pkg_footer.hex().upper()

    @pkgFooter.setter
    def pkgFooter(self, hex_str):
        """设置包尾，hex_str 如 '5A5A' 或 '5a 5a'"""
        try:
            cleaned = hex_str.replace(" ", "").replace("\n", "").replace("\r", "")
            data = bytes.fromhex(cleaned)
            if len(data) != 2:
                self._set_status("包尾必须是2个字节 (4个十六进制字符)")
                return
            self._pkg_footer = data
            self.pkgFooterChanged.emit()
            self._set_status(f"包尾已更新: {data.hex().upper()}")
            # 重置解析状态
            self._parse_state = 0
            self._oled_data = bytearray()
            self._oled_data_count = 0
        except Exception as e:
            self._set_status(f"包尾格式错误: {str(e)}")

    # ---------- Slots callable from QML ----------

    @Slot()
    def refresh_ports(self):
        """Scan available serial ports and update the list."""
        port_list = serial.tools.list_ports.comports()
        self._ports = [f"{p.device} - {p.description}" for p in port_list]
        self.portsChanged.emit()
        self._set_status(f"扫描到 {len(self._ports)} 个串口")

    @Slot(str, str)
    def connect_port(self, port_info, baud_rate):
        """Connect to the selected serial port."""
        if self._connected:
            self._set_status("已连接，请先断开")
            return

        # Extract device name from "COM3 - Description" format
        device = port_info.split(" - ")[0] if " - " in port_info else port_info

        try:
            self._serial_port = serial.Serial(
                port=device,
                baudrate=int(baud_rate),
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=0.01
            )
            self._connected = True
            self.connectedChanged.emit()
            self._timer.start(10)  # Poll every 10ms for faster response
            self._set_status(f"已连接到 {device} @ {baud_rate} bps")
            # 重置协议解析状态
            self._parse_state = 0
            self._oled_data = bytearray()
            self._oled_data_count = 0
        except PermissionError:
            self._set_status(
                f"权限不足！请将用户加入 dialout 组:\n"
                f"  sudo usermod -a -G dialout $USER\n"
                f"然后注销重新登录"
            )
        except Exception as e:
            self._set_status(f"连接失败: {str(e)}")

    @Slot()
    def disconnect_port(self):
        """Disconnect from the serial port."""
        if self._timer.isActive():
            self._timer.stop()
        if self._serial_port and self._serial_port.is_open:
            try:
                self._serial_port.close()
            except Exception:
                pass
        self._serial_port = None
        self._connected = False
        self.connectedChanged.emit()
        self._set_status("已断开连接")

    @Slot(str)
    def send_data(self, data):
        """Send string data over the serial port."""
        if not self._connected or not self._serial_port:
            self._set_status("未连接，无法发送")
            return
        try:
            self._serial_port.write(data.encode("utf-8"))
            self.dataSent.emit(data)
        except Exception as e:
            self._set_status(f"发送失败: {str(e)}")

    @Slot(str)
    def send_hex_data(self, hex_str):
        """Send hex data (e.g. '01 02 FF') over the serial port."""
        if not self._connected or not self._serial_port:
            self._set_status("未连接，无法发送")
            return
        try:
            hex_str = hex_str.replace(" ", "").replace("\n", "").replace("\r", "")
            data = bytes.fromhex(hex_str)
            self._serial_port.write(data)
            self.dataSent.emit(hex_str.upper())
        except Exception as e:
            self._set_status(f"发送失败: {str(e)}")

    @Slot()
    def clear_buffer(self):
        """Clear the internal read buffer."""
        self._buffer = b""
        self._parse_state = 0
        self._oled_data = bytearray()
        self._oled_data_count = 0

    # ---------- Internal methods ----------

    def _parse_oled_packet(self, data):
        """解析 OLED 数据包，使用状态机处理流式数据。
        使用可配置的 self._pkg_header (2字节) 和 self._pkg_footer (2字节)。
        """
        h0, h1 = self._pkg_header[0], self._pkg_header[1]
        f0, f1 = self._pkg_footer[0], self._pkg_footer[1]

        for byte in data:
            b = bytes([byte])

            if self._parse_state == 0:
                # 等待包头的第一个字节
                if b == bytes([h0]):
                    self._parse_state = 1
                continue

            elif self._parse_state == 1:
                # 等待包头的第二个字节
                if b == bytes([h1]):
                    # 收到完整包头，准备接收数据
                    self._parse_state = 2
                    self._oled_data = bytearray()
                    self._oled_data_count = 0
                else:
                    # 不是预期的第二个字节，回到初始状态
                    self._parse_state = 0
                continue

            elif self._parse_state == 2:
                # 接收 OLED 数据
                self._oled_data.append(byte)
                self._oled_data_count += 1

                if self._oled_data_count == OLED_BUFFER_SIZE:
                    # 已经收满 1024 字节，接下来应该是包尾
                    self._parse_state = 3
                continue

            elif self._parse_state == 3:
                # 等待包尾的第一个字节
                if b == bytes([f0]):
                    self._parse_state = 4
                else:
                    # 包尾错误，重置
                    self._parse_state = 0
                    self._oled_data = bytearray()
                    self._oled_data_count = 0
                continue

            elif self._parse_state == 4:
                # 等待包尾的第二个字节
                if b == bytes([f1]):
                    # 完整包接收完成！
                    # 将像素数据转为列表发送给 QML
                    pixel_list = list(self._oled_data)
                    self.oledFrameReady.emit(pixel_list)
                    self._set_status(f"OLED 帧已更新 ({len(pixel_list)} bytes)")
                # 无论是否成功，重置状态机
                self._parse_state = 0
                self._oled_data = bytearray()
                self._oled_data_count = 0
                continue

    def _read_data(self):
        """Read available data from serial port (called by timer)."""
        if not self._connected or not self._serial_port:
            return
        try:
            if self._serial_port.in_waiting > 0:
                data = self._serial_port.read(self._serial_port.in_waiting)
                # 直接解析 OLED 协议包
                self._parse_oled_packet(data)
        except Exception:
            pass

    def _set_status(self, msg):
        self._status_message = msg
        self.statusMessageChanged.emit()


def main():
    app = QGuiApplication(sys.argv)
    app.setWindowIcon(QIcon("image-0.png"))
    engine = QQmlApplicationEngine()

    # Keep strong references to prevent garbage collection
    # PySide6 context properties can be garbage collected if not properly referenced
    bridge = SerialBridge()
    engine.rootContext().setContextProperty("serialBridge", bridge)

    # Register dialog objects
    about_dialog = AboutDialog(engine)
    engine.rootContext().setContextProperty("aboutDialog", about_dialog)

    settings_dialog = SettingsDialog(engine)
    engine.rootContext().setContextProperty("settingsDialog", settings_dialog)

    control_dialog = ControlDialog(engine)
    engine.rootContext().setContextProperty("controlDialog", control_dialog)

    # Store references on the engine to prevent garbage collection
    engine._bridge = bridge
    engine._about_dialog = about_dialog
    engine._settings_dialog = settings_dialog
    engine._control_dialog = control_dialog

    engine.load("main.qml")

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
