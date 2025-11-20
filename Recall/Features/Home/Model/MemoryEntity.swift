import Foundation
import FirebaseFirestore

enum MemoryPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var color: String {
        switch self {
        case .low: return "#4CAF50"
        case .medium: return "#2196F3"
        case .high: return "#FF9800"
        case .urgent: return "#F44336"
        }
    }
}

struct MemoryEntity: Codable, Identifiable {
    var id: String?
    var userId: String
    var title: String
    var description: String?
    var priority: MemoryPriority
    var dateToRemember: Date?
    var relatedPerson: String?
    var relatedTo: String?
    var tags: [String]
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var source: MemorySource

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case priority
        case dateToRemember = "date_to_remember"
        case relatedPerson = "related_person"
        case relatedTo = "related_to"
        case tags
        case isCompleted = "is_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case source
    }

    init(
        id: String? = nil,
        userId: String,
        title: String,
        description: String? = nil,
        priority: MemoryPriority = .medium,
        dateToRemember: Date? = nil,
        relatedPerson: String? = nil,
        relatedTo: String? = nil,
        tags: [String] = [],
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        source: MemorySource = .manual
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.priority = priority
        self.dateToRemember = dateToRemember
        self.relatedPerson = relatedPerson
        self.relatedTo = relatedTo
        self.tags = tags
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.source = source
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "user_id": userId,
            "title": title,
            "priority": priority.rawValue,
            "tags": tags,
            "is_completed": isCompleted,
            "created_at": Timestamp(date: createdAt),
            "updated_at": Timestamp(date: updatedAt),
            "source": source.rawValue
        ]
        
        // Include ID if it exists
        if let id = id {
            dict["id"] = id
        }

        if let description = description {
            dict["description"] = description
        }
        if let dateToRemember = dateToRemember {
            dict["date_to_remember"] = Timestamp(date: dateToRemember)
        }
        if let relatedPerson = relatedPerson {
            dict["related_person"] = relatedPerson
        }
        if let relatedTo = relatedTo {
            dict["related_to"] = relatedTo
        }

        return dict
    }

    static func fromDictionary(_ dict: [String: Any], id: String) -> MemoryEntity? {
        guard let userId = dict["user_id"] as? String,
              let title = dict["title"] as? String,
              let priorityStr = dict["priority"] as? String,
              let priority = MemoryPriority(rawValue: priorityStr),
              let tags = dict["tags"] as? [String],
              let isCompleted = dict["is_completed"] as? Bool,
              let createdAtTimestamp = dict["created_at"] as? Timestamp,
              let updatedAtTimestamp = dict["updated_at"] as? Timestamp,
              let sourceStr = dict["source"] as? String,
              let source = MemorySource(rawValue: sourceStr) else {
            return nil
        }

        let description = dict["description"] as? String
        let dateToRemember = (dict["date_to_remember"] as? Timestamp)?.dateValue()
        let relatedPerson = dict["related_person"] as? String
        let relatedTo = dict["related_to"] as? String

        return MemoryEntity(
            id: id,
            userId: userId,
            title: title,
            description: description,
            priority: priority,
            dateToRemember: dateToRemember,
            relatedPerson: relatedPerson,
            relatedTo: relatedTo,
            tags: tags,
            isCompleted: isCompleted,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            source: source
        )
    }
}

enum MemorySource: String, Codable {
    case manual = "manual"
    case siri = "siri"
}

// MARK: - User Memory Document for new structure
struct UserMemoryDocument: Codable {
    var uid: String
    var memories: [MemoryEntity]
    var lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case uid
        case memories
        case lastUpdated = "last_updated"
    }
    
    init(uid: String, memories: [MemoryEntity] = []) {
        self.uid = uid
        self.memories = memories
        self.lastUpdated = Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "uid": uid,
            "memories": memories.map { $0.toDictionary() },
            "last_updated": Timestamp(date: lastUpdated)
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> UserMemoryDocument? {
        guard let uid = dict["uid"] as? String,
              let memoriesData = dict["memories"] as? [[String: Any]] else {
            return nil
        }
        
        let memories = memoriesData.compactMap { memoryDict in
            // Use stored ID if available, otherwise generate a new one
            let memoryId = memoryDict["id"] as? String ?? UUID().uuidString
            return MemoryEntity.fromDictionary(memoryDict, id: memoryId)
        }
        
        var document = UserMemoryDocument(uid: uid, memories: memories)
        
        if let lastUpdatedTimestamp = dict["last_updated"] as? Timestamp {
            document.lastUpdated = lastUpdatedTimestamp.dateValue()
        }
        
        return document
    }
}
