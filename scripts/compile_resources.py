"""Resource Compiler Script
Compiles resources.qrc into resources_rc.py using PySide6's rcc tool.

Usage:
    conda activate pyside6
    python scripts/compile_resources.py          # Compile resources.qrc -> resources_rc.py
    python scripts/compile_resources.py --clean   # Remove the generated resources_rc.py
"""

import sys
import subprocess
from pathlib import Path

# Paths
ROOT_DIR = Path(__file__).resolve().parent.parent
QRC_FILE = ROOT_DIR / "resources.qrc"
OUTPUT_FILE = ROOT_DIR / "resources_rc.py"


def compile_resources():
    """Compile resources.qrc into resources_rc.py using pyside6-rcc."""
    if not QRC_FILE.is_file():
        print(f"[ERROR] QRC file not found: {QRC_FILE}")
        sys.exit(1)

    print(f"[INFO] Compiling: {QRC_FILE}")
    print(f"[INFO] Output:    {OUTPUT_FILE}")

    try:
        result = subprocess.run(
            ["pyside6-rcc", str(QRC_FILE), "-o", str(OUTPUT_FILE)],
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
    if OUTPUT_FILE.is_file():
        OUTPUT_FILE.unlink()
        print(f"[INFO] Removed: {OUTPUT_FILE}")
    else:
        print(f"[INFO] File not found, nothing to clean: {OUTPUT_FILE}")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--clean":
        clean()
    else:
        compile_resources()
