# Privacy Manifest Setup Instructions

## ✅ Step 1: Add PrivacyInfo.xcprivacy to Xcode Project

I've created the `PrivacyInfo.xcprivacy` file at:
`/Users/jaidenhenley/Desktop/SwiftStudentChallenge/QuickStudy/QuickStudy/PrivacyInfo.xcprivacy`

**To add it to your Xcode project:**

1. Open `QuickStudy.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), right-click on the `QuickStudy` folder (the one with your Swift files)
3. Select **"Add Files to 'QuickStudy'..."**
4. Navigate to and select `PrivacyInfo.xcprivacy`
5. Make sure **"Copy items if needed"** is checked
6. Make sure **"QuickStudy" target** is checked
7. Click **"Add"**

The file should now appear in your project and will be included in your app bundle.

---

## ✅ Step 2: Add Photo Library Usage Description

You need to add the missing `NSPhotoLibraryUsageDescription` privacy key.

**In Xcode:**

1. Select your project in the Project Navigator (top-level "QuickStudy")
2. Select the **"QuickStudy" target**
3. Go to the **"Info"** tab
4. Look for **"Custom iOS Target Properties"** section
5. Click the **"+"** button to add a new key
6. Type: `NSPhotoLibraryUsageDescription` (or select "Privacy - Photo Library Usage Description" from the dropdown)
7. For the value, enter: **"We use your photos to create study flashcards from images."**

**Alternative method (Build Settings):**

1. Select your project → QuickStudy target
2. Go to **"Build Settings"** tab
3. Search for "photo"
4. Find **"Photo Library Usage Description"** or search for `INFOPLIST_KEY_NSPhotoLibraryUsageDescription`
5. Set value to: **"We use your photos to create study flashcards from images."**

---

## What the Privacy Manifest Declares

Your `PrivacyInfo.xcprivacy` declares:

### Data Collection:
- **Photos/Videos**: Used for app functionality only (OCR processing)
- **Not linked to user identity**
- **Not used for tracking**

### Required Reason APIs:
- **File Timestamp API (C617.1)**: Used for accessing file modification dates when saving study sets
- **UserDefaults API (CA92.1)**: Used for storing user preferences (demo mode, settings)

### Tracking:
- **No tracking**: Your app doesn't track users
- **No tracking domains**: No third-party analytics or advertising

This manifest meets Apple's privacy requirements for iOS 17+.

---

## Verification

After adding these:

1. Build your project (⌘B)
2. Check for any warnings related to privacy
3. The Privacy Manifest will be automatically included in your app bundle
4. You can verify in App Store Connect after upload

---

## Why This Matters

- **Required by Apple** (as of May 2024) for apps using camera/photos
- **Prevents App Store rejection** for missing privacy declarations
- **Builds user trust** by being transparent about data usage
- **Required for TestFlight and App Store submission**
