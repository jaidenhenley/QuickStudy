#!/usr/bin/env python3
"""Write translation specs into an .xcstrings catalog and validate them.

Spec forms (per key, per locale):
  "plain string"
  {"plural": {"one": "...", "other": "...", ...}}            # key has exactly one format arg
  {"value": "... %#@name@ ...", "substitutions": {
       "name": {"argNum": 1, "formatSpecifier": "lld", "plural": {"one": "%arg x", "other": "%arg xs"}}}}

usage:
  catalog.py apply <catalog> <locale> <spec.json> [--state translated|needs_review]
  catalog.py validate <catalog> <locale> <spec.json>      (prints problems, exit 1 if any)
"""
import json
import re
import sys

PLURAL_CATEGORIES = {
    "en": ["one", "other"],
    "es-419": ["one", "many", "other"],
    "es-ES": ["one", "many", "other"],
    "fr": ["one", "many", "other"],
    "pt-BR": ["one", "many", "other"],
    "de": ["one", "other"],
    "ja": ["other"],
    "ko": ["other"],
}

SPEC_RE = re.compile(r"%(?:(\d+)\$)?(lld|ld|d|@|f|lf|%)")


def args_of(fmt):
    """Return {position: type} for a format string, resolving implicit positions."""
    out = {}
    implicit = 0
    for m in SPEC_RE.finditer(fmt):
        pos, typ = m.group(1), m.group(2)
        if typ == "%":
            continue
        if pos:
            p = int(pos)
        else:
            implicit += 1
            p = implicit
        out[p] = "int" if typ in ("lld", "ld", "d") else ("float" if typ in ("f", "lf") else "obj")
    return out


def unit(value, state):
    return {"stringUnit": {"state": state, "value": value}}


def expected_args(key):
    return args_of(key)


def spec_args(spec):
    """Args a spec consumes, as {position: type}."""
    if isinstance(spec, str):
        return args_of(spec)
    if "plural" in spec:
        merged = {}
        for v in spec["plural"].values():
            merged.update(args_of(v))
        return merged
    value = spec["value"]
    merged = args_of(re.sub(r"%#@\w+@", "", value))
    for sub in spec.get("substitutions", {}).values():
        merged[sub["argNum"]] = "int" if sub["formatSpecifier"] in ("lld", "ld", "d") else "obj"
    return merged


def problems_for(key, spec, locale):
    probs = []
    exp = expected_args(key)
    got = spec_args(spec)
    if exp != got:
        probs.append(f"format args differ: key {exp} vs translation {got}")
    texts = []
    if isinstance(spec, str):
        texts = [spec]
    elif "plural" in spec:
        cats = set(spec["plural"])
        if "other" not in cats:
            probs.append("plural missing 'other'")
        if len(exp) != 1:
            probs.append("top-level plural used on a key with more or less than one argument; use substitutions")
        texts = list(spec["plural"].values())
    else:
        texts = [spec["value"]]
        for name, sub in spec.get("substitutions", {}).items():
            if f"%#@{name}@" not in spec["value"]:
                probs.append(f"substitution {name} not referenced")
            if "other" not in sub["plural"]:
                probs.append(f"substitution {name} missing 'other'")
            for v in sub["plural"].values():
                if "%arg" not in v:
                    probs.append(f"substitution {name} variant lacks %arg: {v!r}")
                texts.append(v)
    for t in texts:
        if "\u2014" in t:
            probs.append("contains an em dash")
        if not t.strip() and key.strip():
            probs.append("empty translation")
        if len(exp) > 1 and isinstance(spec, str) and re.search(r"%(lld|@)", re.sub(r"%\d+\$", "", t)):
            probs.append("multi-argument translation must use positional specifiers like %1$@")
    return probs


def build_localization(spec, locale, state):
    cats = PLURAL_CATEGORIES[locale]
    if isinstance(spec, str):
        return unit(spec, state)
    if "plural" in spec:
        forms = fill(spec["plural"], cats)
        return {"variations": {"plural": {c: unit(v, state) for c, v in forms.items()}}}
    subs = {}
    for name, sub in spec["substitutions"].items():
        forms = fill(sub["plural"], cats)
        subs[name] = {
            "argNum": sub["argNum"],
            "formatSpecifier": sub["formatSpecifier"],
            "variations": {"plural": {c: unit(v, state) for c, v in forms.items()}},
        }
    loc = unit(spec["value"], state)
    loc["substitutions"] = subs
    return loc


def fill(forms, cats):
    out = {}
    for c in cats:
        if c in forms:
            out[c] = forms[c]
        else:
            out[c] = forms["other"]
    return out


def main():
    cmd, catalog_path, locale, spec_path = sys.argv[1:5]
    state = "translated"
    if "--state" in sys.argv:
        state = sys.argv[sys.argv.index("--state") + 1]
    catalog = json.load(open(catalog_path))
    specs = json.load(open(spec_path))
    prefix = "InfoPlist:"
    if catalog_path.endswith("InfoPlist.xcstrings"):
        specs = {k[len(prefix):]: v for k, v in specs.items() if k.startswith(prefix)}
    else:
        specs = {k: v for k, v in specs.items() if not k.startswith(prefix)}
    bad = 0
    for key, spec in specs.items():
        if key not in catalog["strings"]:
            print(f"UNKNOWN KEY {key!r}")
            bad += 1
            continue
        probs = problems_for(key, spec, locale)
        for p in probs:
            print(f"{locale} {key!r}: {p}")
        bad += bool(probs)
    if cmd == "validate":
        missing = [k for k, v in catalog["strings"].items()
                   if v.get("shouldTranslate") is not False and k not in specs]
        if locale != "en":
            for k in missing:
                print(f"{locale} MISSING {k!r}")
            bad += len(missing)
        sys.exit(1 if bad else 0)
    if bad:
        print(f"refusing to apply: {bad} problems")
        sys.exit(1)
    for key, spec in specs.items():
        entry = catalog["strings"][key]
        entry.setdefault("localizations", {})[locale] = build_localization(spec, locale, state)
    json.dump(catalog, open(catalog_path, "w"), ensure_ascii=False, indent=2, separators=(",", " : "))
    open(catalog_path, "a").write("\n")
    print(f"applied {len(specs)} {locale} entries")


if __name__ == "__main__":
    main()
