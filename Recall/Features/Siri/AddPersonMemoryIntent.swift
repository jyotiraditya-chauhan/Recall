import Foundation
import AppIntents
import FirebaseAuth

// MARK: - Add Person Memory Intent
// Note: This intent is available in Shortcuts app but not registered as an App Shortcut
// because multi-parameter Siri phrases are unreliable. Users can still create
// custom shortcuts using this intent in the Shortcuts app.

struct AddPersonMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Remember About Person"
    static var description = IntentDescription("Save a memory about someone to Recall")

    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "Memory",
        description: "What do you want to remember?",
        requestValueDialog: "What would you like to remember?"
    )
    var memoryText: String

    @Parameter(
        title: "Person",
        description: "Who is this about?",
        requestValueDialog: "Who is this memory about?"
    )
    var personName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Remember \(\.$memoryText) about \(\.$personName)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Check authentication
        guard let userId = Auth.auth().currentUser?.uid else {
            return .result(dialog: "Please open Recall and sign in first to save memories.")
        }

        // Validate input
        let trimmedText = memoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPerson = personName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            return .result(dialog: "Please tell me what you'd like to remember.")
        }

        guard !trimmedPerson.isEmpty else {
            return .result(dialog: "Please tell me who this memory is about.")
        }

        // Create and save the memory
        let memory = MemoryEntity(
            userId: userId,
            title: trimmedText,
            priority: .medium,
            relatedPerson: trimmedPerson,
            source: .siri
        )

        do {
            _ = try await MemoryService.shared.createMemory(memory)
            return .result(dialog: "Saved memory about \(trimmedPerson): \(trimmedText)")
        } catch {
            return .result(dialog: "Sorry, I couldn't save that right now. Please try again.")
        }
    }
}
