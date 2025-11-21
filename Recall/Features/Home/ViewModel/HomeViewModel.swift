import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol HomeViewModelProtocol: ObservableObject {
    var memories: [MemoryEntity] { get set }
    var filteredMemories: [MemoryEntity] { get }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var searchText: String { get set }
    var selectedPriorityFilter: MemoryPriority? { get set }
    var showCompletedOnly: Bool { get set }

    func fetchMemories() async
    func createMemory(_ memory: MemoryEntity) async
    func updateMemory(_ memory: MemoryEntity) async
    func deleteMemory(_ memoryId: String) async
    func toggleMemoryCompletion(_ memoryId: String) async
    func startListeningToMemories()
    func stopListeningToMemories()
}

@MainActor
class HomeViewModel: HomeViewModelProtocol, ObservableObject {
    static let shared = HomeViewModel()

    @Published var memories: [MemoryEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedPriorityFilter: MemoryPriority?
    @Published var showCompletedOnly = false

    private var memoryListener: ListenerRegistration?
    private let memoryService = MemoryService.shared

    private init() {
        startListeningToMemories()
    }

    var filteredMemories: [MemoryEntity] {
        var filtered = memories

        if !searchText.isEmpty {
            filtered = filtered.filter { memory in
                memory.title.localizedCaseInsensitiveContains(searchText) ||
                (memory.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                memory.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        if let priority = selectedPriorityFilter {
            filtered = filtered.filter { $0.priority == priority }
        }

        if showCompletedOnly {
            filtered = filtered.filter { $0.isCompleted }
        }

        return filtered
    }

    func fetchMemories() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            memories = try await memoryService.fetchMemories(forUserId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createMemory(_ memory: MemoryEntity) async {

        isLoading = true
        errorMessage = nil

        do {
            let createdMemory = try await memoryService.createMemory(memory)

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func updateMemory(_ memory: MemoryEntity) async {
        isLoading = true
        errorMessage = nil

        do {
            try await memoryService.updateMemory(memory)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteMemory(_ memoryId: String) async {

        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await memoryService.deleteMemory(memoryId, userId: userId)

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleMemoryCompletion(_ memoryId: String) async {
        do {
            try await memoryService.toggleMemoryCompletion(memoryId)

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startListeningToMemories() {
        guard let userId = Auth.auth().currentUser?.uid else { return }


        Task {
            do {
                try await memoryService.migrateOldDataToNewStructure(userId: userId)

            } catch {
            }
        }

        memoryListener = memoryService.listenToMemories(forUserId: userId) { [weak self] memories in
        
            self?.memories = memories
        }
    }

    func stopListeningToMemories() {
        memoryListener?.remove()
        memoryListener = nil
    }

    func clearFilters() {
        searchText = ""
        selectedPriorityFilter = nil
        showCompletedOnly = false
    }

    deinit {
        MainActor.assumeIsolated {
            self.stopListeningToMemories()
        }
    }
}
