# App Store Assets & Submission Guide

## 📱 Required Screenshots

Apple requires screenshots for specific device sizes. You'll need to provide screenshots for:

### iPhone Screenshots (Required)
- **6.7" Display** (iPhone 15 Pro Max, 14 Pro Max, 13 Pro Max, 12 Pro Max)
  - Resolution: 1290 x 2796 pixels (portrait) or 2796 x 1290 pixels (landscape)
  - **Required**: 3-10 screenshots

- **6.5" Display** (iPhone 11 Pro Max, XS Max)
  - Resolution: 1242 x 2688 pixels (portrait) or 2688 x 1242 pixels (landscape)
  - **Required**: 3-10 screenshots

### iPad Screenshots (If Supporting iPad)
- **12.9" Display** (iPad Pro 12.9")
  - Resolution: 2048 x 2732 pixels (portrait) or 2732 x 2048 pixels (landscape)
  - **Required**: 3-10 screenshots

### How to Capture Screenshots

**Method 1: Using Xcode Simulator**
1. Open your project in Xcode
2. Select iPhone 15 Pro Max simulator
3. Run your app (⌘R)
4. Navigate to key screens
5. Press **⌘S** to save screenshot (saves to Desktop)
6. Repeat for iPad Pro 12.9" simulator

**Method 2: Using Real Device**
1. Run app on physical device
2. Take screenshots with device buttons
3. AirDrop to Mac
4. Resize if needed using Preview or Image editing tool

### Key Screens to Showcase

Based on your app, capture these moments:

1. **Dashboard/Home Screen** - Shows the main interface with study sets
2. **Document Scanner** - Show the camera scanning a document (use example/demo)
3. **Cards View** - Display generated flashcards with questions/answers
4. **Flashcard Practice** - Show the flip animation or practice mode
5. **Quiz View** - Display a multiple-choice quiz question
6. **Settings** - Show customization options (handwriting mode, etc.)

### Screenshot Tips
- Use **real content** (not lorem ipsum)
- Show your app's **unique features** (AI generation, OCR)
- Keep UI **clean** (no debug info)
- Use **consistent device** for all screenshots
- Consider adding **captions** explaining features
- Show **both light and dark mode** if supported

---

## 🎥 App Preview Video (Optional but Recommended)

### Specifications
- **Duration**: 15-30 seconds
- **Format**: .mov, .mp4, or .m4v
- **Resolution**: Same as screenshot sizes
- **Orientation**: Portrait or landscape (be consistent)

### Content Ideas
1. Quick scan of a document → AI generates flashcards
2. Practice flashcards with flip animation
3. Take a quiz and see results
4. Import from photos or PDF

### Tools to Create
- **QuickTime Player**: Record simulator (File → New Screen Recording)
- **Xcode**: Record simulator directly
- **Third-party**: iMovie, Final Cut Pro for editing

---

## 📝 App Store Metadata

### App Name
- **Current**: QuickStudy
- **Character Limit**: 30 characters
- Keep it short, memorable, and descriptive

### Subtitle (Optional)
- **Suggestion**: "AI-Powered Study Flashcards"
- **Character Limit**: 30 characters
- Explains what your app does at a glance

### App Description
**Character Limit**: 4,000 characters

**Suggested Structure:**

```
Transform your study materials into interactive flashcards and quizzes in seconds with QuickStudy – the AI-powered study companion designed for students.

KEY FEATURES

📸 Smart Document Scanning
• Scan textbooks, notes, and handwritten materials with your camera
• Advanced OCR technology with handwriting recognition
• Import PDFs and photos directly from your library

🤖 AI-Powered Flashcard Generation
• Intelligent flashcard creation using on-device Apple Intelligence
• Automatically identifies key concepts and generates questions
• No internet required – all processing happens on your device

✏️ Interactive Study Modes
• Flip-through flashcards for active recall practice
• AI-generated multiple-choice quizzes
• Track your progress with approved cards

🎨 Beautiful, Native Design
• Elegant glass effects and smooth animations
• Optimized for iPhone and iPad
• Supports both portrait and landscape modes

🔒 Privacy First
• All data stays on your device
• No cloud storage or account required
• Your study materials are completely private

PERFECT FOR
• High school and college students
• Visual learners who prefer flashcards
• Anyone preparing for exams or studying new topics

Download QuickStudy today and transform the way you study!
```

### Keywords
**Character Limit**: 100 characters (comma-separated)

**Suggested Keywords**:
```
study,flashcards,quiz,education,learning,OCR,AI,exam,test prep,student
```

Tips:
- Don't use spaces after commas
- Don't include app name (Apple adds it automatically)
- Focus on search terms users would use
- Research competitors' keywords

### Support URL (Required)
You need a public URL where users can get support.

**Options:**
1. **GitHub Issues**: `https://github.com/yourusername/quickstudy/issues`
2. **Email**: Create a simple webpage with your email
3. **Website**: Build a simple landing page with FAQ

**Quick Solution:**
Create a simple GitHub repository or use a free website builder (Carrd, GitHub Pages) with:
- Contact email
- FAQ section
- Known issues
- How to use the app

