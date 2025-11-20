import Foundation
import AppIntents
import FirebaseAuth

struct AddUrgentMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Urgent Memory"
    static var description = IntentDescription("Store an urgent thought or reminder")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Memory", description: "What do you want to remember urgently?")
    var memoryText: MemoryText

    static var parameterSummary: some ParameterSummary {
        Summary("Remember urgently \(\.$memoryText)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let userId = Auth.auth().currentUser?.uid else {
            return .result(dialog: "You need to log in to the Recall app first to save urgent memories. Please open the app and create an account or sign in.")
        }

        let memory = MemoryEntity(
            userId: userId,
            title: memoryText.text,
            priority: .urgent,
            source: .siri
        )

        do {
            _ = try await MemoryService.shared.createMemory(memory)
            return .result(dialog: "Urgent memory saved: \(memoryText.text)")
        } catch {
            return .result(dialog: "Sorry, I couldn't save your urgent memory right now. Please check your internet connection and try again, or save it directly in the app.")
        }
    }
}
