//
//  SubscriptionsApp.swift
//  Subscriptions
//
//  Created by Thalys Guimarães on 29/12/23.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct SubscriptionsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            // Add other models if necessary
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Request notification permission when the app starts
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
            //ContentView() // Uncomment or modify as needed
                //.environmentObject(SubscriptionManager()) // Uncomment or modify as needed
        }
        .modelContainer(sharedModelContainer)
    }
}

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if granted {
            print("Notification permission granted.")
        } else if let error = error {
            print("Error requesting notification permissions: \(error)")
        }
    }
}

