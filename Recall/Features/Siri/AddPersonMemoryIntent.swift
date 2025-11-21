import Foundation
import AppIntents
import FirebaseAuth

struct PersonName: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Person Name")
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "\(name)")
    }
    
    var id: String { name }
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    static var defaultQuery = PersonNameQuery()
}

struct PersonNameQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [PersonName.ID]) async throws -> [PersonName] {
        return identifiers.map { PersonName(name: $0) }
    }

    /// This method is called by Siri when the user provides voice input for person name
    func entities(matching string: String) async throws -> [PersonName] {
        guard !string.isEmpty else {
            return []
        }
        return [PersonName(name: string)]
    }

    func suggestedEntities() async throws -> [PersonName] {
        return [
            PersonName(name: "John"),
            PersonName(name: "Mom"),
            PersonName(name: "Dad"),
            PersonName(name: "Sarah")
        ]
    }
}

struct AddPersonMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Remember About Person"
    static var description = IntentDescription("Store a memory about someone")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Memory", description: "What do you want to remember?")
    var memoryText: MemoryText

    @Parameter(title: "Person", description: "Who is this about?")
    var personName: PersonName

    static var parameterSummary: some ParameterSummary {
        Summary("Remember \(\.$memoryText) about \(\.$personName)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let userId = Auth.auth().currentUser?.uid else {
            return .result(dialog: "You need to log in to the Recall app first to save memories about people. Please open the app and create an account or sign in.")
        }

        let memory = MemoryEntity(
            userId: userId,
            title: memoryText.text,
            priority: .medium,
            relatedPerson: personName.name,
            source: .siri
        )

        do {
            _ = try await MemoryService.shared.createMemory(memory)
            return .result(dialog: "Saved memory about \(personName.name): \(memoryText.text)")
        } catch {
            return .result(dialog: "Sorry, I couldn't save your memory about \(personName.name) right now. Please check your internet connection and try again, or save it directly in the app.")
        }
    }
}
