# Language Transfer - Spanish

A modern SwiftUI rebuild of the Language Transfer Spanish learning app.

## Overview

This is a complete rebuild of the [Language Transfer app](https://github.com/language-transfer/lt-app) specifically for Spanish, using:
- **SwiftUI** for modern, declarative UI
- **Automatic signing** for simplified deployment
- **TestFlight** for beta distribution
- **Firebase** for analytics and crash reporting
- **Google Gemini** for optional image generation ("Nano Banana" feature)

## Development

### Requirements
- Xcode 15.0+
- iOS 17.0+ target
- macOS 14.0+ for development

### Setup
```bash
# Install dependencies
bundle install

# Configure signing (one-time)
# Open Xcode, sign in with Apple ID, select team

# Build for TestFlight
bundle exec fastlane beta
```

### Architecture
- **SwiftUI** for UI layer
- **Swift Concurrency** (async/await) for audio playback
- **Firebase** for crash reporting and analytics
- **App Store Connect API** for automated deployment

## Automated Deployment

This project uses Fastlane for automated builds:
- Version: Semantic (1.0.0, 1.1.0, etc.)
- Build numbers: Auto-incremented on each TestFlight upload
- Distribution: TestFlight via App Store Connect API

## License

TBD (following Language Transfer's open-source philosophy)
