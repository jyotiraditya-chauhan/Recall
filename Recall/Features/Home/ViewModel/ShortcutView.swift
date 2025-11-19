//
//  ShortcutView.swift
//  Recall
//
//  Created by Aditya Chauhan on 17/11/25.
//
import AppIntents
import SwiftUI
import Combine

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

@MainActor
class AppState: ObservableObject {
    @Published var launchAction: LaunchAction = .none
    @Published var isAuthenticated = false
    @Published var currentUser: UserEntity?
    
     let authViewModel = AuthenticationViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await checkAuthenticationState()
        }
    }
    
    private func checkAuthenticationState() async {
        await MainActor.run {
            isAuthenticated = authViewModel.isAuthenticated
            currentUser = authViewModel.currentUser
        }
        
        // Listen to authentication changes
        authViewModel.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        authViewModel.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
    }
    
    func logout() async {
        await authViewModel.logout()
    }
    
    func login(email: String, password: String) async {
        await authViewModel.login(email: email, password: password)
    }
    
    func signup(email: String, password: String) async {
        await authViewModel.signup(email: email, password: password)
    }
    
    func signInWithGoogle() async {
        await authViewModel.signInWithGoogle()
    }
    
    func signInWithApple() async {
        await authViewModel.signInWithApple()
    }
}

enum LaunchAction {
    case none
    case openHome
}
