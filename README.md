# PayParse – Automated Invoice Agent

## Overview
PayParse is a background utility app that listens for banking SMS messages (simulated or real), generates a PDF invoice instantly, and logs the transaction to Firestore.

## Features
- **Background Service**: Listens for SMS even when app is closed.
- **Isolate Processing**: Uses a separate isolate for heavy regex and PDF work.
- **PDF Generation**: Creates professional invoices locally.
- **Offline Sync**: Logs to Firestore with offline support.

## Project Structure
- `lib/src/features/sms_listener`: Background service & Regex logic.
- `lib/src/features/invoice_generator`: PDF creation logic.
- `lib/src/features/dashboard`: UI and Data Repository.

## Setup & Testing

### 1. Prerequisites
- Flutter SDK
- Android Device (Emulator or Real)
- Firebase Project

### 2. Firebase Setup
1. Create a project in Firebase Console.
2. Add an Android app.
3. Download `google-services.json` and place it in `android/app/`.
4. Enable **Firestore Database** in test mode.

### 3. Permissions
On Android 6+, you must manually grant SMS permissions if the prompt doesn't appear, or ensure you accept the runtime permission dialog when the app launches.

### 4. Testing Background SMS
**On Emulator:**
1. Open the app to initialize the service.
2. Open the emulator's "Extended Controls" (three dots > Phone > SMS).
3. Send a message to the emulator:
   *   **HDFC Example**: `Rs. 5000.00 credited to your A/C ...`
   *   **UPI Example**: `UPI Ref 1234567890 received ...`
   *   **Combined**: `INR 1,200.00 credited by UPI Ref 998877`
4. Watch the "Run" console for "Detected Payment" logs.
5. Check the App Dashboard; the new invoice should appear (pull to refresh or stream updates).

### 5. Troubleshooting
- **No logs?** Ensure `flutter_background_service` notification is visible in the status bar.
- **No PDF?** Check storage permissions or logcat for file write errors.
