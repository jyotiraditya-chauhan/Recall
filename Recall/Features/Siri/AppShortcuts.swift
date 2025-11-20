import AppIntents

struct RecallAppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddMemoryIntent(),
            phrases: [
                "Add \(\.$memoryText) in \(.applicationName)",
                "Remember \(\.$memoryText) in \(.applicationName)",
                "Save \(\.$memoryText) in \(.applicationName)",
                "Store \(\.$memoryText) in \(.applicationName)"
            ],
            shortTitle: "Add Memory",
            systemImageName: "brain.head.profile"
        )

        AppShortcut(
            intent: AddUrgentMemoryIntent(),
            phrases: [
                "Add urgent \(\.$memoryText) in \(.applicationName)",
                "Urgent \(\.$memoryText) in \(.applicationName)"
            ],
            shortTitle: "Add Urgent Memory",
            systemImageName: "exclamationmark.triangle.fill"
        )

    }
}