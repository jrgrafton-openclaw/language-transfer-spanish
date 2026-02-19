//
//  LanguageTransferApp.swift
//  Language Transfer - Spanish
//
//  Created by OpenClaw on 2026-02-17.
//

import SwiftUI
import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics

@main
struct LanguageTransferApp: App {
    init() {
        // Configure Firebase (must be first)
        FirebaseApp.configure()

        // Enable Analytics collection (also controlled via GoogleService-Info.plist IS_ANALYTICS_ENABLED)
        Analytics.setAnalyticsCollectionEnabled(true)

        // Enable Crashlytics collection
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

        // Log app_open event so we can verify analytics are firing
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