### Privacy Policy URL (Required)
You MUST have a publicly accessible privacy policy.

**Template Privacy Policy** (save as HTML and host):

```html
<!DOCTYPE html>
<html>
<head>
    <title>QuickStudy Privacy Policy</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
               max-width: 800px; margin: 40px auto; padding: 20px; line-height: 1.6; }
        h1 { color: #333; }
        h2 { color: #555; margin-top: 30px; }
        p { color: #666; }
    </style>
</head>
<body>
    <h1>QuickStudy Privacy Policy</h1>
    <p><strong>Last Updated:</strong> [Current Date]</p>

    <h2>Overview</h2>
    <p>QuickStudy is committed to protecting your privacy. This policy explains how we handle your data.</p>

    <h2>Data Collection</h2>
    <p>QuickStudy does not collect, store, or transmit any personal data to external servers. All data processing occurs locally on your device.</p>

    <h2>Camera and Photo Access</h2>
    <p>QuickStudy requires access to your camera and photo library to:</p>
    <ul>
        <li>Scan documents for creating study flashcards</li>
        <li>Import images from your photo library for OCR processing</li>
    </ul>
    <p>These images are processed locally on your device and are never uploaded to external servers.</p>

    <h2>Data Storage</h2>
    <p>All study sets, flashcards, and user preferences are stored locally on your device using iOS standard storage mechanisms. This data is:</p>
    <ul>
        <li>Not shared with third parties</li>
        <li>Not backed up to our servers</li>
        <li>Deleted when you uninstall the app</li>
    </ul>

    <h2>On-Device AI Processing</h2>
    <p>QuickStudy uses Apple's FoundationModels framework for AI-powered flashcard generation. This processing:</p>
    <ul>
        <li>Happens entirely on your device</li>
        <li>Does not send data to external servers</li>
        <li>Respects Apple's privacy standards</li>
    </ul>

    <h2>Third-Party Services</h2>
    <p>QuickStudy does not integrate any third-party analytics, advertising, or tracking services.</p>

    <h2>Children's Privacy</h2>
    <p>QuickStudy does not knowingly collect personal information from anyone. The app is designed to work entirely offline with local data storage.</p>

    <h2>Changes to This Policy</h2>
    <p>We may update this privacy policy from time to time. Changes will be posted on this page with an updated revision date.</p>

    <h2>Contact</h2>
    <p>If you have questions about this privacy policy, please contact us at: [your email]</p>
</body>
</html>
```

**Where to Host (Free Options):**
1. **GitHub Pages**: Create a repo, add privacy.html, enable GitHub Pages
2. **Netlify/Vercel**: Free static site hosting
3. **Firebase Hosting**: Free tier available
4. **Personal website**: If you have one

---

## 📋 App Store Connect Setup Checklist

### Before Submitting

- [ ] Privacy Policy hosted and URL accessible
- [ ] Support URL created and working
- [ ] Screenshots captured (3-10 per device size)
- [ ] App preview video created (optional)
- [ ] App description written
- [ ] Keywords selected
- [ ] Age rating questionnaire completed
- [ ] App category selected (Education)
- [ ] Marketing version updated to 1.0.0
- [ ] Build uploaded via Xcode Organizer

### In App Store Connect

1. **Login**: https://appstoreconnect.apple.com
2. **Create App**: Click "+" → New App
3. **Fill Details**:
   - Platform: iOS
   - Name: QuickStudy
   - Primary Language: English
   - Bundle ID: com.henley.jaiden.QuickStudy
   - SKU: Use your Bundle ID

4. **App Information**:
   - Subtitle
   - Privacy Policy URL
   - Category: Education
   - License Agreement: Standard

5. **Pricing and Availability**:
   - Free or paid
   - Available countries
   - Release date

6. **Prepare for Submission**:
   - Upload screenshots
   - Add app preview video
   - Write description
   - Add keywords
   - Add support URL
   - Complete age rating
   - Select build
   - Submit for review

---

## 🎯 Submission Tips

### Common Rejection Reasons to Avoid

1. **Missing Privacy Policy**: Must have working URL
2. **Incorrect Screenshots**: Must match actual app
3. **Crashes**: Test thoroughly on real devices
4. **Missing Usage Descriptions**: We've added these
5. **Incomplete App Information**: Fill all required fields

### Review Timeline

- **Typical**: 24-48 hours
- **First submission**: May take longer
- **Rejections**: Common for first apps, just fix and resubmit

### After Approval

- [ ] Announce on social media
- [ ] Share with friends/family
- [ ] Request reviews from users
- [ ] Monitor crash reports
- [ ] Plan updates based on feedback

---

## 🚀 Quick Start Command

When ready to submit:

1. In Xcode: Product → Archive
2. Wait for archive to complete
3. Window → Organizer → Archives tab
4. Select your archive → Distribute App
5. App Store Connect → Upload
6. Follow prompts to sign and upload
7. Go to App Store Connect to complete submission

---

## Need Help?

- **Apple Documentation**: https://developer.apple.com/app-store/submissions/
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/

Good luck with your submission! 🎉
