"""Compose the 1920x1080 promo thumbnails in docs/thumbnails/.

    python tool/make_thumbnails.py

Needs docs/screenshots/*.png (tool/capture_screenshots.py) and
assets/brand/logo.png (tool/make_logo.py). Pages are plain HTML rendered with
Playwright, with every image and font embedded, so the output is reproducible.
Writes cardvault-thumb-1-hero.png, -2-devices.png, -3-gallery.png.
"""
import base64
import glob
import io
import os

from PIL import Image
from playwright.sync_api import sync_playwright

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, 'docs', 'screenshots')
OUT = os.path.join(ROOT, 'docs', 'thumbnails')

TAGLINE = 'Your cards, privately held.'
BLURB = 'A private card organiser with a layered deck, real bank themes and an encrypted vault that never leaves your device.'


def data_uri(path, max_w=1000, fmt='JPEG'):
    """Downscale + embed an image (keeps the HTML small)."""
    with Image.open(path) as im:
        im = im.convert('RGB')
        if im.width > max_w:
            im = im.resize((max_w, round(im.height * max_w / im.width)), Image.LANCZOS)
        buf = io.BytesIO()
        im.save(buf, fmt, quality=95, subsampling=0)
    mime = 'image/jpeg' if fmt == 'JPEG' else 'image/png'
    return f'data:{mime};base64,' + base64.b64encode(buf.getvalue()).decode()


def logo_uri():
    with open(os.path.join(ROOT, 'assets', 'brand', 'logo.png'), 'rb') as f:
        return 'data:image/png;base64,' + base64.b64encode(f.read()).decode()


def font_face(family, rel, weight='100 900'):
    with open(os.path.join(ROOT, rel), 'rb') as f:
        b64 = base64.b64encode(f.read()).decode()
    return (f"@font-face{{font-family:'{family}';font-weight:{weight};"
            f"src:url(data:font/ttf;base64,{b64}) format('truetype');}}")


def shot(name, **kw):
    return data_uri(os.path.join(SHOTS, name + '.png'), **kw)


GOLD, GOLD_LIGHT, GOLD_DEEP = '#D6B779', '#EBD3A0', '#9C7F44'

CSS = '''
* { box-sizing: border-box; margin: 0; }
html, body { width: 1920px; height: 1080px; overflow: hidden; }
body {
  font-family: Inter, "Segoe UI", Arial, sans-serif; color: #F5F5F5; position: relative;
  background:
    radial-gradient(900px 700px at 78% 30%, rgba(214,183,121,0.20), transparent 60%),
    radial-gradient(700px 600px at 8% 95%, rgba(91,107,140,0.16), transparent 60%),
    linear-gradient(135deg, #050608 0%, #0d0f13 45%, #1b1e25 100%);
}
/* faint ledger grid, echoing the app's glass panels */
body::before {
  content: ""; position: absolute; inset: 0;
  background-image:
    linear-gradient(rgba(255,255,255,0.04) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255,255,255,0.04) 1px, transparent 1px);
  background-size: 96px 64px;
  -webkit-mask-image: linear-gradient(135deg, transparent 5%, #000 55%, #000 100%);
  mask-image: linear-gradient(135deg, transparent 5%, #000 55%, #000 100%);
}
.abs { position: absolute; }
.glow { position: absolute; border-radius: 50%; filter: blur(30px); pointer-events: none; }
.vig { position: absolute; inset: 0; background: radial-gradient(1400px 900px at 60% 50%, transparent 55%, rgba(0,0,0,.35) 100%); pointer-events: none; }
.spark { position: absolute; width: 56px; height: 56px; }
.logo { border-radius: 24%; box-shadow: 0 18px 50px rgba(0,0,0,.55), 0 0 60px rgba(214,183,121,.28); }
h1 { font-family: "Playfair Display", Georgia, serif; font-weight: 700; letter-spacing: -2px; line-height: 1; }
h1 b { font-weight: 700; background: linear-gradient(135deg, #F0D9A6, #D6B779 55%, #B08F4E);
  -webkit-background-clip: text; background-clip: text; color: transparent; }
.tag { color: #EBD3A0; font-weight: 700; }
.blurb { color: rgba(245,245,245,.72); line-height: 1.4; }
.pills { display: flex; flex-wrap: wrap; gap: 14px; width: 700px; }
.pill {
  display: inline-flex; align-items: center; gap: 12px; padding: 10px 22px;
  border-radius: 999px; border: 2px solid rgba(255,255,255,.16);
  background: rgba(255,255,255,.06); font-size: 26px; font-weight: 600;
}
.pill i { width: 12px; height: 12px; border-radius: 50%; background: #D6B779; display: block; }
.chip { display: inline-flex; align-items: center; gap: 12px; padding: 12px 26px;
  border-radius: 999px; background: linear-gradient(135deg, #EBD3A0, #D6B779 55%, #9C7F44); color: #0B0C10; font-weight: 800; font-size: 26px; white-space: nowrap; }
.chip i { width: 12px; height: 12px; border-radius: 50%; background: #0B0C10; display: block; }
.plat { white-space: nowrap; font-size: 25px; font-weight: 600; color: rgba(245,245,245,.7); letter-spacing: .5px; }
.phone {
  position: absolute; background: #0a0a0c; border-radius: 68px; padding: 14px;
  box-shadow: 0 0 0 3px #3a3d45, 0 40px 90px rgba(0,0,0,.65), 0 0 0 1px #000 inset;
}
.phone .scr { position: relative; border-radius: 54px; overflow: hidden; background: #08090B; width: 100%; height: 100%; padding-top: 46px; }
.phone img { width: 100%; height: 100%; object-fit: cover; object-position: top; display: block; }
.phone .notch { position: absolute; top: 14px; left: 50%; transform: translateX(-50%);
  width: 32%; height: 26px; background: #000; border-radius: 99px; z-index: 2; }
.laptop-screen {
  position: absolute; background: #0a0a0c; border-radius: 26px; padding: 14px;
  box-shadow: 0 0 0 3px #3a3d45, 0 40px 90px rgba(0,0,0,.6);
}
.laptop-screen img { width: 100%; height: 100%; object-fit: cover; object-position: top left; display: block; border-radius: 12px; }
.laptop-base { position: absolute; height: 22px; border-radius: 0 0 26px 26px;
  background: linear-gradient(#4a4d55, #22242a); box-shadow: 0 30px 50px rgba(0,0,0,.5); }
.card {
  position: absolute; display: flex; align-items: center; gap: 22px; padding: 22px 34px 22px 22px;
  border-radius: 28px; background: rgba(20,22,28,.93); border: 2px solid rgba(255,255,255,.13);
  box-shadow: 0 24px 60px rgba(0,0,0,.55); z-index: 5; backdrop-filter: blur(6px);
}
.card .ic { width: 78px; height: 78px; border-radius: 20px; display: grid; place-items: center; }
.card small { display: block; font-size: 26px; color: rgba(245,245,245,.6); letter-spacing: .5px; }
.card strong { display: block; font-size: 42px; font-weight: 800; letter-spacing: -.5px; }
'''

