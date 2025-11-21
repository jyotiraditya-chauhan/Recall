import Foundation
import AppIntents
import FirebaseAuth

// MARK: - Add Memory Intent

struct AddMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Memory"
    static var description = IntentDescription("Save a thought or reminder to Recall")

    /// When false, Siri executes the intent without opening the app
    static var openAppWhenRun: Bool = false

    @Parameter(
        title: "Memory",
        description: "What do you want to remember?",
        requestValueDialog: "What would you like to remember?"
    )
    var memoryText: String

    static var parameterSummary: some ParameterSummary {
        Summary("Remember \(\.$memoryText)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Check authentication
        guard let userId = Auth.auth().currentUser?.uid else {
            return .result(dialog: "Please open Recall and sign in first to save memories.")
        }

        // Validate input
        let trimmedText = memoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return .result(dialog: "Please tell me what you'd like to remember.")
        }

        // Create and save the memory
        let memory = MemoryEntity(
            userId: userId,
            title: trimmedText,
            priority: .medium,
            source: .siri
        )

        do {
            _ = try await MemoryService.shared.createMemory(memory)
            return .result(dialog: "Saved: \(trimmedText)")
        } catch {
            return .result(dialog: "Sorry, I couldn't save that right now. Please try again.")
        }
    }
}

// MARK: - Priority Enum for Intents

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

// MARK: - Error Types

enum AddMemoryError: Error, CustomLocalizedStringResourceConvertible {
    case notAuthenticated
    case saveFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notAuthenticated:
            return "Please sign in to save memories"
        case .saveFailed:
            return "Failed to save memory. Please try again."
        }
    }
}
