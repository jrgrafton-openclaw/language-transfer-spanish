# Language Transfer - Spanish

SwiftUI iOS app for language learning via Language Transfer methodology.

## Project Status

✅ **iOS Build Automation Configured**
- Automatic signing via App Store Connect API
- TestFlight deployment pipeline ready
- Firebase integration configured

## Quick Start

### Build Archive Only
```bash
./scripts/ios_build.sh
```

### Build & Deploy to TestFlight
```bash
./scripts/ios_deploy.sh
```

This automatically:
1. Archives the app
2. Exports for App Store distribution
3. Uploads to TestFlight
4. **Configures internal testing** (NEW!)
5. Adds build to internal testers

Build appears in TestFlight app within 1-2 minutes.

## Requirements

- Xcode 26.2+
- macOS running in Aqua/login session (not Background launchd)
- Signing certificates in `~/Library/Keychains/build.keychain-db`
- App Store Connect API key in `~/.openclaw/secrets/app-store-connect/`

## Development Workflow

1. Make changes on feature branch
2. Open PR
3. Review & merge to `main`
4. `main` branch triggers automatic TestFlight deployment

## Project Structure

```
LanguageTransfer/
├── LanguageTransferApp.swift   # App entry point
├── ContentView.swift             # Main UI
├── Assets.xcassets/              # App icons & assets
├── Info.plist                    # App configuration
└── GoogleService-Info.plist      # Firebase config

scripts/
├── ios_build.sh     # Archive only (dev/testing)
└── ios_deploy.sh    # Full pipeline (archive + export + TestFlight)

fastlane/
├── Fastfile         # Fastlane configuration (if needed later)
└── Appfile          # App Store Connect settings
```

## Configuration

### Team & Bundle ID
- **Team ID:** B5X96QDRF4
- **Bundle ID:** com.grafton.languagetransfer.spanish
- **App Store Connect:** Language Transfer - Spanish

### Firebase
- **Project:** lobsterproject
- **iOS App ID:** 1:1045899039244:ios:41f82b59d7d2c798

### Signing
- **Keychain:** `~/Library/Keychains/build.keychain-db` (passwordless)
- **Certificates:** Apple Development + Apple Distribution (auto-managed)
- **Provisioning:** Automatic via API key

## Troubleshooting

### Build Fails with "GatherProvisioningInputs" Crash
**Cause:** Running in Background launchd session instead of login session

**Fix:** Ensure OpenClaw gateway runs as user in Aqua/login session:
```bash
launchctl print gui/$(id -u) | head -n 3
# Should show: type = login
```

### Certificate Not Found
**Cause:** Keychain not in search path

**Fix:** Run keychain setup manually:
```bash
security unlock-keychain -p "" ~/Library/Keychains/build.keychain-db
security default-keychain -d user -s ~/Library/Keychains/build.keychain-db
security list-keychains -d user -s ~/Library/Keychains/build.keychain-db /Library/Keychains/System.keychain
```

## Version Management

- **Marketing Version:** 1.0.0 (set in project settings)
- **Build Number:** Auto-incremented by fastlane (future)
- **TestFlight:** New builds appear within 5-10 minutes of upload

## Firebase Analytics & Crashlytics

✅ **Fully integrated and active**

- Analytics automatically tracks app usage, screens, and events
- Crashlytics captures crashes and provides stack traces
- dSYMs uploaded automatically with each TestFlight build

View data in [Firebase Console](https://console.firebase.google.com/project/lobsterproject)

## Future Enhancements

- [ ] Fastlane lane for version bumping
- [ ] Automatic screenshots for App Store
- [ ] Localization support
- [ ] CI/CD integration (GitHub Actions)
- [ ] Google Gemini image generation ("Nano Banana" feature)
