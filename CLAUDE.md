# LanguageTransfer(Spanish) — Project Context

**Read this before touching anything in this project.**  
Saves you from rediscovering things that took hours to figure out.

---

## What It Is

iOS app that serves Language Transfer Spanish audio courses.  
App Store Connect App ID: `6759312589`  
Bundle ID: `com.grafton.languagetransfer.spanish`

## Current State

- **Last successful build:** 9 (`v1.0-build9`)
- **Version string:** 1.0
- **TestFlight:** Build 9 is live, no crash, verified on simulator
- **Git tag:** `v1.0-build9`

## Key Files

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen spec — source of truth for project structure |
| `LanguageTransfer/Info.plist` | **Do not let XcodeGen touch this** — uses `$(CURRENT_PROJECT_VERSION)` variables |
| `LanguageTransfer/GoogleService-Info.plist` | Firebase config — NOT in git, must exist locally |
| `fastlane/Fastfile` | Build + upload lane |

## To Deploy a New Build

```bash
cd ~/.openclaw/workspace/language-transfer-spanish
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bundle exec fastlane beta
```

That's it. It increments, builds, uploads, tags, and commits.

## Before Running `xcodegen generate`

Only run this if you need to change project structure (add files, change settings).  
**After running it, always verify:**
```bash
grep "GoogleService" LanguageTransfer.xcodeproj/project.pbxproj | wc -l   # must be 4
cat LanguageTransfer/Info.plist | grep "CURRENT_PROJECT_VERSION"           # must still be there
```
If verification fails → see `docs/ios/xcodegen.md`.

## Known Gotchas

- `project.yml` must NOT have `info.path` or `CURRENT_PROJECT_VERSION`/`MARKETING_VERSION` in settings
- `GoogleService-Info.plist` is excluded from sources and added via `buildPhase: resources`
- Fastfile uses `pilot upload` directly (not `upload_to_testflight`) — JSON parsing bug in fastlane
- IPA path in Fastfile is absolute (not `./build/`) because `sh {}` runs from `fastlane/` subdir

## If Something Breaks

Check `docs/ios/troubleshooting.md` symptom table first.  
For XcodeGen issues: `docs/ios/xcodegen.md`  
For upload/TestFlight issues: `docs/ios/fastlane.md` or `docs/ios/testflight.md`
