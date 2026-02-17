#!/bin/bash
# Quick Start Script for Language Transfer Spanish iOS App
# Run this AFTER you've cleared the blockers (see SETUP_STATUS.md)

set -e  # Exit on error

echo "🚀 Language Transfer Spanish - Quick Start"
echo "=========================================="
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode first."
    echo "   See BLOCKER #2 in SETUP_STATUS.md"
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -n1)"

# Check if Homebrew is writable
if [ ! -w "/opt/homebrew" ]; then
    echo "❌ Homebrew not writable. Please fix permissions first:"
    echo "   sudo chown -R $USER /opt/homebrew"
    exit 1
fi

echo "✅ Homebrew permissions OK"

# Check for modern Ruby
RUBY_VERSION=$(ruby -v | grep -oE '[0-9]+\.[0-9]+' | head -n1)
if (( $(echo "$RUBY_VERSION < 3.0" | bc -l) )); then
    echo "⚠️  Old Ruby detected ($RUBY_VERSION). Installing Ruby 3.x..."
    brew install ruby
    echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
    echo "✅ Ruby $(ruby -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') installed"
else
    echo "✅ Ruby $RUBY_VERSION OK"
fi

# Check if .xcodeproj exists
if [ ! -d "LanguageTransfer.xcodeproj" ]; then
    echo "⚠️  No Xcode project found. You need to:"
    echo "   1. Open Xcode"
    echo "   2. Create new iOS App project"
    echo "   3. Save as 'LanguageTransfer' in this directory"
    echo "   4. Sign in with your Apple ID"
    echo "   5. Enable automatic signing"
    echo ""
    echo "See BLOCKER #2 in SETUP_STATUS.md for detailed instructions"
    exit 1
fi

echo "✅ Xcode project found"

# Install fastlane
if ! command -v bundle &> /dev/null; then
    echo "📦 Installing Bundler..."
    gem install bundler
fi

echo "📦 Installing fastlane..."
bundle install

echo "✅ Fastlane installed"

# Check Firebase
if [ ! -f "LanguageTransfer/GoogleService-Info.plist" ]; then
    echo "⚠️  Firebase not configured yet. You need to:"
    echo "   1. Go to https://console.firebase.google.com"
    echo "   2. Create/link project 'onyx-pad-487706-a5'"
    echo "   3. Add iOS app with bundle ID: com.grafton.languagetransfer.spanish"
    echo "   4. Download GoogleService-Info.plist"
    echo "   5. Place it in LanguageTransfer/ directory"
    echo ""
    echo "See BLOCKER #3 in SETUP_STATUS.md"
    echo ""
    echo "Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    echo "✅ Firebase configured"
fi

# Create App Store Connect app
echo ""
echo "🎯 Ready to create App Store Connect app"
echo "   This will:"
echo "   - Create app ID in Developer Portal"
echo "   - Create app record in App Store Connect"
echo "   - Use API key authentication"
echo ""
echo "Continue? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "📱 Creating app..."
    bundle exec fastlane create_app
    echo "✅ App created in App Store Connect!"
else
    echo "Skipped app creation"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Review app in App Store Connect"
echo "  2. Run your first build: bundle exec fastlane beta"
echo "  3. Or ask me on Slack: 'deploy to TestFlight'"
echo ""
echo "Documentation:"
echo "  - SETUP_STATUS.md (what happened overnight)"
echo "  - README.md (project overview)"
echo "  - fastlane/Fastfile (automation lanes)"
echo ""
echo "Happy shipping! 🚀"
