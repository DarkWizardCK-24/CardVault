"""Shared SVG building blocks for CardVault's logo and illustrations (rendered with Playwright).

Everything is vector, so it stays crisp at any size. Card faces mimic the app's CardFront widget:
gradient body, texture, sheen, chip, contactless arcs, number, holder, network mark.
"""
import base64
import glob
import io
import math
import os

from PIL import Image
from playwright.sync_api import sync_playwright

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

GOLD_1, GOLD_2, GOLD_3 = '#F0D9A6', '#D6B779', '#9C7F44'


def _b64(rel):
    with open(os.path.join(ROOT, rel), 'rb') as f:
        return base64.b64encode(f.read()).decode()


def font_css():
    return (f"@font-face{{font-family:'Playfair Display';font-weight:400 900;src:url(data:font/ttf;base64,{_b64('assets/fonts/Playfair.ttf')}) format('truetype');}}"
            f"@font-face{{font-family:'Inter';font-weight:100 900;src:url(data:font/ttf;base64,{_b64('assets/fonts/Inter.ttf')}) format('truetype');}}")


def card_defs(uid, stops):
    """Gradients for one card (ids are namespaced by uid)."""
    st = ''.join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return (f'<linearGradient id="cg-{uid}" x1="0" y1="0" x2="1" y2="1">{st}</linearGradient>')


COMMON_DEFS = f'''
<linearGradient id="chipg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F6E3AA"/><stop offset=".5" stop-color="#C9A24F"/><stop offset="1" stop-color="#EBD28B"/></linearGradient>
<linearGradient id="sheen" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".30"/><stop offset=".42" stop-color="#fff" stop-opacity="0"/><stop offset=".58" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".26"/></linearGradient>
<linearGradient id="goldg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{GOLD_1}"/><stop offset=".5" stop-color="{GOLD_2}"/><stop offset="1" stop-color="{GOLD_3}"/></linearGradient>
<linearGradient id="goldv" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F6E3AA"/><stop offset=".55" stop-color="#D6B779"/><stop offset="1" stop-color="#9C7F44"/></linearGradient>
<filter id="drop" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="14" stdDeviation="14" flood-color="#000" flood-opacity=".6"/></filter>
<filter id="drop-s" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="8" stdDeviation="8" flood-color="#000" flood-opacity=".55"/></filter>
<filter id="blur20"><feGaussianBlur stdDeviation="20"/></filter>
<filter id="blur8"><feGaussianBlur stdDeviation="8"/></filter>
'''


def _texture(kind, w, h, light=True):
    col = '#fff' if light else '#000'
    out = []
    if kind == 'guilloche':
        u = h / 220
        for k in range(24):
            pts = []
            for x in range(0, int(w) + 8, 8):
                y = h * .62 + math.sin(x / w * math.pi * 3 + k * .38) * (h * .12 + k * 1.5 * u) + (k - 12) * 4 * u
                pts.append(f'{x:.1f},{y:.1f}')
            out.append(f'<polyline points="{" ".join(pts)}" fill="none" stroke="{col}" stroke-opacity=".055" stroke-width="{max(.8, u):.2f}"/>')
    elif kind == 'brushed':
        import random
        r = random.Random(7)
        for _ in range(110):
            y = r.random() * h
            c = '#fff' if r.random() > .4 else '#000'
            out.append(f'<line x1="0" y1="{y:.1f}" x2="{w}" y2="{y + r.random() * 3:.1f}" stroke="{c}" stroke-opacity="{.035 + r.random() * .035:.3f}"/>')
    elif kind == 'diagonal':
        step = h / 16
        x = -h
        while x < w:
            out.append(f'<line x1="{x:.1f}" y1="{h}" x2="{x + h:.1f}" y2="0" stroke="{col}" stroke-opacity=".06"/>')
            x += step
    return ''.join(out)


def _network(net, w, h, u, text):
    if net == 'VISA':
        return f'<text x="{w - 22 * u}" y="{h - 22 * u}" text-anchor="end" font-family="Inter" font-weight="900" font-style="italic" font-size="{26 * u}" letter-spacing="-1" fill="{text}">VISA</text>'
    if net == 'MC':
        r = 14 * u
        cx, cy = w - 40 * u, h - 22 * u - r
        return (f'<circle cx="{cx - r * .55}" cy="{cy}" r="{r}" fill="#EB001B"/><circle cx="{cx + r * .55}" cy="{cy}" r="{r}" fill="#F79E1B" fill-opacity=".92"/>')
    if net == 'AMEX':
        return (f'<rect x="{w - 76 * u}" y="{h - 46 * u}" width="{54 * u}" height="{24 * u}" rx="{3 * u}" fill="#006FCF"/>'
                f'<text x="{w - 49 * u}" y="{h - 28.5 * u}" text-anchor="middle" font-family="Inter" font-weight="900" font-size="{13 * u}" letter-spacing="1" fill="#fff">AMEX</text>')
    return ''


