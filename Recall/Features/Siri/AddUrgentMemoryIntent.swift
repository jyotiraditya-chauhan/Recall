import Foundation
import AppIntents
import FirebaseAuth


struct AddUrgentMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Urgent Memory"
    static var description = IntentDescription("Save an urgent thought or reminder to Recall")

    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "Memory",
        description: "What urgent thing do you want to remember?",
        requestValueDialog: "What urgent thing would you like to remember?"
    )
    var memoryText: String

    static var parameterSummary: some ParameterSummary {
        Summary("Remember urgently \(\.$memoryText)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {

        guard let userId = Auth.auth().currentUser?.uid else {
            return .result(dialog: "Please open Recall and sign in first to save memories.")
        }
        let trimmedText = memoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return .result(dialog: "Please tell me what urgent thing you'd like to remember.")
        }
        let memory = MemoryEntity(
            userId: userId,
            title: trimmedText,
            priority: .urgent,
            source: .siri
        )

        do {
            _ = try await MemoryService.shared.createMemory(memory)
            return .result(dialog: "Urgent memory saved: \(trimmedText)")
        } catch {
            return .result(dialog: "Sorry, I couldn't save that right now. Please try again.")
        }
    }
}
