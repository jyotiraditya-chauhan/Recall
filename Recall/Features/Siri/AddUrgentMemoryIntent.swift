import Foundation
import AppIntents
import FirebaseAuth

struct AddUrgentMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Urgent Memory"
    static var description = IntentDescription("Store an urgent thought or reminder")

    @Parameter(title: "Memory", description: "What do you want to remember urgently?")
    var memoryText: MemoryText

    static var parameterSummary: some ParameterSummary {
        Summary("Remember urgently \(\.$memoryText)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AddMemoryError.notAuthenticated
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
            throw AddMemoryError.saveFailed
        }
    }
}
