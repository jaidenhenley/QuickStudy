# QuickStudy

Turn scans and PDFs into a study-ready flashcard deck in minutes. Scan a page or import a PDF, let the app generate cards on-device, approve what's worth keeping, then study. Built solo over about 3 months.

[View on the App Store](https://apps.apple.com/us/app/quickstudy-flashcard-tool/id6759993537)

## Stack

Swift, SwiftUI, VisionKit, PDFKit, Foundation Models, AppStorage, UserDefaults

## Features

- Scan handwritten notes or import a PDF
- On-device flashcard generation using Foundation Models
- Fallback generation path when AI isn't available (breaks cleaned text into card-sized chunks)
- Card review and approval step so only the cards you want make it into the deck
- Flashcard practice mode with swipe interaction
- Quiz mode auto-generated from your approved cards with multiple choice
- Local-first, no account required, everything saved on-device

## Architecture

Solo project. Everything runs on-device with no network layer.

**Scan and import pipeline.** VisionKit handles OCR for scanned pages and PDFKit handles PDF text extraction. Before anything goes to the model, the raw text runs through a cleanup pass that trims junk characters, fixes spacing and line breaks, and reshapes it into something the model can work with. For handwriting specifically, I run the image through a `preprocessForHandwriting` step that desaturates, boosts contrast, adjusts exposure, and sharpens using Core Image filters before OCR even starts.

**Card generation.** The cleaned text gets sent to a `LanguageModelSession` from Foundation Models. I'm using structured generation with the `@Generable` macro so the response comes back as a typed `FlashcardSetModel` instead of raw text I'd have to parse. Each generated card starts with `approved: false` so nothing gets saved until the user explicitly keeps it.

**Fallback path.** Not every device supports Foundation Models, and even supported devices can fail from low memory or a generation error. When AI isn't available the app falls back to breaking the cleaned text into card-sized chunks so you still get a usable deck. The UI shows a clear message about what happened instead of failing silently.

**Approval flow.** Generated cards land in a review list where you toggle each one on or off. Only approved cards move into study and quiz mode. This keeps decks focused and gives the user final say over what the AI produced.

**Quiz generation.** `QuizGenerator` takes the approved cards and builds multiple choice questions. For each card it pulls 3 distractors from the other answers in the deck, preferring ones with similar length (within 10 characters) so wrong answers aren't obviously wrong just by being way shorter or longer. If there aren't enough unique answers it fills in fallbacks like "None of the above." Wrong answers circle back at the end.

**Persistence.** Decks and study history are saved on-device with AppStorage and UserDefaults. No accounts, no analytics, no network calls.

## Privacy

No data collected. No accounts, no analytics, no tracking.

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

Open `QuickStudy.xcodeproj` in Xcode and run on a physical device. AI generation features may not work in Simulator.

## Developer

Jaiden Henley | [Portfolio](https://jaidenhenley.github.io/JaidenHenleyPort/) | [LinkedIn](https://www.linkedin.com/in/jaiden-henley) | [jaidenhenleydev@gmail.com](mailto:jaidenhenleydev@gmail.com)
