import Foundation
import FirebaseFirestore
import FirebaseAuth

enum MemoryError: Error, LocalizedError {
    case userNotAuthenticated
    case memoryNotFound
    
    case invalidData
    case firestoreError(String)

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .memoryNotFound:
            return "Memory not found"
        case .invalidData:
            return "Invalid memory data"
        case .firestoreError(let message):
            return "Firestore error: \(message)"
        }
    }
}

class MemoryService {
    static let shared = MemoryService()
    private init() {}
    private let db = Firestore.firestore()
    private let memoriesCollection = "memories";

    private func getUserMemoryDocument(userId: String) async throws -> UserMemoryDocument {
        let doc = try await db.collection(memoriesCollection).document(userId).getDocument()
        if let data = doc.data(), let userDoc = UserMemoryDocument.fromDictionary(data) {
                    return userDoc
        } else {
                    let newDoc = UserMemoryDocument(uid: userId)
            try await db.collection(memoriesCollection).document(userId).setData(newDoc.toDictionary())
            return newDoc
        }
    }
    private func saveUserMemoryDocument(_ document: UserMemoryDocument) async throws {
        var updatedDoc = document
        updatedDoc.lastUpdated = Date()
        try await db.collection(memoriesCollection).document(document.uid).setData(updatedDoc.toDictionary())
    }

    
    
    func createMemory(_ memory: MemoryEntity) async throws -> MemoryEntity {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MemoryError.userNotAuthenticated}
        var userDoc = try await getUserMemoryDocument(userId: userId)
        var newMemory = memory
        newMemory.id = UUID().uuidString
        
        newMemory.userId = userId
        newMemory.createdAt = Date()
        newMemory.updatedAt = Date()

        userDoc.memories.append(newMemory)
        
    try await saveUserMemoryDocument(userDoc)
        try await updateUserMemoryCount(userId: userId, increment: 1)

        return newMemory
    }

    func fetchMemories(forUserId userId: String) async throws -> [MemoryEntity] {
        let userDoc = try await getUserMemoryDocument(userId: userId)
        return userDoc.memories.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchMemory(byId memoryId: String) async throws -> MemoryEntity {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MemoryError.userNotAuthenticated
        }
        
        let userDoc = try await getUserMemoryDocument(userId: userId)
        
        guard let memory = userDoc.memories.first(where: { $0.id == memoryId }) else {
            throw MemoryError.memoryNotFound
        }
        
        return memory
    }

    func updateMemory(_ memory: MemoryEntity) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let memoryId = memory.id else {
            throw MemoryError.userNotAuthenticated
        }

        var userDoc = try await getUserMemoryDocument(userId: userId)
        
        guard let index = userDoc.memories.firstIndex(where: { $0.id == memoryId }) else {
            throw MemoryError.memoryNotFound
        }
        var updatedMemory = memory
        updatedMemory.updatedAt = Date()
        userDoc.memories[index] = updatedMemory
        try await saveUserMemoryDocument(userDoc)
    }

    func deleteMemory(_ memoryId: String, userId: String) async throws {
        var userDoc = try await getUserMemoryDocument(userId: userId)
        
        guard let index = userDoc.memories.firstIndex(where: { $0.id == memoryId }) else {
            throw MemoryError.memoryNotFound
        }
        userDoc.memories.remove(at: index)
    
        try await saveUserMemoryDocument(userDoc)
        
        try await updateUserMemoryCount(userId: userId, increment: -1)
    }

    func toggleMemoryCompletion(_ memoryId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MemoryError.userNotAuthenticated
        }
        
        var userDoc = try await getUserMemoryDocument(userId: userId)
        
        guard let index = userDoc.memories.firstIndex(where: { $0.id == memoryId }) else {
            throw MemoryError.memoryNotFound
        }
    
        userDoc.memories[index].isCompleted.toggle()
        userDoc.memories[index].updatedAt = Date()
    
        try await saveUserMemoryDocument(userDoc)
    }

    func searchMemories(forUserId userId: String, query: String) async throws -> [MemoryEntity] {
        let userDoc = try await getUserMemoryDocument(userId: userId)
        return userDoc.memories.filter { memory in
            memory.title.localizedCaseInsensitiveContains(query) ||
            (memory.description?.localizedCaseInsensitiveContains(query) ?? false) ||
            memory.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
            (memory.relatedPerson?.localizedCaseInsensitiveContains(query) ?? false) ||
            (memory.relatedTo?.localizedCaseInsensitiveContains(query) ?? false)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    func filterMemories(forUserId userId: String, by priority: MemoryPriority? = nil, completed: Bool? = nil) async throws -> [MemoryEntity] {
        let userDoc = try await getUserMemoryDocument(userId: userId)
        var filtered = userDoc.memories
        
        if let priority = priority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        if let completed = completed {
            filtered = filtered.filter { $0.isCompleted == completed }
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    private func updateUserMemoryCount(userId: String, increment: Int) async throws {
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "total_memories": FieldValue.increment(Int64(increment))
        ])
    }

    func listenToMemories(forUserId userId: String, completion: @MainActor @escaping ([MemoryEntity]) -> Void) -> ListenerRegistration {
        return db.collection(memoriesCollection).document(userId)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else {
                    print("Error fetching user memories: \(error?.localizedDescription ?? "Unknown error")")
                    Task { @MainActor in
                        completion([])
                    }
                    return
                }

                if let userDoc = UserMemoryDocument.fromDictionary(data) {
                    let sortedMemories = userDoc.memories.sorted { $0.createdAt > $1.createdAt }
                    Task { @MainActor in
                        completion(sortedMemories)
                    }
                } else {
                    Task { @MainActor in
                        completion([])
                    }
                }
            }
    }
    
    func migrateOldDataToNewStructure(userId: String) async throws {
        print("🔄 Starting migration for user: \(userId)")
        
        // Fetch old memories using old structure
        let oldMemories = try await fetchOldMemories(forUserId: userId)
        
        if oldMemories.isEmpty {
            print("✅ No old memories to migrate for user: \(userId)")
            return
        }
        
        print("📦 Found \(oldMemories.count) memories to migrate")
        
        var userDoc = UserMemoryDocument(uid: userId)
        userDoc.memories = oldMemories.map { memory in
            var newMemory = memory
            newMemory.id = newMemory.id ?? UUID().uuidString
            return newMemory
        }
    
        try await saveUserMemoryDocument(userDoc)
        try await deleteOldMemoryDocuments(oldMemories)
    }
    
    private func fetchOldMemories(forUserId userId: String) async throws -> [MemoryEntity] {
        let snapshot = try await db.collection(memoriesCollection)
            .whereField("user_id", isEqualTo: userId)
            .getDocuments()

        let memories = snapshot.documents.compactMap { doc in
            MemoryEntity.fromDictionary(doc.data(), id: doc.documentID)
        }
        return memories.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func deleteOldMemoryDocuments(_ memories: [MemoryEntity]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for memory in memories {
                if let memoryId = memory.id {
                    group.addTask { [weak self] in
                        try await self?.db.collection(self?.memoriesCollection ?? "memories").document(memoryId).delete()
                    }
                }
            }
            try await group.waitForAll()
        }
    }
}
