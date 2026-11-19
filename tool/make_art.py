"""Generates the in-app illustrations (hero cards, empty-state art, shield) as crisp vector -> PNG.
The logo and launcher icons come from tool/make_logo.py.

    python tool/make_art.py
"""
import os

from PIL import Image

import brand_svg as B

ROOT = B.ROOT
OUT = os.path.join(ROOT, 'assets', 'images')

HDFC = [(0, '#0B2A5B'), (.5, '#1C4C99'), (1, '#0A1F44')]
AXIS = [(0, '#3A0F1D'), (.5, '#6E1D31'), (1, '#1F0810')]
AMEX = [(0, '#E4E6E9'), (.5, '#B1B5BB'), (1, '#80858D')]
GOLD = [(0, B.GOLD_1), (.5, B.GOLD_2), (1, B.GOLD_3)]


def doc(w, h, inner):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}"><defs>{B.COMMON_DEFS}' \
           f'<radialGradient id="glow" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="{B.GOLD_2}" stop-opacity=".30"/><stop offset="1" stop-color="{B.GOLD_2}" stop-opacity="0"/></radialGradient>' \
           f'</defs>{inner}</svg>'


def hero():
    W, H = 1600, 1000
    cw, ch = 640, 404
    left = B.place(B.card_face('l', cw, ch, HDFC, bank='HDFC Bank', product='Regalia', network='VISA', texture='guilloche'), 470, 585, cw, ch, -12)
    right = B.place(B.card_face('r', cw, ch, AXIS, bank='Axis Bank', product='Magnus', network='MC', texture='brushed'), 1130, 575, cw, ch, 10)
    mid = B.place(B.card_face('c', cw + 60, ch + 38, AMEX, bank='American Express', product='Platinum', network='AMEX', texture='brushed', text='#1B1D21', light_texture=False),
                  800, 440, cw + 60, ch + 38, -1.5)
    inner = f'<ellipse cx="800" cy="500" rx="640" ry="430" fill="url(#glow)"/>{left}{right}{mid}'
    return doc(W, H, inner), W, H


def empty():
    W, H = 900, 600
    cw, ch = 560, 353
    ghosts = ''
    for i, (dy, op) in enumerate([(-58, .45), (-29, .75)]):
        ghosts += (f'<g transform="translate({(W - cw) / 2} {(H - ch) / 2 + dy})" filter="url(#drop-s)">'
                   f'<rect width="{cw}" height="{ch}" rx="30" fill="#fff" fill-opacity="{.04 * op:.3f}" stroke="#fff" stroke-opacity="{.16 * op:.3f}" stroke-width="2.5"/></g>')
    x0, y0 = (W - cw) / 2, (H - ch) / 2 + 22
    front = f'''<g transform="translate({x0} {y0})" filter="url(#drop)">
      <rect width="{cw}" height="{ch}" rx="30" fill="#14161C"/>
      <rect width="{cw}" height="{ch}" rx="30" fill="url(#sheen)" opacity=".7"/>
      <rect x="1.5" y="1.5" width="{cw - 3}" height="{ch - 3}" rx="29" fill="none" stroke="url(#goldv)" stroke-width="3" stroke-dasharray="16 12" stroke-linecap="round"/>
      <circle cx="{cw / 2}" cy="{ch / 2}" r="62" fill="{B.GOLD_2}" fill-opacity=".14" stroke="url(#goldv)" stroke-width="3.5"/>
      <path d="M{cw / 2 - 24} {ch / 2}h48M{cw / 2} {ch / 2 - 24}v48" stroke="{B.GOLD_1}" stroke-width="8" stroke-linecap="round"/>
    </g>'''
    inner = f'<ellipse cx="450" cy="310" rx="380" ry="250" fill="url(#glow)"/>{ghosts}{front}'
    return doc(W, H, inner), W, H


def shield():
    S = 700
    cx = S / 2
    outer = 'M350 70 L568 150 L568 330 C568 450 470 540 350 612 C230 540 132 450 132 330 L132 150 Z'
    inner = 'M350 110 L534 178 L534 330 C534 430 452 508 350 570 C248 508 166 430 166 330 L166 178 Z'
    lock = f'''<g transform="translate({cx} 360)">
      <rect x="-62" y="-6" width="124" height="96" rx="20" fill="url(#goldv)"/>
      <path d="M-36 -6 v-34 a36 36 0 0 1 72 0 v34" fill="none" stroke="url(#goldv)" stroke-width="22" stroke-linecap="round"/>
      <circle cx="0" cy="36" r="13" fill="#0E1015"/><rect x="-5.5" y="36" width="11" height="30" rx="5.5" fill="#0E1015"/>
      <rect x="-62" y="-6" width="124" height="96" rx="20" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="2"/>
    </g>'''
    inner_svg = f'''<ellipse cx="350" cy="350" rx="320" ry="320" fill="url(#glow)"/>
    <g filter="url(#drop)">
      <path d="{outer}" fill="url(#goldg)"/>
      <path d="{outer}" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="2.5"/>
    </g>
    <path d="{inner}" fill="#0E1015"/>
    <path d="{inner}" fill="url(#sheen)" opacity=".6"/>
    <path d="{inner}" fill="none" stroke="{B.GOLD_2}" stroke-opacity=".45" stroke-width="2"/>
    {lock}'''
    return doc(S, S, inner_svg), S, S


def save(name, build, out_w, crop=False):
    svg, w, h = build()
    img = B.render(svg, w, h, scale=1)
    if crop:  # trim empty margins (keeps the soft shadow) so the art fills its box in the app
        box = img.split()[3].point(lambda v: 255 if v > 60 else 0).getbbox()
        pad = 36
        img = img.crop((max(0, box[0] - pad), max(0, box[1] - pad), min(w, box[2] + pad), min(h, box[3] + pad)))
        w, h = img.size
    img = img.resize((out_w, round(h * out_w / w)), Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name), optimize=True)
    print('wrote', name, img.size)


def main():
    save('hero_cards.png', hero, 1200, crop=True)
    save('empty_vault.png', empty, 720)
    save('shield.png', shield, 520)


if __name__ == '__main__':
    main()
