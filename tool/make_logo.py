"""Generate the CardVault logo (SVG + PNG) and the platform app icons.

    python tool/make_logo.py

Writes assets/brand/:
  logo.svg / logo.png            rounded tile, transparent corners (logo.png is 512x512)
  icon-full.png                  full-bleed square, no transparency (1024px master
                                 used to cut the launcher icons)
  logo-horizontal.svg / .png     tile + "CardVault" wordmark
  logo-named.svg / .png          512x512 tile with the name under the mark
Also writes assets/images/logo_256.png (used inside the app) and overwrites the
launcher icons for Android, iOS, web and Windows, keeping each file's pixel size.
"""
import glob
import os

from PIL import Image

import brand_svg as B

ROOT = B.ROOT
BRAND = os.path.join(ROOT, 'assets', 'brand')

NAVY = [(0, '#2A5FB8'), (.5, '#16397A'), (1, '#0A1F44')]
WINE = [(0, '#9A2A40'), (.5, '#63192B'), (1, '#2D0A13')]
GOLD = [(0, B.GOLD_1), (.5, B.GOLD_2), (1, B.GOLD_3)]


def tile(rounded=True, rim=True, zoom=1.0, background=True, scene=True):
    """The mark: a layered deck (navy, burgundy, champagne gold) with a padlock badge on an obsidian tile.

    zoom > 1 enlarges the deck and re-centres it (its bounding box is ~x 88..452, y 62..434),
    which is what the launcher icons use so the artwork fills the icon instead of floating in it.
    """
    rx = 112 if rounded else 0
    back = B.place(B.card_face('b', 288, 182, NAVY, texture='guilloche', detail='icon'), 262, 168, 288, 182, -6, 'drop-s')
    mid = B.place(B.card_face('m', 312, 197, WINE, texture='brushed', detail='icon'), 258, 222, 312, 197, -2.5, 'drop-s')
    front = B.place(B.card_face('f', 336, 212, GOLD, texture='guilloche', text='#2A1D05', detail='icon', light_texture=False), 256, 282, 336, 212, 0, 'drop')
    badge = '''
  <g transform="translate(392 374)" filter="url(#drop)">
    <circle r="60" fill="#0B0C10"/>
    <circle r="52" fill="none" stroke="url(#goldv)" stroke-width="5.5"/>
    <rect x="-25" y="-3" width="50" height="38" rx="9" fill="url(#goldv)"/>
    <path d="M-14 -3 v-13 a14 14 0 0 1 28 0 v13" fill="none" stroke="url(#goldv)" stroke-width="8.5" stroke-linecap="round"/>
    <circle cx="0" cy="13" r="5.6" fill="#0B0C10"/><rect x="-2.3" y="13" width="4.6" height="12" rx="2.3" fill="#0B0C10"/>
  </g>'''
    deck = f'''<ellipse cx="256" cy="414" rx="170" ry="13" fill="#000" opacity=".55" filter="url(#blur8)"/>
  {back}{mid}{front}{badge}'''
    if zoom != 1.0:
        deck = f'<g transform="translate(256 256) scale({zoom}) translate(-270 -248)">{deck}</g>'
    if not scene:
        deck = ''
    rim_el = (f'<rect x="3" y="3" width="506" height="506" rx="{max(rx - 3, 0)}" fill="none" stroke="url(#rim)" stroke-width="6"/>'
              if rim else '')
    bg_el = f'''<rect width="512" height="512" rx="{rx}" fill="url(#bg)"/>
  <g clip-path="url(#tile)">
    <circle cx="420" cy="60" r="300" fill="url(#glowG)"/>
    <circle cx="30" cy="510" r="290" fill="url(#glowB)"/>
  </g>
  {rim_el}''' if background else ''
    return f'''
  <defs>
    {B.COMMON_DEFS}
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#20232B"/><stop offset=".5" stop-color="#0C0D11"/><stop offset="1" stop-color="#08090B"/></linearGradient>
    <linearGradient id="rim" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".42"/><stop offset=".35" stop-color="#fff" stop-opacity=".06"/><stop offset="1" stop-color="#fff" stop-opacity=".02"/></linearGradient>
    <radialGradient id="glowG" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="{B.GOLD_2}" stop-opacity=".50"/><stop offset="1" stop-color="{B.GOLD_2}" stop-opacity="0"/></radialGradient>
    <radialGradient id="glowB" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#4A66A8" stop-opacity=".40"/><stop offset="1" stop-color="#4A66A8" stop-opacity="0"/></radialGradient>
    <clipPath id="tile"><rect width="512" height="512" rx="{rx}"/></clipPath>
  </defs>
  {bg_el}
  <!-- scene -->
  {deck}'''


