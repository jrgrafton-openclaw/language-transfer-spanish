fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

Create app in App Store Connect and Developer Portal

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

### ios build_only

```sh
[bundle exec] fastlane ios build_only
```

Build only (no upload)

### ios upload_symbols

```sh
[bundle exec] fastlane ios upload_symbols
```

Upload dSYMs to Firebase Crashlytics

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
