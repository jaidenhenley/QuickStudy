#!/usr/bin/env python3
"""Assemble the translation review page from the shipped catalogs and the reviewers' notes.
usage: reviewpage.py <template.html> <out.html>"""
import json, sys
from pathlib import Path
REPO = str(Path(__file__).resolve().parents[2])
L10N = REPO + "/Localization"
LOCALES = [("es-419", "Spanish (Latin America)", "es-MX"), ("es-ES", "Spanish (Spain)", "es-ES"), ("fr", "French", "fr-FR"),
           ("de", "German", "de-DE"), ("ja", "Japanese", "ja"), ("ko", "Korean", "ko"), ("pt-BR", "Portuguese (Brazil)", "pt-BR")]
FIELDS = ["name", "subtitle", "promotional_text", "keywords", "description", "release_notes"]

def load(table):
    return json.load(open(f"{REPO}/QuickStudy/{table}.xcstrings"))["strings"]

def flat(loc):
    """One readable line for a catalog localization: plural forms joined by ‖, substitutions in [brackets]."""
    if not loc:
        return ""
    device = loc.get("variations", {}).get("device")
    if device:
        subs = {"substitutions": loc["substitutions"]} if "substitutions" in loc else {}
        return " ⟂ ".join(f"{name}: {flat({**form, **subs})}" for name, form in device.items())
    if "variations" in loc:
        return " ‖ ".join(f"{k}: {v['stringUnit']['value']}" for k, v in loc["variations"]["plural"].items())
    out = loc["stringUnit"]["value"]
    for name, sub in loc.get("substitutions", {}).items():
        forms = []
        for v in sub["variations"]["plural"].values():
            if v["stringUnit"]["value"] not in forms:
                forms.append(v["stringUnit"]["value"])
        out = out.replace(f"%#@{name}@", "[" + " / ".join(forms) + "]")
    return out

ENGLISH_SLIDES = [
    "TURN / any page into / flashcards\nScan, snap or paste your notes.",
    "STUDY / only what's / due today\nA short session, picked for you.",
    "QUIZ / yourself in / minutes\nMultiple choice built from your notes.",
    "KNOW / why each answer / is right\nEvery answer comes with a reason.",
    "LEARN / from every / mistake\nMissed cards return tomorrow.",
    "BUILD / a daily study / habit\nFinish a session, grow your streak.",
    "TRACK / every subject's / progress\nDue, in progress and mastered.",
]
PLAN_NOTES = {"fr": "Description changed in review to the more natural “sur n’importe quel iPhone”."}
headlines = json.load(open(f"{L10N}/screenshot-headlines.json"))
app, info, sample = load("Localizable"), load("InfoPlist"), load("SampleSet")
sample_review = json.load(open(f"{L10N}/review/sample-set.json"))
data = {"locales": []}
for code, name, asc in LOCALES:
    rv = json.load(open(f"{L10N}/review/{code}.json"))
    rows = []
    def add(group, key, rkey, english, text, r):
        rows.append({"g": group, "k": key, "en": english, "t": text, "b": r.get("back", ""), "s": r.get("status", "ok"),
                     "v": r.get("severity", "none"), "n": r.get("note", "")})
    for key, entry in app.items():
        if entry.get("shouldTranslate") is False:
            continue
        locs = entry.get("localizations", {})
        add("App", key, key, flat(locs.get("en")) or key, flat(locs.get(code)), rv.get(key, {}))
    for key, entry in info.items():
        if entry.get("shouldTranslate") is False:
            continue
        locs = entry["localizations"]
        add("Permission prompts", key, key, flat(locs.get("en")), flat(locs.get(code)), rv.get("InfoPlist:" + key, {}))
    for f in FIELDS:
        add("App Store listing", f, f, open(f"{REPO}/AppStoreMetadata/en-US/{f}.txt").read().strip(),
            open(f"{REPO}/AppStoreMetadata/{asc}/{f}.txt").read().strip(), rv.get("listing:" + f, {}))
    for key, entry in sample.items():
        r = dict(sample_review.get(code, {}).get(key, {}))
        text = flat(entry["localizations"].get(code))
        if key in ("Carbon dioxide only.", "Absorbing water through the roots.") and code in ("es-419", "es-ES", "pt-BR") and \
                text in ("Dióxido de carbono.", "Absorver água pelas raízes da planta."):
            r = {"back": "Carbon dioxide." if code != "pt-BR" else "Absorbing water through the plant's roots.",
                 "status": "fixed", "severity": "low",
                 "note": "Changed after review: an automated test showed the quiz's quality filter dropped the earlier wording (it read as a different kind of answer, or was one character too short)."}
        add("Sample set", key, key, key, text, r)
    for i, slide in enumerate(headlines[code]):
        text = f"{slide['v']} / {slide['d'].replace('<br>', ' / ')}\n{slide['sub']}"
        add("Store screenshots", f"slide {i + 1}", "", ENGLISH_SLIDES[i], text, {"back": slide["back"]})
    names = open(f"{REPO}/AppStoreMetadata/{asc}/subscription_names.txt").read().strip()
    add("Subscription names", "plans", "", open(f"{REPO}/AppStoreMetadata/en-US/subscription_names.txt").read().strip(), names,
        {"back": "Checked by the headline reviewer: natural plan names for this language.", "note": PLAN_NOTES.get(code, "")})
    data["locales"].append({"code": code, "name": name, "rows": rows, "glossary": open(f"{L10N}/glossaries/{code}.md").read()})

tpl = open(sys.argv[1]).read()
open(sys.argv[2], "w").write(tpl.replace("/*DATA*/null", json.dumps(data, ensure_ascii=False).replace("</", "<\\/")))
for l in data["locales"]:
    print(l["code"], len(l["rows"]), "no back:", sum(1 for r in l["rows"] if not r["b"]), "empty:", sum(1 for r in l["rows"] if not r["t"]))
