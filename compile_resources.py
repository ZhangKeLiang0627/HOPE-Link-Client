"""
Resource Compiler Script
Compiles resources.qrc into resources_rc.py using PySide6's rcc tool.

Usage:
    python compile_resources.py          # Compile resources.qrc -> resources_rc.py
    python compile_resources.py --clean   # Remove the generated resources_rc.py
"""

import os
import sys
import subprocess

# Paths
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
QRC_FILE = os.path.join(ROOT_DIR, "resources.qrc")
OUTPUT_FILE = os.path.join(ROOT_DIR, "resources_rc.py")


def compile_resources():
    """Compile resources.qrc into resources_rc.py using pyside6-rcc."""
    if not os.path.exists(QRC_FILE):
        print(f"[ERROR] QRC file not found: {QRC_FILE}")
        sys.exit(1)

    print(f"[INFO] Compiling: {QRC_FILE}")
    print(f"[INFO] Output:    {OUTPUT_FILE}")

    try:
        result = subprocess.run(
            ["pyside6-rcc", QRC_FILE, "-o", OUTPUT_FILE],
            capture_output=True,
            text=True,
            cwd=ROOT_DIR,
        )
        if result.returncode != 0:
            print(f"[ERROR] Compilation failed:")
            print(result.stderr)
            sys.exit(1)
        print(f"[SUCCESS] Compiled successfully -> {OUTPUT_FILE}")
    except FileNotFoundError:
        print("[ERROR] 'pyside6-rcc' not found. Make sure PySide6 is installed.")
        print("        Try: pip install PySide6")
        sys.exit(1)


def clean():
    """Remove the generated resources_rc.py file."""
    if os.path.exists(OUTPUT_FILE):
        os.remove(OUTPUT_FILE)
        print(f"[INFO] Removed: {OUTPUT_FILE}")
    else:
        print(f"[INFO] File not found, nothing to clean: {OUTPUT_FILE}")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--clean":
        clean()
    else:
        compile_resources()