def svg(rounded=True, **kw):
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">' + tile(rounded, **kw) + '</svg>'


# Launcher-icon variants: square, no rim stroke, deck enlarged to fill the tile.
ICON_ZOOM = 1.12      # iOS / legacy Android / web: platform applies its own corner mask
ADAPTIVE_ZOOM = 0.68  # Android adaptive foreground: keep the deck inside the 66/108 safe zone


def named_svg():
    """Square tile with the mark scaled up top and the name beneath it."""
    t = tile(True)
    i = t.index('  <!-- scene -->')
    head, scene = t[:i], t[i:]
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">' + head
            + '<defs><linearGradient id="wm2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="%s"/>'
              '<stop offset="0.55" stop-color="%s"/><stop offset="1" stop-color="#B08F4E"/></linearGradient></defs>' % (B.GOLD_1, B.GOLD_2)
            + '<g transform="translate(60 -10) scale(.765)">' + scene + '</g>'
            + "<text x='256' y='426' text-anchor='middle' font-family=\"'Playfair Display', Georgia, serif\" font-weight='700' font-size='82' letter-spacing='-1'>"
              "<tspan fill='#F5F5F5'>Card</tspan><tspan fill='url(#wm2)'>Vault</tspan></text>"
            + "<text x='256' y='466' text-anchor='middle' font-family=\"Inter, 'Segoe UI', Arial, sans-serif\" font-weight='600' font-size='16' letter-spacing='6' fill='#969BA5'>PRIVATE · OFFLINE · SECURE</text>"
            + '</svg>')


def horizontal_svg():
    """Tile + wordmark on its own dark plate, so it reads on any background."""
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1800 512" width="1800" height="512">
  <defs>
    <linearGradient id="wm" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{B.GOLD_1}"/><stop offset="0.55" stop-color="{B.GOLD_2}"/><stop offset="1" stop-color="#B08F4E"/>
    </linearGradient>
  </defs>
  <rect width="1800" height="512" rx="112" fill="#0B0C10"/>
  <rect x="3" y="3" width="1794" height="506" rx="109" fill="none" stroke="#fff" stroke-opacity="0.10" stroke-width="6"/>
  <g>{tile(True)}</g>
  <text x="590" y="318" font-family="'Playfair Display', Georgia, serif" font-weight="700" font-size="200" letter-spacing="-2">
    <tspan fill="#F5F5F5">Card</tspan><tspan fill="url(#wm)">Vault</tspan>
  </text>
  <text x="596" y="396" font-family="Inter, 'Segoe UI', Arial, sans-serif" font-weight="600" font-size="38" letter-spacing="9" fill="#969BA5">PRIVATE · OFFLINE · SECURE</text>
