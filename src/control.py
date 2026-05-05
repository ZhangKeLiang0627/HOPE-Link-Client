from PySide6.QtCore import QObject, Slot
from PySide6.QtQml import QQmlComponent, QQmlEngine

import resources_rc

class ControlDialog(QObject):
    """Python backend for the Control dialog."""

    def __init__(self, engine: QQmlEngine, parent=None):
        super().__init__(parent)
        self._engine = engine
        self._component = None
        self._window = None

    @Slot()
    def show(self):
        """Create and show the Control dialog."""
        if self._window is not None:
            self._window.show()
            self._window.raise_()
            self._window.requestActivate()
            return

        if self._component is None:
            self._component = QQmlComponent(self._engine, "qrc:/qml/control.qml")
            self._component.statusChanged.connect(self._on_component_ready)

        # If component is already ready, create window immediately
        if self._component.status() == QQmlComponent.Status.Ready:
            self._create_window()
        elif self._component.status() == QQmlComponent.Status.Error:
            print(f"Control dialog component error: {self._component.errors()}")

    def _on_component_ready(self, status):
        if status == QQmlComponent.Status.Ready:
            self._create_window()
        elif status == QQmlComponent.Status.Error:
            print(f"Control dialog component error: {self._component.errors()}")

    def _create_window(self):
        self._window = self._component.create()
        if self._window is None:
            print(f"Failed to create Control dialog: {self._component.errors()}")
            return
        self._window.show()
        self._window.raise_()
        self._window.requestActivate()
