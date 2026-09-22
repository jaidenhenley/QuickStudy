# QuickStudy

Turn scans and PDFs into a study-ready flashcard deck in minutes. Scan a page or import a PDF, let the app generate cards on-device, approve what's worth keeping, then study. Built solo over about 3 months.

[View on the App Store](https://apps.apple.com/us/app/quickstudy-flashcard-tool/id6759993537)

## Stack

Swift, SwiftUI, VisionKit, PDFKit, Foundation Models, Keychain, UserDefaults

## Features

- Scan handwritten notes or import a PDF
- On-device flashcard generation using Foundation Models
- Cloud fallback with bring-your-own API key when on-device AI isn't available
- Draft review: swipe to remove unwanted cards before saving
- Multiple-choice quiz with spaced-repetition scheduling (Leitner-style boxes)
- Session history tracked with streaks and earned Streak Freezes
- Local-first, no account required, everything saved on-device
- 10 free cards per month; bring your own API key for unlimited generation

## Architecture

Solo project. Everything runs on-device by default with no network layer unless the user opts into the cloud fallback.

**Scan and import pipeline.** VisionKit handles OCR for scanned pages and PDFKit handles PDF text extraction. Before anything goes to the model, the raw text runs through a cleanup pass that trims junk characters, fixes spacing and line breaks, and reshapes it into something the model can work with. For handwriting specifically, I run the image through a `preprocessForHandwriting` step that desaturates, boosts contrast, adjusts exposure, and sharpens using Core Image filters before OCR even starts.

**Card generation.** The cleaned text gets sent to a `LanguageModelSession` from Foundation Models. I'm using structured generation with the `@Generable` macro so the response comes back as a typed `FlashcardSetModel` instead of raw text I'd have to parse. Each card is generated with its own explanation and three AI-generated distractors in a single call, allowing quizzes to build instantly and offline. Generated cards land in a `DraftSet` held in `DraftStore` (persisted, survives crashes) where the user can edit or swipe left to remove unwanted cards before saving.

**Generation engine abstraction.** I built card generation behind a protocol with two conforming engines — one for on-device Foundation Models and one for a cloud API using a key the user provides in settings. The rest of the app calls the same method either way and gets back the same typed response.

**Fallback path.** Not every device supports Foundation Models, and even supported devices can fail from low memory or a generation error. When AI isn't available and no API key is configured, the app falls back to breaking the cleaned text into card-sized chunks so you still get a usable deck. The UI shows a clear message about what happened instead of failing silently.

**Draft review.** When cards are saved from a draft, every card enters the study rotation immediately as "scheduled" (using Leitner-style boxes 0–5 with intervals 0/1/3/7/14/30 days). Each card carries a `CardSource` linking back to its source document, page, and paragraph, enabling source pills and "Why?" explanations during quiz review.

**Quiz sessions.** Study runs as a multiple-choice quiz session where each card is due based on its box in the Leitner schedule. Wrong answers advance the card back two boxes and show the correct answer alongside a "Why" explanation with the source excerpt. Sessions are recorded as `StudySession` entries, enabling accurate session history and streak calculation.

**Persistence.** Study sets and sessions are persisted as Codable JSON files in the Documents directory (`SavedSets.json`, `PendingDraft.json`), surviving app reinstalls within the same device. Non-secret AI preferences use UserDefaults; the API key is stored in Keychain. No accounts, no analytics, no network calls.

## Privacy

No data collected. No accounts, no analytics, no tracking. If you use the cloud fallback, your text goes to whatever API provider you configure — nothing touches any server I control.

- [Privacy Policy](https://jaidenhenley.github.io/JaidenHenleyPort/quickstudy-privacy.html)
- [Support](https://jaidenhenley.github.io/JaidenHenleyPort/quickstudy-support.html)

## Requirements

- Xcode 16+
- iOS 18+
- Apple Silicon device (on-device AI needs compatible hardware)

## Setup

```bash
git clone https://github.com/jaidenhenley/QuickStudy.git
```

Open `QuickStudy.xcodeproj` in Xcode and run on a physical device. AI generation features may not work in Simulator. To use the cloud fallback, add your API key in the app's settings.

## Developer

Jaiden Henley | [Portfolio](https://jaidenhenley.github.io/JaidenHenleyPort/) | [LinkedIn](https://www.linkedin.com/in/jaiden-henley) | [jaidenhenleydev@gmail.com](mailto:jaidenhenleydev@gmail.com)
