import Foundation
import AppIntents
import FirebaseAuth

struct AddPersonMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Remember About Person"
    static var description = IntentDescription("Store a memory about someone")

    @Parameter(title: "Memory", description: "What do you want to remember?")
    var memoryText: String

    @Parameter(title: "Person", description: "Who is this about?")
    var personName: String

    @Parameter(title: "Priority", description: "How important is this?", default: .medium)
    var priority: MemoryPriorityIntent

    static var parameterSummary: some ParameterSummary {
        Summary("Remember \(\.$memoryText) about \(\.$personName)") {
            \.$priority
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AddMemoryError.notAuthenticated
        }

        let memory = MemoryEntity(
            userId: userId,
            title: memoryText,
            priority: priority.toPriority(),
            relatedPerson: personName,
            source: .siri
        )

        do {
            _ = try await MemoryService.shared.createMemory(memory)
            return .result(dialog: "Saved memory about \(personName): \(memoryText)")
        } catch {
            throw AddMemoryError.saveFailed
        }
    }
}
