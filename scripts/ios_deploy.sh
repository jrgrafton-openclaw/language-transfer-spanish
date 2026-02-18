#!/usr/bin/env bash
set -euo pipefail

# iOS Build & Deploy to TestFlight
# Complete automation: archive → export → upload

SCHEME="LanguageTransfer"
CONFIGURATION="Release"
TEAM_ID="B5X96QDRF4"
PROJECT="LanguageTransfer.xcodeproj"
ARCHIVE_PATH="./build/LanguageTransfer.xcarchive"
EXPORT_PATH="./build/export"

KEYCHAIN="/Users/familybot/Library/Keychains/build.keychain-db"

ASC_KEY_ID="7UKLD4C2CC"
ASC_ISSUER_ID="69a6de70-79a7-47e3-e053-5b8c7c11a4d1"
ASC_KEY_PATH="$ASC_KEY_PATH"

echo "=== iOS Build & Deploy to TestFlight ==="
echo "Configuration: $CONFIGURATION"
echo ""

# Clean
rm -rf ./build
mkdir -p ./build

# ==============================================================================
# STEP 1: KEYCHAIN SETUP
# ==============================================================================

echo "=== Setting up keychain ==="
security unlock-keychain -p "" "$KEYCHAIN" || true
security default-keychain -d user -s "$KEYCHAIN"
security list-keychains -d user -s "$KEYCHAIN" /Library/Keychains/System.keychain

echo "Signing identities:"
security find-identity -v -p codesigning "$KEYCHAIN"
echo ""

# ==============================================================================
# STEP 2: ARCHIVE
# ==============================================================================

echo "=== Building archive ==="
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
  | tee ./build/archive.log

if [ ! -d "$ARCHIVE_PATH" ]; then
  echo "❌ Archive failed"
  exit 1
fi

echo "✅ Archive created: $ARCHIVE_PATH"
echo ""

# ==============================================================================
# STEP 3: EXPORT FOR APP STORE
# ==============================================================================

echo "=== Exporting for App Store distribution ==="

# Create export options plist
cat > ./build/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist ./build/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  | tee ./build/export.log

if [ ! -f "$EXPORT_PATH/LanguageTransfer.ipa" ]; then
  echo "❌ Export failed"
  exit 1
fi

echo "✅ IPA exported: $EXPORT_PATH/LanguageTransfer.ipa"
echo ""

# Get version info
VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$ARCHIVE_PATH/Info.plist" 2>/dev/null || echo "1.0.0")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$ARCHIVE_PATH/Info.plist" 2>/dev/null || echo "1")

echo "Version: $VERSION ($BUILD)"
echo ""

# ==============================================================================
# STEP 4: UPLOAD TO TESTFLIGHT
# ==============================================================================

echo "=== Uploading to TestFlight ==="

xcrun altool \
  --upload-app \
  --type ios \
  --file "$EXPORT_PATH/LanguageTransfer.ipa" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID" \
  | tee ./build/upload.log

echo ""
echo "=== ✅ TestFlight Upload Complete ==="
echo "Version: $VERSION ($BUILD)"
echo ""

# ==============================================================================
# STEP 5: CONFIGURE INTERNAL TESTING
# ==============================================================================

echo "=== Configuring Internal Testing ==="
node ./scripts/setup_testflight_internal.mjs

echo ""
echo "=== 🎉 Deployment Complete ==="
echo "Version: $VERSION ($BUILD)"
echo "Build will appear in TestFlight app within 1-2 minutes"
echo "Check email for TestFlight invitation"
