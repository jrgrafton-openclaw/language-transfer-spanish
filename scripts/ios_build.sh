#!/usr/bin/env bash
set -euo pipefail

# iOS Build Script - Archive Only
# For full deploy (archive + export + upload), use ios_deploy.sh

SCHEME="LanguageTransfer"
CONFIGURATION="Release"
TEAM_ID="B5X96QDRF4"
PROJECT="LanguageTransfer.xcodeproj"
ARCHIVE_PATH="./build/LanguageTransfer.xcarchive"

KEYCHAIN="/Users/familybot/Library/Keychains/build.keychain-db"

ASC_KEY_ID="7UKLD4C2CC"
ASC_ISSUER_ID="69a6de70-79a7-47e3-e053-5b8c7c11a4d1"
ASC_KEY_PATH="/Users/familybot/.openclaw/secrets/app-store-connect/AuthKey_7UKLD4C2CC.p8"

echo "=== iOS Archive Build ==="
echo "Scheme: $SCHEME"
echo "Configuration: $CONFIGURATION"
echo ""

mkdir -p ./build

# Keychain setup
security unlock-keychain -p "" "$KEYCHAIN" || true
security default-keychain -d user -s "$KEYCHAIN"
security list-keychains -d user -s "$KEYCHAIN" /Library/Keychains/System.keychain

echo "=== Signing identities ==="
security find-identity -v -p codesigning "$KEYCHAIN"
echo ""

echo "=== Running xcodebuild archive ==="
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -sdk iphoneos \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  CODE_SIGN_KEYCHAIN="$KEYCHAIN" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  archive \
  | tee ./build/xcodebuild.log

if [ -d "$ARCHIVE_PATH" ]; then
  echo ""
  echo "=== ✅ Archive succeeded ==="
  ls -lh "$ARCHIVE_PATH"
  echo ""
  echo "Archive: $ARCHIVE_PATH"
  
  # Get version info
  VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$ARCHIVE_PATH/Info.plist" 2>/dev/null || echo "unknown")
  BUILD=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$ARCHIVE_PATH/Info.plist" 2>/dev/null || echo "unknown")
  echo "Version: $VERSION ($BUILD)"
else
  echo ""
  echo "=== ❌ Archive failed ==="
  exit 1
fi
