"""Subset the ZCOOL KuaiLe font down to the glyphs the wordmark needs.

Input : docs/icon/fonts/ZCOOLKuaiLe-Regular.ttf   (1.48 MB, OFL)
Output: assets/fonts/TiebananaWordmark.ttf           (a few KB)

The splash wordmark only ever renders "Tiebanana", so shipping the whole CJK
face (1.5 MB) for a short Latin wordmark is not worth it. Re-run this after any
change to the wordmark text.

    py -3 docs/icon/subset_wordmark_font.py
"""
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent

SRC = HERE / "fonts" / "ZCOOLKuaiLe-Regular.ttf"
LICENSE = HERE / "fonts" / "OFL.txt"
OUT_DIR = ROOT / "assets" / "fonts"
OUT = OUT_DIR / "TiebananaWordmark.ttf"

# Keep both cases so the wordmark can be re-cased without re-subsetting.
TEXT = "TiebananaTIEBANANA"


def main():
    if not SRC.exists():
        sys.exit(f"missing {SRC}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            sys.executable, "-m", "fontTools.subset", str(SRC),
            f"--text={TEXT}",
            "--layout-features=*",
            "--name-IDs=*",
            "--flavor=",
            f"--output-file={OUT}",
        ],
        check=True,
    )
    # OFL requires the licence to travel with the font.
    shutil.copyfile(LICENSE, OUT_DIR / "TiebananaWordmark-LICENSE.txt")
    print(f"wrote {OUT} ({OUT.stat().st_size} bytes, from {SRC.stat().st_size})")


main()
