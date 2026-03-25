# QuickStudy

Turn scans and PDFs into a study-ready flashcard deck in minutes. Scan a page or import a PDF, let the app generate cards on-device, approve what's worth keeping, then study. Built solo over about 3 months.

[View on the App Store](https://apps.apple.com/us/app/quickstudy-flashcard-tool/id6759993537)

## Stack

Swift, SwiftUI, VisionKit, PDFKit, Foundation Models, AppStorage, UserDefaults

## Features

- Scan handwritten notes or import a PDF
- On-device flashcard generation using Foundation Models
- Cloud fallback with bring-your-own API key when on-device AI isn't available
- Card review and approval step so only the cards you want make it into the deck
- Flashcard practice mode with swipe interaction
- Quiz mode auto-generated from your approved cards with multiple choice
- Local-first, no account required, everything saved on-device

## Architecture

Solo project. Everything runs on-device by default with no network layer unless the user opts into the cloud fallback.

**Scan and import pipeline.** VisionKit handles OCR for scanned pages and PDFKit handles PDF text extraction. Before anything goes to the model, the raw text runs through a cleanup pass that trims junk characters, fixes spacing and line breaks, and reshapes it into something the model can work with. For handwriting specifically, I run the image through a `preprocessForHandwriting` step that desaturates, boosts contrast, adjusts exposure, and sharpens using Core Image filters before OCR even starts.

**Card generation.** The cleaned text gets sent to a `LanguageModelSession` from Foundation Models. I'm using structured generation with the `@Generable` macro so the response comes back as a typed `FlashcardSetModel` instead of raw text I'd have to parse. Each generated card starts with `approved: false` so nothing gets saved until the user explicitly keeps it.

**Generation engine abstraction.** I built card generation behind a protocol with two conforming engines — one for on-device Foundation Models and one for a cloud API using a key the user provides in settings. The rest of the app calls the same method either way and gets back the same typed response.

**Fallback path.** Not every device supports Foundation Models, and even supported devices can fail from low memory or a generation error. When AI isn't available and no API key is configured, the app falls back to breaking the cleaned text into card-sized chunks so you still get a usable deck. The UI shows a clear message about what happened instead of failing silently.

**Approval flow.** Generated cards land in a review list where you toggle each one on or off. Only approved cards move into study and quiz mode. This keeps decks focused and gives the user final say over what the AI produced.

**Quiz generation.** `QuizGenerator` takes the approved cards and builds multiple choice questions. For each card it pulls 3 distractors from the other answers in the deck, preferring ones with similar length (within 10 characters) so wrong answers aren't obviously wrong just by being way shorter or longer. If there aren't enough unique answers it fills in fallbacks like "None of the above." Wrong answers circle back at the end.

**Persistence.** Decks and study history are saved on-device with AppStorage and UserDefaults. No accounts, no analytics, no network calls.

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