SPARK = ('<svg class="spark" style="{s}" viewBox="0 0 100 100"><path d="M50 2 C54 38 62 46 98 50 '
         'C62 54 54 62 50 98 C46 62 38 54 2 50 C38 46 46 38 50 2 Z" fill="#D6B779" opacity=".9"/></svg>')


def icon(path, stroke='#0B0C10', size=46):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{stroke}" stroke-width="2.6" '
            f'stroke-linecap="round" stroke-linejoin="round">{path}</svg>')


ICON_BACKUP = icon('<path d="M7 18a4.5 4.5 0 0 1-.6-8.96A6 6 0 0 1 18 8.5a4 4 0 0 1-.5 8"/><path d="M12 12v8M9 15l3-3 3 3"/>')
ICON_LOCK = icon('<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>')
ICON_OFFLINE = icon('<path d="M2 8.8a15 15 0 0 1 4-2.6M22 8.8a15 15 0 0 0-9-3.7M5 12.9a10 10 0 0 1 3.4-2M19 12.9a10 10 0 0 0-4-2.3M8.5 16.4a5 5 0 0 1 7 0"/><path d="M12 20h.01M3 3l18 18"/>')
ICON_LAYERS = icon('<path d="M12 3l9 5-9 5-9-5z"/><path d="M3 13l9 5 9-5"/>')


def card(style, ic, bg, small, strong):
    return (f'<div class="card" style="{style}"><div class="ic" style="background:{bg}">{ic}</div>'
            f'<div><small>{small}</small><strong>{strong}</strong></div></div>')


GOLD_BG = 'linear-gradient(135deg,#EBD3A0,#D6B779 55%,#9C7F44)'


def phone(img, left, top, w, rot=0, z=1):
    """Phone whose screen keeps the screenshot's 1170:2532 aspect."""
    inner_w = w - 28
    h = round(inner_w * 2532 / 1170) + 28
    return (f'<div class="phone" style="left:{left}px;top:{top}px;width:{w}px;height:{h}px;'
            f'transform:rotate({rot}deg);z-index:{z}"><div class="scr"><div class="notch"></div>'
            f'<img src="{img}"></div></div>')


