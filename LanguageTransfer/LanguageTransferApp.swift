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
    @StateObject private var lessonStore = LessonStore()
    @StateObject private var audioPlayer = AudioPlayerService()

    init() {
        // Configure Firebase (must be first)
        FirebaseApp.configure()

        // Enable Analytics collection
        Analytics.setAnalyticsCollectionEnabled(true)

        // Enable Crashlytics collection
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

        // Log app_open event
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }

    var body: some Scene {
        WindowGroup {
            LessonListView()
                .environmentObject(lessonStore)
                .environmentObject(audioPlayer)
        }
    }
}
