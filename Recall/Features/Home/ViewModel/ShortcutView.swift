//
//  ShortcutView.swift
//  Recall
//
//  Created by Aditya Chauhan on 17/11/25.
//
import AppIntents
import SwiftUI

struct ShortcutView: AppShortcutsProvider {

    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenHomeIntent(),
            phrases: [
                "Open Home Screen in ${applicationName}",
                "Show Home Page in ${applicationName}",
                "Open ${applicationName} Home Screen",
                "Show ${applicationName} Home"
            ],
            shortTitle: "Open Home",
            systemImageName: "house"
        )
    }
}


struct OpenHomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Home Screen"
    static var openAppWhenRun: Bool { true }

    @AppStorage("intentLaunchAction")
    private var launchAction: String = ""

    @MainActor
    func perform() async throws -> some IntentResult {
        launchAction = "open_home"
        return .result()
    }
}



extension Notification.Name {
    static let openHomeScreen = Notification.Name("openHomeScreen")
}

class AppState: ObservableObject {
    @Published var launchAction: LaunchAction = .none
}

enum LaunchAction {
    case none
    case openHome
}
