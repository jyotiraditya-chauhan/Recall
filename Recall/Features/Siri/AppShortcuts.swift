import AppIntents

struct OpenHomeIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Home Screen"
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct RecallAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenHomeIntent(),
            phrases: [
                "Open Home Screen in \(.applicationName)",
                "Show Home Page in \(.applicationName)",
                "Open \(.applicationName) Home Screen",
                "Show \(.applicationName) Home"
            ],
            shortTitle: "Open Home",
            systemImageName: "house"
        )
        AppShortcut(
            intent: AddMemoryIntent(),
            phrases: [
                "Remember \(\.$memoryText) in \(.applicationName)",
                "Save \(\.$memoryText) to \(.applicationName)",
                "Add memory \(\.$memoryText) in \(.applicationName)",
                "Store \(\.$memoryText) in \(.applicationName)",
                "Keep \(\.$memoryText) in \(.applicationName)",
                "Note \(\.$memoryText) in \(.applicationName)",
                "Record \(\.$memoryText) in \(.applicationName)",
                "Save thought \(\.$memoryText) in \(.applicationName)",
                "Remember to \(\.$memoryText) in \(.applicationName)",
                "Don't forget \(\.$memoryText) in \(.applicationName)",
                "Make a note \(\.$memoryText) in \(.applicationName)",
                "Add reminder \(\.$memoryText) in \(.applicationName)",
                "Store memory \(\.$memoryText) in \(.applicationName)",
                "Create memory \(\.$memoryText) in \(.applicationName)",
                "Add thought \(\.$memoryText) in \(.applicationName)"
            ],
            shortTitle: "Add Memory",
            systemImageName: "brain.head.profile"
        )

        AppShortcut(
            intent: AddUrgentMemoryIntent(),
            phrases: [
                "Remember urgently \(\.$memoryText) in \(.applicationName)",
                "Save urgent \(\.$memoryText) in \(.applicationName)",
                "Important \(\.$memoryText) in \(.applicationName)",
                "Urgent reminder \(\.$memoryText) in \(.applicationName)",
                "High priority \(\.$memoryText) in \(.applicationName)"
            ],
            shortTitle: "Add Urgent Memory",
            systemImageName: "exclamationmark.triangle.fill"
        )

        AppShortcut(
            intent: AddPersonMemoryIntent(),
            phrases: [
                "Remember about person in \(.applicationName)",
                "Save memory about someone in \(.applicationName)",
                "Note about person in \(.applicationName)",
                "Add person memory in \(.applicationName)"
            ],
            shortTitle: "Remember About Person",
            systemImageName: "person.fill"
        )
    }
}
