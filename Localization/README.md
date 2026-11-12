# QuickStudy localization

The app ships in English plus Spanish (Latin America `es-419`, Spain `es-ES`), French `fr`, German `de`, Japanese `ja`, Korean `ko` and Brazilian Portuguese `pt-BR`.

## Where the text lives

| File | Holds |
|---|---|
| `QuickStudy/Localizable.xcstrings` | Every string the app shows or speaks |
| `QuickStudy/InfoPlist.xcstrings` | Camera and Photo Library permission prompts |
| `QuickStudy/SampleSet.xcstrings` | The built-in Photosynthesis sample set |
| `QuickStudy/QuickStudy.storekit` | Plan names for local StoreKit testing |
| `AppStoreMetadata/<App Store locale>/` | App Store listing text and plan names, one file per field |
| `store-screenshots/localized/<locale>/` | Store screenshots per language |

Xcode fills the catalogs from code on every build. English stays in the code; translations are only in the catalogs.

## Rules when you add or change a string

- A literal passed straight to SwiftUI (`Text("…")`, `Button("…")`, `.accessibilityLabel("…")`) is picked up on its own. Anything built as a `String` (view models, models, errors) needs `String(localized: "…")`.
- A component that takes its label as a parameter declares it `LocalizedStringKey` or `LocalizedStringResource`, never `String`, unless it shows user content.
- One string per sentence. Put the number in the string (`"\(count) cards drafted"`) and give the catalog plural forms; never write `count == 1 ? … : …`.
- When one English word plays two roles (a filter chip and a badge, a header and a stat), give each role its own key with `String(localized: "area.role", defaultValue: "…")`. Other languages need different words.
- Dates, numbers, durations and percentages go through `.formatted(…)`.
- Card text, set titles and document text are user content and are never localized. Cards are drafted in the language of the source material, not the iPhone's (`SourceLanguage`).
- New strings need all seven translations before release. `LocalizationCatalogTests` fails the unit tests when one is missing, uses an em dash, or drops a format argument.

## Translating

`glossaries/<locale>.md` holds the term choices for each language; keep new strings consistent with them. `translator-brief.md` and `reviewer-brief.md` are the instructions the translators and the independent reviewers worked from, and `review/<locale>.json` records each string's back-translation and what the reviewer changed.

`tools/catalog.py` writes translations into a catalog and checks placeholders and plural forms:

```sh
python3 Localization/tools/catalog.py validate QuickStudy/Localizable.xcstrings fr my-fr.json
python3 Localization/tools/catalog.py apply QuickStudy/Localizable.xcstrings fr my-fr.json
```

`my-fr.json` maps each key to a string, or to `{"plural": {"one": "…", "other": "…"}}` for a key with one number, or to a `value` with `substitutions` for several (see the top of the script).

## Checking a language in the app

`QuickStudyUITests/LocalizationWalkTests` launches the app in one language with the sample set, walks Today, Library, New Set, a quiz, Session Complete, Streak, Stats, Settings and the paywall, saves a screenshot of each, and lists any English left on screen:

```sh
TEST_RUNNER_QS_LANGUAGE=ja TEST_RUNNER_QS_EVIDENCE_DIR=/tmp/qs-ja xcodebuild test-without-building \
  -project QuickStudy.xcodeproj -scheme QuickStudyUITests -destination "id=<simulator>" \
  -only-testing:QuickStudyUITests/LocalizationWalkTests
```

Captures `01` to `07` are the seven store screenshots' screens.

## Store screenshots

`screenshot-headlines.json` holds the translated headline for each slide. To rebuild a language from fresh walk captures:

```sh
python3 Localization/tools/shots.py ja /tmp/qs-ja
node store-screenshots/engine/studio.mjs render store-screenshots/localized/ja/screens.html
```

The 1320 × 2868 results land in `store-screenshots/localized/ja/out/screens/`.

## Review page

`tools/reviewpage.py` rebuilds the side-by-side review page (English, translation, back-translation, reviewer notes) from the catalogs and `review/`:

```sh
python3 Localization/tools/reviewpage.py Localization/tools/review-template.html review.html
```
