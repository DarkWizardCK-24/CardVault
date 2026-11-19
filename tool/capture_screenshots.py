"""Capture README / portfolio screenshots of CardVault.

    python tool/capture_screenshots.py            # renders the real app, then builds thumbnails
    python tool/capture_screenshots.py --thumbs-only

The screenshots come from test/screenshots_test.dart, which drives the real app (vault setup,
sample data, every major screen) on three viewports: phone 390x844 @3x, tablet 820x1180 @2x
and desktop 1440x900 @1.5x. Writes docs/screenshots/{mobile,tablet,desktop}-<screen>.png and a
small docs/screenshots/thumbs/<same name>.png for each (used by the README).
"""
import argparse
import glob
import os
import subprocess

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'docs', 'screenshots')
THUMBS = os.path.join(OUT, 'thumbs')
THUMB_WIDTH = {'mobile': 270, 'tablet': 330, 'desktop': 440}


def thumbs():
    os.makedirs(THUMBS, exist_ok=True)
    n = 0
    for path in sorted(glob.glob(os.path.join(OUT, '*.png'))):
        name = os.path.basename(path)
        w = THUMB_WIDTH[name.split('-')[0]]
        with Image.open(path) as im:
            im = im.convert('RGB')
            im.resize((w, round(im.height * w / im.width)), Image.LANCZOS).save(os.path.join(THUMBS, name), optimize=True)
        n += 1
    print(f'wrote {n} thumbnails to docs/screenshots/thumbs')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--thumbs-only', action='store_true')
    args = ap.parse_args()
    if not args.thumbs_only:
        subprocess.run(['flutter', 'test', 'test/screenshots_test.dart', '--update-goldens'], cwd=ROOT, check=True, shell=os.name == 'nt')
    thumbs()


if __name__ == '__main__':
    main()
