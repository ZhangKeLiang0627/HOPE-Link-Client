import sys
import serial
import serial.tools.list_ports
from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


class SerialBridge(QObject):
    """Bridge between Python serial backend and QML frontend."""

    # Signals to notify QML
    portsChanged = Signal()
    connectedChanged = Signal()
    dataReceived = Signal(str)
    dataSent = Signal(str)
    statusMessageChanged = Signal()

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
            self._timer.start(50)  # Poll every 50ms
            self._set_status(f"已连接到 {device} @ {baud_rate} bps")
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

    # ---------- Internal methods ----------

    def _read_data(self):
        """Read available data from serial port (called by timer)."""
        if not self._connected or not self._serial_port:
            return
        try:
            if self._serial_port.in_waiting > 0:
                data = self._serial_port.read(self._serial_port.in_waiting)
                self._buffer += data
                # Try to decode as UTF-8, fallback to latin-1
                try:
                    text = self._buffer.decode("utf-8")
                    self._buffer = b""
                    self.dataReceived.emit(text)
                except UnicodeDecodeError:
                    # Incomplete multi-byte character, wait for more data
                    pass
        except Exception:
            pass

    def _set_status(self, msg):
        self._status_message = msg
        self.statusMessageChanged.emit()


def main():
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    bridge = SerialBridge()
    engine.rootContext().setContextProperty("serialBridge", bridge)

    engine.load("main.qml")

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