</svg>'''


def main():
    os.makedirs(BRAND, exist_ok=True)
    open(os.path.join(BRAND, 'logo.svg'), 'w', encoding='utf8').write(svg(True))
    open(os.path.join(BRAND, 'logo-horizontal.svg'), 'w', encoding='utf8').write(horizontal_svg())
    open(os.path.join(BRAND, 'logo-named.svg'), 'w', encoding='utf8').write(named_svg())
    logo = B.render(svg(True), 512, 512, scale=2)  # 1024px
    # Icon masters: square, rim-less, deck enlarged so it fills the launcher icon.
    full = B.render(svg(False, rim=False, zoom=ICON_ZOOM), 512, 512, transparent=False, scale=2).convert('RGB')
    rounded_icon = B.render(svg(True, rim=False, zoom=ICON_ZOOM), 512, 512, scale=2)
    adaptive_bg = B.render(svg(False, rim=False, scene=False), 512, 512, transparent=False, scale=2).convert('RGB')
    adaptive_fg = B.render(svg(False, background=False, zoom=ADAPTIVE_ZOOM), 512, 512, scale=2)
    wide = B.render(horizontal_svg(), 1800, 512)
    named = B.render(named_svg(), 512, 512, scale=2)

    logo.resize((512, 512), Image.LANCZOS).save(os.path.join(BRAND, 'logo.png'), optimize=True)
    full.save(os.path.join(BRAND, 'icon-full.png'), optimize=True)
    wide.save(os.path.join(BRAND, 'logo-horizontal.png'), optimize=True)
    named.resize((512, 512), Image.LANCZOS).save(os.path.join(BRAND, 'logo-named.png'), optimize=True)
    os.makedirs(os.path.join(ROOT, 'assets', 'images'), exist_ok=True)
    logo.resize((256, 256), Image.LANCZOS).save(os.path.join(ROOT, 'assets', 'images', 'logo_256.png'), optimize=True)
    print('wrote assets/brand/* and assets/images/logo_256.png')

    # --- launcher icons: same file names/sizes as the existing ones ---------
    targets = []
    targets += glob.glob(os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res', 'mipmap-*', 'ic_launcher.png'))
    targets += glob.glob(os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset', '*.png'))
    targets += glob.glob(os.path.join(ROOT, 'web', 'icons', '*.png'))
    targets += [os.path.join(ROOT, 'web', 'favicon.png')]
    count = 0
    for path in targets:
        if not os.path.exists(path):
            continue
        with Image.open(path) as old:
            w, h = old.size
        norm = path.replace('\\', '/')
        if 'maskable' in os.path.basename(path):
            canvas = Image.new('RGB', (w, h), (8, 9, 11))
            inner = int(w * 0.8)  # keep the mark inside the maskable safe zone
            canvas.paste(full.resize((inner, inner), Image.LANCZOS), ((w - inner) // 2, (h - inner) // 2))
            out = canvas
        elif '/ios/' in norm:
            out = full.resize((w, h), Image.LANCZOS)  # iOS icons must not have transparency
        elif '/android/' in norm:
            out = full.resize((w, h), Image.LANCZOS)  # legacy (pre-API 26) launchers apply their own mask
        else:
            out = rounded_icon.resize((w, h), Image.LANCZOS)
        out.save(path)
        count += 1

    # --- Android adaptive icon (API 26+): background + foreground layers --------
    res = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
    if os.path.isdir(res):
        for density, px in {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}.items():
            d = os.path.join(res, f'mipmap-{density}')
            os.makedirs(d, exist_ok=True)
            adaptive_bg.resize((px, px), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_background.png'), optimize=True)
            adaptive_fg.resize((px, px), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_foreground.png'), optimize=True)
            count += 2
        anydpi = os.path.join(res, 'mipmap-anydpi-v26')
        os.makedirs(anydpi, exist_ok=True)
        xml = ('<?xml version="1.0" encoding="utf-8"?>\n'
               '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
               '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
               '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
               '</adaptive-icon>\n')
        open(os.path.join(anydpi, 'ic_launcher.xml'), 'w', encoding='utf8').write(xml)

    ico_path = os.path.join(ROOT, 'windows', 'runner', 'resources', 'app_icon.ico')
    if os.path.exists(ico_path):
        rounded_icon.resize((256, 256), Image.LANCZOS).save(ico_path, sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
        count += 1
    print(f'updated {count} platform icon files')


if __name__ == '__main__':
    main()
