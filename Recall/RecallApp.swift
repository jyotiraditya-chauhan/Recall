//
//  RecallApp.swift
//  Recall
//
//  Created by Aditya Chauhan on 14/11/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct RecallApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
        }
    }
}


