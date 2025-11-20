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
    private let memoriesCollection = "memories"

    func createMemory(_ memory: MemoryEntity) async throws -> MemoryEntity {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MemoryError.userNotAuthenticated
        }

        var newMemory = memory
        newMemory.userId = userId
        newMemory.createdAt = Date()
        newMemory.updatedAt = Date()

        let docRef = try await db.collection(memoriesCollection).addDocument(data: newMemory.toDictionary())
        newMemory.id = docRef.documentID

        try await updateUserMemoryCount(userId: userId, increment: 1)

        return newMemory
    }

    func fetchMemories(forUserId userId: String) async throws -> [MemoryEntity] {
        let snapshot = try await db.collection(memoriesCollection)
            .whereField("user_id", isEqualTo: userId)
            .order(by: "created_at", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            MemoryEntity.fromDictionary(doc.data(), id: doc.documentID)
        }
    }

    func fetchMemory(byId memoryId: String) async throws -> MemoryEntity {
        let doc = try await db.collection(memoriesCollection).document(memoryId).getDocument()

        guard let data = doc.data(),
              let memory = MemoryEntity.fromDictionary(data, id: doc.documentID) else {
            throw MemoryError.memoryNotFound
        }

        return memory
    }

    func updateMemory(_ memory: MemoryEntity) async throws {
        guard let memoryId = memory.id else {
            throw MemoryError.invalidData
        }

        var updatedMemory = memory
        updatedMemory.updatedAt = Date()

        try await db.collection(memoriesCollection)
            .document(memoryId)
            .updateData(updatedMemory.toDictionary())
    }

    func deleteMemory(_ memoryId: String, userId: String) async throws {
        try await db.collection(memoriesCollection).document(memoryId).delete()
        try await updateUserMemoryCount(userId: userId, increment: -1)
    }

    func toggleMemoryCompletion(_ memoryId: String) async throws {
        let memory = try await fetchMemory(byId: memoryId)
        var updatedMemory = memory
        updatedMemory.isCompleted.toggle()
        updatedMemory.updatedAt = Date()

        try await db.collection(memoriesCollection)
            .document(memoryId)
            .updateData([
                "is_completed": updatedMemory.isCompleted,
                "updated_at": Timestamp(date: updatedMemory.updatedAt)
            ])
    }

    func searchMemories(forUserId userId: String, query: String) async throws -> [MemoryEntity] {
        let allMemories = try await fetchMemories(forUserId: userId)
        return allMemories.filter { memory in
            memory.title.localizedCaseInsensitiveContains(query) ||
            (memory.description?.localizedCaseInsensitiveContains(query) ?? false) ||
            memory.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
            (memory.relatedPerson?.localizedCaseInsensitiveContains(query) ?? false) ||
            (memory.relatedTo?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func filterMemories(forUserId userId: String, by priority: MemoryPriority? = nil, completed: Bool? = nil) async throws -> [MemoryEntity] {
        var query: Query = db.collection(memoriesCollection)
            .whereField("user_id", isEqualTo: userId)

        if let priority = priority {
            query = query.whereField("priority", isEqualTo: priority.rawValue)
        }

        if let completed = completed {
            query = query.whereField("is_completed", isEqualTo: completed)
        }

        query = query.order(by: "created_at", descending: true)

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { doc in
            MemoryEntity.fromDictionary(doc.data(), id: doc.documentID)
        }
    }

    private func updateUserMemoryCount(userId: String, increment: Int) async throws {
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "total_memories": FieldValue.increment(Int64(increment))
        ])
    }

    func listenToMemories(forUserId userId: String, completion: @escaping ([MemoryEntity]) -> Void) -> ListenerRegistration {
        return db.collection(memoriesCollection)
            .whereField("user_id", isEqualTo: userId)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching memories: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }

                let memories = documents.compactMap { doc in
                    MemoryEntity.fromDictionary(doc.data(), id: doc.documentID)
                }
                completion(memories)
            }
    }
}
