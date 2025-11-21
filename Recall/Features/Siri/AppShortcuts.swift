import AppIntents

struct RecallAppShortcuts: AppShortcutsProvider {

    /// Color displayed in Shortcuts app
    static var shortcutTileColor: ShortcutTileColor = .navy

    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {

        // MARK: - Add Memory Intent
        // Simple phrases without parameters work best with Siri
        // Siri will prompt for the memory text after recognizing the phrase
        AppShortcut(
            intent: AddMemoryIntent(),
            phrases: [
                "Add a memory in \(.applicationName)",
                "Save a memory in \(.applicationName)",
                "Remember something in \(.applicationName)",
                "New memory in \(.applicationName)",
                "Add memory to \(.applicationName)",
                "Save to \(.applicationName)"
            ],
            shortTitle: "Add Memory",
            systemImageName: "brain.head.profile"
        )

        // MARK: - Add Urgent Memory Intent
        AppShortcut(
            intent: AddUrgentMemoryIntent(),
            phrases: [
                "Add urgent memory in \(.applicationName)",
                "Save urgent memory in \(.applicationName)",
                "Urgent memory in \(.applicationName)",
                "Important memory in \(.applicationName)"
            ],
            shortTitle: "Add Urgent Memory",
            systemImageName: "exclamationmark.triangle.fill"
        )
    }
}
