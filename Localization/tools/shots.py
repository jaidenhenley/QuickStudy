#!/usr/bin/env python3
"""Build store-screenshots/localized/<locale>/screens.html from the English final slides.

usage: shots.py <locale> <captures dir with <locale>-NN-name.png>
"""
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WS = ROOT / "store-screenshots"
COPY = ROOT / "Localization" / "screenshot-headlines.json"
NAMES = ["01-newset", "02-today", "03-quiz-selected", "04-correct-why", "05-wrong", "06-complete", "07-library"]
HTML_LANG = {"es-419": "es-419", "es-ES": "es-ES", "fr": "fr", "de": "de", "ja": "ja", "ko": "ko", "pt-BR": "pt-BR"}

loc, captures = sys.argv[1], Path(sys.argv[2])
slides = json.load(open(COPY))[loc]
out = WS / "localized" / loc
(out / "captures").mkdir(parents=True, exist_ok=True)
for f in ["shared.css", "shared.js", "layout.js"]:
    shutil.copy(WS / "final" / "src" / f, out / f)
for name in NAMES:
    src = captures / f"{loc}-{name}.png"
    if not src.exists():
        sys.exit(f"missing capture {src}")
    # The phone mockup draws its own status bar, so the capture's is painted out the way
    # `studio init` does it: the row just under the bar is stretched up over it.
    from PIL import Image
    shot = Image.open(src).convert("RGB")
    band = round(shot.size[1] * 0.0618) + 4
    row = shot.crop((0, band, shot.size[0], band + 1)).resize((shot.size[0], band))
    shot.paste(row, (0, 0))
    shot.save(out / "captures" / f"{name}.png")

html = (WS / "final" / "src" / "screens.html").read_text()


def session_card_crop(path):
    """The TODAY'S SESSION card's bounds in this capture: the longest solid-indigo run down x=100."""
    from PIL import Image
    im = Image.open(path).convert("RGB")
    px, h = im.load(), im.size[1]
    near = lambda p: abs(p[0] - 83) < 16 and abs(p[1] - 82) < 16 and abs(p[2] - 220) < 16
    best, start = (0, 0), None
    for y in range(h + 1):
        ok = y < h and near(px[100, y])
        if ok and start is None:
            start = y
        if not ok and start is not None:
            if y - start > best[1] - best[0]:
                best = (start, y)
            start = None
    assert best[1] - best[0] > 400, best
    return f"02-today 72 {best[0] - 10} 1176 {best[1] - best[0] + 19} 60"


crop = session_card_crop(out / "captures" / "02-today.png")
assert 'data-crop="02-today 72 774 1176 702 60"' in html
html = html.replace('data-crop="02-today 72 774 1176 702 60"', f'data-crop="{crop}"')
blocks = re.findall(r'<div class="v">.*?</div><div class="d">.*?</div><div class="sub"([^>]*)>.*?</div>', html)
assert len(blocks) == 7, len(blocks)
i = iter(range(7))


def swap(m):
    k = next(i)
    s = slides[k]
    return f'<div class="v">{s["v"]}</div><div class="d">{s["d"]}</div><div class="sub"{m.group(1)}>{s["sub"]}</div>'


html = re.sub(r'<div class="v">.*?</div><div class="d">.*?</div><div class="sub"([^>]*)>.*?</div>', swap, html)
html = html.replace('<html style="--n:7">', f'<html lang="{HTML_LANG[loc]}" style="--n:7">')
html = html.replace("<title>Paper poster</title>", f"<title>QuickStudy {loc}</title>")

cjk = {"ja": "Noto+Sans+JP", "ko": "Noto+Sans+KR"}.get(loc)
fonts = ""
style = ".v,.d{white-space:nowrap}\n"
if cjk:
    family = cjk.replace("+", " ")
    fonts = f'<link href="https://fonts.googleapis.com/css2?family={cjk}:wght@500;900&display=block" rel="stylesheet">\n'
    style += (f'.v,.d{{font-family:"{family}",sans-serif;font-weight:900;letter-spacing:-.02em}}\n'
              f'.v{{line-height:1.05}}.d{{line-height:1.12}}\n'
              f'.sub{{font-family:Inter,"{family}",sans-serif}}\n')
# After the page's own <style>, so these rules win over its `font` shorthands.
html = html.replace("</head>", fonts + "<style>" + style + "</style>\n</head>")

fit = """<script>
// Translated headlines run longer than English: shrink each line until it fits the copy column.
function fitHeadlines() {
  document.querySelectorAll('.copy .v, .copy .d').forEach(el => {
    el.style.fontSize = '';
    let size = parseFloat(getComputedStyle(el).fontSize);
    while (el.scrollWidth > el.clientWidth + 1 && size > 20) {
      size *= 0.97;
      el.style.fontSize = size + 'px';
    }
  });
}
fitHeadlines();
document.fonts.ready.then(fitHeadlines);
</script>
"""
html = html.replace('<script src="shared.js"></script>', '<script>window.SCREENS = "captures";</script>\n<script src="shared.js"></script>')
html = html.replace("</body></html>", fit + "</body></html>")
html = html.replace('src="../../assets/brand/icon.png"', 'src="../../assets/brand/icon.png"')
(out / "screens.html").write_text(html)
print("wrote", out / "screens.html")
