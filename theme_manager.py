from PySide6.QtCore import QObject, Signal, Slot, Property


class ThemeManager(QObject):
    """Shared theme manager that syncs dark/light mode across all windows."""

    # Signal to notify all QML windows when theme changes
    themeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._is_dark = True  # Default to dark theme

    @Property(bool, notify=themeChanged)
    def isDark(self):
        return self._is_dark

    @isDark.setter
    def isDark(self, value):
        if self._is_dark != value:
            self._is_dark = value
            self.themeChanged.emit()

    @Slot()
    def toggle(self):
        """Toggle between dark and light theme."""
        self.isDark = not self._is_dark

    @Slot(bool)
    def setTheme(self, dark):
        """Set theme explicitly."""
        self.isDark = dark
