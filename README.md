# Safe-Call AI (voice_phishing)

Safe-Call AI is a Flutter mobile prototype for helping foreign residents in Korea handle suspicious phone calls safely.

The app demonstrates:

- real-time phishing risk monitoring UI during a call,
- instant translation display in user-selected language,
- visual ARS (automated response system) flow,
- quick emergency dialing,
- recent call log with risk summary.

This repository currently contains an MVP/demo experience with simulated scenarios.

## Key Features

- Onboarding flow with language selection
  - Burmese, Vietnamese, Chinese, English
- Dashboard with protection status
  - Toggle AI protection on/off
  - Demo scenario launch buttons
- In-call protection screen
  - Risk meter that updates with score
  - Warning overlay when risk threshold is high
  - Translation bubble in selected language
  - ARS visual menu mode
- Emergency quick dial row
  - Direct tel: launch for major emergency and reporting numbers
- Settings
  - Change language
  - Toggle real-time protection

## Tech Stack

- Flutter (Material 3)
- Dart
- State management: provider
- UI motion: flutter_animate
- Typography: google_fonts
- Device integrations:
  - url_launcher (tel links)
  - permission_handler
  - shared_preferences

## Project Structure

- lib/main.dart: app entry, theme, providers, routes
- lib/providers/app_provider.dart: core app state and demo simulation logic
- lib/screens/: onboarding, dashboard, call, settings
- lib/widgets/: risk meter, warning overlay, ARS menu, emergency row, etc.
- lib/theme/app_colors.dart: shared color system

## Getting Started

### Prerequisites

- Flutter SDK (stable)
- Dart SDK (bundled with Flutter)
- Xcode (for iOS) and/or Android Studio with SDK tools

Check your setup:

```bash
flutter --version
flutter doctor
```

### Install Dependencies

```bash
flutter pub get
```

### Run the App

```bash
flutter run
```

To force a specific Firebase Realtime Database instance URL at runtime:

```bash
flutter run --dart-define=FIREBASE_DATABASE_URL=https://YOUR_DATABASE_URL
```

To enable Google Cloud Translation Basic (v2) from the Flutter app:

```bash
flutter run --dart-define=GOOGLE_CLOUD_TRANSLATE_API_KEY=YOUR_API_KEY
```

This project calls the public `translate/v2` REST endpoint directly from the
client. Restrict that key to `translate.googleapis.com` and treat it as a
development/prototype setup rather than a production-safe mobile architecture.

## Demo Flow

1. Complete onboarding and select a language.
2. Open Dashboard.
3. Tap one of the Demo Scenarios:
   - Phishing Call Demo
   - Bank ARS Demo
4. Observe risk meter and translation updates on call screen.
5. End call and review result in Recent Calls.

## Current Status

- This is an MVP/prototype focused on UX and call-protection flow simulation.
- Risk scoring and call content are currently mocked for demo behavior.
- Production integrations (telephony interception, real ASR/translation backend, live anti-fraud model) are not included yet.

## Roadmap Ideas

- Integrate on-device or server ASR for real-time transcription
- Add multilingual translation pipeline
- Connect risk engine to fraud detection model/service
- Persist call logs and settings locally or via backend
- Add stronger privacy controls and consent flow

## License

No license file is currently included. Add a LICENSE file if you want to publish usage terms.
