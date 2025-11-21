import AppIntents

struct RecallAppShortcuts: AppShortcutsProvider {


    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
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

//        AppShortcut(
//            intent: AddPersonMemoryIntent(),
//            phrases: [
//                "Save about a person in \(.applicationName)",
//                "Person memory in \(.applicationName)",
//                "Add person note in \(.applicationName)"
//            ],
//            shortTitle: "Remember About Person",
//            systemImageName: "person.fill"
//        )
        
        AppShortcut(
            intent: AddPersonMemoryIntent(),
            phrases: [
                "Remember about someone in \(.applicationName)",
                "Save about a person in \(.applicationName)",
                "Person memory in \(.applicationName)",
                "Add person note in \(.applicationName)"
            ],
            shortTitle: "Remember About Person",
            systemImageName: "person.fill"
        )
    }
}
