# Firebase API Key Security Fix

## What Happened
GoogleService-Info.plist (containing Firebase API key) was committed to the public GitHub repo.

**Compromised key:** `AIzaSyDoEUN1mkUDVG2_-W-M5Sp0wQQB7bwuQe8`

## What Was Done

### 1. Removed from Git History ✅
- Used `git filter-repo` to purge file from ALL commits
- Force pushed clean history to GitHub
- Added `GoogleService-Info.plist` to `.gitignore`

### 2. Attempted Key Rotation ⚠️
Firebase iOS apps cannot be deleted via API (returns 404 but app persists).
This is by design - Firebase doesn't allow app deletion.

## Required Manual Steps

### Option A: Restrict the Existing Key (Recommended - 2 minutes)

1. Go to [Google Cloud Console - API & Services - Credentials](https://console.cloud.google.com/apis/credentials?project=onyx-pad-487706-a5)

2. Find the API key: `AIzaSyDoEUN1mkUDVG2_-W-M5Sp0wQQB7bwuQe8`

3. Click "Edit" → "API restrictions"

4. Select "Restrict key" and enable ONLY:
   - Firebase Installations API
   - Firebase Cloud Messaging API  
   - Google Analytics API (if using Analytics)

5. Under "Application restrictions":
   - Select "iOS apps"
   - Add bundle ID: `com.grafton.languagetransfer.spanish`

6. Save

**Result:** Key only works with your specific iOS app, making the leak much less dangerous.

### Option B: Delete Firebase Project & Start Fresh (Nuclear - 15 minutes)

If you want a completely fresh start:

1. Delete Firebase project in [Firebase Console](https://console.firebase.google.com)
2. Re-create project
3. Add iOS app
4. Download new GoogleService-Info.plist
5. Place in `LanguageTransfer/` directory (won't be committed - in .gitignore)

## Current Status

✅ **Git history cleaned** - File removed from all commits
✅ **Future commits protected** - File in .gitignore  
⚠️ **API key still active** - Needs restriction (see Option A above)

## Prevention

All future builds will NOT commit GoogleService-Info.plist.
The file remains local only for build purposes.
