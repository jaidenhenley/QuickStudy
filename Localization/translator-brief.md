# QuickStudy translation brief

QuickStudy is an iPhone study app for high-school and college students. It turns scanned pages,
PDFs, photos and pasted notes into flashcards and multiple-choice quizzes with AI, then schedules
review with spaced repetition. Screens: Today (one daily study session, weakest card, up next),
Library (study sets, filters, import status card), New Set (Scan / Photo / PDF / Text), Review Cards
(edit drafted cards before saving), Card Source, Quiz, Session Complete, Streak, Stats, Settings,
Paywall (QuickStudy Pro subscription), Onboarding, What's New. Many strings are VoiceOver labels
(they are spoken, so they must read naturally aloud).

Scratch directory: <working folder>
Source pack: `source.json` there. Each item: `key` (catalog key, with `%lld`/`%@` placeholders),
`english` (the English text, with positional placeholders when there are several), `context`
(file:line and the Swift line that uses it; use it to tell a button from a header from a sentence),
optional `comment`, and optional `english_plural_spec` (how English varies by count).
App Store listing source: AppStoreMetadata/en-US/*.txt

## Voice and tone
- Casual and friendly, like Apple's own consumer apps. Address the user informally:
  es: tú (never usted, never vosotros forms for a single user) · fr: tu · de: du (lowercase) ·
  pt-BR: você · ja: です・ます (polite, warm, not stiff keigo) · ko: 해요체.
- Concise. Buttons are verbs. Empty states describe the next action and never apologize.
- Match Apple's own terminology for the locale (how Apple's iOS UI says Settings, Cancel, Done,
  Delete, Restore Purchases, Subscribe, Photos, Files, Camera, Edit, Save, Retry, etc.).
  Settings app: es Ajustes · fr Réglages · de Einstellungen · pt-BR Ajustes · ja 設定 · ko 설정.

## Never translate
QuickStudy, QuickStudy Pro, Pro, iPhone, Apple Intelligence, Private Cloud Compute, Claude,
Anthropic, OpenAI, PDF, API, SF Symbol names. Keep "Apple" possessives grammatical
(e.g. fr "Private Cloud Compute d'Apple").

## Format rules (a validator enforces these)
- Keep every placeholder. If a string has more than one placeholder, use positional specifiers
  that keep the English argument numbers: `%1$@`, `%2$lld`. You may reorder them.
- Do not add or remove arguments. `%lld` is an integer, `%@` is text (a title, date, or a
  pre-formatted number). Don't change `%lld` to `%@` or vice versa.
- No em dashes (—) anywhere. Use a period, comma, colon, or the middle dot `·`.
- Keep the middle dot `·` separators where English has them (they are a design element),
  with the spacing conventions of the locale (ja/ko may keep " · ").
- Uppercase section headers (e.g. "TODAY'S SESSION", "PROGRESS") stay uppercase in Latin-script
  languages; ja/ko have no case, write them normally.
- Title Case in English buttons ("Save 3 Cards") does not carry over: use the locale's normal
  capitalization (German nouns capitalized, French/Spanish/Portuguese sentence case).
- French: use a non-breaking space (U+00A0) before ? ! : ; and inside « ». Use ’ (U+2019) for
  apostrophes in all languages that use them, matching Apple.
- Japanese: full-width punctuation (、。「」？！), no spaces between words. Korean: standard 띄어쓰기.
- Length: buttons, chips, tab labels, headers and pill labels should stay within about 120% of
  the English character count; abbreviate naturally if needed (de/fr run long). Sentences may run
  longer.
- `p.%lld` is a page abbreviation on a tiny pill ("p.3 ¶2"): use the locale's page abbreviation
  (es "pág. %lld", fr "p. %lld", de "S. %lld", pt-BR "p. %lld", ja "%lldページ" or "p.%lld",
  ko "%lld쪽" or "p.%lld"); keep it short.

## Plurals
Output form for a key whose English varies by count:
- Exactly one placeholder: `{"plural": {"one": "...", "other": "..."}}`
- Several placeholders: `{"value": "... %#@cards@ ... %2$@ ...", "substitutions": {"cards": {"argNum": 1, "formatSpecifier": "lld", "plural": {"one": "%arg carte", "other": "%arg cartes"}}}}`
  (inside a substitution the number is written `%arg`; other arguments in `value` stay positional).
- es, fr, pt-BR: give `one` and `other` (the tool copies `other` into `many`). fr uses `one` for 0
  and 1. de: `one` and `other`. ja, ko: no plural forms, give a plain string.
- You may also add plural variants to keys whose English has none if your language needs them
  (e.g. a number followed by a noun). Never special-case a number in text.

## Output
1. First write `<LOCALE>-glossary.md`: 40 to 60 core terms (set, card, draft, drafting, session,
   streak, Streak Freeze, due, weakest card, mastered, generation, free generation, cloud,
   on-device, source, passage, review, quiz, Library, Today, scan, paste, import, etc.) with the
   one rendering you will use everywhere and why.
2. Write `<LOCALE>.json`: an object mapping every `key` in source.json to its spec (string or
   plural object). Include the `InfoPlist:` keys too (system permission prompts).
3. Validate until clean (it reports format/placeholder/em-dash problems and missing keys):
   `python3 Localization/tools/catalog.py validate QuickStudy/Localizable.xcstrings <LOCALE> <LOCALE>.json`
   and the same command with `QuickStudy/InfoPlist.xcstrings` for the two `InfoPlist:` keys.
4. Translate the App Store listing into `listing-<LOCALE>.json` with fields `name`, `subtitle`,
   `promotional_text`, `keywords`, `description`, `release_notes`. Limits: name 30 chars (keep
   "QuickStudy"), subtitle 30, promotional_text 170, keywords 100 (comma-separated, no spaces after
   commas, no app name, written as native search terms a student in that market would type, not a
   literal translation), description 4000, release_notes 4000. Keep every factual claim exactly
   (10 free generations, 150 a month for Pro, Anthropic's Claude deletes text within 30 days, the
   subscription renewal terms). Do not say text is "not stored" for the server.
5. Do not edit any file in the repository. Do not touch the catalog.
6. Final message: path of your files, glossary highlights, and every string you were unsure about
   (key + why).