def card_face(uid, w, h, stops, *, bank='', product='', network='', texture='guilloche', text='#FFFFFF',
              last4='4321', holder='YOUR NAME', detail='full', light_texture=True):
    """One card face as an SVG group drawn at the origin (0,0)-(w,h)."""
    u = w / 340
    r = h * .075
    tex = _texture(texture, w, h, light_texture)
    chip_w, chip_h = 44 * u, 33 * u
    cx0, cy0 = 22 * u, 74 * u
    chip = (f'<rect x="{cx0}" y="{cy0}" width="{chip_w}" height="{chip_h}" rx="{6.5 * u}" fill="url(#chipg)" stroke="#8A6D2B" stroke-opacity=".6" stroke-width="{.8 * u}"/>'
            f'<path d="M{cx0} {cy0 + chip_h / 2}h{chip_w}M{cx0 + chip_w / 3} {cy0}v{chip_h}M{cx0 + chip_w * 2 / 3} {cy0}v{chip_h}" stroke="#8A6D2B" stroke-opacity=".55" stroke-width="{1.1 * u}" fill="none"/>'
            f'<rect x="{cx0 + chip_w * .3}" y="{cy0 + chip_h * .25}" width="{chip_w * .4}" height="{chip_h * .5}" rx="{3 * u}" fill="none" stroke="#8A6D2B" stroke-opacity=".55" stroke-width="{1.1 * u}"/>')
    ax, ay = w - 38 * u, 34 * u
    arcs = ''.join(
        f'<path d="M{ax + i * 8 * u} {ay - (7 + i * 7) * u}a{(7 + i * 7) * u} {(7 + i * 7) * u} 0 0 1 0 {(14 + i * 14) * u}" fill="none" stroke="{text}" stroke-opacity=".88" stroke-width="{2.4 * u}" stroke-linecap="round"/>'
        for i in range(3))
    if detail == 'icon':
        dots = ''.join(f'<circle cx="{(22 + g * 64 + d * 14 + 3) * u}" cy="{h - 78 * u}" r="{4.2 * u}" fill="{text}" fill-opacity=".9"/>' for g in range(3) for d in range(4) if g < 2 or d < 2)
        body = (dots
                + f'<rect x="{22 * u}" y="{h - 52 * u}" width="{96 * u}" height="{9 * u}" rx="{4.5 * u}" fill="{text}" fill-opacity=".55"/>'
                + f'<rect x="{22 * u}" y="{h - 36 * u}" width="{60 * u}" height="{7 * u}" rx="{3.5 * u}" fill="{text}" fill-opacity=".32"/>')
        head = ''
    else:
        head = (f'<text x="{22 * u}" y="{35 * u}" font-family="Inter" font-weight="800" font-size="{13 * u}" letter-spacing="{1.4 * u}" fill="{text}">{bank.upper()}</text>'
                f'<text x="{22 * u}" y="{52 * u}" font-family="Inter" font-weight="500" font-size="{11 * u}" fill="{text}" fill-opacity=".75">{product}</text>')
        body = (f'<text x="{22 * u}" y="{h - 62 * u}" font-family="Inter" font-weight="600" font-size="{19 * u}" letter-spacing="{2.2 * u}" fill="{text}">•••• •••• •••• {last4}</text>'
                f'<text x="{22 * u}" y="{h - 38 * u}" font-family="Inter" font-weight="600" font-size="{11.5 * u}" letter-spacing="{u}" fill="{text}">{holder}</text>'
                f'<text x="{22 * u}" y="{h - 22 * u}" font-family="Inter" font-weight="500" font-size="{9.5 * u}" letter-spacing=".8" fill="{text}" fill-opacity=".68">VALID THRU  08/29</text>'
                + _network(network, w, h, u, text))
    return (f'<defs>{card_defs(uid, stops)}<clipPath id="cc-{uid}"><rect width="{w}" height="{h}" rx="{r}"/></clipPath></defs>'
            f'<g clip-path="url(#cc-{uid})"><rect width="{w}" height="{h}" fill="url(#cg-{uid})"/>{tex}'
            f'<rect width="{w}" height="{h}" fill="url(#sheen)"/>{head}{chip}{arcs}{body}</g>'
            f'<rect x=".5" y=".5" width="{w - 1}" height="{h - 1}" rx="{r}" fill="none" stroke="#fff" stroke-opacity=".28" stroke-width="{max(1.2, 1.2 * u)}"/>')


def place(card_svg, cx, cy, w, h, rot=0, filt='drop'):
    return (f'<g transform="translate({cx} {cy}) rotate({rot})" filter="url(#{filt})"><g transform="translate({-w / 2} {-h / 2})">{card_svg}</g></g>')


# ------------------------------------------------------------------ rendering
def render(svg_text, w, h, transparent=True, scale=1):
    """Render an SVG document string to a PIL image with Chromium."""
    with sync_playwright() as p:
        try:
            browser = p.chromium.launch()
        except Exception:
            exe = sorted(glob.glob(os.path.join(os.environ.get('LOCALAPPDATA', ''), 'ms-playwright', 'chromium-*', 'chrome-win*', 'chrome.exe')))[-1]
            browser = p.chromium.launch(executable_path=exe)
        page = browser.new_page(viewport={'width': w, 'height': h}, device_scale_factor=scale)
        page.set_content(f'<html><head><style>{font_css()}</style></head><body style="margin:0;background:transparent">{svg_text}</body></html>')
        page.wait_for_timeout(500)
        png = page.screenshot(omit_background=transparent)
        browser.close()
    return Image.open(io.BytesIO(png)).convert('RGBA')