def left_block(t):
    return f'''
  <img class="logo abs" src="{logo_uri()}" style="left:110px;top:{t}px;width:170px;height:170px">
  <h1 class="abs" style="left:104px;top:{t + 190}px;font-size:140px;white-space:nowrap">Card<b>Vault</b></h1>
  <div class="tag abs" style="left:110px;top:{t + 360}px;font-size:44px;white-space:nowrap">{TAGLINE}</div>
  <div class="blurb abs" style="left:110px;top:{t + 440}px;width:860px;font-size:30px">{BLURB}</div>
  <div class="pills abs" style="left:110px;top:{t + 620}px">
    <span class="pill"><i></i>Layered card deck</span><span class="pill"><i></i>Real bank themes</span>
    <span class="pill"><i></i>AES-256 encrypted</span><span class="pill"><i></i>Backup &amp; restore</span>
  </div>
  <div class="abs" style="left:110px;top:{t + 785}px;display:flex;align-items:center;gap:24px">
    <span class="chip"><i></i>Built with Flutter</span>
    <span class="plat">Android &nbsp;·&nbsp; iOS &nbsp;·&nbsp; Windows &nbsp;·&nbsp; Web</span>
  </div>'''


def hero():
    return (
        '<div class="glow" style="left:1080px;top:140px;width:760px;height:760px;background:radial-gradient(circle,rgba(214,183,121,.30),transparent 65%)"></div>'
        + left_block(50)
        + SPARK.format(s='left:880px;top:250px;width:44px;height:44px')
        + SPARK.format(s='left:850px;top:975px;width:40px;height:40px')
        + SPARK.format(s='left:1840px;top:300px;width:44px;height:44px')
        + phone(shot('mobile-home'), 1000, 290, 360, rot=-9, z=1)
        + phone(shot('mobile-card-details'), 1500, 270, 360, rot=8, z=1)
        + phone(shot('mobile-card-deck'), 1230, 150, 430, rot=0, z=3)
        + card('left:960px;top:30px', ICON_BACKUP, GOLD_BG, 'Encrypted backup', 'Restore anywhere')
        + card('left:880px;top:900px', ICON_OFFLINE, '#6FCF97', '100% offline', 'No cloud')
        + '<div class="vig"></div>'
    )


def devices():
    return (
        left_block(50)
        + SPARK.format(s='left:760px;top:140px;width:44px;height:44px')
        + SPARK.format(s='left:1830px;top:70px;')
        + '<div class="laptop-screen" style="left:960px;top:200px;width:820px;height:560px">'
          f'<img src="{shot("desktop-home", max_w=1400)}"></div>'
        + '<div class="laptop-base" style="left:910px;top:760px;width:920px"></div>'
        + phone(shot('mobile-backup-restore'), 1560, 330, 330, rot=0, z=3)
        + card('left:1000px;top:860px', ICON_LOCK, GOLD_BG, 'Vault key', 'AES-256 · Keychain')
        + card('left:1060px;top:70px', ICON_LAYERS, GOLD_BG, 'Real bank themes', '45+ card styles')
    )


def gallery():
    specs = [
        ('mobile-welcome', 90, 520, 320, 0),
        ('mobile-card-deck', 440, 470, 330, 0),
        ('mobile-card-details', 780, 340, 360, 0),
        ('mobile-benefits', 1150, 470, 330, 0),
        ('mobile-security', 1500, 520, 320, 0),
    ]
    phones = ''.join(phone(shot(n), x, y, w, rot=r, z=1) for n, x, y, w, r in specs)
    return f'''
  <img class="logo abs" src="{logo_uri()}" style="left:640px;top:60px;width:130px;height:130px">
  <h1 class="abs" style="left:800px;top:64px;font-size:140px">Card<b>Vault</b></h1>
  <div class="tag abs" style="left:0;top:225px;width:1920px;text-align:center;font-size:54px">{TAGLINE}</div>
  {SPARK.format(s='left:120px;top:100px;')}
  {SPARK.format(s='left:1760px;top:200px;width:44px;height:44px')}
  {phones}'''


PAGES = {
    'cardvault-thumb-1-hero.png': hero,
    'cardvault-thumb-2-devices.png': devices,
    'cardvault-thumb-3-gallery.png': gallery,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    css = font_face('Playfair Display', 'assets/fonts/Playfair.ttf') + font_face('Inter', 'assets/fonts/Inter.ttf') + CSS
    with sync_playwright() as p:
        try:
            browser = p.chromium.launch()
        except Exception:
            exe = sorted(glob.glob(os.path.join(os.environ.get('LOCALAPPDATA', ''), 'ms-playwright',
                                                'chromium-*', 'chrome-win*', 'chrome.exe')))[-1]
            browser = p.chromium.launch(executable_path=exe)
        page = browser.new_page(viewport={'width': 1920, 'height': 1080})
        for name, build in PAGES.items():
            page.set_content(f'<html><head><meta charset="utf-8"><style>{css}</style></head><body>{build()}</body></html>')
            page.wait_for_timeout(700)
            path = os.path.join(OUT, name)
            page.screenshot(path=path)
            with Image.open(path) as im:
                assert im.size == (1920, 1080), im.size
            print('saved', path)
        browser.close()


if __name__ == '__main__':
    main()
