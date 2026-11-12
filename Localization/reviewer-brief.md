# QuickStudy translation review brief

You are an independent senior reviewer and native-level speaker of the target language. Someone
else drafted the translation; the app owner has no native speakers, so your review is the only
check before release. Be skeptical: assume there are mistakes and find them.

Folder: <working folder>
Read: `BRIEF.md` (the rules the translator had), `source.json` (English + code context),
`<LOCALE>.json`, `<LOCALE>-glossary.md`, `listing-<LOCALE>.json`, and the English listing at
AppStoreMetadata/en-US/*.txt.
If present, also `sample-<LOCALE>.json` with `sample-source.json` (the sample study set content).

## Do this for every string
1. Back-translate it literally into English, without looking at the English first, then compare.
2. Check: meaning drift or omission, wrong UI role (a button that reads as a noun, a header that
   reads as a sentence), tone (casual: es tú, fr tu, de du, pt-BR você, ja です・ます, ko 해요체),
   grammar and agreement with the placeholder values (what `%@` and `%lld` hold, from the context),
   plural forms, gender, particles (ko 을/를 이/가 after placeholders, ja particles),
   Apple's official iOS terminology for the locale, glossary consistency across all strings,
   length (buttons/chips/headers ≤ ~120% of English), typography (fr non-breaking spaces before
   ? ! : ;, ’ apostrophes, ja full-width punctuation), no em dashes, untranslated brand names kept,
   VoiceOver strings that read naturally aloud, and factual claims in privacy, pricing and
   subscription text kept exactly (10 free generations a month, 150 for Pro, Anthropic's Claude
   deletes text within 30 days, renewal terms). A privacy or pricing error is severity high.
3. Fix every real problem directly in `<LOCALE>.json` / `listing-<LOCALE>.json` (and
   `sample-<LOCALE>.json` if present). Do not rewrite strings that are already correct just to
   suit your taste.

## Outputs
- `review-<LOCALE>.json`: an object mapping EVERY key (app strings, `InfoPlist:` keys, and
  `listing:<field>`, plus `sample:<key>` if present) to
  `{"back": "<your literal English back-translation of the FINAL text>", "status": "ok" | "fixed",
    "severity": "none" | "low" | "medium" | "high", "note": "<what was wrong and what you changed, or empty>"}`.
  For plural specs back-translate the `other` form (and note any problem in `one`).
- Validate after fixing, until clean:
  `python3 Localization/tools/catalog.py validate QuickStudy/Localizable.xcstrings <LOCALE> <LOCALE>.json`
  and the same with `QuickStudy/InfoPlist.xcstrings`.
- Final message: counts (ok / fixed by severity), the 10 most important fixes, any systematic
  problem (e.g. a glossary term used wrongly everywhere), and anything you could not resolve.
Do not edit any repository file.
