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

struct PersonNameQuery: EntityQuery {
    func entities(for identifiers: [PersonName.ID]) async throws -> [PersonName] {
        return identifiers.map { PersonName(name: $0) }
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

    @Parameter(title: "Memory", description: "What do you want to remember?")
    var memoryText: MemoryText

    @Parameter(title: "Person", description: "Who is this about?")
    var personName: PersonName

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
            title: memoryText.text,
            priority: priority.toPriority(),
            relatedPerson: personName.name,
            source: .siri
        )

        do {
            _ = try await MemoryService.shared.createMemory(memory)
            return .result(dialog: "Saved memory about \(personName.name): \(memoryText.text)")
        } catch {
            throw AddMemoryError.saveFailed
        }
    }
}
