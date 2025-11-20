import Foundation
import AppIntents
import FirebaseAuth

struct MemoryText: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Memory Text")
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "\(text)")
    }
    
    var id: String { text }
    let text: String
    
    init(text: String) {
        self.text = text
    }
    
    static var defaultQuery = MemoryTextQuery()
}

struct MemoryTextQuery: EntityQuery {
    func entities(for identifiers: [MemoryText.ID]) async throws -> [MemoryText] {
        return identifiers.map { MemoryText(text: $0) }
    }
    
    func suggestedEntities() async throws -> [MemoryText] {
        return [
            MemoryText(text: "Buy groceries"),
            MemoryText(text: "Call mom"),
            MemoryText(text: "Meeting at 3pm"),
            MemoryText(text: "Take medication")
        ]
    }
}

struct AddMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Memory"
    static var description = IntentDescription("Store a thought or reminder that you want to remember")

    @Parameter(title: "Memory", description: "What do you want to remember?")
    var memoryText: MemoryText

    @Parameter(title: "Priority", description: "How important is this?", default: .medium)
    var priority: MemoryPriorityIntent

    static var parameterSummary: some ParameterSummary {
        Summary("Remember \(\.$memoryText)") {
            \.$priority
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AddMemoryError.notAuthenticated
        }

        let memory = MemoryEntity(
            userId: userId,
            title: memoryText.text,
            priority: priority.toPriority(),
            source: .siri
        )

        do {
            _ = try await MemoryService.shared.createMemory(memory)
            return .result(dialog: "I've saved your memory: \(memoryText.text)")
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
