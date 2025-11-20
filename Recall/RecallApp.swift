import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import AppIntents

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
    @StateObject private var authViewModel = AuthenticationViewModel.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(authViewModel)
        }
    }
    
    init() {
        RecallAppShortcuts.updateAppShortcutParameters()
    }
}
