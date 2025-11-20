import Foundation
import AppIntents
import FirebaseAuth

struct AddMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Memory"
    static var description = IntentDescription("Store a thought or reminder that you want to remember")

    @Parameter(title: "Memory", description: "What do you want to remember?")
    var memoryText: String

    @Parameter(title: "Priority", description: "How important is this?", default: .medium)
    var priority: MemoryPriorityIntent

    @Parameter(title: "Related Person", description: "Is this about someone?")
    var relatedPerson: String?

    @Parameter(title: "Related To", description: "What is this related to?")
    var relatedTo: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Remember \(\.$memoryText)") {
            \.$priority
            \.$relatedPerson
            \.$relatedTo
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
            relatedPerson: relatedPerson,
            relatedTo: relatedTo,
            source: .siri
        )

        do {
            _ = try await MemoryService.shared.createMemory(memory)
            return .result(dialog: "I've saved your memory: \(memoryText)")
        } catch {
            throw AddMemoryError.saveFailed
        }
    }
}

enum MemoryPriorityIntent: String, AppEnum {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Priority")

    static var caseDisplayRepresentations: [MemoryPriorityIntent: DisplayRepresentation] = [
        .low: "Low",
        .medium: "Medium",
        .high: "High",
        .urgent: "Urgent"
    ]

    func toPriority() -> MemoryPriority {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .urgent: return .urgent
        }
    }
}

enum AddMemoryError: Error, CustomLocalizedStringResourceConvertible {
    case notAuthenticated
    case saveFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notAuthenticated:
            return "Please log in to save memories"
        case .saveFailed:
            return "Failed to save memory. Please try again"
        }
    }
}
