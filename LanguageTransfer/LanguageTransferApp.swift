//
//  LanguageTransferApp.swift
//  Language Transfer - Spanish
//
//  Created by OpenClaw on 2026-02-17.
//

import SwiftUI
import FirebaseCore
import FirebaseCrashlytics

@main
struct LanguageTransferApp: App {
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Enable Crashlytics collection
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
